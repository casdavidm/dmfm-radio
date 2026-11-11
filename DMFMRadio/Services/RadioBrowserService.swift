import Foundation
import Combine

/// Estados del servicio de Radio Browser
enum RadioBrowserState: Equatable {
    case idle
    case loading
    case loaded([RadioStation])
    case error(String)
    
    var stations: [RadioStation] {
        if case .loaded(let list) = self { return list }
        return []
    }
}

/// Filtros rápidos por país y categorías
enum CountryFilter: String, CaseIterable, Identifiable {
    case topWorld = "Top Mundial"
    case spain = "España"
    case mexico = "México"
    case colombia = "Colombia"
    case argentina = "Argentina"
    case favorites = "Favoritos"
    
    var id: String { rawValue }
    
    var countryCode: String? {
        switch self {
        case .topWorld, .favorites:
            return nil
        case .spain:
            return "ES"
        case .mexico:
            return "MX"
        case .colombia:
            return "CO"
        case .argentina:
            return "AR"
        }
    }
}

/// DTO para la respuesta de la API pública de Radio Browser
private struct RadioBrowserStationDTO: Decodable {
    let stationuuid: String
    let name: String
    let url: String
    let url_resolved: String?
    let homepage: String?
    let favicon: String?
    let tags: String?
    let country: String?
    let countrycode: String?
    let codec: String?
    let bitrate: Int?
    let votes: Int?
}

/// Servicio que interactúa con la API pública de Radio Browser
@MainActor
final class RadioBrowserService: ObservableObject {
    static let shared = RadioBrowserService()
    
    // MARK: - Published Properties
    @Published private(set) var state: RadioBrowserState = .idle
    @Published var searchText: String = ""
    @Published var selectedFilter: CountryFilter = .topWorld {
        didSet {
            if selectedFilter != oldValue {
                loadCurrentSelection()
            }
        }
    }
    
    // MARK: - Private Properties
    private var currentTask: Task<Void, Never>?
    private var searchDebounceCancellable: AnyCancellable?
    private let primaryBaseURL = "https://de1.api.radio-browser.info/json/stations/search"
    private let fallbackBaseURL = "https://at1.api.radio-browser.info/json/stations/search"
    
    private init() {
        setupSearchDebounce()
        loadCurrentSelection()
    }
    
    // MARK: - Debounce Search
    private func setupSearchDebounce() {
        searchDebounceCancellable = $searchText
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.loadCurrentSelection()
            }
    }
    
    // MARK: - Public Fetch Methods
    
    /// Carga las emisoras según el filtro actual y el texto de búsqueda
    func loadCurrentSelection() {
        currentTask?.cancel()
        
        // Si el filtro seleccionado es Favoritos, cargar desde FavoritesManager
        if selectedFilter == .favorites {
            let favs = FavoritesManager.shared.favoriteStations
            let filteredFavs: [RadioStation]
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed.isEmpty {
                filteredFavs = favs
            } else {
                filteredFavs = favs.filter {
                    $0.name.lowercased().contains(trimmed) ||
                    $0.genre.lowercased().contains(trimmed) ||
                    $0.country.lowercased().contains(trimmed)
                }
            }
            self.state = .loaded(filteredFavs)
            return
        }
        
        let filter = selectedFilter
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        currentTask = Task { [weak self] in
            await self?.performSearch(filter: filter, query: query)
        }
    }
    
    /// Realiza la petición a Radio Browser API
    private func performSearch(filter: CountryFilter, query: String) async {
        self.state = .loading
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "votes"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "limit", value: "70")
        ]
        
        if let countryCode = filter.countryCode {
            queryItems.append(URLQueryItem(name: "countrycode", value: countryCode))
        }
        
        if !query.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: query))
        }
        
        do {
            let stations = try await executeRequest(baseURL: primaryBaseURL, queryItems: queryItems)
            if Task.isCancelled { return }
            self.state = .loaded(stations)
        } catch {
            if Task.isCancelled { return }
            // Intentar con servidor de respaldo
            do {
                let stations = try await executeRequest(baseURL: fallbackBaseURL, queryItems: queryItems)
                if Task.isCancelled { return }
                self.state = .loaded(stations)
            } catch {
                if Task.isCancelled { return }
                print("Error consultando Radio Browser: \(error.localizedDescription)")
                // Si falla la red, proveer las emisoras por defecto como respaldo
                let fallbackStations = AppConfig.defaultStations
                if !fallbackStations.isEmpty {
                    self.state = .loaded(fallbackStations)
                } else {
                    self.state = .error("No se pudo conectar con la base de datos de emisoras. Revisa tu conexión a internet.")
                }
            }
        }
    }
    
    /// Ejecuta la petición HTTP y filtra únicamente streams https:// funcionales
    private func executeRequest(baseURL: String, queryItems: [URLQueryItem]) async throws -> [RadioStation] {
        guard var components = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("DMFMRadio/1.0 (iOS; SwiftUI)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let dtos = try JSONDecoder().decode([RadioBrowserStationDTO].self, from: data)
        
        // Filtrar únicamente streams con https:// y con bitrate funcional para evitar bloqueos en iOS
        let filteredStations: [RadioStation] = dtos.compactMap { dto in
            // Obtener URL de stream (preferir url_resolved si existe y no está vacía)
            let rawURL: String
            if let resolved = dto.url_resolved, !resolved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rawURL = resolved.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                rawURL = dto.url.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Requisito estricto: Solo streams https://
            guard rawURL.lowercased().hasPrefix("https://") else {
                return nil
            }
            
            let name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            
            let country = (dto.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let countryCode = (dto.countrycode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let codec = (dto.codec ?? "MP3").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let bitrateInt = dto.bitrate ?? 0
            
            // Tag de bitrate / calidad
            let bitrateString: String
            if bitrateInt > 0 {
                bitrateString = "\(bitrateInt) kbps • \(codec)"
            } else {
                bitrateString = "\(codec) • En Vivo"
            }
            
            // Géneros / tags
            let tagsClean = (dto.tags ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(2)
                .joined(separator: " • ")
            
            let genre = tagsClean.isEmpty ? (country.isEmpty ? "Radio Digital" : country) : tagsClean
            
            return RadioStation(
                id: dto.stationuuid,
                name: name,
                subtitle: country.isEmpty ? "Emisora Internacional" : country,
                streamURL: rawURL,
                genre: genre,
                bitrate: bitrateString,
                country: country,
                countryCode: countryCode,
                codec: codec,
                faviconURL: dto.favicon
            )
        }
        
        return filteredStations
    }
}

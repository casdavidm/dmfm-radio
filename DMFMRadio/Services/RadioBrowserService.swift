import Foundation
import Combine

/// States of the Radio Browser service
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

/// Quick filters by country
enum CountryFilter: String, CaseIterable, Identifiable {
    case topWorld = "Top Worldwide"
    case spain = "Spain"
    case mexico = "Mexico"
    case colombia = "Colombia"
    case argentina = "Argentina"
    case favorites = "Favorites"
    
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

/// DTO for the public Radio Browser API response
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

/// Service that talks to the public Radio Browser API.
///
/// Each country filter queries that country directly. The search bar always queries
/// the entire worldwide directory, regardless of the selected filter.
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
    
    /// True while the list shows worldwide search results instead of the selected filter
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
    
    // MARK: - Debounced Search
    private func setupSearchDebounce() {
        searchDebounceCancellable = $searchText
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.loadCurrentSelection()
            }
    }
    
    // MARK: - Public Fetch Methods
    
    /// Loads stations for the current filter, or worldwide search results when there is a query
    func loadCurrentSelection() {
        currentTask?.cancel()
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Favorites without a query come straight from FavoritesManager
        if selectedFilter == .favorites && query.isEmpty {
            state = .loaded(FavoritesManager.shared.favoriteStations)
            return
        }
        
        let filter = selectedFilter
        currentTask = Task { [weak self] in
            if query.isEmpty {
                await self?.loadFilter(filter)
            } else {
                await self?.searchWorldwide(query)
            }
        }
    }
    
    // MARK: - Country Filter
    
    private func loadFilter(_ filter: CountryFilter) async {
        state = .loading
        
        var queryItems = baseQueryItems(limit: 70)
        if let countryCode = filter.countryCode {
            queryItems.append(URLQueryItem(name: "countrycode", value: countryCode))
        }
        
        do {
            let stations = try await fetchWithFallback(queryItems: queryItems)
            if Task.isCancelled { return }
            state = .loaded(stations)
        } catch {
            if Task.isCancelled { return }
            reportFailure(error)
        }
    }
    
    // MARK: - Worldwide Search
    
    /// Searches the whole worldwide directory by station name and by genre tag, ignoring the selected filter
    private func searchWorldwide(_ query: String) async {
        state = .loading
        
        var byName = baseQueryItems(limit: 80)
        byName.append(URLQueryItem(name: "name", value: query))
        var byTag = baseQueryItems(limit: 40)
        byTag.append(URLQueryItem(name: "tag", value: query.lowercased()))
        
        do {
            async let nameResults = fetchWithFallback(queryItems: byName)
            async let tagResults = try? fetchWithFallback(queryItems: byTag)
            
            var results = try await nameResults
            let seen = Set(results.map(\.id))
            results.append(contentsOf: (await tagResults ?? []).filter { !seen.contains($0.id) })
            
            if Task.isCancelled { return }
            state = .loaded(results)
        } catch {
            if Task.isCancelled { return }
            reportFailure(error)
        }
    }
    
    // MARK: - Helpers
    
    private func baseQueryItems(limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "votes"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }
    
    private func reportFailure(_ error: Error) {
        print("Radio Browser request failed: \(error.localizedDescription)")
        let fallbackStations = AppConfig.defaultStations
        if !fallbackStations.isEmpty {
            state = .loaded(fallbackStations)
        } else {
            state = .error("Could not reach the station directory. Check your internet connection.")
        }
    }
    
    private func fetchWithFallback(queryItems: [URLQueryItem]) async throws -> [RadioStation] {
        do {
            return try await executeRequest(baseURL: primaryBaseURL, queryItems: queryItems)
        } catch {
            if Task.isCancelled { throw error }
            return try await executeRequest(baseURL: fallbackBaseURL, queryItems: queryItems)
        }
    }
    
    private static let englishLocale = Locale(identifier: "en_US")
    
    /// English display name for a two-letter ISO country code, nil if unrecognized
    static func englishCountryName(code: String) -> String? {
        guard code.count == 2, code.allSatisfy({ $0.isLetter }) else { return nil }
        return englishLocale.localizedString(forRegionCode: code)
    }
    
    // MARK: - Networking
    
    /// Runs the HTTP request and keeps only working https:// streams
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
        
        return dtos.compactMap { dto in
            let rawURL: String
            if let resolved = dto.url_resolved, !resolved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                rawURL = resolved.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                rawURL = dto.url.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Strict requirement: https:// streams only
            guard rawURL.lowercased().hasPrefix("https://") else { return nil }
            
            let name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            
            let rawCountry = (dto.country ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let countryCode = (dto.countrycode ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            // Standard English country name ("United States" instead of "The United States Of America")
            let country = RadioBrowserService.englishCountryName(code: countryCode) ?? rawCountry
            let codec = (dto.codec ?? "MP3").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let bitrateInt = dto.bitrate ?? 0
            
            let bitrateString = bitrateInt > 0 ? "\(bitrateInt) kbps • \(codec)" : "\(codec) • Live"
            
            let tagsClean = (dto.tags ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(2)
                .joined(separator: " • ")
            
            let genre = tagsClean.isEmpty ? (country.isEmpty ? "Digital Radio" : country) : tagsClean
            
            return RadioStation(
                id: dto.stationuuid,
                name: name,
                subtitle: country.isEmpty ? "International Station" : country,
                streamURL: rawURL,
                genre: genre,
                bitrate: bitrateString,
                country: country,
                countryCode: countryCode,
                codec: codec,
                faviconURL: dto.favicon
            )
        }
    }
}

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

/// A group of stations that share a country, built dynamically from the catalog.
/// Stations with a missing or unrecognized country fall into the "World" group.
struct CountryGroup: Identifiable, Hashable {
    static let allID = "ALL"
    static let worldID = "WORLD"
    
    let id: String
    let name: String
    let stations: [RadioStation]
    
    var isAll: Bool { id == CountryGroup.allID }
    var isWorld: Bool { id == CountryGroup.worldID }
    
    /// Flag emoji derived from the ISO country code; globe for All and World
    var flag: String {
        guard !isAll, !isWorld, id.count == 2 else { return "🌍" }
        let base: UInt32 = 127397
        var flag = ""
        for scalar in id.uppercased().unicodeScalars {
            guard let unicode = UnicodeScalar(base + scalar.value) else { return "🌍" }
            flag.unicodeScalars.append(unicode)
        }
        return flag
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
/// - Loads a worldwide catalog once and groups it by country on the fly.
/// - The search bar always queries the whole worldwide catalog, ignoring the selected group.
@MainActor
final class RadioBrowserService: ObservableObject {
    static let shared = RadioBrowserService()
    
    // MARK: - Published Properties
    
    /// Stations currently shown in the list (selected group, or worldwide search results)
    @Published private(set) var state: RadioBrowserState = .idle
    /// Country groups derived from the catalog, most populated first, "World" last
    @Published private(set) var groups: [CountryGroup] = []
    @Published var searchText: String = ""
    @Published var selectedGroupID: String = CountryGroup.allID {
        didSet {
            if selectedGroupID != oldValue && !isSearching {
                showSelectedGroup()
            }
        }
    }
    
    var selectedGroup: CountryGroup? {
        groups.first { $0.id == selectedGroupID }
    }
    
    /// True while the list shows worldwide search results instead of a country group
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Private Properties
    
    private var catalog: [RadioStation] = []
    private var catalogTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var searchDebounceCancellable: AnyCancellable?
    private let primaryBaseURL = "https://de1.api.radio-browser.info/json/stations/search"
    private let fallbackBaseURL = "https://at1.api.radio-browser.info/json/stations/search"
    private let catalogLimit = 600
    private let searchLimit = 120
    
    private init() {
        setupSearchDebounce()
        loadCurrentSelection()
    }
    
    // MARK: - Debounced Search
    
    private func setupSearchDebounce() {
        searchDebounceCancellable = $searchText
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.searchTask?.cancel()
                    self.showSelectedGroup()
                } else {
                    self.searchWorldwide(query)
                }
            }
    }
    
    // MARK: - Public API
    
    /// Reloads the catalog (or re-runs the active search) and refreshes the list
    func loadCurrentSelection() {
        if isSearching {
            searchWorldwide(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if catalog.isEmpty {
            loadCatalog()
        } else {
            showSelectedGroup()
        }
    }
    
    // MARK: - Catalog & Grouping
    
    private func loadCatalog() {
        catalogTask?.cancel()
        state = .loading
        
        let queryItems = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "votes"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "limit", value: "\(catalogLimit)")
        ]
        
        catalogTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let stations = try await self.fetchWithFallback(queryItems: queryItems)
                if Task.isCancelled { return }
                self.catalog = stations
                self.groups = self.buildGroups(from: stations)
                if !self.groups.contains(where: { $0.id == self.selectedGroupID }) {
                    self.selectedGroupID = CountryGroup.allID
                }
                if !self.isSearching {
                    self.showSelectedGroup()
                }
            } catch {
                if Task.isCancelled { return }
                self.state = .error("Could not reach the station directory. Check your internet connection.")
            }
        }
    }
    
    /// Groups stations by country. Missing or unrecognized countries go to "World".
    private func buildGroups(from stations: [RadioStation]) -> [CountryGroup] {
        var byCountry: [String: (name: String, stations: [RadioStation])] = [:]
        var world: [RadioStation] = []
        
        for station in stations {
            let code = station.countryCode.uppercased()
            let name = station.country
            let isRecognized = code.count == 2 && code.allSatisfy { $0.isLetter } && !name.isEmpty
            
            if isRecognized {
                byCountry[code, default: (name: name, stations: [])].stations.append(station)
            } else {
                world.append(station)
            }
        }
        
        var result: [CountryGroup] = [CountryGroup(id: CountryGroup.allID, name: "All", stations: stations)]
        
        let countries = byCountry
            .map { CountryGroup(id: $0.key, name: $0.value.name, stations: $0.value.stations) }
            .sorted {
                if $0.stations.count != $1.stations.count { return $0.stations.count > $1.stations.count }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        result.append(contentsOf: countries)
        
        if !world.isEmpty {
            result.append(CountryGroup(id: CountryGroup.worldID, name: "World", stations: world))
        }
        return result
    }
    
    private func showSelectedGroup() {
        guard !catalog.isEmpty else {
            loadCatalog()
            return
        }
        state = .loaded(selectedGroup?.stations ?? catalog)
    }
    
    // MARK: - Worldwide Search
    
    /// Searches the entire worldwide directory by station name, ignoring the selected group
    private func searchWorldwide(_ query: String) {
        searchTask?.cancel()
        state = .loading
        
        let queryItems = [
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "votes"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "limit", value: "\(searchLimit)"),
            URLQueryItem(name: "name", value: query)
        ]
        
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                var results = try await self.fetchWithFallback(queryItems: queryItems)
                if Task.isCancelled { return }
                
                // Also match genre tags and countries from the loaded catalog
                let lowered = query.lowercased()
                let seen = Set(results.map(\.id))
                let localMatches = self.catalog.filter {
                    !seen.contains($0.id) &&
                    ($0.name.lowercased().contains(lowered) ||
                     $0.genre.lowercased().contains(lowered) ||
                     $0.country.lowercased().contains(lowered))
                }
                results.append(contentsOf: localMatches)
                self.state = .loaded(results)
            } catch {
                if Task.isCancelled { return }
                self.state = .error("Could not reach the station directory. Check your internet connection.")
            }
        }
    }
    
    // MARK: - Country names
    
    private static let englishLocale = Locale(identifier: "en_US")
    
    /// English display name for a two-letter ISO country code, nil if unrecognized
    static func englishCountryName(code: String) -> String? {
        guard code.count == 2, code.allSatisfy({ $0.isLetter }) else { return nil }
        return englishLocale.localizedString(forRegionCode: code)
    }
    
    // MARK: - Networking
    
    private func fetchWithFallback(queryItems: [URLQueryItem]) async throws -> [RadioStation] {
        do {
            return try await executeRequest(baseURL: primaryBaseURL, queryItems: queryItems)
        } catch {
            if Task.isCancelled { throw error }
            return try await executeRequest(baseURL: fallbackBaseURL, queryItems: queryItems)
        }
    }
    
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
        request.timeoutInterval = 15
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
            // Standard English country name from the ISO code ("United States" instead of "The United States Of America")
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
                subtitle: country.isEmpty ? "World" : country,
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

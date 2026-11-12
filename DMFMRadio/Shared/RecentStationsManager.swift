import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Gestor de sincronización de emisoras recientes compartidas vía App Group con el Widget
public final class RecentStationsManager {
    public static let shared = RecentStationsManager()
    
    /// Identificador del App Group compartido entre App y Widget Extension
    public static let appGroupID = "group.casdavidm.dmfmradio"
    public static let recentStationsKey = "dmfm_recent_stations_v1"
    private static let sharedFileName = "dmfm_recent_stations.json"
    
    /// Identificadores y nombres de emisoras de relleno antiguas que deben descartarse
    private static let legacyFillerIDs: Set<String> = [
        "dmfm-main", "dmfm-hits", "dmfm-chill", "dmfm-rock", "dmfm-placeholder"
    ]
    private static let legacyFillerNames: Set<String> = [
        "DM/FM Principal", "DM/FM Hits Global", "DM/FM Lounge & Chill", "DM/FM Rock & Classics", "Selecciona una emisora"
    ]
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: RecentStationsManager.appGroupID)
    }
    
    private var sharedContainerFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: RecentStationsManager.appGroupID)?
            .appendingPathComponent(RecentStationsManager.sharedFileName)
    }
    
    private init() {
        purgeLegacyFillerStationsIfNeeded()
    }
    
    /// Valida que una emisora sea una estación real y no de relleno
    private func isRealStation(_ station: RadioStation) -> Bool {
        guard !station.isPlaceholder else { return false }
        guard !RecentStationsManager.legacyFillerIDs.contains(station.id) else { return false }
        guard !RecentStationsManager.legacyFillerNames.contains(station.name) else { return false }
        return !station.streamURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Limpia cualquier emisora de relleno que haya quedado guardada previamente
    private func purgeLegacyFillerStationsIfNeeded() {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: RecentStationsManager.recentStationsKey),
              let decoded = try? JSONDecoder().decode([RadioStation].self, from: data) else {
            return
        }
        let cleaned = decoded.filter { isRealStation($0) }
        if cleaned.count != decoded.count {
            persistStations(cleaned)
        }
    }
    
    /// Persiste la lista de emisoras en el UserDefaults del App Group y en el contenedor compartido
    private func persistStations(_ stations: [RadioStation]) {
        guard let data = try? JSONEncoder().encode(stations) else { return }
        
        if let defaults = sharedDefaults {
            defaults.set(data, forKey: RecentStationsManager.recentStationsKey)
            defaults.synchronize()
            CFPreferencesAppSynchronize(RecentStationsManager.appGroupID as CFString)
        }
        
        if let fileURL = sharedContainerFileURL {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    /// Guarda la emisora reproducida al inicio de la lista de recientes (sin duplicados, máx. 5) y recarga los widgets de inmediato
    public func saveRecentStation(_ station: RadioStation) {
        guard isRealStation(station) else { return }
        
        var recents = getRecentStations()
        recents.removeAll {
            $0.id == station.id ||
            $0.streamURL.lowercased() == station.streamURL.lowercased() ||
            $0.name.lowercased() == station.name.lowercased()
        }
        recents.insert(station, at: 0)
        
        let trimmed = Array(recents.prefix(5))
        persistStations(trimmed)
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "DMFMRadioRecentStationsWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    /// Obtiene la lista de emisoras recientes reales guardadas en el App Group (vacía si aún no hay historial)
    public func getRecentStations() -> [RadioStation] {
        if let defaults = sharedDefaults {
            CFPreferencesAppSynchronize(RecentStationsManager.appGroupID as CFString)
            if let data = defaults.data(forKey: RecentStationsManager.recentStationsKey),
               let list = try? JSONDecoder().decode([RadioStation].self, from: data) {
                let realStations = list.filter { isRealStation($0) }
                if !realStations.isEmpty {
                    return realStations
                }
            }
        }
        
        if let fileURL = sharedContainerFileURL,
           let data = try? Data(contentsOf: fileURL),
           let list = try? JSONDecoder().decode([RadioStation].self, from: data) {
            let realStations = list.filter { isRealStation($0) }
            if !realStations.isEmpty {
                return realStations
            }
        }
        
        return []
    }
    
    /// Obtiene la última emisora real reproducida (nil si aún no hay historial)
    public func getLatestStation() -> RadioStation? {
        getRecentStations().first
    }
}

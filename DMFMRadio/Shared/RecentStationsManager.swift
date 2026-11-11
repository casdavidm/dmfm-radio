import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Gestor de sincronización de emisoras recientes compartidas vía App Group con el Widget
public final class RecentStationsManager {
    public static let shared = RecentStationsManager()
    
    /// Identificador del App Group compartido entre App y Widget Extension
    public static let appGroupID = "group.casdavidm.dmfmradio"
    private static let recentStationsKey = "dmfm_recent_stations_v1"
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: RecentStationsManager.appGroupID) ?? .standard
    }
    
    private init() {}
    
    /// Guarda la emisora reproducida al inicio de la lista de recientes y recarga los widgets
    public func saveRecentStation(_ station: RadioStation) {
        var recents = getRecentStations()
        recents.removeAll { $0.id == station.id || $0.streamURL == station.streamURL }
        recents.insert(station, at: 0)
        
        let trimmed = Array(recents.prefix(5))
        if let data = try? JSONEncoder().encode(trimmed) {
            sharedDefaults.set(data, forKey: RecentStationsManager.recentStationsKey)
            sharedDefaults.synchronize()
        }
        
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    /// Obtiene la lista de emisoras recientes guardadas en el App Group
    public func getRecentStations() -> [RadioStation] {
        guard let data = sharedDefaults.data(forKey: RecentStationsManager.recentStationsKey),
              let list = try? JSONDecoder().decode([RadioStation].self, from: data),
              !list.isEmpty else {
            return AppConfig.defaultStations
        }
        return list
    }
    
    /// Obtiene la última emisora reproducida (o la predeterminada)
    public func getLatestStation() -> RadioStation {
        getRecentStations().first ?? AppConfig.defaultStations[0]
    }
}

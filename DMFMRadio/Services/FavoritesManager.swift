import Foundation
import Combine

/// Gestor de persistencia de emisoras favoritas del usuario
@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    private let userDefaultsKey = "DMFM_Favorite_Stations_V1"
    
    @Published private(set) var favoriteStations: [RadioStation] = []
    
    private init() {
        loadFavorites()
    }
    
    func isFavorite(_ station: RadioStation) -> Bool {
        favoriteStations.contains(where: { $0.id == station.id || $0.streamURL == station.streamURL })
    }
    
    func toggleFavorite(_ station: RadioStation) {
        if isFavorite(station) {
            favoriteStations.removeAll(where: { $0.id == station.id || $0.streamURL == station.streamURL })
        } else {
            favoriteStations.append(station)
        }
        saveFavorites()
    }
    
    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(favoriteStations)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Error guardando favoritos: \(error.localizedDescription)")
        }
    }
    
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // Favorito inicial de demostración
            if let first = AppConfig.defaultStations.first {
                self.favoriteStations = [first]
            }
            return
        }
        do {
            self.favoriteStations = try JSONDecoder().decode([RadioStation].self, from: data)
        } catch {
            print("Error cargando favoritos: \(error.localizedDescription)")
            if let first = AppConfig.defaultStations.first {
                self.favoriteStations = [first]
            }
        }
    }
}

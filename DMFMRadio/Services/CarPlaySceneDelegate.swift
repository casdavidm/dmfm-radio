import CarPlay
import UIKit

/// Escena de CarPlay con plantillas de audio: Recientes, Favoritos y Top mundial.
///
/// Requiere el entitlement `com.apple.developer.carplay-audio`, que Apple concede
/// bajo solicitud a cuentas de desarrollador de pago. Sin él, CarPlay no muestra
/// la app, pero el audio y el "Ahora suena" del coche siguen funcionando.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    
    nonisolated func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                              didConnect interfaceController: CPInterfaceController) {
        Task { @MainActor in
            self.interfaceController = interfaceController
            interfaceController.setRootTemplate(makeRootTemplate(), animated: true, completion: nil)
            
            // Al conectar al coche, retomar la última emisora
            RadioPlayer.shared.resumeLastStationIfIdle()
            
            // Asegurar catálogo cargado para la sección Top mundial
            if case .idle = RadioBrowserService.shared.state {
                RadioBrowserService.shared.loadCurrentSelection()
            }
        }
    }
    
    nonisolated func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                              didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        Task { @MainActor in
            self.interfaceController = nil
        }
    }
    
    // MARK: - Plantillas
    
    private func makeRootTemplate() -> CPTemplate {
        let recents = RecentStationsManager.shared.getRecentStations()
        let favorites = FavoritesManager.shared.favoriteStations
        let top = Array(RadioBrowserService.shared.state.stations.prefix(20))
        
        var sections: [CPListSection] = []
        if !recents.isEmpty {
            sections.append(CPListSection(items: recents.map(listItem), header: "Recientes", sectionIndexTitle: nil))
        }
        if !favorites.isEmpty {
            sections.append(CPListSection(items: favorites.map(listItem), header: "Favoritos", sectionIndexTitle: nil))
        }
        if !top.isEmpty {
            sections.append(CPListSection(items: top.map(listItem), header: "Top mundial", sectionIndexTitle: nil))
        }
        if sections.isEmpty {
            let empty = CPListItem(text: "Sin emisoras todavía", detailText: "Escucha una emisora en el iPhone para verla aquí")
            sections = [CPListSection(items: [empty])]
        }
        
        let list = CPListTemplate(title: AppConfig.appName, sections: sections)
        list.tabImage = UIImage(systemName: "dot.radiowaves.left.and.right")
        return list
    }
    
    private func listItem(for station: RadioStation) -> CPListItem {
        let detail = [station.dialFrequencyString, station.country].filter { !$0.isEmpty }.joined(separator: " · ")
        let item = CPListItem(text: station.name, detailText: detail)
        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            Task { @MainActor in
                RadioPlayer.shared.switchStation(to: station)
                self?.interfaceController?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                completion()
            }
        }
        return item
    }
}

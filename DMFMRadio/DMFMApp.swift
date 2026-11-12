import SwiftUI

@main
struct DMFMApp: App {
    init() {
        // Reproducción desde el widget: el sistema ejecuta el intent en este proceso
        // (lanzado en segundo plano si hace falta) sin mostrar la app.
        PlayStationIntent.playHandler = { station in
            let player = RadioPlayer.shared
            let isSameStation = player.currentStation.streamURL == station.streamURL
            if isSameStation && player.state.isPlaying {
                player.pause()
            } else {
                player.switchStation(to: station)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

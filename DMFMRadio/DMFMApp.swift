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
        
        // Play / pausa desde la Live Activity (Dynamic Island y pantalla de bloqueo)
        TogglePlaybackIntent.toggleHandler = {
            RadioPlayer.shared.togglePlayPause()
        }
        
        // Live Activity sincronizada con el reproductor
        LiveActivityManager.shared.start(observing: RadioPlayer.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

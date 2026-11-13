import ActivityKit
import Foundation

/// Atributos de la Live Activity de reproducción (Dynamic Island y pantalla de bloqueo).
/// Se compila en la app (que la inicia y actualiza) y en la extensión (que la dibuja).
struct RadioActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stationName: String
        var frequency: Double
        var isPlaying: Bool
        var isBuffering: Bool
        var trackTitle: String
        var country: String
        
        var frequencyText: String {
            String(format: "%.1f", frequency)
        }
        
        var statusText: String {
            if isBuffering { return "Sintonizando…" }
            if isPlaying { return trackTitle.isEmpty ? "En vivo" : trackTitle }
            return "En pausa"
        }
    }
    
    var startedAt: Date
}

import AppIntents
import Foundation

/// Intent de reproducción invocado desde los botones del widget.
///
/// Al conformar a `AudioPlaybackIntent`, el sistema lanza la app en segundo plano
/// y ejecuta `perform()` dentro de su proceso sin traerla al frente, lo que permite
/// iniciar el audio directamente desde el widget.
///
/// Este archivo se compila en la app y en la extensión del widget. Solo la app
/// registra `playHandler`; en la extensión permanece `nil` y `perform()` no hace nada.
struct PlayStationIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Reproducir emisora"
    static var description = IntentDescription("Sintoniza una emisora reciente de DM/FM Radio sin abrir la app.")
    
    /// Emisora codificada en JSON para atravesar el límite entre procesos
    @Parameter(title: "Emisora")
    var stationJSON: String
    
    /// Manejador que la app registra al arrancar
    @MainActor static var playHandler: ((RadioStation) -> Void)?
    
    init() {
        stationJSON = ""
    }
    
    init(station: RadioStation) {
        let data = (try? JSONEncoder().encode(station)) ?? Data()
        stationJSON = String(decoding: data, as: UTF8.self)
    }
    
    func perform() async throws -> some IntentResult {
        guard let data = stationJSON.data(using: .utf8),
              let station = try? JSONDecoder().decode(RadioStation.self, from: data),
              !station.isPlaceholder else {
            return .result()
        }
        
        await MainActor.run {
            PlayStationIntent.playHandler?(station)
        }
        return .result()
    }
}

/// Alterna reproducción / pausa de la emisora actual desde la Live Activity.
struct TogglePlaybackIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Reproducir o pausar"
    static var description = IntentDescription("Alterna la reproducción de DM/FM Radio.")
    
    /// Manejador que la app registra al arrancar
    @MainActor static var toggleHandler: (() -> Void)?
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TogglePlaybackIntent.toggleHandler?()
        }
        return .result()
    }
}

import Foundation

/// Estructura de estación de radio para DM/FM
struct RadioStation: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let subtitle: String
    let streamURL: String
    let genre: String
    let bitrate: String
}

/// Configuración general de DM/FM Radio
enum AppConfig {
    /// Nombre principal de la emisora
    static let appName = "DM/FM Radio"
    
    /// Slogan o descripción de la radio
    static let appTagline = "Tu música favorita transmitiendo en vivo 24/7"
    
    /// Estación predeterminada (Stream de demostración de alta disponibilidad)
    /// Puedes cambiar esta URL por la de tu servidor Icecast / Shoutcast / HLS
    static let defaultStreamURL = "https://ice1.somafm.com/groovesalad-128-mp3"
    
    /// Lista de estaciones / canales disponibles de DM/FM
    static let defaultStations: [RadioStation] = [
        RadioStation(
            name: "DM/FM Principal",
            subtitle: "La mejor selección musical en vivo",
            streamURL: "https://ice1.somafm.com/groovesalad-128-mp3",
            genre: "Éxitos & Variedad",
            bitrate: "128 kbps MP3"
        ),
        RadioStation(
            name: "DM/FM Hits",
            subtitle: "Top 40 y tendencias globales",
            streamURL: "https://ice2.somafm.com/poptron-128-mp3",
            genre: "Pop / Hits",
            bitrate: "128 kbps MP3"
        ),
        RadioStation(
            name: "DM/FM Lounge & Chill",
            subtitle: "Sonidos relajantes para tu día",
            streamURL: "https://ice4.somafm.com/secretagent-128-mp3",
            genre: "Chillout / Downtempo",
            bitrate: "128 kbps MP3"
        ),
        RadioStation(
            name: "DM/FM Rock & Classics",
            subtitle: "Clásicos legendarios de todos los tiempos",
            streamURL: "https://ice6.somafm.com/7soul-128-mp3",
            genre: "Rock & Classic Soul",
            bitrate: "128 kbps MP3"
        )
    ]
}


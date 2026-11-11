import Foundation

/// Estructura de estación de radio para DM/FM
struct RadioStation: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let subtitle: String
    let streamURL: String
    let genre: String
    let bitrate: String
    let country: String
    let countryCode: String
    let codec: String
    let faviconURL: String?
    
    init(
        id: String? = nil,
        name: String,
        subtitle: String = "",
        streamURL: String,
        genre: String = "En vivo",
        bitrate: String = "128 kbps",
        country: String = "",
        countryCode: String = "",
        codec: String = "MP3",
        faviconURL: String? = nil
    ) {
        self.id = id ?? streamURL
        self.name = name
        self.subtitle = subtitle.isEmpty ? (country.isEmpty ? "Radio en Vivo" : country) : subtitle
        self.streamURL = streamURL
        self.genre = genre
        self.bitrate = bitrate
        self.country = country
        self.countryCode = countryCode
        self.codec = codec
        self.faviconURL = faviconURL
    }
    
    /// Frecuencia simulada de dial FM (entre 88.0 y 107.9 MHz) basada en el hash de la emisora
    var dialFrequency: Double {
        let hashValue = abs(name.hashValue ^ streamURL.hashValue)
        let step = Double(hashValue % 200) / 10.0 // 0.0 a 19.9
        return 88.0 + step
    }
    
    var dialFrequencyString: String {
        String(format: "%.1f FM", dialFrequency)
    }
}

/// Configuración general de DM/FM Radio
enum AppConfig {
    /// Nombre principal de la emisora
    static let appName = "DM/FM Radio"
    
    /// Slogan o descripción de la radio
    static let appTagline = "Base de datos mundial de emisoras en vivo"
    
    /// Estación predeterminada (Stream de demostración de alta disponibilidad)
    static let defaultStreamURL = "https://ice1.somafm.com/groovesalad-128-mp3"
    
    /// Lista de estaciones iniciales / canales destacados de DM/FM
    static let defaultStations: [RadioStation] = [
        RadioStation(
            id: "dmfm-main",
            name: "DM/FM Principal",
            subtitle: "La mejor selección musical en vivo",
            streamURL: "https://ice1.somafm.com/groovesalad-128-mp3",
            genre: "Éxitos & Variedad",
            bitrate: "128 kbps MP3",
            country: "Mundial",
            countryCode: "WW",
            codec: "MP3"
        ),
        RadioStation(
            id: "dmfm-hits",
            name: "DM/FM Hits Global",
            subtitle: "Top 40 y tendencias globales",
            streamURL: "https://ice2.somafm.com/poptron-128-mp3",
            genre: "Pop / Hits",
            bitrate: "128 kbps MP3",
            country: "Mundial",
            countryCode: "WW",
            codec: "MP3"
        ),
        RadioStation(
            id: "dmfm-chill",
            name: "DM/FM Lounge & Chill",
            subtitle: "Sonidos relajantes para tu día",
            streamURL: "https://ice4.somafm.com/secretagent-128-mp3",
            genre: "Chillout / Downtempo",
            bitrate: "128 kbps MP3",
            country: "Mundial",
            countryCode: "WW",
            codec: "MP3"
        ),
        RadioStation(
            id: "dmfm-rock",
            name: "DM/FM Rock & Classics",
            subtitle: "Clásicos legendarios de todos los tiempos",
            streamURL: "https://ice6.somafm.com/7soul-128-mp3",
            genre: "Rock & Classic Soul",
            bitrate: "128 kbps MP3",
            country: "Mundial",
            countryCode: "WW",
            codec: "MP3"
        )
    ]
}

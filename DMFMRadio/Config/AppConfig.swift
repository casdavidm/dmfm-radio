import Foundation

/// Estructura de estación de radio para DM/FM
public struct RadioStation: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let streamURL: String
    public let genre: String
    public let bitrate: String
    public let country: String
    public let countryCode: String
    public let codec: String
    public let faviconURL: String?
    
    public init(
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
    public var dialFrequency: Double {
        let hashValue = abs(name.hashValue ^ streamURL.hashValue)
        let step = Double(hashValue % 200) / 10.0 // 0.0 a 19.9
        return 88.0 + step
    }
    
    public var dialFrequencyString: String {
        String(format: "%.1f FM", dialFrequency)
    }
    
    /// URL para Deeplink hacia la app principal
    public var deeplinkURL: URL? {
        var components = URLComponents()
        components.scheme = "dmfm"
        components.host = "play"
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "stream", value: streamURL),
            URLQueryItem(name: "subtitle", value: subtitle),
            URLQueryItem(name: "genre", value: genre),
            URLQueryItem(name: "bitrate", value: bitrate),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "countryCode", value: countryCode),
            URLQueryItem(name: "codec", value: codec)
        ]
        return components.url
    }
}

/// Configuración general de DM/FM Radio
public enum AppConfig {
    /// Nombre principal de la emisora
    public static let appName = "DM/FM Radio"
    
    /// Slogan o descripción de la radio
    public static let appTagline = "Base de datos mundial de emisoras en vivo"
    
    /// Estación predeterminada (Stream de demostración de alta disponibilidad)
    public static let defaultStreamURL = "https://ice1.somafm.com/groovesalad-128-mp3"
    
    /// Lista de estaciones iniciales / canales destacados de DM/FM
    public static let defaultStations: [RadioStation] = [
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

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
    
    /// Indica si es una estación de estado vacío (no reproducible)
    public var isPlaceholder: Bool {
        id == "dmfm-placeholder" || streamURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Frecuencia simulada de dial FM (entre 88.0 y 107.9 MHz) estable entre arranques.
    /// Usa FNV-1a en lugar de `hashValue`, que Swift aleatoriza en cada proceso.
    public var dialFrequency: Double {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in (streamURL.isEmpty ? name : streamURL).utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let step = Double(hash % 200) / 10.0 // 0.0 a 19.9
        return 88.0 + step
    }
    
    public var dialFrequencyString: String {
        if isPlaceholder {
            return "--.- FM"
        }
        return String(format: "%.1f FM", dialFrequency)
    }
    
    /// URL para Deeplink hacia la app principal
    public var deeplinkURL: URL? {
        guard !isPlaceholder else { return URL(string: "dmfm://open") }
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
    
    /// Estación inicial vacía mientras el usuario selecciona una emisora real
    public static let placeholderStation = RadioStation(
        id: "dmfm-placeholder",
        name: "Selecciona una emisora",
        subtitle: "Escucha una emisora para verla aquí",
        streamURL: "",
        genre: "En vivo",
        bitrate: "--- kbps",
        country: "",
        countryCode: "",
        codec: "AAC"
    )
    
    /// Sin emisoras de relleno
    public static let defaultStations: [RadioStation] = []
}

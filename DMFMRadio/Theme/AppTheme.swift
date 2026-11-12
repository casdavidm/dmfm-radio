import SwiftUI

/// Paleta de colores estricta de DM/FM Radio
extension Color {
    /// Fondo principal: Azul oscuro #111827
    public static let appBackground = Color(red: 17/255, green: 24/255, blue: 39/255)
    
    /// Contenedores y tarjetas: #1F2937
    public static let appCard = Color(red: 31/255, green: 41/255, blue: 55/255)
    
    /// Borde sutil para tarjetas y divisores: #374151
    public static let appBorder = Color(red: 55/255, green: 65/255, blue: 81/255)
    
    /// Acento y elementos activos: Amarillo #ffc61a
    public static let appAccent = Color(red: 255/255, green: 198/255, blue: 26/255)
    
    /// Tipografía principal: Blanco #ffffff
    public static let appTextPrimary = Color.white
    
    /// Tipografía secundaria y diales: Gris #9CA3AF
    public static let appTextSecondary = Color(red: 156/255, green: 163/255, blue: 175/255)
}

// MARK: - Tipografía retro-moderna

extension Font {
    /// Tipografía condensada estilo dial de radio clásica
    static func retro(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight).width(.condensed)
    }
}

// MARK: - Formas auxiliares

/// Triángulo apuntando hacia arriba (aguja del dial)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

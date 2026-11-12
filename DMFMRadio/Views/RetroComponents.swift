import SwiftUI

// MARK: - Modificadores neumórficos (relieve e inserción) sobre la paleta oscura

/// Superficie en relieve: luz suave arriba-izquierda y sombra profunda abajo-derecha
struct NeumorphicRaised<S: InsettableShape>: ViewModifier {
    let shape: S
    var fill: Color = .appCard
    var shadowRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                shape
                    .fill(fill)
                    .shadow(color: Color.black.opacity(0.55), radius: shadowRadius, x: shadowRadius * 0.6, y: shadowRadius * 0.6)
                    .shadow(color: Color.white.opacity(0.06), radius: shadowRadius * 0.8, x: -shadowRadius * 0.4, y: -shadowRadius * 0.4)
            )
            .overlay(shape.strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
    }
}

/// Superficie hundida: sombra interior que simula una pista o un plato de dial
struct NeumorphicInset<S: InsettableShape>: ViewModifier {
    let shape: S
    var fill: Color = .appBackground
    
    func body(content: Content) -> some View {
        content
            .background(
                shape.fill(
                    fill
                        .shadow(.inner(color: Color.black.opacity(0.65), radius: 6, x: 4, y: 4))
                        .shadow(.inner(color: Color.white.opacity(0.05), radius: 6, x: -3, y: -3))
                )
            )
            .overlay(shape.strokeBorder(Color.appBorder.opacity(0.5), lineWidth: 1))
    }
}

extension View {
    func neumorphicRaised<S: InsettableShape>(_ shape: S, fill: Color = .appCard, shadowRadius: CGFloat = 10) -> some View {
        modifier(NeumorphicRaised(shape: shape, fill: fill, shadowRadius: shadowRadius))
    }
    
    func neumorphicInset<S: InsettableShape>(_ shape: S, fill: Color = .appBackground) -> some View {
        modifier(NeumorphicInset(shape: shape, fill: fill))
    }
}

// MARK: - Rejilla de altavoz circular

/// Círculo en relieve con rayas horizontales, como la rejilla de una radio clásica
struct SpeakerGrilleView: View {
    var size: CGFloat
    var stripeSpacing: CGFloat = 7
    var stripeHeight: CGFloat = 3
    
    private var stripeCount: Int {
        max(1, Int(size / (stripeSpacing + stripeHeight)))
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appCard)
                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 12, y: 14)
                .shadow(color: Color.white.opacity(0.05), radius: 14, x: -8, y: -8)
            
            VStack(spacing: stripeSpacing) {
                ForEach(0..<stripeCount, id: \.self) { _ in
                    Capsule()
                        .fill(Color.appBackground)
                        .frame(height: stripeHeight)
                }
            }
            .frame(width: size * 0.92, height: size * 0.92)
            .clipShape(Circle())
            
            Circle()
                .strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Píldora de estado "En vivo"

struct LiveBadge: View {
    let isPlaying: Bool
    let isBuffering: Bool
    
    private var label: String {
        if isBuffering { return "Sintonizando" }
        return isPlaying ? "En vivo" : "En pausa"
    }
    
    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(isPlaying ? Color.appAccent.opacity(0.35) : Color.clear)
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(isPlaying || isBuffering ? Color.appAccent : Color.appTextSecondary.opacity(0.6))
                    .frame(width: 8, height: 8)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.appTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .neumorphicRaised(Capsule(), shadowRadius: 6)
    }
}

// MARK: - Cabecera: menú · logo · estado

struct RetroHeader: View {
    let isLive: Bool
    let onMenu: () -> Void
    let onStatus: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onMenu) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .neumorphicRaised(Circle(), shadowRadius: 7)
            .accessibilityLabel("Ajustes")
            
            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .accessibilityLabel(AppConfig.appName)
            
            Spacer()
            
            Button(action: onStatus) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isLive ? Color.appBackground : Color.appTextSecondary)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .neumorphicRaised(Circle(), fill: isLive ? Color.appAccent : Color.appCard, shadowRadius: 7)
            .accessibilityLabel(isLive ? "Reproduciendo" : "Reproductor")
        }
    }
}

// MARK: - Barra de pestañas inferior

enum AppTab: CaseIterable {
    case home
    case radio
    case favorites
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .radio: return "dot.radiowaves.left.and.right"
        case .favorites: return "headphones"
        }
    }
    
    var title: String {
        switch self {
        case .home: return "Inicio"
        case .radio: return "Radio"
        case .favorites: return "Favoritos"
        }
    }
}

struct RetroTabBar: View {
    @Binding var selected: AppTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                let isSelected = selected == tab
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selected = tab
                    }
                }) {
                    VStack(spacing: 7) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 21, weight: .regular))
                            .foregroundColor(isSelected ? Color.appAccent : Color.appTextSecondary)
                        
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 5, height: 5)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 10)
        .padding(.horizontal, 24)
        .background(
            Capsule(style: .continuous)
                .fill(Color.appCard)
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1)
        )
    }
}

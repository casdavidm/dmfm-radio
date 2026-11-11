import SwiftUI

/// Vista minimalista de disco de vinilo estilizado para DM/FM Radio
struct VinylDiscView: View {
    let isPlaying: Bool
    var size: CGFloat = 200
    
    var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let seconds = timeline.date.timeIntervalSinceReferenceDate
            let angle = (seconds.truncatingRemainder(dividingBy: 8.0) / 8.0) * 360.0
            
            discBody
                .rotationEffect(.degrees(isPlaying ? angle : 0))
        }
    }
    
    private var discBody: some View {
        ZStack {
            // Sombra ambiental suave
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: size, height: size)
                .blur(radius: 12)
            
            // Cuerpo del vinilo (negro mate con borde sutil)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.16),
                            Color(red: 0.05, green: 0.06, blue: 0.09)
                        ],
                        center: .center,
                        startRadius: size * 0.15,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.appBorder.opacity(0.4), lineWidth: 1.5)
                )
            
            // Surcos concéntricos del vinilo
            ForEach(1...5, id: \.self) { ring in
                let ringRatio = 0.28 + (Double(ring) * 0.11)
                Circle()
                    .stroke(
                        Color.white.opacity(0.04 + (Double(ring % 2) * 0.02)),
                        lineWidth: 1
                    )
                    .frame(width: size * ringRatio, height: size * ringRatio)
            }
            
            // Reflejo de luz diagonal sobre los surcos
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.0)
                        ]),
                        center: .center
                    )
                )
                .frame(width: size * 0.94, height: size * 0.94)
            
            // Etiqueta central del vinilo en Amarillo #ffc61a
            Circle()
                .fill(Color.appAccent)
                .frame(width: size * 0.35, height: size * 0.35)
                .shadow(color: Color.black.opacity(0.3), radius: 3)
            
            // Anillo interior de la etiqueta
            Circle()
                .stroke(Color.appBackground.opacity(0.25), lineWidth: 1.5)
                .frame(width: size * 0.30, height: size * 0.30)
            
            // Texto minimalista DM/FM en la etiqueta
            VStack(spacing: 1) {
                Text("DM/FM")
                    .font(.system(size: size * 0.07, weight: .black, design: .monospaced))
                    .foregroundColor(Color.appBackground)
                
                Text("LIVE")
                    .font(.system(size: size * 0.038, weight: .bold))
                    .foregroundColor(Color.appBackground.opacity(0.8))
            }
            
            // Orificio central del eje
            Circle()
                .fill(Color.appBackground)
                .frame(width: size * 0.08, height: size * 0.08)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.6), lineWidth: 1)
                )
        }
    }
}

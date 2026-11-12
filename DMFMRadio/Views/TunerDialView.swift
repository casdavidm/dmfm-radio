import SwiftUI

/// Dial de sintonía circular estilo radio clásica: escala 88–108 MHz, puntos, aguja amarilla
/// y frecuencia con nombre de emisora en el centro.
struct TunerDialView: View {
    /// Frecuencia simulada; `nil` cuando no hay emisora seleccionada
    let frequency: Double?
    let stationName: String
    let isPlaying: Bool
    var size: CGFloat = 180
    
    private let minFrequency = 88.0
    private let frequencySpan = 20.0
    
    /// Versión compacta (mini reproductor, tarjetas): sin etiquetas numéricas
    private var isCompact: Bool { size < 90 }
    
    private var radius: CGFloat { size / 2 }
    private var dotCount: Int { isCompact ? 24 : 40 }
    
    private var pointerAngle: Angle {
        let clamped = min(max(frequency ?? minFrequency, minFrequency), minFrequency + frequencySpan)
        return .degrees((clamped - minFrequency) / frequencySpan * 360 - 90)
    }
    
    private var frequencyText: String {
        guard let frequency = frequency else { return "--.-" }
        return String(format: "%.1f", frequency)
    }
    
    var body: some View {
        ZStack {
            // Plato hundido del dial
            Circle()
                .fill(
                    Color.appBackground
                        .shadow(.inner(color: Color.black.opacity(0.7), radius: size * 0.05, x: size * 0.03, y: size * 0.03))
                        .shadow(.inner(color: Color.white.opacity(0.06), radius: size * 0.04, x: -size * 0.02, y: -size * 0.02))
                )
            
            Circle()
                .strokeBorder(Color.appBorder.opacity(0.6), lineWidth: 1)
            
            // Anillo de puntos
            ForEach(0..<dotCount, id: \.self) { index in
                let angle = Double(index) / Double(dotCount) * 360 - 90
                let isMajor = index % 4 == 0
                let dotRadius = radius * (isCompact ? 0.86 : 0.66)
                
                Circle()
                    .fill(isMajor ? Color.appTextSecondary : Color.appTextSecondary.opacity(0.4))
                    .frame(width: isMajor ? size * 0.02 : size * 0.013, height: isMajor ? size * 0.02 : size * 0.013)
                    .offset(x: cos(angle * .pi / 180) * dotRadius, y: sin(angle * .pi / 180) * dotRadius)
            }
            
            // Etiquetas de frecuencia 88 · 90 · … · 106
            if !isCompact {
                ForEach(0..<10, id: \.self) { index in
                    let angle = Double(index) / 10 * 360 - 90
                    let labelRadius = radius * 0.85
                    let isBottomHalf = angle > 0 && angle < 180
                    
                    Text("\(88 + index * 2)")
                        .font(.retro(size * 0.075, weight: .semibold))
                        .foregroundColor(Color.appTextSecondary)
                        .rotationEffect(.degrees(isBottomHalf ? angle - 90 : angle + 90))
                        .offset(x: cos(angle * .pi / 180) * labelRadius, y: sin(angle * .pi / 180) * labelRadius)
                }
            }
            
            // Aguja indicadora amarilla
            if frequency != nil {
                Triangle()
                    .fill(Color.appAccent)
                    .frame(width: size * (isCompact ? 0.12 : 0.06), height: size * (isCompact ? 0.1 : 0.055))
                    .shadow(color: Color.appAccent.opacity(0.7), radius: 3)
                    .offset(y: -radius * (isCompact ? 0.86 : 0.55))
                    .rotationEffect(pointerAngle + .degrees(90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: frequency)
            }
            
            // Frecuencia y emisora en el centro
            VStack(spacing: isCompact ? 0 : 2) {
                Text(frequencyText)
                    .font(.retro(size * (isCompact ? 0.26 : 0.2)))
                    .foregroundColor(Color.appTextPrimary)
                    .monospacedDigit()
                
                if !isCompact {
                    Text(stationName.uppercased())
                        .font(.retro(size * 0.075, weight: .semibold))
                        .foregroundColor(Color.appAccent)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: size * 0.5)
                    
                    Text("FM")
                        .font(.system(size: size * 0.05, weight: .bold))
                        .foregroundColor(Color.appTextSecondary.opacity(0.8))
                        .padding(.top, 2)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(frequencyText) FM, \(stationName)")
    }
}

import SwiftUI

/// Vista animada de visualizador de ondas de audio
struct VisualizerView: View {
    let isPlaying: Bool
    let barCount: Int = 18
    
    @State private var barHeights: [CGFloat] = Array(repeating: 0.15, count: 18)
    @State private var timer: Timer?
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.75, blue: 1.0),
                                Color(red: 0.85, green: 0.20, blue: 0.95)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 5,
                        height: max(6, barHeights[index] * 48)
                    )
                    .animation(
                        .easeInOut(duration: 0.25),
                        value: barHeights[index]
                    )
            }
        }
        .frame(height: 52)
        .padding(.horizontal)
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: isPlaying) { _ in
            updateAnimationState()
        }
    }
    
    private func updateAnimationState() {
        timer?.invalidate()
        if isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { _ in
                withAnimation {
                    self.barHeights = (0..<barCount).map { index in
                        // Generar alturas orgánicas simulando espectro de audio
                        let mid = Double(barCount) / 2.0
                        let dist = abs(Double(index) - mid) / mid
                        let factor = max(0.2, 1.0 - (dist * 0.4))
                        return CGFloat(Double.random(in: 0.2...1.0) * factor)
                    }
                }
            }
        } else {
            withAnimation {
                self.barHeights = Array(repeating: 0.12, count: barCount)
            }
        }
    }
}

import SwiftUI
import Foundation

/// Modelo observable para las barras de visualización de audio
@MainActor
final class VisualizerModel: ObservableObject {
    @Published var barHeights: [CGFloat] = Array(repeating: 0.15, count: 18)
    private var timer: Timer?
    
    func update(isPlaying: Bool) {
        timer?.invalidate()
        timer = nil
        
        if isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: 0.22, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.barHeights = (0..<18).map { index in
                            let mid = 9.0
                            let dist = abs(Double(index) - mid) / mid
                            let factor = max(0.2, 1.0 - (dist * 0.4))
                            return CGFloat(Double.random(in: 0.2...1.0) * factor)
                        }
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.barHeights = Array(repeating: 0.12, count: 18)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

/// Vista animada de visualizador de ondas de audio
struct VisualizerView: View {
    let isPlaying: Bool
    @StateObject private var model = VisualizerModel()
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(0..<18, id: \.self) { index in
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
                        height: max(6, model.barHeights[index] * 48)
                    )
            }
        }
        .frame(height: 52)
        .padding(.horizontal)
        .onAppear {
            model.update(isPlaying: isPlaying)
        }
        .onChange(of: isPlaying) { playing in
            model.update(isPlaying: playing)
        }
    }
}

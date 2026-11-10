import SwiftUI
import UIKit

/// Controles de reproducción y volumen
struct PlayerControlsView: View {
    @ObservedObject var player: RadioPlayer
    
    var body: some View {
        VStack(spacing: 24) {
            // Botón principal de Reproducción / Pausa
            HStack(spacing: 36) {
                // Botón silenciar / desmutear
                Button(action: {
                    triggerHaptic()
                    player.isMuted.toggle()
                }) {
                    Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(player.isMuted ? .red : .white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                
                // Botón central principal
                Button(action: {
                    triggerHaptic(style: .heavy)
                    player.togglePlayPause()
                }) {
                    ZStack {
                        // Halo brillante al reproducir
                        if player.state.isPlaying {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.10, green: 0.75, blue: 1.0).opacity(0.55),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 25,
                                        endRadius: 55
                                    )
                                )
                                .frame(width: 110, height: 110)
                        }
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.10, green: 0.75, blue: 1.0),
                                        Color(red: 0.85, green: 0.20, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(red: 0.85, green: 0.20, blue: 0.95).opacity(0.5), radius: 15, x: 0, y: 8)
                        
                        if player.state.isBuffering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.3)
                        } else {
                            Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: player.state.isPlaying ? 0 : 2)
                        }
                    }
                }
                
                // Botón detener (Stop)
                Button(action: {
                    triggerHaptic()
                    player.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
            }
            
            // Slider de Volumen
            HStack(spacing: 14) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                Slider(
                    value: Binding(
                        get: { Double(player.volume) },
                        set: {
                            player.volume = Float($0)
                            if player.isMuted && $0 > 0.05 {
                                player.isMuted = false
                            }
                        }
                    ),
                    in: 0.0...1.0
                )
                .accentColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                
                Image(systemName: "speaker.3.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 32)
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}


import SwiftUI

/// Mini-reproductor persistente en la parte inferior de la pantalla
struct PersistentMiniPlayerView: View {
    @ObservedObject var player: RadioPlayer
    let onOpenFullPlayer: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Mini Vinilo Giratorio
            VinylDiscView(isPlaying: player.state.isPlaying, size: 44)
            
            // MARK: - Información de Emisora y Metadatos
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.currentStation.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(1)
                    
                    Text(player.currentStation.dialFrequencyString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.appBackground)
                        .cornerRadius(4)
                }
                
                if player.state.isBuffering {
                    HStack(spacing: 4) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                            .scaleEffect(0.6)
                        
                        Text("Sintonizando señal...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                } else if player.state.isPlaying {
                    Text(player.trackTitle.isEmpty ? player.currentStation.subtitle : player.trackTitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(1)
                } else {
                    Text(player.state == .paused ? "En pausa" : "Listo para reproducir")
                        .font(.system(size: 11))
                        .foregroundColor(Color.appTextSecondary.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 4)
            
            // MARK: - Botón Circular Play/Pause en Amarillo #ffc61a
            Button(action: {
                player.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.appAccent.opacity(0.35), radius: 6, x: 0, y: 2)
                    
                    if player.state.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.appBackground)
                            .offset(x: player.state.isPlaying ? 0 : 1.5)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenFullPlayer()
        }
    }
}

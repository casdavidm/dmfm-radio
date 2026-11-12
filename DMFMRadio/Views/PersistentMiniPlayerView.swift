import SwiftUI

/// Mini-reproductor persistente sobre la barra de pestañas
struct PersistentMiniPlayerView: View {
    @ObservedObject var player: RadioPlayer
    let onOpenFullPlayer: () -> Void
    
    private var station: RadioStation { player.currentStation }
    
    var body: some View {
        HStack(spacing: 14) {
            // MARK: - Mini dial
            TunerDialView(
                frequency: station.isPlaceholder ? nil : station.dialFrequency,
                stationName: station.name,
                isPlaying: player.state.isPlaying,
                size: 50
            )
            
            // MARK: - Emisora y estado
            VStack(alignment: .leading, spacing: 3) {
                Text(station.name)
                    .font(.retro(17))
                    .foregroundColor(Color.appBackground)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.appBackground.opacity(player.state.isPlaying || player.state.isBuffering ? 1 : 0.4))
                        .frame(width: 6, height: 6)
                    
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.appBackground.opacity(0.75))
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 4)
            
            // MARK: - Play / Pausa
            Button(action: {
                hapticTap(.medium)
                player.togglePlayPause()
            }) {
                ZStack {
                    if player.state.isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(Color.appAccent)
                            .offset(x: player.state.isPlaying ? 0 : 1.5)
                    }
                }
                .frame(width: 46, height: 46)
            }
            .buttonStyle(.plain)
            .background(
                Circle()
                    .fill(Color.appBackground)
                    .shadow(color: Color.black.opacity(0.35), radius: 6, x: 3, y: 3)
            )
            .accessibilityLabel(player.state.isPlaying ? "Pausar" : "Reproducir")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.appAccent)
                .shadow(color: Color.black.opacity(0.6), radius: 14, x: 0, y: 8)
                .shadow(color: Color.appAccent.opacity(0.25), radius: 18, x: 0, y: 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenFullPlayer()
        }
    }
    
    private var statusText: String {
        if player.state.isBuffering { return "Sintonizando señal…" }
        if player.state.isPlaying {
            return player.trackTitle.isEmpty ? station.subtitle : player.trackTitle
        }
        return player.state == .paused ? "En pausa" : "Listo para reproducir"
    }
}

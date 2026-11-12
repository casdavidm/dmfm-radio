import SwiftUI
import UIKit

/// Pestaña "Radio": rejilla de altavoz con dial de sintonía, controles neumórficos y volumen
struct RadioTunerView: View {
    @ObservedObject var player: RadioPlayer
    @ObservedObject var browserService: RadioBrowserService
    @ObservedObject var favoritesManager: FavoritesManager
    let onOpenNowPlaying: () -> Void
    
    private var station: RadioStation { player.currentStation }
    
    /// Lista por la que se navega con anterior/siguiente: resultados cargados o, si no hay, favoritos
    private var playlist: [RadioStation] {
        let loaded = browserService.state.stations
        return loaded.isEmpty ? favoritesManager.favoriteStations : loaded
    }
    
    private var currentIndex: Int? {
        playlist.firstIndex { $0.id == station.id || (!station.streamURL.isEmpty && $0.streamURL == station.streamURL) }
    }
    
    private var canSkip: Bool {
        playlist.count > 1 || (playlist.count == 1 && currentIndex == nil)
    }
    
    var body: some View {
        GeometryReader { geo in
            let grilleSize = min(geo.size.width - 64, geo.size.height * 0.48, 330)
            
            VStack(spacing: 0) {
                // MARK: - Estado
                HStack {
                    Text("AHORA SUENA")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color.appTextSecondary)
                    
                    Spacer()
                    
                    LiveBadge(isPlaying: player.state.isPlaying, isBuffering: player.state.isBuffering)
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
                
                Spacer(minLength: 12)
                
                // MARK: - Rejilla + Dial
                Button(action: onOpenNowPlaying) {
                    ZStack {
                        SpeakerGrilleView(size: grilleSize)
                        
                        TunerDialView(
                            frequency: station.isPlaceholder ? nil : station.dialFrequency,
                            stationName: station.isPlaceholder ? "Elige una emisora" : station.name,
                            isPlaying: player.state.isPlaying,
                            size: grilleSize * 0.56
                        )
                    }
                }
                .buttonStyle(.plain)
                .disabled(station.isPlaceholder)
                .accessibilityHint("Abre la vista de reproducción")
                
                Spacer(minLength: 12)
                
                // MARK: - Información
                VStack(spacing: 5) {
                    Text(station.isPlaceholder ? "Sin emisora seleccionada" : station.name)
                        .font(.retro(22))
                        .foregroundColor(Color.appTextPrimary)
                        .lineLimit(1)
                    
                    Text(subtitleText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 28)
                
                Spacer(minLength: 16)
                
                // MARK: - Controles
                PlayerControlsView(
                    player: player,
                    skipEnabled: canSkip,
                    onPrevious: { skip(-1) },
                    onNext: { skip(1) }
                )
                
                Spacer(minLength: 16)
                
                // MARK: - Volumen
                RetroVolumeSlider(volume: $player.volume, isMuted: $player.isMuted)
                    .padding(.horizontal, 36)
                
                Spacer(minLength: 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    private var subtitleText: String {
        if station.isPlaceholder { return "Explora emisoras en Inicio" }
        if player.state.isBuffering { return "Sintonizando señal…" }
        if player.state.isPlaying && !player.trackTitle.isEmpty { return player.trackTitle }
        let parts = [station.country, station.genre].filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
    
    private func skip(_ delta: Int) {
        guard !playlist.isEmpty else { return }
        let target: Int
        if let index = currentIndex {
            target = (index + delta + playlist.count) % playlist.count
        } else {
            target = delta > 0 ? 0 : playlist.count - 1
        }
        hapticTap()
        player.switchStation(to: playlist[target])
    }
}

// MARK: - Controles anterior / play-pausa / siguiente sobre una pista hundida

struct PlayerControlsView: View {
    @ObservedObject var player: RadioPlayer
    var skipEnabled: Bool = true
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    Color.appBackground
                        .shadow(.inner(color: Color.black.opacity(0.7), radius: 8, x: 4, y: 4))
                        .shadow(.inner(color: Color.white.opacity(0.05), radius: 6, x: -3, y: -3))
                )
                .frame(width: 236, height: 64)
            
            HStack(spacing: 0) {
                sideButton(icon: "backward.fill", action: onPrevious, label: "Emisora anterior")
                
                Spacer()
                
                Button(action: {
                    hapticTap(.medium)
                    player.togglePlayPause()
                }) {
                    ZStack {
                        if player.state.isBuffering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color.appBackground)
                                .offset(x: player.state.isPlaying ? 0 : 2)
                        }
                    }
                    .frame(width: 84, height: 84)
                }
                .buttonStyle(.plain)
                .neumorphicRaised(Circle(), fill: Color.appAccent, shadowRadius: 12)
                .disabled(player.currentStation.isPlaceholder)
                .opacity(player.currentStation.isPlaceholder ? 0.5 : 1)
                .accessibilityLabel(player.state.isPlaying ? "Pausar" : "Reproducir")
                
                Spacer()
                
                sideButton(icon: "forward.fill", action: onNext, label: "Emisora siguiente")
            }
            .frame(width: 290)
        }
    }
    
    private func sideButton(icon: String, action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
                .frame(width: 58, height: 58)
        }
        .buttonStyle(.plain)
        .neumorphicRaised(Circle(), shadowRadius: 8)
        .disabled(!skipEnabled)
        .opacity(skipEnabled ? 1 : 0.45)
        .accessibilityLabel(label)
    }
}

// MARK: - Deslizador de volumen con – y +

struct RetroVolumeSlider: View {
    @Binding var volume: Float
    @Binding var isMuted: Bool
    
    private var level: CGFloat { CGFloat(isMuted ? 0 : volume) }
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { adjust(-0.1) }) {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bajar volumen")
            
            GeometryReader { geo in
                let width = geo.size.width
                let thumbX = max(0, min(width, width * level))
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appBorder)
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.appAccent)
                        .frame(width: thumbX, height: 4)
                    
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 22, height: 22)
                        .shadow(color: Color.black.opacity(0.5), radius: 5, x: 2, y: 3)
                        .overlay(Circle().strokeBorder(Color.appBackground.opacity(0.4), lineWidth: 1))
                        .offset(x: thumbX - 11)
                }
                .frame(height: 22)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newLevel = Float(max(0, min(1, value.location.x / width)))
                            if isMuted && newLevel > 0 { isMuted = false }
                            volume = newLevel
                        }
                )
            }
            .frame(height: 22)
            
            Button(action: { adjust(0.1) }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Subir volumen")
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(Int(level * 100)) por ciento")
    }
    
    private func adjust(_ delta: Float) {
        hapticTap(.light)
        let base = isMuted ? 0 : volume
        let newLevel = max(0, min(1, base + delta))
        if isMuted && newLevel > 0 { isMuted = false }
        volume = newLevel
    }
}

// MARK: - Feedback háptico

func hapticTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}

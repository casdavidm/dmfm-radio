import SwiftUI

/// Hoja "Reproduciendo": carátula circular con arco de señal, controles y ficha de la emisora
struct FullPlayerSheetView: View {
    @ObservedObject var player: RadioPlayer
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Environment(\.dismiss) private var dismiss
    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}
    var skipEnabled: Bool = false
    
    private var station: RadioStation { player.currentStation }
    
    private var faviconURL: URL? {
        guard let raw = station.faviconURL, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
    
    private var initials: String {
        let words = station.name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map { String($0).uppercased() }
        return letters.isEmpty ? "FM" : letters.joined()
    }
    
    var body: some View {
        GeometryReader { geo in
            let artworkSize = min(geo.size.width - 96, geo.size.height * 0.38, 300)
            
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Barra superior
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.appTextPrimary)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .neumorphicRaised(Circle(), shadowRadius: 7)
                        .accessibilityLabel("Cerrar")
                        
                        Spacer()
                        
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        
                        Spacer()
                        
                        Button(action: {
                            hapticTap()
                            favoritesManager.toggleFavorite(station)
                        }) {
                            let isFav = favoritesManager.isFavorite(station)
                            Image(systemName: isFav ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isFav ? Color.appAccent : Color.appTextSecondary)
                                .frame(width: 42, height: 42)
                        }
                        .buttonStyle(.plain)
                        .neumorphicRaised(Circle(), shadowRadius: 7)
                        .accessibilityLabel("Favorito")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // MARK: - Ahora suena
                    VStack(spacing: 12) {
                        HStack {
                            Text("AHORA SUENA")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(Color.appTextSecondary)
                            
                            Spacer()
                            
                            LiveBadge(isPlaying: player.state.isPlaying, isBuffering: player.state.isBuffering)
                        }
                        
                        Text("\(station.dialFrequencyString.replacingOccurrences(of: " FM", with: "")) · \(station.name.uppercased())")
                            .font(.retro(24))
                            .foregroundColor(Color.appTextPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    
                    Spacer()
                    
                    // MARK: - Carátula circular con arco de señal
                    ZStack {
                        Circle()
                            .strokeBorder(Color.appBorder.opacity(0.6), lineWidth: 1)
                            .frame(width: artworkSize + 32, height: artworkSize + 32)
                        
                        TimelineView(.animation(paused: !player.state.isPlaying)) { timeline in
                            let seconds = timeline.date.timeIntervalSinceReferenceDate
                            let rotation = seconds.truncatingRemainder(dividingBy: 4) / 4 * 360
                            
                            Circle()
                                .trim(from: 0, to: 0.32)
                                .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .frame(width: artworkSize + 32, height: artworkSize + 32)
                                .rotationEffect(.degrees(player.state.isPlaying ? rotation - 90 : -90))
                                .shadow(color: Color.appAccent.opacity(0.6), radius: 6)
                        }
                        
                        artwork(size: artworkSize)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.6), radius: 22, x: 10, y: 14)
                        
                        // Etiqueta central
                        ZStack {
                            Circle()
                                .fill(Color.appBackground)
                                .frame(width: artworkSize * 0.36, height: artworkSize * 0.36)
                            
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: artworkSize * 0.3, height: artworkSize * 0.3)
                                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 2, y: 4)
                            
                            VStack(spacing: 0) {
                                Text(initials)
                                    .font(.retro(artworkSize * 0.1))
                                    .foregroundColor(Color.appBackground)
                                Text("FM")
                                    .font(.system(size: artworkSize * 0.045, weight: .bold))
                                    .foregroundColor(Color.appBackground.opacity(0.75))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // MARK: - Controles cuadrados
                    HStack(spacing: 20) {
                        squareButton(icon: "backward.fill", width: 62, action: onPrevious, label: "Emisora anterior")
                            .disabled(!skipEnabled)
                            .opacity(skipEnabled ? 1 : 0.45)
                        
                        Button(action: {
                            hapticTap(.medium)
                            player.togglePlayPause()
                        }) {
                            ZStack {
                                if player.state.isBuffering {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                                } else {
                                    Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(Color.appBackground)
                                        .offset(x: player.state.isPlaying ? 0 : 2)
                                }
                            }
                            .frame(width: 84, height: 64)
                        }
                        .buttonStyle(.plain)
                        .neumorphicRaised(RoundedRectangle(cornerRadius: 20, style: .continuous), fill: Color.appAccent, shadowRadius: 10)
                        .accessibilityLabel(player.state.isPlaying ? "Pausar" : "Reproducir")
                        
                        squareButton(icon: "forward.fill", width: 62, action: onNext, label: "Emisora siguiente")
                            .disabled(!skipEnabled)
                            .opacity(skipEnabled ? 1 : 0.45)
                    }
                    
                    Spacer()
                    
                    // MARK: - Ficha de la emisora
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.appBackground)
                            Text(station.countryCode.isEmpty ? "FM" : station.countryCode.uppercased())
                                .font(.retro(14))
                                .foregroundColor(Color.appAccent)
                        }
                        .frame(width: 46, height: 46)
                        .overlay(Circle().strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(player.trackTitle.isEmpty || !player.state.isPlaying ? station.name : player.trackTitle)
                                .font(.retro(16))
                                .foregroundColor(Color.appTextPrimary)
                                .lineLimit(1)
                            
                            Text([station.country, station.genre].filter { !$0.isEmpty }.joined(separator: " · ").uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(Color.appTextSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer(minLength: 6)
                        
                        Text(station.bitrate)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.appAccent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.appBackground))
                            .overlay(Capsule().strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .neumorphicRaised(RoundedRectangle(cornerRadius: 26, style: .continuous), shadowRadius: 12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
        }
    }
    
    @ViewBuilder
    private func artwork(size: CGFloat) -> some View {
        if let url = faviconURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                default:
                    SpeakerGrilleView(size: size)
                }
            }
            .frame(width: size, height: size)
        } else {
            SpeakerGrilleView(size: size)
        }
    }
    
    private func squareButton(icon: String, width: CGFloat, action: @escaping () -> Void, label: String) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
                .frame(width: width, height: 56)
        }
        .buttonStyle(.plain)
        .neumorphicRaised(RoundedRectangle(cornerRadius: 18, style: .continuous), shadowRadius: 8)
        .accessibilityLabel(label)
    }
}

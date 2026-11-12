import SwiftUI

/// Tarjeta de emisora con mini dial, estilo retro-moderno
struct StationCardView: View {
    let station: RadioStation
    let isSelected: Bool
    let isPlaying: Bool
    let isBuffering: Bool
    let isFavorite: Bool
    let onPlayTapped: () -> Void
    let onFavoriteTapped: () -> Void
    
    /// País y género sin repetir cuando el servicio usa el país como género de respaldo
    private var subtitleText: String {
        var parts = [station.country]
        if !station.genre.isEmpty && station.genre.caseInsensitiveCompare(station.country) != .orderedSame {
            parts.append(station.genre)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // MARK: - Mini dial con frecuencia
            ZStack {
                Circle()
                    .fill(
                        Color.appBackground
                            .shadow(.inner(color: Color.black.opacity(0.65), radius: 5, x: 3, y: 3))
                            .shadow(.inner(color: Color.white.opacity(0.05), radius: 4, x: -2, y: -2))
                    )
                
                VStack(spacing: 0) {
                    Text(String(format: "%.1f", station.dialFrequency))
                        .font(.retro(15))
                        .foregroundColor(isSelected ? Color.appAccent : Color.appTextPrimary)
                        .monospacedDigit()
                    
                    Text("FM")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.appTextSecondary)
                }
            }
            .frame(width: 58, height: 58)
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? Color.appAccent.opacity(0.7) : Color.appBorder.opacity(0.6), lineWidth: 1)
            )
            
            // MARK: - Información
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.retro(17))
                    .foregroundColor(isSelected ? Color.appAccent : Color.appTextPrimary)
                    .lineLimit(1)
                
                Text(subtitleText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                
                Text(station.bitrate)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.appTextSecondary.opacity(0.75))
            }
            
            Spacer(minLength: 4)
            
            // MARK: - Favorito
            Button(action: onFavoriteTapped) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15))
                    .foregroundColor(isFavorite ? Color.appAccent : Color.appTextSecondary.opacity(0.7))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
            
            // MARK: - Play / Pausa
            Button(action: onPlayTapped) {
                ZStack {
                    if isSelected && isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isPlaying ? Color.appBackground : Color.appAccent))
                            .scaleEffect(0.75)
                    } else {
                        Image(systemName: isSelected && isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected && isPlaying ? Color.appBackground : Color.appAccent)
                            .offset(x: (isSelected && isPlaying) ? 0 : 1)
                    }
                }
                .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .neumorphicRaised(Circle(), fill: isSelected && isPlaying ? Color.appAccent : Color.appCard, shadowRadius: 6)
            .accessibilityLabel(isSelected && isPlaying ? "Pausar" : "Reproducir")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .neumorphicRaised(RoundedRectangle(cornerRadius: 22, style: .continuous), shadowRadius: 9)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.appAccent.opacity(isSelected ? 0.6 : 0), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onPlayTapped()
        }
    }
}

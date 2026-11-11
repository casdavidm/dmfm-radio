import SwiftUI

/// Tarjeta minimalista de emisora de radio
struct StationCardView: View {
    let station: RadioStation
    let isSelected: Bool
    let isPlaying: Bool
    let isBuffering: Bool
    let isFavorite: Bool
    let onPlayTapped: () -> Void
    let onFavoriteTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // MARK: - Dial o Frecuencia Simulada
            VStack(spacing: 3) {
                Text(station.dialFrequencyString)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(isSelected ? Color.appAccent : Color.appTextPrimary)
                
                Text(station.codec)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.appBackground.opacity(0.85))
                    .cornerRadius(4)
            }
            .frame(width: 68, height: 56)
            .background(Color.appBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.appAccent.opacity(0.5) : Color.appBorder.opacity(0.6), lineWidth: 1)
            )
            
            // MARK: - Información de la Emisora
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? Color.appAccent : Color.appTextPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if !station.country.isEmpty {
                        Text(station.country)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(1)
                    }
                    
                    if !station.genre.isEmpty {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color.appTextSecondary.opacity(0.6))
                        
                        Text(station.genre)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(1)
                    }
                }
                
                Text(station.bitrate)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.appTextSecondary.opacity(0.8))
            }
            
            Spacer(minLength: 4)
            
            // MARK: - Botón Favorito
            Button(action: onFavoriteTapped) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15))
                    .foregroundColor(isFavorite ? Color.appAccent : Color.appTextSecondary.opacity(0.6))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // MARK: - Botón Reproducir / Estado
            Button(action: onPlayTapped) {
                ZStack {
                    Circle()
                        .fill(isSelected && isPlaying ? Color.appAccent : Color.appBackground)
                        .frame(width: 40, height: 40)
                    
                    if isSelected && isBuffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isPlaying ? Color.appBackground : Color.appAccent))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSelected && isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected && isPlaying ? Color.appBackground : Color.appAccent)
                            .offset(x: (isSelected && isPlaying) ? 0 : 1)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 1)
                )
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.appCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.appAccent.opacity(0.7) : Color.appBorder.opacity(0.6), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onPlayTapped()
        }
    }
}

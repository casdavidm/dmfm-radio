import SwiftUI

/// Hoja modal de controles completos y reproductor con vinilo y dial de frecuencia
struct FullPlayerSheetView: View {
    @ObservedObject var player: RadioPlayer
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Fondo Azul oscuro #111827
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // MARK: - Barra Superior / Dismiss
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color.appTextSecondary)
                            .frame(width: 38, height: 38)
                            .background(Color.appCard)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("SINTONIZADOR")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(Color.appAccent)
                        
                        Text(player.currentStation.country.isEmpty ? "Transmisión Digital" : player.currentStation.country)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Botón de Favoritos
                    Button(action: {
                        favoritesManager.toggleFavorite(player.currentStation)
                    }) {
                        let isFav = favoritesManager.isFavorite(player.currentStation)
                        Image(systemName: isFav ? "star.fill" : "star")
                            .font(.system(size: 17))
                            .foregroundColor(isFav ? Color.appAccent : Color.appTextSecondary)
                            .frame(width: 38, height: 38)
                            .background(Color.appCard)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer(minLength: 4)
                
                // MARK: - Vinilo Minimalista Giratorio
                VinylDiscView(isPlaying: player.state.isPlaying, size: 210)
                    .padding(.vertical, 8)
                
                Spacer(minLength: 4)
                
                // MARK: - Dial de Frecuencia FM Estilizado
                VStack(spacing: 8) {
                    HStack {
                        Text("FM STEREO")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.appTextSecondary)
                        
                        Spacer()
                        
                        Text(player.currentStation.dialFrequencyString)
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(Color.appAccent)
                    }
                    .padding(.horizontal, 4)
                    
                    // Escala de sintonizador analógica/digital
                    GeometryReader { geo in
                        let width = geo.size.width
                        let freq = player.currentStation.dialFrequency
                        let clampedFreq = min(max(freq, 88.0), 108.0)
                        let percent = CGFloat((clampedFreq - 88.0) / 20.0) // 0.0 a 1.0
                        let needleX = percent * width
                        
                        ZStack(alignment: .leading) {
                            // Fondo de la escala
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appCard)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appBorder, lineWidth: 1)
                                )
                            
                            // Marcas de dial graduadas
                            HStack(spacing: 0) {
                                ForEach(0..<21, id: \.self) { i in
                                    VStack {
                                        Rectangle()
                                            .fill(i % 5 == 0 ? Color.appTextPrimary.opacity(0.8) : Color.appTextSecondary.opacity(0.35))
                                            .frame(width: 1.5, height: i % 5 == 0 ? 14 : 7)
                                        
                                        if i % 5 == 0 {
                                            Text("\(88 + i)")
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(Color.appTextSecondary)
                                        }
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 6)
                            .padding(.horizontal, 8)
                            
                            // Aguja indicadora en Amarillo #ffc61a
                            Rectangle()
                                .fill(Color.appAccent)
                                .frame(width: 2.5, height: 42)
                                .shadow(color: Color.appAccent.opacity(0.8), radius: 4)
                                .offset(x: max(8, min(needleX, width - 8)) - 1.25, y: 0)
                        }
                    }
                    .frame(height: 52)
                }
                .padding(.horizontal, 24)
                
                // MARK: - Información de Emisora y Canción en Vivo
                VStack(spacing: 6) {
                    Text(player.currentStation.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(player.trackTitle.isEmpty ? player.currentStation.genre : player.trackTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 16)
                    
                    // Tag de calidad
                    Text(player.currentStation.bitrate)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.appAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color.appCard)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.appBorder, lineWidth: 1))
                }
                .padding(.horizontal, 24)
                
                // MARK: - Control de Volumen
                HStack(spacing: 12) {
                    Button(action: {
                        player.isMuted.toggle()
                    }) {
                        Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundColor(player.isMuted ? Color.appAccent : Color.appTextSecondary)
                    }
                    
                    Slider(value: $player.volume, in: 0...1)
                        .accentColor(Color.appAccent)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.horizontal, 28)
                .padding(.top, 4)
                
                // MARK: - Controles Principales de Reproducción
                HStack(spacing: 36) {
                    // Botón Detener
                    Button(action: {
                        player.stop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.appTextSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color.appCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                    }
                    
                    // Botón Central Play/Pause en Amarillo #ffc61a
                    Button(action: {
                        player.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: 72, height: 72)
                                .shadow(color: Color.appAccent.opacity(0.4), radius: 10, x: 0, y: 4)
                            
                            if player.state.isBuffering {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.appBackground))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: player.state.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 26, weight: .heavy))
                                    .foregroundColor(Color.appBackground)
                                    .offset(x: player.state.isPlaying ? 0 : 2)
                            }
                        }
                    }
                    
                    // Botón Mute / Desmutear
                    Button(action: {
                        player.isMuted.toggle()
                    }) {
                        Image(systemName: player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(player.isMuted ? Color.appAccent : Color.appTextSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color.appCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

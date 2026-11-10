import SwiftUI

struct ContentView: View {
    @StateObject private var player = RadioPlayer.shared
    @State private var showingSettings = false
    @State private var discRotation: Double = 0
    @State private var pulseLive: Bool = false
    
    var body: some View {
        ZStack {
            // Fondo de atmósfera oscura con degradados sutiles
            Color(red: 0.04, green: 0.05, blue: 0.09)
                .ignoresSafeArea()
            
            // Círculos de luz ambiental
            GeometryReader { proxy in
                Circle()
                    .fill(Color(red: 0.10, green: 0.75, blue: 1.0).opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.15)
                
                Circle()
                    .fill(Color(red: 0.85, green: 0.20, blue: 0.95).opacity(0.12))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.65)
            }
            
            VStack(spacing: 16) {
                // MARK: - Barra Superior
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("DM")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("/")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.85, green: 0.20, blue: 0.95))
                            Text("FM")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                        }
                        
                        Text("ONLINE RADIO STREAM")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2.0)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    // Indicador "EN VIVO"
                    HStack(spacing: 6) {
                        Circle()
                            .fill(player.state.isPlaying ? Color.red : Color.gray)
                            .frame(width: 8, height: 8)
                            .scaleEffect(player.state.isPlaying && pulseLive ? 1.3 : 1.0)
                            .opacity(player.state.isPlaying && pulseLive ? 0.8 : 1.0)
                        
                        Text(player.state.isPlaying ? "EN VIVO" : "EN PAUSA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(player.state.isPlaying ? Color.red.opacity(0.2) : Color.white.opacity(0.08))
                    )
                    
                    // Botón de Configuración
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                // MARK: - Arte de Estación / Vinilo Giratorio
                ZStack {
                    // Sombra y resplandor
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.75, blue: 1.0).opacity(0.25),
                                    Color(red: 0.85, green: 0.20, blue: 0.95).opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 250, height: 250)
                        .blur(radius: 20)
                    
                    // Cuerpo del Vinilo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.13, blue: 0.18),
                                    Color(red: 0.05, green: 0.06, blue: 0.09)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 110
                            )
                        )
                        .frame(width: 230, height: 230)
                        .overlay(
                            // Ranuras de disco
                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                .frame(width: 190, height: 190)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                .frame(width: 150, height: 150)
                        )
                    
                    // Centro del vinilo
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
                        .frame(width: 90, height: 90)
                        .overlay(
                            VStack(spacing: 2) {
                                Image(systemName: "radio.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                Text("DM/FM")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                            }
                        )
                        .overlay(
                            Circle()
                                .fill(Color.black)
                                .frame(width: 14, height: 14)
                        )
                }
                .rotationEffect(.degrees(discRotation))
                .animation(
                    player.state.isPlaying
                        ? .linear(duration: 12).repeatForever(autoreverses: false)
                        : .default,
                    value: discRotation
                )
                .onAppear {
                    if player.state.isPlaying {
                        discRotation = 360
                    }
                }
                .onChange(of: player.state.isPlaying) { isPlaying in
                    if isPlaying {
                        discRotation += 360
                    }
                }
                
                Spacer()
                
                // MARK: - Información de Pista y Metadatos
                VStack(spacing: 6) {
                    Text(player.trackTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                    
                    Text(player.artistName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                    
                    // Badge con información de emisión
                    HStack(spacing: 6) {
                        Text(player.currentStation.genre)
                        Text("•")
                        Text(player.currentStation.bitrate)
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .padding(.top, 4)
                }
                
                // Visualizador de audio animado
                VisualizerView(isPlaying: player.state.isPlaying)
                
                // Mensaje de Error si ocurre
                if let err = player.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        Button("Reintentar") {
                            player.play()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.18))
                    .cornerRadius(8)
                }
                
                // MARK: - Selector Rápido de Canales
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AppConfig.defaultStations) { station in
                            let isSelected = player.currentStation.name == station.name
                            Button(action: {
                                player.switchStation(to: station)
                            }) {
                                HStack(spacing: 6) {
                                    if isSelected && player.state.isPlaying {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 11))
                                    }
                                    Text(station.name)
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                }
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            isSelected
                                                ? AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.10, green: 0.75, blue: 1.0),
                                                            Color(red: 0.85, green: 0.20, blue: 0.95)
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                  )
                                                : AnyShapeStyle(Color.white.opacity(0.06))
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // MARK: - Controles de Reproducción
                PlayerControlsView(player: player)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(player: player)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseLive.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}

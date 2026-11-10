import SwiftUI

/// Pantalla de configuración y gestión de streams
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var player: RadioPlayer
    
    @State private var customURL: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.12)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Sección: Stream Personalizado
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STREAM PERSONALIZADO")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Introduce la URL de tu transmisión en vivo (Icecast, Shoutcast, HLS o MP3):")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                TextField("https://tu-radio-stream.com/live", text: $customURL)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                
                                Button(action: applyCustomURL) {
                                    HStack {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                        Text("Conectar y Reproducir")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.10, green: 0.75, blue: 1.0),
                                                Color(red: 0.85, green: 0.20, blue: 0.95)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                                }
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                        }
                        
                        // Sección: Estaciones Disponibles
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ESTACIONES PRECONFIGURADAS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                            
                            VStack(spacing: 8) {
                                ForEach(AppConfig.defaultStations) { station in
                                    Button(action: {
                                        player.switchStation(to: station)
                                        dismiss()
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(station.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Text(station.subtitle)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                            
                                            Spacer()
                                            
                                            if player.currentStation.name == station.name {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                                                    .font(.system(size: 18))
                                            }
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Sección: Información del Sistema
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CARACTERÍSTICAS TÉCNICAS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(icon: "bolt.fill", title: "Audio en segundo plano", value: "Activo (UIBackgroundModes)")
                                InfoRow(icon: "lock.shield.fill", title: "Control en pantalla bloqueada", value: "MPNowPlayingInfoCenter")
                                InfoRow(icon: "waveform", title: "Metadatos en vivo", value: "Icecast / Timed Metadata")
                                InfoRow(icon: "network", title: "Seguridad ATS", value: "HTTP & HTTPS soportados")
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Configuración DM/FM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Aviso"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func applyCustomURL() {
        let trimmed = customURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" else {
            alertMessage = "Por favor introduce una URL válida que empiece con http:// o https://"
            showAlert = true
            return
        }
        player.setCustomStreamURL(trimmed)
        dismiss()
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.10, green: 0.75, blue: 1.0))
                .frame(width: 22)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}


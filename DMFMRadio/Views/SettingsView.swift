import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var customURL: String = ""
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    func apply(player: RadioPlayer, onDismiss: () -> Void) {
        let trimmed = customURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" else {
            alertMessage = "Introduce una URL válida que empiece con https:// o http://"
            showAlert = true
            return
        }
        player.setCustomStreamURL(trimmed)
        onDismiss()
    }
}

/// Pantalla de configuración y gestión de streams
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var player: RadioPlayer
    @StateObject private var model = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Sección: Stream Personalizado
                        VStack(alignment: .leading, spacing: 12) {
                            Text("STREAM PERSONALIZADO")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.appAccent)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Introduce la URL de tu transmisión en vivo (Icecast, Shoutcast, HLS o MP3):")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.appTextSecondary)
                                
                                TextField("https://tu-radio-stream.com/live", text: $model.customURL)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding()
                                    .background(Color.appCard)
                                    .cornerRadius(10)
                                    .foregroundColor(Color.appTextPrimary)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                                
                                Button(action: {
                                    model.apply(player: player) {
                                        dismiss()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                        Text("Conectar y Reproducir")
                                    }
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color.appBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.appAccent)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(16)
                            .background(Color.appCard)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(Color.appAccent)
                }
            }
            .alert(isPresented: $model.showAlert) {
                Alert(
                    title: Text("Aviso"),
                    message: Text(model.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

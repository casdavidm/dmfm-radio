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

/// Ajustes: stream personalizado y datos de la app
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var player: RadioPlayer
    @StateObject private var model = SettingsViewModel()
    
    var body: some View {
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
                    
                    Text("AJUSTES")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Color.appTextPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 42, height: 42)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Stream personalizado
                        VStack(alignment: .leading, spacing: 14) {
                            Text("STREAM PERSONALIZADO")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(Color.appAccent)
                            
                            Text("Introduce la URL de tu transmisión en vivo (Icecast, Shoutcast, HLS o MP3):")
                                .font(.system(size: 13))
                                .foregroundColor(Color.appTextSecondary)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "link")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appTextSecondary)
                                
                                TextField("https://tu-radio-stream.com/live", text: $model.customURL)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appTextPrimary)
                                    .tint(Color.appAccent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .neumorphicInset(Capsule())
                            
                            Button(action: {
                                hapticTap(.medium)
                                model.apply(player: player) { dismiss() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                    Text("Conectar y reproducir")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.appBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                            }
                            .buttonStyle(.plain)
                            .neumorphicRaised(Capsule(), fill: Color.appAccent, shadowRadius: 8)
                        }
                        .padding(18)
                        .neumorphicRaised(RoundedRectangle(cornerRadius: 26, style: .continuous), shadowRadius: 12)
                        
                        // MARK: - Acerca de
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ACERCA DE")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(2)
                                .foregroundColor(Color.appAccent)
                            
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 26)
                            
                            Text(AppConfig.appTagline)
                                .font(.system(size: 13))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .neumorphicRaised(RoundedRectangle(cornerRadius: 26, style: .continuous), shadowRadius: 12)
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert(isPresented: $model.showAlert) {
            Alert(
                title: Text("Aviso"),
                message: Text(model.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

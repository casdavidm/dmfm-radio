import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

/// Estado actual de reproducción
enum PlayerState: Equatable {
    case stopped
    case buffering
    case playing
    case paused
    case error(String)
    
    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
    
    var isBuffering: Bool {
        if case .buffering = self { return true }
        return false
    }
}

/// Gestor principal de audio para streaming en vivo con soporte de segundo plano
@MainActor
final class RadioPlayer: ObservableObject {
    static let shared = RadioPlayer()
    
    // MARK: - Published Properties
    @Published private(set) var state: PlayerState = .stopped
    @Published var currentStation: RadioStation
    @Published private(set) var trackTitle: String = "Transmisión en directo"
    @Published private(set) var artistName: String = AppConfig.appName
    @Published var volume: Float = 1.0 {
        didSet {
            player?.volume = isMuted ? 0.0 : volume
        }
    }
    @Published var isMuted: Bool = false {
        didSet {
            player?.volume = isMuted ? 0.0 : volume
        }
    }
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var metadataObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        self.currentStation = AppConfig.defaultStations.first ?? RadioStation(
            name: AppConfig.appName,
            subtitle: AppConfig.appTagline,
            streamURL: AppConfig.defaultStreamURL,
            genre: "En vivo",
            bitrate: "128 kbps"
        )
        
        setupAudioSession()
        setupRemoteCommands()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Session Configuration
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
            try session.setActive(true)
        } catch {
            print("Error configurando AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Playback Controls
    
    /// Alternar reproducción / pausa
    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .buffering:
            stop()
        case .paused, .stopped, .error:
            play()
        }
    }
    
    /// Inicia la reproducción del stream actual
    func play() {
        guard let url = URL(string: currentStation.streamURL) else {
            self.state = .error("URL de stream inválida: \(currentStation.streamURL)")
            self.errorMessage = "URL de stream inválida"
            return
        }
        
        // Si ya está pausado el mismo playerItem, reanudar
        if let player = player, state == .paused {
            state = .buffering
            player.play()
            updateNowPlayingInfo()
            return
        }
        
        // Limpiar player anterior
        cleanupPlayer()
        
        state = .buffering
        errorMessage = nil
        
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        self.playerItem = item
        
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        newPlayer.volume = isMuted ? 0.0 : volume
        self.player = newPlayer
        
        observePlayerItem(item)
        observePlayer(newPlayer)
        
        newPlayer.play()
        updateNowPlayingInfo()
    }
    
    /// Pausar reproducción
    func pause() {
        player?.pause()
        state = .paused
        updateNowPlayingInfo()
    }
    
    /// Detener reproducción
    func stop() {
        cleanupPlayer()
        state = .stopped
        updateNowPlayingInfo()
    }
    
    /// Cambia de estación e inicia reproducción
    func switchStation(to station: RadioStation) {
        currentStation = station
        trackTitle = "Conectando..."
        artistName = station.name
        play()
    }
    
    /// Actualiza la URL personalizada para la estación actual
    func setCustomStreamURL(_ urlString: String) {
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        currentStation = RadioStation(
            name: "DM/FM Personalizada",
            subtitle: "Stream personalizado",
            streamURL: cleanURL,
            genre: "Personalizado",
            bitrate: "Stream en vivo"
        )
        play()
    }
    
    // MARK: - Player Observers
    private func observePlayerItem(_ item: AVPlayerItem) {
        statusObserver = item.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    if self.player?.timeControlStatus == .playing {
                        self.state = .playing
                    }
                case .failed:
                    let err = item.error?.localizedDescription ?? "Error al cargar el stream"
                    self.state = .error(err)
                    self.errorMessage = err
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // Observar metadatos ICY (Título de la canción y artista)
        metadataObserver = item.observe(\.timedMetadata, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self = self, let metadata = item.timedMetadata else { return }
                self.processMetadata(metadata)
            }
        }
    }
    
    private func observePlayer(_ player: AVPlayer) {
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.state = .playing
                    self.errorMessage = nil
                    self.updateNowPlayingInfo()
                case .paused:
                    if self.state != .stopped {
                        self.state = .paused
                    }
                    self.updateNowPlayingInfo()
                case .waitingToPlayAtSpecifiedRate:
                    self.state = .buffering
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func processMetadata(_ items: [AVMetadataItem]) {
        for item in items {
            if let stringValue = item.stringValue, !stringValue.isEmpty {
                // Formato habitual de streaming: "Artista - Canción"
                let components = stringValue.components(separatedBy: " - ")
                if components.count >= 2 {
                    self.artistName = components[0].trimmingCharacters(in: .whitespaces)
                    self.trackTitle = components.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                } else {
                    self.trackTitle = stringValue
                    self.artistName = currentStation.name
                }
                updateNowPlayingInfo()
                break
            }
        }
    }
    
    private func cleanupPlayer() {
        statusObserver?.invalidate()
        statusObserver = nil
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        metadataObserver?.invalidate()
        metadataObserver = nil
        
        player?.pause()
        player = nil
        playerItem = nil
    }
    
    // MARK: - Lock Screen & Control Center (MPRemoteCommandCenter)
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.play()
            }
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.pause()
            }
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.togglePlayPause()
            }
            return .success
        }
        
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.stop()
            }
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        
        info[MPMediaItemPropertyTitle] = trackTitle.isEmpty ? currentStation.name : trackTitle
        info[MPMediaItemPropertyArtist] = artistName.isEmpty ? AppConfig.appName : artistName
        info[MPMediaItemPropertyAlbumTitle] = currentStation.name
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = (state == .playing) ? 1.0 : 0.0
        
        // Artwork vectorial dinámico para Lock Screen
        let size = CGSize(width: 300, height: 300)
        let artwork = MPMediaItemArtwork(boundsSize: size) { [weak self] _ in
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                let rect = CGRect(origin: .zero, size: size)
                // Fondo oscuro degradado
                let colors = [
                    UIColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1.0).cgColor,
                    UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1.0).cgColor
                ]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                    ctx.cgContext.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
                }
                
                // Letras "DM/FM"
                let title = self?.currentStation.name ?? "DM/FM"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let str = NSAttributedString(string: title, attributes: attrs)
                let strRect = str.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
                str.draw(at: CGPoint(x: (size.width - strRect.width) / 2, y: (size.height - strRect.height) / 2))
            }
        }
        info[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Notifications (Audio Interruption & Route Change)
    private func setupNotificationObservers() {
        // Interrupciones (llamada entrante, alarma)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch type {
                case .began:
                    if self.state == .playing {
                        self.pause()
                    }
                case .ended:
                    if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                        if options.contains(.shouldResume) {
                            self.play()
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
        
        // Cambio de salida de audio (desconexión de audífonos / Bluetooth)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
            
            if reason == .oldDeviceUnavailable {
                Task { @MainActor [weak self] in
                    self?.pause()
                }
            }
        }
    }
}


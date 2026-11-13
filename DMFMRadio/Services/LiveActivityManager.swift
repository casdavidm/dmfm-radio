import ActivityKit
import Combine
import Foundation

/// Mantiene una Live Activity sincronizada con el estado del reproductor:
/// aparece al sintonizar, se actualiza con metadatos y desaparece al detener.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<RadioActivityAttributes>?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    func start(observing player: RadioPlayer) {
        Publishers.CombineLatest3(player.$state, player.$currentStation, player.$trackTitle)
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] state, station, trackTitle in
                self?.sync(state: state, station: station, trackTitle: trackTitle)
            }
            .store(in: &cancellables)
    }
    
    private func sync(state: PlayerState, station: RadioStation, trackTitle: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        switch state {
        case .stopped, .error:
            end()
        case .playing, .paused, .buffering:
            guard !station.isPlaceholder else {
                end()
                return
            }
            
            let cleanTitle = (trackTitle == "Conectando..." || trackTitle == "Transmisión en directo") ? "" : trackTitle
            let content = RadioActivityAttributes.ContentState(
                stationName: station.name,
                frequency: station.dialFrequency,
                isPlaying: state.isPlaying,
                isBuffering: state.isBuffering,
                trackTitle: cleanTitle,
                country: station.country
            )
            
            if let activity = activity {
                Task {
                    await activity.update(ActivityContent(state: content, staleDate: nil))
                }
            } else {
                request(with: content)
            }
        }
    }
    
    private func request(with content: RadioActivityAttributes.ContentState) {
        // Cierra actividades huérfanas de un arranque anterior
        for stale in Activity<RadioActivityAttributes>.activities {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        
        do {
            activity = try Activity.request(
                attributes: RadioActivityAttributes(startedAt: Date()),
                content: ActivityContent(state: content, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("No se pudo iniciar la Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func end() {
        guard let current = activity else { return }
        activity = nil
        Task { await current.end(nil, dismissalPolicy: .immediate) }
    }
}

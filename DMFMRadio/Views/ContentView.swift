import SwiftUI

/// Vista principal de DM/FM Radio: cabecera, pestañas Inicio · Radio · Favoritos y mini-reproductor
struct ContentView: View {
    @StateObject private var player = RadioPlayer.shared
    @StateObject private var browserService = RadioBrowserService.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var selectedTab: AppTab = .home
    @State private var showingNowPlaying = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Cabecera
                RetroHeader(
                    isLive: player.state.isPlaying,
                    onMenu: { showingSettings = true },
                    onStatus: {
                        if player.currentStation.isPlaceholder {
                            withAnimation { selectedTab = .radio }
                        } else {
                            showingNowPlaying = true
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 14)
                
                // MARK: - Contenido de la pestaña
                Group {
                    switch selectedTab {
                    case .home:
                        homeView
                    case .radio:
                        RadioTunerView(
                            player: player,
                            browserService: browserService,
                            favoritesManager: favoritesManager,
                            onOpenNowPlaying: { showingNowPlaying = true }
                        )
                    case .favorites:
                        favoritesView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    // Desvanecido de la lista bajo el mini-reproductor
                    if selectedTab != .radio && !player.currentStation.isPlaceholder {
                        LinearGradient(colors: [Color.appBackground.opacity(0), Color.appBackground], startPoint: .top, endPoint: .bottom)
                            .frame(height: 56)
                            .allowsHitTesting(false)
                    }
                }
                
                // MARK: - Mini-reproductor (oculto en la pestaña Radio)
                if selectedTab != .radio && !player.currentStation.isPlaceholder {
                    PersistentMiniPlayerView(player: player) {
                        showingNowPlaying = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // MARK: - Barra de pestañas
                RetroTabBar(selected: $selectedTab)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedTab)
        .animation(.easeInOut(duration: 0.25), value: player.currentStation.isPlaceholder)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingNowPlaying) {
            FullPlayerSheetView(
                player: player,
                onPrevious: { skipStation(-1) },
                onNext: { skipStation(1) },
                skipEnabled: skipPlaylist.count > 1
            )
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(player: player)
        }
        .onOpenURL { url in
            handleDeeplink(url)
        }
    }
    
    // MARK: - Navegación anterior / siguiente desde la hoja
    
    private var skipPlaylist: [RadioStation] {
        let loaded = browserService.state.stations
        return loaded.isEmpty ? favoritesManager.favoriteStations : loaded
    }
    
    private func skipStation(_ delta: Int) {
        let list = skipPlaylist
        guard !list.isEmpty else { return }
        let current = player.currentStation
        let index = list.firstIndex { $0.id == current.id || (!current.streamURL.isEmpty && $0.streamURL == current.streamURL) }
        let target: Int
        if let index = index {
            target = (index + delta + list.count) % list.count
        } else {
            target = delta > 0 ? 0 : list.count - 1
        }
        hapticTap()
        player.switchStation(to: list[target])
    }
    
    // MARK: - Deeplink
    
    private func handleDeeplink(_ url: URL) {
        guard url.scheme == "dmfm" else { return }
        guard url.host == "play" else {
            withAnimation { selectedTab = .radio }
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        let id = queryItems.first(where: { $0.name == "id" })?.value
        let stream = queryItems.first(where: { $0.name == "stream" })?.value
        let name = queryItems.first(where: { $0.name == "name" })?.value ?? "DM/FM Radio"
        let subtitle = queryItems.first(where: { $0.name == "subtitle" })?.value ?? ""
        let genre = queryItems.first(where: { $0.name == "genre" })?.value ?? "En vivo"
        let bitrate = queryItems.first(where: { $0.name == "bitrate" })?.value ?? "128 kbps"
        let country = queryItems.first(where: { $0.name == "country" })?.value ?? ""
        let countryCode = queryItems.first(where: { $0.name == "countryCode" })?.value ?? ""
        let codec = queryItems.first(where: { $0.name == "codec" })?.value ?? "MP3"
        
        let matches: (RadioStation) -> Bool = { station in
            station.id == id || (stream != nil && !stream!.isEmpty && station.streamURL == stream)
        }
        
        let recents = RecentStationsManager.shared.getRecentStations()
        if let match = recents.first(where: matches) ?? AppConfig.defaultStations.first(where: matches) {
            player.switchStation(to: match)
            withAnimation { selectedTab = .radio }
            return
        }
        
        if let stream = stream, !stream.isEmpty {
            let station = RadioStation(
                id: id,
                name: name,
                subtitle: subtitle,
                streamURL: stream,
                genre: genre,
                bitrate: bitrate,
                country: country,
                countryCode: countryCode,
                codec: codec
            )
            player.switchStation(to: station)
            withAnimation { selectedTab = .radio }
        }
    }
    
    // MARK: - Pestaña Inicio
    
    private var homeView: some View {
        VStack(spacing: 0) {
            searchBarView
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            
            filterChipsView
                .padding(.bottom, 6)
            
            stationListView
        }
    }
    
    /// Barra de búsqueda hundida en la superficie
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(browserService.searchText.isEmpty ? Color.appTextSecondary : Color.appAccent)
            
            TextField("Buscar emisora o género…", text: $browserService.searchText)
                .font(.system(size: 14))
                .foregroundColor(Color.appTextPrimary)
                .tint(Color.appAccent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !browserService.searchText.isEmpty {
                Button(action: { browserService.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color.appTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .neumorphicInset(Capsule())
    }
    
    /// Chips de filtro rápido (Favoritos vive en su propia pestaña)
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(CountryFilter.allCases.filter { $0 != .favorites }) { filter in
                    let isSelected = browserService.selectedFilter == filter
                    
                    Button(action: {
                        hapticTap()
                        browserService.selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Color.appBackground : Color.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .neumorphicRaised(Capsule(), fill: isSelected ? Color.appAccent : Color.appCard, shadowRadius: 6)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }
    
    /// Lista de emisoras con estados de carga y error
    private var stationListView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                switch browserService.state {
                case .loading:
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                            .scaleEffect(1.2)
                        
                        Text("Sintonizando emisoras mundiales…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    
                case .error(let message):
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(Color.appAccent)
                        
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Button(action: { browserService.loadCurrentSelection() }) {
                            Text("Reintentar")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.appBackground)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .neumorphicRaised(Capsule(), fill: Color.appAccent, shadowRadius: 6)
                    }
                    .padding(.top, 40)
                    
                case .loaded(let stations):
                    if stations.isEmpty {
                        emptyStateView(
                            icon: "antenna.radiowaves.left.and.right.slash",
                            title: "No se encontraron emisoras con streams HTTPS activos.",
                            hint: nil
                        )
                    } else {
                        ForEach(stations) { station in
                            stationCard(for: station)
                        }
                    }
                    
                case .idle:
                    Color.clear
                        .frame(height: 1)
                        .onAppear { browserService.loadCurrentSelection() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Pestaña Favoritos
    
    private var favoritesView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                HStack {
                    Text("TUS EMISORAS")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color.appTextSecondary)
                    
                    Spacer()
                    
                    Text("\(favoritesManager.favoriteStations.count)")
                        .font(.retro(14))
                        .foregroundColor(Color.appAccent)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                
                if favoritesManager.favoriteStations.isEmpty {
                    emptyStateView(
                        icon: "star.slash",
                        title: "No tienes emisoras favoritas guardadas.",
                        hint: "Toca la estrella en cualquier emisora para agregarla aquí."
                    )
                } else {
                    ForEach(favoritesManager.favoriteStations) { station in
                        stationCard(for: station)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Auxiliares
    
    private func stationCard(for station: RadioStation) -> some View {
        let isCurrent = player.currentStation.streamURL == station.streamURL
        
        return StationCardView(
            station: station,
            isSelected: isCurrent,
            isPlaying: isCurrent && player.state.isPlaying,
            isBuffering: isCurrent && player.state.isBuffering,
            isFavorite: favoritesManager.isFavorite(station),
            onPlayTapped: {
                hapticTap()
                if isCurrent {
                    player.togglePlayPause()
                } else {
                    player.switchStation(to: station)
                }
            },
            onFavoriteTapped: {
                hapticTap()
                favoritesManager.toggleFavorite(station)
            }
        )
    }
    
    private func emptyStateView(icon: String, title: String, hint: String?) -> some View {
        VStack(spacing: 14) {
            ZStack {
                SpeakerGrilleView(size: 96, stripeSpacing: 5, stripeHeight: 2)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(Color.appTextSecondary)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.appBackground))
                    .overlay(Circle().strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let hint = hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

import SwiftUI

/// Vista principal minimalista de DM/FM Radio
struct ContentView: View {
    @StateObject private var player = RadioPlayer.shared
    @StateObject private var browserService = RadioBrowserService.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingFullPlayer = false
    
    var body: some View {
        ZStack {
            // Fondo Azul oscuro estricto #111827
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Header Superior
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                
                // MARK: - 2. Barra de Búsqueda Reactiva
                searchBarView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // MARK: - 3. Píldoras de Filtro Rápido (Chips)
                filterChipsView
                    .padding(.bottom, 12)
                
                // MARK: - 4. Lista de Emisoras Minimalista
                stationListView
                
                // MARK: - 5. Mini-Reproductor Persistente
                PersistentMiniPlayerView(player: player) {
                    showingFullPlayer = true
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheetView(player: player)
        }
        .onOpenURL { url in
            handleDeeplink(url)
        }
    }
    
    // MARK: - Deeplink Handling
    
    private func handleDeeplink(_ url: URL) {
        guard url.scheme == "dmfm", url.host == "play" else { return }
        
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
        
        // 1. Buscar en emisoras recientes guardadas
        let recents = RecentStationsManager.shared.getRecentStations()
        if let match = recents.first(where: { $0.id == id || ($0.streamURL == stream && stream != nil && !stream!.isEmpty) }) {
            player.switchStation(to: match)
            return
        }
        
        // 2. Buscar en las predeterminadas
        if let match = AppConfig.defaultStations.first(where: { $0.id == id || ($0.streamURL == stream && stream != nil && !stream!.isEmpty) }) {
            player.switchStation(to: match)
            return
        }
        
        // 3. Reconstruir emisora desde parámetros
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
        }
    }
    
    // MARK: - Subvistas
    
    /// Header superior con logotipo tipográfico DM / FM e indicador de estado
    private var headerView: some View {
        HStack {
            // Logotipo oficial DM | FM
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)
            
            Spacer()
            
            // Indicador de estado en vivo
            HStack(spacing: 6) {
                Circle()
                    .fill(player.state.isPlaying ? Color.appAccent : Color.appTextSecondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                
                Text(player.state.isPlaying ? "EN VIVO" : "EN PAUSA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(player.state.isPlaying ? Color.appAccent : Color.appTextSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.appCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(player.state.isPlaying ? Color.appAccent.opacity(0.5) : Color.appBorder, lineWidth: 1)
            )
        }
    }
    
    /// Barra de búsqueda reactiva contra la API de Radio Browser
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(browserService.searchText.isEmpty ? Color.appTextSecondary : Color.appAccent)
            
            TextField("Buscar emisora o género...", text: $browserService.searchText)
                .font(.system(size: 14))
                .foregroundColor(Color.appTextPrimary)
                .accentColor(Color.appAccent)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !browserService.searchText.isEmpty {
                Button(action: {
                    browserService.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color.appTextSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
    
    /// Píldoras de filtro rápido (Chips): Top Mundial, España, México, Colombia, Argentina, Favoritos
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CountryFilter.allCases) { filter in
                    let isSelected = browserService.selectedFilter == filter
                    
                    Button(action: {
                        browserService.selectedFilter = filter
                    }) {
                        HStack(spacing: 5) {
                            if filter == .favorites {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                            }
                            
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        }
                        .foregroundColor(isSelected ? Color.appBackground : Color.appTextSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.appAccent : Color.appCard)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    /// Lista de emisoras minimalista con estados de carga y error
    private var stationListView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                switch browserService.state {
                case .loading:
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                            .scaleEffect(1.2)
                        
                        Text("Sintonizando emisoras mundiales...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    
                case .error(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 32))
                            .foregroundColor(Color.appAccent)
                        
                        Text(message)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                            browserService.loadCurrentSelection()
                        }) {
                            Text("Reintentar")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.appBackground)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(Color.appAccent)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 40)
                    
                case .loaded(let stations):
                    if stations.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(stations) { station in
                            let isCurrent = player.currentStation.streamURL == station.streamURL
                            
                            StationCardView(
                                station: station,
                                isSelected: isCurrent,
                                isPlaying: isCurrent && player.state.isPlaying,
                                isBuffering: isCurrent && player.state.isBuffering,
                                isFavorite: favoritesManager.isFavorite(station),
                                onPlayTapped: {
                                    if isCurrent {
                                        player.togglePlayPause()
                                    } else {
                                        player.switchStation(to: station)
                                    }
                                },
                                onFavoriteTapped: {
                                    favoritesManager.toggleFavorite(station)
                                }
                            )
                        }
                    }
                    
                case .idle:
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            browserService.loadCurrentSelection()
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }
    
    /// Vista de estado vacío cuando no se encuentran resultados
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: browserService.selectedFilter == .favorites ? "star.slash" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 36))
                .foregroundColor(Color.appTextSecondary.opacity(0.6))
            
            Text(browserService.selectedFilter == .favorites
                 ? "No tienes emisoras favoritas guardadas."
                 : "No se encontraron emisoras con streams HTTPS activos.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if browserService.selectedFilter == .favorites {
                Text("Toca la estrella en cualquier emisora para agregarla a tus favoritos.")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 50)
    }
}

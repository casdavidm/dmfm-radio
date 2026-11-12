import WidgetKit
import SwiftUI
import AppIntents

/// Entrada de la línea de tiempo del Widget con la lista de emisoras recientes reales
struct RecentStationsEntry: TimelineEntry {
    let date: Date
    let stations: [RadioStation]
    
    var latestStation: RadioStation? {
        stations.first
    }
}

/// Proveedor de la línea de tiempo conectado a RecentStationsManager vía App Group (group.casdavidm.dmfmradio)
struct RecentStationsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentStationsEntry {
        RecentStationsEntry(
            date: Date(),
            stations: RecentStationsManager.shared.getRecentStations()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentStationsEntry) -> Void) {
        let stations = RecentStationsManager.shared.getRecentStations()
        completion(RecentStationsEntry(date: Date(), stations: stations))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentStationsEntry>) -> Void) {
        let stations = RecentStationsManager.shared.getRecentStations()
        let entry = RecentStationsEntry(date: Date(), stations: stations)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

/// Vista contenedora del Widget que se adapta a .systemSmall y .systemMedium
struct RecentStationsWidgetEntryView: View {
    var entry: RecentStationsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(stations: Array(entry.stations.prefix(3)))
            default:
                SmallWidgetView(station: entry.latestStation)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.appBackground, for: .widget)
    }
}

// MARK: - Piezas compartidas del widget

/// Rejilla de altavoz circular en relieve (versión ligera para WidgetKit)
struct WidgetGrilleView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appCard)
                .shadow(color: Color.black.opacity(0.55), radius: size * 0.08, x: size * 0.04, y: size * 0.05)
                .shadow(color: Color.white.opacity(0.05), radius: size * 0.05, x: -size * 0.03, y: -size * 0.03)
            
            VStack(spacing: 4) {
                ForEach(0..<Int(size / 6), id: \.self) { _ in
                    Capsule()
                        .fill(Color.appBackground)
                        .frame(height: 2)
                }
            }
            .frame(width: size * 0.92, height: size * 0.92)
            .clipShape(Circle())
            
            Circle()
                .strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1)
        }
        .frame(width: size, height: size)
    }
}

/// Cabecera: logotipo oficial + píldora de estado
struct WidgetHeader: View {
    var label: String = "RECIENTES"
    /// Versión reducida para .systemSmall
    var compact: Bool = false
    
    var body: some View {
        HStack(alignment: .center) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: compact ? 15 : 18)
            
            Spacer(minLength: 4)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(compact ? 0.5 : 1)
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.appCard))
            .overlay(Capsule().strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1))
        }
        // Separa logo y píldora de las esquinas redondeadas del widget
        .padding(.top, 6)
        .padding(.horizontal, 6)
    }
}

/// Estado vacío con una rejilla y un mensaje
struct WidgetEmptyView: View {
    let compact: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                WidgetGrilleView(size: compact ? 44 : 56)
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: compact ? 13 : 16, weight: .semibold))
                    .foregroundColor(Color.appAccent)
                    .frame(width: compact ? 26 : 32, height: compact ? 26 : 32)
                    .background(Circle().fill(Color.appBackground))
            }
            
            Text("Escucha una emisora para verla aquí")
                .font(.system(size: compact ? 11 : 13, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Vista para .systemSmall

struct SmallWidgetView: View {
    let station: RadioStation?

    var body: some View {
        VStack(spacing: 0) {
            WidgetHeader(label: station == nil ? "RADIO" : "ÚLTIMA", compact: true)
            
            if let station = station {
                // Toda la zona de la emisora reproduce sin abrir la app
                Button(intent: PlayStationIntent(station: station)) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 4)
                        
                        // Rejilla con dial de sintonía
                        ZStack {
                            WidgetGrilleView(size: 92)
                            TunerDialView(
                                frequency: station.dialFrequency,
                                stationName: "",
                                isPlaying: false,
                                size: 54
                            )
                        }
                        
                        Spacer(minLength: 4)
                        
                        // Nombre y país
                        VStack(spacing: 1) {
                            Text(station.name)
                                .font(.retro(13))
                                .foregroundColor(Color.appTextPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(station.country.isEmpty ? station.bitrate : station.country.uppercased())
                                .font(.system(size: 8, weight: .semibold))
                                .tracking(0.8)
                                .foregroundColor(Color.appTextSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                WidgetEmptyView(compact: true)
                    .padding(.top, 6)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Sin emisora reciente, el widget abre la app
        .widgetURL(station == nil ? URL(string: "dmfm://open") : nil)
    }
}

// MARK: - Vista para .systemMedium

struct MediumWidgetView: View {
    let stations: [RadioStation]

    var body: some View {
        VStack(spacing: 8) {
            WidgetHeader(label: stations.isEmpty ? "RADIO" : "RECIENTES")
            
            if stations.isEmpty {
                WidgetEmptyView(compact: false)
            } else if let latest = stations.first {
                HStack(spacing: 12) {
                    // Última emisora: rejilla con dial, reproduce sin abrir la app
                    Button(intent: PlayStationIntent(station: latest)) {
                        ZStack {
                            WidgetGrilleView(size: 96)
                            TunerDialView(
                                frequency: latest.dialFrequency,
                                stationName: "",
                                isPlaying: false,
                                size: 56
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Lista de recientes
                    VStack(spacing: 6) {
                        ForEach(stations.prefix(3)) { station in
                            Button(intent: PlayStationIntent(station: station)) {
                                MediumStationRow(station: station, isLatest: station.id == latest.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Fila de emisora para .systemMedium

struct MediumStationRow: View {
    let station: RadioStation
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%.1f", station.dialFrequency))
                .font(.retro(11))
                .monospacedDigit()
                .foregroundColor(isLatest ? Color.appBackground : Color.appAccent)
                .frame(width: 38, height: 22)
                .background(Capsule().fill(isLatest ? Color.appAccent : Color.appBackground))
            
            Text(station.name)
                .font(.retro(12, weight: .semibold))
                .foregroundColor(Color.appTextPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 2)
            
            Image(systemName: "play.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appCard)
                .shadow(color: Color.black.opacity(0.45), radius: 4, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.appBorder.opacity(0.7), lineWidth: 1)
        )
    }
}

// MARK: - Widget Entry Point

@main
struct RecentStationsWidget: Widget {
    let kind: String = "DMFMRadioRecentStationsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentStationsProvider()) { entry in
            RecentStationsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DM/FM Radio")
        .description("Acceso rápido y sintonización de tus emisoras recientes.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

import WidgetKit
import SwiftUI

/// Entrada de la línea de tiempo del Widget con la lista de emisoras recientes
struct RecentStationsEntry: TimelineEntry {
    let date: Date
    let stations: [RadioStation]
    
    var latestStation: RadioStation {
        stations.first ?? AppConfig.defaultStations[0]
    }
}

/// Proveedor de la línea de tiempo conectado a RecentStationsManager vía App Group
struct RecentStationsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentStationsEntry {
        RecentStationsEntry(
            date: Date(),
            stations: Array(AppConfig.defaultStations.prefix(3))
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentStationsEntry) -> Void) {
        let stations = RecentStationsManager.shared.getRecentStations()
        let list = stations.isEmpty ? Array(AppConfig.defaultStations.prefix(3)) : stations
        completion(RecentStationsEntry(date: Date(), stations: list))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentStationsEntry>) -> Void) {
        let stations = RecentStationsManager.shared.getRecentStations()
        let list = stations.isEmpty ? Array(AppConfig.defaultStations.prefix(3)) : stations
        let entry = RecentStationsEntry(date: Date(), stations: list)
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
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
            case .systemSmall:
                SmallWidgetView(station: entry.latestStation)
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

// MARK: - Vista para .systemSmall

struct SmallWidgetView: View {
    let station: RadioStation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: DM / FM y badge EN VIVO
            HStack(alignment: .center) {
                HStack(spacing: 2) {
                    Text("DM")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    Text("/")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.appAccent)
                    Text("FM")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 6, height: 6)
                    Text("EN VIVO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color.appAccent)
                        .tracking(0.5)
                }
            }
            
            Spacer()
            
            // Frecuencia Dial FM en Amarillo #ffc61a
            VStack(alignment: .leading, spacing: 3) {
                Text(station.dialFrequencyString)
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color.appAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Nombre de la emisora en blanco
                Text(station.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // País / Género / Bitrate en gris
                Text(station.country.isEmpty ? station.genre : "\(station.country) • \(station.bitrate)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(station.deeplinkURL)
    }
}

// MARK: - Vista para .systemMedium

struct MediumWidgetView: View {
    let stations: [RadioStation]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header superior
            HStack(alignment: .center) {
                HStack(spacing: 2) {
                    Text("DM")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Text("/")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.appAccent)
                    Text("FM")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                }
                
                Text("•")
                    .foregroundColor(Color.appTextSecondary.opacity(0.6))
                    .font(.system(size: 11))
                
                Text("EMISORAS RECIENTES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color.appTextSecondary)
                    .tracking(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "radio.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.appAccent)
                    Text("EN DIRECTO")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Color.appAccent)
                }
            }
            
            // Fila de las 3 emisoras recientes con enlaces Deeplink
            HStack(spacing: 8) {
                ForEach(stations.prefix(3)) { station in
                    if let url = station.deeplinkURL {
                        Link(destination: url) {
                            MediumStationCard(station: station)
                        }
                    } else {
                        MediumStationCard(station: station)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Celda de Tarjeta de Emisora para .systemMedium

struct MediumStationCard: View {
    let station: RadioStation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Frecuencia Dial + Icono de reproducción
            HStack {
                Text(station.dialFrequencyString)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(Color.appAccent)
                    .lineLimit(1)
                
                Spacer(minLength: 2)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color.appBackground)
                    .padding(4)
                    .background(Color.appAccent)
                    .clipShape(Circle())
            }
            
            Spacer(minLength: 2)
            
            // Nombre de la emisora en blanco
            Text(station.name)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Género o país en gris
            Text(station.country.isEmpty ? station.genre : station.country)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
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

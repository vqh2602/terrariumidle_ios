import AppIntents
import SwiftUI
import UIKit
import WidgetKit

enum GardenWidgetContent: String, AppEnum {
    case plant, schedule, clock, weather, temperature, feelsLike, uv, humidity, wind, rain
    var weatherMetric: GardenWeatherMetric? { GardenWeatherMetric(rawValue: rawValue) }
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("Nội dung", table: "WatchLocalizable"))
    }
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [.plant: DisplayRepresentation(title: LocalizedStringResource("Cây yêu thích", table: "WatchLocalizable")),
         .schedule: DisplayRepresentation(title: LocalizedStringResource("Lịch ngủ/thức", table: "WatchLocalizable")),
         .clock: DisplayRepresentation(title: LocalizedStringResource("Ngày và giờ", table: "WatchLocalizable")),
         .weather: DisplayRepresentation(title: LocalizedStringResource("Thời tiết", table: "WatchLocalizable")),
         .temperature: DisplayRepresentation(title: LocalizedStringResource("Nhiệt độ", table: "WatchLocalizable")),
         .feelsLike: DisplayRepresentation(title: LocalizedStringResource("Cảm giác như", table: "WatchLocalizable")),
         .uv: DisplayRepresentation(title: LocalizedStringResource("Chỉ số UV", table: "WatchLocalizable")),
         .humidity: DisplayRepresentation(title: LocalizedStringResource("Độ ẩm", table: "WatchLocalizable")),
         .wind: DisplayRepresentation(title: LocalizedStringResource("Gió", table: "WatchLocalizable")),
         .rain: DisplayRepresentation(title: LocalizedStringResource("Khả năng mưa", table: "WatchLocalizable"))]
    }
}

struct GardenWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { LocalizedStringResource("Tùy chỉnh Terrarium", table: "WatchLocalizable") }
    @Parameter(title: LocalizedStringResource("Nội dung", table: "WatchLocalizable"), default: .plant)
    var content: GardenWidgetContent
    @Parameter(title: LocalizedStringResource("Hiển thị tên cây", table: "WatchLocalizable"), default: true)
    var showPlantName: Bool
    @Parameter(title: LocalizedStringResource("Dùng độ F", table: "WatchLocalizable"), default: false)
    var fahrenheit: Bool
}

private struct GardenEntry: TimelineEntry {
    let date: Date
    let snapshot: WatchGardenSnapshot
    let configuration: GardenWidgetIntent
}

private struct GardenProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GardenEntry {
        GardenEntry(date: .now, snapshot: WatchGardenSnapshot(), configuration: GardenWidgetIntent())
    }
    func snapshot(for configuration: GardenWidgetIntent, in context: Context) async -> GardenEntry {
        GardenEntry(date: .now, snapshot: WatchGardenCache.read(), configuration: configuration)
    }
    func timeline(for configuration: GardenWidgetIntent, in context: Context) async -> Timeline<GardenEntry> {
        let now = Date(), snapshot = WatchGardenCache.read()
        // Predict local schedule changes; no phone polling or per-second reload requests.
        let entries = (0..<13).map {
            GardenEntry(date: now.addingTimeInterval(Double($0) * 300), snapshot: snapshot, configuration: configuration)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    func recommendations() -> [AppIntentRecommendation<GardenWidgetIntent>] {
        let language = WatchGardenCache.read().languageCode
        return [(GardenWidgetContent.plant, "Cây yêu thích"), (.schedule, "Lịch ngủ/thức"), (.clock, "Ngày và giờ"), (.weather, "Thời tiết"), (.temperature, "Nhiệt độ"),
                (.feelsLike, "Cảm giác như"), (.uv, "Chỉ số UV"), (.humidity, "Độ ẩm"),
                (.wind, "Gió"), (.rain, "Khả năng mưa")].map { content, key in
            var intent = GardenWidgetIntent()
            intent.content = content
            return AppIntentRecommendation(intent: intent, description: WatchText.value(key, language: language))
        }
    }
}

private struct GardenComplicationView: View {
    let entry: GardenEntry
    @Environment(\.widgetFamily) private var family
    private var language: String? { entry.snapshot.languageCode }
    private func text(_ key: String) -> String { WatchText.value(key, language: language) }
    private var phase: GardenDayPhase { GardenSkyState.resolve(at: entry.date, snapshot: entry.snapshot).phase }
    private var restful: Bool { phase == .night || phase == .dusk }
    private var title: String {
        guard entry.snapshot.enabled else { return "Terrarium" }
        switch entry.configuration.content {
        case .plant: return entry.configuration.showPlantName ? entry.snapshot.plantName : "Terrarium"
        case .schedule: return text(isSleepInterval ? "Giờ thức dậy" : "Giờ đi ngủ")
        case .clock: return time
        default: return text(entry.configuration.content.weatherMetric?.titleKey ?? "Thời tiết")
        }
    }
    private var time: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: WatchText.language(language))
        formatter.dateFormat = entry.snapshot.display.use24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: entry.date)
    }
    private var detail: String {
        guard entry.snapshot.enabled else { return entry.configuration.content.weatherMetric == nil ? text("Mở Terrarium để chọn cây") : "—" }
        switch entry.configuration.content {
        case .plant: return text(restful ? "Nghỉ ngơi" : "Chào ngày mới")
        case .clock:
            return entry.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)
                .locale(Locale(identifier: WatchText.language(language))))
        case .schedule:
            guard entry.snapshot.scheduleEnabled else { return text("Bật lịch trên iPhone") }
            // Schedule content follows the sleep interval, independent of a forced sky theme.
            let minutes = isSleepInterval ? entry.snapshot.wakeMinutes : entry.snapshot.bedMinutes
            let date = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: entry.date) ?? entry.date
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: WatchText.language(language))
            formatter.dateFormat = entry.snapshot.display.use24HourTime ? "HH:mm" : "h:mm a"
            return formatter.string(from: date)
        default:
            guard let weather = freshWeather, let metric = entry.configuration.content.weatherMetric else { return "—" }
            return metric.value(in: weather, fahrenheit: entry.configuration.fahrenheit, language: language)
        }
    }
    private var isSleepInterval: Bool {
        var scheduled = entry.snapshot
        scheduled.theme = .schedule
        let state = GardenSkyState.resolve(at: entry.date, snapshot: scheduled)
        return state.phase == .night || state.phase == .dusk
    }
    private var icon: String {
        switch entry.configuration.content {
        case .plant: return "leaf.fill"
        case .schedule: return isSleepInterval ? "sun.max.fill" : "moon.fill"
        case .clock: return "clock.fill"
        case .weather: return freshWeather?.symbolName ?? "cloud.sun.fill"
        default: return entry.configuration.content.weatherMetric?.icon ?? "cloud.sun.fill"
        }
    }
    private var freshWeather: WatchWeatherSnapshot? {
        guard entry.snapshot.enabled, let weather = entry.snapshot.weather,
              weather.isFresh(at: entry.date) else { return nil }
        return weather
    }
    @ViewBuilder private var providerMark: some View {
        if let data = freshWeather?.attributionMark, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFit().frame(width: 44, height: 9)
                .accessibilityLabel("Apple Weather")
        } else { Text("Apple Weather").font(.system(size: 7)) }
    }
    @ViewBuilder private var weatherWidget: some View {
        switch family {
        case .accessoryInline:
            Label("\(detail) · Weather", systemImage: icon)
        case .accessoryCorner:
            Image(systemName: icon).widgetAccentable()
                .widgetLabel { Text("\(detail) · Weather") }
        default:
            VStack(spacing: 1) {
                if family == .accessoryRectangular {
                    HStack(spacing: 6) {
                        Image(systemName: icon).font(.title2).widgetAccentable()
                        VStack(alignment: .leading, spacing: 1) {
                            Text(title).font(.caption).lineLimit(1)
                            Text(detail).font(.title3).monospacedDigit().lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    if freshWeather == nil { Text(text("Mở iPhone để cập nhật")).font(.caption2).lineLimit(1) }
                } else {
                    Image(systemName: icon).font(.caption).widgetAccentable()
                    Text(detail).font(.system(size: 13, weight: .semibold)).minimumScaleFactor(0.6).lineLimit(1)
                }
                providerMark
            }
        }
    }
    @ViewBuilder private var artwork: some View {
        if entry.configuration.content == .plant, entry.snapshot.enabled,
           let data = entry.snapshot.artwork, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFit()
        } else { Image(systemName: icon).font(.title2).widgetAccentable() }
    }
    @ViewBuilder private var gardenWidget: some View {
        switch family {
        case .accessoryInline:
            Label(entry.configuration.content == .plant ? title : "\(title) · \(detail)", systemImage: icon)
        case .accessoryCorner:
            artwork.widgetLabel { Text(detail) }
        case .accessoryCircular:
            if entry.configuration.content == .plant { artwork }
            else {
                VStack(spacing: 2) {
                    Image(systemName: icon).widgetAccentable()
                    Text(entry.configuration.content == .clock ? time : detail)
                        .font(.caption2).minimumScaleFactor(0.5).lineLimit(1)
                }
            }
        default:
            HStack(spacing: 6) {
                artwork.frame(width: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.configuration.content == .schedule
                         ? text(isSleepInterval ? "Giờ thức dậy" : "Giờ đi ngủ") : title)
                        .font(.headline).lineLimit(1).minimumScaleFactor(0.6)
                    Text(detail).font(.caption2).lineLimit(2)
                }
            }
        }
    }
    var body: some View {
        Group {
            if entry.configuration.content.weatherMetric != nil { weatherWidget }
            else { gardenWidget }
        }
        .containerBackground(for: .widget) { Color.clear }
        .environment(\.locale, Locale(identifier: WatchText.language(language)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(detail)")
        .widgetURL(entry.configuration.content.weatherMetric == nil ? nil : URL(string: "terrariumwatch://weather"))
    }
}

@main
struct TerrariumComplication: Widget {
    let kind = "TerrariumGarden"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GardenWidgetIntent.self, provider: GardenProvider()) { entry in
            GardenComplicationView(entry: entry)
        }
        .configurationDisplayName("Terrarium")
        .description(Text("Một góc vườn nhỏ trên mặt đồng hồ của bạn.", tableName: "WatchLocalizable"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

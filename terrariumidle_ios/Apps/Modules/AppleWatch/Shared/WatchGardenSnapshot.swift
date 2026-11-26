import Foundation

enum GardenClockStyle: String, Codable, CaseIterable {
    case digital, analog
}

enum GardenClockTheme: String, Codable, CaseIterable {
    case schedule, light, dark
}

enum GardenClockLayout: String, Codable, CaseIterable {
    case balanced, plantFocus, sideBySide
}

enum GardenClockFont: String, Codable, CaseIterable {
    case rounded, classic, monospaced
}

enum GardenAccent: String, Codable, CaseIterable {
    case mint, amber, lavender, ocean, rose
}

struct GardenClockAppearance: Codable, Equatable {
    var layout: GardenClockLayout = .balanced
    var font: GardenClockFont = .rounded
    var accent: GardenAccent = .mint
    var plantScale = 1.0
    var showDate = true
    var showPlantName = true
    var showSeconds = false
    var use24HourTime = true
    var animatePlant = true

    var isValid: Bool { plantScale.isFinite && (0.7...1.3).contains(plantScale) }
}

/// A display-only projection. Never contains wallet, rewards, or garden mutations.
struct WatchGardenSnapshot: Codable, Equatable {
    static let schemaVersion = 1
    static let contextKey = "terrarium.watch.snapshot"
    var version = schemaVersion
    var updatedAt = Date()
    var enabled = false
    var plantName = "Terrarium"
    var artwork: Data?
    var clockStyle: GardenClockStyle = .digital
    var theme: GardenClockTheme = .schedule
    var scheduleEnabled = false
    var bedMinutes = 22 * 60
    var wakeMinutes = 6 * 60
    // Optional additions keep snapshots from the initial release decodable.
    var appearance: GardenClockAppearance?
    var languageCode: String?
    var weather: WatchWeatherSnapshot?
    var plantLevel: Int?
    var display: GardenClockAppearance { appearance ?? GardenClockAppearance() }
    // Only a recent aggregate; no raw Health samples leave the phone.
    var sleepSeconds: Double?
    var sleepMeasuredAt: Date?

    var isValid: Bool {
        version == Self.schemaVersion && (0..<1440).contains(bedMinutes)
            && (0..<1440).contains(wakeMinutes)
            && (artwork?.count ?? 0) <= 48_000
            && (sleepSeconds.map { $0.isFinite && (0...86400).contains($0) } ?? true)
            && (appearance?.isValid ?? true)
            && (weather?.isValid ?? true)
    }
}

/// Temporary, location-free projection of Apple Weather data, not a forecast history.
struct WatchWeatherSnapshot: Codable, Equatable {
    var measuredAt: Date
    var expiresAt: Date
    var temperatureCelsius: Double
    var feelsLikeCelsius: Double
    var uvIndex: Int
    var humidity: Double
    var windKilometersPerHour: Double
    var rainChance: Double?
    var symbolName: String
    var legalURL: URL
    var attributionMark: Data?

    var isValid: Bool {
        temperatureCelsius.isFinite && feelsLikeCelsius.isFinite
            && (0...100).contains(uvIndex) && humidity.isFinite && (0...1).contains(humidity)
            && windKilometersPerHour.isFinite && windKilometersPerHour >= 0
            && (rainChance.map { $0.isFinite && (0...1).contains($0) } ?? true)
            && expiresAt > measuredAt && (attributionMark?.count ?? 0) <= 5_000
            && legalURL.scheme == "https"
    }

    func isFresh(at date: Date) -> Bool {
        isValid && measuredAt <= date.addingTimeInterval(300) && date < expiresAt
            && date.timeIntervalSince(measuredAt) < 3600
    }
}

enum GardenWeatherMetric: String, CaseIterable {
    case weather, temperature, feelsLike, uv, humidity, wind, rain

    var titleKey: String {
        switch self {
        case .weather: return "Thời tiết"
        case .temperature: return "Nhiệt độ"
        case .feelsLike: return "Cảm giác như"
        case .uv: return "Chỉ số UV"
        case .humidity: return "Độ ẩm"
        case .wind: return "Gió"
        case .rain: return "Khả năng mưa"
        }
    }
    var icon: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .temperature, .feelsLike: return "thermometer.medium"
        case .uv: return "sun.max.fill"
        case .humidity: return "humidity.fill"
        case .wind: return "wind"
        case .rain: return "cloud.rain.fill"
        }
    }
    func value(in weather: WatchWeatherSnapshot, fahrenheit: Bool, language: String?) -> String {
        let locale = Locale(identifier: WatchText.language(language))
        func number(_ value: Double) -> String {
            value.formatted(.number.precision(.fractionLength(0)).locale(locale))
        }
        switch self {
        case .weather, .temperature, .feelsLike:
            let celsius = self == .feelsLike ? weather.feelsLikeCelsius : weather.temperatureCelsius
            return number(fahrenheit ? celsius * 9 / 5 + 32 : celsius) + (fahrenheit ? "°F" : "°C")
        case .uv: return number(Double(weather.uvIndex))
        case .humidity: return (weather.humidity).formatted(.percent.precision(.fractionLength(0)).locale(locale))
        case .wind: return number(weather.windKilometersPerHour) + " km/h"
        case .rain: return weather.rainChance.map { $0.formatted(.percent.precision(.fractionLength(0)).locale(locale)) } ?? "—"
        }
    }
}

enum GardenDayPhase: String {
    case dawn, day, dusk, night
}

struct GardenSkyState {
    let phase: GardenDayPhase
    let progress: Double

    /// Transitions start at the user's wake/bed time and last at most 30 minutes.
    /// Modular wall-clock arithmetic supports overnight and daytime sleep schedules.
    static func resolve(at date: Date, snapshot: WatchGardenSnapshot,
                        calendar: Calendar = .current) -> Self {
        if snapshot.theme == .light { return Self(phase: .day, progress: 1) }
        if snapshot.theme == .dark { return Self(phase: .night, progress: 1) }
        guard snapshot.scheduleEnabled, snapshot.bedMinutes != snapshot.wakeMinutes else {
            return Self(phase: .day, progress: 1)
        }
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let minute = Double((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
            + Double(parts.second ?? 0) / 60
        let sinceWake = (minute - Double(snapshot.wakeMinutes) + 1440)
            .truncatingRemainder(dividingBy: 1440)
        let awakeLength = Double((snapshot.bedMinutes - snapshot.wakeMinutes + 1440) % 1440)
        if sinceWake < awakeLength {
            let duration = min(30, awakeLength / 2)
            return sinceWake < duration
                ? Self(phase: .dawn, progress: sinceWake / duration)
                : Self(phase: .day, progress: 1)
        }
        let sinceBed = sinceWake - awakeLength
        let duration = min(30, (1440 - awakeLength) / 2)
        return sinceBed < duration
            ? Self(phase: .dusk, progress: sinceBed / duration)
            : Self(phase: .night, progress: 1)
    }
}

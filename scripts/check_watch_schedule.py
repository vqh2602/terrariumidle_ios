"""Run standalone Foundation schedule checks without building any app target."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / 'terrariumidle_ios/Apps/Modules/AppleWatch/Shared/WatchGardenSnapshot.swift'
checks = r'''
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
func instant(_ hour: Int, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: 26, hour: hour, minute: minute))!
}
var snapshot = WatchGardenSnapshot()
snapshot.scheduleEnabled = true
func check(_ hour: Int, _ minute: Int = 0, _ phase: GardenDayPhase) {
    let actual = GardenSkyState.resolve(at: instant(hour, minute), snapshot: snapshot, calendar: calendar)
    precondition(actual.phase == phase, "Unexpected phase at \(hour):\(minute): \(actual.phase)")
    precondition((0...1).contains(actual.progress))
}
check(5, 59, .night)
check(6, 0, .dawn)
check(6, 15, .dawn)
precondition(GardenSkyState.resolve(at: instant(6, 15), snapshot: snapshot, calendar: calendar).progress == 0.5)
check(6, 30, .day)
check(21, 59, .day)
check(22, 0, .dusk)
check(22, 15, .dusk)
check(22, 30, .night)
check(0, 0, .night)
// A daytime sleeper: wake before midnight, bed after midnight.
snapshot.wakeMinutes = 23 * 60 + 50
snapshot.bedMinutes = 8 * 60
check(23, 55, .dawn)
check(0, 5, .dawn)
check(0, 20, .day)
check(8, 0, .dusk)
check(9, 0, .night)
// Tiny awake intervals must not overlap their transition windows.
snapshot.wakeMinutes = 6 * 60
snapshot.bedMinutes = 6 * 60 + 10
check(6, 4, .dawn)
check(6, 5, .day)
check(6, 10, .dusk)
snapshot.bedMinutes = snapshot.wakeMinutes
check(6, 0, .day)
snapshot.scheduleEnabled = false
check(23, 0, .day)
snapshot.theme = .dark
check(12, 0, .night)
snapshot.theme = .light
check(0, 0, .day)
// Device-local wall-clock times survive a timezone change and DST dates.
snapshot = WatchGardenSnapshot()
snapshot.scheduleEnabled = true
calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
for day in [(2026, 3, 8), (2026, 11, 1)] {
    let date = calendar.date(from: DateComponents(year: day.0, month: day.1, day: day.2, hour: 6, minute: 15))!
    let sky = GardenSkyState.resolve(at: date, snapshot: snapshot, calendar: calendar)
    precondition(sky.phase == .dawn && sky.progress == 0.5)
}
snapshot.enabled = true
snapshot.appearance = GardenClockAppearance()
snapshot.languageCode = "zh-Hans"
snapshot.artwork = Data(repeating: 1, count: 48_000)
let encoded = try JSONEncoder().encode(snapshot)
precondition(encoded.count < 65_000)
let decoded = try JSONDecoder().decode(WatchGardenSnapshot.self, from: encoded)
precondition(decoded == snapshot && decoded.isValid)
var legacy = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
legacy.removeValue(forKey: "appearance")
legacy.removeValue(forKey: "languageCode")
let old = try JSONDecoder().decode(WatchGardenSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
precondition(old.isValid && old.display == GardenClockAppearance())
var appearance = GardenClockAppearance()
appearance.plantScale = 0.69
precondition(!appearance.isValid)
appearance.plantScale = 1.31
precondition(!appearance.isValid)
appearance.plantScale = 1.3
precondition(appearance.isValid)
for code in ["vi", "en", "ja", "zh-Hans", "ko"] { precondition(WatchText.language(code) == code) }
precondition(WatchText.language("ja-JP") == "ja")
precondition(WatchText.language("zh-TW") == "zh-Hans")
precondition(WatchText.language("fr-FR") == "en")

// A weather reading must expire; unavailable values never become made-up zeroes.
let weatherNow = instant(12)
var weather = WatchWeatherSnapshot(
    measuredAt: weatherNow, expiresAt: weatherNow.addingTimeInterval(1800),
    temperatureCelsius: 30, feelsLikeCelsius: 32, uvIndex: 0, humidity: 0.75,
    windKilometersPerHour: 12, rainChance: nil, symbolName: "sun.max.fill",
    legalURL: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!,
    attributionMark: Data(repeating: 0, count: 5000))
precondition(weather.isValid && weather.isFresh(at: weatherNow))
precondition(!weather.isFresh(at: weatherNow.addingTimeInterval(1800)))
precondition(!weather.isFresh(at: weatherNow.addingTimeInterval(-301)))
precondition(GardenWeatherMetric.temperature.value(in: weather, fahrenheit: false, language: "en") == "30°C")
precondition(GardenWeatherMetric.temperature.value(in: weather, fahrenheit: true, language: "en") == "86°F")
precondition(GardenWeatherMetric.uv.value(in: weather, fahrenheit: false, language: "en") == "0")
precondition(GardenWeatherMetric.rain.value(in: weather, fahrenheit: false, language: "en") == "—")
precondition(GardenWeatherMetric.humidity.value(in: weather, fahrenheit: false, language: "en") == "75%")
weather.humidity = 1.1
precondition(!weather.isValid)
weather.humidity = 0.75
weather.uvIndex = -1
precondition(!weather.isValid)
weather.uvIndex = 7
var withWeather = snapshot
withWeather.artwork = Data(repeating: 1, count: 40000)
withWeather.weather = weather
let weatherData = try JSONEncoder().encode(withWeather)
precondition(weatherData.count < 65000)
let weatherRoundTrip = try JSONDecoder().decode(WatchGardenSnapshot.self, from: weatherData)
precondition(weatherRoundTrip == withWeather)
legacy.removeValue(forKey: "weather")
let legacyWeather = try JSONDecoder().decode(WatchGardenSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
precondition(legacyWeather.weather == nil)

snapshot.version = 99
precondition(!snapshot.isValid)
snapshot.version = WatchGardenSnapshot.schemaVersion
snapshot.wakeMinutes = -1
precondition(!snapshot.isValid)
snapshot.wakeMinutes = 360
snapshot.artwork = Data(repeating: 0, count: 48_001)
precondition(!snapshot.isValid)
print("PASS: day/night boundaries, overnight/daytime sleep, short/equal schedules, themes, timezones/DST, payload round-trip/legacy decoding, appearance limits, language selection, weather expiry/validation, units and payload size")
'''
with tempfile.TemporaryDirectory(prefix='terrarium-watch-check-') as temporary:
    script = Path(temporary) / 'main.swift'
    script.write_text(source.read_text() + '\n' + source.with_name("WatchText.swift").read_text() + '\n' + checks)
    subprocess.run(['swift', str(script)], check=True)

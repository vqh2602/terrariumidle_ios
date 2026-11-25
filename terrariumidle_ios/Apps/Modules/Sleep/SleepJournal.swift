import Foundation

struct ManualSleepEntry: Codable, Identifiable {
    var id = UUID()
    let start: Date
    let end: Date
    let feeling: String
    var exported = false
    var interval: DateInterval { DateInterval(start: start, end: end) }
}

enum SleepJournal {
    static func isValid(start: Date, end: Date, now: Date = .now) -> Bool {
        start < end && end <= now && end.timeIntervalSince(start) <= 24 * 3600
    }

    static func average(_ days: [SleepDay]) -> TimeInterval? {
        let recorded = days.filter { $0.seconds > 0 }
        guard !recorded.isEmpty else { return nil }
        return recorded.reduce(0) { $0 + $1.seconds } / Double(recorded.count)
    }

    static func scheduledHours(bedMinutes: Int, wakeMinutes: Int) -> Double {
        Double((wakeMinutes - bedMinutes + 1440) % 1440) / 60
    }
}

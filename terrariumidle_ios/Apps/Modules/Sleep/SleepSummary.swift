import Foundation

/// A reporting day ends at noon, keeping a night across midnight in one bucket.
/// Union intervals before summing: Watch stages and other sources can overlap.
struct SleepDay: Identifiable, Equatable {
    let date: Date
    let seconds: TimeInterval
    var id: String { SleepSummary.dayKey(date) }
    var hours: Double { seconds / 3600 }
}

enum SleepSummary {
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func window(for date: Date, calendar: Calendar = .current) -> DateInterval {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date)!
        return DateInterval(start: calendar.date(byAdding: .day, value: -1, to: noon)!, end: noon)
    }

    static func days(intervals: [DateInterval], from start: Date, through end: Date,
                     calendar: Calendar = .current) -> [SleepDay] {
        let ordered = intervals.filter { $0.duration > 0 }.sorted { $0.start < $1.start }
        var merged: [DateInterval] = []
        for interval in ordered {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else { merged.append(interval) }
        }
        var result: [SleepDay] = []
        var date = calendar.startOfDay(for: start)
        let lastDate = calendar.startOfDay(for: end)
        while date <= lastDate {
            let window = window(for: date, calendar: calendar)
            let seconds = merged.reduce(0.0) { total, interval in
                total + max(0, min(interval.end, window.end).timeIntervalSince(max(interval.start, window.start)))
            }
            result.append(SleepDay(date: date, seconds: seconds))
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return result
    }

    static func canClaim(_ day: SleepDay, goal: Double, now: Date = .now,
                         calendar: Calendar = .current) -> Bool {
        guard goal.isFinite, (6...10).contains(goal) else { return false }
        let today = calendar.startOfDay(for: now)
        let earliest = calendar.date(byAdding: .day, value: -6, to: today)!
        return day.date >= earliest && day.date <= today && day.hours >= goal
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds / 60))
        return "%d giờ %d phút".tr(minutes / 60, minutes % 60)
    }
}

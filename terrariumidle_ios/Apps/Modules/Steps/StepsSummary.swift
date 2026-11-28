import Foundation

struct StepsDay: Identifiable, Equatable {
    let date: Date
    let steps: Int
    var id: String { StepsSummary.dayKey(date) }
}

enum StepsSummary {
    static let goalStorageKey = "steps.goalCount"
    static let defaultGoal = 8_000
    static let minGoal = 2_000
    static let maxGoal = 30_000
    static let goalStep = 500
    static let presetGoals = [5_000, 8_000, 10_000, 12_000, 15_000]

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        SleepSummary.dayKey(date, calendar: calendar)
    }

    static func isValidGoal(_ goal: Int) -> Bool {
        (minGoal...maxGoal).contains(goal)
    }

    static func clampedGoal(_ goal: Int) -> Int {
        min(max(goal, minGoal), maxGoal)
    }

    static func days(
        countsByDayKey: [String: Int],
        from start: Date,
        through end: Date,
        calendar: Calendar = .current
    ) -> [StepsDay] {
        var result: [StepsDay] = []
        var date = calendar.startOfDay(for: start)
        let lastDate = calendar.startOfDay(for: end)
        while date <= lastDate {
            let key = dayKey(date, calendar: calendar)
            let steps = max(0, countsByDayKey[key] ?? 0)
            result.append(StepsDay(date: date, steps: steps))
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return result
    }

    static func canClaim(
        _ day: StepsDay,
        goal: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard isValidGoal(goal) else { return false }
        let today = calendar.startOfDay(for: now)
        let earliest = calendar.date(byAdding: .day, value: -6, to: today)!
        return day.date >= earliest && day.date <= today && day.steps >= goal
    }

    static func average(_ days: [StepsDay]) -> Int? {
        let recorded = days.filter { $0.steps > 0 }
        guard !recorded.isEmpty else { return nil }
        let total = recorded.reduce(0) { $0 + $1.steps }
        return Int((Double(total) / Double(recorded.count)).rounded())
    }

    static func formatted(_ steps: Int) -> String {
        steps.formatted(.number.grouping(.automatic).locale(LocalizationManager.shared.currentLanguage.locale))
    }

    static func countLabel(_ steps: Int) -> String {
        "%@ bước".tr(formatted(steps))
    }
}

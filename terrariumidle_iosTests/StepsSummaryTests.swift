import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct StepsSummaryTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func daysFillMissingDaysWithZeroAndClampNegatives() {
        let start = date("2026-11-22T00:00:00Z")
        let end = date("2026-11-24T00:00:00Z")
        let counts = [
            "2026-11-22": 9_200,
            "2026-11-24": -50
        ]
        let days = StepsSummary.days(countsByDayKey: counts, from: start, through: end, calendar: calendar)
        #expect(days.map(\.steps) == [9_200, 0, 0])
    }

    @Test func rewardWindowIncludesSevenDaysAndRespectsGoalBounds() {
        let now = date("2026-11-24T03:00:00Z")
        func day(_ offset: Int, steps: Int = 8_000) -> StepsDay {
            StepsDay(date: calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!,
                     steps: steps)
        }
        #expect(StepsSummary.canClaim(day(-6), goal: 8_000, now: now, calendar: calendar))
        #expect(!StepsSummary.canClaim(day(-7), goal: 8_000, now: now, calendar: calendar))
        #expect(!StepsSummary.canClaim(day(1), goal: 8_000, now: now, calendar: calendar))
        #expect(!StepsSummary.canClaim(day(0, steps: 7_999), goal: 8_000, now: now, calendar: calendar))
        #expect(!StepsSummary.canClaim(day(0, steps: 10_000), goal: 500, now: now, calendar: calendar))
        #expect(!StepsSummary.canClaim(day(0, steps: 50_000), goal: 40_000, now: now, calendar: calendar))
    }

    @Test func averageExcludesZeroDays() {
        let now = date("2026-11-24T03:00:00Z")
        #expect(StepsSummary.average([]) == nil)
        #expect(StepsSummary.average([StepsDay(date: now, steps: 0)]) == nil)
        let avg = StepsSummary.average([
            StepsDay(date: now, steps: 0),
            StepsDay(date: now, steps: 6_000),
            StepsDay(date: now, steps: 10_000)
        ])
        #expect(avg == 8_000)
    }

    @Test func clampedGoalStaysWithinConfiguredLimits() {
        #expect(StepsSummary.clampedGoal(100) == StepsSummary.minGoal)
        #expect(StepsSummary.clampedGoal(10_000) == 10_000)
        #expect(StepsSummary.clampedGoal(99_999) == StepsSummary.maxGoal)
    }
}

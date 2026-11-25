import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct SleepSummaryTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")!
        return calendar
    }
    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func overlappingSourcesCountOnceAcrossMidnight() {
        let end = date("2026-11-24T00:00:00Z") // 07:00 local
        let start = date("2026-11-23T16:00:00Z") // 23:00 local
        let intervals = [DateInterval(start: start, end: end),
                         DateInterval(start: start.addingTimeInterval(3600), end: end),
                         DateInterval(start: start, end: end)]
        let days = SleepSummary.days(intervals: intervals, from: end, through: end, calendar: calendar)
        #expect(days.count == 1)
        #expect(days[0].seconds == 8 * 3600)
    }

    @Test func gapsAndAwakeningsDoNotBecomeSleep() {
        let morning = date("2026-11-24T00:00:00Z")
        let days = SleepSummary.days(intervals: [
            DateInterval(start: morning.addingTimeInterval(-8 * 3600), end: morning.addingTimeInterval(-4 * 3600)),
            DateInterval(start: morning.addingTimeInterval(-3 * 3600), end: morning)
        ], from: morning, through: morning, calendar: calendar)
        #expect(days[0].seconds == 7 * 3600)
    }

    @Test func rewardWindowIncludesSevenDaysButExcludesFutureAndShortSleep() {
        let now = date("2026-11-24T03:00:00Z")
        func day(_ offset: Int, hours: Double = 8) -> SleepDay {
            SleepDay(date: calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!,
                     seconds: hours * 3600)
        }
        #expect(SleepSummary.canClaim(day(-6), goal: 8, now: now, calendar: calendar))
        #expect(!SleepSummary.canClaim(day(-7), goal: 8, now: now, calendar: calendar))
        #expect(!SleepSummary.canClaim(day(1), goal: 8, now: now, calendar: calendar))
        #expect(!SleepSummary.canClaim(day(0, hours: 7.99), goal: 8, now: now, calendar: calendar))
    }

    @Test func daylightSavingUsesCalendarDaysInsteadOfFixed24Hours() {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let spring = SleepSummary.window(for: date("2026-03-08T19:00:00Z"), calendar: local)
        let autumn = SleepSummary.window(for: date("2026-11-01T20:00:00Z"), calendar: local)
        #expect(spring.duration == 23 * 3600)
        #expect(autumn.duration == 25 * 3600)
    }

    @Test func missingDataIsZeroAndNoonSplitsWithoutDuplication() {
        let noon = date("2026-11-24T05:00:00Z")
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: noon)!
        let days = SleepSummary.days(intervals: [DateInterval(start: noon.addingTimeInterval(-3600),
                                                            end: noon.addingTimeInterval(3600))],
                                     from: noon, through: tomorrow, calendar: calendar)
        #expect(days.map(\.seconds) == [3600, 3600])
        let empty = SleepSummary.days(intervals: [], from: noon, through: noon, calendar: calendar)
        #expect(empty[0].seconds == 0)
    }
    @Test func manualEntryValidationRejectsFutureReversedAndOverlongSleep() {
        let now = date("2026-11-24T03:00:00Z")
        #expect(SleepJournal.isValid(start: now.addingTimeInterval(-8 * 3600), end: now, now: now))
        #expect(!SleepJournal.isValid(start: now, end: now, now: now))
        #expect(!SleepJournal.isValid(start: now, end: now.addingTimeInterval(60), now: now))
        #expect(!SleepJournal.isValid(start: now.addingTimeInterval(-25 * 3600), end: now, now: now))
    }

    @Test func averageExcludesMissingDaysAndScheduleCrossesMidnight() {
        let now = date("2026-11-24T03:00:00Z")
        #expect(SleepJournal.average([]) == nil)
        #expect(SleepJournal.average([SleepDay(date: now, seconds: 0), SleepDay(date: now, seconds: 8 * 3600)]) == 8 * 3600)
        #expect(SleepJournal.scheduledHours(bedMinutes: 22 * 60, wakeMinutes: 6 * 60) == 8)
    }

    @Test func journalRoundTripPreservesExportChoiceAndOverlapsHealthOnlyOnce() throws {
        let end = date("2026-11-24T00:00:00Z")
        let entry = ManualSleepEntry(start: end.addingTimeInterval(-8 * 3600), end: end,
                                     feeling: "Sảng khoái", wantsExport: false)
        let restored = try JSONDecoder().decode(ManualSleepEntry.self, from: JSONEncoder().encode(entry))
        #expect(restored.id == entry.id)
        #expect(restored.wantsExport == false)
        #expect(!restored.exported)
        let days = SleepSummary.days(intervals: [restored.interval, restored.interval], from: end,
                                     through: end, calendar: calendar)
        #expect(days[0].hours == 8)
    }

}

import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct SleepRewardRulesTests {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    private func days(year: Int = 2026, month: Int = 11, count: Int) -> [SleepDay] {
        let start = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        return (0..<count).map {
            SleepDay(date: calendar.date(byAdding: .day, value: $0, to: start)!, seconds: 8 * 3600)
        }
    }
    private func rewards(_ days: [SleepDay], covered: Set<String> = [], claimed: Set<String> = []) -> [SleepRewardGrant] {
        SleepRewardRules.available(days: days, goal: 8, claimed: claimed, weeklyDays: covered,
                                   now: days.last!.date.addingTimeInterval(3600), calendar: calendar)
    }

    @Test func seventhDayStacksDailyAndWeeklyPrizes() {
        let grants = rewards(days(count: 7))
        #expect(grants.filter { $0.kind == .daily }.count == 7)
        #expect(grants.filter { $0.kind == .daily }.allSatisfy { $0.oxygen == 1000 })
        let weekly = grants.filter { $0.kind == .weekly }
        #expect(weekly.count == 1)
        #expect(weekly.first?.gems == 10)
        #expect(weekly.first?.tickets == 0)
        #expect(!grants.contains { $0.kind == .monthly })
    }

    @Test func shortOrMissingNightBreaksStreak() {
        var records = days(count: 10)
        records[4] = SleepDay(date: records[4].date, seconds: 7 * 3600)
        #expect(!rewards(records).contains { $0.kind == .weekly })
        records.remove(at: 4)
        #expect(!rewards(records).contains { $0.kind == .weekly })
    }

    @Test func weeklyDaysCannotBeReusedButNextSevenCanEarnAgain() {
        let records = days(count: 14)
        let covered = Set(records.prefix(7).map(\.id))
        let grants = rewards(records, covered: covered)
        let weekly = grants.filter { $0.kind == .weekly }
        #expect(weekly.count == 1)
        #expect(weekly[0].days.map(\.id) == Array(records.suffix(7)).map(\.id))
        #expect(!rewards(records, covered: Set(records.map(\.id))).contains { $0.kind == .weekly })
    }

    @Test func completeCalendarMonthGrantsGemsAndTicket() {
        for (year, month, count) in [(2026, 11, 30), (2026, 12, 31), (2028, 2, 29), (2027, 2, 28)] {
            let records = days(year: year, month: month, count: count)
            let monthly = rewards(records).filter { $0.kind == .monthly }
            #expect(monthly.count == 1)
            #expect(monthly[0].gems == 20)
            #expect(monthly[0].tickets == 1)
            #expect(monthly[0].oxygen == 0)
            #expect(!rewards(Array(records.dropFirst())).contains { $0.kind == .monthly })
            #expect(!rewards(Array(records.dropLast())).contains { $0.kind == .monthly })
            #expect(!rewards(records, claimed: [monthly[0].id]).contains { $0.kind == .monthly })
        }
    }

    @Test func monthlyAndWeeklyAwardsStackWithoutReusingWeeks() {
        let records = days(year: 2027, month: 2, count: 28)
        let covered = Set(records.prefix(21).map(\.id))
        let grants = rewards(records, covered: covered)
        #expect(grants.filter { $0.kind == .weekly }.count == 1)
        #expect(grants.filter { $0.kind == .monthly }.count == 1)
        #expect(grants.reduce(0) { $0 + $1.gems } == 30)
        #expect(grants.reduce(0) { $0 + $1.tickets } == 1)
    }

    @Test func invalidOrExpiredMilestonesCannotBeClaimed() {
        let records = days(count: 7)
        let weekly = SleepRewardGrant(kind: .weekly, days: records)
        let expired = calendar.date(byAdding: .day, value: 7, to: weekly.endDate)!
        #expect(!SleepRewardRules.isValid(weekly, goal: 8, now: expired, calendar: calendar))
        #expect(!SleepRewardRules.isValid(weekly, goal: 0, now: weekly.endDate, calendar: calendar))
        #expect(!SleepRewardRules.isValid(SleepRewardGrant(kind: .weekly, days: Array(records.prefix(6))),
                                         goal: 8, now: weekly.endDate, calendar: calendar))
        #expect(!SleepRewardRules.isValid(SleepRewardGrant(kind: .monthly, days: []),
                                         goal: 8, now: weekly.endDate, calendar: calendar))
    }
}

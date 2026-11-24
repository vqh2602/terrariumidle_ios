import Foundation

struct SleepRewardGrant: Identifiable {
    enum Kind: String { case daily, weekly, monthly }
    let kind: Kind
    let days: [SleepDay]
    var endDate: Date { days.last!.date }
    var id: String {
        let key = SleepSummary.dayKey(endDate)
        return kind == .daily ? key : "\(kind.rawValue)-\(key)"
    }
    var oxygen: Int { kind == .daily ? 1_000 : 0 }
    var gems: Int { kind == .weekly ? 10 : kind == .monthly ? 20 : 0 }
    var tickets: Int { kind == .monthly ? 1 : 0 }
    var title: String {
        switch kind {
        case .daily: return "Ngày \(endDate.formatted(.dateTime.day().month()))"
        case .weekly: return "7 ngày liên tiếp · \(endDate.formatted(.dateTime.day().month()))"
        case .monthly: return "Trọn tháng \(endDate.formatted(.dateTime.month().year()))"
        }
    }
    var prize: String {
        switch kind {
        case .daily: return "1.000 Oxy"
        case .weekly: return "10 gem"
        case .monthly: return "20 gem + 1 ticket"
        }
    }
}

enum SleepRewardRules {
    static func isValid(_ grant: SleepRewardGrant, goal: Double, now: Date = .now,
                        calendar: Calendar = .current) -> Bool {
        guard !grant.days.isEmpty, SleepSummary.canClaim(grant.days.last!, goal: goal, now: now, calendar: calendar),
              grant.days.allSatisfy({ $0.hours >= goal && $0.date == calendar.startOfDay(for: $0.date) }) else { return false }
        for pair in zip(grant.days, grant.days.dropFirst()) {
            guard calendar.date(byAdding: .day, value: 1, to: pair.0.date) == pair.1.date else { return false }
        }
        switch grant.kind {
        case .daily: return grant.days.count == 1
        case .weekly: return grant.days.count == 7
        case .monthly:
            guard let month = calendar.dateInterval(of: .month, for: grant.endDate),
                  let count = calendar.range(of: .day, in: .month, for: grant.endDate)?.count else { return false }
            return grant.days.count == count && grant.days.first?.date == month.start &&
                calendar.date(byAdding: .day, value: 1, to: grant.endDate) == month.end
        }
    }

    /// Weeks repeat after each seven qualifying days. Previously rewarded days cannot be reused.
    /// Monthly awards cover a complete calendar month and stack with daily/weekly awards.
    static func available(days: [SleepDay], goal: Double, claimed: Set<String>, weeklyDays: Set<String>,
                          now: Date = .now, calendar: Calendar = .current) -> [SleepRewardGrant] {
        let sorted = days.sorted { $0.date < $1.date }
        var grants = sorted.map { SleepRewardGrant(kind: .daily, days: [$0]) }
        var run: [SleepDay] = []
        for day in sorted {
            if day.hours < goal || weeklyDays.contains(SleepSummary.dayKey(day.date, calendar: calendar)) {
                run = []
                continue
            }
            if let last = run.last, calendar.date(byAdding: .day, value: 1, to: last.date) != day.date { run = [] }
            run.append(day)
            if run.count == 7 {
                grants.append(SleepRewardGrant(kind: .weekly, days: run))
                run = []
            }
        }
        let months = Dictionary(grouping: sorted) { calendar.dateInterval(of: .month, for: $0.date)!.start }
        grants += months.values.map { SleepRewardGrant(kind: .monthly, days: $0.sorted { $0.date < $1.date }) }
        return grants.filter { !claimed.contains($0.id) && isValid($0, goal: goal, now: now, calendar: calendar) }
            .sorted { $0.endDate == $1.endDate ? $0.kind.rawValue < $1.kind.rawValue : $0.endDate > $1.endDate }
    }
}

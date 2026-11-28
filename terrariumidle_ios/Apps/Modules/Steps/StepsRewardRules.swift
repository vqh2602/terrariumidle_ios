import Foundation

struct StepsRewardGrant: Identifiable {
    enum Kind: String { case daily, weekly, monthly }
    let kind: Kind
    let days: [StepsDay]
    var endDate: Date { days.last!.date }
    var id: String {
        let key = StepsSummary.dayKey(endDate)
        return kind == .daily ? key : "\(kind.rawValue)-\(key)"
    }
    var oxygen: Int { kind == .daily ? 1_000 : 0 }
    var gems: Int { kind == .weekly ? 10 : kind == .monthly ? 20 : 0 }
    var tickets: Int { kind == .monthly ? 1 : 0 }
    var title: String {
        switch kind {
        case .daily: return "Ngày %@".tr(endDate.formatted(.dateTime.day().month()))
        case .weekly: return "7 ngày liên tiếp · %@".tr(endDate.formatted(.dateTime.day().month()))
        case .monthly: return "Trọn tháng %@".tr(endDate.formatted(.dateTime.month().year()))
        }
    }
    var prize: String {
        switch kind {
        case .daily: return "1.000 Oxy".tr
        case .weekly: return "10 gem".tr
        case .monthly: return "20 gem + 1 ticket"
        }
    }
}

enum StepsRewardRules {
    static func isValid(
        _ grant: StepsRewardGrant,
        goal: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard !grant.days.isEmpty,
              StepsSummary.canClaim(grant.days.last!, goal: goal, now: now, calendar: calendar),
              grant.days.allSatisfy({ $0.steps >= goal && $0.date == calendar.startOfDay(for: $0.date) }) else {
            return false
        }
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
    static func available(
        days: [StepsDay],
        goal: Int,
        claimed: Set<String>,
        weeklyDays: Set<String>,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [StepsRewardGrant] {
        guard StepsSummary.isValidGoal(goal) else { return [] }
        let sorted = days.sorted { $0.date < $1.date }
        var grants = sorted.map { StepsRewardGrant(kind: .daily, days: [$0]) }
        var run: [StepsDay] = []
        for day in sorted {
            if day.steps < goal || weeklyDays.contains(StepsSummary.dayKey(day.date, calendar: calendar)) {
                run = []
                continue
            }
            if let last = run.last, calendar.date(byAdding: .day, value: 1, to: last.date) != day.date { run = [] }
            run.append(day)
            if run.count == 7 {
                grants.append(StepsRewardGrant(kind: .weekly, days: run))
                run = []
            }
        }
        let months = Dictionary(grouping: sorted) { calendar.dateInterval(of: .month, for: $0.date)!.start }
        grants += months.values.map { StepsRewardGrant(kind: .monthly, days: $0.sorted { $0.date < $1.date }) }
        return grants
            .filter { !claimed.contains($0.id) && isValid($0, goal: goal, now: now, calendar: calendar) }
            .sorted { $0.endDate == $1.endDate ? $0.kind.rawValue < $1.kind.rawValue : $0.endDate > $1.endDate }
    }
}

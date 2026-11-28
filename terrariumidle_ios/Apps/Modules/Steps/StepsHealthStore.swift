import Combine
import Foundation
import HealthKit

@MainActor
final class StepsHealthStore: ObservableObject {
    static let shared = StepsHealthStore()
    @Published private(set) var days: [StepsDay] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSync: Date?
    @Published private(set) var message: String?
    // This only records that the permission sheet was completed, never read authorization.
    @Published private(set) var hasRequestedAccess = UserDefaults.standard.bool(forKey: "steps.requestedAccess")
    private var healthCountsByDayKey: [String: Int] = [:]
    private let store = HKHealthStore()

    private init() {
        rebuildDays()
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private func rebuildDays() {
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))!
        days = StepsSummary.days(countsByDayKey: healthCountsByDayKey, from: start, through: now, calendar: calendar)
    }

    func connect() async {
        guard isAvailable, !isSyncing else { return }
        isSyncing = true
        message = nil
        do {
            let type = HKObjectType.quantityType(forIdentifier: .stepCount)!
            try await store.requestAuthorization(toShare: [], read: [type])
            hasRequestedAccess = true
            UserDefaults.standard.set(true, forKey: "steps.requestedAccess")
            isSyncing = false
            await sync()
        } catch {
            isSyncing = false
            message = "Chưa mở được kết nối Apple Health. Hãy thử lại.".tr
        }
    }

    func sync() async {
        rebuildDays()
        guard isAvailable, hasRequestedAccess, !isSyncing else { return }
        isSyncing = true
        message = nil
        defer { isSyncing = false }

        let now = Date()
        let calendar = Calendar.current
        // Full current year plus the preceding 12 months for month/week navigation.
        let start = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))!
        let type = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)

        do {
            let counts: [String: Int] = try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: start,
                    intervalComponents: DateComponents(day: 1)
                )
                query.initialResultsHandler = { _, collection, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    var result: [String: Int] = [:]
                    collection?.enumerateStatistics(from: start, to: now) { statistics, _ in
                        if let sum = statistics.sumQuantity() {
                            let value = Int(sum.doubleValue(for: .count()).rounded())
                            if value > 0 {
                                result[StepsSummary.dayKey(statistics.startDate, calendar: calendar)] = value
                            }
                        }
                    }
                    continuation.resume(returning: result)
                }
                store.execute(query)
            }
            healthCountsByDayKey = counts
            rebuildDays()
            lastSync = now
            HealthRewardStatusStore.shared.recalculate(notifyIfNeeded: true)
        } catch {
            // Do not keep stale records eligible for rewards after a failed query.
            healthCountsByDayKey = [:]
            rebuildDays()
            message = "Chưa đồng bộ được. Hãy kiểm tra kết nối Apple Health rồi thử lại.".tr
            HealthRewardStatusStore.shared.recalculate(notifyIfNeeded: false)
        }
    }
}

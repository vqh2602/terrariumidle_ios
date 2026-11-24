import Combine
import Foundation
import HealthKit

@MainActor
final class SleepHealthStore: ObservableObject {
    static let shared = SleepHealthStore()
    @Published private(set) var days: [SleepDay] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSync: Date?
    @Published private(set) var message: String?
    // This only records that the permission sheet was completed, never read authorization.
    @Published private(set) var hasRequestedAccess = UserDefaults.standard.bool(forKey: "sleep.requestedAccess")
    private let store = HKHealthStore()
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connect() async {
        guard isAvailable, !isSyncing else { return }
        isSyncing = true
        message = nil
        do {
            let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            try await store.requestAuthorization(toShare: [], read: [type])
            hasRequestedAccess = true
            UserDefaults.standard.set(true, forKey: "sleep.requestedAccess")
            isSyncing = false
            await sync()
        } catch {
            isSyncing = false
            message = "Chưa mở được kết nối Apple Health. Hãy thử lại."
        }
    }

    func sync() async {
        guard isAvailable, hasRequestedAccess, !isSyncing else { return }
        isSyncing = true
        message = nil
        defer { isSyncing = false }
        let now = Date()
        let calendar = Calendar.current
        // Full current year plus the preceding 12 months for month/week navigation.
        let start = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now))!
        let windowStart = SleepSummary.window(for: start).start
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: windowStart, end: now, options: [])
        do {
            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                                          sortDescriptors: nil) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples as? [HKCategorySample] ?? []) }
                }
                store.execute(query)
            }
            let asleep = Set([HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                              HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                              HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                              HKCategoryValueSleepAnalysis.asleepREM.rawValue])
            let intervals = samples.compactMap { sample -> DateInterval? in
                guard asleep.contains(sample.value), sample.startDate < sample.endDate,
                      sample.endDate <= now else { return nil }
                return DateInterval(start: sample.startDate, end: sample.endDate)
            }
            days = SleepSummary.days(intervals: intervals, from: start, through: now)
            lastSync = now
        } catch {
            // Do not keep stale records eligible for rewards after a failed query.
            days = []
            message = "Chưa đồng bộ được. Hãy kiểm tra kết nối Apple Health rồi thử lại."
        }
    }
}

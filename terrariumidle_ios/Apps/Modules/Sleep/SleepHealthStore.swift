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
    @Published private(set) var manualEntries: [ManualSleepEntry] = []
    @Published private(set) var isSaving = false
    private var healthIntervals: [DateInterval] = []
    private let store = HKHealthStore()
    private let journalURL = URL.documentsDirectory.appendingPathComponent("sleep-journal.json")

    private init() {
        if let data = try? Data(contentsOf: journalURL),
           let entries = try? JSONDecoder().decode([ManualSleepEntry].self, from: data) {
            manualEntries = entries
        }
        rebuildDays()
    }

    private func persist(_ entries: [ManualSleepEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try data.write(to: journalURL, options: [.atomic, .completeFileProtection])
        var url = journalURL
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        manualEntries = entries
        rebuildDays()
    }

    private func rebuildDays() {
        let now = Date()
        let start = Calendar.current.date(byAdding: .year, value: -1, to: Calendar.current.startOfDay(for: now))!
        days = SleepSummary.days(intervals: healthIntervals + manualEntries.map(\.interval), from: start, through: now)
    }

    func addManual(start: Date, end: Date, feeling: String, export: Bool) async -> Bool {
        guard !isSaving, !isSyncing, SleepJournal.isValid(start: start, end: end) else { return false }
        isSaving = true
        message = nil
        defer { isSaving = false }
        let entry = ManualSleepEntry(start: start, end: end, feeling: feeling, wantsExport: export)
        do {
            try persist(manualEntries + [entry])
        } catch {
            message = "Chưa lưu được nhật ký trên thiết bị. Hãy thử lại."
            return false
        }
        if export { await exportPending() }
        return true
    }

    func syncManualJournal() async {
        guard !isSyncing, !isSaving else { return }
        do {
            var entries = manualEntries
            for index in entries.indices { entries[index].wantsExport = true }
            try persist(entries)
        } catch {
            message = "Chưa lưu được lựa chọn đồng bộ. Hãy thử lại."
            return
        }
        await sync()
    }

    private func exportPending() async {
        guard manualEntries.contains(where: { !$0.exported && $0.wantsExport == true }) else { return }
        guard isAvailable else {
            message = "Đã lưu trên thiết bị; Apple Health chưa khả dụng."
            return
        }
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        guard store.authorizationStatus(for: type) == .sharingAuthorized else {
            message = "Bản ghi vẫn ở trên thiết bị. Hãy cho phép ghi Giấc ngủ qua nút Kết nối Apple Health rồi đồng bộ lại."
            return
        }
        do {
            for entry in manualEntries where !entry.exported && entry.wantsExport == true {
                let sample = HKCategorySample(type: type,
                    value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    start: entry.start, end: entry.end,
                    metadata: [HKMetadataKeyWasUserEntered: true,
                               HKMetadataKeySyncIdentifier: "terrarium.sleep.\(entry.id.uuidString)",
                               HKMetadataKeySyncVersion: 1])
                try await store.save(sample)
                var updated = manualEntries
                if let index = updated.firstIndex(where: { $0.id == entry.id }) {
                    updated[index].exported = true
                    try persist(updated)
                }
            }
        } catch {
            message = "Nhật ký đã lưu trên thiết bị. Chưa ghi được sang Apple Health; hãy thử đồng bộ lại."
        }
    }
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func connect() async {
        guard isAvailable, !isSyncing, !isSaving else { return }
        isSyncing = true
        message = nil
        do {
            let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            try await store.requestAuthorization(toShare: [type], read: [type])
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
        rebuildDays()
        guard isAvailable, hasRequestedAccess, !isSyncing, !isSaving else { return }
        isSyncing = true
        message = nil
        defer { isSyncing = false }
        await exportPending()
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
            healthIntervals = intervals
            rebuildDays()
            lastSync = now
        } catch {
            // Do not keep stale records eligible for rewards after a failed query.
            healthIntervals = []
            rebuildDays()
            message = "Chưa đồng bộ được. Hãy kiểm tra kết nối Apple Health rồi thử lại."
        }
    }
}

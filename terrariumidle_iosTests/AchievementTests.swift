import Foundation
import XCTest
@testable import terrariumidle_ios

final class AchievementTests: XCTestCase {
    func testCatalogLeavesRoomForFutureReleasesAndUsesMeaningfulThresholds() {
        let items = AchievementCatalog.all
        XCTAssertEqual(items.count, 70)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        XCTAssertEqual(items.reduce(0) { $0 + $1.points }, 700)
        XCTAssertTrue(items.allSatisfy { $0.id.utf8.count <= 100 && $0.target > 1 })
        XCTAssertEqual(items.filter { $0.metric == .plantsOwned }.map(\.target), [25, 55, 80])
        XCTAssertEqual(items.filter { $0.metric == .potsOwned }.map(\.target), [25, 55, 80])
        XCTAssertEqual(items.filter { $0.metric == .stickersOwned }.map(\.target), [4, 15, 30, 50])
        XCTAssertEqual(items.filter { $0.metric == .animalsOwned }.map(\.target), [2, 8, 16, 25])
        XCTAssertEqual(items.filter { $0.metric == .matureSpecies }.map(\.target), [5, 15, 30, 55, 80])
        XCTAssertEqual(items.filter { $0.metric == .plantLevel }.map(\.target), [10, 25, 50, 100, 150, 200])
        XCTAssertEqual(items.filter { $0.metric == .harvests }.map(\.target), [1_000, 10_000, 100_000, 1_000_000])
        for metric in AchievementMetric.allCases {
            let targets = items.filter { $0.metric == metric }.map(\.target)
            XCTAssertFalse(targets.isEmpty)
            XCTAssertEqual(targets, targets.sorted())
            XCTAssertEqual(Set(targets).count, targets.count)
        }
    }

    func testDeviceCountersDoNotDoubleCountRetriesAndDoAddIndependentDevices() {
        var phone = AchievementProgress()
        phone.increment(.harvests, device: "phone", by: 300)
        var tablet = phone
        tablet.increment(.harvests, device: "tablet", by: 50)
        phone.increment(.harvests, device: "phone", by: 10)
        phone.merge(tablet)
        phone.merge(tablet)
        XCTAssertEqual(phone.value(for: .harvests), 360)
        tablet.merge(phone)
        XCTAssertEqual(tablet, phone)
        let copy = phone
        phone.merge(copy)
        XCTAssertEqual(copy, phone)
    }

    func testCollectionAndHighWaterMarksSurviveAnOlderOrEmptyGarden() {
        var progress = AchievementProgress()
        progress.include(["plant1", "plant1", "plant2", ""], for: .matureSpecies)
        progress.observe(50, for: .plantLevel)
        var older = AchievementProgress()
        older.include(["plant1", "plant3"], for: .matureSpecies)
        older.observe(3, for: .plantLevel)
        progress.merge(older)
        progress.merge(AchievementProgress())
        XCTAssertEqual(progress.value(for: .matureSpecies), 3)
        XCTAssertEqual(progress.value(for: .plantLevel), 50)
    }

    func testProgressSurvivesDiskAndFirestoreRoundTrips() throws {
        var progress = AchievementProgress()
        progress.increment(.oxygenCollected, device: "phone", by: 123_456)
        progress.include(["2026-11-27", "2026-11-29"], for: .activeDays)
        progress.observe(100, for: .gardenerLevel)
        let decoded = try JSONDecoder().decode(AchievementProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(decoded, progress)
        XCTAssertEqual(AchievementProgress(dictionary: progress.dictionary), progress)
        XCTAssertEqual(AchievementProgress(dictionary: [:]), AchievementProgress())
    }

    func testDaysNeedNotBeConsecutiveAndUseTheLocalCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Ho_Chi_Minh"))
        let formatter = ISO8601DateFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2026-11-27T18:00:00Z"))
        XCTAssertEqual(AchievementProgress.dayID(date, calendar: calendar), "2026-11-28")
        var progress = AchievementProgress()
        progress.include(["2026-11-25", "2026-11-25", "2026-11-28"], for: .activeDays)
        XCTAssertEqual(progress.value(for: .activeDays), 2)
    }

    func testReportsNeverRegressAppleProgressOrSendUnconfiguredIDs() throws {
        let item = try XCTUnwrap(AchievementCatalog.all.first { $0.metric == .plantsOwned && $0.target == 25 })
        var progress = AchievementProgress()
        progress.include((1...10).map { "p\($0)" }, for: .plantsOwned)
        XCTAssertEqual(item.percent(for: progress), 40)
        XCTAssertTrue(AchievementReportPlan.updates(progress: progress, configured: [], reported: [:]).isEmpty)
        XCTAssertTrue(AchievementReportPlan.updates(progress: progress, configured: [item.id], reported: [item.id: 80]).isEmpty)
        XCTAssertEqual(AchievementReportPlan.updates(progress: progress, configured: [item.id], reported: [:]), [item.id: 40])
        progress.include((11...30).map { "p\($0)" }, for: .plantsOwned)
        XCTAssertEqual(item.percent(for: progress), 100)
        XCTAssertEqual(AchievementReportPlan.updates(progress: progress, configured: [item.id], reported: [item.id: 40]), [item.id: 100])
        XCTAssertTrue(AchievementReportPlan.updates(progress: progress, configured: [item.id], reported: [item.id: 100]).isEmpty)
    }

    func testInvalidCountersAndOverflowCannotProduceNegativeProgress() {
        var progress = AchievementProgress(dictionary: ["counters": ["harvests": ["bad": -1]], "maxima": ["plantLevel": -2]])
        progress.increment(.harvests, device: "phone", by: Int.max)
        progress.increment(.harvests, device: "phone", by: 1)
        progress.increment(.harvests, device: "tablet", by: 1)
        progress.increment(.harvests, device: "tablet", by: -50)
        XCTAssertEqual(progress.value(for: .harvests), Int.max)
        XCTAssertEqual(progress.value(for: .plantLevel), 0)
    }
}

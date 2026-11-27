import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct AppUpdateCheckerTests {
    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "AppUpdateCheckerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func mockLookupResponse(version: String, releaseNotes: String? = nil, trackId: Int = 123456) -> Data {
        var result: [String: Any] = [
            "version": version,
            "trackViewUrl": "https://apps.apple.com/app/id\(trackId)",
            "trackId": trackId
        ]
        if let releaseNotes {
            result["releaseNotes"] = releaseNotes
        }
        let payload: [String: Any] = [
            "resultCount": 1,
            "results": [result]
        ]
        return try! JSONSerialization.data(withJSONObject: payload)
    }

    @Test func versionComparisonHandlesSemanticVersions() {
        #expect(AppUpdateChecker.isNewerVersion("1.0.1", than: "1.0"))
        #expect(AppUpdateChecker.isNewerVersion("1.10.0", than: "1.2.0"))
        #expect(AppUpdateChecker.isNewerVersion("2.0", than: "1.9.9"))
        #expect(!AppUpdateChecker.isNewerVersion("1.0.0", than: "1.0"))
        #expect(!AppUpdateChecker.isNewerVersion("1.0", than: "1.0.1"))
        #expect(!AppUpdateChecker.isNewerVersion("invalid", than: "1.0"))
    }

    @Test func automaticCheckPromptsAndRespectsSkipAndThrottle() async {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let data = mockLookupResponse(version: "1.2.0", releaseNotes: "  Cải thiện hiệu năng  ")
        let fetcher: AppUpdateChecker.DataFetcher = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let checker = AppUpdateChecker(
            userDefaults: defaults,
            bundleId: "vqhapp.terrariumidle-ios",
            currentVersion: "1.0.0",
            checkInterval: 3600,
            fetcher: fetcher
        )

        await checker.checkForUpdateIfNeeded()
        #expect(checker.isShowingUpdateAlert)
        #expect(checker.availableUpdate?.storeVersion == "1.2.0")
        #expect(checker.availableUpdate?.releaseNotes == "Cải thiện hiệu năng")

        checker.skipCurrentStoreVersion()
        #expect(!checker.isShowingUpdateAlert)

        // New instance with same UserDefaults should be throttled & skipped for automatic check
        let nextChecker = AppUpdateChecker(
            userDefaults: defaults,
            bundleId: "vqhapp.terrariumidle-ios",
            currentVersion: "1.0.0",
            checkInterval: 3600,
            fetcher: fetcher
        )
        await nextChecker.checkForUpdateIfNeeded()
        #expect(!nextChecker.isShowingUpdateAlert)

        // Manual check bypasses both throttle and skipped version
        await nextChecker.checkForUpdate(manual: true)
        #expect(nextChecker.isShowingUpdateAlert)
        #expect(nextChecker.availableUpdate?.storeVersion == "1.2.0")
    }

    @Test func manualCheckWhenUpToDateSetsStatus() async {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let data = mockLookupResponse(version: "1.0")
        let checker = AppUpdateChecker(
            userDefaults: defaults,
            bundleId: "vqhapp.terrariumidle-ios",
            currentVersion: "1.0.0",
            fetcher: { request in
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (data, response)
            }
        )

        await checker.checkForUpdate(manual: true)
        #expect(!checker.isShowingUpdateAlert)
        #expect(checker.manualStatus == .upToDate(version: "1.0.0"))
    }

    @Test func networkFailureIsSilentForAutoAndReportedForManual() async {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let checker = AppUpdateChecker(
            userDefaults: defaults,
            bundleId: "vqhapp.terrariumidle-ios",
            currentVersion: "1.0.0",
            fetcher: { _ in
                throw URLError(.notConnectedToInternet)
            }
        )

        await checker.checkForUpdateIfNeeded()
        #expect(!checker.isShowingUpdateAlert)
        #expect(checker.manualStatus == nil)

        await checker.checkForUpdate(manual: true)
        #expect(!checker.isShowingUpdateAlert)
        if case .failed = checker.manualStatus {
            #expect(true)
        } else {
            Issue.record("Expected failed manualStatus")
        }
    }
}

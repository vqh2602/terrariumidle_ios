//
//  AppUpdateChecker.swift
//  terrariumidle_ios
//

import Combine
import Foundation
import SwiftUI
import UIKit

/// Thông tin phiên bản mới trên App Store.
struct AppUpdateInfo: Equatable {
    let currentVersion: String
    let storeVersion: String
    let releaseNotes: String?
    let storeURL: URL
}

/// Kết quả kiểm tra thủ công khi không có bản cập nhật hoặc gặp lỗi.
enum AppUpdateManualStatus: Equatable, Identifiable {
    case upToDate(version: String)
    case failed(message: String)

    var id: String {
        switch self {
        case .upToDate(let version): return "upToDate-\(version)"
        case .failed(let message): return "failed-\(message)"
        }
    }
}

/// Kiểm tra phiên bản ứng dụng mới nhất trên App Store thông qua iTunes Lookup API.
@MainActor
final class AppUpdateChecker: ObservableObject {
    static let shared = AppUpdateChecker()

    @Published var availableUpdate: AppUpdateInfo?
    @Published var isShowingUpdateAlert = false
    @Published var isChecking = false
    @Published var manualStatus: AppUpdateManualStatus?

    typealias DataFetcher = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let userDefaults: UserDefaults
    private let bundleId: String
    private let currentVersion: String
    private let checkInterval: TimeInterval
    private let fetcher: DataFetcher
    private let now: () -> Date

    private var hasDismissedForSession = false

    private enum StorageKey {
        static let lastCheckTimestamp = "app_update_last_check_timestamp"
        static let skippedVersion = "app_update_skipped_version"
    }

    nonisolated static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    init(
        userDefaults: UserDefaults = .standard,
        bundleId: String = Bundle.main.bundleIdentifier ?? "vqhapp.terrariumidle-ios",
        currentVersion: String = AppUpdateChecker.currentAppVersion,
        checkInterval: TimeInterval = 6 * 60 * 60,
        fetcher: @escaping DataFetcher = { request in
            try await URLSession.shared.data(for: request)
        },
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.bundleId = bundleId
        self.currentVersion = currentVersion
        self.checkInterval = checkInterval
        self.fetcher = fetcher
        self.now = now
    }

    /// Tự động kiểm tra cập nhật khi mở app / quay lại foreground (có giới hạn tần suất).
    func checkForUpdateIfNeeded() async {
        guard !isChecking, !hasDismissedForSession else { return }

        let lastTimestamp = userDefaults.double(forKey: StorageKey.lastCheckTimestamp)
        if lastTimestamp > 0 {
            let elapsed = now().timeIntervalSince1970 - lastTimestamp
            if elapsed < checkInterval {
                return
            }
        }

        await checkForUpdate(manual: false)
    }

    /// Kiểm tra cập nhật từ App Store. Khi `manual = true` sẽ bỏ qua throttle và phiên bản đã bỏ qua.
    func checkForUpdate(manual: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        do {
            guard let storeResult = try await fetchStoreResult() else {
                if manual {
                    manualStatus = .upToDate(version: currentVersion)
                }
                return
            }

            userDefaults.set(now().timeIntervalSince1970, forKey: StorageKey.lastCheckTimestamp)

            guard Self.isNewerVersion(storeResult.version, than: currentVersion) else {
                availableUpdate = nil
                if manual {
                    manualStatus = .upToDate(version: currentVersion)
                }
                return
            }

            if !manual {
                let skipped = userDefaults.string(forKey: StorageKey.skippedVersion)
                if skipped == storeResult.version || hasDismissedForSession {
                    return
                }
            }

            guard let storeURL = Self.resolveStoreURL(from: storeResult) else {
                if manual {
                    manualStatus = .failed(message: "Không thể mở liên kết App Store.".tr)
                }
                return
            }

            let trimmedNotes = storeResult.releaseNotes?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            availableUpdate = AppUpdateInfo(
                currentVersion: currentVersion,
                storeVersion: storeResult.version,
                releaseNotes: (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil,
                storeURL: storeURL
            )
            isShowingUpdateAlert = true
        } catch {
            if manual {
                manualStatus = .failed(message: "Không thể kiểm tra cập nhật lúc này. Vui lòng thử lại sau.".tr)
            }
        }
    }

    /// Mở trang ứng dụng trên App Store.
    func openAppStore() {
        guard let url = availableUpdate?.storeURL else { return }
        isShowingUpdateAlert = false
        UIApplication.shared.open(url)
    }

    /// Tạm ẩn thông báo cập nhật trong phiên hiện tại.
    func remindLater() {
        hasDismissedForSession = true
        isShowingUpdateAlert = false
    }

    /// Bỏ qua phiên bản này cho các lần tự động kiểm tra tiếp theo.
    func skipCurrentStoreVersion() {
        if let version = availableUpdate?.storeVersion {
            userDefaults.set(version, forKey: StorageKey.skippedVersion)
        }
        hasDismissedForSession = true
        isShowingUpdateAlert = false
    }

    // MARK: - Version Comparison

    /// So sánh semantic version (`storeVersion > currentVersion`).
    nonisolated static func isNewerVersion(_ storeVersion: String, than currentVersion: String) -> Bool {
        let storeParts = numericComponents(from: storeVersion)
        let currentParts = numericComponents(from: currentVersion)
        guard !storeParts.isEmpty, !currentParts.isEmpty else { return false }

        let count = max(storeParts.count, currentParts.count)
        for index in 0..<count {
            let lhs = index < storeParts.count ? storeParts[index] : 0
            let rhs = index < currentParts.count ? currentParts[index] : 0
            if lhs != rhs {
                return lhs > rhs
            }
        }
        return false
    }

    nonisolated private static func numericComponents(from version: String) -> [Int] {
        version
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
            .compactMap { part in
                let digits = part.prefix(while: { $0.isNumber })
                return digits.isEmpty ? nil : Int(digits)
            }
    }

    // MARK: - iTunes Lookup

    private struct ITunesLookupResponse: Decodable {
        let resultCount: Int
        let results: [ITunesAppResult]
    }

    private struct ITunesAppResult: Decodable {
        let version: String
        let trackViewUrl: String?
        let releaseNotes: String?
        let trackId: Int?
    }

    private func fetchStoreResult() async throws -> ITunesAppResult? {
        let countryCode = Locale.current.region?.identifier
        if let countryCode, !countryCode.isEmpty,
           let localizedResult = try await requestLookup(country: countryCode) {
            return localizedResult
        }
        return try await requestLookup(country: nil)
    }

    private func requestLookup(country: String?) async throws -> ITunesAppResult? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId)
        ]
        if let country, !country.isEmpty {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "GET"

        let (data, response) = try await fetcher(request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)
        return decoded.results.first
    }

    private static func resolveStoreURL(from result: ITunesAppResult) -> URL? {
        if let trackViewUrl = result.trackViewUrl,
           let url = URL(string: trackViewUrl) {
            return url
        }
        if let trackId = result.trackId {
            return URL(string: "https://apps.apple.com/app/id\(trackId)")
        }
        return nil
    }
}

// MARK: - SwiftUI Alert Modifier

struct AppUpdateAlertModifier: ViewModifier {
    @ObservedObject var updateChecker: AppUpdateChecker

    func body(content: Content) -> some View {
        content
            .alert(
                "Có phiên bản mới".tr,
                isPresented: $updateChecker.isShowingUpdateAlert,
                presenting: updateChecker.availableUpdate
            ) { _ in
                Button("Cập nhật".tr) {
                    updateChecker.openAppStore()
                }
                Button("Để sau".tr, role: .cancel) {
                    updateChecker.remindLater()
                }
                Button("Bỏ qua phiên bản này".tr) {
                    updateChecker.skipCurrentStoreVersion()
                }
            } message: { info in
                Text(alertMessage(for: info))
            }
            .alert(item: $updateChecker.manualStatus) { status in
                switch status {
                case .upToDate(let version):
                    Alert(
                        title: Text("Bạn đang ở phiên bản mới nhất".tr),
                        message: Text("Phiên bản hiện tại: v%@".tr(version)),
                        dismissButton: .default(Text("Đóng".tr))
                    )
                case .failed(let message):
                    Alert(
                        title: Text("Kiểm tra cập nhật".tr),
                        message: Text(message),
                        dismissButton: .default(Text("Đóng".tr))
                    )
                }
            }
    }

    private func alertMessage(for info: AppUpdateInfo) -> String {
        let base = "Phiên bản %@ đã có trên App Store (bạn đang dùng %@).".tr(info.storeVersion, info.currentVersion)
        if let notes = info.releaseNotes, !notes.isEmpty {
            return "\(base)\n\n\(notes)"
        }
        return base
    }
}

extension View {
    /// Gắn thông báo cập nhật ứng dụng tự động từ App Store.
    func appUpdateAlert(_ updateChecker: AppUpdateChecker = .shared) -> some View {
        modifier(AppUpdateAlertModifier(updateChecker: updateChecker))
    }
}

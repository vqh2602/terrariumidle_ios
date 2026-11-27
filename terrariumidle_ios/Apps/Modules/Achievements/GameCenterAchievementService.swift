import Combine
import FirebaseAuth
import FirebaseFirestore
import GameKit
import UIKit

/// Game Center owns Apple's achievements; Firebase owns the garden and cumulative counters.
/// A garden is linked to one Game Center player before any progress is reported.
@MainActor
final class GameCenterAchievementService: ObservableObject {
    static let shared = GameCenterAchievementService()

    struct Presentation: Identifiable {
        let id = UUID()
        let controller: UIViewController
        let isAuthentication: Bool
    }

    @Published var presentation: Presentation?
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var isReporting = false
    @Published private(set) var playerName = ""
    @Published private(set) var message: String?
    @Published private(set) var configuredCount = 0

    private var sessionUID: String?
    private var linkedPlayerID: String?
    private var generation = UUID()
    private var configuredIDs = Set<String>()
    private var reported: [String: Double] = [:]
    private var reportTask: Task<Void, Never>?
    private var needsReport = false

    private init() {}
    private func enabledKey(_ uid: String) -> String { "terrarium.gamecenter.enabled.\(uid)" }

    func displayPercent(for item: GardenAchievement, progress: AchievementProgress) -> Double {
        max(item.percent(for: progress), isConnected ? (reported[item.id] ?? 0) : 0)
    }

    func resumeIfEnabled(userID: String) {
        guard sessionUID != userID, UserDefaults.standard.bool(forKey: enabledKey(userID)) else { return }
        connect()
    }

    func connect() {
        guard !isConnecting, let uid = AchievementStore.shared.userID,
              uid == Auth.auth().currentUser?.uid else { return }
        resetGardenSession()
        sessionUID = uid
        UserDefaults.standard.set(true, forKey: enabledKey(uid))
        isConnecting = true
        message = nil
        let token = generation
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor in
                guard let self, token == self.generation,
                      uid == Auth.auth().currentUser?.uid else { return }
                if let controller {
                    self.presentation = Presentation(controller: controller, isAuthentication: true)
                    return
                }
                if self.presentation?.isAuthentication == true { self.presentation = nil }
                guard error == nil, GKLocalPlayer.local.isAuthenticated else {
                    self.isConnecting = false
                    self.isConnected = false
                    self.message = "Chưa kết nối Game Center. Bạn vẫn có thể tiếp tục chăm vườn.".tr
                    return
                }
                // The authenticate handler may run again after a Game Center account change.
                let playerID = GKLocalPlayer.local.gamePlayerID
                if self.isConnected, self.linkedPlayerID == playerID { return }
                self.reportTask?.cancel()
                self.reportTask = nil
                self.isReporting = false
                self.reported = [:]
                self.configuredIDs = []
                self.configuredCount = 0
                self.isConnected = false
                self.linkedPlayerID = nil
                self.isConnecting = true
                await self.finishConnection(uid: uid, playerID: playerID, token: token)
            }
        }
    }

    private func finishConnection(uid: String, playerID: String, token: UUID) async {
        do {
            let reference = Firestore.firestore().collection("users").document(uid)
            // Atomic binding also protects against two devices connecting different Apple players.
            _ = try await Firestore.firestore().runTransaction { transaction, errorPointer -> Any? in
                do {
                    let document = try transaction.getDocument(reference)
                    guard document.exists else { throw NSError(domain: "GameCenter", code: 1) }
                    if let previous = document.data()?["achievementGameCenterPlayerID"] as? String,
                       !previous.isEmpty, previous != playerID {
                        throw NSError(domain: "GameCenter", code: 2,
                                      userInfo: [NSLocalizedDescriptionKey: "Khu vườn này đã liên kết với tài khoản Game Center khác.".tr])
                    }
                    transaction.updateData(["achievementGameCenterPlayerID": playerID], forDocument: reference)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            let descriptions = try await GKAchievementDescription.loadAchievementDescriptions()
            let achievements = try await GKAchievement.loadAchievements()
            guard isCurrent(uid: uid, playerID: playerID, token: token) else { return }
            configuredIDs = Set(descriptions.map(\.identifier)).intersection(AchievementCatalog.all.map(\.id))
            configuredCount = configuredIDs.count
            reported = Dictionary(achievements.map { ($0.identifier, $0.percentComplete) }, uniquingKeysWith: max)
            linkedPlayerID = playerID
            playerName = GKLocalPlayer.local.displayName
            isConnected = true
            isConnecting = false
            if configuredCount < AchievementCatalog.all.count {
                message = "Một số thành tích chưa được cấu hình trên Game Center.".tr
            }
            reportNow()
        } catch {
            guard isCurrent(uid: uid, playerID: playerID, token: token) else { return }
            isConnecting = false
            isConnected = false
            message = (error as NSError).domain == "GameCenter" && (error as NSError).code == 2
                ? error.localizedDescription : "Chưa tải được thành tích Game Center. Hãy kiểm tra kết nối và thử lại.".tr
        }
    }

    private func isCurrent(uid: String, playerID: String, token: UUID) -> Bool {
        token == generation && sessionUID == uid && AchievementStore.shared.userID == uid
            && Auth.auth().currentUser?.uid == uid && GKLocalPlayer.local.isAuthenticated
            && GKLocalPlayer.local.gamePlayerID == playerID
    }

    func resetGardenSession() {
        generation = UUID()
        reportTask?.cancel()
        reportTask = nil
        needsReport = false
        sessionUID = nil
        linkedPlayerID = nil
        isConnected = false
        isConnecting = false
        isReporting = false
        playerName = ""
        configuredCount = 0
        configuredIDs = []
        reported = [:]
        presentation = nil
        message = nil
        GKLocalPlayer.local.authenticateHandler = nil
    }

    func disconnect() {
        if let sessionUID { UserDefaults.standard.set(false, forKey: enabledKey(sessionUID)) }
        resetGardenSession()
    }

    func showDashboard() {
        guard isConnected, GKLocalPlayer.local.isAuthenticated,
              GKLocalPlayer.local.gamePlayerID == linkedPlayerID else { connect(); return }
        presentation = Presentation(controller: GKGameCenterViewController(state: .achievements), isAuthentication: false)
    }

    func scheduleReport() {
        needsReport = true
        guard isConnected, reportTask == nil, !isReporting else { return }
        let token = generation
        reportTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            guard let self, token == self.generation else { return }
            self.reportTask = nil
            await self.report(token: token)
        }
    }

    func reportNow() {
        needsReport = true
        guard isConnected, !isReporting else { return }
        reportTask?.cancel()
        reportTask = nil
        let token = generation
        Task { await report(token: token) }
    }

    private func report(token: UUID) async {
        guard !isReporting, let uid = sessionUID, let playerID = linkedPlayerID,
              isCurrent(uid: uid, playerID: playerID, token: token) else { return }
        let progress = AchievementStore.shared.progress
        let updates = AchievementReportPlan.updates(progress: progress, configured: configuredIDs, reported: reported)
        let pending: [GKAchievement] = updates.sorted { $0.key < $1.key }.map { id, percent in
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = percent
            achievement.showsCompletionBanner = percent >= 100
            return achievement
        }
        needsReport = false
        guard !pending.isEmpty else { return }
        isReporting = true
        do {
            try await GKAchievement.report(pending)
            guard isCurrent(uid: uid, playerID: playerID, token: token) else { return }
            for achievement in pending { reported[achievement.identifier] = achievement.percentComplete }
            message = configuredCount < AchievementCatalog.all.count
                ? "Một số thành tích chưa được cấu hình trên Game Center.".tr : nil
        } catch {
            guard isCurrent(uid: uid, playerID: playerID, token: token) else { return }
            message = "Tiến độ đã lưu. Chưa gửi được lên Game Center, app sẽ thử lại khi bạn tiếp tục chơi.".tr
        }
        guard token == generation else { return }
        isReporting = false
        if needsReport { scheduleReport() }
    }
}

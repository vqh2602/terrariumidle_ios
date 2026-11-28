import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import UserNotifications

struct HealthRewardBanner: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
}

@MainActor
final class HealthRewardStatusStore: ObservableObject {
    static let shared = HealthRewardStatusStore()

    @Published private(set) var sleepGrants: [SleepRewardGrant] = []
    @Published private(set) var stepsGrants: [StepsRewardGrant] = []
    @Published var activeBanner: HealthRewardBanner?
    @Published var shouldOpenHealthHub = false

    private var loadedUserID: String?
    private var isLoadingReceipts = false
    private var sleepClaimed: Set<String> = []
    private var sleepWeeklyDays: Set<String> = []
    private var stepsClaimed: Set<String> = []
    private var stepsWeeklyDays: Set<String> = []
    private var lastBannerSignature: String?

    var sleepUnclaimedCount: Int { sleepGrants.count }
    var stepsUnclaimedCount: Int { stepsGrants.count }
    var totalUnclaimedCount: Int { sleepGrants.count + stepsGrants.count }
    var hasUnclaimedRewards: Bool { totalUnclaimedCount > 0 }

    private init() {}

    func resetSession() {
        loadedUserID = nil
        isLoadingReceipts = false
        sleepClaimed = []
        sleepWeeklyDays = []
        stepsClaimed = []
        stepsWeeklyDays = []
        sleepGrants = []
        stepsGrants = []
        activeBanner = nil
        lastBannerSignature = nil
    }

    func dismissBanner() {
        activeBanner = nil
    }

    func loadReceiptsIfNeeded(userID: String?, force: Bool = false) async {
        guard let userID, !userID.isEmpty, Auth.auth().currentUser?.uid == userID else {
            resetSession()
            return
        }
        guard force || loadedUserID != userID else {
            recalculate(notifyIfNeeded: true)
            return
        }
        guard !isLoadingReceipts else { return }
        isLoadingReceipts = true
        defer { isLoadingReceipts = false }

        do {
            let data = try await Firestore.firestore().collection("users").document(userID).getDocument().data()
            guard Auth.auth().currentUser?.uid == userID else { return }
            sleepClaimed = Set((data?["sleepRewardDays"] as? [String: Any] ?? [:]).keys)
                .union((data?["sleepRewardMilestones"] as? [String: Any] ?? [:]).keys)
            sleepWeeklyDays = Set((data?["sleepRewardWeekDays"] as? [String: Any] ?? [:]).keys)
            stepsClaimed = Set((data?["stepsRewardDays"] as? [String: Any] ?? [:]).keys)
                .union((data?["stepsRewardMilestones"] as? [String: Any] ?? [:]).keys)
            stepsWeeklyDays = Set((data?["stepsRewardWeekDays"] as? [String: Any] ?? [:]).keys)
            loadedUserID = userID
            recalculate(notifyIfNeeded: true)
        } catch {
            // Keep prior receipts if reload failed; avoid emitting false notifications.
        }
    }

    func updateSleepReceipts(claimed: Set<String>, weeklyDays: Set<String>, userID: String?) {
        guard let userID, !userID.isEmpty, Auth.auth().currentUser?.uid == userID else { return }
        sleepClaimed = claimed
        sleepWeeklyDays = weeklyDays
        loadedUserID = userID
        recalculate(notifyIfNeeded: false)
    }

    func updateStepsReceipts(claimed: Set<String>, weeklyDays: Set<String>, userID: String?) {
        guard let userID, !userID.isEmpty, Auth.auth().currentUser?.uid == userID else { return }
        stepsClaimed = claimed
        stepsWeeklyDays = weeklyDays
        loadedUserID = userID
        recalculate(notifyIfNeeded: false)
    }

    func syncAndRefresh(userID: String? = FireStoreService.shared.gradenModel?.user.userID) async {
        async let sleepTask: Void = SleepHealthStore.shared.sync()
        async let stepsTask: Void = StepsHealthStore.shared.sync()
        async let receiptsTask: Void = loadReceiptsIfNeeded(userID: userID)
        _ = await (sleepTask, stepsTask, receiptsTask)
        recalculate(notifyIfNeeded: true)
    }

    func recalculate(notifyIfNeeded: Bool = false) {
        guard let uid = Auth.auth().currentUser?.uid, loadedUserID == uid else {
            sleepGrants = []
            stepsGrants = []
            activeBanner = nil
            return
        }
        let defaults = UserDefaults.standard
        let sleepGoal = defaults.object(forKey: "sleep.goalHours") as? Double ?? 8.0
        let rawStepsGoal = defaults.object(forKey: StepsSummary.goalStorageKey) as? Int ?? StepsSummary.defaultGoal
        let stepsGoal = StepsSummary.clampedGoal(rawStepsGoal)

        sleepGrants = SleepRewardRules.available(
            days: SleepHealthStore.shared.days,
            goal: sleepGoal,
            claimed: sleepClaimed,
            weeklyDays: sleepWeeklyDays
        )
        stepsGrants = StepsRewardRules.available(
            days: StepsHealthStore.shared.days,
            goal: stepsGoal,
            claimed: stepsClaimed,
            weeklyDays: stepsWeeklyDays
        )

        if sleepGrants.isEmpty && stepsGrants.isEmpty {
            activeBanner = nil
            lastBannerSignature = nil
            return
        }

        if notifyIfNeeded {
            notifyUnclaimedIfNeeded(userID: uid)
        }
    }

    private func notifyUnclaimedIfNeeded(userID: String) {
        let sleepIds = sleepGrants.map(\.id).sorted()
        let stepsIds = stepsGrants.map(\.id).sorted()
        let signature = "sleep:\(sleepIds.joined(separator: ","))|steps:\(stepsIds.joined(separator: ","))"
        let bannerContent = makeBannerContent(sleepCount: sleepIds.count, stepsCount: stepsIds.count)

        if lastBannerSignature != signature {
            lastBannerSignature = signature
            activeBanner = HealthRewardBanner(
                id: signature,
                title: bannerContent.title,
                message: bannerContent.message
            )
        }

        let storageKey = "health.notifiedRewards.\(userID)"
        let defaults = UserDefaults.standard
        var notified = Set(defaults.stringArray(forKey: storageKey) ?? [])
        let currentKeys = sleepIds.map { "sleep:\($0)" } + stepsIds.map { "steps:\($0)" }
        let newlyAchieved = currentKeys.filter { !notified.contains($0) }
        guard !newlyAchieved.isEmpty else { return }

        notified.formUnion(newlyAchieved)
        defaults.set(Array(notified.sorted().suffix(60)), forKey: storageKey)

        let title = bannerContent.title
        let body = bannerContent.message
        Task {
            await scheduleLocalNotificationIfAuthorized(title: title, body: body)
        }
    }

    private func makeBannerContent(sleepCount: Int, stepsCount: Int) -> (title: String, message: String) {
        if sleepCount > 0 && stepsCount > 0 {
            return (
                "Quà Sức khỏe đang chờ!".tr,
                "Giấc ngủ và Bước chân đều đã đạt mục tiêu. Bấm để nhận quà cho khu vườn.".tr
            )
        } else if sleepCount > 0 {
            return (
                "Giấc ngủ đã đạt mục tiêu!".tr,
                "Bạn có %d phần thưởng Giấc ngủ chưa nhận. Bấm để mở Sức khỏe.".tr(sleepCount)
            )
        } else {
            return (
                "Bước chân đã đạt mục tiêu!".tr,
                "Bạn có %d phần thưởng Bước chân chưa nhận. Bấm để mở Sức khỏe.".tr(stepsCount)
            )
        }
    }

    private func scheduleLocalNotificationIfAuthorized(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["destination": "healthHub"]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "terrarium.health.unclaimed",
                content: content,
                trigger: trigger
            )
            center.removePendingNotificationRequests(withIdentifiers: ["terrarium.health.unclaimed"])
            try? await center.add(request)
        default:
            break
        }
    }
}

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class StepsRewards: ObservableObject {
    @Published private(set) var claimed: Set<String> = []
    @Published private(set) var weeklyDays: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isClaiming = false
    @Published var message: String?
    private var userID: String?

    func load(userID: String?) async {
        self.userID = userID
        claimed = []
        weeklyDays = []
        guard let userID, !userID.isEmpty else {
            HealthRewardStatusStore.shared.updateStepsReceipts(claimed: [], weeklyDays: [], userID: nil)
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await Firestore.firestore().collection("users").document(userID).getDocument().data()
            guard self.userID == userID else { return }
            claimed = Set((data?["stepsRewardDays"] as? [String: Any] ?? [:]).keys)
                .union((data?["stepsRewardMilestones"] as? [String: Any] ?? [:]).keys)
            weeklyDays = Set((data?["stepsRewardWeekDays"] as? [String: Any] ?? [:]).keys)
            HealthRewardStatusStore.shared.updateStepsReceipts(claimed: claimed, weeklyDays: weeklyDays, userID: userID)
        } catch {
            message = "Chưa tải được lịch sử nhận thưởng. Khi nhận, app sẽ kiểm tra lại để tránh trùng.".tr
        }
    }

    func claim(_ grant: StepsRewardGrant, goal: Int) async {
        guard !isClaiming, !claimed.contains(grant.id), let uid = userID,
              uid == Auth.auth().currentUser?.uid else { return }
        isClaiming = true
        defer { isClaiming = false }
        do {
            let credited = try await FireStoreService.shared.claimStepsReward(grant: grant, goal: goal)
            guard userID == uid else { return }
            if !credited {
                await load(userID: uid)
                message = "Mốc này đã được nhận thưởng rồi.".tr
                return
            }
            claimed.insert(grant.id)
            if grant.kind == .weekly {
                weeklyDays.formUnion(grant.days.map(\.id))
            }
            HealthRewardStatusStore.shared.updateStepsReceipts(claimed: claimed, weeklyDays: weeklyDays, userID: uid)
            message = "Khu vườn đã nhận %@ từ bước chân của bạn!".tr(grant.prize)
        } catch {
            message = error.localizedDescription
        }
    }
}

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class SleepRewards: ObservableObject {
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
        guard let userID, !userID.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await Firestore.firestore().collection("users").document(userID).getDocument().data()
            guard self.userID == userID else { return }
            claimed = Set((data?["sleepRewardDays"] as? [String: Any] ?? [:]).keys)
                .union((data?["sleepRewardMilestones"] as? [String: Any] ?? [:]).keys)
            weeklyDays = Set((data?["sleepRewardWeekDays"] as? [String: Any] ?? [:]).keys)
        } catch {
            message = "Chưa tải được lịch sử nhận thưởng. Khi nhận, app sẽ kiểm tra lại để tránh trùng.".tr
        }
    }

    func claim(_ grant: SleepRewardGrant, goal: Double) async {
        guard !isClaiming, !claimed.contains(grant.id), let uid = userID,
              uid == Auth.auth().currentUser?.uid else { return }
        isClaiming = true
        defer { isClaiming = false }
        do {
            let credited = try await FireStoreService.shared.claimSleepReward(grant: grant, goal: goal)
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
            message = "Khu vườn đã nhận %@ từ giấc ngủ của bạn!".tr(grant.prize)
        } catch { message = error.localizedDescription }
    }
}

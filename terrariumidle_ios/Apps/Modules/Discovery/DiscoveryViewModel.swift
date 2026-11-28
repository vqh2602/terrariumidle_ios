import Combine
import FirebaseAuth
import Foundation

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published private(set) var profiles: [DiscoveredProfile] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var nextCursor: String?
    @Published var category: DiscoveryCategory = .world
    @Published var searchID = ""
    @Published private(set) var submittedID = ""
    @Published private(set) var refreshID = 0
    private let repository: any DiscoveryReading
    private let ownID: String?
    private var generation = UUID()
    private var loadedRequestKey: String?

    init(repository: any DiscoveryReading, ownID: String?) {
        self.repository = repository
        self.ownID = ownID
    }

    var requestKey: String { "\(category.rawValue)|\(submittedID)|\(refreshID)" }
    func search() {
        submittedID = searchID.trimmingCharacters(in: .whitespacesAndNewlines)
        refreshID += 1
    }
    func resetSearch() { searchID = ""; submittedID = ""; refreshID += 1 }
    func refresh() { refreshID += 1 }

    func loadIfNeeded() async {
        guard loadedRequestKey != requestKey else { return }
        await load()
    }

    func isOwn(_ profile: DiscoveredProfile) -> Bool {
        profile.id == ownID
    }

    func updateLikes(gardenID: String, total: Int) {
        guard let index = profiles.firstIndex(where: { $0.id == gardenID }) else { return }
        profiles[index] = profiles[index].updatingLikes(total)
    }

    func load(more: Bool = false) async {
        if more && (isLoading || nextCursor == nil) { return }
        let token = UUID()
        generation = token
        let loadingKey = requestKey
        let category = self.category
        let search = category == .world ? submittedID : ""
        let cursor = more ? nextCursor : nil
        if !more { profiles = []; nextCursor = nil }
        isLoading = true
        error = nil
        defer { if generation == token { isLoading = false } }
        do {
            let page: DiscoveryPage
            if !search.isEmpty {
                let garden = try await repository.garden(id: search)
                page = DiscoveryPage(profiles: [garden.profile], nextCursor: nil)
            } else {
                page = try await repository.profiles(category: category, after: cursor)
            }
            try Task.checkCancellation()
            guard generation == token else { return }
            var ids = Set(profiles.map(\.id))
            let excludeOwn = category == .world
            profiles += page.profiles.filter { (!excludeOwn || $0.id != ownID) && ids.insert($0.id).inserted }
            nextCursor = page.nextCursor
            loadedRequestKey = loadingKey
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            print("❌ Discovery load failed (\(category.rawValue)):", error)
            self.error = (error as? DiscoveryError)?.localizedDescription ?? "Không tải được danh sách khu vườn. Vui lòng kiểm tra kết nối và thử lại.".tr
        }
    }
}

@MainActor
final class VisitorGardenViewModel: ObservableObject {
    @Published private(set) var garden: VisitorGarden?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var likeCount = 0
    @Published private(set) var isLiking = false
    @Published private(set) var hasLiked = false
    @Published private(set) var likeMessage: String?
    @Published private(set) var isDroppingPest = false
    @Published var pestDropMessage: String?
    private let liking: (any GardenLiking)?
    private let onLike: ((String, Int) -> Void)?
    private let repository: any DiscoveryReading
    private var generation = UUID()

    init(repository: any DiscoveryReading, liking: (any GardenLiking)? = nil,
         onLike: ((String, Int) -> Void)? = nil) {
        self.repository = repository
        self.liking = liking
        self.onLike = onLike
    }

    var canLike: Bool {
        guard let garden, let viewerID = liking?.viewerID else { return false }
        return viewerID != garden.profile.id && !hasLiked && !isLiking
    }

    var isOwnGarden: Bool {
        guard let garden, let viewerID = Auth.auth().currentUser?.uid else { return false }
        return viewerID == garden.profile.id
    }

    var dailyDropLimit: Int {
        GardenModel.visitorPestDropLimit(isVIP: SubscriptionManager.isVIP(gardenModel: FireStoreService.shared.gradenModel))
    }

    var remainingDailyDrops: Int {
        let garden = FireStoreService.shared.gradenModel
        return garden?.remainingVisitorPestDrops(isVIP: SubscriptionManager.isVIP(gardenModel: garden)) ?? 0
    }

    var capturedPestCount: Int {
        FireStoreService.shared.gradenModel?.capturedPests.count ?? 0
    }

    var hasPlantTargets: Bool {
        guard let garden else { return false }
        return garden.slots.values.contains { !$0.isSticker && !$0.isAnimal && !$0.plantID.isEmpty && !$0.potID.isEmpty }
    }

    func dropPest() async {
        guard let garden, !isDroppingPest else { return }
        guard remainingDailyDrops > 0 else {
            pestDropMessage = FireStoreService.VisitorPestDropError.dailyLimitReached(limit: dailyDropLimit).errorDescription
            return
        }
        guard capturedPestCount > 0 else {
            pestDropMessage = FireStoreService.VisitorPestDropError.emptyBag.errorDescription
            return
        }
        let token = generation
        isDroppingPest = true
        pestDropMessage = nil
        defer { isDroppingPest = false }
        do {
            let result = try await FireStoreService.shared.dropPestInVisitorGarden(
                targetGardenId: garden.profile.id,
                targetSlots: Array(garden.slots.values),
                existingTargetPests: garden.pests
            )
            guard token == generation else { return }
            self.garden?.pests.append(result.pest)
            AudioPlayer.shared.playClickSound(named: "virtual_vibes-pop-tap-click-fx-383733")
            let remainingInBag = FireStoreService.shared.gradenModel?.capturedPests.count ?? 0
            if remainingInBag == 0 {
                pestDropMessage = "Đã thả %@ lên cây · +%d 💨! Túi đã hết sâu, hãy về vườn bắt thêm nhé.".tr(
                    result.pest.kind.displayName, result.oxygenReward
                )
            } else {
                pestDropMessage = "Đã thả %@ lên cây · +%d 💨! (Túi còn %d/%d)".tr(
                    result.pest.kind.displayName, result.oxygenReward, remainingInBag, GardenModel.maxBagCapacity
                )
            }
        } catch {
            guard token == generation else { return }
            pestDropMessage = (error as? LocalizedError)?.errorDescription ?? "Chưa thể thả sâu lúc này.".tr
        }
    }

    func like() async {
        guard let garden, let liking, canLike else { return }
        let token = generation
        let viewerID = Auth.auth().currentUser?.uid
        isLiking = true
        likeMessage = nil
        defer { isLiking = false }
        do {
            let total = try await liking.like(gardenID: garden.profile.id)
            onLike?(garden.profile.id, total)
            guard token == generation else { return }
            likeCount = total
            hasLiked = true
            if let viewerID, viewerID == Auth.auth().currentUser?.uid {
                AchievementStore.shared.recordGarden(garden.profile.id, liked: true)
            }
            likeMessage = "Đã gửi một trái tim cho khu vườn này!".tr
        } catch {
            guard token == generation else { return }
            likeMessage = (error as? GardenLikeError)?.localizedDescription ?? "Chưa gửi được lượt thích. Vui lòng thử lại.".tr
        }
    }

    func load(id: String) async {
        guard !isLiking else { return }
        let token = UUID()
        let viewerID = Auth.auth().currentUser?.uid
        generation = token
        garden = nil
        error = nil
        likeMessage = nil
        pestDropMessage = nil
        hasLiked = false
        likeCount = 0
        isLoading = true
        defer { if generation == token { isLoading = false } }
        do {
            let snapshot = try await repository.garden(id: id)
            try Task.checkCancellation()
            guard generation == token else { return }
            garden = snapshot
            if let viewerID, viewerID == Auth.auth().currentUser?.uid {
                AchievementStore.shared.recordGarden(snapshot.profile.id)
            }
            likeCount = snapshot.profile.likes
            hasLiked = liking?.hasLiked(gardenID: snapshot.profile.id) ?? false
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            self.error = (error as? DiscoveryError)?.localizedDescription ?? "Không tải được khu vườn. Vui lòng thử lại.".tr
        }
    }
}

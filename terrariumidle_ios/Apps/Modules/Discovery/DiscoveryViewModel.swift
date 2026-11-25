import Combine
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
            profiles += page.profiles.filter { $0.id != ownID && ids.insert($0.id).inserted }
            nextCursor = page.nextCursor
            loadedRequestKey = loadingKey
        } catch {
            guard generation == token, !Task.isCancelled else { return }
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

    func like() async {
        guard let garden, let liking, canLike else { return }
        let token = generation
        isLiking = true
        likeMessage = nil
        defer { isLiking = false }
        do {
            let total = try await liking.like(gardenID: garden.profile.id)
            onLike?(garden.profile.id, total)
            guard token == generation else { return }
            likeCount = total
            hasLiked = true
            likeMessage = "Đã gửi một trái tim cho khu vườn này!".tr
        } catch {
            guard token == generation else { return }
            likeMessage = (error as? GardenLikeError)?.localizedDescription ?? "Chưa gửi được lượt thích. Vui lòng thử lại.".tr
        }
    }

    func load(id: String) async {
        guard !isLiking else { return }
        let token = UUID()
        generation = token
        garden = nil
        error = nil
        likeMessage = nil
        hasLiked = false
        likeCount = 0
        isLoading = true
        defer { if generation == token { isLoading = false } }
        do {
            let snapshot = try await repository.garden(id: id)
            try Task.checkCancellation()
            guard generation == token else { return }
            garden = snapshot
            likeCount = snapshot.profile.likes
            hasLiked = liking?.hasLiked(gardenID: snapshot.profile.id) ?? false
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            self.error = (error as? DiscoveryError)?.localizedDescription ?? "Không tải được khu vườn. Vui lòng thử lại.".tr
        }
    }
}

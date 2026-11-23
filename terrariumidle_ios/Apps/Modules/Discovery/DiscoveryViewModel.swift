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

    func load(more: Bool = false) async {
        if more && (isLoading || nextCursor == nil) { return }
        let token = UUID()
        generation = token
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
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            self.error = (error as? DiscoveryError)?.localizedDescription ?? "Không tải được danh sách khu vườn. Vui lòng kiểm tra kết nối và thử lại."
        }
    }
}

@MainActor
final class VisitorGardenViewModel: ObservableObject {
    @Published private(set) var garden: VisitorGarden?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    private let repository: any DiscoveryReading
    private var generation = UUID()

    init(repository: any DiscoveryReading) { self.repository = repository }

    func load(id: String) async {
        let token = UUID()
        generation = token
        garden = nil
        error = nil
        isLoading = true
        defer { if generation == token { isLoading = false } }
        do {
            let snapshot = try await repository.garden(id: id)
            try Task.checkCancellation()
            guard generation == token else { return }
            garden = snapshot
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            self.error = (error as? DiscoveryError)?.localizedDescription ?? "Không tải được khu vườn. Vui lòng thử lại."
        }
    }
}

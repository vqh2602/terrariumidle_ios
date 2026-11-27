import Combine
import Foundation

@MainActor
final class MailboxStore: ObservableObject {
    static let shared = MailboxStore()

    @Published private(set) var items: [MailboxItem] = []
    @Published private(set) var readIds: Set<String>
    @Published private(set) var isLoading = false
    @Published var error: String?

    private let readStorageKey = "terrarium.mailbox.readIds"
    private var hasLoadedOnce = false

    private init() {
        let saved = UserDefaults.standard.stringArray(forKey: readStorageKey) ?? []
        self.readIds = Set(saved)
    }

    var unreadCount: Int {
        items.reduce(0) { count, item in
            count + (readIds.contains(item.id) ? 0 : 1)
        }
    }

    func isRead(_ item: MailboxItem) -> Bool {
        readIds.contains(item.id)
    }

    func markAsRead(_ item: MailboxItem) {
        guard readIds.insert(item.id).inserted else { return }
        UserDefaults.standard.set(Array(readIds), forKey: readStorageKey)
    }

    func markAllAsRead() {
        let allIds = items.map(\.id)
        guard !allIds.isEmpty else { return }
        readIds.formUnion(allIds)
        UserDefaults.standard.set(Array(readIds), forKey: readStorageKey)
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce, !isLoading else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: MailboxItem.feedURL)
            request.timeoutInterval = 25
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let decoded = try JSONDecoder().decode(MailboxItem.Feed.self, from: data)
            items = decoded.data
                .filter(\.isSupportedByCurrentVersion)
                .sorted { lhs, rhs in
                    let leftPinned = lhs.pinned ?? false
                    let rightPinned = rhs.pinned ?? false
                    if leftPinned != rightPinned { return leftPinned && !rightPinned }
                    return lhs.date > rhs.date
                }
            hasLoadedOnce = true
        } catch is CancellationError {
        } catch {
            self.error = "Không tải được hòm thư. Vui lòng thử lại.".tr
        }
    }
}

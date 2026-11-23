import FirebaseFirestore
import Foundation

@MainActor
protocol DiscoveryReading {
    func profiles(category: DiscoveryCategory, after cursor: String?) async throws -> DiscoveryPage
    func garden(id: String) async throws -> VisitorGarden
}

/// Thiết kế chỉ đọc (read-only); không dùng store của chủ vườn, không lắng nghe sự kiện, không thay đổi auth và không có API ghi.
@MainActor
final class DiscoveryRepository: DiscoveryReading {
    private let db: Firestore
    init(db: Firestore = Firestore.firestore()) { self.db = db }

    func profiles(category: DiscoveryCategory, after cursor: String?) async throws -> DiscoveryPage {
        let limit = category == .world ? 30 : 10
        let collection = category == .oxygen ? "rankings" : "users"
        var query: Query = db.collection(collection)
        switch category {
        case .world:
            query = query.order(by: FieldPath.documentID())
            if let cursor { query = query.start(after: [cursor]) }
        case .likes: query = query.order(by: "user.userTotalLike", descending: true)
        case .level: query = query.order(by: "user.userLevel", descending: true)
        case .oxygen: query = query.order(by: "oxygenCollect", descending: true)
        }
        let snapshot = try await query.limit(to: limit).getDocuments()
        try Task.checkCancellation()
        let profiles = snapshot.documents.compactMap { document -> DiscoveredProfile? in
            let data = document.data()
            if category == .world && (data["plants"] as? [Any] ?? []).isEmpty { return nil }
            return DiscoveredProfile(documentID: document.documentID, data: data,
                                     oxygenCollected: category == .oxygen ? DiscoveryValue.int(data["oxygenCollect"]) : nil)
        }
        let next = category == .world && snapshot.documents.count == limit ? snapshot.documents.last?.documentID : nil
        return DiscoveryPage(profiles: profiles, nextCursor: next)
    }

    func garden(id: String) async throws -> VisitorGarden {
        let cleanID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanID.isEmpty, !cleanID.contains("/"), cleanID != ".", cleanID != "..", cleanID.utf8.count <= 1500 else {
            throw DiscoveryError.invalidID
        }
        let snapshot = try await db.collection("users").document(cleanID).getDocument()
        try Task.checkCancellation()
        guard let data = snapshot.data() else { throw DiscoveryError.unavailable }
        return try VisitorGarden(documentID: snapshot.documentID, data: data)
    }
}

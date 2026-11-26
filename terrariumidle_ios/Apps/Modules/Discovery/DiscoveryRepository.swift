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
        if category == .world { return try await randomWorldPage(after: cursor) }
        if category == .oxygen { return try await oxygenRankingPage(limit: 10) }
        let limit = 10
        var query: Query = db.collection("users")
        switch category {
        case .world, .oxygen: break
        case .likes: query = query.order(by: "user.userTotalLike", descending: true)
        case .level: query = query.order(by: "user.userLevel", descending: true)
        }
        let snapshot = try await query.limit(to: limit).getDocuments()
        try Task.checkCancellation()
        let profiles = snapshot.documents.compactMap { document -> DiscoveredProfile? in
            DiscoveredProfile(documentID: document.documentID, data: document.data())
        }
        return DiscoveryPage(profiles: profiles, nextCursor: nil)
    }

    private func oxygenRankingPage(limit: Int) async throws -> DiscoveryPage {
        do {
            let snapshot = try await db.collection("user-event")
                .order(by: "oxygenCollected", descending: true)
                .limit(to: limit)
                .getDocuments()
            try Task.checkCancellation()

            let entries: [(uid: String, oxygen: Int)] = snapshot.documents.compactMap { doc in
                let data = doc.data()
                let rawUID = (data["userId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let uid = (rawUID?.isEmpty == false ? rawUID! : doc.documentID)
                guard !uid.isEmpty, !uid.contains("/") else { return nil }
                return (uid, max(0, DiscoveryValue.int(data["oxygenCollected"])))
            }

            let firestore = db
            let userDocs = await withTaskGroup(of: (String, [String: Any]?).self) { group in
                for entry in entries {
                    group.addTask {
                        let doc = try? await firestore.collection("users").document(entry.uid).getDocument()
                        return (entry.uid, doc?.data())
                    }
                }
                var map: [String: [String: Any]] = [:]
                for await (uid, data) in group {
                    if let data { map[uid] = data }
                }
                return map
            }
            try Task.checkCancellation()

            let profiles = entries.compactMap { entry -> DiscoveredProfile? in
                guard let userData = userDocs[entry.uid] else { return nil }
                return DiscoveredProfile(documentID: entry.uid, data: userData, oxygenCollected: entry.oxygen)
            }
            #if DEBUG
            print("📊 user-event oxygen: \(snapshot.documents.count) docs, \(entries.count) entries, \(profiles.count) matched users")
            #endif
            return DiscoveryPage(profiles: profiles, nextCursor: nil)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            print("⚠️ user-event oxygen query failed, falling back to rankings:", error.localizedDescription)
            let snapshot = try await db.collection("rankings")
                .order(by: "oxygenCollect", descending: true)
                .limit(to: limit)
                .getDocuments()
            try Task.checkCancellation()
            let profiles = snapshot.documents.compactMap { document -> DiscoveredProfile? in
                let data = document.data()
                return DiscoveredProfile(documentID: document.documentID, data: data,
                                         oxygenCollected: DiscoveryValue.int(data["oxygenCollect"]))
            }
            return DiscoveryPage(profiles: profiles, nextCursor: nil)
        }
    }

    private struct WorldCursor: Codable {
        let pivot: String
        let lastID: String
        let wrapped: Bool
    }

    private func randomWorldPage(after cursor: String?) async throws -> DiscoveryPage {
        let limit = 30
        let previous = cursor.flatMap { Data(base64Encoded: $0) }
            .flatMap { try? JSONDecoder().decode(WorldCursor.self, from: $0) }
        // Generating an auto-ID does not create or write a document.
        let pivot = previous?.pivot ?? db.collection("users").document().documentID
        let base = db.collection("users").order(by: FieldPath.documentID())
        var wrapped = previous?.wrapped ?? false
        var query: Query
        if wrapped {
            query = base.start(after: [previous?.lastID ?? pivot]).end(before: [pivot])
        } else if let previous {
            query = base.start(after: [previous.lastID])
        } else {
            query = base.start(at: [pivot])
        }
        var documents = try await query.limit(to: limit).getDocuments().documents
        try Task.checkCancellation()
        // Continue from the beginning once, then stop at the original pivot.
        if !wrapped && documents.count < limit {
            wrapped = true
            let remaining = limit - documents.count
            let beginning = try await base.end(before: [pivot]).limit(to: remaining).getDocuments()
            try Task.checkCancellation()
            documents.append(contentsOf: beginning.documents)
        }
        let profiles = documents.compactMap { document -> DiscoveredProfile? in
            let data = document.data()
            guard !(data["plants"] as? [Any] ?? []).isEmpty else { return nil }
            return DiscoveredProfile(documentID: document.documentID, data: data)
        }.shuffled()
        let next: String?
        if documents.count == limit, let lastID = documents.last?.documentID {
            next = try JSONEncoder().encode(WorldCursor(pivot: pivot, lastID: lastID, wrapped: wrapped)).base64EncodedString()
        } else {
            next = nil
        }
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

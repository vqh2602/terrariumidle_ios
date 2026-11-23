import Foundation

/// Chỉ chứa dữ liệu công khai. Các model dành cho khách ghé thăm không thể truyền vào saveGarden/updateDataUser.
struct DiscoveredProfile: Identifiable, Equatable {
    let id: String
    let name: String
    let avatar: String?
    let level: Int
    let floors: Int
    let likes: Int
    let oxygenCollected: Int?

    init?(documentID: String, data: [String: Any], oxygenCollected: Int? = nil) {
        guard !documentID.isEmpty, !documentID.contains("/"),
              !DiscoveryValue.bool(data["isBan"]),
              let user = data["user"] as? [String: Any] else { return nil }
        // Document ID luôn là định danh chuẩn, kể cả với các hồ sơ legacy bị thiếu hoặc không khớp userID.
        id = documentID
        let rawName = (user["userName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        name = rawName.isEmpty ? "Người làm vườn" : rawName
        avatar = user["userAvatar"] as? String
        level = max(1, DiscoveryValue.int(user["userLevel"]))
        floors = max(0, DiscoveryValue.int(user["userFloor"]))
        likes = max(0, DiscoveryValue.int(user["userTotalLike"]))
        self.oxygenCollected = oxygenCollected.map { max(0, $0) }
    }
}

struct VisitorGarden {
    struct Slot: Identifiable, Equatable {
        let row: Int
        let column: Int
        let plantID: String
        let potID: String
        let level: Int
        let isHanging: Bool
        var id: String { "\(row),\(column)" }
        var isSticker: Bool { plantID.hasPrefix("sticker") && plantID == potID }
    }

    static let maximumFloor = 500
    let profile: DiscoveredProfile
    let topFloor: Int
    let slots: [String: Slot]

    init(documentID: String, data: [String: Any]) throws {
        guard let profile = DiscoveredProfile(documentID: documentID, data: data) else {
            throw DiscoveryError.unavailable
        }
        self.profile = profile
        // Phân tích cú pháp snapshot độc lập: tuyệt đối không chuẩn hoá hay phát tán qua store của chủ vườn.
        var indexed: [String: Slot] = [:]
        let plants = data["plants"] as? [Any] ?? []
        for case let plant as [String: Any] in plants {
            guard let position = plant["position"] as? String else { continue }
            let components = position.split(separator: ",", omittingEmptySubsequences: false)
            guard components.count == 2, let row = Int(components[0]), let column = Int(components[1]),
                  (0...Self.maximumFloor).contains(row), (1...3).contains(column) else { continue }
            let plantID = (plant["idPlant"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let potID = (plant["idPot"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !plantID.isEmpty || !potID.isEmpty else { continue }
            let slot = Slot(row: row, column: column, plantID: plantID, potID: potID,
                            level: min(max(1, DiscoveryValue.int(plant["plantLevel"])), 10),
                            isHanging: DiscoveryValue.bool(plant["isHanging"]))
            if let previous = indexed[slot.id] {
                let previousComplete = !previous.plantID.isEmpty && !previous.potID.isEmpty
                let complete = !slot.plantID.isEmpty && !slot.potID.isEmpty
                if previousComplete && !complete { continue }
                if previousComplete == complete && previous.level > slot.level { continue }
            }
            indexed[slot.id] = slot
        }
        slots = indexed
        topFloor = max(min(profile.floors, Self.maximumFloor), indexed.values.map(\.row).max() ?? 0)
    }

    func slot(row: Int, column: Int) -> Slot? { slots["\(row),\(column)"] }
}

enum DiscoveryCategory: String, CaseIterable, Identifiable {
    case world = "Thế giới"
    case likes = "Yêu thích"
    case level = "Cấp độ"
    case oxygen = "Thu thập"
    var id: Self { self }
}

struct DiscoveryPage {
    let profiles: [DiscoveredProfile]
    let nextCursor: String?
}

enum DiscoveryError: LocalizedError {
    case invalidID, unavailable
    var errorDescription: String? {
        switch self {
        case .invalidID: return "ID khu vườn không hợp lệ."
        case .unavailable: return "Khu vườn không tồn tại hoặc hiện không thể xem."
        }
    }
}

enum DiscoveryValue {
    static func int(_ value: Any?) -> Int {
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) ?? 0 }
        return 0
    }
    static func bool(_ value: Any?) -> Bool {
        if let string = value as? String { return string == "true" || string == "1" }
        return (value as? NSNumber)?.boolValue ?? false
    }
}

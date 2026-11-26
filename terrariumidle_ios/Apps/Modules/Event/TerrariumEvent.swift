import Foundation

struct TerrariumEvent: Decodable, Identifiable, Hashable {
    struct Content: Decodable, Hashable {
        let local: String
        let description: String
        let title: String
        let image: String
    }

    struct Feed: Decodable {
        let data: [TerrariumEvent]
    }

    static let feedURL = URL(string: "https://vqh2602.github.io/terrarium_data.github.io/event_terrarium.json")!
    static let webBase = "https://vqh2602.github.io/dailycoccoli_data.github.io/event/"

    let eventdata: [Content]
    let start: String
    let end: String
    let create: String
    let version: String
    let link: String
    var id: String { "\(link)|\(start)|\(end)" }

    func content(language: String = Locale.current.language.languageCode?.identifier ?? "en") -> Content? {
        eventdata.first { $0.local == language } ?? eventdata.first { $0.local == "en" } ?? eventdata.first
    }

    // Feed thực tế có thể chứa ngày không đệm số 0 và năm dạng 20100. So sánh trực tiếp
    // các thành phần lịch thay vì phụ thuộc vào DateFormatter 4 chữ số.
    static func dayValue(_ value: String) -> Int? {
        let fields = value.split(separator: "-", omittingEmptySubsequences: false)
        let parts = fields.compactMap { Int($0) }
        guard fields.count == 3, parts.count == 3, (1...99999).contains(parts[0]),
              (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        return parts[0] * 10000 + parts[1] * 100 + parts[2]
    }

    func unavailableReason(now: Date = Date(), appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") -> String? {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        let today = (components.year ?? 0) * 10000 + (components.month ?? 0) * 100 + (components.day ?? 0)
        guard let firstDay = Self.dayValue(start), let lastDay = Self.dayValue(end) else { return "Lịch sự kiện chưa hợp lệ".tr }
        if today < firstDay { return "Chưa bắt đầu".tr }
        if today > lastDay { return "Đã kết thúc".tr }
        if !Self.supportsVersion(appVersion, minimum: version) { return "Yêu cầu phiên bản %@".tr(version) }
        return nil
    }

    static func supportsVersion(_ current: String, minimum: String) -> Bool {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let requiredParts = minimum.split(separator: ".").compactMap { Int($0) }
        guard !currentParts.isEmpty, !requiredParts.isEmpty else { return false }
        for index in 0..<max(currentParts.count, requiredParts.count) {
            let lhs = index < currentParts.count ? currentParts[index] : 0
            let rhs = index < requiredParts.count ? requiredParts[index] : 0
            if lhs != rhs { return lhs > rhs }
        }
        return true
    }

    var handler: String? {
        switch link {
        case "clam-level-up": return "event_get_bag_level"
        case "clam-floor": return "event_get_bag_floor"
        case "clam-lavender-plant": return "clam-lavender-plant"
        default: return nil
        }
    }

    var v2EventId: String? {
        guard let url = URL(string: link),
              url.scheme == "https",
              url.host == "vqh2602.github.io",
              url.path.hasPrefix("/terrarium_data.github.io/terrarium-events-web/events/") else {
            return nil
        }
        switch url.lastPathComponent {
        case "slot.html": return "slot"
        case "match.html": return "match"
        case "oxygen.html": return "oxygen"
        case "level.html": return "level"
        case "daily.html": return "daily"
        default: return nil
        }
    }

    func webURL(garden: GardenModel?) -> URL? {
        let path: String
        switch link {
        case "clam-level-up": path = "event_level_terrarium/index.html"
        case "clam-floor": path = "events_floors/index.html"
        case "clam-lavender-plant": path = "lucky-wheel/index.html"
        default:
            guard let url = URL(string: link), url.scheme == "https", url.host != nil else { return nil }
            return url
        }
        guard let garden, var url = URLComponents(string: Self.webBase + path) else { return nil }
        url.queryItems = [
            URLQueryItem(name: "userId", value: garden.user.userID),
            URLQueryItem(name: "userLevel", value: String(garden.user.userLevel)),
            URLQueryItem(name: "userFloor", value: String(garden.user.userFloor)),
            URLQueryItem(name: "bagId", value: garden.user.bag.map(\.idBag).joined(separator: ",")),
            URLQueryItem(name: "plants", value: garden.cart.cartPlants.joined(separator: ",")),
            URLQueryItem(name: "pots", value: garden.cart.cartPots.joined(separator: ",")),
            URLQueryItem(name: "oxygen", value: String(garden.money.oxygen))
        ]
        return url.url
    }
}

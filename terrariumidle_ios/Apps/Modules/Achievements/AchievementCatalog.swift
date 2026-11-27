import Foundation

enum AchievementMetric: String, Codable, CaseIterable {
    case plantsOwned, potsOwned, stickersOwned, animalsOwned, matureSpecies
    case plantLevel, gardenerLevel, floors, activeDays, harvests, oxygenCollected
    case watering, fertilizing, weather, gardensVisited, heartsGiven, likesReceived
    case plantings, plantedTogether
}

struct GardenAchievement: Identifiable, Codable {
    let id: String
    let metric: AchievementMetric
    let target: Int
    let points: Int
    let icon: String
    let titleVI: String
    let titleEN: String
    let descriptionVI: String
    let descriptionEN: String

    func percent(for progress: AchievementProgress) -> Double {
        min(100, max(0, Double(progress.value(for: metric)) / Double(target) * 100))
    }
}

enum AchievementCatalog {
    /// Permanent Game Center IDs. Never rename a published ID or change its target.
    static let all: [GardenAchievement] = {
        var result: [GardenAchievement] = []
        func series(_ metric: AchievementMetric, _ targets: [Int], _ icon: String,
                    _ vi: String, _ en: String, _ descriptionVI: String, _ descriptionEN: String) {
            for (index, target) in targets.enumerated() {
                result.append(GardenAchievement(
                    id: "terrarium.achievement.\(metric.rawValue).\(target)",
                    metric: metric, target: target, points: 10, icon: icon,
                    titleVI: "\(vi) \(index + 1)", titleEN: "\(en) \(index + 1)",
                    descriptionVI: descriptionVI.replacingOccurrences(of: "{n}", with: String(target)),
                    descriptionEN: descriptionEN.replacingOccurrences(of: "{n}", with: String(target))
                ))
            }
        }
        series(.plantsOwned, [25, 55, 80], "leaf.fill", "Bộ sưu tập xanh", "Plant Collector",
               "Sưu tầm {n} loài cây khác nhau.", "Collect {n} different plant species.")
        series(.potsOwned, [25, 55, 80], "cup.and.saucer.fill", "Nghệ nhân chậu", "Pot Collector",
               "Sưu tầm {n} mẫu chậu khác nhau.", "Collect {n} different pot designs.")
        series(.stickersOwned, [4, 15, 30, 50], "sparkles", "Góc vườn xinh", "Garden Stylist",
               "Sưu tầm {n} vật trang trí khác nhau.", "Collect {n} different decorations.")
        series(.animalsOwned, [2, 8, 16, 25], "ladybug.fill", "Bạn nhỏ trong vườn", "Garden Friends",
               "Sưu tầm {n} loài động vật khác nhau.", "Collect {n} different garden animals.")
        series(.matureSpecies, [5, 15, 30, 55, 80], "tree.fill", "Đơm lá", "In Full Leaf",
               "Nuôi {n} loài cây khác nhau đạt cấp 3 trở lên.", "Grow {n} different plant species to level 3 or higher.")
        series(.plantLevel, [10, 25, 50, 100, 150, 200], "arrow.up.circle.fill", "Cây vươn cao", "Growing Strong",
               "Nuôi một cây đạt cấp {n}.", "Grow a plant to level {n}.")
        series(.gardenerLevel, [20, 50, 100, 200], "person.fill", "Người làm vườn", "Green Thumb",
               "Đạt cấp người chơi {n}.", "Reach gardener level {n}.")
        series(.floors, [5, 10, 20], "square.stack.3d.up.fill", "Vườn trên cao", "Sky Garden",
               "Nâng chỉ số tầng kệ lên {n}.", "Raise your shelf floor level to {n}.")
        series(.activeDays, [7, 30, 60, 90, 180, 365], "calendar", "Hẹn với khu vườn", "Garden Days",
               "Ghé vườn vào {n} ngày khác nhau, không cần liên tiếp.", "Visit your garden on {n} different days; no streak required.")
        series(.harvests, [1000, 10000, 100000, 1000000], "hand.tap.fill", "Chạm vào sắc xanh", "A Gentle Touch",
               "Thu hoạch oxy thành công {n} lần từ cây (kể cả tự động).", "Collect oxygen successfully {n} times from plants, including automatic harvests.")
        series(.oxygenCollected, [100000, 1000000, 10000000, 100000000], "bubbles.and.sparkles.fill", "Hơi thở xanh", "Fresh Air",
               "Thu hoạch tổng cộng {n} oxy từ cây kể từ khi có hệ thống thành tích.", "Harvest a total of {n} oxygen from plants since achievements were introduced.")
        series(.watering, [25, 100, 500], "drop.fill", "Giọt nước yêu thương", "Water With Care",
               "Tưới cây thành công {n} lần.", "Water plants successfully {n} times.")
        series(.fertilizing, [25, 100, 500], "sun.max.fill", "Dưỡng mầm", "Nourishing Growth",
               "Bón phân cho cây thành công {n} lần.", "Fertilize plants successfully {n} times.")
        series(.weather, [10, 50, 200], "cloud.sun.fill", "Nhịp trời trong vườn", "Garden Weather",
               "Tạo mưa hoặc gió thành công {n} lần.", "Start rain or wind successfully {n} times.")
        series(.gardensVisited, [10, 50, 100], "globe.asia.australia.fill", "Dạo quanh vườn bạn", "Garden Explorer",
               "Ghé thăm {n} khu vườn của những người chơi khác nhau.", "Visit the gardens of {n} different other players.")
        series(.heartsGiven, [10, 50, 100], "heart.fill", "Gửi chút yêu thương", "Spreading Kindness",
               "Gửi lượt thích thành công tới {n} khu vườn khác nhau.", "Successfully like {n} different other gardens.")
        series(.likesReceived, [25, 100, 500], "heart.circle.fill", "Khu vườn được yêu", "A Beloved Garden",
               "Nhận {n} lượt thích cho khu vườn của bạn.", "Receive {n} likes on your garden.")
        series(.plantings, [25, 100, 500], "plus.circle.fill", "Gieo thêm hy vọng", "Planting Hope",
               "Trồng cây mới thành công {n} lần kể từ khi có hệ thống thành tích.", "Plant a new plant successfully {n} times since achievements were introduced.")
        series(.plantedTogether, [9, 18, 36], "square.grid.3x3.fill", "Khu vườn sum suê", "A Lush Garden",
               "Có {n} cây cùng trồng trong vườn, không tính chậu trống và vật trang trí.", "Have {n} plants growing together, excluding empty pots and decorations.")
        return result
    }()
}

/// Grow-only counters, sets and maxima form a mergeable progress record.
/// Device counters merge with max per installation, then sum across installations.
struct AchievementProgress: Codable, Equatable {
    var counters: [String: [String: Int]] = [:]
    var collections: [String: Set<String>] = [:]
    var maxima: [String: Int] = [:]

    func value(for metric: AchievementMetric) -> Int {
        let total = (counters[metric.rawValue] ?? [:]).values.reduce(0) { sum, value in
            let (next, overflow) = sum.addingReportingOverflow(max(0, value))
            return overflow ? Int.max : next
        }
        return max(total, collections[metric.rawValue]?.count ?? 0, maxima[metric.rawValue] ?? 0)
    }

    mutating func increment(_ metric: AchievementMetric, device: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        let old = counters[metric.rawValue]?[device] ?? 0
        let (next, overflow) = old.addingReportingOverflow(amount)
        counters[metric.rawValue, default: [:]][device] = overflow ? Int.max : next
    }

    mutating func include(_ ids: [String], for metric: AchievementMetric) {
        collections[metric.rawValue, default: []].formUnion(ids.filter { !$0.isEmpty })
    }

    mutating func observe(_ value: Int, for metric: AchievementMetric) {
        maxima[metric.rawValue] = max(maxima[metric.rawValue] ?? 0, value)
    }

    mutating func merge(_ other: AchievementProgress) {
        for (metric, devices) in other.counters {
            for (device, value) in devices {
                counters[metric, default: [:]][device] = max(counters[metric]?[device] ?? 0, value)
            }
        }
        for (metric, ids) in other.collections { collections[metric, default: []].formUnion(ids) }
        for (metric, value) in other.maxima { maxima[metric] = max(maxima[metric] ?? 0, value) }
    }

    static func dayID(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    init() {}

    init(dictionary: [String: Any]) {
        if let counters = dictionary["counters"] as? [String: [String: NSNumber]] {
            self.counters = counters.mapValues { $0.mapValues { max(0, $0.intValue) } }
        }
        if let collections = dictionary["collections"] as? [String: [String]] {
            self.collections = collections.mapValues { Set($0) }
        }
        if let maxima = dictionary["maxima"] as? [String: NSNumber] {
            self.maxima = maxima.mapValues { max(0, $0.intValue) }
        }
    }

    var dictionary: [String: Any] {
        ["counters": counters, "collections": collections.mapValues { $0.sorted() }, "maxima": maxima]
    }
}

enum AchievementReportPlan {
    /// Only IDs configured by Apple, whole percentages, strictly increasing progress.
    static func updates(progress: AchievementProgress, configured: Set<String>, reported: [String: Double]) -> [String: Double] {
        var result: [String: Double] = [:]
        for item in AchievementCatalog.all where configured.contains(item.id) {
            let percent = floor(item.percent(for: progress))
            if percent > (reported[item.id] ?? 0) { result[item.id] = percent }
        }
        return result
    }
}

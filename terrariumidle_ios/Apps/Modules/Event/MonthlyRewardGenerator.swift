import Foundation

struct MonthlyRewardItem: Equatable {
    let day: Int
    let rewardId: String
    let quantity: Int
    let rarity: String

    func toDictionary() -> [String: Any] {
        [
            "day": day,
            "rewardId": rewardId,
            "quantity": quantity,
            "rarity": rarity,
        ]
    }

    init(day: Int, rewardId: String, quantity: Int, rarity: String) {
        self.day = day
        self.rewardId = rewardId
        self.quantity = quantity
        self.rarity = rarity
    }

    init?(dict: [String: Any]) {
        guard let rewardId = dict["rewardId"] as? String, !rewardId.isEmpty else { return nil }
        let day = (dict["day"] as? NSNumber)?.intValue ?? 0
        let quantity = max(1, (dict["quantity"] as? NSNumber)?.intValue ?? 1)
        let rarity = (dict["rarity"] as? String) ?? MonthlyRewardGenerator.rarity(for: rewardId)
        guard day >= 1 else { return nil }
        self.day = day
        self.rewardId = rewardId
        self.quantity = quantity
        self.rarity = rarity
    }
}

enum MonthlyRewardGenerator {
    struct Spec {
        let id: String
        let rarity: String
        let weight: Int
        let quantities: [Int]
        let milestoneQuantities: [Int]
    }

    static let specs: [Spec] = [
        Spec(id: "oxygen", rarity: "common", weight: 38, quantities: [250, 300, 350, 400, 450, 500, 600], milestoneQuantities: [750, 900, 1000, 1200]),
        Spec(id: "fertilizer", rarity: "uncommon", weight: 24, quantities: [2, 3, 4, 5], milestoneQuantities: [5, 6, 8]),
        Spec(id: "shovel", rarity: "rare", weight: 16, quantities: [1, 2, 3], milestoneQuantities: [3, 4]),
        Spec(id: "gemstone", rarity: "epic", weight: 14, quantities: [5, 8, 10, 12, 15], milestoneQuantities: [18, 20, 25]),
        Spec(id: "ticket", rarity: "legendary", weight: 8, quantities: [1, 2], milestoneQuantities: [2, 3]),
    ]

    static let milestoneDays: Set<Int> = [7, 14, 21, 28, 30]

    static func rarity(for rewardId: String) -> String {
        specs.first(where: { $0.id == rewardId })?.rarity ?? "common"
    }

    static func generate(monthKey: String, seedSalt: String = "") -> [MonthlyRewardItem] {
        var rng = SeededGenerator(seed: "\(monthKey):\(seedSalt)")
        let milestonePool = specs.filter { ["shovel", "gemstone", "ticket", "oxygen"].contains($0.id) }

        var items: [MonthlyRewardItem] = []
        items.reserveCapacity(30)

        for day in 1 ... 30 {
            let isMilestone = milestoneDays.contains(day)
            let spec: Spec
            if day == 30 {
                let roll = rng.nextUnit()
                spec = roll < 0.55 ? specFor("ticket") : specFor("gemstone")
            } else if isMilestone {
                spec = pickWeighted(from: milestonePool, using: &rng)
            } else {
                spec = pickWeighted(from: specs, using: &rng)
            }

            let qtyPool = isMilestone ? spec.milestoneQuantities : spec.quantities
            let qty = qtyPool[rng.nextIndex(upperBound: qtyPool.count)]
            items.append(MonthlyRewardItem(day: day, rewardId: spec.id, quantity: qty, rarity: spec.rarity))
        }

        // Guarantee all 5 item categories appear in every generated month.
        let required = ["oxygen", "fertilizer", "shovel", "gemstone", "ticket"]
        var present = Set(items.map(\.rewardId))
        let normalIndices = items.indices.filter { !milestoneDays.contains(items[$0].day) }
        var cursor = 0
        for id in required where !present.contains(id) && cursor < normalIndices.count {
            let idx = normalIndices[cursor]
            cursor += 1
            let spec = specFor(id)
            let qty = spec.quantities[rng.nextIndex(upperBound: spec.quantities.count)]
            items[idx] = MonthlyRewardItem(day: items[idx].day, rewardId: spec.id, quantity: qty, rarity: spec.rarity)
            present.insert(id)
        }

        return items
    }

    private static func specFor(_ id: String) -> Spec {
        specs.first { $0.id == id } ?? specs[0]
    }

    private static func pickWeighted(from list: [Spec], using rng: inout SeededGenerator) -> Spec {
        let total = list.reduce(0) { $0 + $1.weight }
        var roll = rng.nextUnit() * Double(total)
        for item in list {
            roll -= Double(item.weight)
            if roll <= 0 { return item }
        }
        return list.last ?? specs[0]
    }
}

private struct SeededGenerator {
    private var state: UInt32

    init(seed: String) {
        var hash: UInt32 = 2166136261
        for byte in seed.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        self.state = hash == 0 ? 0x6D2B79F5 : hash
    }

    mutating func nextUInt32() -> UInt32 {
        state = state &+ 0x6D2B79F5
        var t = (state ^ (state >> 15)) &* (1 | state)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return t ^ (t >> 14)
    }

    mutating func nextUnit() -> Double {
        Double(nextUInt32()) / Double(UInt32.max)
    }

    mutating func nextIndex(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(nextUInt32() % UInt32(upperBound))
    }
}

//
//  GradenModel.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import Foundation

// MARK: - Garden Pest & Notification Models

struct GardenPest: Identifiable, Equatable, Codable {
    enum Source: String, Codable, Equatable {
        case auto
        case visitor
    }

    let id: String
    let kind: PestSpecies
    let position: String
    let plantId: String
    let source: Source
    let senderId: String?
    let senderName: String?
    let createdAt: TimeInterval

    init(
        id: String = UUID().uuidString,
        kind: PestSpecies,
        position: String,
        plantId: String,
        source: Source,
        senderId: String? = nil,
        senderName: String? = nil,
        createdAt: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.plantId = plantId
        self.source = source
        self.senderId = senderId
        self.senderName = senderName
        self.createdAt = createdAt
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String, !id.isEmpty,
              let kindRaw = dict["kind"] as? String,
              let kind = PestSpecies(rawValue: kindRaw),
              let position = dict["position"] as? String, !position.isEmpty else {
            return nil
        }
        self.id = id
        self.kind = kind
        self.position = position
        self.plantId = (dict["plantId"] as? String) ?? ""
        self.source = Source(rawValue: (dict["source"] as? String) ?? "auto") ?? .auto
        self.senderId = dict["senderId"] as? String
        self.senderName = dict["senderName"] as? String
        self.createdAt = (dict["createdAt"] as? NSNumber)?.doubleValue ?? 0
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "kind": kind.rawValue,
            "position": position,
            "plantId": plantId,
            "source": source.rawValue,
            "createdAt": createdAt
        ]
        if let senderId { dict["senderId"] = senderId }
        if let senderName { dict["senderName"] = senderName }
        return dict
    }
}

struct GardenPestNotification: Identifiable, Equatable, Codable {
    let id: String
    let senderId: String
    let senderName: String
    let kind: PestSpecies
    let position: String
    let createdAt: TimeInterval

    init(
        id: String = UUID().uuidString,
        senderId: String,
        senderName: String,
        kind: PestSpecies,
        position: String,
        createdAt: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.kind = kind
        self.position = position
        self.createdAt = createdAt
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String, !id.isEmpty,
              let kindRaw = dict["kind"] as? String,
              let kind = PestSpecies(rawValue: kindRaw) else {
            return nil
        }
        self.id = id
        self.senderId = (dict["senderId"] as? String) ?? ""
        let rawName = (dict["senderName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.senderName = rawName.isEmpty ? "Người chơi khác".tr : rawName
        self.kind = kind
        self.position = (dict["position"] as? String) ?? ""
        self.createdAt = (dict["createdAt"] as? NSNumber)?.doubleValue ?? 0
    }

    func toDictionary() -> [String: Any] {
        [
            "id": id,
            "senderId": senderId,
            "senderName": senderName,
            "kind": kind.rawValue,
            "position": position,
            "createdAt": createdAt
        ]
    }
}

// MARK: - Model

struct GardenModel {
    static let maxBagCapacity = 5
    static let maxDailyVisitorPestDrops = 10
    static let visitorDropOxygenReward = 350
    static let pestKillOxygenReward = 300
    static let pestPenaltyMultiplier = 0.3
    static let autoPestSpawnCooldown: TimeInterval = 55
    static let maxActiveAutoPests = 3

    let isBan: Int
    let isServerUpdate: Int

    var item: Item
    var cart: Cart
    var money: Money
    var user: UserProfile
    var plants: [Plant]
    /// Cumulative sleep credit already reflected in this local wallet snapshot.
    var sleepRewardOxygen: Int = 0
    var sleepRewardGems: Int = 0
    var sleepRewardTickets: Int = 0
    /// Cumulative steps credit already reflected in this local wallet snapshot.
    var stepsRewardOxygen: Int = 0
    var stepsRewardGems: Int = 0
    var stepsRewardTickets: Int = 0
    var weatherUntil: TimeInterval = 0
    var weatherKind: WeatherKind = .rain
    var vipStatus: VIPStatus = VIPStatus()
    var pests: [GardenPest] = []
    var capturedPests: [PestSpecies] = []
    var pestNotifications: [GardenPestNotification] = []
    var sprayUsageDate: String = ""
    var sprayUsageCount: Int = 0
    var pestDropDate: String = ""
    var pestDropCount: Int = 0
    var lastAutoPestSpawnAt: TimeInterval = 0

    struct VIPStatus: Equatable {
        var isActive: Bool = false
        var productId: String? = nil
        var expiresAt: TimeInterval = 0
        var willAutoRenew: Bool = false
        var welcomeBonusClaimed: Bool = false
        var source: String? = nil
        var originalTransactionId: String? = nil
        var updatedAt: TimeInterval = 0

        var isCurrentlyActive: Bool {
            isActive && (expiresAt <= 0 || expiresAt > Date().timeIntervalSince1970)
        }
    }

    struct Item {
        var fertilizer: Int
        var shovel: Int
    }

    struct Cart {
        let cartPlants: [String]
        let cartPots: [String]
        let cartStickers: [String]
        let cartAnimals: [String]

        init(cartPlants: [String], cartPots: [String], cartStickers: [String], cartAnimals: [String] = []) {
            self.cartPlants = cartPlants
            self.cartPots = cartPots
            self.cartStickers = cartStickers
            self.cartAnimals = cartAnimals
        }
    }

    struct Money {
        var gemstone: Int
        var oxygen: Int // Made mutable for tap rewards
        var ticket: Int
    }

    struct UserProfile {
        struct BagItem {
            let colorBag: UInt64
            let idBag: String
            let nameBag: String
        }

        let bag: [BagItem]
        let identifier: String?
        let latestPurchaseDate: String?
        var userAvatar: String?
        let userEmail: String?

        var userFloor: Int // Made mutable for user leveling
        let userID: String
        let userImageBackground: String?

        var userLevel: Int // Made mutable for user leveling
        var userLevelEXP: Int // Made mutable for EXP progression
        let userName: String
        let userTotalLike: Int
    }

    struct Plant {
        let harvestTime: Int64
        var idPlant: String
        var idPot: String
        let isHanging: Bool
        var plantLevel: Int // Made mutable for leveling
        var platLevelExp: Int // Made mutable for EXP progression
        var position: String // Made mutable for drag-and-drop
        var wateringUntil: TimeInterval = 0
    }
}

// MARK: - Watering

extension GardenModel {
    enum WateringResult {
        case watered, insufficientDiamonds, alreadyWatering, invalidPlant
    }

    /// Charge once and store the deadline on the plant so leveling and moving preserve it.
    mutating func waterPlant(at position: String, plantId: String, now: TimeInterval) -> WateringResult {
        guard let index = plants.lastIndex(where: {
            $0.position == position && $0.idPlant == plantId &&
            $0.idPlant.hasPrefix("plant") && !$0.idPot.isEmpty
        }) else { return .invalidPlant }
        guard max(plants[index].wateringUntil, weatherUntil) <= now else { return .alreadyWatering }
        guard money.gemstone >= 10 else { return .insufficientDiamonds }
        money.gemstone -= 10
        plants[index].wateringUntil = now + 60
        return .watered
    }
}

// MARK: - Change Pot (VIP)

extension GardenModel {
    enum ChangePotResult {
        case changed, vipRequired, insufficientOxygen, samePot, invalidPlant, invalidPot
    }

    /// Replace a plant's pot by paying the new pot's oxygen price without refunding the old pot.
    mutating func changePot(
        at position: String,
        plantId: String,
        to newPotId: String,
        cost: Int,
        isVIP: Bool
    ) -> ChangePotResult {
        guard isVIP else { return .vipRequired }
        guard !newPotId.isEmpty, cost >= 0 else { return .invalidPot }
        guard let index = plants.lastIndex(where: {
            $0.position == position &&
            $0.idPlant == plantId &&
            !$0.idPlant.isEmpty &&
            !$0.idPot.isEmpty &&
            $0.idPlant != $0.idPot
        }) else { return .invalidPlant }
        guard plants[index].idPot != newPotId else { return .samePot }
        guard money.oxygen >= cost else { return .insufficientOxygen }
        money.oxygen -= cost
        plants[index].idPot = newPotId
        return .changed
    }
}

// MARK: - Garden weather & Pests

extension GardenModel {
    enum WeatherKind: String, CaseIterable, Identifiable {
        case rain, wind, spray

        var id: Self { self }

        var title: String {
            switch self {
            case .rain: return "Mưa".tr
            case .wind: return "Gió".tr
            case .spray: return "Xịt hóa chất".tr
            }
        }

        var icon: String {
            switch self {
            case .rain: return "cloud.rain.fill"
            case .wind: return "wind"
            case .spray: return "aqi.medium"
            }
        }

        var soundFileName: String {
            switch self {
            case .rain: return "mixkit-light-rain-loop-2393"
            case .wind: return "mixkit-wind-in-the-forest-loop-1233"
            case .spray: return "soundreality-spray-178360"
            }
        }

        var soundFileExtension: String {
            switch self {
            case .rain, .wind: return "wav"
            case .spray: return "mp3"
            }
        }

        var duration: TimeInterval {
            switch self {
            case .rain, .wind: return 60
            case .spray: return 5
            }
        }

        var autoTapsPlants: Bool {
            self != .spray
        }
    }

    enum WeatherResult {
        case started, insufficientTickets, alreadyActive, noPlants
    }

    var weatherPlants: [Plant] {
        // Only the last record at each socket is displayed by the garden.
        var positions = Set<String>()
        return plants.reversed().filter { plant in
            guard positions.insert(plant.position).inserted else { return false }
            return plant.idPlant.hasPrefix("plant") && !plant.idPot.isEmpty
        }
    }

    static func todayDateKey(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func sprayFreeLimit(isVIP: Bool) -> Int {
        isVIP ? 5 : 1
    }

    func usedFreeSpraysToday(now: Date = Date()) -> Int {
        let today = Self.todayDateKey(date: now)
        return sprayUsageDate == today ? max(0, sprayUsageCount) : 0
    }

    func remainingFreeSprays(isVIP: Bool, now: Date = Date()) -> Int {
        let limit = Self.sprayFreeLimit(isVIP: isVIP)
        return max(0, limit - usedFreeSpraysToday(now: now))
    }

    func usedVisitorPestDropsToday(now: Date = Date()) -> Int {
        let today = Self.todayDateKey(date: now)
        return pestDropDate == today ? max(0, pestDropCount) : 0
    }

    func remainingVisitorPestDrops(now: Date = Date()) -> Int {
        max(0, Self.maxDailyVisitorPestDrops - usedVisitorPestDropsToday(now: now))
    }

    var bugsNetPosition: String? {
        var latestByPos: [String: Plant] = [:]
        for plant in plants where !plant.idPlant.isEmpty && !plant.idPot.isEmpty {
            latestByPos[plant.position] = plant
        }
        return latestByPos.values.first(where: { $0.idPlant == "animal3" && $0.idPot == "animal3" })?.position
    }

    var hasBugsNet: Bool {
        bugsNetPosition != nil
    }

    func isPlantInfested(at position: String) -> Bool {
        pests.contains { $0.position == position }
    }

    mutating func startWeather(_ kind: WeatherKind, isVIP: Bool = false, now: TimeInterval, date: Date = Date()) -> WeatherResult {
        guard weatherUntil <= now else { return .alreadyActive }
        if kind == .spray {
            guard !weatherPlants.isEmpty || !pests.isEmpty else { return .noPlants }
            let today = Self.todayDateKey(date: date)
            if sprayUsageDate != today {
                sprayUsageDate = today
                sprayUsageCount = 0
            }
            let freeRemaining = Self.sprayFreeLimit(isVIP: isVIP) - sprayUsageCount
            if freeRemaining <= 0 {
                guard money.ticket >= 1 else { return .insufficientTickets }
                money.ticket -= 1
            }
            sprayUsageCount += 1
            weatherKind = .spray
            weatherUntil = now + kind.duration
            // Xịt hóa chất tiêu diệt toàn bộ côn trùng và không thu thập vào túi
            pests.removeAll()
            return .started
        } else {
            guard !weatherPlants.isEmpty else { return .noPlants }
            guard money.ticket >= 1 else { return .insufficientTickets }
            money.ticket -= 1
            weatherKind = kind
            weatherUntil = now + kind.duration
            return .started
        }
    }
}

// MARK: - Maximum Placement Limits

extension GardenModel {
    /// Count active unique slot positions currently occupied by the given item ID.
    func plantedCount(forItemId itemId: String, excludingPosition: String? = nil) -> Int {
        let cleanId = itemId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else { return 0 }
        var latestByPos: [String: Plant] = [:]
        for plant in plants where !plant.idPlant.isEmpty && !plant.idPot.isEmpty {
            latestByPos[plant.position] = plant
        }
        return latestByPos.values.filter { slot in
            if let excludingPosition, slot.position == excludingPosition { return false }
            return slot.idPlant.lowercased() == cleanId || slot.idPot.lowercased() == cleanId
        }.count
    }

    /// Check whether an item can still be placed in the garden under its `maximum` limit.
    func canPlantItem(_ item: ItemData, at position: String? = nil) -> Bool {
        guard let maxLimit = item.maximum, maxLimit > 0 else { return true }
        return plantedCount(forItemId: item.id, excludingPosition: position) < maxLimit
    }
}

// MARK: - Parse Error

enum ParseError: Error, CustomStringConvertible {
    case missing(String)
    case type(String)

    var description: String {
        switch self {
        case let .missing(k): return "Missing key: \(k)"
        case let .type(k): return "Type mismatch for key: \(k)"
        }
    }
}

// MARK: - Initializers from Dictionary

extension GardenModel {
    init(dict: [String: Any]) throws {
        // Preserve a rain session saved by the previous app version.
        weatherUntil = (dict["weatherUntil"] as? NSNumber)?.doubleValue
            ?? (dict["rainUntil"] as? NSNumber)?.doubleValue ?? 0
        weatherKind = WeatherKind(rawValue: dict["weatherKind"] as? String ?? "") ?? .rain
        isBan = dict.int("isBan")
        isServerUpdate = dict.int("isServerUpdate")

        item = try Item(dict: dict.dict("item"))
        cart = try Cart(dict: dict.dict("cart"))
        money = try Money(dict: dict.dict("money"))
        sleepRewardOxygen = dict.int("sleepRewardOxygen")
        sleepRewardGems = dict.int("sleepRewardGems")
        sleepRewardTickets = dict.int("sleepRewardTickets")
        stepsRewardOxygen = dict.int("stepsRewardOxygen")
        stepsRewardGems = dict.int("stepsRewardGems")
        stepsRewardTickets = dict.int("stepsRewardTickets")
        if let vipDict = dict["vip"] as? [String: Any] {
            vipStatus = VIPStatus(dict: vipDict)
        }
        pests = (dict["pests"] as? [[String: Any]] ?? []).compactMap { GardenPest(dict: $0) }
        capturedPests = Array((dict["capturedPests"] as? [String] ?? []).compactMap { PestSpecies(rawValue: $0) }.prefix(Self.maxBagCapacity))
        pestNotifications = (dict["pestNotifications"] as? [[String: Any]] ?? []).compactMap { GardenPestNotification(dict: $0) }
        if let sprayDict = dict["sprayUsage"] as? [String: Any] {
            sprayUsageDate = (sprayDict["date"] as? String) ?? ""
            sprayUsageCount = (sprayDict["count"] as? NSNumber)?.intValue ?? 0
        }
        if let dropDict = dict["pestDropLog"] as? [String: Any] {
            pestDropDate = (dropDict["date"] as? String) ?? ""
            pestDropCount = (dropDict["count"] as? NSNumber)?.intValue ?? 0
        }
        lastAutoPestSpawnAt = (dict["lastAutoPestSpawnAt"] as? NSNumber)?.doubleValue ?? 0
        user = try UserProfile(dict: dict.dict("user"))

        let plantsAny = dict.array("plants")
        plants = try plantsAny.map { any in
            guard let p = any as? [String: Any] else { throw ParseError.type("plants[]") }
            return try Plant(dict: p)
        }
    }
}

extension GardenModel.Item {
    init(dict: [String: Any]) throws {
        fertilizer = dict.int("fertilizer")
        shovel = dict.int("shovel")
    }
}

extension GardenModel.VIPStatus {
    init(dict: [String: Any]) {
        isActive = (dict["isActive"] as? Bool) ?? ((dict["isActive"] as? NSNumber)?.boolValue ?? false)
        productId = dict.optionalStringOrNull("productId")
        expiresAt = (dict["expiresAt"] as? NSNumber)?.doubleValue ?? 0
        willAutoRenew = (dict["willAutoRenew"] as? Bool) ?? ((dict["willAutoRenew"] as? NSNumber)?.boolValue ?? false)
        welcomeBonusClaimed = (dict["welcomeBonusClaimed"] as? Bool) ?? ((dict["welcomeBonusClaimed"] as? NSNumber)?.boolValue ?? false)
        source = dict.optionalStringOrNull("source")
        originalTransactionId = dict.optionalStringOrNull("originalTransactionId")
        updatedAt = (dict["updatedAt"] as? NSNumber)?.doubleValue ?? 0
    }

    func toDictionary() -> [String: Any] {
        return [
            "isActive": isActive,
            "productId": productId ?? NSNull(),
            "expiresAt": expiresAt,
            "willAutoRenew": willAutoRenew,
            "welcomeBonusClaimed": welcomeBonusClaimed,
            "source": source ?? NSNull(),
            "originalTransactionId": originalTransactionId ?? NSNull(),
            "updatedAt": updatedAt,
        ]
    }
}

extension GardenModel.Cart {
    init(dict: [String: Any]) throws {
        cartPlants = dict.stringArray("cartPlants")
        cartPots = dict.stringArray("cartPots")
        cartStickers = dict.stringArray("cartStickers")
        cartAnimals = dict.stringArray("cartAnimals")
    }
}

extension GardenModel.Money {
    init(dict: [String: Any]) throws {
        gemstone = dict.int("gemstone")
        oxygen = dict.int("oxygen")
        ticket = dict.int("ticket")
    }
}

extension GardenModel.UserProfile {
    init(dict: [String: Any]) throws {
        // bag: [ {colorBag, idBag, nameBag}, ...]
        let bagAny = dict.array("bag")
        bag = bagAny.compactMap { any in
            guard let b = any as? [String: Any] else { return nil }
            return BagItem(
                colorBag: b.uInt64("colorBag"),
                idBag: b.string("idBag"),
                nameBag: b.string("nameBag")
            )
        }

        identifier = dict.optionalStringOrNull("identifier")
        latestPurchaseDate = dict.optionalStringOrNull("latestPurchaseDate")
        userAvatar = dict.optionalStringOrNull("userAvatar")
        userEmail = dict.optionalStringOrNull("userEmail")

        userFloor = dict.int("userFloor")
        userID = dict.string("userID")
        userImageBackground = dict.optionalStringOrNull("userImageBackground")

        userLevel = dict.int("userLevel")
        userLevelEXP = dict.int("userLevelEXP")
        userName = dict.string("userName")
        userTotalLike = dict.int("userTotalLike")
    }
}

extension GardenModel.Plant {
    init(dict: [String: Any]) throws {
        harvestTime = dict.int64("harvestTime")
        idPlant = dict.string("idPlant")
        idPot = dict.string("idPot")
        isHanging = dict["isHanging"] as? Bool ?? false
        plantLevel = dict.int("plantLevel")
        platLevelExp = dict.int("platLevelExp")
        position = dict.string("position")
        wateringUntil = (dict["wateringUntil"] as? NSNumber)?.doubleValue ?? 0
    }
}

// MARK: - Dictionary Helpers (typed getters)

private extension Dictionary where Key == String, Value == Any {
    func dict(_ key: String) throws -> [String: Any] {
        guard let d = self[key] as? [String: Any] else { throw ParseError.type(key) }
        return d
    }

    func array(_ key: String) -> [Any] {
        (self[key] as? [Any]) ?? []
    }

    func stringArray(_ key: String) -> [String] {
        // Sometimes comes as [Any]
        if let s = self[key] as? [String] { return s }
        if let a = self[key] as? [Any] { return a.compactMap { $0 as? String } }
        return []
    }

    func string(_ key: String) -> String {
        if let s = self[key] as? String { return s }
        if let n = self[key] as? NSNumber { return n.stringValue }
        return ""
    }

    /// handle "<null>" string and NSNull
    func optionalStringOrNull(_ key: String) -> String? {
        let v = self[key]
        if v is NSNull { return nil }
        if let s = v as? String {
            if s == "<null>" { return nil }
            return s
        }
        return nil
    }

    func int(_ key: String) -> Int {
        if let n = self[key] as? Int { return n }
        if let n = self[key] as? Int64 { return Int(n) }
        if let n = self[key] as? NSNumber { return n.intValue }
        if let s = self[key] as? String, let n = Int(s) { return n }
        return 0
    }

    func int64(_ key: String) -> Int64 {
        if let n = self[key] as? Int64 { return n }
        if let n = self[key] as? Int { return Int64(n) }
        if let n = self[key] as? NSNumber { return n.int64Value }
        if let s = self[key] as? String, let n = Int64(s) { return n }
        return 0
    }

    func uInt64(_ key: String) -> UInt64 {
        if let n = self[key] as? UInt64 { return n }
        if let n = self[key] as? Int { return UInt64(n) }
        if let n = self[key] as? NSNumber { return n.uint64Value }
        if let s = self[key] as? String, let n = UInt64(s) { return n }
        return 0
    }
}

// MARK: - Convert to Dictionary (for Firestore updates)

extension GardenModel {
    func toDictionary() -> [String: Any] {
        return [
            "weatherUntil": weatherUntil,
            "weatherKind": weatherKind.rawValue,
            "isBan": isBan,
            "isServerUpdate": isServerUpdate,
            "item": item.toDictionary(),
            "cart": cart.toDictionary(),
            "money": money.toDictionary(),
            "user": user.toDictionary(),
            "plants": plants.map { $0.toDictionary() },
            "vip": vipStatus.toDictionary(),
            "pests": pests.map { $0.toDictionary() },
            "capturedPests": Array(capturedPests.prefix(Self.maxBagCapacity)).map(\.rawValue),
            "sprayUsage": [
                "date": sprayUsageDate,
                "count": sprayUsageCount
            ],
            "pestDropLog": [
                "date": pestDropDate,
                "count": pestDropCount
            ],
            "lastAutoPestSpawnAt": lastAutoPestSpawnAt
        ]
    }
}

extension GardenModel.Item {
    func toDictionary() -> [String: Any] {
        return [
            "fertilizer": fertilizer,
            "shovel": shovel,
        ]
    }
}

extension GardenModel.Cart {
    func toDictionary() -> [String: Any] {
        return [
            "cartPlants": cartPlants,
            "cartPots": cartPots,
            "cartStickers": cartStickers,
            "cartAnimals": cartAnimals,
        ]
    }
}

extension GardenModel.Money {
    func toDictionary() -> [String: Any] {
        return [
            "gemstone": gemstone,
            "oxygen": oxygen,
            "ticket": ticket,
        ]
    }
}

extension GardenModel.UserProfile {
    func toDictionary() -> [String: Any] {
        return [
            "bag": bag.map { [
                "colorBag": $0.colorBag,
                "idBag": $0.idBag,
                "nameBag": $0.nameBag,
            ] },
            "identifier": identifier ?? NSNull(),
            "latestPurchaseDate": latestPurchaseDate ?? NSNull(),
            "userAvatar": userAvatar ?? NSNull(),
            "userEmail": userEmail ?? NSNull(),
            "userFloor": userFloor,
            "userID": userID,
            "userImageBackground": userImageBackground ?? NSNull(),
            "userLevel": userLevel,
            "userLevelEXP": userLevelEXP,
            "userName": userName,
            "userTotalLike": userTotalLike,
        ]
    }
}

extension GardenModel.Plant {
    func toDictionary() -> [String: Any] {
        return [
            "harvestTime": harvestTime,
            "idPlant": idPlant,
            "idPot": idPot,
            "isHanging": isHanging,
            "plantLevel": plantLevel,
            "platLevelExp": platLevelExp,
            "position": position,
            "wateringUntil": wateringUntil,
        ]
    }
}

// MARK: - Usage Example

func parseGardenExample(dict: [String: Any]) {
    do {
        let garden = try GardenModel(dict: dict)
        print("✅ Parsed GardenData")
        print("User:", garden.user.userName, "| Level:", garden.user.userLevel)
        print("Plants:", garden.plants.count)
        print("Money oxygen:", garden.money.oxygen)
    } catch {
        print("❌ Parse error:", error)
    }
}

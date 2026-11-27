//
//  GradenModel.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import Foundation

// MARK: - Model

struct GardenModel {
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
    var weatherUntil: TimeInterval = 0
    var weatherKind: WeatherKind = .rain
    var vipStatus: VIPStatus = VIPStatus()

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

// MARK: - Garden weather

extension GardenModel {
    enum WeatherKind: String, CaseIterable, Identifiable {
        case rain, wind

        var id: Self { self }
        var title: String { self == .rain ? "Mưa".tr : "Gió".tr }
        var icon: String { self == .rain ? "cloud.rain.fill" : "wind" }
        var soundFileName: String {
            switch self {
            case .rain: return "mixkit-light-rain-loop-2393"
            case .wind: return "mixkit-wind-in-the-forest-loop-1233"
            }
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

    mutating func startWeather(_ kind: WeatherKind, now: TimeInterval) -> WeatherResult {
        guard weatherUntil <= now else { return .alreadyActive }
        guard !weatherPlants.isEmpty else { return .noPlants }
        guard money.ticket >= 1 else { return .insufficientTickets }
        money.ticket -= 1
        weatherKind = kind
        weatherUntil = now + 60
        return .started
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
        if let vipDict = dict["vip"] as? [String: Any] {
            vipStatus = VIPStatus(dict: vipDict)
        }
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

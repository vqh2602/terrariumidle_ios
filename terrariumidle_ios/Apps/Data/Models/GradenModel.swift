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
    var rainUntil: TimeInterval = 0

    struct Item {
        var fertilizer: Int
        var shovel: Int
    }

    struct Cart {
        let cartPlants: [String]
        let cartPots: [String]
        let cartStickers: [String]
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
        let userAvatar: String?
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
        guard max(plants[index].wateringUntil, rainUntil) <= now else { return .alreadyWatering }
        guard money.gemstone >= 10 else { return .insufficientDiamonds }
        money.gemstone -= 10
        plants[index].wateringUntil = now + 60
        return .watered
    }
}

// MARK: - Garden rain

extension GardenModel {
    enum RainResult {
        case started, insufficientTickets, alreadyRaining, noPlants
    }

    var rainPlants: [Plant] {
        // Only the last record at each socket is displayed by the garden.
        var positions = Set<String>()
        return plants.reversed().filter { plant in
            guard positions.insert(plant.position).inserted else { return false }
            return plant.idPlant.hasPrefix("plant") && !plant.idPot.isEmpty
        }
    }

    mutating func startRain(now: TimeInterval) -> RainResult {
        guard rainUntil <= now else { return .alreadyRaining }
        guard !rainPlants.isEmpty else { return .noPlants }
        guard money.ticket >= 1 else { return .insufficientTickets }
        money.ticket -= 1
        rainUntil = now + 60
        return .started
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
        rainUntil = (dict["rainUntil"] as? NSNumber)?.doubleValue ?? 0
        isBan = dict.int("isBan")
        isServerUpdate = dict.int("isServerUpdate")

        item = try Item(dict: dict.dict("item"))
        cart = try Cart(dict: dict.dict("cart"))
        money = try Money(dict: dict.dict("money"))
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

extension GardenModel.Cart {
    init(dict: [String: Any]) throws {
        cartPlants = dict.stringArray("cartPlants")
        cartPots = dict.stringArray("cartPots")
        cartStickers = dict.stringArray("cartStickers")
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
            "rainUntil": rainUntil,
            "isBan": isBan,
            "isServerUpdate": isServerUpdate,
            "item": item.toDictionary(),
            "cart": cart.toDictionary(),
            "money": money.toDictionary(),
            "user": user.toDictionary(),
            "plants": plants.map { $0.toDictionary() },
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

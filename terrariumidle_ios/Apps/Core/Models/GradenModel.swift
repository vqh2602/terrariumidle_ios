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

    let item: Item
    let cart: Cart
    let money: Money
    let user: UserProfile
    let plants: [Plant]

    struct Item {
        let fertilizer: Int
        let shovel: Int
    }

    struct Cart {
        let cartPlants: [String]
        let cartPots: [String]
        let cartStickers: [String]
    }

    struct Money {
        let gemstone: Int
        let oxygen: Int
        let ticket: Int
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

        let userFloor: Int
        let userID: String
        let userImageBackground: String?

        let userLevel: Int
        let userLevelEXP: Int
        let userName: String
        let userTotalLike: Int
    }

    struct Plant {
        let harvestTime: Int64
        let idPlant: String
        let idPot: String
        let isHanging: Int
        let plantLevel: Int
        let platLevelExp: Int
        let position: String
    }
}

// MARK: - Parse Error

enum ParseError: Error, CustomStringConvertible {
    case missing(String)
    case type(String)

    var description: String {
        switch self {
        case .missing(let k): return "Missing key: \(k)"
        case .type(let k): return "Type mismatch for key: \(k)"
        }
    }
}

// MARK: - Initializers from Dictionary

extension GardenModel {
    init(dict: [String: Any]) throws {
        self.isBan = dict.int("isBan")
        self.isServerUpdate = dict.int("isServerUpdate")

        self.item = try Item(dict: try dict.dict("item"))
        self.cart = try Cart(dict: try dict.dict("cart"))
        self.money = try Money(dict: try dict.dict("money"))
        self.user = try UserProfile(dict: try dict.dict("user"))

        let plantsAny = dict.array("plants")
        self.plants = try plantsAny.map { any in
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
        bag = try bagAny.compactMap { any in
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
        isHanging = dict.int("isHanging")
        plantLevel = dict.int("plantLevel")
        platLevelExp = dict.int("platLevelExp")
        position = dict.string("position")
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

//
//  ItemData.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import Foundation

// MARK: - Item Data Model (dùng chung cho Plant, Pot, Decoration)

struct ItemData: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let image: String
    let priceStore: Int
    let priceOxygen: Int
    let currencyUnit: String
    let type: String // "plant", "pot", "decoration", "music", "overlay"
    let effect: String
    let itemTypeAttribute: ItemTypeAttribute
    let levelUnlock: Int

    // MARK: - Cấu hình âm thanh khi tap
    let sound: String?
    let tapSound: String?

    var clickSound: String {
        if let s = sound, !s.trimmingCharacters(in: .whitespaces).isEmpty {
            return s.trimmingCharacters(in: .whitespaces)
        }
        if let ts = tapSound, !ts.trimmingCharacters(in: .whitespaces).isEmpty {
            return ts.trimmingCharacters(in: .whitespaces)
        }
        return "tap"
    }

    // MARK: - Cấu hình động SpriteKit từ file JSON (loại bỏ switch-case thủ công)
    let kind: String?            // "fallingLeaves", "fireflies", "weather", etc.
    let sksFile: String?         // Tên file .sks ("Fireflies.sks", "Rain.sks", "PlantScene.sks", v.v.)
    let images: [String]?        // Danh sách 1 -> 6 ảnh cho overlay/effect
    let wind: String?            // "none", "gentleLeft", "gentleRight", "breezeLeft", "breezeRight", "variable"
    let density: String?         // "low", "medium", "high"
    let speed: String?           // "slow", "normal", "fast"
    let particleCount: Int?      // Số lượng hạt (ví dụ: đom đóm = 26)
    let skyGradient: [String]?   // Mảng mã màu hex bầu trời ["#6BAFCF", "#C7E6FA", "#EBF5FC"]
    let elements: [String]?      // Thành phần bầu trời: ["sun", "clouds", "rain", "moon_crescent", "stars", "shooting_stars"]

    // MARK: - Cấu hình độ rộng chậu cây (0.0 -> 1.0)
    let widthFill: Double?
}

// MARK: - Item Type Attribute (Hỗ trợ đa thuộc tính: "none", "hanging", "front", "hanging,front", v.v.)

public struct ItemTypeAttribute: RawRepresentable, Codable, Hashable, Equatable, ExpressibleByStringLiteral, CustomStringConvertible {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.rawValue = "none"
        } else {
            let str = try container.decode(String.self)
            self.rawValue = str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String {
        return rawValue
    }

    /// Tập hợp các thuộc tính thành phần (phân tách bởi dấu phẩy, chữ thường, bỏ khoảng trắng)
    public var flags: Set<String> {
        let items = rawValue
            .lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(items)
    }

    /// Cây hoặc chậu dạng treo ("hanging")
    public var isHanging: Bool {
        return flags.contains("hanging")
    }

    /// Cây có cành lá/dây leo nằm TRƯỚC mặt chậu ("front")
    public var isInFront: Bool {
        return flags.contains("front")
    }

    /// Không có cờ đặc biệt (mặc định để bàn, thân sau chậu)
    public var isNone: Bool {
        return flags.contains("none") || flags.isEmpty || (!isHanging && !isInFront)
    }

    /// Kiểm tra xem có chứa thuộc tính cụ thể hay không (ví dụ: .contains("hanging"))
    public func contains(_ flag: String) -> Bool {
        return flags.contains(flag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Kiểm tra xem có khớp/tương thích với thuộc tính khác hay không
    public func matches(_ other: ItemTypeAttribute) -> Bool {
        if other.isNone { return self.isNone }
        if other.isHanging && !self.isHanging { return false }
        if other.isInFront && !self.isInFront { return false }
        return true
    }

    // MARK: - Equatable & Hashable theo tập flags chuẩn hóa

    public static func == (lhs: ItemTypeAttribute, rhs: ItemTypeAttribute) -> Bool {
        if lhs.isNone && rhs.isNone { return true }
        return lhs.flags == rhs.flags
    }

    public func hash(into hasher: inout Hasher) {
        if isNone {
            hasher.combine("none")
        } else {
            hasher.combine(flags)
        }
    }

    // MARK: - Constants tĩnh tiện dụng

    public static let none: ItemTypeAttribute = ItemTypeAttribute(rawValue: "none")
    public static let hanging: ItemTypeAttribute = ItemTypeAttribute(rawValue: "hanging")
    public static let front: ItemTypeAttribute = ItemTypeAttribute(rawValue: "front")
    public static let hangingFront: ItemTypeAttribute = ItemTypeAttribute(rawValue: "hanging,front")
}

// MARK: - Item Data Manager

class ItemDataManager {
    static let shared = ItemDataManager()

    private var allPlants: [ItemData] = []
    private var allPots: [ItemData] = []
    private var allDecorations: [ItemData] = []
    private var allEffects: [ItemData] = []
    private var allShopItems: [ItemData] = []
    private var allLandscapes: [ItemData] = []
    private var allMusics: [ItemData] = []
    private var allMusicsSFX: [ItemData] = []

    private init() {
        loadItems()
    }

    /// Load tất cả items từ JSON files
    private func loadItems() {
        allPlants = loadItemsFromFile(named: "plants_data",)
        allPots = loadItemsFromFile(named: "pots_data",)
        allDecorations = loadItemsFromFile(named: "stickers_data",)
        allEffects = loadItemsFromFile(named: "effects_data",)
        allShopItems = loadItemsFromFile(named: "shop_items_data",)
        allLandscapes = loadItemsFromFile(named: "landscapes_data",)
        allMusics = loadItemsFromFile(named: "music_data",)
        allMusicsSFX = loadItemsFromFile(named: "music_sfx_data",)

        print("✅ Đã load \(allPlants.count) plants, \(allPots.count) pots, \(allDecorations.count) stickers, \(allEffects.count) effects, \(allShopItems.count) shop items, \(allLandscapes.count) landscapes")
    }

    /// Helper function để load items từ file
    private func loadItemsFromFile(named fileName: String, folder: String? = nil) -> [ItemData] {
        var url: URL?

        if let folder = folder {
            url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: folder)
        } else {
            url = Bundle.main.url(forResource: fileName, withExtension: "json")
        }

        guard let url = url else {
            print("❌ Không tìm thấy file \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([ItemData].self, from: data)
            return items
        } catch {
            print("❌ Lỗi khi decode \(fileName): \(error)")
            return []
        }
    }

    // MARK: - Get All Items

    func getAllPlants() -> [ItemData] {
        return allPlants
    }

    func getAllPots() -> [ItemData] {
        return allPots
    }

    func getAllDecorations() -> [ItemData] {
        return allDecorations
    }

    func getAllEffects() -> [ItemData] {
        return allEffects
    }

    func getEffect(byIdOrImage idOrImage: String) -> ItemData? {
        return allEffects.first { $0.id == idOrImage || $0.image == idOrImage }
    }

    func getAllShopItems() -> [ItemData] {
        return allShopItems
    }

    func getAllLandscapes() -> [ItemData] {
        return allLandscapes
    }

    func getLandscape(byIdOrImage idOrImage: String) -> ItemData? {
        return allLandscapes.first {
            $0.id == idOrImage ||
            $0.image == idOrImage ||
            $0.image == "i_\(idOrImage)" ||
            idOrImage == "i_\($0.image)" ||
            (idOrImage == "sky_sun_day" && $0.id == "landscape1")
        }
    }

    func getAllMusics() -> [ItemData] {
        return allMusics
    }

    func getAllMusicsSFX() -> [ItemData] {
        return allMusicsSFX
    }

    // MARK: - Get Item by ID

    func getItem(byId id: String) -> ItemData? {
        return (allPlants + allPots + allDecorations + allEffects + allShopItems + allLandscapes + allMusics + allMusicsSFX).first { $0.id == id }
    }

    func getPlant(byId id: String) -> ItemData? {
        return allPlants.first { $0.id == id }
    }

    func getPot(byId id: String) -> ItemData? {
        return allPots.first { $0.id == id }
    }

    // MARK: - Filter by Level

    func getPlants(forLevel level: Int) -> [ItemData] {
        return allPlants.filter { $0.levelUnlock <= level }
    }

    func getPots(forLevel level: Int) -> [ItemData] {
        return allPots.filter { $0.levelUnlock <= level }
    }

    // MARK: - Filter by Attribute

    func getPlants(byAttribute attribute: ItemTypeAttribute) -> [ItemData] {
        return allPlants.filter { $0.itemTypeAttribute.matches(attribute) }
    }

    func getPots(byAttribute attribute: ItemTypeAttribute) -> [ItemData] {
        return allPots.filter { $0.itemTypeAttribute.matches(attribute) }
    }

    // MARK: - Filter by Currency

    func getPlants(byCurrency currency: String) -> [ItemData] {
        return allPlants.filter { $0.currencyUnit == currency }
    }

    func getPots(byCurrency currency: String) -> [ItemData] {
        return allPots.filter { $0.currencyUnit == currency }
    }

    func getDecorations(byCurrency currency: String) -> [ItemData] {
        return allDecorations.filter { $0.currencyUnit == currency }
    }

    func getMusics(byCurrency currency: String) -> [ItemData] {
        return allMusics.filter { $0.currencyUnit == currency }
    }

    func getMusicsSFX(byCurrency currency: String) -> [ItemData] {
        return allMusicsSFX.filter { $0.currencyUnit == currency }
    }

    // MARK: - Search

    func searchPlants(keyword: String) -> [ItemData] {
        guard !keyword.isEmpty else { return allPlants }
        return allPlants.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
                $0.description.localizedCaseInsensitiveContains(keyword)
        }
    }

    func searchPots(keyword: String) -> [ItemData] {
        guard !keyword.isEmpty else { return allPots }
        return allPots.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
                $0.description.localizedCaseInsensitiveContains(keyword)
        }
    }

    func searchDecorations(keyword: String) -> [ItemData] {
        guard !keyword.isEmpty else { return allDecorations }
        return allDecorations.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
                $0.description.localizedCaseInsensitiveContains(keyword)
        }
    }
}

// MARK: - Backward Compatibility (alias cho code cũ)

typealias PlantItemData = ItemData
typealias PlantDataManager = ItemDataManager

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
    let effect: String // ID(s) hiệu ứng overlay (phân tách bởi dấu phẩy, ví dụ: "overlay1", "overlay1,overlay2")
    let effectDescription: String? // Mô tả hiệu ứng (ví dụ: "Lá rơi xanh ngọc")
    let itemTypeAttribute: ItemTypeAttribute
    let levelUnlock: Int

    // MARK: - Cấu hình âm thanh khi tap
    let sound: String? // Âm thanh click vào (mặc định "tap", chỉ áp dụng với plant)
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

    // MARK: - Mở khóa Âm nhạc, Phong cảnh, SFX khi trồng cây/chậu
    let music: String? // ID(s) âm nhạc mở khóa ("m0,m1")
    let musicDescription: String? // Mô tả nhạc mở khóa ("Relax")
    let effectLandscape: String? // ID(s) phong cảnh mở khóa ("landscape1,landscape2")
    let effectLandscapeDescription: String? // Mô tả phong cảnh ("Ban công quang đãng")
    let effectSfx: String? // ID(s) âm thanh sfx mở khóa ("sfx1,sfx5")
    let effectSfxDescription: String? // Mô tả sfx ("Tiếng nước chảy")

    // MARK: - Helper trích xuất danh sách ID mở khóa
    var unlockedMusicIds: [String] {
        guard let music = music else { return [] }
        return music.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "none" && $0 != "N.A" }
    }

    var unlockedEffectIds: [String] {
        return effect.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "none" && $0 != "N.A" }
    }

    var unlockedLandscapeIds: [String] {
        guard let landscapes = effectLandscape else { return [] }
        return landscapes.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "none" && $0 != "N.A" }
    }

    var unlockedSfxIds: [String] {
        guard let sfx = effectSfx else { return [] }
        return sfx.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "none" && $0 != "N.A" }
    }

    /// Mô tả tổng hợp hiệu ứng để hiển thị trên UI Store & Selection cards
    var displayEffect: String {
        var parts: [String] = []
        if let ed = effectDescription, !ed.isEmpty && ed != "N.A" && ed != "none" {
            parts.append(ed)
        }
        if let md = musicDescription, !md.isEmpty && md != "N.A" && md != "none" {
            parts.append("Nhạc: \(md)")
        }
        if let ld = effectLandscapeDescription, !ld.isEmpty && ld != "N.A" && ld != "none" {
            parts.append("Cảnh: \(ld)")
        }
        if let sd = effectSfxDescription, !sd.isEmpty && sd != "N.A" && sd != "none" {
            parts.append("SFX: \(sd)")
        }
        if !parts.isEmpty {
            return parts.joined(separator: ", ")
        }
        if effect != "none" && effect != "N.A" && !effect.isEmpty {
            return effect
        }
        return "N.A"
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

    // MARK: - Codable Custom Keys & Fallback
    enum CodingKeys: String, CodingKey {
        case id, name, description, image, priceStore, priceOxygen, currencyUnit, type, effect
        case effectDescription, effectdescription
        case itemTypeAttribute, levelUnlock
        case sound, tapSound
        case music, musicDescription, musicdescription
        case effectLandscape, effectlandscape, effectLancape, effectlancape
        case effectLandscapeDescription, effectlandscapedescription, effectLancapedescription
        case effectSfx, effectsfx
        case effectSfxDescription, effectsfxdescription, effectsfxdesdescription
        case kind, sksFile, images, wind, density, speed, particleCount, skyGradient, elements, widthFill
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        image = try container.decode(String.self, forKey: .image)
        priceStore = try container.decode(Int.self, forKey: .priceStore)
        priceOxygen = try container.decode(Int.self, forKey: .priceOxygen)
        currencyUnit = try container.decode(String.self, forKey: .currencyUnit)
        type = try container.decode(String.self, forKey: .type)
        effect = (try? container.decode(String.self, forKey: .effect)) ?? ""

        effectDescription = (try? container.decode(String.self, forKey: .effectDescription))
            ?? (try? container.decode(String.self, forKey: .effectdescription))

        itemTypeAttribute = (try? container.decode(ItemTypeAttribute.self, forKey: .itemTypeAttribute)) ?? .none
        levelUnlock = try container.decode(Int.self, forKey: .levelUnlock)

        sound = try? container.decode(String.self, forKey: .sound)
        tapSound = try? container.decode(String.self, forKey: .tapSound)

        music = try? container.decode(String.self, forKey: .music)
        musicDescription = (try? container.decode(String.self, forKey: .musicDescription))
            ?? (try? container.decode(String.self, forKey: .musicdescription))

        effectLandscape = (try? container.decode(String.self, forKey: .effectLandscape))
            ?? (try? container.decode(String.self, forKey: .effectlandscape))
            ?? (try? container.decode(String.self, forKey: .effectLancape))
            ?? (try? container.decode(String.self, forKey: .effectlancape))

        effectLandscapeDescription = (try? container.decode(String.self, forKey: .effectLandscapeDescription))
            ?? (try? container.decode(String.self, forKey: .effectlandscapedescription))
            ?? (try? container.decode(String.self, forKey: .effectLancapedescription))

        effectSfx = (try? container.decode(String.self, forKey: .effectSfx))
            ?? (try? container.decode(String.self, forKey: .effectsfx))

        effectSfxDescription = (try? container.decode(String.self, forKey: .effectSfxDescription))
            ?? (try? container.decode(String.self, forKey: .effectsfxdescription))
            ?? (try? container.decode(String.self, forKey: .effectsfxdesdescription))

        kind = try? container.decode(String.self, forKey: .kind)
        sksFile = try? container.decode(String.self, forKey: .sksFile)
        images = try? container.decode([String].self, forKey: .images)
        wind = try? container.decode(String.self, forKey: .wind)
        density = try? container.decode(String.self, forKey: .density)
        speed = try? container.decode(String.self, forKey: .speed)
        particleCount = try? container.decode(Int.self, forKey: .particleCount)
        skyGradient = try? container.decode([String].self, forKey: .skyGradient)
        elements = try? container.decode([String].self, forKey: .elements)
        widthFill = try? container.decode(Double.self, forKey: .widthFill)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(image, forKey: .image)
        try container.encode(priceStore, forKey: .priceStore)
        try container.encode(priceOxygen, forKey: .priceOxygen)
        try container.encode(currencyUnit, forKey: .currencyUnit)
        try container.encode(type, forKey: .type)
        try container.encode(effect, forKey: .effect)
        try container.encodeIfPresent(effectDescription, forKey: .effectDescription)
        try container.encode(itemTypeAttribute, forKey: .itemTypeAttribute)
        try container.encode(levelUnlock, forKey: .levelUnlock)
        try container.encodeIfPresent(sound, forKey: .sound)
        try container.encodeIfPresent(tapSound, forKey: .tapSound)
        try container.encodeIfPresent(music, forKey: .music)
        try container.encodeIfPresent(musicDescription, forKey: .musicDescription)
        try container.encodeIfPresent(effectLandscape, forKey: .effectLandscape)
        try container.encodeIfPresent(effectLandscapeDescription, forKey: .effectLandscapeDescription)
        try container.encodeIfPresent(effectSfx, forKey: .effectSfx)
        try container.encodeIfPresent(effectSfxDescription, forKey: .effectSfxDescription)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(sksFile, forKey: .sksFile)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(wind, forKey: .wind)
        try container.encodeIfPresent(density, forKey: .density)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(particleCount, forKey: .particleCount)
        try container.encodeIfPresent(skyGradient, forKey: .skyGradient)
        try container.encodeIfPresent(elements, forKey: .elements)
        try container.encodeIfPresent(widthFill, forKey: .widthFill)
    }
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

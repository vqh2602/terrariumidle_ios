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
    let type: String // "plant", "pot", "decoration"
    let effect: String
    let itemTypeAttribute: ItemTypeAttribute
    let levelUnlock: Int
}

// MARK: - Item Type Attribute

enum ItemTypeAttribute: String, Codable {
    case none
    case hanging
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

    private init() {
        loadItems()
    }

    /// Load tất cả items từ JSON files
    private func loadItems() {
        allPlants = loadItemsFromFile(named: "plants_data", folder: "Items")
        allPots = loadItemsFromFile(named: "pots_data", folder: "Items")
        allDecorations = loadItemsFromFile(named: "stickers_data", folder: "Items")
        allEffects = loadItemsFromFile(named: "effects_data", folder: "Items")
        allShopItems = loadItemsFromFile(named: "shop_items_data", folder: "Items")
        allLandscapes = loadItemsFromFile(named: "landscapes_data", folder: "Items")

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

    func getAllShopItems() -> [ItemData] {
        return allShopItems
    }

    func getAllLandscapes() -> [ItemData] {
        return allLandscapes
    }

    // MARK: - Get Item by ID

    func getItem(byId id: String) -> ItemData? {
        return (allPlants + allPots + allDecorations + allEffects + allShopItems + allLandscapes).first { $0.id == id }
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
        return allPlants.filter { $0.itemTypeAttribute == attribute }
    }

    func getPots(byAttribute attribute: ItemTypeAttribute) -> [ItemData] {
        return allPots.filter { $0.itemTypeAttribute == attribute }
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

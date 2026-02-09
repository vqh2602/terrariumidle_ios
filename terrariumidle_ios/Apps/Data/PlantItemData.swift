//
//  PlantItemData.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import Foundation

// MARK: - Plant Item Data Model

struct PlantItemData: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let image: String
    let priceStore: Int
    let priceOxygen: Int
    let currencyUnit: String
    let type: String
    let effect: String
    let itemTypeAttribute: ItemTypeAttribute
    let levelUnlock: Int
}

// MARK: - Item Type Attribute

enum ItemTypeAttribute: String, Codable {
    case none
    case hanging
}

// MARK: - Plant Data Manager

class PlantDataManager {
    static let shared = PlantDataManager()

    private var allPlants: [PlantItemData] = []

    private init() {
        loadPlants()
    }

    /// Load plants từ JSON file
    private func loadPlants() {
        guard let url = Bundle.main.url(forResource: "plants_data", withExtension: "json") else {
            print("❌ Không tìm thấy file plants_data.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            allPlants = try JSONDecoder().decode([PlantItemData].self, from: data)
            print("✅ Đã load \(allPlants.count) plants")
        } catch {
            print("❌ Lỗi khi decode plants: \(error)")
        }
    }

    /// Lấy tất cả plants
    func getAllPlants() -> [PlantItemData] {
        return allPlants
    }

    /// Lấy plant theo ID
    func getPlant(byId id: String) -> PlantItemData? {
        return allPlants.first { $0.id == id }
    }

    /// Lấy plants theo level unlock
    func getPlants(forLevel level: Int) -> [PlantItemData] {
        return allPlants.filter { $0.levelUnlock <= level }
    }

    /// Lấy plants theo type attribute (hanging/none)
    func getPlants(byAttribute attribute: ItemTypeAttribute) -> [PlantItemData] {
        return allPlants.filter { $0.itemTypeAttribute == attribute }
    }

    /// Lấy plants theo currency unit
    func getPlants(byCurrency currency: String) -> [PlantItemData] {
        return allPlants.filter { $0.currencyUnit == currency }
    }

    /// Search plants theo tên
    func searchPlants(keyword: String) -> [PlantItemData] {
        guard !keyword.isEmpty else { return allPlants }
        return allPlants.filter {
            $0.name.localizedCaseInsensitiveContains(keyword) ||
                $0.description.localizedCaseInsensitiveContains(keyword)
        }
    }
}

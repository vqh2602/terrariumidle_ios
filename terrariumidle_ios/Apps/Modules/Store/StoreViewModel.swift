//
//  StoreViewModel.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import Combine
import FirebaseAuth
import Foundation

enum StoreTab: String, CaseIterable {
    case pots = "Chậu"
    case plants = "Cây"
    case decorations = "Trang trí"
    case animals = "Động vật"
    case gemstones = "Đá quý"
    case tools = "Dụng cụ"
}

@MainActor
final class StoreViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTab: StoreTab = .plants
    @Published var isLoading = false
    @Published var hasError = false
    @Published var errorMessage: String?
    @Published var availableItems: [ItemData] = []
    @Published var searchText: String = ""

    // MARK: - Dependencies

    private let auth: AuthService
    private let fireStore: FireStoreService
    private let itemManager = ItemDataManager.shared

    // MARK: - Computed Properties

    var filteredItems: [ItemData] {
        guard let gardenModel = fireStore.gradenModel else {
            print("Không có data gradenModel trong StoreViewModel")
            return []
        }

        var items = availableItems

        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.tr.localizedCaseInsensitiveContains(searchText) ||
                    item.description.tr.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by level unlock
//        items = items.filter { $0.levelUnlock <= gardenModel.user.userLevel }

        // Filter by ownership (exclude items already owned)
        let ownedIds = getOwnedIds(for: selectedTab, from: gardenModel)
        items = items.filter { !ownedIds.contains($0.id) }

        return items
    }

    // MARK: - Init

    init(auth: AuthService) {
        self.auth = auth
        fireStore = FireStoreService.shared
        Task {
            await fireStore.getDataById(userId: auth.currentUser?.uid ?? "")
        }
    }

    // MARK: - Public Methods

    func loadItems(for tab: StoreTab) {
        selectedTab = tab

        switch tab {
        case .pots:
            availableItems = itemManager.getAllPots()
        case .plants:
            availableItems = itemManager.getAllPlants()
        case .decorations:
            availableItems = itemManager.getAllDecorations()
        case .animals:
            availableItems = itemManager.getAllAnimals()
        case .gemstones:
            // TODO: Load gemstone packages
            availableItems = []
        case .tools:
            availableItems = itemManager.getAllShopItems()
        }
    }

    func canAfford(item: ItemData, quantity: Int = 1) -> Bool {
        guard let money = fireStore.gradenModel?.money,
              let totalPrice = item.totalStorePrice(quantity: quantity) else { return false }

        switch item.currencyUnit {
        case "oxygen":
            return money.oxygen >= totalPrice
        case "gemstone":
            return money.gemstone >= totalPrice
        case "ticket":
            return money.ticket >= totalPrice
        default:
            return false
        }
    }

    func meetsLevelRequirement(item: ItemData) -> Bool {
        guard let userLevel = fireStore.gradenModel?.user.userLevel else { return false }
        return userLevel >= item.levelUnlock
    }

    func isOwned(item: ItemData) -> Bool {
        guard let gardenModel = fireStore.gradenModel else { return false }
        let ownedIds = getOwnedIds(for: selectedTab, from: gardenModel)
        return ownedIds.contains(item.id)
    }

    func purchaseItem(_ item: ItemData, quantity: Int = 1) async {
        guard !isLoading else { return }
        guard var updatedModel = fireStore.gradenModel else {
            showError("Không thể tải thông tin người dùng".tr)
            return
        }
        guard let totalPrice = item.totalStorePrice(quantity: quantity),
              item.supportsPurchaseQuantity || quantity == 1 else {
            showError("Số lượng không hợp lệ".tr)
            return
        }
        guard meetsLevelRequirement(item: item) else {
            showError("Mở khóa ở cấp %d".tr(item.levelUnlock))
            return
        }
        guard canAfford(item: item, quantity: quantity) else {
            showError("Không đủ tiền để mua".tr)
            return
        }

        // Apply the reward before charging; reject invalid or overflowing amounts.
        if item.supportsPurchaseQuantity {
            guard let reward = item.shopReward(quantity: quantity) else {
                showError("Số lượng không hợp lệ".tr)
                return
            }
            let addition: (partialValue: Int, overflow: Bool)
            switch reward.kind {
            case "item1":
                addition = updatedModel.item.fertilizer.addingReportingOverflow(reward.amount)
                updatedModel.item.fertilizer = addition.partialValue
            case "item2":
                addition = updatedModel.item.shovel.addingReportingOverflow(reward.amount)
                updatedModel.item.shovel = addition.partialValue
            case "item3":
                addition = updatedModel.money.oxygen.addingReportingOverflow(reward.amount)
                updatedModel.money.oxygen = addition.partialValue
            default: // item4: user levels
                addition = updatedModel.user.userLevel.addingReportingOverflow(reward.amount)
                updatedModel.user.userLevel = addition.partialValue
            }
            guard !addition.overflow else {
                showError("Số lượng không hợp lệ".tr)
                return
            }
        } else {
            var plants = updatedModel.cart.cartPlants
            var pots = updatedModel.cart.cartPots
            var stickers = updatedModel.cart.cartStickers
            var animals = updatedModel.cart.cartAnimals
            switch item.type {
            case "plant":
                guard !plants.contains(item.id) else { return }
                plants.append(item.id)
            case "pot":
                guard !pots.contains(item.id) else { return }
                pots.append(item.id)
            case "sticker", "decoration":
                guard !stickers.contains(item.id) else { return }
                stickers.append(item.id)
            case "animal":
                guard !animals.contains(item.id) else { return }
                animals.append(item.id)
            default:
                showError("Không thể mua vật phẩm này".tr)
                return
            }
            updatedModel.cart = GardenModel.Cart(
                cartPlants: plants, cartPots: pots, cartStickers: stickers, cartAnimals: animals
            )
        }

        switch item.currencyUnit {
        case "oxygen": updatedModel.money.oxygen -= totalPrice
        case "gemstone": updatedModel.money.gemstone -= totalPrice
        case "ticket": updatedModel.money.ticket -= totalPrice
        default: return
        }

        isLoading = true
        hasError = false
        errorMessage = nil
        defer { isLoading = false }

        guard await fireStore.updateDataUser(gardenModel: updatedModel) != nil else {
            showError("Không thể hoàn tất mua hàng. Vui lòng thử lại.".tr)
            return
        }
        loadItems(for: selectedTab)
    }

    private func showError(_ message: String) {
        errorMessage = message
        hasError = true
    }

    // MARK: - Private Methods

    private func getOwnedIds(for tab: StoreTab, from gardenModel: GardenModel) -> [String] {
        switch tab {
        case .plants:
            return gardenModel.cart.cartPlants
        case .pots:
            return gardenModel.cart.cartPots
        case .decorations:
            return gardenModel.cart.cartStickers
        case .animals:
            return gardenModel.cart.cartAnimals
        case .tools, .gemstones:
            return []
        }
    }
}

// Existing shop IDs encode the quantity in each pack. Quantity means number of packs.
extension ItemData {
    var supportsPurchaseQuantity: Bool {
        type == "item" && shopReward(quantity: 1) != nil
    }

    func totalStorePrice(quantity: Int) -> Int? {
        guard quantity > 0, priceStore >= 0 else { return nil }
        let total = priceStore.multipliedReportingOverflow(by: quantity)
        return total.overflow ? nil : total.partialValue
    }

    func shopReward(quantity: Int) -> (kind: String, amount: Int)? {
        guard type == "item", quantity > 0 else { return nil }
        let parts = id.split(separator: "_")
        guard let kind = parts.first.map(String.init) else { return nil }
        let perPack: Int
        if kind == "item4", parts.count == 1 {
            perPack = 1
        } else {
            guard parts.count == 2, let size = Int(parts[1]), size > 0 else { return nil }
            switch kind {
            case "item1", "item2": perPack = size
            case "item3":
                // Convert gemstones to oxygen at the catalog's 5.5 rate.
                let converted = size.multipliedReportingOverflow(by: 11)
                guard !converted.overflow, converted.partialValue.isMultiple(of: 2) else { return nil }
                perPack = converted.partialValue / 2
            default: return nil
            }
        }
        let amount = perPack.multipliedReportingOverflow(by: quantity)
        guard !amount.overflow else { return nil }
        return (kind, amount.partialValue)
    }

    func shopRewardDescription(quantity: Int) -> String? {
        guard let reward = shopReward(quantity: quantity) else { return nil }
        switch reward.kind {
        case "item1": return "Phân bón: %@".tr(reward.amount.formatted())
        case "item2": return "Xẻng: %@".tr(reward.amount.formatted())
        case "item3": return "Oxygen: %@".tr(reward.amount.formatted())
        default: return "Tăng %@ cấp".tr(reward.amount.formatted())
        }
    }
}

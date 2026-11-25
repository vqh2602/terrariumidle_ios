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
        case .gemstones:
            // TODO: Load gemstone packages
            availableItems = []
        case .tools:
            availableItems = itemManager.getAllShopItems()
        }
    }

    func canAfford(item: ItemData) -> Bool {
        guard let money = fireStore.gradenModel?.money else { return false }

        switch item.currencyUnit {
        case "oxygen":
            return money.oxygen >= item.priceStore
        case "gemstone":
            return money.gemstone >= item.priceStore
        case "ticket":
            return money.ticket >= item.priceStore
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

    func purchaseItem(_ item: ItemData) async {
        guard let gardenModel = fireStore.gradenModel else {
            errorMessage = "Không thể tải thông tin người dùng".tr
            hasError = true
            return
        }

        // Check if can afford
        guard canAfford(item: item) else {
            errorMessage = "Không đủ tiền để mua".tr
            hasError = true
            return
        }

        isLoading = true
        hasError = false
        errorMessage = nil

        do {
            // Create updated money
            var newMoney = gardenModel.money
            switch item.currencyUnit {
            case "oxygen":
                newMoney = GardenModel.Money(
                    gemstone: gardenModel.money.gemstone,
                    oxygen: gardenModel.money.oxygen - item.priceStore,
                    ticket: gardenModel.money.ticket
                )
            case "gemstone":
                newMoney = GardenModel.Money(
                    gemstone: gardenModel.money.gemstone - item.priceStore,
                    oxygen: gardenModel.money.oxygen,
                    ticket: gardenModel.money.ticket
                )
            case "ticket":
                newMoney = GardenModel.Money(
                    gemstone: gardenModel.money.gemstone,
                    oxygen: gardenModel.money.oxygen,
                    ticket: gardenModel.money.ticket - item.priceStore
                )
            default:
                break
            }

            // Create updated cart
            var newCart = gardenModel.cart
            switch selectedTab {
            case .plants:
                var plants = gardenModel.cart.cartPlants
                plants.append(item.id)
                newCart = GardenModel.Cart(
                    cartPlants: plants,
                    cartPots: gardenModel.cart.cartPots,
                    cartStickers: gardenModel.cart.cartStickers
                )
            case .pots:
                var pots = gardenModel.cart.cartPots
                pots.append(item.id)
                newCart = GardenModel.Cart(
                    cartPlants: gardenModel.cart.cartPlants,
                    cartPots: pots,
                    cartStickers: gardenModel.cart.cartStickers
                )
            case .decorations:
                var stickers = gardenModel.cart.cartStickers
                stickers.append(item.id)
                newCart = GardenModel.Cart(
                    cartPlants: gardenModel.cart.cartPlants,
                    cartPots: gardenModel.cart.cartPots,
                    cartStickers: stickers
                )
            case .tools:
                // Tools don't go to cart, they update item counts
                break
            case .gemstones:
                // Gemstones update money directly
                break
            }

            // Create updated garden model
            let updatedModel = GardenModel(
                isBan: gardenModel.isBan,
                isServerUpdate: gardenModel.isServerUpdate,
                item: gardenModel.item,
                cart: newCart,
                money: newMoney,
                user: gardenModel.user,
                plants: gardenModel.plants
            )

            // Update Firestore
            _ = await fireStore.updateDataUser(gardenModel: updatedModel)

            // Reload items to reflect purchase
            loadItems(for: selectedTab)

            isLoading = false
        }
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
        case .tools, .gemstones:
            return []
        }
    }
}

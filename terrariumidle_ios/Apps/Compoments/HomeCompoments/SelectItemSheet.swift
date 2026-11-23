//
//  SelectItemSheet.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

enum SelectionTab: String, CaseIterable {
    case pot = "Chọn chậu"
    case plant = "Chọn cây"
    case decoration = "Trang trí"
}

enum SelectionMode {
    case plantCombo // Requires plant + pot
    case decorationOnly // Standalone decoration
}

struct SelectItemSheet: View {
    @Binding var isPresented: Bool

    let cartPlants: [String]
    let cartPots: [String]
    let cartStickers: [String]
    let rowIndex: Int
    let columnIndex: Int
    var onOpenStore: (String) -> Void = { _ in }

    @State private var selectedTab: SelectionTab = .plant
    @State private var selectedPlantId: String? = nil
    @State private var selectedPotId: String? = nil
    @State private var selectedDecorationId: String? = nil

    @StateObject private var fireStore = FireStoreService.shared

    var selectionMode: SelectionMode {
        selectedTab == .decoration ? .decorationOnly : .plantCombo
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Selection Preview

                if selectedPlantId != nil || selectedPotId != nil || selectedDecorationId != nil {
                    VStack(spacing: 8) {
                        if let plantId = selectedPlantId,
                           let plant = ItemDataManager.shared.getPlant(byId: plantId)
                        {
                            SelectedItemPreview(
                                item: plant,
                                type: "Cây",
                                onRemove: { selectedPlantId = nil }
                            )
                            .padding(.horizontal)
                        }

                        if let potId = selectedPotId,
                           let pot = ItemDataManager.shared.getPot(byId: potId)
                        {
                            SelectedItemPreview(
                                item: pot,
                                type: "Chậu",
                                onRemove: { selectedPotId = nil }
                            )
                            .padding(.horizontal)
                        }

                        if let decorationId = selectedDecorationId,
                           let decoration = ItemDataManager.shared.getItem(byId: decorationId)
                        {
                            SelectedItemPreview(
                                item: decoration,
                                type: "Trang trí",
                                onRemove: { selectedDecorationId = nil }
                            )
                            .padding(.horizontal)
                        }

                        // Type mismatch warning
                        if !areTypesCompatible {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Cây và chậu phải cùng loại (cả 2 treo hoặc cả 2 không treo)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)

                    Divider()
                        .padding(.vertical, 8)
                }

                // MARK: - Tab Selector

                Picker("Loại vật phẩm", selection: $selectedTab) {
                    Text("Chậu").tag(SelectionTab.pot)
                    Text("Cây").tag(SelectionTab.plant)
                    Text("Trang trí").tag(SelectionTab.decoration)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if let item = unownedRecommendation {
                    unownedItemRecommendation(item)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                } else if selectedTab == .plant, let pot = recommendedPot, selectedPotId != pot.id {
                    GardenInventoryRow(item: pot, isSelected: false, onSelect: {
                        selectedPotId = pot.id
                        selectedTab = .pot
                    }, recommendationText: "Chậu phù hợp nhất với cây đã chọn")
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                } else if selectedTab == .pot, let plant = recommendedPlant, selectedPlantId != plant.id {
                    GardenInventoryRow(item: plant, isSelected: false, onSelect: {
                        selectedPlantId = plant.id
                        selectedTab = .plant
                    }, recommendationText: "Cây phù hợp nhất với chậu đã chọn")
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

                // MARK: - Content

                Group {
                    switch selectedTab {
                    case .pot:
                        PotSelectionView(
                            cartPots: cartPots,
                            onSelect: { potId in
                                print("Selected pot: \(potId)")
                            },
                            selectedPotId: $selectedPotId,
                            recommendedPotId: recommendedPot?.id
                        )
                    case .plant:
                        PlantSelectionView(
                            cartPlants: cartPlants,
                            rowIndex: rowIndex,
                            columnIndex: columnIndex,
                            onSelect: { plantId in
                                print("Selected plant: \(plantId)")
                            },
                            selectedPlantId: $selectedPlantId,
                            recommendedPlantId: recommendedPlant?.id
                        )
                    case .decoration:
                        DecorationSelectionView(
                            cartStickers: cartStickers,
                            onSelect: { decorationId in
                                print("Selected decoration: \(decorationId)")
                            },
                            selectedDecorationId: $selectedDecorationId
                        )
                    }
                }

                // MARK: - Build Button

                if canBuildSelection() {
                    Divider()

                    buildButton
                        .padding()
                }
            }
            .background {
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
            .tint(AccountStyle.green)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AccountStyle.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Chọn vật phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        isPresented = false
                    }
                    .fontWeight(.bold)
                }
            }
            .onChange(of: selectedTab) { oldTab, newTab in
//                print("Old:", oldValue)
//                print("New:", newValue)
                // Clear incompatible selections when switching modes
                if newTab == .decoration {
                    // Switching to decoration mode → clear plant/pot
                    selectedPlantId = nil
                    selectedPotId = nil
                } else {
                    // Switching to plant/pot mode → clear decoration
                    selectedDecorationId = nil
                }
            }
        }
    }

    // MARK: - Build Button

    private var buildButton: some View {
        let totalCost = calculateTotalCost()
        let currentOxygen = fireStore.gradenModel?.money.oxygen ?? 0
        let hasEnoughOxygen = currentOxygen >= totalCost

        return Button(action: {
            if hasEnoughOxygen {
                buildPlant()
            } else {
                // Close sheet when not enough oxygen
                isPresented = false
            }
        }) {
            HStack {
                if hasEnoughOxygen {
                    Image("oxygen")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(totalCost)")
                        .fontWeight(.bold)
                    Spacer()
                    Text(selectionMode == .plantCombo ? "Trồng cây" : "Đặt trang trí")
                        .fontWeight(.semibold)
                } else {
                    Text("Không đủ oxygen")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(AccountStyle.cream)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasEnoughOxygen ? AccountStyle.green : AccountStyle.danger)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Methods

    private var unownedRecommendation: ItemData? {
        guard selectedTab != .decoration else { return nil }
        let pot = recommendedPot.flatMap { cartPots.contains($0.id) ? nil : $0 }
        let plant = recommendedPlant.flatMap { cartPlants.contains($0.id) ? nil : $0 }
        return selectedTab == .pot ? (plant ?? pot) : (pot ?? plant)
    }

    private func unownedItemRecommendation(_ item: ItemData) -> some View {
        let isPlant = item.type == "plant"
        return VStack(alignment: .leading, spacing: 8) {
            Label(isPlant ? "Cây phù hợp nhất với chậu đã chọn" : "Chậu phù hợp nhất với cây đã chọn", systemImage: "sparkles")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.green)
            HStack(spacing: 10) {
                CachedAsyncImage(named: item.image) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: isPlant ? "leaf.fill" : "shippingbox.fill").foregroundStyle(AccountStyle.green)
                }
                .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                    Text(isPlant ? "Bạn chưa sở hữu cây này." : "Bạn chưa sở hữu chậu này.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                }
            }
            Button {
                onOpenStore(item.id)
                isPresented = false
            } label: {
                Label("Vào cửa hàng để mua", systemImage: "basket.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(AccountStyle.cream)
                    .background(AccountStyle.green, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(AccountStyle.border, lineWidth: 1) }
    }

    private var recommendedPot: ItemData? {
        guard let plantId = selectedPlantId,
              let plant = ItemDataManager.shared.getPlant(byId: plantId),
              let potId = matchingItemId(plantId, from: "plant", to: "pot"),
              let pot = ItemDataManager.shared.getPot(byId: potId),
              plant.itemTypeAttribute.isHanging == pot.itemTypeAttribute.isHanging
        else { return nil }
        return pot
    }

    private var recommendedPlant: ItemData? {
        guard let potId = selectedPotId,
              let pot = ItemDataManager.shared.getPot(byId: potId),
              let plantId = matchingItemId(potId, from: "pot", to: "plant"),
              let plant = ItemDataManager.shared.getPlant(byId: plantId),
              plant.itemTypeAttribute.isHanging == pot.itemTypeAttribute.isHanging
        else { return nil }
        return plant
    }

    private func matchingItemId(_ id: String, from prefix: String, to targetPrefix: String) -> String? {
        guard id.hasPrefix(prefix) else { return nil }
        let number = id.dropFirst(prefix.count)
        guard !number.isEmpty, number.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return targetPrefix + number
    }

    // Check if plant and pot types are compatible (both hanging or both non-hanging)
    private var areTypesCompatible: Bool {
        guard let plantId = selectedPlantId,
              let potId = selectedPotId,
              let plant = ItemDataManager.shared.getPlant(byId: plantId),
              let pot = ItemDataManager.shared.getPot(byId: potId)
        else {
            return true // No conflict if either is not selected
        }

        let plantIsHanging = plant.itemTypeAttribute.isHanging
        let potIsHanging = pot.itemTypeAttribute.isHanging

        return plantIsHanging == potIsHanging
    }

    private func canBuildSelection() -> Bool {
        switch selectionMode {
        case .plantCombo:
            return selectedPlantId != nil && selectedPotId != nil && areTypesCompatible
        case .decorationOnly:
            return selectedDecorationId != nil
        }
    }

    private func calculateTotalCost() -> Int {
        var total = 0

        if let plantId = selectedPlantId,
           let plant = ItemDataManager.shared.getPlant(byId: plantId)
        {
            total += plant.priceOxygen
        }

        if let potId = selectedPotId,
           let pot = ItemDataManager.shared.getPot(byId: potId)
        {
            total += pot.priceOxygen
        }

        if let decorationId = selectedDecorationId,
           let decoration = ItemDataManager.shared.getItem(byId: decorationId)
        {
            total += decoration.priceOxygen
        }

        return total
    }

    private func buildPlant() {
        guard let gardenModel = fireStore.gradenModel else {
            print("❌ No garden model available")
            isPresented = false
            return
        }

        let totalCost = calculateTotalCost()

        // Check oxygen balance
        guard gardenModel.money.oxygen >= totalCost else {
            print("❌ Not enough oxygen")
            isPresented = false
            return
        }

        // Deduct oxygen
        let newMoney = GardenModel.Money(
            gemstone: gardenModel.money.gemstone,
            oxygen: gardenModel.money.oxygen - totalCost,
            ticket: gardenModel.money.ticket
        )

        // Create new plant entry
        var newPlants = gardenModel.plants
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000) // milliseconds
        let position = "\(rowIndex),\(columnIndex)" // e.g. "1,2"

        if selectionMode == .plantCombo,
           let plantId = selectedPlantId,
           let plant = ItemDataManager.shared.getPlant(byId: plantId),
           let potId = selectedPotId
        {
            // Create plant with pot
            let isHanging = plant.itemTypeAttribute.isHanging

            let newPlant = GardenModel.Plant(
                harvestTime: currentTime,
                idPlant: plantId,
                idPot: potId,
                isHanging: isHanging,
                plantLevel: 1,
                platLevelExp: 0,
                position: position
            )
            // Xoá bản ghi cũ tại cùng vị trí nếu có để tránh trùng lặp
            newPlants.removeAll { $0.position == position }
            newPlants.append(newPlant)
            print("✅ Created plant: \(plantId) with pot: \(potId) at position: \(position), hanging: \(isHanging)")

        } else if selectionMode == .decorationOnly,
                  let decorationId = selectedDecorationId
        {
            let isHanging = ItemDataManager.shared.getItem(byId: decorationId)?.itemTypeAttribute.isHanging ?? false
            // Create decoration (both idPlant and idPot set to sticker id)
            let newDecoration = GardenModel.Plant(
                harvestTime: currentTime,
                idPlant: decorationId,
                idPot: decorationId,
                isHanging: isHanging,
                plantLevel: 1,
                platLevelExp: 0,
                position: position
            )
            // Xoá bản ghi cũ tại cùng vị trí nếu có để tránh trùng lặp
            newPlants.removeAll { $0.position == position }
            newPlants.append(newDecoration)
            print("✅ Created decoration: \(decorationId) at position: \(position)")
        }

        // Create updated garden model
        let updatedModel = GardenModel(
            isBan: gardenModel.isBan,
            isServerUpdate: gardenModel.isServerUpdate,
            item: gardenModel.item,
            cart: gardenModel.cart,
            money: newMoney,
            user: gardenModel.user,
            plants: newPlants
        )

        // Update Firestore asynchronously
        fireStore.saveGarden(gardenModel: updatedModel, debounce: false)
        isPresented = false
    }
}

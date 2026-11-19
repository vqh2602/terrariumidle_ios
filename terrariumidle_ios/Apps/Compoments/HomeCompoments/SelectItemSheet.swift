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

    @State private var selectedTab: SelectionTab = .plant
    @State private var selectedPlantId: String? = nil
    @State private var selectedPotId: String? = nil
    @State private var selectedDecorationId: String? = nil

    @StateObject private var fireStore = FireStoreService.shared

    var selectionMode: SelectionMode {
        selectedTab == .decoration ? .decorationOnly : .plantCombo
    }

    var body: some View {
        NavigationView {
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

                HStack(spacing: 12) {
                    ForEach(SelectionTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTab == tab ? Color.green : Color.gray.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Divider()
                    .padding(.vertical, 12)

                // MARK: - Content

                Group {
                    switch selectedTab {
                    case .pot:
                        PotSelectionView(
                            cartPots: cartPots,
                            onSelect: { potId in
                                print("Selected pot: \(potId)")
                            },
                            selectedPotId: $selectedPotId
                        )
                    case .plant:
                        PlantSelectionView(
                            cartPlants: cartPlants,
                            rowIndex: rowIndex,
                            columnIndex: columnIndex,
                            onSelect: { plantId in
                                print("Selected plant: \(plantId)")
                            },
                            selectedPlantId: $selectedPlantId
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
            .navigationTitle("Chọn vật phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        isPresented.toggle()
                    }
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
                    Text("Xây dựng")
                        .fontWeight(.semibold)
                } else {
                    Text("Không đủ oxygen")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasEnoughOxygen ? Color.green : Color.red)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Methods

    // Check if plant and pot types are compatible (both hanging or both non-hanging)
    private var areTypesCompatible: Bool {
        guard let plantId = selectedPlantId,
              let potId = selectedPotId,
              let plant = ItemDataManager.shared.getPlant(byId: plantId),
              let pot = ItemDataManager.shared.getPot(byId: potId)
        else {
            return true // No conflict if either is not selected
        }

        let plantIsHanging = plant.itemTypeAttribute == .hanging
        let potIsHanging = pot.itemTypeAttribute == .hanging

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
            let isHanging = plant.itemTypeAttribute == .hanging

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
            let isHanging = ItemDataManager.shared.getItem(byId: decorationId)?.itemTypeAttribute == .hanging
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

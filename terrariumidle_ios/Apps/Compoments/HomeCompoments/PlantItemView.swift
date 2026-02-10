//
//  PlantItemView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

import UniformTypeIdentifiers

/// Widget hiển thị plant/pot với logic cho hanging và normal layout
struct PlantItemView: View {
    let itemWidth: CGFloat
    let plantData: GardenModel.Plant?
    let rowIndex: Int
    let columnIndex: Int
    let cartPlants: [String]
    let cartPots: [String]
    let cartStickers: [String]
    @Binding var isEditing: Bool
    @Binding var draggedPlant: DraggedPlantData?
    let onDrop: (Int, Int) -> Void

    @State private var showSheet = false
    @State private var floatingTexts: [(id: UUID, text: String, offset: CGFloat)] = []
    @State var fireStoreService: FireStoreService = .shared

    var body: some View {
        // Kiểm tra xem có phải sticker không
        let isSticker = (plantData?.idPlant.contains("sticker") == true &&
            plantData?.idPlant == plantData?.idPot)

        // Kiểm tra xem cây có treo không (isHanging = 1)
        let isHanging = plantData?.isHanging ?? false

        // Nếu KHÔNG phải sticker, check xem có plantId hoặc potId trống không
        let hasEmptyIds = !isSticker && (
            plantData?.idPlant.isEmpty == true ||
                plantData?.idPot.isEmpty == true ||
                plantData?.idPlant == nil ||
                plantData?.idPot == nil
        )

        Group {
            // MARK: - Layout Logic

            // nếu isedit = true thì hiện widget có icon thêm plant với những ô không có cây hay trang trí nào
            // Nếu không phải sticker và có ID trống → hiển thị widget trong suốt chiều cao 150
            if hasEmptyIds {
                if isEditing {
                    // Edit mode: Hiển thị nút thêm plant
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)

                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green.opacity(0.7))
                            Text("Thêm cây")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: itemWidth, height: 150).onTapGesture {
                        showSheet.toggle()
                    }
                } else {
                    // Normal mode: Completely hidden, no UI, no tap
                    EmptyView()
                }
            } else if isSticker {
                // STICKER LAYOUT
                if isHanging {
                    // Sticker treo - hiển thị như pot treo
                    ZStack(alignment: .top) {
                        PotRiveView(
                            width: itemWidth * 1.0,
                            height: itemWidth + itemWidth * 0.2, // Chiều cao pot treo
                            potId: plantData?.idPot ?? "pot15"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    // Sticker không treo - chiều cao 155
                    VStack(spacing: 0) {
                        PotRiveView(
                            width: itemWidth,
                            height: 155, // Fixed height cho sticker không treo
                            potId: plantData?.idPot ?? "pot1"
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            } else if isHanging {
                // HANGING PLANT LAYOUT - Cây treo
                // Pot ở trên, Plant phủ xuống dưới
                ZStack(alignment: .top) {
                    // Pot ở trên cùng (topCenter)
                    PotRiveView(
                        width: itemWidth * 1.0,
                        height: itemWidth + itemWidth * 0.2, // Fixed height cho pot treo
                        potId: plantData?.idPot ?? "pot15"
                    )
                    .frame(maxWidth: .infinity)

                    // Plant phủ xuống - full width
                    PlantRiveView(
                        width: itemWidth, // full width
                        height: itemWidth + itemWidth * 0.5, // Chiều cao như normal plant
                        plantId: plantData?.idPlant ?? "plant12",
                        plantLevel: plantData?.plantLevel ?? 3
                    )
                }
                .id("\(plantData?.idPlant ?? "")-\(plantData?.plantLevel ?? 1)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                // NORMAL PLANT LAYOUT
                VStack(spacing: 0) {
                    // Hiển thị Plant với idPlant từ data
                    PlantRiveView(
                        width: itemWidth,
                        height: itemWidth + itemWidth * 0.35,
                        plantId: plantData?.idPlant ?? "plant1",
                        plantLevel: plantData?.plantLevel ?? 1
                    )

                    // Hiển thị Pot với idPot từ data
                    PotRiveView(
                        width: itemWidth,
                        height: itemWidth * 0.6,
                        potId: plantData?.idPot ?? "pot1"
                    )
                }
                .id("\(plantData?.idPlant ?? "")-\(plantData?.plantLevel ?? 1)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .customContextMenu(menuItems: isSticker || isEditing ? [] : [
            MenuItem(title: "Tưới cây", icon: "drop.fill") {
                print("water at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Bón phân", icon: "leaf.fill") {
                print("fertilize at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Thu hoạch", icon: "basket.fill") {
                print("harvest at \(rowIndex),\(columnIndex)")
            },
            MenuItem(title: "Xóa", icon: "trash", role: .destructive) {
                print("remove at \(rowIndex),\(columnIndex)")
            },
        ]).sheet(isPresented: $showSheet) {
            SelectItemSheet(
                isPresented: $showSheet,
                cartPlants: cartPlants,
                cartPots: cartPots,
                cartStickers: cartStickers,
                rowIndex: rowIndex,
                columnIndex: columnIndex
            )
        }

        // MARK: - Tap to Collect (Non-Edit Mode Only)

        .onTapGesture {
            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
                handlePlantTap()
            }
        }

        // MARK: - Floating Text Overlay

        .overlay(
            ZStack {
                ForEach(floatingTexts, id: \.id) { item in
                    Text(item.text)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                        .offset(y: item.offset)
                        .opacity(item.offset == 0 ? 1 : 0)
                }
            }
        )

        // MARK: - Drag and Drop (Edit Mode Only - Conditionally Applied)

        .modifier(DragDropModifier(
            isEditing: isEditing,
            plantData: plantData,
            hasEmptyIds: hasEmptyIds,
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            draggedPlant: $draggedPlant,
            onDrop: onDrop
        ))

        // MARK: - Visual Feedback

        .overlay(
            // Blue overlay on source plant being dragged
            draggedPlant?.sourceRow == rowIndex &&
                draggedPlant?.sourceColumn == columnIndex ?
                Color.blue.opacity(0.3).cornerRadius(12) : nil
        )
        .overlay(
            // Green border on potential drop zones (when dragging)
            isEditing && draggedPlant != nil &&
                !(draggedPlant?.sourceRow == rowIndex && draggedPlant?.sourceColumn == columnIndex) ?
                RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.6), lineWidth: 3)
                : nil
        )
    }

    // MARK: - Tap Mechanics Helper Functions

    /// Handle plant tap with probability-based oxygen drop
    private func handlePlantTap() {
        guard let plant = plantData,
              var gardenModel = fireStoreService.gradenModel else { return }

        let level = plant.plantLevel

        // Get drop rate and oxygen amount based on level
        let (dropChance, oxygenDrop) = getDropRate(level: level)

        // Random check
        if Double.random(in: 0 ... 1) <= dropChance {
            // SUCCESS: Drop oxygen
            var updatedMoney = gardenModel.money
            updatedMoney.oxygen += oxygenDrop

            // Update plant in plants array
            var updatedPlants = gardenModel.plants
            guard let plantIndex = updatedPlants.firstIndex(where: {
                $0.position == "\(rowIndex),\(columnIndex)"
            }) else { return }

            var updatedPlant = updatedPlants[plantIndex]
            updatedPlant.platLevelExp += 100

            // Check plant level up (max level 3)
            if level < 3 {
                let maxExp = calculatePlantMaxExp(level: level)
                if updatedPlant.platLevelExp >= maxExp {
                    updatedPlant.plantLevel += 1
                    updatedPlant.platLevelExp -= maxExp
                    showFloatingText("🌟 Plant Level \(updatedPlant.plantLevel)!")
                }
            }

            updatedPlants[plantIndex] = updatedPlant

            // Add EXP to user
            var updatedUser = gardenModel.user
            updatedUser.userLevelEXP += 100

            // Check user level up
            let userMaxExp = calculateUserMaxExp(level: updatedUser.userLevel)
            if updatedUser.userLevelEXP >= userMaxExp {
                updatedUser.userLevel += 1
                updatedUser.userLevelEXP -= userMaxExp
                showFloatingText("⭐ Level \(updatedUser.userLevel)!")
            }

            // Update model
            gardenModel.money = updatedMoney
            gardenModel.plants = updatedPlants
            gardenModel.user = updatedUser

            // Show oxygen collected
            showFloatingText("+\(oxygenDrop) 💨")

            // Save to Firestore
            Task {
                _ = await fireStoreService.updateDataUser(gardenModel: gardenModel)
            }
        }
    }

    /// Get drop rate and oxygen amount based on plant level
    private func getDropRate(level: Int) -> (chance: Double, oxygen: Int) {
        switch level {
        case 1: return (0.60, 5) // 60% chance, 5 oxygen
        case 2: return (0.70, 10) // 70% chance, 10 oxygen
        case 3: return (0.95, 20) // 95% chance, 20 oxygen
        default: return (0.0, 0)
        }
    }

    /// Calculate max EXP needed for plant level up
    /// Formula: (3000 * level) * 0.95
    private func calculatePlantMaxExp(level: Int) -> Int {
        return Int(Double(3000 * level) * 0.95)
    }

    /// Calculate max EXP needed for user level up
    /// Formula: (1000 * level) * 0.75
    private func calculateUserMaxExp(level: Int) -> Int {
        return Int(Double(1000 * level) * 0.75)
    }

    /// Show floating text animation
    private func showFloatingText(_ text: String) {
        let id = UUID()
        floatingTexts.append((id: id, text: text, offset: 0))

        withAnimation(.easeOut(duration: 1.5)) {
            if let index = floatingTexts.firstIndex(where: { $0.id == id }) {
                floatingTexts[index].offset = -50
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            floatingTexts.removeAll { $0.id == id }
        }
    }
}

// MARK: - Conditional Drag Drop Modifier

struct DragDropModifier: ViewModifier {
    let isEditing: Bool
    let plantData: GardenModel.Plant?
    let hasEmptyIds: Bool
    let rowIndex: Int
    let columnIndex: Int
    @Binding var draggedPlant: DraggedPlantData?
    let onDrop: (Int, Int) -> Void

    func body(content: Content) -> some View {
        if isEditing {
            // Apply onDrop to ALL slots (empty or not) in edit mode
            let droppableContent = content
                .onDrop(of: [.text], isTargeted: nil) { _, _ in
                    if draggedPlant != nil {
                        onDrop(rowIndex, columnIndex)
                        draggedPlant = nil
                        return true
                    }
                    return false
                }

            // Apply onDrag ONLY to slots with plants
            if plantData != nil && !hasEmptyIds {
                droppableContent
                    .onDrag {
                        if let plant = plantData {
                            draggedPlant = DraggedPlantData(
                                sourceRow: rowIndex,
                                sourceColumn: columnIndex,
                                plant: plant
                            )
                            return NSItemProvider(object: "\(rowIndex),\(columnIndex)" as NSString)
                        }
                        return NSItemProvider()
                    }
            } else {
                droppableContent
            }
        } else {
            content
        }
    }
}

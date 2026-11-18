//
//  PlantItemView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

// [RIVE_DEPRECATED] Loại bỏ Rive 100%, chuyển hoàn toàn sang SpriteKit
// @_spi(RiveExperimental) import RiveRuntime
import SpriteKit
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

    // Confirmation alerts
    @State private var showFertilizeAlert = false
    @State private var showRemoveAlert = false
    
    @State private var animationPressed = false

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
                            .background(Color.white.opacity(0.1))
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
                        /* [RIVE_DEPRECATED] Không dùng Rive nữa, thay bằng SpriteKitPotView
                        PotRiveView(
                            width: itemWidth * 1.0,
                            height: itemWidth + itemWidth * 0.2, // Chiều cao pot treo
                            potId: plantData?.idPot ?? "pot15"
                        )
                        .frame(maxWidth: .infinity)
                        */
                        SpriteKitPotView(
                            potId: plantData?.idPot ?? "pot15",
                            isHanging: true,
                            width: itemWidth * 1.0,
                            height: itemWidth + itemWidth * 0.2
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    // Sticker không treo - chiều cao 155
                    VStack(spacing: 0) {
                        /* [RIVE_DEPRECATED] Không dùng Rive nữa, thay bằng SpriteKitPotView
                        PotRiveView(
                            width: itemWidth,
                            height: 155, // Fixed height cho sticker không treo
                            potId: plantData?.idPot ?? "pot1"
                        )
                        */
                        SpriteKitPotView(
                            potId: plantData?.idPot ?? "pot1",
                            isHanging: false,
                            width: itemWidth,
                            height: 155
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            } else if isHanging {
                // HANGING PLANT LAYOUT - Cây treo
                // Pot ở trên, Plant phủ xuống dưới
                ZStack(alignment: .top) {
                    // Pot ở trên cùng (topCenter)
                    SpriteKitPotView(
                        potId: plantData?.idPot ?? "pot1",
                        isHanging: true,
                        width: itemWidth * 1.0,
                        height: itemWidth + itemWidth * 0.2,
                        onTap: {
                            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
                                handlePlantTap()
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)

                    // Plant phủ xuống - full width
                    SpriteKitPlantView(
                        plantId: plantData?.idPlant ?? "plant1",
                        plantLevel: plantData?.plantLevel ?? 3,
                        isHanging: true,
                        width: itemWidth,
                        height: itemWidth + itemWidth * 0.5,
                        onTap: {
                            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
                                handlePlantTap()
                            }
                        }
                    )
                }
                .id("\(plantData?.idPlant ?? "")-\(plantData?.plantLevel ?? 1)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                // NORMAL PLANT LAYOUT
                VStack(spacing: 0) {
                    // Hiển thị Plant với idPlant từ data (không dùng mockup, cây chưa có sẽ hiện <update app để hiển thị>)
                    SpriteKitPlantView(
                        plantId: plantData?.idPlant ?? "plant1",
                        plantLevel: plantData?.plantLevel ?? 1,
                        isHanging: false,
                        width: itemWidth,
                        height: itemWidth + itemWidth * 0.35,
                        onTap: {
                            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
                                handlePlantTap()
                            }
                        }
                    )

                    // Hiển thị Pot với idPot từ data
                    SpriteKitPotView(
                        potId: plantData?.idPot ?? "pot1",
                        isHanging: false,
                        width: itemWidth,
                        height: itemWidth * 0.6,
                        onTap: {
                            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
                                handlePlantTap()
                            }
                        }
                    )
                }
                .id("\(plantData?.idPlant ?? "")-\(plantData?.plantLevel ?? 1)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
            .customContextMenu(menuItems: {
                        if isEditing { return [] }
                        var items: [MenuItem] = []
                        if !isSticker {
                            items.append(MenuItem(title: "Bón phân", icon: "leaf.fill") {
                                showFertilizeAlert = true
                            })
                        }
                        items.append(MenuItem(title: "Loại bỏ", icon: "trash", role: .destructive) {
                            showRemoveAlert = true
                        })
                        return items
                    }())
        .sheet(isPresented: $showSheet) {
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
        .scaleEffect(animationPressed ? 0.94 : 1.0, anchor: .center)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: animationPressed)
        .onTapGesture {
            // Trigger zoom effect
            animationPressed = true
            if !isEditing && plantData != nil && !hasEmptyIds && !isSticker {
            
                handlePlantTap()
               
            }
            AudioPlayer.shared.playTap()
            // Reset zoom after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationPressed = false
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

        // bản chất là bọc thêm conten chính 1 lớp view nữa
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

//        .overlay(
//            // Blue overlay on source plant being dragged
//            draggedPlant?.sourceRow == rowIndex &&
//                draggedPlant?.sourceColumn == columnIndex ?
//                Color.blue.opacity(0.3).cornerRadius(12) : nil
//        )
        .overlay(
            // Green border on potential drop zones (when dragging)
            isEditing && draggedPlant != nil &&
                !(draggedPlant?.sourceRow == rowIndex && draggedPlant?.sourceColumn == columnIndex) ?
                RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.6), lineWidth: 3)
                : nil
        )

        // MARK: - Confirmation Alerts

        .alert("Bón phân", isPresented: $showFertilizeAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xác nhận") {
                handleFertilize()
            }
        } message: {
            Text("Sử dụng 10 phân bón để nâng cấp cây lên 1 level?")
        }

        .alert("Loại bỏ cây", isPresented: $showRemoveAlert) {
            Button("Hủy", role: .cancel) {}
            Button("Xác nhận", role: .destructive) {
                handleRemovePlant()
            }
        } message: {
            Text("Sử dụng 1 xẻng để loại bỏ cây này?").textStyle(.bodyMedium)
        }
    }

    // MARK: - Tap Mechanics Helper Functions

    /// Handle plant tap with probability-based oxygen drop
    private func handlePlantTap() {
        guard let plant = plantData,
              var gardenModel = fireStoreService.gradenModel else { return }

        let level = plant.plantLevel

        // Get drop rate and oxygen amount based on level
        let (dropChance, oxygenDrop) = ShareFunc.getDropRate(level: level)

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
                let maxExp = ShareFunc.calculatePlantMaxExp(level: level)
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
            let userMaxExp = ShareFunc.calculateUserMaxExp(level: updatedUser.userLevel)
            if updatedUser.userLevelEXP >= userMaxExp {
                AudioPlayer.shared.playSFX(fileName: "level_up")
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

    // MARK: - Plant Action Functions

    /// Fertilize plant - costs 10 fertilizer, increases plant level by 1 (no limit)
    private func handleFertilize() {
        guard var gardenModel = fireStoreService.gradenModel else { return }

        // Check if user has enough fertilizer
        if gardenModel.item.fertilizer < 10 {
            showFloatingText("❌ Không đủ phân bón!")
            return
        }

        // Find the plant
        var updatedPlants = gardenModel.plants
        guard let plantIndex = updatedPlants.firstIndex(where: {
            $0.position == "\(rowIndex),\(columnIndex)"
        }) else { return }

        var updatedPlant = updatedPlants[plantIndex]

        // Increase plant level by 1 (no cap when using fertilizer)
        updatedPlant.plantLevel += 1
        updatedPlants[plantIndex] = updatedPlant

        // Deduct 10 fertilizer
        var updatedItem = gardenModel.item
        updatedItem.fertilizer -= 10

        // Update model
        gardenModel.plants = updatedPlants
        gardenModel.item = updatedItem

        // Show success message
        showFloatingText("🌟 Level \(updatedPlant.plantLevel)!")

        // Save to Firestore
        Task {
            _ = await fireStoreService.updateDataUser(gardenModel: gardenModel)
        }
    }

    /// Remove plant - costs 1 shovel, removes the plant
    private func handleRemovePlant() {
        guard var gardenModel = fireStoreService.gradenModel else { return }

        // Check if user has enough shovels
        if gardenModel.item.shovel < 1 {
            showFloatingText("❌ Không đủ xẻng!")
            return
        }

        // Remove the plant by setting its IDs to empty
        var updatedPlants = gardenModel.plants
        guard let plantIndex = updatedPlants.firstIndex(where: {
            $0.position == "\(rowIndex),\(columnIndex)"
        }) else { return }

        var updatedPlant = updatedPlants[plantIndex]
        updatedPlant.idPlant = ""
        updatedPlant.idPot = ""
        updatedPlant.plantLevel = 1
        updatedPlant.platLevelExp = 0
        updatedPlants[plantIndex] = updatedPlant

        // Deduct 1 shovel
        var updatedItem = gardenModel.item
        updatedItem.shovel -= 1

        // Update model
        gardenModel.plants = updatedPlants
        gardenModel.item = updatedItem

        // Show success message
        showFloatingText("✅ Đã loại bỏ cây!")

        // Save to Firestore
        Task {
            _ = await fireStoreService.updateDataUser(gardenModel: gardenModel)
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

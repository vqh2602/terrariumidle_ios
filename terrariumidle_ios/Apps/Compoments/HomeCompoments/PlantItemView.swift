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
    @State private var pendingStoreItemId: String?
    @EnvironmentObject private var router: AppRouter
    @State private var floatingTexts: [(id: UUID, text: String, offset: CGFloat)] = []
    @State var fireStoreService: FireStoreService = .shared

    // Confirmation alerts
    @State private var showFertilizeAlert = false
    @State private var showRemoveAlert = false
    
    private var isSticker: Bool {
        plantData?.idPlant.contains("sticker") == true && plantData?.idPlant == plantData?.idPot
    }

    private var isHanging: Bool {
        if isSticker {
            let stickerId = plantData?.idPot ?? plantData?.idPlant ?? ""
            if let item = ItemDataManager.shared.getItem(byId: stickerId) {
                return item.itemTypeAttribute.isHanging
            }
        }
        return plantData?.isHanging ?? false
    }

    /// Chiều cao cố định chuẩn cho một tầng kệ, giúp tất cả các ô trên kệ đồng nhất
    /// và cho phép chậu treo dính sát đỉnh trên cùng của kệ
    private var slotHeight: CGFloat {
        itemWidth * 1.95
    }

    private var hasEmptyIds: Bool {
        !isSticker && (
            plantData?.idPlant.isEmpty == true ||
            plantData?.idPot.isEmpty == true ||
            plantData?.idPlant == nil ||
            plantData?.idPot == nil
        )
    }

    private func handleDetailTap() {
        guard !isEditing && plantData != nil && !hasEmptyIds && !isSticker else { return }
        handlePlantTap()
    }

    var body: some View {

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
                    .frame(width: itemWidth, height: slotHeight).onTapGesture {
                        showSheet.toggle()
                    }
                } else {
                    // Normal mode: Completely hidden, no UI, no tap
                    EmptyView()
                }
            } else if isSticker {
                // STICKER LAYOUT - FULL KHUNG CHUẨN NHƯ CÂY VÀ CHẬU (width: itemWidth, height: slotHeight)
                // - Sử dụng trọn vẹn toàn bộ ô kệ (slotHeight), loại bỏ hoàn toàn việc cắt xén hiệu ứng và vùng căn chỉnh
                // - Sticker treo bám sát đỉnh kệ (alignment: .top), sticker để bàn neo đáy kệ (alignment: .bottom)
                // - Hiệu ứng thị giác (mặt trời, tia nắng, sao, hào quang, tiền vàng, tàn lửa) tỏa sáng tự do toàn khung ô
                let stickerId = plantData?.idPot ?? plantData?.idPlant ?? "sticker1"
                if StickerAvailability.isAvailable(stickerId: stickerId) {
                    SpriteKitStickerView(
                        stickerId: stickerId,
                        isHanging: isHanging,
                        width: itemWidth,
                        height: slotHeight,
                        onTap: {
                            handleDetailTap()
                        }
                    )
                    .id("\(stickerId)-\(isHanging)-\(itemWidth)-\(slotHeight)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isHanging ? .top : .bottom)
                } else {
                    SpriteKitPotView(
                        potId: stickerId,
                        isHanging: isHanging,
                        width: itemWidth,
                        height: slotHeight,
                        onTap: {
                            handleDetailTap()
                        }
                    )
                    .id("\(stickerId)-\(isHanging)-\(itemWidth)-\(slotHeight)")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isHanging ? .top : .bottom)
                }
            } else {
                // UNIFIED PLANT & POT LAYOUT (TerrariumSlotView)
                // Hợp nhất Cây và Chậu vào chung 1 Scene SpriteKit:
                // - Đan xen chiều sâu: lá rủ ra trước thành chậu, dây treo trước vắt qua lá
                // - Chậu treo tự động định vị lòng chậu qua plantMount socket
                // - Giảm 50% Metal SKView trên màn hình chính
                TerrariumSlotView(
                    potId: plantData?.idPot ?? "pot1",
                    plantId: plantData?.idPlant ?? "plant1",
                    plantLevel: plantData?.plantLevel ?? 1,
                    isHanging: isHanging,
                    width: itemWidth,
                    height: slotHeight,
                    onTap: {
                        handleDetailTap()
                    }
                )
                .id("\(plantData?.idPlant ?? "")-\(plantData?.idPot ?? "")-\(plantData?.plantLevel ?? 1)-\(isHanging)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isHanging ? .top : .bottom)
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
        .sheet(isPresented: $showSheet, onDismiss: {
            if let itemId = pendingStoreItemId {
                pendingStoreItemId = nil
                router.push(.storeItem(itemId: itemId))
            }
        }) {
            SelectItemSheet(
                isPresented: $showSheet,
                cartPlants: cartPlants,
                cartPots: cartPots,
                cartStickers: cartStickers,
                rowIndex: rowIndex,
                columnIndex: columnIndex,
                onOpenStore: { pendingStoreItemId = $0 }
            )
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
            .allowsHitTesting(false)
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

        .overlay(
            // Green border on potential drop zones (when dragging)
            (isEditing && draggedPlant != nil &&
                !(draggedPlant?.sourceRow == rowIndex && draggedPlant?.sourceColumn == columnIndex) ?
                RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.6), lineWidth: 3)
                : nil)
                .allowsHitTesting(false)
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
            let targetPos = "\(rowIndex),\(columnIndex)"
            guard let plantIndex = updatedPlants.lastIndex(where: {
                $0.position == targetPos && !$0.idPlant.isEmpty
            }) ?? updatedPlants.firstIndex(where: { $0.position == targetPos }) else { return }

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

            // Xoá mọi bản ghi trùng tại toạ độ này và cập nhật lại bằng bản ghi mới nhất
            updatedPlants.removeAll { $0.position == targetPos }
            updatedPlants.append(updatedPlant)

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

            // Save to Firestore asynchronously with debouncing (gom các lần tap lại thành 1 lần ghi Firestore ở background)
            fireStoreService.saveGarden(gardenModel: gardenModel, debounce: true)
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
        let targetPos = "\(rowIndex),\(columnIndex)"
        guard let plantIndex = updatedPlants.lastIndex(where: {
            $0.position == targetPos && !$0.idPlant.isEmpty
        }) ?? updatedPlants.firstIndex(where: { $0.position == targetPos }) else { return }

        var updatedPlant = updatedPlants[plantIndex]

        // Increase plant level by 1 (no cap when using fertilizer)
        updatedPlant.plantLevel += 1
        // Xoá mọi bản ghi trùng tại toạ độ này và cập nhật lại bằng bản ghi mới nhất
        updatedPlants.removeAll { $0.position == targetPos }
        updatedPlants.append(updatedPlant)

        // Deduct 10 fertilizer
        var updatedItem = gardenModel.item
        updatedItem.fertilizer -= 10

        // Update model
        gardenModel.plants = updatedPlants
        gardenModel.item = updatedItem

        // Show success message
        showFloatingText("🌟 Level \(updatedPlant.plantLevel)!")

        // Save to Firestore asynchronously
        fireStoreService.saveGarden(gardenModel: gardenModel, debounce: false)
    }

    /// Remove plant - costs 1 shovel, removes the plant
    private func handleRemovePlant() {
        guard var gardenModel = fireStoreService.gradenModel else { return }

        // Check if user has enough shovels
        if gardenModel.item.shovel < 1 {
            showFloatingText("❌ Không đủ xẻng!")
            return
        }

        // Remove the plant by removing it from the array
        var updatedPlants = gardenModel.plants
        updatedPlants.removeAll { $0.position == "\(rowIndex),\(columnIndex)" }

        // Deduct 1 shovel
        var updatedItem = gardenModel.item
        updatedItem.shovel -= 1

        // Update model
        gardenModel.plants = updatedPlants
        gardenModel.item = updatedItem

        // Show success message
        showFloatingText("✅ Đã loại bỏ cây!")

        // Save to Firestore asynchronously
        fireStoreService.saveGarden(gardenModel: gardenModel, debounce: false)
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

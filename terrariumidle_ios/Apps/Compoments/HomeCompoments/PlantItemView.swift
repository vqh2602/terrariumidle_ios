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
    var weatherUntil: TimeInterval = 0
    var weatherTapTrigger: Int = 0
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
    @State private var autoTapTrigger = 0
    @State private var careAnimation: PlantCareAnimationRequest?
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var router: AppRouter
    @State private var floatingTexts: [(id: UUID, text: String, offset: CGFloat)] = []
    private let fireStoreService: FireStoreService = .shared

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
        if let plantId = plantData?.idPlant, let plant = ItemDataManager.shared.getPlant(byId: plantId) {
            if plant.itemTypeAttribute.isHanging { return true }
        }
        if let potId = plantData?.idPot, let pot = ItemDataManager.shared.getPot(byId: potId) {
            if pot.itemTypeAttribute.isHanging { return true }
        }
        return plantData?.isHanging ?? false
    }

    private var wateringDeadline: TimeInterval {
        max(plantData?.wateringUntil ?? 0, weatherUntil)
    }

    /// Fixed shelf height keeps standing and hanging sockets aligned.
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

    private func handleDetailTap(isAutomatic: Bool = false) {
        guard !isEditing && careAnimation == nil && plantData != nil && !hasEmptyIds && !isSticker else { return }
        handlePlantTap(playsSound: !isAutomatic)
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
                    },
                    autoTapTrigger: autoTapTrigger,
                    weatherTapTrigger: weatherTapTrigger,
                    onAutoTap: { handleDetailTap(isAutomatic: true) },
                    careAnimation: careAnimation,
                    onCareAnimationCompleted: finishCareAnimation
                )
                .id("\(plantData?.idPlant ?? "")-\(plantData?.idPot ?? "")-\(plantData?.plantLevel ?? 1)-\(isHanging)")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isHanging ? .top : .bottom)
            }
        }
            .customContextMenu(menuItems: {
                        if isEditing || careAnimation != nil || hasEmptyIds { return [] }
                        var items: [MenuItem] = []
                        if !isSticker {
                            if !hasEmptyIds {
                                items.append(MenuItem(title: "Tưới cây", assetIcon: "water-can",
                                                      subtitle: "10 diamond · Tự tap 60 giây") {
                                    handleWaterPlant()
                                })
                            }
                            items.append(MenuItem(title: "Bón phân", assetIcon: "fertilizer",
                                                  subtitle: "10 phân bón · Tăng 1 cấp") {
                                showFertilizeAlert = true
                            })
                        }
                        items.append(MenuItem(title: "Loại bỏ", assetIcon: "shovel",
                                              subtitle: "1 xẻng · Xúc cây khỏi kệ", role: .destructive) {
                            showRemoveAlert = true
                        })
                        return items
                    }())
        .task(id: "\(plantData?.wateringUntil ?? 0)-\(weatherUntil)-\(scenePhase)-\(isEditing)") {
            await runWateringAutoTap()
        }
        .task(id: careAnimation?.id) {
            guard let request = careAnimation else { return }
            // Scene rebuilds or pauses can interrupt SKActions and their completion.
            // Finish the model update even when SpriteKit cannot report completion.
            do {
                try await Task.sleep(for: .seconds(PlantCareAnimation.duration + 0.2))
            } catch {
                return
            }
            finishCareAnimation(request.id)
        }
        .overlay(alignment: .top) {
            if !isSticker, !hasEmptyIds, wateringDeadline > Date().timeIntervalSince1970 {
                let end = wateringDeadline
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = max(0, Int(ceil(end - context.date.timeIntervalSince1970)))
                    if seconds > 0 {
                        Label("Tự tap · \(seconds)s", systemImage: "drop.fill")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(.regularMaterial, in: Capsule())
                    }
                }
                .allowsHitTesting(false)
            }
        }
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

    /// Handle plant tap with probability-based oxygen drop (Atomic & Race-free)
    private func handlePlantTap(playsSound: Bool = true) {
        guard let displayedPlant = plantData else { return }

        guard let result = fireStoreService.recordPlantTap(
            at: "\(rowIndex),\(columnIndex)",
            plantId: displayedPlant.idPlant
        ) else { return }

        if result.didPlantLevelUp {
            showFloatingText("🌟 Plant Level \(result.newPlantLevel)!")
        }

        if result.didUserLevelUp {
            if playsSound {
                AudioPlayer.shared.playSFX(fileName: "level_up")
            }
            showFloatingText("⭐ Level \(result.newUserLevel)!")
        }

        showFloatingText("+\(result.oxygenGained) 💨")
    }

    /// Show floating text animation (giới hạn tối đa 4 nhãn cùng lúc để tránh quá tải view tree)
    private func showFloatingText(_ text: String) {
        if floatingTexts.count >= 4 {
            floatingTexts.removeFirst()
        }
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

    private func handleWaterPlant(animate: Bool = true) {
        guard careAnimation == nil, !isEditing, !isSticker, !hasEmptyIds,
              let plant = plantData,
              var garden = fireStoreService.gradenModel else { return }
        switch garden.waterPlant(at: "\(rowIndex),\(columnIndex)", plantId: plant.idPlant,
                                now: Date().timeIntervalSince1970) {
        case .watered:
            if animate {
                careAnimation = PlantCareAnimationRequest(action: .water)
            } else {
                fireStoreService.saveGarden(gardenModel: garden, debounce: false)
                showFloatingText("💧 Tự tap trong 60 giây!")
            }
        case .insufficientDiamonds:
            showFloatingText("❌ Không đủ 10 diamond!")
        case .alreadyWatering:
            showFloatingText("💧 Cây đang được tưới!")
        case .invalidPlant:
            break
        }
    }

    @MainActor
    private func runWateringAutoTap() async {
        guard let plant = plantData, !isSticker, !hasEmptyIds,
              scenePhase == .active, !isEditing else { return }
        let deadline = plant.wateringUntil
        while !Task.isCancelled, Date().timeIntervalSince1970 < deadline {
            // Read the latest model: never tap a replacement or use a stale level.
            guard let current = fireStoreService.gradenModel?.plants.last(where: {
                $0.position == "\(rowIndex),\(columnIndex)"
            }), current.idPlant == plant.idPlant, current.wateringUntil == deadline else { return }
            if scenePhase == .active && !isEditing && weatherUntil <= Date().timeIntervalSince1970 {
                autoTapTrigger += 1
            }
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
        }
    }

    /// Fertilize plant - costs 10 fertilizer, increases plant level by 1 (no limit)
    private func handleFertilize(animate: Bool = true) {
        guard careAnimation == nil, var gardenModel = fireStoreService.gradenModel else { return }

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
        if animate {
            careAnimation = PlantCareAnimationRequest(action: .fertilize)
            return
        }

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
        guard careAnimation == nil, let plant = plantData,
              let garden = fireStoreService.gradenModel,
              garden.plants.contains(where: {
                  $0.position == "\(rowIndex),\(columnIndex)" && $0.idPlant == plant.idPlant
              }) else { return }
        guard garden.item.shovel >= 1 else {
            showFloatingText("❌ Không đủ xẻng!")
            return
        }
        if isSticker {
            commitRemovePlant()
        } else {
            careAnimation = PlantCareAnimationRequest(action: .remove)
        }
    }

    private func finishCareAnimation(_ id: UUID) {
        guard let request = careAnimation, request.id == id else { return }
        careAnimation = nil
        switch request.action {
        case .water: handleWaterPlant(animate: false)
        case .fertilize: handleFertilize(animate: false)
        case .remove: commitRemovePlant()
        }
    }

    private func commitRemovePlant() {
        guard let plant = plantData,
              var gardenModel = fireStoreService.gradenModel,
              gardenModel.plants.contains(where: {
                  $0.position == "\(rowIndex),\(columnIndex)" &&
                  $0.idPlant == plant.idPlant && $0.harvestTime == plant.harvestTime
              }) else { return }

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

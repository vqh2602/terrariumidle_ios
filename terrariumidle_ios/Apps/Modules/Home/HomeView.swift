//
//  HomeView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

// [RIVE_DEPRECATED] Loại bỏ Rive 100%, chuyển hoàn toàn sang SpriteKit
// @_spi(RiveExperimental) import RiveRuntime
import SpriteKit
import SwiftUI

import Combine
import FirebaseAuth

// MARK: - Helper Struct for Position Parsing

/// Cấu trúc để lưu vị trí của cây (row, column)
struct PlantPosition {
    let row: Int
    let column: Int

    /// Parse từ string "row,column" (ví dụ: "12,1" -> row=12, column=1)
    init?(from positionString: String) {
        let components = positionString.split(separator: ",")
        guard components.count == 2,
              let r = Int(components[0]),
              let c = Int(components[1])
        else {
            return nil
        }
        row = r
        column = c
    }
}

// MARK: - Dragged Plant Data

struct DraggedPlantData: Equatable {
    static func == (lhs: DraggedPlantData, rhs: DraggedPlantData) -> Bool {
        return lhs.sourceRow == rhs.sourceRow &&
            lhs.sourceColumn == rhs.sourceColumn &&
            lhs.plant.position == rhs.plant.position
    }

    let sourceRow: Int
    let sourceColumn: Int
    let plant: GardenModel.Plant
}

struct HomeView: View {
    @State private var authService: AuthService = .shared
    @StateObject private var loginViewModel: LoginViewModel = .init(auth: AuthService.shared)
    @StateObject private var fireStoreService: FireStoreService = .shared
    @EnvironmentObject var router: AppRouter

    @State private var isEdit: Bool = false
    @State private var draggedPlant: DraggedPlantData? = nil
    @State var backgroundRive: String = "sky_sun_day"
    @State var overlayRive: String? = nil

    init() {
        print("play sound tap")
        //            AudioPlayer.shared.playBGM(fileName:"peacefulgarden" )
        BackgroundAudioManager.shared.switchBGM(id: "m0", fileName: "peacefulgarden", title: "Mặc định")
    }

    private func autoSelectOverlay() {
        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: fireStoreService.gradenModel)

        // Auto-select background landscape
        let unlockedLandscapes = ItemDataManager.shared.getAllLandscapes().filter {
            unlockedIds.contains($0.id)
        }
        if !unlockedLandscapes.isEmpty {
            backgroundRive = unlockedLandscapes.randomElement()?.image ?? "sky_sun_day"
        }

        // Auto-select overlay effect (sử dụng custom SpriteKit cho tất cả các overlay)
        let unlockedOverlays = ItemDataManager.shared.getAllEffects().filter {
            unlockedIds.contains($0.id)
        }
        if !unlockedOverlays.isEmpty {
            overlayRive = unlockedOverlays.randomElement()?.image
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MARK: - Layout plant

            GeometryReader { geometry in
                let itemWidth = (geometry.size.width - 32) / 3.0
                ZStack {
                    // [RIVE_DEPRECATED] Đã chuyển 100% sang SpriteKit, không dùng RiveViewModel nữa
                    /*
                    if Bundle.main.url(forResource: backgroundRive, withExtension: "riv") != nil {
                        RiveViewModel(
                            fileName: backgroundRive,
                            fit: .cover
                        ).view().id(backgroundRive)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    } else {
                        // Tự động load background SpriteKit động từ JSON
                        SpriteKitBackgroundView(backgroundId: backgroundRive)
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    }
                    */
                    // 100% SpriteKit Background
                    SpriteKitBackgroundView(backgroundId: backgroundRive)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)

                    HStack(spacing: 0) {
                        Image("r1").resizable()
                            .scaledToFill().frame(
                                width: 16, // 30% chiều rộng màn hình
                                height: geometry.size.height // 30% chiều rộng màn hình
                            )

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                let userFloors: Int = (fireStoreService.gradenModel?.user.userFloor) ?? 1

                                // MARK: - Unlock Floor Button (Edit Mode Only)

                                if isEdit && canUnlockFloor() {
                                    UnlockFloorButton(
                                        currentFloor: userFloors,
                                        cost: calculateUnlockCost(),
                                        maxFloors: maxUnlockableFloors(),
                                        onUnlock: handleUnlockFloor
                                    )
                                    .rotationEffect(.degrees(180))
                                    .padding(.vertical, 12)
                                }

                                // MARK: - Main Loop: Iterate through each floor/row

                                ForEach(0 ... userFloors, id: \.self) { rowIndex in
                                    VStack(spacing: 0) {
                                        HStack(spacing: 4) {
                                            // MARK: - Column Loop: 3 columns per row

                                            ForEach(1 ... 3, id: \.self) { columnIndex in
                                                // Lấy dữ liệu plant tại vị trí (rowIndex, columnIndex)
                                                let plantData = getPlantData(at: rowIndex, column: columnIndex, from: fireStoreService.gradenModel)

                                                // Check if slot is empty
                                                let isEmpty = plantData == nil ||
                                                    (plantData?.idPlant.isEmpty == true && plantData?.idPot.isEmpty == true)

                                                if isEmpty && !isEdit {
                                                    // Empty slot in non-edit mode: Spacer to maintain layout, no interaction
                                                    Color.clear
                                                        .frame(width: itemWidth, height: 150)
                                                        .allowsHitTesting(false)
                                                        .id("\(rowIndex)-\(columnIndex)")
                                                } else {
                                                    // Plant slot: Tương tác tap trực tiếp trên cây và chậu, không bọc TouchScaleMenu khung ngoài
                                                    PlantItemView(
                                                        itemWidth: itemWidth,
                                                        plantData: plantData,
                                                        rowIndex: rowIndex,
                                                        columnIndex: columnIndex,
                                                        cartPlants: fireStoreService.gradenModel?.cart.cartPlants ?? [],
                                                        cartPots: fireStoreService.gradenModel?.cart.cartPots ?? [],
                                                        cartStickers: fireStoreService.gradenModel?.cart.cartStickers ?? [],
                                                        isEditing: $isEdit,
                                                        draggedPlant: $draggedPlant,
                                                        onDrop: handleDrop
                                                    )
                                                    .id("\(rowIndex)-\(columnIndex)")
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)

                                        Image("r2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(
                                                width: geometry.size.width - 32,
                                                height: 16
                                            )
                                    }
                                    .rotationEffect(.degrees(180))
                                }
                            }
                        }
                        .rotationEffect(.degrees(180))
                        Image("r1").resizable()
                            .scaledToFill().frame(
                                width: 16, // 30% chiều rộng màn hình
                                height: geometry.size.height // 30% chiều rộng màn hình
                            ).scaleEffect(x: -1, y: 1) // 👈 lật ngang
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    //                    .background(AppColors.backgroundLogin)
                    OverlayEffectView(overlayId: overlayRive)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .ignoresSafeArea(.all)
                        .allowsHitTesting(false)

                }.frame(alignment: .leading)
            }.overlay(alignment: .top) {
                GeometryReader { geo in
                    UserInfoCompoment()
                        .padding(.top, geo.safeAreaInsets.top + 40)
                        .padding(.horizontal)
                }
            }

            .task {
                guard let userId = authService.currentUser?.uid else {
                    print("HomeView: chưa có userid")
                    return
                }
                _ = await fireStoreService.getDataById(userId: userId)
                fireStoreService.realtimeChangeDataGraden(userId: userId)
                
                // Auto-select random overlay if user has unlocked any
                autoSelectOverlay()
            }
          

            .navigationBarHidden(true) // Ẩn thanh navigation
            .ignoresSafeArea(.all)
            .onChange(of: isEdit) {oldValue, newValue in
                // Clear drag state when disabling edit mode
                if !newValue {
                    draggedPlant = nil
                }
            }

            SpeedDial(isEditing: $isEdit, backgroundRive: $backgroundRive, overlayRive: $overlayRive)
        } // Full màn hình, bao gồm status bar
    }

    // MARK: - Helper Function

    /// Hàm lấy dữ liệu plant tại vị trí cụ thể (row, column)
    /// - Parameters:
    ///   - row: Số hàng (ví dụ: 12)
    ///   - column: Số cột (1, 2, hoặc 3)
    ///   - gardenModel: Dữ liệu garden từ Firebase
    /// - Returns: Plant data hoặc nil nếu không tìm thấy
    private func getPlantData(at row: Int, column: Int, from gardenModel: GardenModel?) -> GardenModel.Plant? {
        guard let plants = gardenModel?.plants else { return nil }

        // Tìm plant có position khớp với row,column
        return plants.first { plant in
            // Parse position từ string "row,column"
            guard let position = PlantPosition(from: plant.position) else {
                return false
            }

            // So sánh row và column
            return position.row == row && position.column == column
        }
    }

    // MARK: - Drag and Drop Handler

    /// Handle drop event for drag-and-drop repositioning
    private func handleDrop(targetRow: Int, targetColumn: Int) {
        guard let dragged = draggedPlant,
              var gardenModel = fireStoreService.gradenModel
        else {
            draggedPlant = nil
            return
        }

        // Don't drop on same position
        if dragged.sourceRow == targetRow && dragged.sourceColumn == targetColumn {
            draggedPlant = nil
            return
        }

        var updatedPlants = gardenModel.plants

        // Find source plant index
        guard let sourceIndex = updatedPlants.firstIndex(where: {
            $0.position == "\(dragged.sourceRow),\(dragged.sourceColumn)"
        }) else {
            draggedPlant = nil
            return
        }

        // Check if target has a plant
        if let targetIndex = updatedPlants.firstIndex(where: {
            $0.position == "\(targetRow),\(targetColumn)"
        }) {
            // SWAP: Exchange positions
            var sourcePlant = updatedPlants[sourceIndex]
            var targetPlant = updatedPlants[targetIndex]

            sourcePlant.position = "\(targetRow),\(targetColumn)"
            targetPlant.position = "\(dragged.sourceRow),\(dragged.sourceColumn)"

            updatedPlants[sourceIndex] = targetPlant
            updatedPlants[targetIndex] = sourcePlant

            print("🔄 Swapped plants: [\(dragged.sourceRow),\(dragged.sourceColumn)] ↔ [\(targetRow),\(targetColumn)]")
        } else {
            // MOVE: Update position
            var sourcePlant = updatedPlants[sourceIndex]
            sourcePlant.position = "\(targetRow),\(targetColumn)"
            updatedPlants[sourceIndex] = sourcePlant

            print("📍 Moved plant: [\(dragged.sourceRow),\(dragged.sourceColumn)] → [\(targetRow),\(targetColumn)]")
        }

        // Update Firestore
        gardenModel.plants = updatedPlants

        // Clear drag state IMMEDIATELY to prevent ghost overlay
        draggedPlant = nil

        // Save asynchronously
        fireStoreService.saveGarden(gardenModel: gardenModel, debounce: false)
    }

    // MARK: - Floor Unlock Functions

    /// Calculate maximum unlockable floors based on user level
    /// Formula: userLevel / 5 (rounded down)
    private func maxUnlockableFloors() -> Int {
        let userLevel = fireStoreService.gradenModel?.user.userLevel ?? 1
        return userLevel / 5
    }

    /// Calculate cost to unlock next floor
    /// Formula: 2500 * current_floors + (userLevel / 100)
    private func calculateUnlockCost() -> Int {
        let userFloor = fireStoreService.gradenModel?.user.userFloor ?? 1
        let userLevel = fireStoreService.gradenModel?.user.userLevel ?? 1
        return 2500 * userFloor + (userLevel / 100)
    }

    /// Check if user can unlock another floor
    private func canUnlockFloor() -> Bool {
        guard let gardenModel = fireStoreService.gradenModel else { return false }
        let userFloor = gardenModel.user.userFloor
        let maxFloors = maxUnlockableFloors()
        return userFloor < maxFloors
    }

    /// Handle floor unlock purchase
    private func handleUnlockFloor() {
        guard var gardenModel = fireStoreService.gradenModel else { return }

        let cost = calculateUnlockCost()

        // Check oxygen
        guard gardenModel.money.oxygen >= cost else {
            print("❌ Not enough oxygen. Need: \(cost), Have: \(gardenModel.money.oxygen)")
            // TODO: Show error toast
            return
        }

        // Check max floors
        guard canUnlockFloor() else {
            print("❌ Already at max floors")
            // TODO: Show error toast
            return
        }

        // Deduct oxygen
        gardenModel.money.oxygen -= cost

        // Unlock floor
        gardenModel.user.userFloor += 1

        print("✅ Floor unlocked! New floor: \(gardenModel.user.userFloor), Oxygen spent: \(cost)")

        // Update Firestore asynchronously
        fireStoreService.saveGarden(gardenModel: gardenModel, debounce: false)
    }
}

// #Preview {
//    HomeView()
// }

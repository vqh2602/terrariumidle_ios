//
//  HomeView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

@_spi(RiveExperimental) import RiveRuntime
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

    init() {
        print("play sound tap")
        //            AudioPlayer.shared.playBGM(fileName:"peacefulgarden" )
        BackgroundAudioManager.shared.startBGM(fileName: "peacefulgarden", title: "Relax...")
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MARK: - Layout plant

            GeometryReader { geometry in
                let itemWidth = (geometry.size.width - 32) / 3.0
                ZStack {
                    RiveViewModel(
                        fileName: "sky_sun_day", // Sử dụng plantId làm fileName (ví dụ: "plant24", "sticker1")
                        //                    stateMachineName: isPlant ? "plant" : nil, // nil cho sticker/decoration
                        fit: .cover,

                    ).view().frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height) // Chiếm toàn bộ không gian

                    HStack(spacing: 0) {
                        Image("r1").resizable()
                            .scaledToFill().frame(
                                width: 16, // 30% chiều rộng màn hình
                                height: geometry.size.height // 30% chiều rộng màn hình
                            )

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                let userFloors: Int = (fireStoreService.gradenModel?.user.userFloor) ?? 1

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

                                                // Disable TouchScaleMenu in edit mode to allow drag gesture
                                                if isEdit {
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
                                                } else if isEmpty {
                                                    // Empty slot in non-edit mode: Spacer to maintain layout, no interaction
                                                    Color.clear
                                                        .frame(width: itemWidth, height: 150)
                                                        .allowsHitTesting(false)
                                                        .id("\(rowIndex)-\(columnIndex)")
                                                } else {
                                                    // Non-empty slot: Normal interaction
                                                    TouchScaleMenu {
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

                    //                RiveUIView(rive: {
                    //                    let worker = Worker()
                    //                    let file = try await File(source: .local("overlay1", Bundle.main), worker: worker)
                    //                    return try await Rive(file: file)
                    //                }).view()
                    //                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height) // Chiếm toàn bộ không gian
                    //                    .ignoresSafeArea(.all) // Full màn hình, bao gồm status bar
                    //                    .allowsHitTesting(false) // Chỉ hiển thị, không cho phép thao tác
                    //
                    //                    Button("lôgut") {
                    //                        loginViewModel.logout()
                    //                        router.replaceRoot(.loginView(id: ""))
                    //                    }

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
            }

            .navigationBarHidden(true) // Ẩn thanh navigation
            .ignoresSafeArea(.all)
            .onChange(of: isEdit) { newValue in
                // Clear drag state when disabling edit mode
                if !newValue {
                    draggedPlant = nil
                }
            }

            SpeedDial(isEditing: $isEdit)
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

        Task {
            _ = await fireStoreService.updateDataUser(gardenModel: gardenModel)
        }
    }
}

// #Preview {
//    HomeView()
// }

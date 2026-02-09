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

struct HomeView: View {
    @State private var authService: AuthService = .shared
    @StateObject private var loginViewModel: LoginViewModel = .init(auth: AuthService.shared)
    @StateObject private var fireStoreService: FireStoreService = .init(auth: AuthService.shared)
    @EnvironmentObject var router: AppRouter

    @State private var isEdit: Bool = false

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

                                                TouchScaleMenu {
                                                    PlantItemView(
                                                        itemWidth: itemWidth,
                                                        plantData: plantData,
                                                        rowIndex: rowIndex,
                                                        columnIndex: columnIndex,
                                                        isEditing: $isEdit
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
            }

            .navigationBarHidden(true) // Ẩn thanh navigation
            .ignoresSafeArea(.all)

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
}

// #Preview {
//    HomeView()
// }

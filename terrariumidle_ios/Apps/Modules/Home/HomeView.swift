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
import UniformTypeIdentifiers

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
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject var router: AppRouter

    @Environment(\.scenePhase) private var scenePhase
    @State private var weatherTapTrigger = 0
    @State private var dataReady = false
    @State private var backgroundReady = false
    @State private var loadFailed = false
    @State private var reloadID = 0
    @State private var shelfPosition = ScrollPosition(edge: .bottom)
    @State private var scrollDirection = 0
    @State private var topSafeInset: CGFloat = 0
    @State private var hudHeight: CGFloat = 56
    @State private var isEdit: Bool = false
    @State private var draggedPlant: DraggedPlantData? = nil
    @ObservedObject private var atmosphere = GardenAtmosphereManager.shared
    @StateObject private var beeCoordinator = GardenBeeSwarmCoordinator()
    @State private var pestToastMessage: String? = nil
    @State private var pestToastTask: Task<Void, Never>? = nil
    @State private var showPestAttackAlert: Bool = false
    @State private var pestAttackAlertMessage: String = ""
    @State private var lastHandledSprayDeadline: TimeInterval = 0

    init() {
        // BGM và landscape được khởi tạo xuyên suốt 1 lần khi vào app, không reset khi chuyển màn hình hoặc re-render.
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MARK: - Layout plant

            if dataReady {
            GeometryReader { geometry in
                let itemWidth = (geometry.size.width - 32) / 3.0
                let slotHeight = itemWidth * 1.95
                let userFloors: Int = (fireStoreService.gradenModel?.user.userFloor) ?? 1
                let _ = {
                    beeCoordinator.layout.viewportSize = geometry.size
                    beeCoordinator.layout.slotSize = CGSize(width: itemWidth, height: slotHeight)
                    beeCoordinator.layout.userFloors = userFloors
                    beeCoordinator.isEditing = isEdit
                    beeCoordinator.isSceneActive = (scenePhase == .active)
                }()
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
                        SpriteKitBackgroundView(backgroundId: backgroundRive, onReady: { backgroundReady = true })
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    }
                    */
                    // 100% SpriteKit Background
                    SpriteKitBackgroundView(backgroundId: atmosphere.backgroundRive, onReady: {
                        backgroundReady = true
                    })
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .ignoresSafeArea(.all)

                    HStack(spacing: 0) {
                        Image("r1").resizable()
                            .scaledToFill().frame(
                                width: 16, // 30% chiều rộng màn hình
                                height: geometry.size.height // 30% chiều rộng màn hình
                            )

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                Color.clear.frame(height: topSafeInset + hudHeight + 20)

                                // MARK: - Unlock Floor Button (Edit Mode Only)

                                if isEdit && canUnlockFloor() {
                                    UnlockFloorButton(
                                        currentFloor: userFloors,
                                        cost: calculateUnlockCost(),
                                        maxFloors: maxUnlockableFloors(),
                                        onUnlock: handleUnlockFloor
                                    )
                                    .padding(.vertical, 12)
                                }

                                // MARK: - Main Loop: Iterate through each floor/row

                                ForEach(Array((0 ... userFloors).reversed()), id: \.self) { rowIndex in
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
                                                        .frame(width: itemWidth, height: itemWidth * 1.95)
                                                        .allowsHitTesting(false)
                                                        .id("\(rowIndex)-\(columnIndex)-empty")
                                                } else {
                                                    // Plant slot: Tương tác tap trực tiếp trên cây và chậu, không bọc TouchScaleMenu khung ngoài
                                                    PlantItemView(
                                                        itemWidth: itemWidth,
                                                        weatherUntil: fireStoreService.gradenModel?.weatherUntil ?? 0,
                                                        weatherTapTrigger: weatherTapTrigger,
                                                        plantData: plantData,
                                                        rowIndex: rowIndex,
                                                        columnIndex: columnIndex,
                                                        cartPlants: fireStoreService.gradenModel?.cart.cartPlants ?? [],
                                                        cartPots: fireStoreService.gradenModel?.cart.cartPots ?? [],
                                                        cartStickers: fireStoreService.gradenModel?.cart.cartStickers ?? [],
                                                        cartAnimals: fireStoreService.gradenModel?.cart.cartAnimals ?? [],
                                                        isInfested: fireStoreService.gradenModel?.isPlantInfested(at: "\(rowIndex),\(columnIndex)") ?? false,
                                                        capturedPests: fireStoreService.gradenModel?.capturedPests ?? [],
                                                        isEditing: $isEdit,
                                                        draggedPlant: $draggedPlant,
                                                        onDrop: handleDrop,
                                                        onAnimalTap: {
                                                            let tappedId = plantData?.idPot ?? plantData?.idPlant ?? "animal1"
                                                            beeCoordinator.notifyAnimalTapped(animalId: tappedId)
                                                        }
                                                    )
                                                    .id("\(rowIndex)-\(columnIndex)-\(plantData?.idPlant ?? "empty")-\(plantData?.idPot ?? "empty")")
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("gardenViewport")) } action: { rect in
                                            guard beeCoordinator.hivePositionKey != nil
                                                || beeCoordinator.ladybugHomePositionKey != nil
                                                || beeCoordinator.bugsNetPositionKey != nil
                                                || !beeCoordinator.activePests.isEmpty else { return }
                                            beeCoordinator.layout.calibrate(row: rowIndex, viewportMinY: rect.minY)
                                        }
                                        // SpriteKit particle zPositions cannot cross SwiftUI siblings.
                                        // Let the padded slot surface draw over its own wooden shelf.
                                        .zIndex(1)

                                        Image("r2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(
                                                width: geometry.size.width - 32,
                                                height: 16
                                            )
                                    }
                                    // Rows below draw last so rising bubbles from a hanging
                                    // pot remain above the wooden shelf in the preceding row.
                                    .zIndex(Double(userFloors - rowIndex))
                                }
                            }
                        }
                        .defaultScrollAnchor(.bottom)
                        .scrollPosition($shelfPosition)
                        .onScrollGeometryChange(for: ShelfScrollMetrics.self) { value in
                            ShelfScrollMetrics(offset: value.contentOffset.y,
                                               maximum: max(0, value.contentSize.height - value.containerSize.height + value.contentInsets.bottom))
                        } action: { _, value in
                            beeCoordinator.layout.shelfOffset = value.offset
                            beeCoordinator.layout.shelfMaxOffset = value.maximum
                        }
                        .overlay {
                            if isEdit && draggedPlant != nil {
                                VStack(spacing: 0) {
                                    dragScrollEdge(-1)
                                    Spacer(minLength: 0)
                                    dragScrollEdge(1)
                                }
                            }
                        }
                        Image("r1").resizable()
                            .scaledToFill().frame(
                                width: 16, // 30% chiều rộng màn hình
                                height: geometry.size.height // 30% chiều rộng màn hình
                            ).scaleEffect(x: -1, y: 1) // 👈 lật ngang
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    GardenAnimalOverlayView(coordinator: beeCoordinator, viewportSize: geometry.size)

                    OverlayEffectView(overlayId: atmosphere.overlayRive)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                        .ignoresSafeArea(.all)
                        .allowsHitTesting(false)

                    GardenWeatherOverlay(weatherUntil: fireStoreService.gradenModel?.weatherUntil ?? 0,
                                         kind: fireStoreService.gradenModel?.weatherKind ?? .rain)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                }.frame(alignment: .leading)
                .coordinateSpace(name: "gardenViewport")
                .onAppear { syncGardenBees() }
                .onChange(of: gardenBeeSyncKey) { _, _ in syncGardenBees() }
            }

            .navigationBarHidden(true) // Ẩn thanh navigation
            .ignoresSafeArea(.container, edges: isEdit ? [.top, .leading, .trailing] : .all)
            .onChange(of: isEdit) {oldValue, newValue in
                // Clear drag state when disabling edit mode
                if !newValue {
                    draggedPlant = nil
                }
            }

            }
            if dataReady && backgroundReady && !isEdit {
                SpeedDial(isEditing: $isEdit, backgroundRive: $atmosphere.backgroundRive, overlayRive: $atmosphere.overlayRive)
            }
        } // Full màn hình, bao gồm status bar
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topSafeInset = $0 }
        .overlay(alignment: .topLeading) {
            if dataReady && backgroundReady {
            UserInfoCompoment()
                .allowsHitTesting(draggedPlant == nil)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hudHeight = $0 }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .overlay {
            CurtainLoadingOverlay(
                isLoading: !dataReady || !backgroundReady,
                loadFailed: loadFailed,
                onRetry: { reloadID += 1 }
            )
        }
        .task(id: "weather-\(fireStoreService.gradenModel?.weatherUntil ?? 0)-\(fireStoreService.gradenModel?.weatherKind.rawValue ?? "")-\(scenePhase)-\(dataReady)") {
            if let garden = fireStoreService.gradenModel,
               garden.weatherKind == .spray,
               garden.weatherUntil > Date().timeIntervalSince1970,
               lastHandledSprayDeadline != garden.weatherUntil {
                lastHandledSprayDeadline = garden.weatherUntil
                beeCoordinator.triggerChemicalSprayKillAll()
                showPestToast("💨 Xịt hóa chất tiêu diệt toàn bộ sâu bọ!".tr)
            }
            await runWeatherAutoTap()
        }
        .task(id: "autopest-\(dataReady)-\(scenePhase)-\(isEdit)-\(fireStoreService.gradenModel?.hasBugsNet ?? false)") {
            guard dataReady,
                  scenePhase == .active,
                  !isEdit,
                  fireStoreService.gradenModel?.hasBugsNet == true else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(18))
                    try Task.checkCancellation()
                    fireStoreService.spawnAutoPestIfNeeded()
                } catch {
                    return
                }
            }
        }
        .onChange(of: pestNotificationKey) { _, _ in
            presentPendingPestNotificationsIfNeeded()
        }
        .overlay(alignment: .bottom) {
            if let toast = pestToastMessage {
                Text(toast)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay { Capsule().strokeBorder(AccountStyle.border, lineWidth: 1) }
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 86)
                    .allowsHitTesting(false)
            }
        }
        .alert("Khu vườn bị thả sâu!".tr, isPresented: $showPestAttackAlert) {
            Button("Đã hiểu".tr, role: .cancel) {
                fireStoreService.clearPestNotifications()
            }
        } message: {
            Text(pestAttackAlertMessage)
        }
        .task(id: reloadID) { await loadGarden() }
        .task(id: "load-\(reloadID)-\(dataReady)-\(backgroundReady)") {
            guard !dataReady || !backgroundReady else { return }
            do {
                try await Task.sleep(for: .seconds(20))
                try Task.checkCancellation()
                loadFailed = true
            } catch { /* Ready state, retry, or navigation cancels the timeout. */ }
        }
        .task(id: "\(scrollDirection)-\(draggedPlant != nil)-\(isEdit)") {
            guard isEdit, draggedPlant != nil, scrollDirection != 0 else { return }
            do {
                while !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(30))
                    try Task.checkCancellation()
                    let target = min(max(beeCoordinator.layout.shelfOffset + CGFloat(scrollDirection) * 10, 0), beeCoordinator.layout.shelfMaxOffset)
                    shelfPosition.scrollTo(y: target)
                }
            } catch { }
        }
        .onChange(of: draggedPlant) { _, value in
            if value == nil { scrollDirection = 0 }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isEdit {
                LayoutEditingPanel {
                    isEdit = false
                    draggedPlant = nil
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
        .onDisappear { scrollDirection = 0; draggedPlant = nil }
    }

    @MainActor
    private func runWeatherAutoTap() async {
        guard dataReady, scenePhase == .active,
              let kind = fireStoreService.gradenModel?.weatherKind,
              kind.autoTapsPlants,
              let deadline = fireStoreService.gradenModel?.weatherUntil else { return }
        while !Task.isCancelled, Date().timeIntervalSince1970 < deadline {
            guard let garden = fireStoreService.gradenModel,
                  garden.weatherKind.autoTapsPlants,
                  garden.weatherUntil == deadline else { return }
            // Award every planted socket, including floors outside the lazy scroll viewport.
            for plant in garden.weatherPlants {
                fireStoreService.recordPlantTap(at: plant.position, plantId: plant.idPlant)
            }
            weatherTapTrigger += 1
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
        }
    }

    private func loadGarden() async {
        if fireStoreService.gradenModel == nil {
            dataReady = false
            backgroundReady = false
        } else {
            dataReady = true
        }
        loadFailed = false

        guard let userId = authService.currentUser?.uid else {
            if fireStoreService.gradenModel == nil {
                loadFailed = true
            }
            return
        }

        let loaded = await fireStoreService.getDataById(userId: userId)
        guard !Task.isCancelled else { return }
        guard loaded != nil || fireStoreService.gradenModel?.user.userID == userId else {
            if fireStoreService.gradenModel == nil {
                loadFailed = true
            }
            return
        }

        atmosphere.initializeIfNeeded(gardenModel: fireStoreService.gradenModel)
        fireStoreService.realtimeChangeDataGraden(userId: userId)
        dataReady = true
        presentPendingPestNotificationsIfNeeded()

        // Safety fallback: Đảm bảo không bị treo màn loading nếu SpriteKit view delay render
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            if !backgroundReady {
                backgroundReady = true
            }
        }

        // Wait for both garden unlocks and StoreKit VIP before choosing the startup track.
        await SubscriptionManager.shared.refreshEntitlements()
        guard !Task.isCancelled,
              authService.currentUser?.uid == userId,
              let garden = fireStoreService.gradenModel,
              garden.user.userID == userId else { return }
        BackgroundAudioManager.shared.startInitialBGMIfNeeded(gardenModel: garden)
    }

    private func dragScrollEdge(_ direction: Int) -> some View {
        Color.clear
            .frame(height: direction < 0 ? max(90, topSafeInset + hudHeight + 20) : 76)
            .contentShape(Rectangle())
            .onDrop(of: [.text], delegate: ShelfEdgeDropDelegate(
                onEnter: { scrollDirection = direction },
                onExit: { if scrollDirection == direction { scrollDirection = 0 } },
                onEnd: { scrollDirection = 0; draggedPlant = nil }
            ))
            .accessibilityHidden(true)
    }

    // MARK: - Helper Function

    private var pestNotificationKey: String {
        (fireStoreService.gradenModel?.pestNotifications ?? [])
            .map(\.id)
            .joined(separator: ",")
    }

    private func presentPendingPestNotificationsIfNeeded() {
        guard dataReady,
              !showPestAttackAlert,
              let notifications = fireStoreService.gradenModel?.pestNotifications,
              !notifications.isEmpty else { return }

        var grouped: [String: (bug1: Int, grasshopper: Int)] = [:]
        var senderOrder: [String] = []
        for item in notifications {
            if grouped[item.senderName] == nil {
                senderOrder.append(item.senderName)
            }
            var counts = grouped[item.senderName] ?? (0, 0)
            switch item.kind {
            case .bug1: counts.bug1 += 1
            case .grasshopper: counts.grasshopper += 1
            }
            grouped[item.senderName] = counts
        }

        let summaryLines = senderOrder.map { sender -> String in
            let counts = grouped[sender] ?? (0, 0)
            var parts: [String] = []
            if counts.bug1 > 0 { parts.append("%d sâu xanh".tr(counts.bug1)) }
            if counts.grasshopper > 0 { parts.append("%d châu chấu".tr(counts.grasshopper)) }
            return "• %@: %@".tr(sender, parts.joined(separator: ", "))
        }.joined(separator: "\n")

        pestAttackAlertMessage = "Trong lúc bạn vắng mặt, khu vườn đã bị thả sâu:\n%@\n\nHãy chạm vào sâu trên cây để tiêu diệt (+300 Oxy) hoặc dùng Xịt hóa chất!".tr(summaryLines)
        showPestAttackAlert = true
    }

    private func showPestToast(_ text: String) {
        pestToastTask?.cancel()
        pestToastMessage = text
        pestToastTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            pestToastMessage = nil
        }
    }

    private var gardenBeeSyncKey: String {
        let floor = fireStoreService.gradenModel?.user.userFloor ?? 1
        let items = (fireStoreService.gradenModel?.plants ?? [])
            .map { "\($0.position):\($0.idPlant):\($0.idPot):\($0.isHanging)" }
            .sorted()
            .joined(separator: "|")
        let pests = (fireStoreService.gradenModel?.pests ?? [])
            .map { "\($0.id):\($0.position):\($0.kind.rawValue)" }
            .sorted()
            .joined(separator: "|")
        return "\(floor)#\(items)#\(pests)"
    }

    private func syncGardenBees() {
        guard let garden = fireStoreService.gradenModel else {
            beeCoordinator.onPestTapped = nil
            beeCoordinator.syncGarden(hivePosition: nil, plantTargets: [], pests: [], userFloors: 1)
            return
        }
        var latestByPos: [String: GardenModel.Plant] = [:]
        for p in garden.plants {
            latestByPos[p.position] = p
        }
        let validSlots = latestByPos.values.filter { !$0.idPlant.isEmpty && !$0.idPot.isEmpty }
        let hive = validSlots.first(where: {
            $0.idPlant == "animal1" && $0.idPlant == $0.idPot && AnimalAvailability.isAvailable(animalId: $0.idPlant)
        })
        let ladybugHome = validSlots.first(where: {
            $0.idPlant == "animal2" && $0.idPlant == $0.idPot && AnimalAvailability.isAvailable(animalId: $0.idPlant)
        })
        let bugsNet = validSlots.first(where: {
            $0.idPlant == "animal3" && $0.idPlant == $0.idPot && AnimalAvailability.isAvailable(animalId: $0.idPlant)
        })
        let targets: [BeePlantTarget] = validSlots.compactMap { plant in
            guard plant.idPlant.hasPrefix("plant"), !plant.idPot.isEmpty,
                  let pos = PlantPosition(from: plant.position) else { return nil }
            let hanging = ItemDataManager.shared.getPlant(byId: plant.idPlant)?.itemTypeAttribute.isHanging ?? plant.isHanging
            return BeePlantTarget(positionKey: plant.position, row: pos.row, column: pos.column, isHanging: hanging)
        }
        beeCoordinator.onPestTapped = { [weak fireStoreService] pest in
            guard let fireStoreService,
                  let result = fireStoreService.resolvePestTap(pestId: pest.id) else {
                return false
            }
            if result.caughtInBag {
                let count = fireStoreService.gradenModel?.capturedPests.count ?? 0
                showPestToast("+%d 💨 · Đã bắt %@ vào túi (%d/5)".tr(result.oxygenGained, pest.kind.displayName, count))
            } else {
                showPestToast("+%d 💨 · Đã tiêu diệt %@".tr(result.oxygenGained, pest.kind.displayName))
            }
            return result.caughtInBag
        }
        beeCoordinator.syncGarden(
            hivePosition: hive?.position,
            ladybugHomePosition: ladybugHome?.position,
            bugsNetPosition: bugsNet?.position,
            plantTargets: targets,
            pests: garden.pests,
            userFloors: garden.user.userFloor,
            animalId: hive?.idPlant ?? ladybugHome?.idPlant ?? bugsNet?.idPlant ?? "animal1"
        )
    }

    /// Hàm lấy dữ liệu plant tại vị trí cụ thể (row, column)
    /// - Parameters:
    ///   - row: Số hàng (ví dụ: 12)
    ///   - column: Số cột (1, 2, hoặc 3)
    ///   - gardenModel: Dữ liệu garden từ Firebase
    /// - Returns: Plant data hoặc nil nếu không tìm thấy
    private func getPlantData(at row: Int, column: Int, from gardenModel: GardenModel?) -> GardenModel.Plant? {
        guard let plants = gardenModel?.plants else { return nil }

        // Ưu tiên tìm plant tại vị trí (row, column) có dữ liệu hợp lệ (không rỗng)
        if let validPlant = plants.reversed().first(where: { plant in
            guard let position = PlantPosition(from: plant.position) else { return false }
            return position.row == row && position.column == column && !plant.idPlant.isEmpty && !plant.idPot.isEmpty
        }) {
            return validPlant
        }

        // Fallback: Tìm bản ghi khớp toạ độ
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

private struct ShelfScrollMetrics: Equatable {
    let offset: CGFloat
    let maximum: CGFloat
}

private struct ShelfEdgeDropDelegate: DropDelegate {
    let onEnter: () -> Void
    let onExit: () -> Void
    let onEnd: () -> Void
    func dropEntered(info: DropInfo) { onEnter() }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func dropExited(info: DropInfo) { onExit() }
    func performDrop(info: DropInfo) -> Bool { onEnd(); return false }
}

//
//  GardenBeeSwarmCoordinator.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import Combine
import SpriteKit
import UIKit

// MARK: - Bee Plant Target

public struct BeePlantTarget: Equatable {
    public let positionKey: String
    public let row: Int
    public let column: Int
    public let isHanging: Bool

    public init(positionKey: String, row: Int, column: Int, isHanging: Bool) {
        self.positionKey = positionKey
        self.row = row
        self.column = column
        self.isHanging = isHanging
    }
}

// MARK: - Garden Slot Layout Tracker

/// Theo dõi tọa độ từng ô kệ trong hệ tọa độ nội dung vườn mà không kích hoạt SwiftUI re-render ở 60fps.
@MainActor
public final class GardenSlotLayoutTracker {
    public var viewportSize: CGSize = .zero {
        didSet {
            if abs(oldValue.width - viewportSize.width) > 1 || abs(oldValue.height - viewportSize.height) > 1 {
                resetCalibration()
            }
        }
    }
    public var slotSize: CGSize = .zero {
        didSet {
            if abs(oldValue.width - slotSize.width) > 1 || abs(oldValue.height - slotSize.height) > 1 {
                resetCalibration()
            }
        }
    }
    public var shelfSpacing: CGFloat = 16.0
    public var columnSpacing: CGFloat = 4.0
    public var shelfOffset: CGFloat = 0.0
    public var shelfMaxOffset: CGFloat = 0.0
    public var userFloors: Int = 1 {
        didSet {
            if oldValue != userFloors {
                resetCalibration()
            }
        }
    }

    /// Tọa độ `minY` của hàng (row) trong hệ nội dung top-down (`viewportMinY + shelfOffset`)
    private var calibratedRowContentTopY: [Int: CGFloat] = [:]
    private var referenceCalibration: (row: Int, contentTopY: CGFloat)?

    public init() {}

    public var isCalibrated: Bool {
        referenceCalibration != nil && viewportSize.width > 0 && viewportSize.height > 0 && slotSize.width > 0
    }

    private func resetCalibration() {
        calibratedRowContentTopY.removeAll()
        referenceCalibration = nil
    }

    public func calibrate(row: Int, viewportMinY: CGFloat) {
        guard viewportSize.width > 0, slotSize.height > 0 else { return }
        let contentTopY = viewportMinY + shelfOffset
        if let existing = calibratedRowContentTopY[row], abs(existing - contentTopY) < 0.5 {
            return
        }
        calibratedRowContentTopY[row] = contentTopY
        referenceCalibration = (row: row, contentTopY: contentTopY)
    }

    /// Tọa độ X tâm cột (`1...3`) trong viewport / worldNode
    public func contentX(forColumn column: Int) -> CGFloat {
        return viewportSize.width * 0.5 + CGFloat(column - 2) * (slotSize.width + columnSpacing)
    }

    /// Tọa độ Y top của hàng (`row`) trong hệ nội dung top-down
    public func contentTopY(forRow row: Int) -> CGFloat? {
        if let exact = calibratedRowContentTopY[row] {
            return exact
        }
        guard let ref = referenceCalibration else { return nil }
        let rowStride = slotSize.height + shelfSpacing
        return ref.contentTopY + CGFloat(ref.row - row) * rowStride
    }

    /// Chuyển tọa độ top-down nội dung sang tọa độ `worldNode` SpriteKit (+Y hướng lên)
    public func worldPoint(contentX: CGFloat, contentTopDownY: CGFloat) -> CGPoint {
        return CGPoint(x: contentX, y: viewportSize.height - contentTopDownY)
    }

    /// Điểm cửa tổ ong `animal1` trong `worldNode`
    public func hiveEntranceWorldPoint(for positionKey: String) -> CGPoint? {
        guard let (row, col) = Self.parsePosition(positionKey),
              let rowTopY = contentTopY(forRow: row) else { return nil }
        let offset = Animal1Node.hiveEntranceOffsetFromSlotTop(slotSize: slotSize)
        let cx = contentX(forColumn: col) + offset.x
        let cy = rowTopY + offset.y
        return worldPoint(contentX: cx, contentTopDownY: cy)
    }

    /// Điểm nghỉ trên mặt gốc gỗ mục `animal2` trong `worldNode`
    public func ladybugHomeWorldPoint(for positionKey: String) -> CGPoint? {
        guard let (row, col) = Self.parsePosition(positionKey),
              let rowTopY = contentTopY(forRow: row) else { return nil }
        let offset = Animal2Node.logRestOffsetFromSlotBottom(slotSize: slotSize)
        let cx = contentX(forColumn: col) + offset.x
        let cy = rowTopY + slotSize.height - offset.y
        return worldPoint(contentX: cx, contentTopDownY: cy)
    }

    /// Điểm tán lá cây để bọ rùa đáp xuống và bò trên lá trong `worldNode`
    public func plantLeafWorldPoint(for target: BeePlantTarget) -> CGPoint? {
        guard let rowTopY = contentTopY(forRow: target.row) else { return nil }
        let jitterX = CGFloat.random(in: -0.14...0.14) * slotSize.width
        let fracY: CGFloat = target.isHanging ? CGFloat.random(in: 0.48...0.68) : CGFloat.random(in: 0.58...0.74)
        let cx = contentX(forColumn: target.column) + jitterX
        let cy = rowTopY + slotSize.height * fracY
        return worldPoint(contentX: cx, contentTopDownY: cy)
    }

    /// Điểm tán hoa/cây để ong đáp xuống lấy mật trong `worldNode`
    public func plantNectarWorldPoint(for target: BeePlantTarget) -> CGPoint? {
        guard let rowTopY = contentTopY(forRow: target.row) else { return nil }
        let jitterX = CGFloat.random(in: -0.24...0.24) * slotSize.width
        let fracY: CGFloat = target.isHanging ? CGFloat.random(in: 0.56...0.76) : CGFloat.random(in: 0.36...0.60)
        let cx = contentX(forColumn: target.column) + jitterX
        let cy = rowTopY + slotSize.height * fracY
        return worldPoint(contentX: cx, contentTopDownY: cy)
    }

    public static func parsePosition(_ key: String) -> (Int, Int)? {
        let parts = key.split(separator: ",")
        guard parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) else { return nil }
        return (r, c)
    }
}

// MARK: - Garden Bee Swarm Coordinator

@MainActor
public final class GardenBeeSwarmCoordinator: ObservableObject {
    public let layout = GardenSlotLayoutTracker()
    public var isEditing: Bool = false {
        didSet {
            overlayScene?.isEditing = isEditing
        }
    }
    public var isSceneActive: Bool = true {
        didSet {
            overlayScene?.isScenePausedByLifecycle = !isSceneActive
        }
    }

    public private(set) var animalId: String = "animal1"
    public private(set) var hivePositionKey: String?
    public private(set) var ladybugHomePositionKey: String?
    public private(set) var plantTargets: [BeePlantTarget] = []

    weak var overlayScene: GardenBeeOverlayScene?

    public init() {}

    public func syncGarden(
        hivePosition: String?,
        ladybugHomePosition: String? = nil,
        plantTargets: [BeePlantTarget],
        userFloors: Int,
        animalId: String = "animal1"
    ) {
        let resolvedHive = (animalId == "animal2" && ladybugHomePosition == nil) ? nil : hivePosition
        let resolvedLadybug = ladybugHomePosition ?? (animalId == "animal2" ? hivePosition : nil)

        let changedHive = (self.hivePositionKey != resolvedHive) || (self.animalId != animalId)
        let changedLadybug = (self.ladybugHomePositionKey != resolvedLadybug)
        self.animalId = animalId
        self.hivePositionKey = resolvedHive
        self.ladybugHomePositionKey = resolvedLadybug
        self.plantTargets = plantTargets
        self.layout.userFloors = userFloors
        overlayScene?.syncSwarmConfiguration(hiveChanged: changedHive, ladybugChanged: changedLadybug)
    }

    /// Khi người dùng click vào tổ ong: nếu hiện không có chú ong nào ngoài vườn thì thả ra 1 chú ong đi lấy mật
    public func notifyHiveTapped() {
        overlayScene?.releaseOneBeeIfIdle()
    }

    /// Khi người dùng click vào tổ động vật theo ID (`animal1` hoặc `animal2`)
    public func notifyAnimalTapped(animalId: String) {
        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        if cleanId == "animal2" {
            overlayScene?.handleLadybugLogTapped()
        } else {
            overlayScene?.releaseOneBeeIfIdle()
        }
    }
}

// MARK: - Garden Bee Overlay Scene

public final class GardenBeeOverlayScene: SKScene {

    weak var coordinator: GardenBeeSwarmCoordinator?

    private let worldNode = SKNode()
    private var bees: [BeeAgentNode] = []
    private var lastSingleVariantIndex: Int?
    private var autoDispatchWorkItem: DispatchWorkItem?
    private var pendingDispatchCount: Int = 0

    private var ladybug: LazybugAgentNode?
    private var ladybugNeedsInitialPlacement: Bool = false
    private var ladybugTimerWorkItem: DispatchWorkItem?

    var isEditing: Bool = false {
        didSet {
            guard oldValue != isEditing else { return }
            refreshActiveRenderingState()
            if !isEditing && !isScenePausedByLifecycle {
                if activeBeeCount == 0 && coordinator?.hivePositionKey != nil {
                    scheduleAutoDispatch(delay: Double.random(in: 2.0...4.0))
                }
                if coordinator?.ladybugHomePositionKey != nil, ladybugTimerWorkItem == nil,
                   let bug = ladybug, bug.behaviorState == .idleAtHome || bug.behaviorState == .sleepingAtHome {
                    scheduleNextLadybugAction(delay: Double.random(in: 3.0...6.0))
                }
            } else if isEditing {
                cancelAutoDispatch()
                cancelLadybugTimer()
            }
        }
    }

    var isScenePausedByLifecycle: Bool = false {
        didSet {
            guard oldValue != isScenePausedByLifecycle else { return }
            refreshActiveRenderingState()
            if !isEditing && !isScenePausedByLifecycle {
                if activeBeeCount == 0 && coordinator?.hivePositionKey != nil {
                    scheduleAutoDispatch(delay: Double.random(in: 2.0...4.0))
                }
                if coordinator?.ladybugHomePositionKey != nil, ladybugTimerWorkItem == nil,
                   let bug = ladybug, bug.behaviorState == .idleAtHome || bug.behaviorState == .sleepingAtHome {
                    scheduleNextLadybugAction(delay: Double.random(in: 3.0...6.0))
                }
            } else if isScenePausedByLifecycle {
                cancelAutoDispatch()
                cancelLadybugTimer()
            }
        }
    }

    // MARK: - Lifecycle

    public override init(size: CGSize) {
        super.init(size: size)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.0, y: 0.0)
        addChild(worldNode)
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        syncSwarmConfiguration(hiveChanged: true, ladybugChanged: true)
    }

    // MARK: - Configuration & Pool

    func syncSwarmConfiguration(hiveChanged: Bool, ladybugChanged: Bool = false) {
        guard let coordinator else { return }

        if coordinator.hivePositionKey == nil {
            cancelAutoDispatch()
            removeAllBees()
        } else if bees.isEmpty {
            let slotW = coordinator.layout.slotSize.width > 0 ? coordinator.layout.slotSize.width : 110.0
            let beeWidth = max(18.0, min(25.0, slotW * 0.20))
            for variant in BeeVariant.allCases {
                let bee = BeeAgentNode(variant: variant, displayWidth: beeWidth)
                bee.zPosition = 300 + CGFloat(variant.rawValue)
                bee.setState(.idleInHive)
                bee.onReturnedToHive = { [weak self] _ in
                    self?.scheduleCooldownIfAllIdle()
                }
                worldNode.addChild(bee)
                bees.append(bee)
            }
            scheduleAutoDispatch(delay: Double.random(in: 2.2...4.0))
        } else if hiveChanged {
            for bee in bees {
                bee.removeAction(forKey: "bee_flight_mission")
                bee.setState(.idleInHive)
            }
            pendingDispatchCount = 0
            scheduleAutoDispatch(delay: Double.random(in: 2.2...4.0))
        }

        // Cấu hình chú bọ rùa duy nhất (`animal2`)
        if coordinator.ladybugHomePositionKey == nil {
            cancelLadybugTimer()
            removeLadybug()
        } else if ladybug == nil {
            let slotW = coordinator.layout.slotSize.width > 0 ? coordinator.layout.slotSize.width : 110.0
            let bugWidth = max(22.0, min(28.0, slotW * 0.23))
            let bug = LazybugAgentNode(displayWidth: bugWidth)
            bug.zPosition = 310
            bug.onReturnedHome = { [weak self] in
                self?.scheduleNextLadybugAction(delay: Double.random(in: 10.0...16.0))
            }
            worldNode.addChild(bug)
            ladybug = bug
            placeLadybugAtHomeIfPossible()
            scheduleNextLadybugAction(delay: Double.random(in: 5.0...9.0))
        } else if ladybugChanged {
            placeLadybugAtHomeIfPossible()
            scheduleNextLadybugAction(delay: Double.random(in: 5.0...9.0))
        }

        refreshActiveRenderingState()
    }

    private func removeLadybug() {
        ladybug?.removeAllActions()
        ladybug?.removeFromParent()
        ladybug = nil
        ladybugNeedsInitialPlacement = false
    }

    private func placeLadybugAtHomeIfPossible() {
        guard let bug = ladybug,
              let coordinator,
              let key = coordinator.ladybugHomePositionKey else { return }
        if coordinator.layout.isCalibrated,
           let homePt = coordinator.layout.ladybugHomeWorldPoint(for: key) {
            bug.settleAtHome(at: homePt, sleep: Bool.random())
            ladybugNeedsInitialPlacement = false
        } else {
            bug.isHidden = true
            ladybugNeedsInitialPlacement = true
        }
    }

    private func removeAllBees() {
        removeAction(forKey: "bee_batch_dispatch")
        pendingDispatchCount = 0
        for bee in bees {
            bee.removeAllActions()
            bee.removeFromParent()
        }
        bees.removeAll()
    }

    private var activeBeeCount: Int {
        bees.filter { $0.flightState != .idleInHive }.count + pendingDispatchCount
    }

    private func refreshActiveRenderingState() {
        let hasHive = coordinator?.hivePositionKey != nil
        let hasLadybug = coordinator?.ladybugHomePositionKey != nil
        let shouldRun = !isEditing && !isScenePausedByLifecycle && ((hasHive && activeBeeCount > 0) || hasLadybug)
        worldNode.isHidden = !shouldRun
        self.isPaused = !shouldRun
        if shouldRun, let coordinator {
            let y = coordinator.layout.shelfOffset
            if abs(worldNode.position.y - y) > 0.1 {
                worldNode.position = CGPoint(x: 0, y: y)
            }
        }
    }

    private func cancelAutoDispatch() {
        autoDispatchWorkItem?.cancel()
        autoDispatchWorkItem = nil
    }

    private func scheduleAutoDispatch(delay: TimeInterval) {
        cancelAutoDispatch()
        guard !isEditing, !isScenePausedByLifecycle, coordinator?.hivePositionKey != nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.autoDispatchWorkItem = nil
            self.dispatchRandomSwarm()
        }
        autoDispatchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func scheduleCooldownIfAllIdle() {
        if activeBeeCount == 0 {
            refreshActiveRenderingState()
            // Thỉnh thoảng mới bay ra để tránh spam
            scheduleAutoDispatch(delay: Double.random(in: 12.0...22.0))
        }
    }

    // MARK: - Frame Update

    public override func update(_ currentTime: TimeInterval) {
        guard let coordinator else { return }

        // Đồng bộ vị trí scroll của vườn theo từng frame khi có ong đang bay
        let targetY = coordinator.layout.shelfOffset
        if abs(worldNode.position.y - targetY) > 0.1 {
            worldNode.position = CGPoint(x: 0, y: targetY)
        }

        guard !isEditing,
              coordinator.layout.isCalibrated else { return }

        if coordinator.hivePositionKey != nil, !bees.isEmpty {
            for bee in bees where bee.flightState == .flyingToPlant || bee.flightState == .returning {
                bee.syncFacingToHorizontalMotion()
            }
        }

        if let bug = ladybug, let homeKey = coordinator.ladybugHomePositionKey {
            if ladybugNeedsInitialPlacement, let homePt = coordinator.layout.ladybugHomeWorldPoint(for: homeKey) {
                bug.settleAtHome(at: homePt, sleep: Bool.random())
                ladybugNeedsInitialPlacement = false
            } else if bug.behaviorState == .idleAtHome || bug.behaviorState == .sleepingAtHome {
                if let homePt = coordinator.layout.ladybugHomeWorldPoint(for: homeKey) {
                    let restYOffset = (bug.behaviorState == .sleepingAtHome) ? (bug.displayWidth * 0.24) : (bug.displayWidth * 0.36)
                    let adjustedHome = CGPoint(x: homePt.x, y: homePt.y + restYOffset)
                    if hypot(bug.position.x - adjustedHome.x, bug.position.y - adjustedHome.y) > 0.5 {
                        bug.position = adjustedHome
                    }
                }
            } else if bug.behaviorState == .flyingToPlant || bug.behaviorState == .flyingBetweenPlants || bug.behaviorState == .flyingHome {
                bug.syncFacingToHorizontalMotion()
            }
        }
    }

    // MARK: - Dispatch Logic

    /// Thả 1..4 chú ong (lần lượt hoặc hàng loạt) bay đến cây bất kỳ trên chậu lấy mật
    private func dispatchRandomSwarm() {
        guard let coordinator,
              !isEditing,
              !isScenePausedByLifecycle,
              coordinator.hivePositionKey != nil,
              coordinator.layout.isCalibrated else {
            if !isEditing && !isScenePausedByLifecycle && coordinator?.hivePositionKey != nil && activeBeeCount == 0 {
                scheduleAutoDispatch(delay: 1.5)
            }
            return
        }

        let count = Int.random(in: 1...4)
        let chosen = Array(bees.filter { $0.flightState == .idleInHive }.shuffled().prefix(count))
        guard !chosen.isEmpty else { return }

        cancelAutoDispatch()
        removeAction(forKey: "bee_batch_dispatch")
        let isBurst = Bool.random()
        pendingDispatchCount = chosen.count
        refreshActiveRenderingState()

        var actions: [SKAction] = []
        for (index, bee) in chosen.enumerated() {
            if index > 0 {
                let stagger = isBurst ? Double.random(in: 0.16...0.42) : Double.random(in: 1.15...2.25)
                actions.append(SKAction.wait(forDuration: stagger))
            }
            actions.append(SKAction.run { [weak self, weak bee] in
                guard let self else { return }
                self.pendingDispatchCount = max(0, self.pendingDispatchCount - 1)
                guard let bee else { return }
                self.launchSingleBee(bee)
            })
        }

        run(SKAction.sequence(actions), withKey: "bee_batch_dispatch")
    }

    /// Khi người dùng click vào tổ ong và hiện không có chú ong nào đang bay -> thả ra 1 con
    func releaseOneBeeIfIdle() {
        guard let coordinator,
              !isEditing,
              coordinator.hivePositionKey != nil,
              coordinator.layout.isCalibrated,
              activeBeeCount == 0 else { return }

        let idleBees = bees.filter { $0.flightState == .idleInHive }
        guard !idleBees.isEmpty else { return }

        let candidates = idleBees.filter { $0.variant.rawValue != lastSingleVariantIndex }
        let chosen = (candidates.isEmpty ? idleBees : candidates).randomElement()!
        lastSingleVariantIndex = chosen.variant.rawValue
        cancelAutoDispatch()
        launchSingleBee(chosen)
        refreshActiveRenderingState()
    }

    private func launchSingleBee(_ bee: BeeAgentNode) {
        guard let coordinator,
              let hiveKey = coordinator.hivePositionKey,
              let hivePoint = coordinator.layout.hiveEntranceWorldPoint(for: hiveKey) else {
            bee.setState(.idleInHive)
            return
        }

        let targetPlant = coordinator.plantTargets.randomElement()
        let destination: CGPoint
        if let plant = targetPlant,
           let pt = coordinator.layout.plantNectarWorldPoint(for: plant) {
            destination = pt
        } else {
            let dx = CGFloat.random(in: -70...70)
            let dy = CGFloat.random(in: -55...35)
            destination = CGPoint(x: hivePoint.x + dx, y: hivePoint.y + dy)
        }

        let collectTime = Double.random(in: 3.4...5.2)
        bee.launchMission(
            from: hivePoint,
            to: destination,
            plantKey: targetPlant?.positionKey,
            collectDuration: collectTime,
            hiveEntranceProvider: { [weak coordinator] in
                guard let coordinator,
                      let key = coordinator.hivePositionKey,
                      let pt = coordinator.layout.hiveEntranceWorldPoint(for: key) else {
                    return hivePoint
                }
                return pt
            },
            in: worldNode
        )
    }

    // MARK: - Ladybug Orchestration

    private func cancelLadybugTimer() {
        ladybugTimerWorkItem?.cancel()
        ladybugTimerWorkItem = nil
    }

    private func scheduleNextLadybugAction(delay: TimeInterval) {
        cancelLadybugTimer()
        guard !isEditing, !isScenePausedByLifecycle, coordinator?.ladybugHomePositionKey != nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.ladybugTimerWorkItem = nil
            self.performNextLadybugStep()
        }
        ladybugTimerWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func performNextLadybugStep() {
        guard let coordinator,
              let bug = ladybug,
              let homeKey = coordinator.ladybugHomePositionKey,
              !isEditing,
              !isScenePausedByLifecycle else { return }

        guard coordinator.layout.isCalibrated,
              let homePt = coordinator.layout.ladybugHomeWorldPoint(for: homeKey) else {
            scheduleNextLadybugAction(delay: 1.5)
            return
        }

        guard bug.behaviorState == .idleAtHome || bug.behaviorState == .sleepingAtHome else { return }

        // Nếu đang ở nhà: có thể chuyển qua lại idle <-> sleep lâu hơn hoặc bay ra cây
        if !coordinator.plantTargets.isEmpty && Double.random(in: 0...1) < 0.55 {
            launchLadybugRoam(from: homePt)
        } else {
            let nextSleep = (bug.behaviorState == .idleAtHome)
            bug.settleAtHome(at: homePt, sleep: nextSleep)
            scheduleNextLadybugAction(delay: Double.random(in: 9.0...15.0))
        }
    }

    private func launchLadybugRoam(from startPoint: CGPoint) {
        guard let bug = ladybug, let coordinator else { return }
        bug.launchRoamMission(
            from: startPoint,
            plantTargetProvider: { [weak coordinator] in
                guard let coordinator,
                      let target = coordinator.plantTargets.randomElement(),
                      let pt = coordinator.layout.plantLeafWorldPoint(for: target) else { return nil }
                return (key: target.positionKey, point: pt)
            },
            leafCrawlOffsetProvider: { [weak coordinator] in
                let slotW = coordinator?.layout.slotSize.width ?? 110.0
                let dx = (Bool.random() ? 1.0 : -1.0) * CGFloat.random(in: slotW * 0.05...slotW * 0.12)
                let dy = CGFloat.random(in: -5.0...6.0)
                return CGVector(dx: dx, dy: dy)
            },
            homePointProvider: { [weak coordinator] in
                guard let coordinator,
                      let key = coordinator.ladybugHomePositionKey,
                      let pt = coordinator.layout.ladybugHomeWorldPoint(for: key) else {
                    return startPoint
                }
                return pt
            },
            onFinishedHome: {}
        )
    }

    /// Khi người dùng click vào gốc cây gỗ mục (`animal2`):
    /// - Nếu bọ rùa đang ở bên ngoài -> bay về nhà
    /// - Nếu bọ rùa đã ở nhà -> không làm gì thêm (chỉ phát hiệu ứng rơi mảnh gỗ trên Animal2Node)
    func handleLadybugLogTapped() {
        guard let coordinator,
              let bug = ladybug,
              let homeKey = coordinator.ladybugHomePositionKey,
              !isEditing else { return }

        switch bug.behaviorState {
        case .flyingToPlant, .crawlingOnLeaf, .flyingBetweenPlants:
            cancelLadybugTimer()
            let fallback = bug.position
            bug.flyBackHome(
                homePointProvider: { [weak coordinator] in
                    guard let coordinator,
                          let pt = coordinator.layout.ladybugHomeWorldPoint(for: homeKey) else {
                        return fallback
                    }
                    return pt
                },
                onFinishedHome: {}
            )
        case .idleAtHome, .sleepingAtHome, .flyingHome, .startledHiding:
            break
        }
    }

    // MARK: - Hit Testing & Tap-to-Startle

    func hasTappableBee(atViewPoint viewPoint: CGPoint) -> Bool {
        guard !isEditing, !isScenePausedByLifecycle else { return false }
        let scenePoint = convertPoint(fromView: viewPoint)
        return findTappableBee(atScenePoint: scenePoint) != nil || findTappableLadybug(atScenePoint: scenePoint) != nil
    }

    private func findTappableLadybug(atScenePoint scenePoint: CGPoint) -> LazybugAgentNode? {
        guard let bug = ladybug, !bug.isHidden else { return nil }
        switch bug.behaviorState {
        case .flyingToPlant, .crawlingOnLeaf, .flyingBetweenPlants, .flyingHome:
            let worldPoint = convert(scenePoint, to: worldNode)
            let hitRadius = max(26.0, bug.displayWidth * 1.25)
            let d = hypot(worldPoint.x - bug.position.x, worldPoint.y - bug.position.y)
            return d <= hitRadius ? bug : nil
        case .idleAtHome, .sleepingAtHome, .startledHiding:
            return nil
        }
    }

    private func findTappableBee(atScenePoint scenePoint: CGPoint) -> BeeAgentNode? {
        let worldPoint = convert(scenePoint, to: worldNode)
        var closest: (bee: BeeAgentNode, dist: CGFloat)?

        for bee in bees {
            guard bee.flightState == .flyingToPlant || bee.flightState == .collecting else { continue }
            let hitRadius = max(24.0, bee.displayWidth * 1.15)
            let d = hypot(worldPoint.x - bee.position.x, worldPoint.y - bee.position.y)
            if d <= hitRadius {
                if closest == nil || d < closest!.dist {
                    closest = (bee, d)
                }
            }
        }
        return closest?.bee
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let coordinator else { return }
        let scenePoint = touch.location(in: self)

        if let bug = findTappableLadybug(atScenePoint: scenePoint) {
            cancelLadybugTimer()
            let soundName = ItemDataManager.shared.getAnimal(byId: "animal2")?.childClickSound(for: "lazybug") ?? "mixkit-clinking-coins-1993"
            AudioPlayer.shared.playClickSound(named: soundName)

            let fallbackHome = bug.position
            let worldSz = coordinator.layout.viewportSize.width > 0 ? coordinator.layout.viewportSize : self.size
            bug.triggerStartledAndHide(
                hideDuration: Double.random(in: 4.6...5.4),
                worldSize: worldSz,
                plantTargetProvider: { [weak coordinator] in
                    guard let coordinator,
                          let target = coordinator.plantTargets.randomElement(),
                          let pt = coordinator.layout.plantLeafWorldPoint(for: target) else { return nil }
                    return (key: target.positionKey, point: pt)
                },
                leafCrawlOffsetProvider: { [weak coordinator] in
                    let slotW = coordinator?.layout.slotSize.width ?? 110.0
                    let dx = (Bool.random() ? 1.0 : -1.0) * CGFloat.random(in: slotW * 0.05...slotW * 0.12)
                    let dy = CGFloat.random(in: -5.0...6.0)
                    return CGVector(dx: dx, dy: dy)
                },
                homePointProvider: { [weak coordinator] in
                    guard let coordinator,
                          let key = coordinator.ladybugHomePositionKey,
                          let pt = coordinator.layout.ladybugHomeWorldPoint(for: key) else {
                        return fallbackHome
                    }
                    return pt
                },
                in: worldNode,
                onFinishedHome: {}
            )
            return
        }

        guard let bee = findTappableBee(atScenePoint: scenePoint) else { return }

        // Âm thanh khi click vào con ong từ tapSoundChild["bee"]
        let soundName = ItemDataManager.shared.getAnimal(byId: coordinator.animalId)?.childClickSound(for: "bee") ?? "mixkit-clinking-coins-1993"
        AudioPlayer.shared.playClickSound(named: soundName)

        let fallbackHive = bee.position
        bee.triggerStartled(
            hiveEntranceProvider: { [weak coordinator] in
                guard let coordinator,
                      let key = coordinator.hivePositionKey,
                      let pt = coordinator.layout.hiveEntranceWorldPoint(for: key) else {
                    return fallbackHive
                }
                return pt
            },
            in: worldNode
        )
    }
}

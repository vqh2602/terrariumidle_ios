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
    public private(set) var plantTargets: [BeePlantTarget] = []

    weak var overlayScene: GardenBeeOverlayScene?

    public init() {}

    public func syncGarden(
        hivePosition: String?,
        plantTargets: [BeePlantTarget],
        userFloors: Int,
        animalId: String = "animal1"
    ) {
        let changedHive = (self.hivePositionKey != hivePosition) || (self.animalId != animalId)
        self.animalId = animalId
        self.hivePositionKey = hivePosition
        self.plantTargets = plantTargets
        self.layout.userFloors = userFloors
        overlayScene?.syncSwarmConfiguration(hiveChanged: changedHive)
    }

    /// Khi người dùng click vào tổ ong: nếu hiện không có chú ong nào ngoài vườn thì thả ra 1 chú ong đi lấy mật
    public func notifyHiveTapped() {
        overlayScene?.releaseOneBeeIfIdle()
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

    var isEditing: Bool = false {
        didSet {
            guard oldValue != isEditing else { return }
            refreshActiveRenderingState()
            if !isEditing && !isScenePausedByLifecycle && activeBeeCount == 0 && coordinator?.hivePositionKey != nil {
                scheduleAutoDispatch(delay: Double.random(in: 2.0...4.0))
            } else if isEditing {
                cancelAutoDispatch()
            }
        }
    }

    var isScenePausedByLifecycle: Bool = false {
        didSet {
            guard oldValue != isScenePausedByLifecycle else { return }
            refreshActiveRenderingState()
            if !isEditing && !isScenePausedByLifecycle && activeBeeCount == 0 && coordinator?.hivePositionKey != nil {
                scheduleAutoDispatch(delay: Double.random(in: 2.0...4.0))
            } else if isScenePausedByLifecycle {
                cancelAutoDispatch()
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
        syncSwarmConfiguration(hiveChanged: true)
    }

    // MARK: - Configuration & Pool

    func syncSwarmConfiguration(hiveChanged: Bool) {
        guard let coordinator else { return }

        guard coordinator.hivePositionKey != nil else {
            cancelAutoDispatch()
            removeAllBees()
            refreshActiveRenderingState()
            return
        }

        if bees.isEmpty {
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
            refreshActiveRenderingState()
            scheduleAutoDispatch(delay: Double.random(in: 2.2...4.0))
        } else if hiveChanged {
            for bee in bees {
                bee.removeAction(forKey: "bee_flight_mission")
                bee.setState(.idleInHive)
            }
            pendingDispatchCount = 0
            refreshActiveRenderingState()
            scheduleAutoDispatch(delay: Double.random(in: 2.2...4.0))
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
        let shouldRun = !isEditing && !isScenePausedByLifecycle && hasHive && activeBeeCount > 0
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
              coordinator.hivePositionKey != nil,
              coordinator.layout.isCalibrated,
              !bees.isEmpty else { return }

        for bee in bees where bee.flightState == .flyingToPlant || bee.flightState == .returning {
            bee.syncFacingToHorizontalMotion()
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

    // MARK: - Hit Testing & Tap-to-Startle

    func hasTappableBee(atViewPoint viewPoint: CGPoint) -> Bool {
        guard !isEditing, !isScenePausedByLifecycle else { return false }
        let scenePoint = convertPoint(fromView: viewPoint)
        return findTappableBee(atScenePoint: scenePoint) != nil
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

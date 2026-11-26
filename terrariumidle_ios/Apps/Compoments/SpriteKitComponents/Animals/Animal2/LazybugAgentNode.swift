//
//  LazybugAgentNode.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

// MARK: - Lazybug Pose & Behavior State

public enum LazybugPoseState: Equatable {
    case idle
    case sleep
    case fly
    case move
}

public enum LazybugBehaviorState: Equatable {
    case idleAtHome
    case sleepingAtHome
    case flyingToPlant
    case crawlingOnLeaf
    case flyingBetweenPlants
    case flyingHome
    case startledHiding
}

// MARK: - Part Metadata

private enum LazybugPartRole {
    case body
    case head
    case antennaLeft
    case antennaRight
    case legLeft
    case legRight
    case innerWingLeft
    case innerWingRight
    case outerWingLeft
    case outerWingRight
    case outerWingSpotsLeft
    case outerWingSpotsRight
}

private struct LazybugPartSpec {
    let imageName: String
    let svgX: CGFloat
    let svgY: CGFloat
    let svgW: CGFloat
    let svgH: CGFloat
    let anchorX: CGFloat
    let anchorY: CGFloat
    let zPosition: CGFloat
    let role: LazybugPartRole
}

// MARK: - Lazybug Agent Node

/// Node lắp ghép chú Bọ Rùa (`lazybug` / `animal2`) từ tọa độ SVG chuẩn xác ở 4 trạng thái:
/// - `idle`: đứng nghỉ trên gốc gỗ mục hoặc lá cây
/// - `sleep`: ngủ cuộn tròn trên gốc gỗ mục kèm chữ "Z" bay nhẹ
/// - `fly`: dang cánh bay chậm rãi giữa gốc gỗ mục và các cây
/// - `move`: bò lạch bạch trên lá cây, có thể quay trái/phải linh hoạt
public final class LazybugAgentNode: SKNode {

    // MARK: - Properties

    public private(set) var poseState: LazybugPoseState = .idle
    public private(set) var behaviorState: LazybugBehaviorState = .idleAtHome
    public var displayWidth: CGFloat

    private let facingNode = SKNode()
    private let bodyRigNode = SKNode()

    private var antennaeLeft: [SKNode] = []
    private var antennaeRight: [SKNode] = []
    private var legsLeft: [SKNode] = []
    private var legsRight: [SKNode] = []
    private var innerWingLeft: SKNode?
    private var innerWingRight: SKNode?
    private var outerWingLeftRig: SKNode?
    private var outerWingRightRig: SKNode?
    private var headNodes: [SKNode] = []

    public var currentTargetPlantKey: String?
    public var onReturnedHome: (() -> Void)?

    private var activeSequenceId = UUID()
    private var lastSampledX: CGFloat?

    // MARK: - Init

    public init(displayWidth: CGFloat = 28.0) {
        self.displayWidth = displayWidth
        super.init()

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assemblePose(.idle)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.displayWidth = 28.0
        super.init(coder: aDecoder)

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assemblePose(.idle)
    }

    // MARK: - Orientation

    private var currentPoseFacesRightByDefault: Bool {
        // Trong SVG: Ladybug_sleep quay đầu sang phải; lazybug-idle / fly / move hướng sang trái
        return poseState == .sleep
    }

    public private(set) var isFacingRight: Bool = false

    public func face(toward targetX: CGFloat, from sourceX: CGFloat, animated: Bool = true) {
        let movingRight = targetX >= sourceX
        setFacingRight(movingRight, animated: animated)
    }

    public func setFacingRight(_ facingRight: Bool, animated: Bool = true) {
        isFacingRight = facingRight
        applyFacingScale(animated: animated)
    }

    private func applyFacingScale(animated: Bool) {
        let needsFlip = (isFacingRight != currentPoseFacesRightByDefault)
        let targetXScale: CGFloat = needsFlip ? -1.0 : 1.0
        guard abs(facingNode.xScale - targetXScale) > 0.01 else { return }

        facingNode.removeAction(forKey: "lazybug_turn_facing")
        if animated {
            let turn = SKAction.scaleX(to: targetXScale, duration: 0.16)
            turn.timingMode = .easeInEaseOut
            facingNode.run(turn, withKey: "lazybug_turn_facing")
        } else {
            facingNode.xScale = targetXScale
        }
    }

    public func syncFacingToHorizontalMotion() {
        if let prevX = lastSampledX {
            let dx = position.x - prevX
            if abs(dx) > 0.35 {
                setFacingRight(dx > 0, animated: true)
            }
        }
        lastSampledX = position.x
    }

    // MARK: - Pose Assembly & Animation

    public func setPose(_ newPose: LazybugPoseState) {
        if poseState == newPose && !bodyRigNode.children.isEmpty {
            return
        }
        assemblePose(newPose)
    }

    private func assemblePose(_ pose: LazybugPoseState) {
        poseState = pose
        stopPartAnimations()
        bodyRigNode.removeAllChildren()
        antennaeLeft.removeAll()
        antennaeRight.removeAll()
        legsLeft.removeAll()
        legsRight.removeAll()
        innerWingLeft = nil
        innerWingRight = nil
        outerWingLeftRig = nil
        outerWingRightRig = nil
        headNodes.removeAll()

        bodyRigNode.position = .zero
        bodyRigNode.zRotation = 0.0
        bodyRigNode.xScale = 1.0
        bodyRigNode.yScale = 1.0

        let canvas = Self.svgCanvasSize(for: pose)
        let scale = displayWidth / canvas.width
        let specs = Self.specs(for: pose)

        // Đối với trạng thái bay, gom cánh đỏ ngoài + đốm đen vào cùng wing rig để xoay đồng bộ
        var wingLeftRig: SKNode?
        var wingRightRig: SKNode?

        if pose == .fly {
            if let lwSpec = specs.first(where: { $0.role == .outerWingLeft }) {
                let rig = SKNode()
                rig.position = skPosition(for: lwSpec, canvas: canvas, scale: scale)
                rig.zPosition = lwSpec.zPosition
                rig.restZRotation = 0.0
                bodyRigNode.addChild(rig)
                wingLeftRig = rig
                outerWingLeftRig = rig
            }
            if let rwSpec = specs.first(where: { $0.role == .outerWingRight }) {
                let rig = SKNode()
                rig.position = skPosition(for: rwSpec, canvas: canvas, scale: scale)
                rig.zPosition = rwSpec.zPosition
                rig.restZRotation = 0.0
                bodyRigNode.addChild(rig)
                wingRightRig = rig
                outerWingRightRig = rig
            }
        }

        for spec in specs {
            let tex = LazybugTextureCache.shared.texture(named: spec.imageName)
            let sprite = SKSpriteNode(texture: tex)
            sprite.size = CGSize(width: spec.svgW * scale, height: spec.svgH * scale)
            sprite.anchorPoint = CGPoint(x: spec.anchorX, y: spec.anchorY)
            sprite.zPosition = spec.zPosition
            let pos = skPosition(for: spec, canvas: canvas, scale: scale)
            sprite.position = pos
            sprite.restZRotation = 0.0

            switch spec.role {
            case .outerWingLeft:
                if let rig = wingLeftRig {
                    sprite.position = .zero
                    sprite.zPosition = 0
                    rig.addChild(sprite)
                } else {
                    bodyRigNode.addChild(sprite)
                }
            case .outerWingSpotsLeft:
                if let rig = wingLeftRig {
                    sprite.position = CGPoint(x: pos.x - rig.position.x, y: pos.y - rig.position.y)
                    sprite.zPosition = 1
                    rig.addChild(sprite)
                } else {
                    bodyRigNode.addChild(sprite)
                }
            case .outerWingRight:
                if let rig = wingRightRig {
                    sprite.position = .zero
                    sprite.zPosition = 0
                    rig.addChild(sprite)
                } else {
                    bodyRigNode.addChild(sprite)
                }
            case .outerWingSpotsRight:
                if let rig = wingRightRig {
                    sprite.position = CGPoint(x: pos.x - rig.position.x, y: pos.y - rig.position.y)
                    sprite.zPosition = 1
                    rig.addChild(sprite)
                } else {
                    bodyRigNode.addChild(sprite)
                }
            default:
                bodyRigNode.addChild(sprite)
            }

            switch spec.role {
            case .antennaLeft: antennaeLeft.append(sprite)
            case .antennaRight: antennaeRight.append(sprite)
            case .legLeft: legsLeft.append(sprite)
            case .legRight: legsRight.append(sprite)
            case .innerWingLeft: innerWingLeft = sprite
            case .innerWingRight: innerWingRight = sprite
            case .head: headNodes.append(sprite)
            case .body, .outerWingLeft, .outerWingRight, .outerWingSpotsLeft, .outerWingSpotsRight:
                break
            }
        }

        applyFacingScale(animated: false)
        startPartAnimations(for: pose)
    }

    private func skPosition(for spec: LazybugPartSpec, canvas: CGSize, scale: CGFloat) -> CGPoint {
        let svgAnchorX = spec.svgX + spec.anchorX * spec.svgW
        let svgAnchorY = spec.svgY + (1.0 - spec.anchorY) * spec.svgH
        let skX = (svgAnchorX - canvas.width * 0.5) * scale
        let skY = (canvas.height * 0.5 - svgAnchorY) * scale
        return CGPoint(x: skX, y: skY)
    }

    private func stopPartAnimations() {
        removeAction(forKey: "lazybug_sleep_z")
        bodyRigNode.removeAllActions()
        for node in antennaeLeft + antennaeRight + legsLeft + legsRight + headNodes {
            node.removeAllActions()
            node.zRotation = 0.0
        }
        innerWingLeft?.removeAllActions()
        innerWingLeft?.zRotation = 0.0
        innerWingRight?.removeAllActions()
        innerWingRight?.zRotation = 0.0
        outerWingLeftRig?.removeAllActions()
        outerWingLeftRig?.zRotation = 0.0
        outerWingRightRig?.removeAllActions()
        outerWingRightRig?.zRotation = 0.0
    }

    private func startPartAnimations(for pose: LazybugPoseState) {
        switch pose {
        case .idle:
            // Nhịp thở nhẹ + lắc râu đáng yêu
            let breatheUp = SKAction.group([
                SKAction.scaleX(to: 1.025, duration: 0.9),
                SKAction.scaleY(to: 0.975, duration: 0.9)
            ])
            breatheUp.timingMode = .easeInEaseOut
            let breatheDown = SKAction.group([
                SKAction.scaleX(to: 0.99, duration: 0.9),
                SKAction.scaleY(to: 1.02, duration: 0.9)
            ])
            breatheDown.timingMode = .easeInEaseOut
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown])), withKey: "lazybug_body")

            startAntennaWiggle(amplitude: 0.09, duration: 0.65)
            startHeadNod(amplitude: 0.035, duration: 1.1)

        case .sleep:
            // Thở sâu chậm rãi khi ngủ + chữ Z nhẹ nhàng bay lên
            let inhale = SKAction.group([
                SKAction.scaleX(to: 1.035, duration: 1.35),
                SKAction.scaleY(to: 0.96, duration: 1.35)
            ])
            inhale.timingMode = .easeInEaseOut
            let exhale = SKAction.group([
                SKAction.scaleX(to: 0.99, duration: 1.35),
                SKAction.scaleY(to: 1.02, duration: 1.35)
            ])
            exhale.timingMode = .easeInEaseOut
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([inhale, exhale])), withKey: "lazybug_body")

            startAntennaWiggle(amplitude: 0.035, duration: 1.35)
            startSleepZLoop()

        case .fly:
            // Cánh trong đập nhanh, cánh cứng ngoài rung nhẹ, thân bay nhấp nhô êm ái
            if let lw = innerWingLeft {
                let flapUp = SKAction.rotate(toAngle: 0.26, duration: 0.055)
                let flapDown = SKAction.rotate(toAngle: -0.18, duration: 0.055)
                lw.run(SKAction.repeatForever(SKAction.sequence([flapUp, flapDown])), withKey: "lazybug_wing")
            }
            if let rw = innerWingRight {
                let flapUp = SKAction.rotate(toAngle: -0.26, duration: 0.055)
                let flapDown = SKAction.rotate(toAngle: 0.18, duration: 0.055)
                rw.run(SKAction.repeatForever(SKAction.sequence([flapUp, flapDown])), withKey: "lazybug_wing")
            }
            if let olw = outerWingLeftRig {
                let a = SKAction.rotate(toAngle: 0.07, duration: 0.14)
                let b = SKAction.rotate(toAngle: -0.05, duration: 0.14)
                olw.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_outer_wing")
            }
            if let orw = outerWingRightRig {
                let a = SKAction.rotate(toAngle: -0.07, duration: 0.14)
                let b = SKAction.rotate(toAngle: 0.05, duration: 0.14)
                orw.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_outer_wing")
            }

            let bobUp = SKAction.group([
                SKAction.moveTo(y: 3.0, duration: 0.42),
                SKAction.rotate(toAngle: 0.05, duration: 0.42)
            ])
            bobUp.timingMode = .easeInEaseOut
            let bobDown = SKAction.group([
                SKAction.moveTo(y: -2.5, duration: 0.42),
                SKAction.rotate(toAngle: -0.04, duration: 0.42)
            ])
            bobDown.timingMode = .easeInEaseOut
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "lazybug_body")
            startAntennaWiggle(amplitude: 0.08, duration: 0.35)

        case .move:
            // Bò lạch bạch trên lá: chân đạp xen kẽ, thân lắc lư nhẹ
            let waddleL = SKAction.group([
                SKAction.moveTo(y: 1.4, duration: 0.14),
                SKAction.rotate(toAngle: 0.055, duration: 0.14)
            ])
            let waddleR = SKAction.group([
                SKAction.moveTo(y: 0.0, duration: 0.14),
                SKAction.rotate(toAngle: -0.055, duration: 0.14)
            ])
            bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([waddleL, waddleR])), withKey: "lazybug_body")

            for (idx, leg) in legsLeft.enumerated() {
                let phase = (idx % 2 == 0) ? 1.0 : -1.0
                let a = SKAction.rotate(toAngle: CGFloat(phase) * 0.22, duration: 0.12)
                let b = SKAction.rotate(toAngle: CGFloat(-phase) * 0.22, duration: 0.12)
                leg.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_leg")
            }
            for (idx, leg) in legsRight.enumerated() {
                let phase = (idx % 2 == 0) ? -1.0 : 1.0
                let a = SKAction.rotate(toAngle: CGFloat(phase) * 0.22, duration: 0.12)
                let b = SKAction.rotate(toAngle: CGFloat(-phase) * 0.22, duration: 0.12)
                leg.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_leg")
            }
            startAntennaWiggle(amplitude: 0.10, duration: 0.24)
        }
    }

    private func startAntennaWiggle(amplitude: CGFloat, duration: TimeInterval) {
        for ant in antennaeLeft {
            let a = SKAction.rotate(toAngle: amplitude, duration: duration)
            a.timingMode = .easeInEaseOut
            let b = SKAction.rotate(toAngle: -amplitude * 0.6, duration: duration)
            b.timingMode = .easeInEaseOut
            ant.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_ant")
        }
        for ant in antennaeRight {
            let a = SKAction.rotate(toAngle: -amplitude, duration: duration)
            a.timingMode = .easeInEaseOut
            let b = SKAction.rotate(toAngle: amplitude * 0.6, duration: duration)
            b.timingMode = .easeInEaseOut
            ant.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_ant")
        }
    }

    private func startHeadNod(amplitude: CGFloat, duration: TimeInterval) {
        for head in headNodes {
            let a = SKAction.rotate(toAngle: amplitude, duration: duration)
            a.timingMode = .easeInEaseOut
            let b = SKAction.rotate(toAngle: -amplitude, duration: duration)
            b.timingMode = .easeInEaseOut
            head.run(SKAction.repeatForever(SKAction.sequence([a, b])), withKey: "lazybug_head")
        }
    }

    private func startSleepZLoop() {
        let spawn = SKAction.run { [weak self] in
            guard let self, self.poseState == .sleep, !self.isHidden else { return }
            let zNode = SKSpriteNode(texture: LazybugTextureCache.shared.sleepZTexture)
            let sz = max(8.0, self.displayWidth * 0.34)
            zNode.size = CGSize(width: sz, height: sz * 1.1)
            let dir: CGFloat = self.isFacingRight ? 1.0 : -1.0
            zNode.position = CGPoint(x: dir * self.displayWidth * 0.28, y: self.displayWidth * 0.30)
            zNode.zPosition = 25
            zNode.alpha = 0.0
            zNode.setScale(0.55)
            self.addChild(zNode)

            let rise = SKAction.move(by: CGVector(dx: dir * 7.0, dy: 20.0), duration: 1.55)
            rise.timingMode = .easeOut
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.88, duration: 0.30),
                SKAction.wait(forDuration: 0.70),
                SKAction.fadeOut(withDuration: 0.55)
            ])
            let scale = SKAction.scale(to: 1.05, duration: 1.55)
            zNode.run(SKAction.sequence([
                SKAction.group([rise, fade, scale]),
                SKAction.removeFromParent()
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([spawn, SKAction.wait(forDuration: 1.35)])), withKey: "lazybug_sleep_z")
    }

    // MARK: - Behavior Orchestration

    /// Đặt bọ rùa về trạng thái nghỉ hoặc ngủ trên gốc cây gỗ mục
    public func settleAtHome(at homePoint: CGPoint, sleep: Bool) {
        activeSequenceId = UUID()
        removeAction(forKey: "lazybug_mission")
        currentTargetPlantKey = nil
        isHidden = false
        alpha = 1.0
        setScale(1.0)
        position = homePoint
        lastSampledX = homePoint.x
        behaviorState = sleep ? .sleepingAtHome : .idleAtHome
        setFacingRight(Bool.random(), animated: false)
        setPose(sleep ? .sleep : .idle)
    }

    /// Bắt đầu hành trình bay chậm hơn ong từ gốc gỗ mục -> đậu & bò trên lá cây -> (tùy chọn sang cây khác) -> bay về nhà
    public func launchRoamMission(
        from startPoint: CGPoint,
        plantTargetProvider: @escaping () -> (key: String?, point: CGPoint)?,
        leafCrawlOffsetProvider: @escaping () -> CGVector,
        homePointProvider: @escaping () -> CGPoint,
        onFinishedHome: @escaping () -> Void
    ) {
        activeSequenceId = UUID()
        let seqId = activeSequenceId
        removeAction(forKey: "lazybug_mission")

        isHidden = false
        alpha = 1.0
        setScale(1.0)
        position = startPoint
        lastSampledX = startPoint.x

        let firstDest = plantTargetProvider() ?? (key: nil, point: CGPoint(x: startPoint.x + 60, y: startPoint.y + 40))
        currentTargetPlantKey = firstDest.key
        behaviorState = .flyingToPlant
        face(toward: firstDest.point.x, from: startPoint.x)
        setPose(.fly)

        // Bọ rùa bay chậm hơn ong (ong ~62 pt/s -> bọ rùa ~36 pt/s)
        let dist1 = hypot(firstDest.point.x - startPoint.x, firstDest.point.y - startPoint.y)
        let dur1 = max(2.8, min(7.2, TimeInterval(dist1 / 36.0)))
        let flyToFirst = makeCurvedFlightAction(from: startPoint, to: firstDest.point, duration: dur1, arcLift: 22.0)

        var sequence: [SKAction] = [flyToFirst]

        // Đậu lên lá & bò qua lại trên cây 1
        sequence.append(contentsOf: makeLeafCrawlActions(seqId: seqId, offsetProvider: leafCrawlOffsetProvider))

        // 50% cơ hội bay sang 1 cây khác trước khi về nhà
        if Bool.random(), let secondDest = plantTargetProvider(), secondDest.key != firstDest.key {
            let hopToSecond = SKAction.run { [weak self] in
                guard let self, self.activeSequenceId == seqId else { return }
                self.currentTargetPlantKey = secondDest.key
                self.behaviorState = .flyingBetweenPlants
                self.face(toward: secondDest.point.x, from: self.position.x)
                self.setPose(.fly)
                let curPos = self.position
                let d2 = hypot(secondDest.point.x - curPos.x, secondDest.point.y - curPos.y)
                let dur2 = max(2.6, min(6.8, TimeInterval(d2 / 36.0)))
                let flight2 = self.makeCurvedFlightAction(from: curPos, to: secondDest.point, duration: dur2, arcLift: 20.0)
                var restSeq: [SKAction] = [flight2]
                restSeq.append(contentsOf: self.makeLeafCrawlActions(seqId: seqId, offsetProvider: leafCrawlOffsetProvider))
                restSeq.append(SKAction.run { [weak self] in
                    guard let self, self.activeSequenceId == seqId else { return }
                    self.flyBackHome(homePointProvider: homePointProvider, onFinishedHome: onFinishedHome)
                })
                self.run(SKAction.sequence(restSeq), withKey: "lazybug_mission")
            }
            sequence.append(hopToSecond)
        } else {
            sequence.append(SKAction.run { [weak self] in
                guard let self, self.activeSequenceId == seqId else { return }
                self.flyBackHome(homePointProvider: homePointProvider, onFinishedHome: onFinishedHome)
            })
        }

        run(SKAction.sequence(sequence), withKey: "lazybug_mission")
    }

    /// Bay về gốc cây gỗ mục ngay lập tức (khi user click vào tổ gỗ mục lúc bọ rùa đang ở ngoài)
    public func flyBackHome(
        homePointProvider: @escaping () -> CGPoint,
        onFinishedHome: @escaping () -> Void
    ) {
        activeSequenceId = UUID()
        let seqId = activeSequenceId
        removeAction(forKey: "lazybug_mission")

        isHidden = false
        alpha = 1.0
        setScale(1.0)
        currentTargetPlantKey = nil
        behaviorState = .flyingHome
        setPose(.fly)

        let start = position
        let home = homePointProvider()
        face(toward: home.x, from: start.x)

        let dist = hypot(home.x - start.x, home.y - start.y)
        let dur = max(2.0, min(6.5, TimeInterval(dist / 38.0)))
        let flyHome = makeCurvedFlightAction(from: start, to: home, duration: dur, arcLift: 20.0)

        let land = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            let exactHome = homePointProvider()
            let shouldSleep = Bool.random()
            self.settleAtHome(at: exactHome, sleep: shouldSleep)
            self.onReturnedHome?()
            onFinishedHome()
        }

        run(SKAction.sequence([flyHome, land]), withKey: "lazybug_mission")
    }

    /// Bọ rùa giật mình khi bị tap bên ngoài -> bay trốn ~5s -> bay về lại cây khác hoặc về gỗ mục
    public func triggerStartledAndHide(
        hideDuration: TimeInterval = 5.0,
        worldSize: CGSize,
        plantTargetProvider: @escaping () -> (key: String?, point: CGPoint)?,
        leafCrawlOffsetProvider: @escaping () -> CGVector,
        homePointProvider: @escaping () -> CGPoint,
        in worldNode: SKNode,
        onFinishedHome: @escaping () -> Void
    ) {
        activeSequenceId = UUID()
        let seqId = activeSequenceId
        removeAction(forKey: "lazybug_mission")

        behaviorState = .startledHiding
        currentTargetPlantKey = nil
        setPose(.fly)

        // Hiệu ứng tia sáng giật mình
        spawnStartleBurst(in: worldNode)

        let escapeDirX: CGFloat = Bool.random() ? 1.0 : -1.0
        setFacingRight(escapeDirX > 0, animated: false)

        let hopUp = SKAction.group([
            SKAction.move(by: CGVector(dx: -escapeDirX * 8.0, dy: 14.0), duration: 0.14),
            SKAction.scale(to: 1.22, duration: 0.14)
        ])
        hopUp.timingMode = .easeOut

        let fleeTarget = CGPoint(
            x: escapeDirX > 0 ? max(worldSize.width + 48.0, position.x + 140.0) : min(-48.0, position.x - 140.0),
            y: position.y + CGFloat.random(in: 70.0...130.0)
        )
        let fleeDist = hypot(fleeTarget.x - position.x, fleeTarget.y - position.y)
        let fleeDur = max(0.75, min(1.35, TimeInterval(fleeDist / 160.0)))
        let fleeMove = SKAction.group([
            SKAction.move(to: fleeTarget, duration: fleeDur),
            SKAction.scale(to: 0.72, duration: fleeDur),
            SKAction.sequence([
                SKAction.wait(forDuration: fleeDur * 0.55),
                SKAction.fadeOut(withDuration: fleeDur * 0.45)
            ])
        ])
        fleeMove.timingMode = .easeIn

        let hide = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            self.isHidden = true
        }

        let waitHidden = SKAction.wait(forDuration: hideDuration)

        let reappear = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            self.isHidden = false
            self.alpha = 0.0
            self.setScale(0.75)
            self.setPose(.fly)

            // Chọn bay về cây khác hoặc bay về gốc gỗ mục
            let goToPlant = Bool.random()
            let entryX: CGFloat = Bool.random() ? -32.0 : (worldSize.width + 32.0)
            let homePt = homePointProvider()
            let entryY = max(60.0, homePt.y + CGFloat.random(in: 40.0...120.0))
            let entryPt = CGPoint(x: entryX, y: entryY)
            self.position = entryPt
            self.lastSampledX = entryPt.x

            let fadeIn = SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.35),
                SKAction.scale(to: 1.0, duration: 0.35)
            ])

            if goToPlant, let plantDest = plantTargetProvider() {
                self.currentTargetPlantKey = plantDest.key
                self.behaviorState = .flyingToPlant
                self.face(toward: plantDest.point.x, from: entryPt.x, animated: false)
                let d = hypot(plantDest.point.x - entryPt.x, plantDest.point.y - entryPt.y)
                let dur = max(2.8, min(6.5, TimeInterval(d / 36.0)))
                let flyIn = self.makeCurvedFlightAction(from: entryPt, to: plantDest.point, duration: dur, arcLift: 20.0)

                var seq: [SKAction] = [SKAction.group([fadeIn, flyIn])]
                seq.append(contentsOf: self.makeLeafCrawlActions(seqId: seqId, offsetProvider: leafCrawlOffsetProvider))
                seq.append(SKAction.run { [weak self] in
                    guard let self, self.activeSequenceId == seqId else { return }
                    self.flyBackHome(homePointProvider: homePointProvider, onFinishedHome: onFinishedHome)
                })
                self.run(SKAction.sequence(seq), withKey: "lazybug_mission")
            } else {
                self.behaviorState = .flyingHome
                self.face(toward: homePt.x, from: entryPt.x, animated: false)
                let d = hypot(homePt.x - entryPt.x, homePt.y - entryPt.y)
                let dur = max(2.5, min(6.0, TimeInterval(d / 38.0)))
                let flyIn = self.makeCurvedFlightAction(from: entryPt, to: homePt, duration: dur, arcLift: 18.0)
                let land = SKAction.run { [weak self] in
                    guard let self, self.activeSequenceId == seqId else { return }
                    self.settleAtHome(at: homePointProvider(), sleep: Bool.random())
                    self.onReturnedHome?()
                    onFinishedHome()
                }
                self.run(SKAction.sequence([SKAction.group([fadeIn, flyIn]), land]), withKey: "lazybug_mission")
            }
        }

        run(SKAction.sequence([hopUp, fleeMove, hide, waitHidden, reappear]), withKey: "lazybug_mission")
    }

    // MARK: - Helpers

    private func makeLeafCrawlActions(seqId: UUID, offsetProvider: @escaping () -> CGVector) -> [SKAction] {
        var actions: [SKAction] = []
        let steps = Int.random(in: 2...3)
        for _ in 0..<steps {
            let pause = SKAction.run { [weak self] in
                guard let self, self.activeSequenceId == seqId else { return }
                self.behaviorState = .crawlingOnLeaf
                self.setPose(.idle)
            }
            let waitIdle = SKAction.wait(forDuration: Double.random(in: 1.1...2.0))

            let crawl = SKAction.run { [weak self] in
                guard let self, self.activeSequenceId == seqId else { return }
                let delta = offsetProvider()
                self.face(toward: self.position.x + delta.dx, from: self.position.x)
                self.setPose(.move)
                let dist = hypot(delta.dx, delta.dy)
                let dur = max(0.85, min(1.85, TimeInterval(dist / 16.0)))
                let move = SKAction.move(by: delta, duration: dur)
                move.timingMode = .easeInEaseOut
                self.run(move, withKey: "lazybug_leaf_step")
            }
            let waitCrawl = SKAction.wait(forDuration: 1.55)
            actions.append(contentsOf: [pause, waitIdle, crawl, waitCrawl])
        }
        return actions
    }

    private func makeCurvedFlightAction(from start: CGPoint, to end: CGPoint, duration: TimeInterval, arcLift: CGFloat) -> SKAction {
        let mid = CGPoint(
            x: (start.x + end.x) * 0.5 + CGFloat.random(in: -22...22),
            y: max(start.y, end.y) + arcLift + CGFloat.random(in: 6...24)
        )
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: mid)
        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeInEaseOut
        return follow
    }

    private func spawnStartleBurst(in worldNode: SKNode) {
        let tex = LazybugTextureCache.shared.sparkleTexture
        let origin = position
        for i in 0..<6 {
            let spark = SKSpriteNode(texture: tex)
            spark.color = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.42, blue: 0.30, alpha: 1.0)
                : UIColor(red: 1.0, green: 0.90, blue: 0.40, alpha: 1.0)
            spark.colorBlendFactor = 1.0
            spark.size = CGSize(width: 6, height: 6)
            spark.position = origin
            spark.zPosition = 320
            worldNode.addChild(spark)

            let angle = CGFloat(i) * (.pi * 2.0 / 6.0) + CGFloat.random(in: -0.2...0.2)
            let dist = CGFloat.random(in: 14.0...26.0)
            let move = SKAction.move(by: CGVector(dx: cos(angle) * dist, dy: sin(angle) * dist), duration: 0.32)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.32)
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    // MARK: - SVG Canvas & Exact Specs

    private static func svgCanvasSize(for pose: LazybugPoseState) -> CGSize {
        switch pose {
        case .idle:  return CGSize(width: 1025.527, height: 1483.133)
        case .sleep: return CGSize(width: 1443.003, height: 1011.071)
        case .fly:   return CGSize(width: 1460.815, height: 1165.700)
        case .move:  return CGSize(width: 1342.585, height: 1037.205)
        }
    }

    private static func specs(for pose: LazybugPoseState) -> [LazybugPartSpec] {
        switch pose {
        case .idle:
            return [
                LazybugPartSpec(imageName: "lazybug-idle-6",  svgX: 296.26, svgY: 1235.09, svgW: 179.65, svgH: 248.04, anchorX: 0.25, anchorY: 0.85, zPosition: 2,  role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-idle-7",  svgX: 771.01, svgY: 1170.78, svgW: 179.62, svgH: 248.08, anchorX: 0.25, anchorY: 0.85, zPosition: 2,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-idle-8",  svgX: 794.14, svgY: 1109.28, svgW: 231.36, svgH: 188.19, anchorX: 0.15, anchorY: 0.70, zPosition: 3,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-idle-9",  svgX: 262.12, svgY: 1145.26, svgW: 231.37, svgH: 188.19, anchorX: 0.15, anchorY: 0.70, zPosition: 3,  role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-idle-2",  svgX: 202.43, svgY: 566.11,  svgW: 672.05, svgH: 788.28, anchorX: 0.50, anchorY: 0.50, zPosition: 5,  role: .body),
                LazybugPartSpec(imageName: "lazybug-idle-1",  svgX: 0.01,   svgY: 211.77,  svgW: 975.12, svgH: 1156.33, anchorX: 0.50, anchorY: 0.50, zPosition: 8,  role: .body),
                LazybugPartSpec(imageName: "lazybug-idle-3",  svgX: 186.89, svgY: 346.79,  svgW: 714.48, svgH: 539.03, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .head),
                LazybugPartSpec(imageName: "lazybug-idle-4",  svgX: 209.63, svgY: 936.36,  svgW: 167.89, svgH: 84.45,  anchorX: 0.85, anchorY: 0.50, zPosition: 12, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-idle-5",  svgX: 719.70, svgY: 897.19,  svgW: 167.85, svgH: 84.45,  anchorX: 0.15, anchorY: 0.50, zPosition: 12, role: .legRight),
                LazybugPartSpec(imageName: "lazybug-idle-11", svgX: 336.76, svgY: 0.11,    svgW: 106.05, svgH: 374.50, anchorX: 0.55, anchorY: 0.05, zPosition: 14, role: .antennaLeft),
                LazybugPartSpec(imageName: "lazybug-idle-10", svgX: 717.37, svgY: 37.11,   svgW: 193.87, svgH: 339.92, anchorX: 0.10, anchorY: 0.05, zPosition: 14, role: .antennaRight)
            ]

        case .sleep:
            return [
                LazybugPartSpec(imageName: "lazybug-sleep-1",  svgX: 0.03,    svgY: 710.79, svgW: 241.17,  svgH: 196.15, anchorX: 0.90, anchorY: 0.80, zPosition: 2,  role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-sleep-2",  svgX: 31.46,   svgY: 0.01,   svgW: 1235.49, svgH: 936.31, anchorX: 0.50, anchorY: 0.50, zPosition: 4,  role: .body),
                LazybugPartSpec(imageName: "lazybug-sleep-3",  svgX: 31.55,   svgY: 70.98,  svgW: 935.14,  svgH: 630.72, anchorX: 0.50, anchorY: 0.50, zPosition: 6,  role: .body),
                LazybugPartSpec(imageName: "lazybug-sleep-4",  svgX: 304.21,  svgY: 0.15,   svgW: 975.21,  svgH: 610.06, anchorX: 0.50, anchorY: 0.50, zPosition: 7,  role: .body),
                LazybugPartSpec(imageName: "lazybug-sleep-5",  svgX: 595.19,  svgY: 437.53, svgW: 690.13,  svgH: 462.26, anchorX: 0.50, anchorY: 0.50, zPosition: 9,  role: .head),
                LazybugPartSpec(imageName: "lazybug-sleep-7",  svgX: 519.20,  svgY: 197.21, svgW: 281.20,  svgH: 295.28, anchorX: 0.90, anchorY: 0.08, zPosition: 11, role: .antennaLeft),
                LazybugPartSpec(imageName: "lazybug-sleep-6",  svgX: 1161.74, svgY: 187.51, svgW: 281.20,  svgH: 295.28, anchorX: 0.10, anchorY: 0.08, zPosition: 11, role: .antennaRight),
                LazybugPartSpec(imageName: "lazybug-sleep-8",  svgX: 270.22,  svgY: 759.66, svgW: 176.39,  svgH: 251.31, anchorX: 0.15, anchorY: 0.90, zPosition: 12, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-sleep-9",  svgX: 597.89,  svgY: 807.56, svgW: 262.20,  svgH: 182.02, anchorX: 0.15, anchorY: 0.85, zPosition: 12, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-sleep-10", svgX: 1086.32, svgY: 778.02, svgW: 177.58,  svgH: 140.64, anchorX: 0.70, anchorY: 0.85, zPosition: 12, role: .legRight)
            ]

        case .fly:
            return [
                LazybugPartSpec(imageName: "lazybug-fly-1",  svgX: 1124.40, svgY: 692.43,  svgW: 261.63,  svgH: 95.23,  anchorX: 0.10, anchorY: 0.50, zPosition: 2,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-fly-2",  svgX: 1072.72, svgY: 822.72,  svgW: 171.36,  svgH: 236.67, anchorX: 0.15, anchorY: 0.85, zPosition: 2,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-fly-3",  svgX: 205.77,  svgY: 265.07,  svgW: 1077.22, svgH: 900.58, anchorX: 0.50, anchorY: 0.50, zPosition: 4,  role: .body),
                LazybugPartSpec(imageName: "lazybug-fly-4",  svgX: 0.03,    svgY: 46.48,   svgW: 583.23,  svgH: 733.22, anchorX: 0.85, anchorY: 0.25, zPosition: 5,  role: .innerWingLeft),
                LazybugPartSpec(imageName: "lazybug-fly-5",  svgX: 660.50,  svgY: 66.67,   svgW: 800.16,  svgH: 729.00, anchorX: 0.15, anchorY: 0.25, zPosition: 5,  role: .innerWingRight),
                LazybugPartSpec(imageName: "lazybug-fly-6",  svgX: 69.11,   svgY: 0.00,    svgW: 542.35,  svgH: 760.87, anchorX: 0.85, anchorY: 0.20, zPosition: 7,  role: .outerWingLeft),
                LazybugPartSpec(imageName: "lazybug-fly-11", svgX: 158.05,  svgY: 112.67,  svgW: 378.79,  svgH: 485.28, anchorX: 0.50, anchorY: 0.50, zPosition: 8,  role: .outerWingSpotsLeft),
                LazybugPartSpec(imageName: "lazybug-fly-7",  svgX: 643.90,  svgY: 24.19,   svgW: 750.83,  svgH: 789.10, anchorX: 0.15, anchorY: 0.20, zPosition: 7,  role: .outerWingRight),
                LazybugPartSpec(imageName: "lazybug-fly-12", svgX: 806.58,  svgY: 157.86,  svgW: 416.88,  svgH: 474.75, anchorX: 0.50, anchorY: 0.50, zPosition: 8,  role: .outerWingSpotsRight),
                LazybugPartSpec(imageName: "lazybug-fly-8",  svgX: 226.44,  svgY: 590.58,  svgW: 837.30,  svgH: 559.64, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .head),
                LazybugPartSpec(imageName: "lazybug-fly-9",  svgX: 858.60,  svgY: 1027.74, svgW: 162.50,  svgH: 128.73, anchorX: 0.70, anchorY: 0.85, zPosition: 11, role: .legRight),
                LazybugPartSpec(imageName: "lazybug-fly-10", svgX: 281.19,  svgY: 1021.26, svgW: 162.54,  svgH: 128.73, anchorX: 0.30, anchorY: 0.85, zPosition: 11, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-fly-14", svgX: 291.80,  svgY: 312.00,  svgW: 184.95,  svgH: 324.28, anchorX: 0.88, anchorY: 0.08, zPosition: 13, role: .antennaLeft),
                LazybugPartSpec(imageName: "lazybug-fly-13", svgX: 838.21,  svgY: 309.11,  svgW: 184.92,  svgH: 324.31, anchorX: 0.12, anchorY: 0.08, zPosition: 13, role: .antennaRight)
            ]

        case .move:
            return [
                LazybugPartSpec(imageName: "lazybug-move-1",  svgX: 927.30,  svgY: 819.79, svgW: 198.43,  svgH: 147.24,  anchorX: 0.15, anchorY: 0.85, zPosition: 2,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-move-2",  svgX: 1116.50, svgY: 632.35, svgW: 226.08,  svgH: 87.00,   anchorX: 0.10, anchorY: 0.50, zPosition: 2,  role: .legRight),
                LazybugPartSpec(imageName: "lazybug-move-3",  svgX: 45.33,   svgY: 26.21,  svgW: 1209.24, svgH: 1010.94, anchorX: 0.50, anchorY: 0.50, zPosition: 4,  role: .body),
                LazybugPartSpec(imageName: "lazybug-move-4",  svgX: 426.44,  svgY: 52.60,  svgW: 812.95,  svgH: 624.78,  anchorX: 0.50, anchorY: 0.50, zPosition: 6,  role: .body),
                LazybugPartSpec(imageName: "lazybug-move-5",  svgX: 52.07,   svgY: 0.01,   svgW: 892.97,  svgH: 685.69,  anchorX: 0.50, anchorY: 0.50, zPosition: 7,  role: .body),
                LazybugPartSpec(imageName: "lazybug-move-6",  svgX: 54.64,   svgY: 408.63, svgW: 826.34,  svgH: 623.38,  anchorX: 0.50, anchorY: 0.50, zPosition: 9,  role: .head),
                LazybugPartSpec(imageName: "lazybug-move-7",  svgX: 74.12,   svgY: 814.85, svgW: 179.80,  svgH: 90.46,   anchorX: 0.85, anchorY: 0.80, zPosition: 11, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-move-8",  svgX: 498.04,  svgY: 915.39, svgW: 299.87,  svgH: 80.71,   anchorX: 0.85, anchorY: 0.50, zPosition: 11, role: .legLeft),
                LazybugPartSpec(imageName: "lazybug-move-9",  svgX: 0.00,    svgY: 139.00, svgW: 251.13,  svgH: 335.45,  anchorX: 0.88, anchorY: 0.08, zPosition: 13, role: .antennaLeft),
                LazybugPartSpec(imageName: "lazybug-move-10", svgX: 576.40,  svgY: 126.61, svgW: 251.15,  svgH: 335.43,  anchorX: 0.12, anchorY: 0.08, zPosition: 13, role: .antennaRight)
            ]
        }
    }
}

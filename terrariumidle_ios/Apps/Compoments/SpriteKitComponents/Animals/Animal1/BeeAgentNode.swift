//
//  BeeAgentNode.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

// MARK: - Bee State

public enum BeeFlightState: Equatable {
    case idleInHive
    case flyingToPlant
    case collecting
    case returning
    case startled
}

// MARK: - Bee Variant

public enum BeeVariant: Int, CaseIterable {
    case bee1 = 1
    case bee2 = 2
    case bee3 = 3
    case bee4 = 4

    /// Canvas kích thước SVG gốc để quy đổi tọa độ chuẩn xác
    public var svgCanvasSize: CGSize {
        switch self {
        case .bee1: return CGSize(width: 1191.186, height: 1260.024)
        case .bee2: return CGSize(width: 1260.392, height: 1251.412)
        case .bee3: return CGSize(width: 1375.415, height: 1372.854)
        case .bee4: return CGSize(width: 1704.283, height: 1324.172)
        }
    }

    /// Hướng nhìn gốc trong file SVG (bee1, bee3 nhìn phải; bee2, bee4 nhìn trái)
    public var facesRightByDefault: Bool {
        switch self {
        case .bee1, .bee3: return true
        case .bee2, .bee4: return false
        }
    }
}

// MARK: - Bee Part Metadata

private enum BeePartRole {
    case body
    case backWing
    case frontWing
    case eye
    case mouth
    case antenna
    case arm
    case leg
    case stinger
    case flower
}

private struct BeePartSpec {
    let imageName: String
    let svgX: CGFloat
    let svgY: CGFloat
    let svgW: CGFloat
    let svgH: CGFloat
    let anchorX: CGFloat
    let anchorY: CGFloat
    let zPosition: CGFloat
    let role: BeePartRole
}

// MARK: - Bee Agent Node

/// Node lắp ghép từng chú ong (`bee1`...`bee4`) từ tọa độ SVG chuẩn xác,
/// hỗ trợ đầy đủ 4 trạng thái hoạt ảnh: bay (`flyingToPlant`), lấy mật (`collecting`),
/// mang mật bay về tổ (`returning`), và giật mình khi bị chạm (`startled`).
public final class BeeAgentNode: SKNode {

    // MARK: - Properties

    public let variant: BeeVariant
    public private(set) var flightState: BeeFlightState = .idleInHive
    public var displayWidth: CGFloat

    private let facingNode = SKNode()
    private let bodyRigNode = SKNode()

    private var backWings: [SKSpriteNode] = []
    private var frontWings: [SKSpriteNode] = []
    private var antennae: [SKSpriteNode] = []
    private var arms: [SKSpriteNode] = []
    private var legs: [SKSpriteNode] = []
    private var eyes: [SKSpriteNode] = []
    private var flowerNode: SKSpriteNode?
    private var honeyCarryGlow: SKNode?

    public var currentTargetPlantKey: String?
    public var onReturnedToHive: ((BeeAgentNode) -> Void)?

    private var activeSequenceId = UUID()
    private var collectSparkTimer: TimeInterval = 0
    private var lastSampledX: CGFloat?

    // MARK: - Init

    public init(variant: BeeVariant, displayWidth: CGFloat = 22.0) {
        self.variant = variant
        self.displayWidth = displayWidth
        super.init()

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assembleFromSVG()
    }

    public required init?(coder aDecoder: NSCoder) {
        self.variant = .bee1
        self.displayWidth = 22.0
        super.init(coder: aDecoder)

        addChild(facingNode)
        facingNode.addChild(bodyRigNode)
        assembleFromSVG()
    }

    // MARK: - SVG Assembly

    private func assembleFromSVG() {
        bodyRigNode.removeAllChildren()
        backWings.removeAll()
        frontWings.removeAll()
        antennae.removeAll()
        arms.removeAll()
        legs.removeAll()
        eyes.removeAll()
        flowerNode = nil
        honeyCarryGlow = nil

        let canvas = variant.svgCanvasSize
        let scale = displayWidth / canvas.width
        let specs = Self.specs(for: variant)

        for spec in specs {
            let tex = BeeTextureCache.shared.texture(named: spec.imageName)
            let sprite = SKSpriteNode(texture: tex)
            sprite.size = CGSize(width: spec.svgW * scale, height: spec.svgH * scale)
            sprite.anchorPoint = CGPoint(x: spec.anchorX, y: spec.anchorY)
            sprite.zPosition = spec.zPosition

            // Quy đổi hệ tọa độ SVG (gốc trên-trái, +Y xuống) sang SpriteKit (tâm giữa, +Y lên)
            let svgAnchorX = spec.svgX + spec.anchorX * spec.svgW
            let svgAnchorY = spec.svgY + (1.0 - spec.anchorY) * spec.svgH
            let skX = (svgAnchorX - canvas.width * 0.5) * scale
            let skY = (canvas.height * 0.5 - svgAnchorY) * scale
            sprite.position = CGPoint(x: skX, y: skY)
            sprite.restZRotation = 0.0

            bodyRigNode.addChild(sprite)

            switch spec.role {
            case .backWing: backWings.append(sprite)
            case .frontWing: frontWings.append(sprite)
            case .antenna: antennae.append(sprite)
            case .arm: arms.append(sprite)
            case .leg: legs.append(sprite)
            case .eye: eyes.append(sprite)
            case .flower: flowerNode = sprite
            case .body, .mouth, .stinger: break
            }
        }

        // Hạt mật vàng nhỏ mang theo khi bay về tổ
        let glow = SKNode()
        glow.position = CGPoint(
            x: (variant.facesRightByDefault ? 1 : -1) * displayWidth * 0.16,
            y: -displayWidth * 0.18
        )
        glow.zPosition = 22
        glow.alpha = 0.0

        let drop = SKShapeNode(circleOfRadius: max(3.2, displayWidth * 0.09))
        drop.fillColor = UIColor(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.95)
        drop.strokeColor = UIColor(red: 0.95, green: 0.52, blue: 0.0, alpha: 0.9)
        drop.lineWidth = 0.9
        glow.addChild(drop)

        let halo = SKShapeNode(circleOfRadius: max(5.5, displayWidth * 0.15))
        halo.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.32)
        halo.strokeColor = .clear
        glow.addChild(halo)

        bodyRigNode.addChild(glow)
        self.honeyCarryGlow = glow
    }

    // MARK: - Orientation

    public func face(toward targetX: CGFloat, from sourceX: CGFloat, animated: Bool = true) {
        let movingRight = targetX >= sourceX
        setFacingRight(movingRight, animated: animated)
    }

    public func setFacingRight(_ facingRight: Bool, animated: Bool = true) {
        let needsFlip = (facingRight != variant.facesRightByDefault)
        let targetXScale: CGFloat = needsFlip ? -1.0 : 1.0
        guard abs(facingNode.xScale - targetXScale) > 0.01 else { return }

        facingNode.removeAction(forKey: "bee_turn_facing")
        if animated {
            let turn = SKAction.scaleX(to: targetXScale, duration: 0.14)
            turn.timingMode = .easeInEaseOut
            facingNode.run(turn, withKey: "bee_turn_facing")
        } else {
            facingNode.xScale = targetXScale
        }
    }

    // MARK: - State Animations

    public func setState(_ newState: BeeFlightState) {
        flightState = newState
        stopPartAnimations()

        switch newState {
        case .idleInHive:
            honeyCarryGlow?.alpha = 0.0
            bodyRigNode.position = .zero
            bodyRigNode.zRotation = 0.0
            bodyRigNode.xScale = 1.0
            bodyRigNode.yScale = 1.0
            isHidden = true

        case .flyingToPlant:
            isHidden = false
            honeyCarryGlow?.alpha = 0.0
            startWingFlap(flapDuration: 0.065, amplitude: 0.32)
            startBodyBobbing(amplitudeY: 2.8, duration: 0.32, pitch: -0.06)
            startAntennaIdle(amplitude: 0.08, duration: 0.28)
            startLegsTrailing(angle: -0.10, duration: 0.36)

        case .collecting:
            isHidden = false
            honeyCarryGlow?.alpha = 0.0
            startWingFlap(flapDuration: 0.075, amplitude: 0.24)
            startCollectingMotion()
            startAntennaIdle(amplitude: 0.12, duration: 0.20)
            startArmsCollecting()

        case .returning:
            isHidden = false
            honeyCarryGlow?.alpha = 1.0
            startWingFlap(flapDuration: 0.060, amplitude: 0.34)
            startBodyBobbing(amplitudeY: 2.4, duration: 0.28, pitch: 0.05)
            startAntennaIdle(amplitude: 0.07, duration: 0.26)
            startLegsTrailing(angle: -0.08, duration: 0.32)

        case .startled:
            isHidden = false
            honeyCarryGlow?.alpha = 0.0
            startWingFlap(flapDuration: 0.036, amplitude: 0.42)
            startStartledMotion()
        }
    }

    // MARK: - Flight Orchestration

    /// Bay từ tổ ong đến cây đích, lấy mật vài giây rồi bay về tổ
    public func launchMission(
        from hiveEntrance: CGPoint,
        to plantCanopy: CGPoint,
        plantKey: String?,
        collectDuration: TimeInterval,
        hiveEntranceProvider: @escaping () -> CGPoint,
        in worldNode: SKNode
    ) {
        activeSequenceId = UUID()
        let seqId = activeSequenceId
        currentTargetPlantKey = plantKey

        removeAction(forKey: "bee_flight_mission")
        setScale(0.28)
        alpha = 0.0
        position = hiveEntrance
        face(toward: plantCanopy.x, from: hiveEntrance.x)
        setState(.flyingToPlant)

        let distance = hypot(plantCanopy.x - hiveEntrance.x, plantCanopy.y - hiveEntrance.y)
        let travelDuration = max(2.2, min(4.8, TimeInterval(distance / 62.0)))

        let emerge = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.26),
            SKAction.fadeAlpha(to: 1.0, duration: 0.22)
        ])
        emerge.timingMode = .easeOut

        face(toward: plantCanopy.x, from: hiveEntrance.x, animated: false)
        let flyOut = makeCurvedFlightAction(from: hiveEntrance, to: plantCanopy, duration: travelDuration, arcLift: 26.0)

        let beginCollecting = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            self.setState(.collecting)
            self.startCollectingSparkles(in: worldNode, duration: collectDuration)
        }

        // Di chuyển và quay trái/phải linh hoạt quanh tán hoa trong lúc thu mật
        let firstDirRight = Bool.random()
        let step1X: CGFloat = firstDirRight ? 7.0 : -7.0
        let step2X: CGFloat = firstDirRight ? -13.0 : 13.0
        let step3X: CGFloat = firstDirRight ? 6.0 : -6.0

        let turn1 = SKAction.run { [weak self] in self?.setFacingRight(firstDirRight, animated: true) }
        let hoverDrift1 = SKAction.moveBy(x: step1X, y: -4.0, duration: collectDuration * 0.32)
        hoverDrift1.timingMode = .easeInEaseOut

        let turn2 = SKAction.run { [weak self] in self?.setFacingRight(!firstDirRight, animated: true) }
        let hoverDrift2 = SKAction.moveBy(x: step2X, y: 5.0, duration: collectDuration * 0.36)
        hoverDrift2.timingMode = .easeInEaseOut

        let turn3 = SKAction.run { [weak self] in self?.setFacingRight(firstDirRight, animated: true) }
        let hoverDrift3 = SKAction.moveBy(x: step3X, y: -1.0, duration: collectDuration * 0.32)
        hoverDrift3.timingMode = .easeInEaseOut

        let startReturn = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            let returnPoint = hiveEntranceProvider()
            self.flyBackToHive(to: returnPoint, fast: false, missionId: seqId)
        }

        let mission = SKAction.sequence([
            SKAction.group([emerge, flyOut]),
            beginCollecting,
            turn1, hoverDrift1,
            turn2, hoverDrift2,
            turn3, hoverDrift3,
            startReturn
        ])
        run(mission, withKey: "bee_flight_mission")
    }

    /// Kích hoạt khi người dùng tap vào chú ong đang bay hoặc đang lấy mật
    public func triggerStartled(hiveEntranceProvider: @escaping () -> CGPoint, in worldNode: SKNode) {
        guard flightState == .flyingToPlant || flightState == .collecting else { return }

        activeSequenceId = UUID()
        let seqId = activeSequenceId
        removeAction(forKey: "bee_flight_mission")

        setState(.startled)
        BeeStartledSparkEffect.trigger(
            at: CGPoint(x: position.x, y: position.y + displayWidth * 0.35),
            in: worldNode
        )

        let jumpUp = SKAction.moveBy(x: 0, y: 16.0, duration: 0.11)
        jumpUp.timingMode = .easeOut
        let settle = SKAction.moveBy(x: 0, y: -4.0, duration: 0.14)
        settle.timingMode = .easeInEaseOut

        let afterShock = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == seqId else { return }
            self.flyBackToHive(to: hiveEntranceProvider(), fast: true, missionId: seqId)
        }

        run(SKAction.sequence([jumpUp, settle, SKAction.wait(forDuration: 0.10), afterShock]), withKey: "bee_flight_mission")
    }

    private func flyBackToHive(to hivePoint: CGPoint, fast: Bool, missionId: UUID) {
        guard activeSequenceId == missionId else { return }
        face(toward: hivePoint.x, from: position.x)
        setState(.returning)

        let dist = hypot(hivePoint.x - position.x, hivePoint.y - position.y)
        let speed: CGFloat = fast ? 175.0 : 68.0
        let duration = max(fast ? 0.90 : 2.0, min(fast ? 2.0 : 4.6, TimeInterval(dist / speed)))

        let flyHome = makeCurvedFlightAction(from: position, to: hivePoint, duration: duration, arcLift: fast ? 20.0 : 32.0)

        let shrinkIntoHive = SKAction.sequence([
            SKAction.wait(forDuration: max(0.0, duration - 0.24)),
            SKAction.group([
                SKAction.scale(to: 0.22, duration: 0.24),
                SKAction.fadeAlpha(to: 0.0, duration: 0.24)
            ])
        ])

        let finish = SKAction.run { [weak self] in
            guard let self, self.activeSequenceId == missionId else { return }
            self.currentTargetPlantKey = nil
            self.setState(.idleInHive)
            self.onReturnedToHive?(self)
        }

        run(SKAction.sequence([SKAction.group([flyHome, shrinkIntoHive]), finish]), withKey: "bee_flight_mission")
    }

    /// Tự động cập nhật hướng quay trái/phải theo vận tốc ngang thực tế khi đang bay
    public func syncFacingToHorizontalMotion() {
        defer { lastSampledX = position.x }
        guard flightState == .flyingToPlant || flightState == .returning,
              let prevX = lastSampledX else { return }
        let dx = position.x - prevX
        if dx > 0.35 {
            setFacingRight(true, animated: true)
        } else if dx < -0.35 {
            setFacingRight(false, animated: true)
        }
    }

    private func makeCurvedFlightAction(from start: CGPoint, to end: CGPoint, duration: TimeInterval, arcLift: CGFloat) -> SKAction {
        let lateralSwing: CGFloat = abs(end.x - start.x) < 22.0 ? (Bool.random() ? 26.0 : -26.0) : 0.0
        let midX = (start.x + end.x) * 0.5 + lateralSwing
        let midY = max(start.y, end.y) + arcLift
        let path = CGMutablePath()
        path.move(to: start)
        path.addQuadCurve(to: end, control: CGPoint(x: midX, y: midY))

        let follow = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        follow.timingMode = .easeInEaseOut
        return follow
    }

    // MARK: - Sub-Animations (Strict rotate(toAngle:) around restZRotation)

    private func stopPartAnimations() {
        bodyRigNode.removeAllActions()
        for node in backWings + frontWings + antennae + arms + legs + eyes {
            node.removeAllActions()
            node.zRotation = node.restZRotation
            node.xScale = 1.0
            node.yScale = 1.0
        }
        flowerNode?.removeAllActions()
        flowerNode?.zRotation = flowerNode?.restZRotation ?? 0.0
    }

    private func startWingFlap(flapDuration: TimeInterval, amplitude: CGFloat) {
        let dirSign: CGFloat = variant.facesRightByDefault ? 1.0 : -1.0

        for (idx, wing) in (backWings + frontWings).enumerated() {
            let rest = wing.restZRotation
            let phaseOffset = (idx % 2 == 0) ? 1.0 : 0.78
            let upAngle = rest + dirSign * amplitude * phaseOffset
            let downAngle = rest - dirSign * amplitude * 0.55 * phaseOffset

            let up = SKAction.group([
                SKAction.rotate(toAngle: upAngle, duration: flapDuration),
                SKAction.scaleY(to: 0.90, duration: flapDuration)
            ])
            up.timingMode = .easeInEaseOut

            let down = SKAction.group([
                SKAction.rotate(toAngle: downAngle, duration: flapDuration),
                SKAction.scaleY(to: 1.04, duration: flapDuration)
            ])
            down.timingMode = .easeInEaseOut

            let loop = SKAction.repeatForever(SKAction.sequence([up, down]))
            if idx % 2 == 1 {
                wing.run(SKAction.sequence([SKAction.wait(forDuration: flapDuration * 0.35), loop]), withKey: "wing_flap")
            } else {
                wing.run(loop, withKey: "wing_flap")
            }
        }
    }

    private func startBodyBobbing(amplitudeY: CGFloat, duration: TimeInterval, pitch: CGFloat) {
        let up = SKAction.move(to: CGPoint(x: 0, y: amplitudeY), duration: duration)
        up.timingMode = .easeInEaseOut
        let down = SKAction.move(to: CGPoint(x: 0, y: -amplitudeY), duration: duration)
        down.timingMode = .easeInEaseOut
        bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "body_bob")

        let dirSign: CGFloat = variant.facesRightByDefault ? 1.0 : -1.0
        let tiltForward = SKAction.rotate(toAngle: dirSign * pitch, duration: duration * 1.2)
        tiltForward.timingMode = .easeInEaseOut
        let tiltBack = SKAction.rotate(toAngle: dirSign * (pitch * 0.3), duration: duration * 1.2)
        tiltBack.timingMode = .easeInEaseOut
        bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([tiltForward, tiltBack])), withKey: "body_pitch")
    }

    private func startCollectingMotion() {
        let dirSign: CGFloat = variant.facesRightByDefault ? 1.0 : -1.0
        let dipDown = SKAction.group([
            SKAction.move(to: CGPoint(x: 0, y: -4.0), duration: 0.42),
            SKAction.rotate(toAngle: dirSign * (-0.14), duration: 0.42)
        ])
        dipDown.timingMode = .easeInEaseOut
        let liftUp = SKAction.group([
            SKAction.move(to: CGPoint(x: 0, y: 2.5), duration: 0.45),
            SKAction.rotate(toAngle: dirSign * (-0.04), duration: 0.45)
        ])
        liftUp.timingMode = .easeInEaseOut

        bodyRigNode.run(SKAction.repeatForever(SKAction.sequence([dipDown, liftUp])), withKey: "body_collect")

        if let flower = flowerNode {
            let r = flower.restZRotation
            let sway1 = SKAction.rotate(toAngle: r + 0.08, duration: 0.35)
            let sway2 = SKAction.rotate(toAngle: r - 0.08, duration: 0.35)
            flower.run(SKAction.repeatForever(SKAction.sequence([sway1, sway2])), withKey: "flower_bob")
        }
    }

    private func startArmsCollecting() {
        for (idx, arm) in arms.enumerated() {
            let r = arm.restZRotation
            let delta: CGFloat = (idx % 2 == 0) ? 0.16 : -0.16
            let a1 = SKAction.rotate(toAngle: r + delta, duration: 0.24)
            a1.timingMode = .easeInEaseOut
            let a2 = SKAction.rotate(toAngle: r - delta * 0.6, duration: 0.24)
            a2.timingMode = .easeInEaseOut
            arm.run(SKAction.repeatForever(SKAction.sequence([a1, a2])), withKey: "arm_collect")
        }
    }

    private func startAntennaIdle(amplitude: CGFloat, duration: TimeInterval) {
        for (idx, ant) in antennae.enumerated() {
            let r = ant.restZRotation
            let sign: CGFloat = (idx % 2 == 0) ? 1.0 : -1.0
            let w1 = SKAction.rotate(toAngle: r + sign * amplitude, duration: duration)
            w1.timingMode = .easeInEaseOut
            let w2 = SKAction.rotate(toAngle: r - sign * amplitude * 0.7, duration: duration)
            w2.timingMode = .easeInEaseOut
            ant.run(SKAction.repeatForever(SKAction.sequence([w1, w2])), withKey: "ant_twitch")
        }
    }

    private func startLegsTrailing(angle: CGFloat, duration: TimeInterval) {
        let dirSign: CGFloat = variant.facesRightByDefault ? 1.0 : -1.0
        for (idx, leg) in legs.enumerated() {
            let r = leg.restZRotation
            let l1 = SKAction.rotate(toAngle: r + dirSign * angle, duration: duration + Double(idx) * 0.05)
            l1.timingMode = .easeInEaseOut
            let l2 = SKAction.rotate(toAngle: r, duration: duration + Double(idx) * 0.05)
            l2.timingMode = .easeInEaseOut
            leg.run(SKAction.repeatForever(SKAction.sequence([l1, l2])), withKey: "leg_trail")
        }
    }

    private func startStartledMotion() {
        let squash = SKAction.group([
            SKAction.scaleX(to: 0.84, duration: 0.06),
            SKAction.scaleY(to: 1.24, duration: 0.06)
        ])
        let stretch = SKAction.group([
            SKAction.scaleX(to: 1.15, duration: 0.08),
            SKAction.scaleY(to: 0.88, duration: 0.08)
        ])
        let norm = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.08),
            SKAction.scaleY(to: 1.0, duration: 0.08)
        ])
        let shake = SKAction.sequence([
            SKAction.rotate(toAngle: 0.22, duration: 0.05),
            SKAction.rotate(toAngle: -0.22, duration: 0.06),
            SKAction.rotate(toAngle: 0.14, duration: 0.06),
            SKAction.rotate(toAngle: 0.0, duration: 0.06)
        ])
        bodyRigNode.run(SKAction.group([SKAction.sequence([squash, stretch, norm]), shake]), withKey: "body_startled")
    }

    private func startCollectingSparkles(in worldNode: SKNode, duration: TimeInterval) {
        let sparkCount = max(3, Int(duration / 0.55))
        for i in 0..<sparkCount {
            let delay = Double(i) * (duration / Double(sparkCount))
            let spawn = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self, weak worldNode] in
                    guard let self, let worldNode, self.flightState == .collecting else { return }
                    let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.8...3.2))
                    dot.fillColor = [
                        UIColor(red: 1.0, green: 0.86, blue: 0.22, alpha: 0.95),
                        UIColor(red: 1.0, green: 0.96, blue: 0.62, alpha: 0.95),
                        UIColor(red: 1.0, green: 0.68, blue: 0.18, alpha: 0.90)
                    ].randomElement()!
                    dot.strokeColor = .clear
                    dot.position = CGPoint(
                        x: self.position.x + CGFloat.random(in: -12...12),
                        y: self.position.y + CGFloat.random(in: -8...8)
                    )
                    dot.zPosition = self.zPosition - 1
                    worldNode.addChild(dot)

                    let floatUp = SKAction.moveBy(
                        x: CGFloat.random(in: -10...10),
                        y: CGFloat.random(in: 14...28),
                        duration: 0.65
                    )
                    floatUp.timingMode = .easeOut
                    dot.run(SKAction.sequence([
                        SKAction.group([floatUp, SKAction.fadeOut(withDuration: 0.65)]),
                        SKAction.removeFromParent()
                    ]))
                }
            ])
            run(spawn)
        }
    }

    // MARK: - Exact SVG Assembly Specs (bee1..bee4)

    private static func specs(for variant: BeeVariant) -> [BeePartSpec] {
        switch variant {
        case .bee1:
            return [
                BeePartSpec(imageName: "bee1-3@2.083x", svgX: 26.55, svgY: 197.04, svgW: 304.88, svgH: 310.13, anchorX: 0.90, anchorY: 0.08, zPosition: 3, role: .backWing),
                BeePartSpec(imageName: "bee1-2@2.083x", svgX: 372.12, svgY: 0.00, svgW: 160.92, svgH: 396.84, anchorX: 0.35, anchorY: 0.05, zPosition: 4, role: .backWing),
                BeePartSpec(imageName: "bee1-1@2.083x", svgX: 99.10, svgY: 300.62, svgW: 1050.31, svgH: 946.87, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .body),
                BeePartSpec(imageName: "bee1-12@2.083x", svgX: 106.70, svgY: 1109.87, svgW: 171.78, svgH: 77.06, anchorX: 0.92, anchorY: 0.90, zPosition: 11, role: .leg),
                BeePartSpec(imageName: "bee1-11@2.083x", svgX: 306.32, svgY: 1092.27, svgW: 195.87, svgH: 167.75, anchorX: 0.92, anchorY: 0.92, zPosition: 12, role: .leg),
                BeePartSpec(imageName: "bee1-4@2.083x", svgX: 744.25, svgY: 630.56, svgW: 85.24, svgH: 53.40, anchorX: 0.50, anchorY: 0.50, zPosition: 15, role: .mouth),
                BeePartSpec(imageName: "bee1-6@2.083x", svgX: 0.00, svgY: 260.50, svgW: 311.13, svgH: 303.53, anchorX: 0.90, anchorY: 0.12, zPosition: 15, role: .frontWing),
                BeePartSpec(imageName: "bee1-5@2.083x", svgX: 170.55, svgY: 31.31, svgW: 233.20, svgH: 471.08, anchorX: 0.85, anchorY: 0.05, zPosition: 16, role: .frontWing),
                BeePartSpec(imageName: "bee1-9@2.083x", svgX: 603.09, svgY: 95.07, svgW: 216.61, svgH: 379.78, anchorX: 0.12, anchorY: 0.04, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee1-10@2.083x", svgX: 751.33, svgY: 196.44, svgW: 300.34, svgH: 166.68, anchorX: 0.08, anchorY: 0.05, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee1-7@2.083x", svgX: 462.64, svgY: 672.14, svgW: 203.66, svgH: 129.97, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee1-8@2.083x", svgX: 867.01, svgY: 523.88, svgW: 191.24, svgH: 148.00, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee1-13@2.083x", svgX: 1009.08, svgY: 739.77, svgW: 182.10, svgH: 128.87, anchorX: 0.85, anchorY: 0.85, zPosition: 20, role: .arm),
                BeePartSpec(imageName: "bee1-14@2.083x", svgX: 616.07, svgY: 951.47, svgW: 263.48, svgH: 100.42, anchorX: 0.08, anchorY: 0.25, zPosition: 20, role: .arm)
            ]

        case .bee2:
            return [
                BeePartSpec(imageName: "bee2-4@2.083x", svgX: 780.78, svgY: 132.63, svgW: 282.47, svgH: 346.52, anchorX: 0.12, anchorY: 0.08, zPosition: 3, role: .backWing),
                BeePartSpec(imageName: "bee2-3@2.083x", svgX: 633.23, svgY: 0.00, svgW: 165.58, svgH: 408.43, anchorX: 0.40, anchorY: 0.05, zPosition: 4, role: .backWing),
                BeePartSpec(imageName: "bee2-5@2.083x", svgX: 1151.38, svgY: 836.15, svgW: 78.91, svgH: 54.63, anchorX: 0.15, anchorY: 0.50, zPosition: 8, role: .stinger),
                BeePartSpec(imageName: "bee2-1@2.083x", svgX: 82.32, svgY: 324.39, svgW: 1092.41, svgH: 927.02, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .body),
                BeePartSpec(imageName: "bee2-15@2.083x", svgX: 1067.38, svgY: 902.02, svgW: 193.01, svgH: 68.39, anchorX: 0.08, anchorY: 0.85, zPosition: 11, role: .leg),
                BeePartSpec(imageName: "bee2-14@2.083x", svgX: 952.07, svgY: 1031.35, svgW: 268.42, svgH: 83.36, anchorX: 0.08, anchorY: 0.88, zPosition: 12, role: .leg),
                BeePartSpec(imageName: "bee2-6@2.083x", svgX: 409.06, svgY: 729.15, svgW: 111.25, svgH: 80.65, anchorX: 0.50, anchorY: 0.50, zPosition: 15, role: .mouth),
                BeePartSpec(imageName: "bee2-12@2.083x", svgX: 821.68, svgY: 177.44, svgW: 290.57, svgH: 251.29, anchorX: 0.12, anchorY: 0.12, zPosition: 15, role: .frontWing),
                BeePartSpec(imageName: "bee2-13@2.083x", svgX: 761.85, svgY: 51.02, svgW: 174.16, svgH: 335.88, anchorX: 0.12, anchorY: 0.06, zPosition: 16, role: .frontWing),
                BeePartSpec(imageName: "bee2-10@2.083x", svgX: 624.72, svgY: 217.85, svgW: 132.88, svgH: 229.99, anchorX: 0.10, anchorY: 0.05, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee2-11@2.083x", svgX: 367.48, svgY: 186.21, svgW: 60.58, svgH: 254.17, anchorX: 0.70, anchorY: 0.05, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee2-7@2.083x", svgX: 136.84, svgY: 528.80, svgW: 203.93, svgH: 240.81, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee2-8@2.083x", svgX: 632.07, svgY: 625.16, svgW: 199.20, svgH: 246.81, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee2-9@2.083x", svgX: 197.49, svgY: 283.94, svgW: 181.40, svgH: 207.74, anchorX: 0.50, anchorY: 0.50, zPosition: 19, role: .flower),
                BeePartSpec(imageName: "bee2-2@2.083x", svgX: 0.00, svgY: 873.23, svgW: 263.90, svgH: 149.04, anchorX: 0.92, anchorY: 0.85, zPosition: 20, role: .arm),
                BeePartSpec(imageName: "bee2-16@2.083x", svgX: 451.56, svgY: 1011.58, svgW: 263.90, svgH: 148.81, anchorX: 0.92, anchorY: 0.85, zPosition: 20, role: .arm)
            ]

        case .bee3:
            return [
                BeePartSpec(imageName: "bee3-3@2.083x", svgX: 38.76, svgY: 347.83, svgW: 405.82, svgH: 312.49, anchorX: 0.90, anchorY: 0.12, zPosition: 3, role: .backWing),
                BeePartSpec(imageName: "bee3-2@2.083x", svgX: 297.39, svgY: 97.78, svgW: 240.81, svgH: 445.21, anchorX: 0.85, anchorY: 0.06, zPosition: 4, role: .backWing),
                BeePartSpec(imageName: "bee3-9@2.083x", svgX: 388.85, svgY: 1173.59, svgW: 42.05, svgH: 84.03, anchorX: 0.65, anchorY: 0.85, zPosition: 8, role: .stinger),
                BeePartSpec(imageName: "bee3-1@2.083x", svgX: 308.68, svgY: 282.61, svgW: 1029.23, svgH: 1043.40, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .body),
                BeePartSpec(imageName: "bee3-11@2.083x", svgX: 474.10, svgY: 1147.59, svgW: 116.60, svgH: 215.48, anchorX: 0.85, anchorY: 0.92, zPosition: 11, role: .leg),
                BeePartSpec(imageName: "bee3-10@2.083x", svgX: 714.85, svgY: 1106.75, svgW: 116.60, svgH: 266.10, anchorX: 0.85, anchorY: 0.92, zPosition: 12, role: .leg),
                BeePartSpec(imageName: "bee3-6@2.083x", svgX: 999.23, svgY: 456.25, svgW: 76.94, svgH: 66.63, anchorX: 0.50, anchorY: 0.50, zPosition: 15, role: .mouth),
                BeePartSpec(imageName: "bee3-14@2.083x", svgX: 0.00, svgY: 435.87, svgW: 453.53, svgH: 229.95, anchorX: 0.92, anchorY: 0.18, zPosition: 15, role: .frontWing),
                BeePartSpec(imageName: "bee3-15@2.083x", svgX: 165.83, svgY: 192.99, svgW: 346.64, svgH: 379.12, anchorX: 0.90, anchorY: 0.08, zPosition: 16, role: .frontWing),
                BeePartSpec(imageName: "bee3-12@2.083x", svgX: 917.82, svgY: 0.00, svgW: 192.44, svgH: 337.40, anchorX: 0.10, anchorY: 0.04, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee3-13@2.083x", svgX: 622.62, svgY: 78.79, svgW: 104.44, svgH: 372.04, anchorX: 0.45, anchorY: 0.04, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee3-4@2.083x", svgX: 741.17, svgY: 499.98, svgW: 207.48, svgH: 203.12, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee3-5@2.083x", svgX: 1079.04, svgY: 339.87, svgW: 165.03, svgH: 161.58, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee3-7@2.083x", svgX: 1213.61, svgY: 666.26, svgW: 161.80, svgH: 114.25, anchorX: 0.10, anchorY: 0.35, zPosition: 20, role: .arm),
                BeePartSpec(imageName: "bee3-8@2.083x", svgX: 935.98, svgY: 826.50, svgW: 190.78, svgH: 188.62, anchorX: 0.12, anchorY: 0.18, zPosition: 20, role: .arm)
            ]

        case .bee4:
            return [
                BeePartSpec(imageName: "bee4-3@2.083x", svgX: 979.29, svgY: 0.00, svgW: 190.29, svgH: 469.14, anchorX: 0.45, anchorY: 0.04, zPosition: 3, role: .backWing),
                BeePartSpec(imageName: "bee4-2@2.083x", svgX: 1070.28, svgY: 49.72, svgW: 207.82, svgH: 410.69, anchorX: 0.15, anchorY: 0.05, zPosition: 4, role: .backWing),
                BeePartSpec(imageName: "bee4-9@2.083x", svgX: 1566.26, svgY: 934.42, svgW: 87.59, svgH: 60.69, anchorX: 0.15, anchorY: 0.50, zPosition: 8, role: .stinger),
                BeePartSpec(imageName: "bee4-1@2.083x", svgX: 424.15, svgY: 389.31, svgW: 1159.32, svgH: 934.87, anchorX: 0.50, anchorY: 0.50, zPosition: 10, role: .body),
                BeePartSpec(imageName: "bee4-16@2.083x", svgX: 1478.79, svgY: 1030.64, svgW: 225.50, svgH: 117.07, anchorX: 0.08, anchorY: 0.88, zPosition: 11, role: .leg),
                BeePartSpec(imageName: "bee4-15@2.083x", svgX: 1176.88, svgY: 1149.23, svgW: 347.97, svgH: 168.19, anchorX: 0.08, anchorY: 0.90, zPosition: 12, role: .leg),
                BeePartSpec(imageName: "bee4-6@2.083x", svgX: 652.51, svgY: 684.38, svgW: 98.95, svgH: 45.73, anchorX: 0.50, anchorY: 0.50, zPosition: 15, role: .mouth),
                BeePartSpec(imageName: "bee4-4@2.083x", svgX: 1223.30, svgY: 285.89, svgW: 383.90, svgH: 256.93, anchorX: 0.08, anchorY: 0.12, zPosition: 15, role: .frontWing),
                BeePartSpec(imageName: "bee4-5@2.083x", svgX: 1159.77, svgY: 97.28, svgW: 311.09, svgH: 406.59, anchorX: 0.12, anchorY: 0.06, zPosition: 16, role: .frontWing),
                BeePartSpec(imageName: "bee4-13@2.083x", svgX: 852.80, svgY: 259.47, svgW: 147.25, svgH: 258.50, anchorX: 0.12, anchorY: 0.04, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee4-14@2.083x", svgX: 627.04, svgY: 256.05, svgW: 147.25, svgH: 258.49, anchorX: 0.12, anchorY: 0.04, zPosition: 17, role: .antenna),
                BeePartSpec(imageName: "bee4-7@2.083x", svgX: 451.56, svgY: 584.76, svgW: 166.70, svgH: 167.41, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee4-8@2.083x", svgX: 855.14, svgY: 653.40, svgW: 192.00, svgH: 193.07, anchorX: 0.50, anchorY: 0.50, zPosition: 18, role: .eye),
                BeePartSpec(imageName: "bee4-10@2.083x", svgX: 0.00, svgY: 927.30, svgW: 998.86, svgH: 345.94, anchorX: 0.75, anchorY: 0.35, zPosition: 19, role: .flower),
                BeePartSpec(imageName: "bee4-11@2.083x", svgX: 342.28, svgY: 909.87, svgW: 124.82, svgH: 151.60, anchorX: 0.90, anchorY: 0.85, zPosition: 20, role: .arm),
                BeePartSpec(imageName: "bee4-12@2.083x", svgX: 701.61, svgY: 1014.49, svgW: 248.12, svgH: 109.42, anchorX: 0.90, anchorY: 0.45, zPosition: 20, role: .arm)
            ]
        }
    }
}

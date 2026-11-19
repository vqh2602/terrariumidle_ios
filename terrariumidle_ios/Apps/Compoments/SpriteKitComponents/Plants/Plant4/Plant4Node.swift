//
//  Plant4Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cây Ráy Alocasia Morocco (Plant4)

public enum Plant4GrowthState: Equatable {
    case seed
    case sprout
    case mature(level: Int)

    public init(level: Int) {
        switch level {
        case 1, 100:
            self = .seed
        case 2, 200:
            self = .sprout
        default:
            self = .mature(level: max(3, level))
        }
    }

    public var rawLevel: Int {
        switch self {
        case .seed: return 1
        case .sprout: return 2
        case .mature(let lvl): return lvl
        }
    }

    public var title: String {
        switch self {
        case .seed: return "Gieo hạt (Lv.1)"
        case .sprout: return "Cây con (Lv.2)"
        case .mature(let lvl): return "Trưởng thành (Lv.\(lvl))"
        }
    }
}

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant4

public final class Plant4Node: SKNode {

    // MARK: - Metadata cấu trúc 8 phiến lá & cuống Alocasia Morocco (Canvas 723 x 737)

    private struct LeafData {
        let assetId: Int
        let imgX: CGFloat
        let imgY: CGFloat
        let width: CGFloat
        let height: CGFloat
        let anchorX: CGFloat
        let anchorY: CGFloat
        let isLeft: Bool
        let zPos: CGFloat
        let bendAngle: CGFloat
        let duration: TimeInterval
    }

    /// Tọa độ pixel và điểm neo cuống lá Alocasia Morocco (Canvas 723 x 737)
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 1, imgX: 506, imgY: 182, width:  83, height: 141, anchorX: 0.17, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: 0.035, duration: 2.6),
        LeafData(assetId: 2, imgX: 357, imgY:  41, width: 346, height: 458, anchorX: 0.46, anchorY: 0.00, isLeft: true,  zPos: 12, bendAngle: 0.040, duration: 2.8),
        LeafData(assetId: 3, imgX: 365, imgY: 259, width: 179, height: 245, anchorX: 0.68, anchorY: 0.00, isLeft: false, zPos: 13, bendAngle: 0.045, duration: 3.0),
        LeafData(assetId: 4, imgX: 379, imgY: 422, width: 254, height: 315, anchorX: 0.54, anchorY: 0.00, isLeft: false, zPos: 14, bendAngle: 0.050, duration: 3.2),
        LeafData(assetId: 5, imgX: 112, imgY:  28, width: 289, height: 685, anchorX: 0.59, anchorY: 0.00, isLeft: false, zPos: 15, bendAngle: 0.035, duration: 3.4),
        LeafData(assetId: 6, imgX: 342, imgY: 108, width: 186, height: 319, anchorX: 0.11, anchorY: 0.00, isLeft: true,  zPos: 16, bendAngle: 0.040, duration: 2.6),
        LeafData(assetId: 7, imgX:   1, imgY:   0, width: 347, height: 499, anchorX: 0.53, anchorY: 0.00, isLeft: false, zPos: 17, bendAngle: 0.045, duration: 2.8),
        LeafData(assetId: 8, imgX: 171, imgY:  14, width: 201, height: 486, anchorX: 0.68, anchorY: 0.00, isLeft: false, zPos: 18, bendAngle: 0.050, duration: 3.0),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant4GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant4GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant4GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant4GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant4GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    // MARK: - Build Scene theo trạng thái

    public func build() {
        plantRootNode.removeAllChildren()
        plantRootNode.removeAllActions()
        leafNodes.removeAll()
        seedNode = nil
        sproutNode = nil

        self.isPaused = false
        self.speed = 1.0
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        switch growthState {
        case .seed:
            buildSeedState()
        case .sprout:
            buildSproutState()
        case .mature(let level):
            buildMatureState(level: level)
        }
    }

    // MARK: - State 100: Hạt giống (Tái sử dụng ánh xạ chuẩn từ Plant1)

    private func buildSeedState() {
        plantRootNode.setScale(1.0)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height * 0.70 : 0)
        self.baseScale = 1.0

        guard let seedTexture = loadTexture(assetId: 100) else { return }

        let targetW = containerSize.width * 0.20
        let aspect: CGFloat = 257.0 / 259.0
        let targetH = targetW * aspect

        let node = SKSpriteNode(texture: seedTexture)
        node.size = CGSize(width: targetW, height: targetH)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        let seedY: CGFloat = isHanging ? containerSize.height * 0.70 : containerSize.height * 0.08
        node.position = CGPoint(x: 0, y: seedY)
        node.zPosition = 10
        node.isPaused = false
        node.speed = 1.0

        plantRootNode.addChild(node)
        self.seedNode = node
        self.initialSeedPosition = node.position

        let breatheIn = SKAction.scaleX(to: 1.10, y: 0.90, duration: 1.0)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scaleX(to: 0.92, y: 1.08, duration: 1.0)
        breatheOut.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut])), withKey: "seedBreath")

        let tiltL = SKAction.rotate(toAngle: -0.08, duration: 1.2)
        tiltL.timingMode = .easeInEaseOut
        let tiltR = SKAction.rotate(toAngle: 0.08, duration: 1.2)
        tiltR.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([tiltL, tiltR])), withKey: "seedWiggle")

        startSeedGlowEffect(on: node, radius: targetW * 0.45)
    }

    private func startSeedGlowEffect(on node: SKNode, radius: CGFloat = 14) {
        let glowNode = SKShapeNode(circleOfRadius: radius)
        glowNode.fillColor = UIColor(red: 0.35, green: 0.92, blue: 0.60, alpha: 0.28)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: radius * 0.6)
        glowNode.zPosition = -1
        glowNode.name = "seedGlowNode"
        node.addChild(glowNode)

        let glowUp = SKAction.group([
            SKAction.fadeAlpha(to: 0.55, duration: 1.4),
            SKAction.scale(to: 1.25, duration: 1.4)
        ])
        glowUp.timingMode = .easeInEaseOut

        let glowDown = SKAction.group([
            SKAction.fadeAlpha(to: 0.18, duration: 1.4),
            SKAction.scale(to: 0.88, duration: 1.4)
        ])
        glowDown.timingMode = .easeInEaseOut

        glowNode.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])), withKey: "seedGlowPulse")
    }

    // MARK: - State 200: Cây con (Tái sử dụng ánh xạ chuẩn từ Plant1)

    private func buildSproutState() {
        plantRootNode.setScale(1.0)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height * 0.70 : 0)
        self.baseScale = 1.0

        guard let sproutTexture = loadTexture(assetId: 200) else { return }

        let targetH = containerSize.height * 0.38
        let aspect: CGFloat = 235.0 / 253.0
        let targetW = min(targetH * aspect, containerSize.width * 0.42)

        let node = SKSpriteNode(texture: sproutTexture)
        node.size = CGSize(width: targetW, height: targetH)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        let sproutY: CGFloat = isHanging ? containerSize.height * 0.70 : containerSize.height * 0.08
        node.position = CGPoint(x: 0, y: sproutY)
        node.zPosition = 10
        node.isPaused = false
        node.speed = 1.0

        plantRootNode.addChild(node)
        self.sproutNode = node
        self.initialSproutPosition = node.position

        let swayLeft = SKAction.rotate(toAngle: -0.06, duration: 1.8)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.06, duration: 1.8)
        swayRight.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])), withKey: "sproutSway")

        let bobUp = SKAction.scaleY(to: 1.05, duration: 1.5)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.scaleY(to: 0.95, duration: 1.5)
        bobDown.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "sproutBob")

        startSproutGlowEffect(on: node, radius: targetW * 0.45, targetH: targetH)
    }

    private func startSproutGlowEffect(on node: SKNode, radius: CGFloat = 16, targetH: CGFloat = 50) {
        let glowNode = SKShapeNode(circleOfRadius: radius)
        glowNode.fillColor = UIColor(red: 0.40, green: 0.92, blue: 0.65, alpha: 0.22)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: targetH * 0.52)
        glowNode.zPosition = -1
        glowNode.name = "sproutGlowNode"
        node.addChild(glowNode)

        let glowUp = SKAction.group([
            SKAction.fadeAlpha(to: 0.48, duration: 1.6),
            SKAction.scale(to: 1.20, duration: 1.6)
        ])
        glowUp.timingMode = .easeInEaseOut

        let glowDown = SKAction.group([
            SKAction.fadeAlpha(to: 0.12, duration: 1.6),
            SKAction.scale(to: 0.90, duration: 1.6)
        ])
        glowDown.timingMode = .easeInEaseOut

        glowNode.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])), withKey: "sproutGlowPulse")
    }

    // MARK: - SKS Scene Loader (Hybrid Visual Architecture)

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Plant4Scene") {
            return scene
        }
        return nil
    }

    // MARK: - State Level 3+: Cây trưởng thành Alocasia Morocco

    private func buildMatureState(level: Int) {
        let growthRatio: CGFloat = 0.88 + (CGFloat(max(3, min(10, level)) - 3) / 7.0) * 0.12

        let baseCanvasWidth: CGFloat = 723.0
        let baseCanvasHeight: CGFloat = 737.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        let scale = min(fitW, fitH) * growthRatio
        self.baseScale = scale

        plantRootNode.setScale(scale)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height : 0)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Đọc trực tiếp từ file Plant4Scene.sks
        if let scene = loadSceneTemplate(),
           let matureGroup = scene.childNode(withName: "matureNode"),
           !matureGroup.children.isEmpty {

            matureGroup.removeFromParent()
            matureGroup.isHidden = false
            matureGroup.isPaused = false
            matureGroup.speed = 1.0
            plantRootNode.addChild(matureGroup)

            let sortedLeaves = matureGroup.children.compactMap { $0 as? SKSpriteNode }.sorted {
                let id1 = Int($0.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let id2 = Int($1.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                return id1 < id2
            }

            for (idx, leaf) in sortedLeaves.enumerated() {
                let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                if leaf.texture == nil {
                    leaf.texture = loadTexture(assetId: assetNum)
                }
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leafNodes.append(leaf)

                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                let bendAngle = meta?.bendAngle ?? 0.040
                let duration = meta?.duration ?? 3.0
                let phaseDelay = Double(idx) * 0.15

                startLeafBendingAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay)
            }

            addTrunkSwayAnimation()
            return
        }

        // 2. Fallback procedural: Sinh 8 phiến lá từ metadata
        for (idx, data) in Self.leavesMetadata.enumerated() {
            guard let leafTexture = loadTexture(assetId: data.assetId) else { continue }

            let leaf = SKSpriteNode(texture: leafTexture)
            leaf.name = "leaf_\(data.assetId)"
            leaf.size = CGSize(width: data.width, height: data.height)
            leaf.anchorPoint = CGPoint(x: data.anchorX, y: data.anchorY)

            let skX = (data.imgX + data.anchorX * data.width) - (baseCanvasWidth / 2.0)
            let skY = baseCanvasHeight - data.imgY - (1.0 - data.anchorY) * data.height - 10.0

            leaf.position = CGPoint(x: skX, y: skY)
            leaf.zPosition = data.zPos
            leaf.isPaused = false
            leaf.speed = 1.0

            plantRootNode.addChild(leaf)
            leafNodes.append(leaf)

            let phaseDelay = Double(idx) * 0.15
            startLeafBendingAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: phaseDelay)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        plantRootNode.removeAction(forKey: "trunkSway")
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        let trunkSwayLeft = SKAction.rotate(toAngle: -0.024, duration: 3.5)
        trunkSwayLeft.timingMode = .easeInEaseOut
        let trunkSwayRight = SKAction.rotate(toAngle: 0.024, duration: 3.5)
        trunkSwayRight.timingMode = .easeInEaseOut
        plantRootNode.run(SKAction.repeatForever(SKAction.sequence([trunkSwayLeft, trunkSwayRight])), withKey: "trunkSway")
    }

    // MARK: - Animation: Phiến lá cứng cáp uốn lượn theo gió

    private func startLeafBendingAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval = 0.0) {
        leaf.removeAction(forKey: "leafBend")
        leaf.isPaused = false
        leaf.speed = 1.0

        let angleDelta = isLeft ? -bendAngle : bendAngle

        let bendForward = SKAction.rotate(byAngle: angleDelta, duration: duration * 0.5)
        bendForward.timingMode = .easeInEaseOut
        let bendBack = SKAction.rotate(byAngle: -angleDelta, duration: duration * 0.5)
        bendBack.timingMode = .easeInEaseOut

        let swayCycle = SKAction.sequence([bendForward, bendBack])
        let pulseUp = SKAction.scaleY(to: 1.025, duration: duration * 0.48)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scaleY(to: 0.985, duration: duration * 0.52)
        pulseDown.timingMode = .easeInEaseOut
        let breatheCycle = SKAction.sequence([pulseUp, pulseDown])

        let combined = SKAction.group([swayCycle, breatheCycle])

        if phaseDelay > 0 {
            let delayAction = SKAction.wait(forDuration: phaseDelay)
            let fullSequence = SKAction.sequence([delayAction, SKAction.repeatForever(combined)])
            leaf.run(fullSequence, withKey: "leafBend")
        } else {
            leaf.run(SKAction.repeatForever(combined), withKey: "leafBend")
        }
    }

    // MARK: - Tap Interaction

    public func playTapAnimation() {
        spawnOxygenBubbles()

        switch growthState {
        case .seed:
            playSeedTapAnimation()
        case .sprout:
            playSproutTapAnimation()
        case .mature:
            playMatureTapAnimation()
        }
    }

    private func playSeedTapAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedTapHop")
        node.position = initialSeedPosition
        node.setScale(1.0)

        let squash = SKAction.scaleX(to: 1.30, y: 0.70, duration: 0.07)
        squash.timingMode = .easeIn
        let jumpUp = SKAction.group([
            SKAction.moveTo(y: initialSeedPosition.y + 14, duration: 0.12),
            SKAction.scaleX(to: 0.85, y: 1.25, duration: 0.12)
        ])
        jumpUp.timingMode = .easeOut
        let fallDown = SKAction.group([
            SKAction.moveTo(y: initialSeedPosition.y, duration: 0.12),
            SKAction.scaleX(to: 1.12, y: 0.90, duration: 0.12)
        ])
        fallDown.timingMode = .easeIn
        let settle = SKAction.scale(to: 1.0, duration: 0.10)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([squash, jumpUp, fallDown, settle]), withKey: "seedTapHop")

        if let glow = node.childNode(withName: "seedGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.08),
                SKAction.fadeAlpha(to: 0.28, duration: 0.25)
            ])
            glow.run(flash)
        }
    }

    private func playSproutTapAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutTapBounce")
        node.position = initialSproutPosition
        node.zRotation = 0

        let squash = SKAction.scaleX(to: 1.26, y: 0.74, duration: 0.08)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: 0.84, y: 1.22, duration: 0.12)
        stretch.timingMode = .easeOut
        let bounceBack = SKAction.scaleX(to: 1.08, y: 0.94, duration: 0.10)
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeInEaseOut

        let shakeL = SKAction.rotate(toAngle: -0.15, duration: 0.07)
        let shakeR = SKAction.rotate(toAngle: 0.15, duration: 0.08)
        let shakeBack = SKAction.rotate(toAngle: 0, duration: 0.07)
        let shakeSeq = SKAction.sequence([shakeL, shakeR, shakeBack])

        let combined = SKAction.group([
            SKAction.sequence([squash, stretch, bounceBack, settle]),
            shakeSeq
        ])

        node.run(combined, withKey: "sproutTapBounce")

        if let glow = node.childNode(withName: "sproutGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.75, duration: 0.08),
                SKAction.fadeAlpha(to: 0.22, duration: 0.25)
            ])
            glow.run(flash)
        }
    }

    private func playMatureTapAnimation() {
        plantRootNode.removeAction(forKey: "matureTapBounce")

        let squash = SKAction.scaleX(to: baseScale * 1.12, y: baseScale * 0.88, duration: 0.08)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: baseScale * 0.92, y: baseScale * 1.12, duration: 0.12)
        stretch.timingMode = .easeOut
        let bounce = SKAction.scaleX(to: baseScale * 1.04, y: baseScale * 0.97, duration: 0.10)
        let settle = SKAction.scale(to: baseScale, duration: 0.10)
        settle.timingMode = .easeInEaseOut

        plantRootNode.run(SKAction.sequence([squash, stretch, bounce, settle]), withKey: "matureTapBounce")

        for (idx, leaf) in leafNodes.enumerated() {
            let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
            let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
            let impulseAngle: CGFloat = (isLeft ? -1.0 : 1.0) * CGFloat.random(in: 0.06...0.10)

            let delay = SKAction.wait(forDuration: Double(idx) * 0.02)
            let jiggleOut = SKAction.rotate(byAngle: impulseAngle, duration: 0.07)
            jiggleOut.timingMode = .easeOut
            let jiggleBack = SKAction.rotate(byAngle: -impulseAngle, duration: 0.11)
            jiggleBack.timingMode = .easeInEaseOut

            leaf.run(SKAction.sequence([delay, jiggleOut, jiggleBack]))
        }
    }

    private func spawnOxygenBubbles() {
        let bubbleCount: Int
        switch growthState {
        case .seed: bubbleCount = Int.random(in: 1...2)
        case .sprout: bubbleCount = Int.random(in: 3...4)
        case .mature: bubbleCount = Int.random(in: 8...12)
        }

        for i in 0..<bubbleCount {
            let radius: CGFloat
            let spawnX: CGFloat
            let spawnY: CGFloat
            let floatDistance: CGFloat

            switch growthState {
            case .seed:
                radius = CGFloat.random(in: 1.8...3.0)
                spawnX = CGFloat.random(in: -containerSize.width * 0.08...containerSize.width * 0.08)
                spawnY = CGFloat.random(in: containerSize.height * 0.03...containerSize.height * 0.12)
                floatDistance = CGFloat.random(in: 18...35)
            case .sprout:
                radius = CGFloat.random(in: 2.2...3.8)
                spawnX = CGFloat.random(in: -containerSize.width * 0.10...containerSize.width * 0.10)
                spawnY = CGFloat.random(in: containerSize.height * 0.05...containerSize.height * 0.20)
                floatDistance = CGFloat.random(in: 25...45)
            case .mature:
                radius = CGFloat.random(in: 3.5...7.5)
                floatDistance = CGFloat.random(in: 60...115)
                if !leafNodes.isEmpty && Bool.random() {
                    let randomLeaf = leafNodes.randomElement()!
                    spawnX = randomLeaf.position.x + CGFloat.random(in: -16...16)
                    spawnY = max(containerSize.height * 0.18, min(containerSize.height * 0.90, randomLeaf.position.y + CGFloat.random(in: -10...20)))
                } else {
                    spawnX = CGFloat.random(in: -containerSize.width * 0.44...containerSize.width * 0.44)
                    spawnY = CGFloat.random(in: containerSize.height * 0.18...containerSize.height * 0.88)
                }
            }

            let bubble = SKShapeNode(circleOfRadius: radius)
            bubble.fillColor = UIColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 0.85)
            bubble.strokeColor = UIColor.white.withAlphaComponent(0.7)
            bubble.lineWidth = 1.0

            let highlight = SKShapeNode(circleOfRadius: radius * 0.3)
            highlight.fillColor = UIColor.white.withAlphaComponent(0.8)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -radius * 0.3, y: radius * 0.3)
            bubble.addChild(highlight)

            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 100
            bubble.alpha = 0.0
            addChild(bubble)

            let floatDuration = Double.random(in: 0.8...1.5)
            let driftX = CGFloat.random(in: -18...18)
            let delay = SKAction.wait(forDuration: Double(i) * 0.04)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.12)
            let floatUp = SKAction.moveBy(x: driftX, y: floatDistance, duration: floatDuration)
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: floatDuration * 0.6)
            let scaleUp = SKAction.scale(by: 1.30, duration: floatDuration)

            let motionGroup = SKAction.group([
                floatUp,
                SKAction.sequence([SKAction.wait(forDuration: floatDuration * 0.4), fadeOut]),
                scaleUp
            ])

            bubble.run(SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Texture Loader

    private func loadTexture(assetId: Int) -> SKTexture? {
        if assetId == 100 {
            return loadTextureByName("plant1_Asset-100@4.167x") ??
                   loadTextureByName("plant1_Asset-1@4.167x")
        }
        if assetId == 200 {
            return loadTextureByName("plant1_Asset-200@4.167x") ??
                   loadTextureByName("plant1_Asset-2@4.167x")
        }

        let names = [
            "Plant4-\(assetId)@4.167x",
            "Plant4-\(assetId)",
            "plant4_Asset-\(assetId)@4.167x",
            "plant4_Asset-\(assetId)",
            "Plant4/Plant4-\(assetId)@4.167x",
            "plant4/Plant4-\(assetId)@4.167x"
        ]

        for name in names {
            if let texture = loadTextureByName(name) {
                return texture
            }
        }
        return nil
    }

    private func loadTextureByName(_ name: String) -> SKTexture? {
        if let image = UIImage(named: name) {
            return SKTexture(image: image)
        }
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return SKTexture(image: image)
            }
        }
        return nil
    }
}

//
//  Plant17Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cúc tần Ấn Độ (Plant17 - Vernonia elliptica)

public enum Plant17GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant17

public final class Plant17Node: SKNode {

    // MARK: - Metadata cấu trúc dải cành lá Cúc tần Ấn Độ Vernonia elliptica (Canvas 611 x 858)

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
        let shouldSway: Bool
    }

    /// Tọa độ pixel và phân tách cấu trúc 2 phần của Cúc tần Ấn Độ:
    /// - assetId 1 (Crown / Thân bụi trên miệng chậu): shouldSway = false -> Cố định trên miệng chậu, KHÔNG đung đưa theo gió!
    /// - assetId 2 (Vines / Cành rủ buông dài): shouldSway = true -> Đung đưa mềm mại theo gió.
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 1, imgX: 0.0, imgY: -104.0, width: 611, height: 274, anchorX: 0.50, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: 0.0,   duration: 0.0, shouldSway: false),
        LeafData(assetId: 2, imgX: 0.0, imgY:  -53.0, width: 611, height: 635, anchorX: 0.50, anchorY: 1.00, isLeft: false, zPos: 12, bendAngle: 0.048, duration: 3.8, shouldSway: true),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant17GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = true

    /// Danh sách các hiệu ứng thị giác khi tap vào cây (mặc định Bọt khí Oxy Emerald)
    /// Hiệu ứng chuyển động rung lắc / nảy cành lá khi tap vào cây (mặc định: CascadingVineMotionEffect)
    public var motionEffect: PlantMotionEffect = CascadingVineMotionEffect()

    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .emerald)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant17GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = true) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        buildPlant()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = true) {
        self.init(growthState: Plant17GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
        buildPlant()
    }

    // MARK: - Configuration

    public func configure(growthState: Plant17GrowthState, containerSize: CGSize? = nil, isHanging: Bool? = nil) {
        self.growthState = growthState
        if let containerSize = containerSize { self.containerSize = containerSize }
        if let isHanging = isHanging { self.isHanging = isHanging }
        buildPlant()
    }

    public func configure(level: Int, containerSize: CGSize? = nil, isHanging: Bool? = nil) {
        configure(growthState: Plant17GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    // MARK: - Plant Builder

    private func buildPlant() {
        plantRootNode.removeAllChildren()
        plantRootNode.removeAllActions()
        leafNodes.removeAll()
        seedNode = nil
        sproutNode = nil

        self.isPaused = false
        self.speed = 1.0
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        switch growthState {
        case .seed:
            buildSeedState()
        case .sprout:
            buildSproutState()
        case .mature(let level):
            buildMatureState(level: level)
        }
    }

    // MARK: - Level 1: Gieo hạt (Seed)

    private func buildSeedState() {
        let baseCanvasWidth: CGFloat = 611.0
        let baseCanvasHeight: CGFloat = 858.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.08
        plantRootNode.setScale(baseScale)

        // 1. Ưu tiên nạp từ Plant17Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSeedNode = scene.childNode(withName: "seedNode") {
            templateSeedNode.removeFromParent()
            templateSeedNode.position = .zero

            let seedSprite = templateSeedNode.childNode(withName: "seedSprite") as? SKSpriteNode
            if let sprite = seedSprite {
                if sprite.texture == nil {
                    sprite.texture = loadTexture(assetId: 100)
                }
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.initialSeedPosition = sprite.position
                self.seedNode = sprite
            }

            plantRootNode.addChild(templateSeedNode)
            startSeedAnimation()
            return
        }

        // 2. Fallback procedural
        guard let seedTexture = loadTexture(assetId: 100) else { return }
        let seed = SKSpriteNode(texture: seedTexture)
        seed.name = "seedSprite"
        seed.size = CGSize(width: 80, height: 60)
        seed.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        seed.position = CGPoint(x: 0, y: -18.5)
        seed.zPosition = 10
        seed.isPaused = false
        seed.speed = 1.0

        plantRootNode.addChild(seed)
        self.seedNode = seed
        self.initialSeedPosition = seed.position
        startSeedAnimation()
    }

    // MARK: - Level 2: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasWidth: CGFloat = 611.0
        let baseCanvasHeight: CGFloat = 858.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.15
        plantRootNode.setScale(baseScale)

        // 1. Ưu tiên nạp từ Plant17Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSproutNode = scene.childNode(withName: "sproutNode") {
            templateSproutNode.removeFromParent()
            templateSproutNode.position = .zero

            let sproutSprite = templateSproutNode.childNode(withName: "sproutSprite") as? SKSpriteNode
            if let sprite = sproutSprite {
                if sprite.texture == nil {
                    sprite.texture = loadTexture(assetId: 200)
                }
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.initialSproutPosition = sprite.position
                self.sproutNode = sprite
            }

            plantRootNode.addChild(templateSproutNode)
            startSproutAnimation()
            return
        }

        // 2. Fallback procedural
        guard let sproutTexture = loadTexture(assetId: 200) else { return }
        let sprout = SKSpriteNode(texture: sproutTexture)
        sprout.name = "sproutSprite"
        sprout.size = CGSize(width: 140, height: 160)
        sprout.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        sprout.position = CGPoint(x: 0, y: -18.5)
        sprout.zPosition = 10
        sprout.isPaused = false
        sprout.speed = 1.0

        plantRootNode.addChild(sprout)
        self.sproutNode = sprout
        self.initialSproutPosition = sprout.position
        startSproutAnimation()
    }

    // MARK: - Level 3+: Cây trưởng thành (Mature)

    private func buildMatureState(level: Int) {
        let baseCanvasWidth: CGFloat = 611.0
        let baseCanvasHeight: CGFloat = 858.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.12
        plantRootNode.setScale(baseScale)

        // 1. Nạp từ Plant17Scene.sks
        if let scene = loadSceneTemplate(),
           let templateMatureNode = scene.childNode(withName: "matureNode") {
            templateMatureNode.removeFromParent()
            templateMatureNode.isHidden = false
            templateMatureNode.isPaused = false
            templateMatureNode.speed = 1.0
            templateMatureNode.position = CGPoint(x: 0, y: 0)
            plantRootNode.addChild(templateMatureNode)

            var sortedLeaves: [SKSpriteNode] = []
            templateMatureNode.enumerateChildNodes(withName: "leaf_*") { node, _ in
                if let sprite = node as? SKSpriteNode {
                    sortedLeaves.append(sprite)
                }
            }
            sortedLeaves.sort { $0.zPosition < $1.zPosition }

            for (idx, leaf) in sortedLeaves.enumerated() {
                let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                if leaf.texture == nil {
                    leaf.texture = loadTexture(assetId: assetNum)
                }
                if let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum }) {
                    leaf.size = CGSize(width: meta.width, height: meta.height)
                    leaf.anchorPoint = CGPoint(x: meta.anchorX, y: meta.anchorY)
                }
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leaf.restZRotation = leaf.zRotation
                leafNodes.append(leaf)

                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                let shouldSway = meta?.shouldSway ?? (assetNum != 1)
                if shouldSway {
                    let bendAngle = meta?.bendAngle ?? 0.048
                    let duration = meta?.duration ?? 3.8
                    let delay = Double(idx) * 0.15

                    startLeafSwayAnimation(leaf: leaf, bendAngle: bendAngle, duration: duration, phaseDelay: delay)
                }
            }

            addTrunkBobAnimation()
            return
        }

        // 2. Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: 0)
        plantRootNode.addChild(fallbackGroup)

        for (idx, data) in Self.leavesMetadata.enumerated() {
            guard let leafTexture = loadTexture(assetId: data.assetId) else { continue }

            let leaf = SKSpriteNode(texture: leafTexture)
            leaf.name = "leaf_\(data.assetId)"
            leaf.size = CGSize(width: data.width, height: data.height)
            leaf.anchorPoint = CGPoint(x: data.anchorX, y: data.anchorY)
            leaf.position = CGPoint(x: data.imgX, y: data.imgY)
            leaf.zPosition = data.zPos
            leaf.isPaused = false
            leaf.speed = 1.0

            fallbackGroup.addChild(leaf)
            leaf.restZRotation = leaf.zRotation
            leafNodes.append(leaf)

            if data.shouldSway {
                let delay = Double(idx) * 0.15
                startLeafSwayAnimation(leaf: leaf, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: delay)
            }
        }

        addTrunkBobAnimation()
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant17Scene")
    }

    // MARK: - Texture Loader

    private func loadTexture(assetId: Int) -> SKTexture? {
        let nameVariants: [String]
        switch assetId {
        case 100:
            nameVariants = ["plant1_Asset-100@4.167x", "plant1_Asset-100", "seed"]
        case 200:
            nameVariants = ["plant1_Asset-200@4.167x", "plant1_Asset-200", "sprout"]
        case 1:
            nameVariants = ["plant17-crown@4.167x", "plant17-crown"]
        case 2:
            nameVariants = ["plant17-vines@4.167x", "plant17-vines", "plant17-2@4.167x", "Vernonia-elliptica@4.167x"]
        default:
            nameVariants = ["plant17-\(assetId)@4.167x", "plant17-\(assetId)"]
        }

        for name in nameVariants {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }
        return nil
    }

    // MARK: - Khôi phục chuyển động nhàn rỗi (Idle Animation) sau tương tác Tap

    public func resumeIdleAnimation() {
        switch growthState {
        case .seed:
            startSeedAnimation()
        case .sprout:
            startSproutAnimation()
        case .mature:
            addTrunkBobAnimation()
            for (idx, leaf) in leafNodes.enumerated() {
                let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                guard meta?.shouldSway ?? (assetNum != 1) else {
                    leaf.removeAction(forKey: "leafSway")
                    leaf.zRotation = leaf.restZRotation
                    continue
                }
                let bendAngle = meta?.bendAngle ?? 0.048
                let duration = max(0.2, meta?.duration ?? 3.8)
                let delay = Double(idx) * 0.22
                startLeafSwayAnimation(leaf: leaf, bendAngle: bendAngle, duration: duration, phaseDelay: delay)
            }
        }
    }

    // MARK: - Tap Animation & Interactions

    public func playTapAnimation() {
        // 1. Kích hoạt hiệu ứng chuyển động cành lá
        motionEffect.apply(
            plantNode: self,
            plantRootNode: plantRootNode,
            seedNode: seedNode,
            sproutNode: sproutNode,
            leafNodes: leafNodes,
            baseScale: baseScale,
            level: growthState.rawLevel,
            initialSeedPosition: initialSeedPosition,
            initialSproutPosition: initialSproutPosition,
            containerSize: containerSize,
            onComplete: { [weak self] in
                self?.resumeIdleAnimation()
            }
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã đăng ký (Bọt khí Oxy, phấn hoa...)
        let lvl = growthState.rawLevel
        for effect in tapEffects {
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }
    }

    private func playSeedTapAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedTapHop")

        let squash = SKAction.scaleX(to: 1.15, y: 0.85, duration: 0.08)
        squash.timingMode = .easeIn
        let jumpUp = SKAction.moveBy(x: 0, y: 16, duration: 0.14)
        jumpUp.timingMode = .easeOut
        let fallDown = SKAction.moveBy(x: 0, y: -16, duration: 0.12)
        fallDown.timingMode = .easeIn
        let settle = SKAction.scale(to: 1.0, duration: 0.10)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([squash, jumpUp, fallDown, settle]), withKey: "seedTapHop")
    }

    private func playSproutTapAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutTapBounce")

        let squash = SKAction.scaleX(to: 1.18, y: 0.84, duration: 0.08)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: 0.90, y: 1.12, duration: 0.14)
        stretch.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([squash, stretch, settle]), withKey: "sproutTapBounce")
    }

    private func playMatureTapAnimation() {
        // Cúc tần Ấn Độ: khi tap dải lá rủ dài đung đưa mạnh và gợn sóng theo gió
        for (idx, leaf) in leafNodes.enumerated() {
            let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
            guard meta?.shouldSway != false else { continue }
            let impulseAngle: CGFloat = 0.085

            let delay = SKAction.wait(forDuration: Double(idx) * 0.04)
            let sway1 = SKAction.rotate(byAngle: impulseAngle, duration: 0.35)
            sway1.timingMode = .easeOut
            let sway2 = SKAction.rotate(byAngle: -impulseAngle * 1.3, duration: 0.55)
            sway2.timingMode = .easeInEaseOut
            let sway3 = SKAction.rotate(byAngle: impulseAngle * 0.5, duration: 0.45)
            sway3.timingMode = .easeInEaseOut
            let swayBack = SKAction.rotate(toAngle: 0.0, duration: 0.35)
            swayBack.timingMode = .easeInEaseOut

            let resumeNormalSway = SKAction.run { [weak self, weak leaf] in
                guard let self = self, let leaf = leaf else { return }
                let bendAngle = meta?.bendAngle ?? 0.048
                let duration = meta?.duration ?? 3.8
                self.startLeafSwayAnimation(leaf: leaf, bendAngle: bendAngle, duration: duration, phaseDelay: 0)
            }

            let flutter = SKAction.sequence([delay, sway1, sway2, sway3, swayBack, resumeNormalSway])
            leaf.run(flutter, withKey: "leafTapJiggle")
        }
    }

    // MARK: - Animation tự nhiên: Cành đung đưa & Thân nhấp nhô mượt mà

    private func addTrunkBobAnimation() {
        plantRootNode.removeAction(forKey: "trunkSway")
        plantRootNode.removeAction(forKey: "trunkBob")
        plantRootNode.zRotation = 0.0
        plantRootNode.position = .zero

        // Thân nhấp nhô nhẹ nhàng, êm ái theo phương thẳng đứng (dùng moveTo chống trôi toạ độ tuyệt đối)
        let bobUp = SKAction.moveTo(y: 2.0, duration: 2.8)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveTo(y: 0.0, duration: 3.0)
        bobDown.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([bobUp, bobDown])
        plantRootNode.run(SKAction.repeatForever(sequence), withKey: "trunkBob")
    }

    private func startLeafSwayAnimation(leaf: SKSpriteNode, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval) {
        leaf.removeAction(forKey: "leafSway")
        let rest = leaf.restZRotation
        leaf.zRotation = rest

        // Chốt chặn an toàn: Tuyệt đối không tạo SKAction.repeatForever với duration == 0 (gây vòng lặp vô hạn treo app)
        guard duration > 0.05, abs(bendAngle) > 0.001 else {
            return
        }

        // Cành đung đưa con lắc gió uyển chuyển quanh cuống rủ
        let swingLeft = SKAction.rotate(toAngle: rest - bendAngle, duration: duration * 0.50)
        swingLeft.timingMode = .easeInEaseOut
        let swingRight = SKAction.rotate(toAngle: rest + bendAngle, duration: duration * 0.50)
        swingRight.timingMode = .easeInEaseOut
        let swingCycle = SKAction.sequence([swingLeft, swingRight])

        let repeatAction = SKAction.repeatForever(swingCycle)

        if phaseDelay > 0 {
            let wait = SKAction.wait(forDuration: phaseDelay)
            leaf.run(SKAction.sequence([wait, repeatAction]), withKey: "leafSway")
        } else {
            leaf.run(repeatAction, withKey: "leafSway")
        }
    }

    private func startSeedAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedBreathing")

        let breatheIn = SKAction.scale(to: 1.04, duration: 1.8)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scale(to: 0.98, duration: 1.8)
        breatheOut.timingMode = .easeInEaseOut

        node.run(SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut])), withKey: "seedBreathing")
    }

    private func startSproutAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutSway")

        let swayLeft = SKAction.rotate(toAngle: -0.04, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.04, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut

        node.run(SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])), withKey: "sproutSway")
    }

    // MARK: - Oxygen Bubbles Convention

    private func spawnOxygenBubbles() {
        let lvl = growthState.rawLevel
        for effect in tapEffects {
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }
    }
}

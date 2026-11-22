//
//  Plant16Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cỏ Lan Chi (Plant16 - Chlorophytum comosum)

public enum Plant16GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant16

public final class Plant16Node: SKNode {

    // MARK: - Metadata cấu trúc 22 phiến lá Cỏ Lan Chi Chlorophytum comosum (Canvas 721 x 552)

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

    /// Tọa độ pixel và điểm neo cuống lá Cỏ Lan Chi (Canvas 721 x 552)
    /// Đung đưa mềm mại, biên độ rõ nét cho toàn bộ cành và các dải nhánh dây nhện vươn dài
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId:  2, imgX: 242.0, imgY:  77.7, width: 163, height: 322, anchorX: 0.07, anchorY: 0.01, isLeft: true , zPos: 11, bendAngle: 0.125, duration: 3.8),
        LeafData(assetId:  3, imgX: 411.7, imgY:  96.6, width: 247, height: 203, anchorX: 0.01, anchorY: 0.54, isLeft: false, zPos: 12, bendAngle: 0.140, duration: 4.2),
        LeafData(assetId:  4, imgX: 412.4, imgY: 203.6, width:  75, height: 221, anchorX: 0.83, anchorY: 0.01, isLeft: false, zPos: 13, bendAngle: 0.110, duration: 3.4),
        LeafData(assetId:  5, imgX: 400.1, imgY:  29.4, width: 321, height: 280, anchorX: 0.01, anchorY: 0.45, isLeft: false, zPos: 14, bendAngle: 0.155, duration: 4.5),
        LeafData(assetId:  6, imgX: 398.4, imgY: 205.9, width:  69, height: 158, anchorX: 0.86, anchorY: 0.01, isLeft: false, zPos: 15, bendAngle: 0.105, duration: 3.2),
        LeafData(assetId:  7, imgX: 397.9, imgY: 175.7, width: 144, height: 246, anchorX: 0.48, anchorY: 0.01, isLeft: false, zPos: 16, bendAngle: 0.115, duration: 3.6),
        LeafData(assetId:  8, imgX: 410.3, imgY: 142.0, width: 216, height: 250, anchorX: 0.72, anchorY: 0.01, isLeft: false, zPos: 17, bendAngle: 0.135, duration: 4.0),
        LeafData(assetId:  9, imgX: 403.9, imgY:   0.7, width: 100, height: 202, anchorX: 0.03, anchorY: 0.01, isLeft: false, zPos: 18, bendAngle: 0.120, duration: 3.3),
        LeafData(assetId: 10, imgX: 346.4, imgY: 183.6, width:  55, height: 194, anchorX: 0.34, anchorY: 0.01, isLeft: false, zPos: 19, bendAngle: 0.100, duration: 3.5),
        LeafData(assetId: 11, imgX: 198.8, imgY:  77.6, width: 200, height: 105, anchorX: 0.99, anchorY: 0.01, isLeft: true , zPos: 20, bendAngle: 0.115, duration: 3.9),
        LeafData(assetId: 12, imgX: 245.2, imgY: 185.8, width: 149, height: 284, anchorX: 0.52, anchorY: 0.14, isLeft: true , zPos: 21, bendAngle: 0.130, duration: 3.7),
        LeafData(assetId: 13, imgX: 398.8, imgY: 194.2, width:  72, height: 164, anchorX: 0.58, anchorY: 0.01, isLeft: false, zPos: 22, bendAngle: 0.105, duration: 3.4),
        LeafData(assetId: 14, imgX: 400.9, imgY: 124.5, width: 209, height:  82, anchorX: 0.01, anchorY: 0.01, isLeft: false, zPos: 23, bendAngle: 0.125, duration: 4.3),
        LeafData(assetId: 15, imgX: 410.6, imgY:  26.6, width: 234, height: 151, anchorX: 0.01, anchorY: 0.01, isLeft: false, zPos: 24, bendAngle: 0.135, duration: 3.8),
        LeafData(assetId: 16, imgX: 175.6, imgY:   4.4, width: 236, height: 191, anchorX: 0.89, anchorY: 0.01, isLeft: true , zPos: 25, bendAngle: 0.140, duration: 3.9),
        LeafData(assetId: 17, imgX: 267.1, imgY: 108.2, width: 140, height:  66, anchorX: 0.98, anchorY: 0.01, isLeft: true , zPos: 26, bendAngle: 0.110, duration: 4.1),
        LeafData(assetId: 18, imgX: 147.4, imgY: 125.7, width: 255, height: 194, anchorX: 0.89, anchorY: 0.55, isLeft: true , zPos: 27, bendAngle: 0.150, duration: 3.5),
        LeafData(assetId: 19, imgX: 133.3, imgY: 159.5, width: 265, height: 268, anchorX: 0.36, anchorY: 0.11, isLeft: true , zPos: 28, bendAngle: 0.160, duration: 3.7),
        LeafData(assetId: 20, imgX: 376.9, imgY: 200.0, width: 105, height: 338, anchorX: 0.23, anchorY: 0.32, isLeft: false, zPos: 29, bendAngle: 0.145, duration: 4.4),
        LeafData(assetId: 21, imgX: 394.4, imgY: 114.1, width: 299, height: 293, anchorX: 0.01, anchorY: 0.66, isLeft: false, zPos: 30, bendAngle: 0.165, duration: 3.9),
        LeafData(assetId: 22, imgX: 418.2, imgY: 148.1, width: 157, height: 357, anchorX: 0.50, anchorY: 0.15, isLeft: false, zPos: 31, bendAngle: 0.155, duration: 4.2),
        LeafData(assetId: 23, imgX:  -1.1, imgY:  68.9, width: 399, height: 267, anchorX: 0.99, anchorY: 0.57, isLeft: true , zPos: 32, bendAngle: 0.175, duration: 4.0),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant16GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Danh sách các hiệu ứng thị giác khi tap vào cây (mặc định Bọt khí Oxy Emerald)
    /// Hiệu ứng chuyển động rung lắc / nảy cành lá khi tap vào cây (mặc định: WindSwayMotionEffect)
    public var motionEffect: PlantMotionEffect = WindSwayMotionEffect()

    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .emerald)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant16GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant16GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant16GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant16GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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

    // MARK: - Level 1: Hạt giống (Seed)

    private func buildSeedState() {
        let baseCanvasWidth: CGFloat = 721.0
        let baseCanvasHeight: CGFloat = 552.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp seedNode từ Plant16Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSeedNode = scene.childNode(withName: "seedNode") {
            let seedSprite = templateSeedNode.childNode(withName: "seedSprite") as? SKSpriteNode

            templateSeedNode.removeFromParent()
            templateSeedNode.isHidden = false
            templateSeedNode.isPaused = false
            templateSeedNode.speed = 1.0

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
        let baseCanvasWidth: CGFloat = 721.0
        let baseCanvasHeight: CGFloat = 552.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp sproutNode từ Plant16Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSproutNode = scene.childNode(withName: "sproutNode") {
            let sproutSprite = templateSproutNode.childNode(withName: "sproutSprite") as? SKSpriteNode

            templateSproutNode.removeFromParent()
            templateSproutNode.isHidden = false
            templateSproutNode.isPaused = false
            templateSproutNode.speed = 1.0

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

    // MARK: - Level 3+: Cây trưởng thành (Mature - 22 phiến lá Chlorophytum comosum)

    private func buildMatureState(level: Int) {
        let baseCanvasWidth: CGFloat = 721.0
        let baseCanvasHeight: CGFloat = 552.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH)

        let levelBonus = CGFloat(min(level, 10) - 3) * 0.012
        plantRootNode.setScale(baseScale * (1.0 + levelBonus))

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp matureNode từ Plant16Scene.sks
        if let scene = loadSceneTemplate(),
           let matureGroup = scene.childNode(withName: "matureNode") {
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
                let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                let bendAngle = meta?.bendAngle ?? 0.060
                let duration = meta?.duration ?? 4.0
                let phaseDelay = Double(idx) * 0.15

                startLeafSwayAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay)
            }

            addTrunkSwayAnimation()
            return
        }

        // 2. Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -10)
        plantRootNode.addChild(fallbackGroup)

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

            fallbackGroup.addChild(leaf)
            leaf.restZRotation = leaf.zRotation
            leafNodes.append(leaf)

            let phaseDelay = Double(idx) * 0.15
            startLeafSwayAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: phaseDelay)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        // Dây nhện: gốc cố định, KHÔNG lắc plantRootNode.
        // Từng lá/cành đã tự đung đưa quanh cuống riêng qua startLeafSwayAnimation.
        plantRootNode.removeAction(forKey: "trunkSway")
        plantRootNode.zRotation = 0
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant16Scene")
    }

    // MARK: - Texture Loader

    private func loadTexture(assetId: Int) -> SKTexture? {
        let nameVariants: [String]
        switch assetId {
        case 100:
            nameVariants = ["plant1_Asset-100@4.167x", "plant1_Asset-100", "seed"]
        case 200:
            nameVariants = ["plant1_Asset-200@4.167x", "plant1_Asset-200", "sprout"]
        default:
            nameVariants = [
                "plant16-\(assetId)@4.167x",
                "Plant16-\(assetId)@4.167x",
                "plant16_\(assetId)@4.167x",
                "plant16-\(assetId)",
                "Plant16-\(assetId)"
            ]
        }

        for name in nameVariants {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }
        return nil
    }

    // MARK: - Animation & Phản hồi tương tác Tap

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
            containerSize: containerSize
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
        node.position = initialSeedPosition

        let squash = SKAction.scaleX(to: 1.28, y: 0.72, duration: 0.08)
        squash.timingMode = .easeIn

        let jumpUp = SKAction.group([
            SKAction.moveTo(y: initialSeedPosition.y + 10, duration: 0.12),
            SKAction.scaleX(to: 0.85, y: 1.20, duration: 0.12)
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
        // Cỏ Lan Chi: tap tạo xung gió — mỗi lá giật mạnh theo hướng riêng rồi damping trở về
        for (idx, leaf) in leafNodes.enumerated() {
            let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
            let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
            let dir: CGFloat = isLeft ? -1.0 : 1.0
            let impulse: CGFloat = dir * CGFloat.random(in: 0.09...0.14)

            // Dừng sway cũ, giữ nguyên zRotation hiện tại làm điểm xuất phát
            leaf.removeAction(forKey: "leafSway")

            let delay = SKAction.wait(forDuration: Double(idx) * 0.018)
            // Giật theo hướng gió (byAngle — tương đối)
            let gust1 = SKAction.rotate(byAngle:  impulse,        duration: 0.22)
            gust1.timingMode = .easeOut
            let gust2 = SKAction.rotate(byAngle: -impulse * 1.60, duration: 0.38)
            gust2.timingMode = .easeInEaseOut
            let gust3 = SKAction.rotate(byAngle:  impulse * 0.65, duration: 0.30)
            gust3.timingMode = .easeInEaseOut
            // Về 0 (vị trí tự nhiên) rồi resume idle sway
            let settle = SKAction.rotate(toAngle: 0.0, duration: 0.22)
            settle.timingMode = .easeInEaseOut

            let resumeSway = SKAction.run { [weak self, weak leaf] in
                guard let self, let leaf else { return }
                let bendAngle = meta?.bendAngle ?? 0.065
                let duration  = meta?.duration  ?? 4.0
                self.startLeafSwayAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: 0)
            }

            leaf.run(SKAction.sequence([delay, gust1, gust2, gust3, settle, resumeSway]), withKey: "leafTapJiggle")
        }
    }

    // MARK: - Animation tự nhiên cành lá Cỏ Lan Chi (Dây nhện)
    // Mỗi lá/cành đung đưa quanh cuống riêng (anchorPoint) theo góc TƯƠNG ĐỐI.
    // Gốc cây (plantRootNode) đứng yên cố định — không lắc tổng thể.

    private func startLeafSwayAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval) {
        leaf.removeAction(forKey: "leafSway")
        let rest = leaf.restZRotation
        leaf.zRotation = rest

        // Hướng đong: lá bên trái đong sang trái trước, lá bên phải đong sang phải trước
        let dir: CGFloat = isLeft ? -1.0 : 1.0

        let swingOut = SKAction.rotate(toAngle: rest + dir * bendAngle, duration: duration * 0.50)
        swingOut.timingMode = .easeInEaseOut
        let swingBack = SKAction.rotate(toAngle: rest - dir * bendAngle * 0.80, duration: duration * 0.50)
        swingBack.timingMode = .easeInEaseOut
        let swingReturn = SKAction.rotate(toAngle: rest, duration: duration * 0.40)
        swingReturn.timingMode = .easeInEaseOut

        let swingCycle = SKAction.sequence([swingOut, swingBack, swingReturn])

        // Nhấp nhô nhẹ theo chiều dài cành (scale Y) — cành dây nhện mềm mại
        let elongate = SKAction.scaleY(to: 1.018, duration: duration * 0.50)
        elongate.timingMode = .easeInEaseOut
        let contract = SKAction.scaleY(to: 0.984, duration: duration * 0.50)
        contract.timingMode = .easeInEaseOut
        let bobCycle = SKAction.sequence([elongate, contract])

        let combined = SKAction.group([swingCycle, bobCycle])
        let repeatForever = SKAction.repeatForever(combined)

        if phaseDelay > 0 {
            leaf.run(SKAction.sequence([SKAction.wait(forDuration: phaseDelay), repeatForever]), withKey: "leafSway")
        } else {
            leaf.run(repeatForever, withKey: "leafSway")
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
        node.zRotation = 0

        let swayLeft = SKAction.rotate(toAngle: -0.04, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.04, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut

        node.run(SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])), withKey: "sproutSway")
    }
}

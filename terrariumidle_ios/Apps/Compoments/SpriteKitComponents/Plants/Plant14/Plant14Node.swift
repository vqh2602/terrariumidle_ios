//
//  Plant14Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cây Trầu Bà Lá Tim (Plant14 - Heartleaf philodendron)

public enum Plant14GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant14

public final class Plant14Node: SKNode {

    // MARK: - Metadata cấu trúc 7 bộ phận Trầu Bà Lá Tim (Canvas 510 x 648)

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

    /// Tọa độ pixel và điểm neo cuống dây lá tim Heartleaf philodendron (Canvas 510 x 648)
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 1, imgX: 258.4, imgY:   0.0, width: 254, height: 627, anchorX: 0.05, anchorY: 0.01, isLeft: false, zPos: 11, bendAngle: 0.025, duration: 4.6),
        LeafData(assetId: 2, imgX: 236.5, imgY: 433.9, width: 124, height: 184, anchorX: 0.05, anchorY: 0.01, isLeft: false, zPos: 12, bendAngle: 0.075, duration: 2.5),
        LeafData(assetId: 3, imgX: 232.7, imgY: 202.3, width: 113, height: 404, anchorX: 0.05, anchorY: 0.01, isLeft: false, zPos: 13, bendAngle: 0.055, duration: 3.2),
        LeafData(assetId: 4, imgX: 213.8, imgY: 292.6, width: 218, height: 334, anchorX: 0.05, anchorY: 0.01, isLeft: false, zPos: 14, bendAngle: 0.065, duration: 2.9),
        LeafData(assetId: 5, imgX:  37.1, imgY: 378.5, width: 172, height: 253, anchorX: 0.90, anchorY: 0.01, isLeft: true , zPos: 15, bendAngle: 0.070, duration: 2.7),
        LeafData(assetId: 6, imgX:   0.0, imgY: 213.0, width: 212, height: 434, anchorX: 0.98, anchorY: 0.01, isLeft: true , zPos: 16, bendAngle: 0.055, duration: 3.4),
        LeafData(assetId: 7, imgX:  67.2, imgY:  57.5, width: 159, height: 570, anchorX: 0.97, anchorY: 0.01, isLeft: true , zPos: 17, bendAngle: 0.035, duration: 4.0),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant14GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Hiệu ứng chuyển động rung lắc / nảy cành lá khi tap vào cây (mặc định: CascadingVineMotionEffect)
    public var motionEffect: PlantMotionEffect = CascadingVineMotionEffect()

    /// Danh sách các hiệu ứng thị giác khi tap vào cây (mặc định Bọt khí Oxy bạc hà sương)
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .mintDew)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant14GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant14GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant14GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant14GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasWidth: CGFloat = 510.0
        let baseCanvasHeight: CGFloat = 648.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp seedNode từ Plant14Scene.sks
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
        let baseCanvasWidth: CGFloat = 510.0
        let baseCanvasHeight: CGFloat = 648.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp sproutNode từ Plant14Scene.sks
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

    // MARK: - Level 3+: Cây trưởng thành (Mature - 7 bộ phận Trầu Bà Lá Tim)

    private func buildMatureState(level: Int) {
        let baseCanvasWidth: CGFloat = 510.0
        let baseCanvasHeight: CGFloat = 648.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH)

        let levelBonus = CGFloat(min(level, 10) - 3) * 0.015
        plantRootNode.setScale(baseScale * (1.0 + levelBonus))

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp matureNode từ Plant14Scene.sks
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
                let duration = meta?.duration ?? 3.2
                let phaseDelay = Double(idx) * 0.18
                let isTrunk = (assetNum == 1)

                startHeartleafAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay, isTrunk: isTrunk)
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
            let skY = baseCanvasHeight - data.imgY - (1.0 - data.anchorY) * data.height

            leaf.position = CGPoint(x: skX, y: skY)
            leaf.zPosition = data.zPos
            leaf.isPaused = false
            leaf.speed = 1.0

            fallbackGroup.addChild(leaf)
            leaf.restZRotation = leaf.zRotation
            leafNodes.append(leaf)

            let phaseDelay = Double(idx) * 0.18
            let isTrunk = (data.assetId == 1)
            startHeartleafAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: phaseDelay, isTrunk: isTrunk)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        plantRootNode.removeAction(forKey: "trunkSway")
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        let swayLeft = SKAction.rotate(toAngle: -0.022, duration: 2.8)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.022, duration: 2.8)
        swayRight.timingMode = .easeInEaseOut
        let trunkSeq = SKAction.sequence([swayLeft, swayRight])
        plantRootNode.run(SKAction.repeatForever(trunkSeq), withKey: "trunkSway")
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant14Scene")
    }

    // MARK: - Animation: Gieo hạt (Level 1)

    private func startSeedAnimation() {
        guard let seed = seedNode else { return }
        seed.removeAction(forKey: "seedBreathing")
        seed.isPaused = false
        seed.speed = 1.0

        let scaleUp = SKAction.scale(to: 1.04, duration: 1.8)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 0.96, duration: 1.8)
        scaleDown.timingMode = .easeInEaseOut
        let breathe = SKAction.sequence([scaleUp, scaleDown])
        seed.run(SKAction.repeatForever(breathe), withKey: "seedBreathing")
    }

    // MARK: - Animation: Cây con (Level 2)

    private func startSproutAnimation() {
        guard let sprout = sproutNode else { return }
        sprout.removeAction(forKey: "sproutSway")
        sprout.isPaused = false
        sprout.speed = 1.0

        let swayLeft = SKAction.rotate(toAngle: -0.045, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.045, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut
        let sway = SKAction.sequence([swayLeft, swayRight])
        sprout.run(SKAction.repeatForever(sway), withKey: "sproutSway")
    }

    // MARK: - Animation: Nhánh trầu bà lá tim mềm mại (Level 3+)

    private func startHeartleafAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: Double, isTrunk: Bool = false) {
        leaf.removeAction(forKey: "heartleafWind")
        leaf.isPaused = false
        leaf.speed = 1.0

        // Reset scale về 1.0 chuẩn (loại bỏ hoàn toàn hiệu ứng scale/zoom lên xuống)
        leaf.xScale = 1.0
        leaf.yScale = 1.0

        let restAngle = leaf.restZRotation
        leaf.zRotation = restAngle
        // Thân chính chỉ đung đưa nhẹ, các nhánh lá tim đung đưa rõ nét theo chiều gió
        let swayAngle: CGFloat = isTrunk ? 0.012 : max(0.045, bendAngle)

        // Gió thổi qua lại: nghiêng sang trái rồi nghiêng sang phải quanh góc cân bằng
        let swayLeft = SKAction.rotate(toAngle: restAngle - swayAngle, duration: duration * 0.5)
        swayLeft.timingMode = .easeInEaseOut

        let swayRight = SKAction.rotate(toAngle: restAngle + swayAngle, duration: duration * 0.5)
        swayRight.timingMode = .easeInEaseOut

        let cycle = SKAction.sequence([swayLeft, swayRight])

        if phaseDelay > 0 {
            leaf.run(SKAction.sequence([
                SKAction.wait(forDuration: phaseDelay),
                SKAction.repeatForever(cycle)
            ]), withKey: "heartleafWind")
        } else {
            leaf.run(SKAction.repeatForever(cycle), withKey: "heartleafWind")
        }
    }

    // MARK: - Khôi phục chuyển động nhàn rỗi (Idle Animation) sau tương tác Tap

    public func resumeIdleAnimation() {
        switch growthState {
        case .seed:
            startSeedAnimation()
        case .sprout:
            startSproutAnimation()
        case .mature:
            addTrunkSwayAnimation()
            for (idx, leaf) in leafNodes.enumerated() {
                let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                let bendAngle = meta?.bendAngle ?? 0.060
                let duration = meta?.duration ?? 3.2
                let phaseDelay = Double(idx) * 0.18
                let isTrunk = (assetNum == 1)
                startHeartleafAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay, isTrunk: isTrunk)
            }
        }
    }

    // MARK: - Phản hồi tương tác Tap (Bounce & Bọt oxy)

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

    // MARK: - Hiệu ứng bọt khí Oxy bay lên chuẩn Terrarium (trên chính Plant14Node)

    private func spawnOxygenBubbles() {
        let bubbleCount: Int
        switch growthState {
        case .seed:
            bubbleCount = Int.random(in: 1...2)
        case .sprout:
            bubbleCount = Int.random(in: 3...4)
        case .mature:
            bubbleCount = Int.random(in: 8...12)
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
                    let leafWorldPos = randomLeaf.parent?.convert(randomLeaf.position, to: self) ?? randomLeaf.position
                    spawnX = leafWorldPos.x + CGFloat.random(in: -16...16)
                    spawnY = max(containerSize.height * 0.18, min(containerSize.height * 0.90, leafWorldPos.y + CGFloat.random(in: -10...20)))
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

    // MARK: - Texture Loader Helper

    private func loadTexture(assetId: Int) -> SKTexture? {
        let nameVariants: [String]
        switch assetId {
        case 100:
            nameVariants = ["plant1_Asset-100@4.167x", "plant1_Asset-100", "seed"]
        case 200:
            nameVariants = ["plant1_Asset-200@4.167x", "plant1_Asset-200", "sprout"]
        default:
            nameVariants = [
                "Plant14-\(assetId)@4.167x",
                "Plant14-\(assetId)",
                "Asset-\(assetId)@4.167x",
                "Asset-\(assetId)",
                "plant14_Asset-\(assetId)@4.167x",
                "plant14_\(assetId)"
            ]
        }

        for name in nameVariants {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        if assetId == 100 || assetId == 200 {
            return generateProceduralPlaceholder(assetId: assetId)
        }

        return nil
    }

    private func generateProceduralPlaceholder(assetId: Int) -> SKTexture {
        let size = (assetId == 100) ? CGSize(width: 40, height: 40) : CGSize(width: 80, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            if assetId == 100 {
                UIColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1.0).setFill()
                ctx.cgContext.fillEllipse(in: rect.insetBy(dx: 4, dy: 4))
            } else {
                UIColor(red: 0.45, green: 0.75, blue: 0.35, alpha: 1.0).setFill()
                ctx.cgContext.fillEllipse(in: rect.insetBy(dx: 6, dy: 6))
            }
        }
        return SKTexture(image: img)
    }
}

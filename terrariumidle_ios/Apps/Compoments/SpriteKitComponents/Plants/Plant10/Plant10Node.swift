//
//  Plant10Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cây Ráy Xẻ Mini / Monstera Mini (Plant10 - Rhaphidophora tetrasperma)

public enum Plant10GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant10

public final class Plant10Node: SKNode {

    // MARK: - Metadata cấu trúc 11 bộ phận Rhaphidophora tetrasperma (Canvas 324 x 818)

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

    /// Tọa độ pixel và điểm neo cuống lá Rhaphidophora tetrasperma (Canvas 324 x 818)
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId:  2, imgX:  94, imgY:   0, width: 172, height: 818, anchorX: 0.50, anchorY: 0.01, isLeft: true , zPos: 11, bendAngle: 0.015, duration: 3.8),
        LeafData(assetId:  3, imgX:  93, imgY:  23, width: 140, height: 151, anchorX: 0.76, anchorY: 0.01, isLeft: false, zPos: 12, bendAngle: 0.035, duration: 3.2),
        LeafData(assetId:  4, imgX:   0, imgY: 135, width: 122, height: 109, anchorX: 0.73, anchorY: 0.01, isLeft: true , zPos: 13, bendAngle: 0.045, duration: 2.8),
        LeafData(assetId:  5, imgX: 133, imgY: 178, width: 114, height: 114, anchorX: 0.87, anchorY: 0.01, isLeft: false, zPos: 14, bendAngle: 0.040, duration: 3.0),
        LeafData(assetId:  6, imgX: 179, imgY: 304, width:  98, height:  87, anchorX: 0.37, anchorY: 0.01, isLeft: false, zPos: 15, bendAngle: 0.045, duration: 2.6),
        LeafData(assetId:  7, imgX:  54, imgY: 268, width:  73, height:  74, anchorX: 0.15, anchorY: 0.01, isLeft: true , zPos: 16, bendAngle: 0.050, duration: 2.8),
        LeafData(assetId:  8, imgX: 211, imgY: 391, width: 111, height: 121, anchorX: 0.85, anchorY: 0.01, isLeft: false, zPos: 17, bendAngle: 0.040, duration: 3.0),
        LeafData(assetId:  9, imgX:  74, imgY: 370, width:  90, height:  96, anchorX: 0.19, anchorY: 0.01, isLeft: true , zPos: 18, bendAngle: 0.045, duration: 3.2),
        LeafData(assetId: 10, imgX:  48, imgY: 486, width: 114, height: 116, anchorX: 0.14, anchorY: 0.01, isLeft: true , zPos: 19, bendAngle: 0.040, duration: 3.4),
        LeafData(assetId: 11, imgX: 210, imgY: 511, width:  77, height:  70, anchorX: 0.31, anchorY: 0.01, isLeft: false, zPos: 20, bendAngle: 0.045, duration: 2.8),
        LeafData(assetId: 12, imgX: 166, imgY: 583, width:  87, height:  98, anchorX: 0.74, anchorY: 0.01, isLeft: false, zPos: 21, bendAngle: 0.040, duration: 3.0),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant10GrowthState = .mature(level: 1)
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

    public init(growthState: Plant10GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant10GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant10GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant10GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasWidth: CGFloat = 324.0
        let baseCanvasHeight: CGFloat = 818.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp seedNode từ Plant10Scene.sks
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
        let baseCanvasWidth: CGFloat = 324.0
        let baseCanvasHeight: CGFloat = 818.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp sproutNode từ Plant10Scene.sks
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

    // MARK: - Level 3+: Cây trưởng thành (Mature - 11 bộ phận Rhaphidophora)

    private func buildMatureState(level: Int) {
        let baseCanvasWidth: CGFloat = 324.0
        let baseCanvasHeight: CGFloat = 818.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH)

        let levelBonus = CGFloat(min(level, 10) - 3) * 0.015
        plantRootNode.setScale(baseScale * (1.0 + levelBonus))

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp matureNode từ Plant10Scene.sks
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
                leafNodes.append(leaf)

                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                let bendAngle = meta?.bendAngle ?? 0.040
                let duration = meta?.duration ?? 3.0
                let phaseDelay = Double(idx) * 0.12

                startSplitLeafAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay)
            }

            addTrunkSwayAnimation()
            return
        }

        // 2. Fallback procedural: Sinh 11 bộ phận từ metadata
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
            leafNodes.append(leaf)

            let phaseDelay = Double(idx) * 0.12
            startSplitLeafAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: phaseDelay)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        plantRootNode.removeAction(forKey: "trunkSway")
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        let swayLeft = SKAction.rotate(byAngle: 0.010, duration: 4.4)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(byAngle: -0.010, duration: 4.4)
        swayRight.timingMode = .easeInEaseOut
        let trunkSeq = SKAction.sequence([swayLeft, swayRight])
        plantRootNode.run(SKAction.repeatForever(trunkSeq), withKey: "trunkSway")
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant10Scene")
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

        let swayLeft = SKAction.rotate(byAngle: 0.045, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(byAngle: -0.045, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut
        let sway = SKAction.sequence([swayLeft, swayRight])
        sprout.run(SKAction.repeatForever(sway), withKey: "sproutSway")
    }

    // MARK: - Animation: Lá ráy xẻ uốn lượn leo cột (Level 3+)

    private func startSplitLeafAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: Double) {
        leaf.removeAction(forKey: "leafWind")
        leaf.isPaused = false
        leaf.speed = 1.0

        let primaryAngle = isLeft ? bendAngle : -bendAngle
        let rotOut = SKAction.rotate(byAngle: primaryAngle, duration: duration)
        rotOut.timingMode = .easeInEaseOut
        let rotIn = SKAction.rotate(byAngle: -primaryAngle, duration: duration)
        rotIn.timingMode = .easeInEaseOut

        let stretchOut = SKAction.scaleY(to: 1.025, duration: duration)
        stretchOut.timingMode = .easeInEaseOut
        let stretchIn = SKAction.scaleY(to: 0.975, duration: duration)
        stretchIn.timingMode = .easeInEaseOut

        let wave1 = SKAction.group([rotOut, stretchOut])
        let wave2 = SKAction.group([rotIn, stretchIn])
        let cycle = SKAction.sequence([wave1, wave2])

        if phaseDelay > 0 {
            leaf.run(SKAction.sequence([
                SKAction.wait(forDuration: phaseDelay),
                SKAction.repeatForever(cycle)
            ]), withKey: "leafWind")
        } else {
            leaf.run(SKAction.repeatForever(cycle), withKey: "leafWind")
        }
    }

    // MARK: - Phản hồi tương tác Tap (Bounce & Bọt oxy)

    public func playTapAnimation() {
        switch growthState {
        case .seed:
            guard let seed = seedNode else { return }
            seed.removeAction(forKey: "seedTap")
            seed.position = initialSeedPosition

            let squash = SKAction.scaleX(to: 1.18, y: 0.82, duration: 0.10)
            squash.timingMode = .easeOut
            let stretch = SKAction.scaleX(to: 0.88, y: 1.15, duration: 0.14)
            stretch.timingMode = .easeInEaseOut
            let settle = SKAction.scale(to: 1.0, duration: 0.16)
            settle.timingMode = .easeOut
            seed.run(SKAction.sequence([squash, stretch, settle]), withKey: "seedTap")
            spawnOxygenBubbles(count: 2, from: seed.position)

        case .sprout:
            guard let sprout = sproutNode else { return }
            sprout.removeAction(forKey: "sproutTap")
            sprout.position = initialSproutPosition

            let squash = SKAction.scaleX(to: 1.15, y: 0.85, duration: 0.11)
            squash.timingMode = .easeOut
            let stretch = SKAction.scaleX(to: 0.90, y: 1.12, duration: 0.15)
            stretch.timingMode = .easeInEaseOut
            let settle = SKAction.scale(to: 1.0, duration: 0.16)
            settle.timingMode = .easeOut
            sprout.run(SKAction.sequence([squash, stretch, settle]), withKey: "sproutTap")
            spawnOxygenBubbles(count: 3, from: CGPoint(x: sprout.position.x, y: sprout.position.y + 40))

        case .mature:
            guard !leafNodes.isEmpty else { return }
            plantRootNode.removeAction(forKey: "matureTapBounce")

            let squash = SKAction.scaleX(to: baseScale * 1.06, y: baseScale * 0.94, duration: 0.10)
            squash.timingMode = .easeOut
            let stretch = SKAction.scaleX(to: baseScale * 0.96, y: baseScale * 1.05, duration: 0.14)
            stretch.timingMode = .easeInEaseOut
            let settle = SKAction.scale(to: baseScale, duration: 0.18)
            settle.timingMode = .easeOut
            plantRootNode.run(SKAction.sequence([squash, stretch, settle]), withKey: "matureTapBounce")

            for (idx, leaf) in leafNodes.enumerated() {
                let flutterAngle: CGFloat = (idx % 2 == 0) ? 0.055 : -0.055
                let flutterOut = SKAction.rotate(byAngle: flutterAngle, duration: 0.08)
                let flutterIn = SKAction.rotate(byAngle: -flutterAngle, duration: 0.12)
                let flutter = SKAction.sequence([flutterOut, flutterIn])
                leaf.run(flutter)
            }

            spawnOxygenBubbles(count: 5, from: CGPoint(x: 0, y: 160))
        }
    }

    // MARK: - Hiệu ứng bọt khí Oxy bay lên

    private func spawnOxygenBubbles(count: Int, from startPos: CGPoint) {
        for i in 0..<count {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...9))
            bubble.fillColor = UIColor(red: 0.40, green: 0.85, blue: 0.50, alpha: 0.70)
            bubble.strokeColor = UIColor.white.withAlphaComponent(0.90)
            bubble.lineWidth = 1.0
            bubble.position = CGPoint(
                x: startPos.x + CGFloat.random(in: -30...30),
                y: startPos.y + CGFloat(i * 10)
            )
            bubble.zPosition = 35
            plantRootNode.addChild(bubble)

            let riseDistance = CGFloat.random(in: 70...140)
            let driftX = CGFloat.random(in: -25...25)
            let riseAction = SKAction.moveBy(x: driftX, y: riseDistance, duration: Double.random(in: 0.7...1.2))
            riseAction.timingMode = .easeOut
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let removeAction = SKAction.removeFromParent()

            bubble.run(SKAction.sequence([riseAction, fadeAction, removeAction]))
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
                "Plant10-\(assetId)@4.167x",
                "plant10_Asset-\(assetId)@4.167x",
                "Plant10-\(assetId)",
                "plant10_\(assetId)"
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

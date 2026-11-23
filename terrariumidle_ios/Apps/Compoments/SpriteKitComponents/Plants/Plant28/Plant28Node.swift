//
//  Plant28Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Xương rồng myrtle xanh (Plant28 - Myrtillocactus geometrizans)

public enum Plant28GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant28

public final class Plant28Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng myrtle xanh (Canvas 2480 x 2642)

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

    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 2, imgX:     9.1, imgY:  1734.5, width:  220.0, height:  898.0, anchorX: 0.08, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 3, imgX:  -343.7, imgY:  1639.0, width:  220.0, height:  898.0, anchorX: 0.08, anchorY: 0.00, isLeft: true , zPos: 12, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 4, imgX:    93.7, imgY:  1325.5, width:  669.0, height: 1003.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 13, bendAngle: -0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 5, imgX:  -140.2, imgY:   475.8, width:  636.0, height: 1102.0, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 14, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 6, imgX:   230.1, imgY:   924.0, width:  636.0, height: 1102.0, anchorX: 0.42, anchorY: 0.00, isLeft: false, zPos: 15, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 7, imgX:   532.6, imgY:   656.3, width:  906.0, height:  865.0, anchorX: 0.22, anchorY: 0.00, isLeft: false, zPos: 16, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 8, imgX:    79.5, imgY:   388.4, width:  810.0, height: 1224.0, anchorX: 0.34, anchorY: 0.00, isLeft: false, zPos: 17, bendAngle: -0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 9, imgX:    72.0, imgY:  1430.0, width:  426.0, height: 1161.0, anchorX: 0.62, anchorY: 0.00, isLeft: false, zPos: 18, bendAngle: -0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 10, imgX:  -147.6, imgY:   871.6, width:  691.0, height: 1256.0, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 19, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 11, imgX:    47.6, imgY:  1029.2, width:  470.0, height: 1520.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 20, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 12, imgX:   -38.8, imgY:   511.6, width:  365.0, height: 1179.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 21, bendAngle: -0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 13, imgX:   533.1, imgY:   778.8, width:  636.0, height: 1102.0, anchorX: 0.42, anchorY: 0.00, isLeft: false, zPos: 22, bendAngle: -0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 14, imgX:   521.2, imgY:   777.1, width:  781.0, height:  369.0, anchorX: 0.08, anchorY: 0.00, isLeft: false, zPos: 23, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 15, imgX:   364.0, imgY:   781.2, width:  279.0, height:  901.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 24, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 16, imgX:  -511.9, imgY:   631.6, width:  712.0, height:  634.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 25, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 17, imgX:  -252.8, imgY:  1176.1, width:  669.0, height: 1003.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 26, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 18, imgX:  -754.1, imgY:  1119.1, width:  636.0, height: 1102.0, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 27, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 19, imgX:  -603.6, imgY:   583.5, width:  810.0, height: 1224.0, anchorX: 0.66, anchorY: 0.00, isLeft: true , zPos: 28, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 20, imgX:  -485.2, imgY:   706.7, width:  365.0, height: 1179.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 29, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 21, imgX:  -347.8, imgY:   633.5, width:  636.0, height: 1102.0, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 30, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 22, imgX:  -193.3, imgY:  1135.3, width:  426.0, height: 1161.0, anchorX: 0.38, anchorY: 0.00, isLeft: true , zPos: 31, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 23, imgX:  -180.0, imgY:   541.9, width:  502.0, height: 1321.0, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 32, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 24, imgX:  -170.2, imgY:   734.5, width:  470.0, height: 1520.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 33, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 25, imgX:  -579.0, imgY:   549.2, width:  826.0, height:  941.0, anchorX: 0.80, anchorY: 0.00, isLeft: true , zPos: 34, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 26, imgX:  -535.0, imgY:   200.3, width:  365.0, height: 1179.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 35, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 27, imgX:  -397.6, imgY:   127.1, width:  636.0, height: 1102.0, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 36, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 28, imgX:  -229.8, imgY:    35.5, width:  502.0, height: 1321.0, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 37, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 29, imgX:   283.0, imgY:   575.2, width:  964.0, height: 1070.0, anchorX: 0.21, anchorY: 0.00, isLeft: false, zPos: 38, bendAngle: -0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 30, imgX:  -220.0, imgY:   228.1, width:  470.0, height: 1520.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 39, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 31, imgX:    68.4, imgY:    -8.5, width:  470.0, height: 1520.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 40, bendAngle: -0.035, duration: 3.35, shouldSway: true)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant28GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = StandardPlantBounceMotionEffect(bounceIntensity: 0.6, durationMultiplier: 1.0)
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .deepOcean)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant28GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant28GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant28GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant28GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        case .mature:
            buildMatureState()
        }
    }

    // MARK: - State 100: Hạt giống (Seed)

    private func buildSeedState() {
        let baseCanvasW: CGFloat = 2480.0
        let baseCanvasH: CGFloat = 2642.0
        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.90
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        if let scene = loadSceneTemplate(),
           let seedGroup = scene.childNode(withName: "seedNode") {
            seedGroup.removeFromParent()
            seedGroup.isHidden = false
            seedGroup.isPaused = false
            seedGroup.speed = 1.0
            plantRootNode.addChild(seedGroup)

            if let sprite = seedGroup.childNode(withName: "seedSprite") as? SKSpriteNode {
                if sprite.texture == nil {
                    sprite.texture = loadSeedTexture()
                }
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0.05)
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.seedNode = sprite
                self.initialSeedPosition = sprite.position
            }
            return
        }

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "seedNode"
        fallbackGroup.position = CGPoint(x: 0, y: 0)

        let node = SKSpriteNode(texture: loadSeedTexture())
        node.name = "seedSprite"
        node.size = CGSize(width: 80, height: 60)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0, y: -18.5)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
    }

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasW: CGFloat = 2480.0
        let baseCanvasH: CGFloat = 2642.0
        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.90
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        if let scene = loadSceneTemplate(),
           let sproutGroup = scene.childNode(withName: "sproutNode") {
            sproutGroup.removeFromParent()
            sproutGroup.isHidden = false
            sproutGroup.isPaused = false
            sproutGroup.speed = 1.0
            plantRootNode.addChild(sproutGroup)

            if let sprite = sproutGroup.childNode(withName: "sproutSprite") as? SKSpriteNode {
                if sprite.texture == nil {
                    sprite.texture = loadSproutTexture()
                }
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0.05)
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.sproutNode = sprite
                self.initialSproutPosition = sprite.position
            }
            return
        }

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "sproutNode"
        fallbackGroup.position = CGPoint(x: 0, y: 0)

        let node = SKSpriteNode(texture: loadSproutTexture())
        node.name = "sproutSprite"
        node.size = CGSize(width: 140, height: 160)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0, y: -18.5)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
    }

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng myrtle xanh)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 2480.0
        let baseCanvasH: CGFloat = 2642.0

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant28Scene.sks
        if let scene = loadSceneTemplate(),
           let templateMature = scene.childNode(withName: "matureNode") {
            templateMature.removeFromParent()
            templateMature.isHidden = false
            templateMature.isPaused = false
            templateMature.speed = 1.0
            plantRootNode.addChild(templateMature)

            let sortedLeaves = templateMature.children.compactMap { $0 as? SKSpriteNode }.sorted {
                let id1 = Int($0.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let id2 = Int($1.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                return id1 < id2
            }

            for (idx, leaf) in sortedLeaves.enumerated() {
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leaf.restZRotation = leaf.zRotation
                leafNodes.append(leaf)

                let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetId })

                if leaf.texture == nil {
                    leaf.texture = loadPlantTexture(assetId: assetId)
                }

                if meta?.shouldSway ?? true {
                    let bend = meta?.bendAngle ?? 0.035
                    let dur = meta?.duration ?? 3.2
                    startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur, phaseDelay: Double(idx) * 0.18)
                }
            }
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -10)
        plantRootNode.addChild(fallbackGroup)

        for (idx, leafData) in Self.leavesMetadata.enumerated() {
            guard let texture = loadPlantTexture(assetId: leafData.assetId) else { continue }

            let leaf = SKSpriteNode(texture: texture)
            leaf.name = "leaf_\(leafData.assetId)"
            leaf.size = CGSize(width: leafData.width, height: leafData.height)
            leaf.anchorPoint = CGPoint(x: leafData.anchorX, y: leafData.anchorY)
            leaf.position = CGPoint(x: leafData.imgX, y: leafData.imgY)
            leaf.zPosition = leafData.zPos

            fallbackGroup.addChild(leaf)
            leaf.restZRotation = leaf.zRotation
            leafNodes.append(leaf)

            if leafData.shouldSway {
                startLeafIdleAnimation(leaf: leaf, bendAngle: leafData.bendAngle, duration: leafData.duration, phaseDelay: Double(idx) * 0.18)
            }
        }
    }

    // MARK: - Hoạt ảnh nhàn rỗi (Idle Animation)

    private func startLeafIdleAnimation(leaf: SKSpriteNode, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval) {
        leaf.removeAction(forKey: "plantIdleAction")
        let rest = leaf.restZRotation
        leaf.zRotation = rest

        let rotateRight = SKAction.rotate(toAngle: rest + bendAngle, duration: duration * 0.5)
        rotateRight.timingMode = .easeInEaseOut
        let rotateLeft = SKAction.rotate(toAngle: rest - bendAngle, duration: duration)
        rotateLeft.timingMode = .easeInEaseOut
        let rotateBack = SKAction.rotate(toAngle: rest, duration: duration * 0.5)
        rotateBack.timingMode = .easeInEaseOut

        let swaySeq = SKAction.sequence([rotateRight, rotateLeft, rotateBack])

        let fullAction: SKAction
        if "standard" == "breathe" {
            let breatheUp = SKAction.scaleY(to: 1.025, duration: duration * 0.5)
            breatheUp.timingMode = .easeInEaseOut
            let breatheDown = SKAction.scaleY(to: 0.985, duration: duration * 0.5)
            breatheDown.timingMode = .easeInEaseOut
            let breatheCycle = SKAction.sequence([breatheUp, breatheDown])
            fullAction = SKAction.group([swaySeq, breatheCycle])
        } else {
            fullAction = swaySeq
        }

        if phaseDelay > 0 {
            leaf.run(SKAction.sequence([
                SKAction.wait(forDuration: phaseDelay),
                SKAction.repeatForever(fullAction)
            ]), withKey: "plantIdleAction")
        } else {
            leaf.run(SKAction.repeatForever(fullAction), withKey: "plantIdleAction")
        }
    }

    // MARK: - Khôi phục chuyển động nhàn rỗi sau Tap

    public func resumeIdleAnimation() {
        for (idx, leaf) in leafNodes.enumerated() {
            let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetId })
            if meta?.shouldSway ?? true {
                let bend = meta?.bendAngle ?? 0.035
                let dur = meta?.duration ?? 3.2
                startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur, phaseDelay: Double(idx) * 0.18)
            }
        }
    }

    // MARK: - Phản hồi tương tác Tap

    public func playTapAnimation() {
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

        let lvl = growthState.rawLevel
        for effect in tapEffects {
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant28Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant28-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant28_Asset-100@4.167x",
            "plant28_Asset-100"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }

    private func loadSproutTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-200@4.167x",
            "plant1_Asset-200",
            "plant28_Asset-200@4.167x",
            "plant28_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

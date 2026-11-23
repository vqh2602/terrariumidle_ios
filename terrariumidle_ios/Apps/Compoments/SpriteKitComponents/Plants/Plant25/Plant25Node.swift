//
//  Plant25Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Xương rồng thùng hồng (Plant25 - Echinocactus grusonii)

public enum Plant25GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant25

public final class Plant25Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng thùng hồng (Canvas 1128 x 1048)

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
        LeafData(assetId: 2, imgX:    31.0, imgY:    -5.6, width:  529.0, height:  754.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 3, imgX:    34.8, imgY:    -3.9, width:  345.0, height:  213.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 12, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 4, imgX:   -79.7, imgY:    -7.5, width:  513.0, height:  303.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 13, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 5, imgX:    45.4, imgY:     2.2, width:  557.0, height:  522.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 14, bendAngle: -0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 6, imgX:   -58.2, imgY:    -1.7, width:  371.0, height:  533.0, anchorX: 0.62, anchorY: 0.00, isLeft: true , zPos: 15, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 7, imgX:    43.4, imgY:    -5.9, width:  307.0, height:  348.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 16, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 8, imgX:   -58.1, imgY:     6.5, width:  500.0, height: 1036.0, anchorX: 0.37, anchorY: 0.00, isLeft: false, zPos: 17, bendAngle: -0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 9, imgX:   -44.0, imgY:    11.2, width:  526.0, height:  929.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 18, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 10, imgX:   -26.3, imgY:    -0.8, width:  550.0, height:  962.0, anchorX: 0.36, anchorY: 0.00, isLeft: false, zPos: 19, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 11, imgX:  -257.8, imgY:   133.9, width:  394.0, height:  394.0, anchorX: 0.33, anchorY: 0.00, isLeft: true , zPos: 20, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 12, imgX:    -2.9, imgY:    -6.4, width:  200.0, height:   30.0, anchorX: 0.57, anchorY: 0.00, isLeft: true , zPos: 21, bendAngle:  0.035, duration: 3.70, shouldSway: true)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant25GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = ConnectedPlantSwayMotionEffect(swayAngle: 0.018)
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .floralPink)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant25GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant25GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant25GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant25GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasW: CGFloat = 1128.0
        let baseCanvasH: CGFloat = 1048.0
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
        let baseCanvasW: CGFloat = 1128.0
        let baseCanvasH: CGFloat = 1048.0
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

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng thùng hồng)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 1128.0
        let baseCanvasH: CGFloat = 1048.0

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant25Scene.sks
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

            for leaf in sortedLeaves {
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leaf.restZRotation = leaf.zRotation
                leafNodes.append(leaf)

                let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0

                if leaf.texture == nil {
                    leaf.texture = loadPlantTexture(assetId: assetId)
                }

            }
            startPlantIdleAnimation()
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -10)
        plantRootNode.addChild(fallbackGroup)

        for leafData in Self.leavesMetadata {
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

        }
        startPlantIdleAnimation()
    }

    // Keep the assembled stems and leaves attached while gently swaying the whole plant.
    private func startPlantIdleAnimation() {
        plantRootNode.removeAction(forKey: "idleSway")
        plantRootNode.zRotation = 0
        plantRootNode.setScale(baseScale)
        guard case .mature = growthState else { return }
        let right = SKAction.rotate(toAngle: 0.004, duration: 2.4)
        let left = SKAction.rotate(toAngle: -0.004, duration: 4.8)
        let settle = SKAction.rotate(toAngle: 0, duration: 2.4)
        right.timingMode = .easeInEaseOut
        left.timingMode = .easeInEaseOut
        settle.timingMode = .easeInEaseOut
        plantRootNode.run(.repeatForever(.sequence([right, left, settle])), withKey: "idleSway")
    }

    public func resumeIdleAnimation() {
        for leaf in leafNodes {
            leaf.removeAction(forKey: "plantIdleAction")
            leaf.zRotation = leaf.restZRotation
            leaf.setScale(1)
        }
        startPlantIdleAnimation()
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
        return SKScene(fileNamed: "Plant25Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant25-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant25_Asset-100@4.167x",
            "plant25_Asset-100"
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
            "plant25_Asset-200@4.167x",
            "plant25_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

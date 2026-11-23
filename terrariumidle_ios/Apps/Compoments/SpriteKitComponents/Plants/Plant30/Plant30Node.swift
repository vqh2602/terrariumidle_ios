//
//  Plant30Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Hoa lan chuông trắng (Plant30 - Convallaria majalis)

public enum Plant30GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant30

public final class Plant30Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Hoa lan chuông trắng (Canvas 279 x 587)

    private struct LeafData {
        let assetId: Int
        let imgX: CGFloat
        let imgY: CGFloat
        let width: CGFloat
        let height: CGFloat
        let anchorX: CGFloat
        let anchorY: CGFloat
        let zPos: CGFloat
    }

    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 3, imgX:    38.9, imgY:   187.9, width:   70.0, height:   97.0, anchorX: 0.05, anchorY: 0.00, zPos: 11),
        LeafData(assetId: 4, imgX:    41.1, imgY:   194.0, width:   72.0, height:   26.0, anchorX: 0.05, anchorY: 0.00, zPos: 12),
        LeafData(assetId: 5, imgX:   108.4, imgY:   175.7, width:  107.0, height:   25.0, anchorX: 0.71, anchorY: 0.00, zPos: 13),
        LeafData(assetId: 6, imgX:    37.8, imgY:    -2.9, width:   15.0, height:  377.0, anchorX: 0.56, anchorY: 0.00, zPos: 14),
        LeafData(assetId: 7, imgX:    34.5, imgY:   366.4, width:   31.0, height:  151.0, anchorX: 0.95, anchorY: 0.00, zPos: 15),
        LeafData(assetId: 8, imgX:    35.9, imgY:   370.1, width:   88.0, height:  108.0, anchorX: 0.05, anchorY: 0.00, zPos: 16),
        LeafData(assetId: 9, imgX:   -21.9, imgY:   408.9, width:  137.0, height:  143.0, anchorX: 0.86, anchorY: 0.00, zPos: 17),
        LeafData(assetId: 10, imgX:   -25.1, imgY:   344.7, width:   37.0, height:   73.0, anchorX: 0.95, anchorY: 0.00, zPos: 18),
        LeafData(assetId: 11, imgX:   -23.9, imgY:   214.7, width:   69.0, height:  116.0, anchorX: 0.94, anchorY: 0.00, zPos: 19),
        LeafData(assetId: 12, imgX:   -11.6, imgY:    42.8, width:   75.0, height:   96.0, anchorX: 0.90, anchorY: 0.00, zPos: 20),
        LeafData(assetId: 13, imgX:    36.6, imgY:    74.1, width:   66.0, height:   83.0, anchorX: 0.05, anchorY: 0.00, zPos: 21),
        LeafData(assetId: 14, imgX:    36.5, imgY:   296.5, width:   35.0, height:  104.0, anchorX: 0.27, anchorY: 0.00, zPos: 22),
        LeafData(assetId: 15, imgX:    74.4, imgY:   316.2, width:   50.0, height:   85.0, anchorX: 0.32, anchorY: 0.00, zPos: 23),
        LeafData(assetId: 16, imgX:    39.0, imgY:   249.3, width:   95.0, height:   98.0, anchorX: 0.05, anchorY: 0.00, zPos: 24),
        LeafData(assetId: 17, imgX:   -20.8, imgY:    -9.9, width:   12.0, height:  460.0, anchorX: 0.33, anchorY: 0.00, zPos: 25),
        LeafData(assetId: 18, imgX:    -5.6, imgY:   -10.6, width:   15.0, height:  426.0, anchorX: 0.33, anchorY: 0.00, zPos: 26),
        LeafData(assetId: 19, imgX:    15.3, imgY:    -7.3, width:   17.0, height:  364.0, anchorX: 0.50, anchorY: 0.00, zPos: 27),
        LeafData(assetId: 20, imgX:   -22.4, imgY:   178.1, width:   76.0, height:  100.0, anchorX: 0.95, anchorY: 0.00, zPos: 28),
        LeafData(assetId: 21, imgX:   -29.9, imgY:   156.1, width:   80.0, height:   31.0, anchorX: 0.81, anchorY: 0.00, zPos: 29),
        LeafData(assetId: 22, imgX:    32.5, imgY:   362.7, width:   77.0, height:   50.0, anchorX: 0.95, anchorY: 0.00, zPos: 30),
        LeafData(assetId: 23, imgX:    33.0, imgY:   397.9, width:   21.0, height:   80.0, anchorX: 0.56, anchorY: 0.00, zPos: 31),
        LeafData(assetId: 24, imgX:    13.4, imgY:   340.2, width:   43.0, height:   73.0, anchorX: 0.72, anchorY: 0.00, zPos: 32),
        LeafData(assetId: 25, imgX:   -26.4, imgY:   444.4, width:   33.0, height:  138.0, anchorX: 0.65, anchorY: 0.00, zPos: 33),
        LeafData(assetId: 26, imgX:    88.0, imgY:     4.2, width:   62.0, height:   88.0, anchorX: 0.95, anchorY: 0.00, zPos: 34),
        LeafData(assetId: 27, imgX:   -20.6, imgY:    21.9, width:   97.0, height:  107.0, anchorX: 0.95, anchorY: 0.00, zPos: 35)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant30GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = BambooWindMotionEffect()
    public var tapEffects: [PlantTapEffect] = [SparklePollenEffect(), OxygenBubblesEffect(theme: .deepOcean)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant30GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant30GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant30GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant30GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    // MARK: - Build Scene theo trạng thái

    public func build() {
        plantRootNode.removeAllChildren()
        plantRootNode.removeAllActions()
        plantRootNode.zRotation = 0
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
        let baseCanvasW: CGFloat = 279.0
        let baseCanvasH: CGFloat = 587.0
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
        let baseCanvasW: CGFloat = 279.0
        let baseCanvasH: CGFloat = 587.0
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

    // MARK: - State 3+: Trưởng thành (Mature Hoa lan chuông trắng)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 279.0
        let baseCanvasH: CGFloat = 587.0

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant30Scene.sks
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
            attachLeavesToStems()
            resumeIdleAnimation()
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
        attachLeavesToStems()
        resumeIdleAnimation()
    }

    /// Giữ nguyên hình ghép từ Scene Editor, nhưng cho lá thừa hưởng chuyển động thân.
    private func attachLeavesToStems() {
        let stems = leafNodes.filter { BambooWindMotionEffect.stemNames.contains($0.name ?? "") }
        for leaf in leafNodes where !BambooWindMotionEffect.stemNames.contains(leaf.name ?? "") {
            guard let parent = leaf.parent,
                  let stem = stems.min(by: {
                      abs($0.convert(.zero, to: parent).x - leaf.position.x)
                        < abs($1.convert(.zero, to: parent).x - leaf.position.x)
                  }) else { continue }
            let position = stem.convert(leaf.position, from: parent)
            let rotation = leaf.zRotation - stem.zRotation
            let xScale = leaf.xScale / stem.xScale
            let yScale = leaf.yScale / stem.yScale
            let depth = leaf.zPosition - stem.zPosition
            leaf.removeFromParent()
            // Xoay ở khớp trên thân, tránh lá có anchor giữa phiến bị tuột cuống.
            let pivot = SKNode()
            pivot.name = "bambooLeafPivot_\(leaf.name ?? "leaf")"
            pivot.position = CGPoint(x: 0, y: position.y)
            pivot.zPosition = depth
            pivot.restZRotation = 0
            stem.addChild(pivot)
            pivot.addChild(leaf)
            leaf.position = CGPoint(x: position.x, y: 0)
            leaf.zRotation = rotation
            leaf.xScale = xScale
            leaf.yScale = yScale
            leaf.zPosition = 0
            leaf.restZRotation = rotation
        }
    }

    // MARK: - Hoạt ảnh nhàn rỗi

    public func resumeIdleAnimation() {
        guard case .mature = growthState else { return }
        for leaf in leafNodes {
            let node = BambooWindMotionEffect.motionNode(for: leaf)
            node.removeAction(forKey: "leafWind")
            let rest = node.restZRotation
            node.zRotation = rest
            let isStem = BambooWindMotionEffect.stemNames.contains(leaf.name ?? "")
            let id = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let angle: CGFloat = isStem ? 0.004 : 0.10 + CGFloat(id % 4) * 0.015
            let duration: TimeInterval = isStem ? 2.6 : 1.5
            let targets: [(CGFloat, Double)] = [
                (angle, 0.65), (-angle * 0.35, 0.55),
                (angle * 0.22, 0.25), (-angle * 0.08, 0.20), (0, 0.35)
            ]
            let actions = targets.map { offset, fraction in
                let action = SKAction.rotate(toAngle: rest + offset, duration: duration * fraction)
                action.timingMode = .easeInEaseOut
                return action
            }
            node.run(.sequence([
                .wait(forDuration: Double(id % 5) * 0.055),
                .repeatForever(.sequence(actions))
            ]), withKey: "leafWind")
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
            containerSize: containerSize
        )

        let lvl = growthState.rawLevel
        for effect in tapEffects {
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant30Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant30-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant30_Asset-100@4.167x",
            "plant30_Asset-100"
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
            "plant30_Asset-200@4.167x",
            "plant30_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

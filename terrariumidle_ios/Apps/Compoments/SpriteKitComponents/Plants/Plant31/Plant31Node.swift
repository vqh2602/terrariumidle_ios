//
//  Plant31Node.swift
//  terrariumidle_ios
//
//  Created by AI on 27/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Hoa sen hồng (Plant31 - Nelumbo nucifera)

public enum Plant31GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant31

public final class Plant31Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Hoa sen hồng (Canvas 479.8 x 794.1)

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

    private static let stemIds: Set<Int> = [2, 4]
    private static let lotusLeafIds: Set<Int> = [3, 5]
    private static let topFlowerPetalIds: Set<Int> = Set(6...13)
    private static let leftFlowerPetalIds: Set<Int> = Set(14...31)

    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId:  2, imgX:    38.9, imgY:     4.2, width:   40.2, height:  655.2, anchorX: 0.50, anchorY: 0.00, zPos: 11),
        LeafData(assetId:  6, imgX:    41.9, imgY:   675.4, width:   55.6, height:   91.4, anchorX: 0.05, anchorY: 0.05, zPos: 12),
        LeafData(assetId:  7, imgX:    30.8, imgY:   665.4, width:   66.4, height:   89.3, anchorX: 0.95, anchorY: 0.05, zPos: 13),
        LeafData(assetId:  8, imgX:    32.7, imgY:   679.0, width:   64.0, height:   88.1, anchorX: 0.63, anchorY: 0.05, zPos: 14),
        LeafData(assetId:  9, imgX:    34.7, imgY:   720.5, width:   36.6, height:   64.3, anchorX: 0.05, anchorY: 0.05, zPos: 15),
        LeafData(assetId: 10, imgX:    61.8, imgY:   741.0, width:   20.0, height:   26.9, anchorX: 0.05, anchorY: 0.05, zPos: 16),
        LeafData(assetId: 11, imgX:    32.4, imgY:   742.3, width:   47.7, height:   48.6, anchorX: 0.93, anchorY: 0.05, zPos: 17),
        LeafData(assetId: 12, imgX:    32.4, imgY:   664.7, width:   40.7, height:   29.8, anchorX: 0.18, anchorY: 0.23, zPos: 18),
        LeafData(assetId: 13, imgX:    22.8, imgY:   664.8, width:   32.2, height:   10.8, anchorX: 0.95, anchorY: 0.92, zPos: 19),
        LeafData(assetId:  3, imgX:    31.2, imgY:    -5.5, width:  361.9, height:  465.0, anchorX: 0.58, anchorY: 0.00, zPos: 20),
        LeafData(assetId:  4, imgX:   -29.4, imgY:    -1.8, width:   71.3, height:  350.9, anchorX: 0.50, anchorY: 0.00, zPos: 21),
        LeafData(assetId: 14, imgX:   -64.9, imgY:   462.7, width:   71.6, height:   93.2, anchorX: 0.95, anchorY: 0.05, zPos: 22),
        LeafData(assetId: 15, imgX:   -50.3, imgY:   434.5, width:   64.2, height:   32.5, anchorX: 0.44, anchorY: 0.05, zPos: 23),
        LeafData(assetId: 16, imgX:   -46.1, imgY:   401.1, width:   32.2, height:   45.5, anchorX: 0.05, anchorY: 0.05, zPos: 24),
        LeafData(assetId: 17, imgX:   -26.1, imgY:   402.5, width:   84.0, height:  102.6, anchorX: 0.05, anchorY: 0.05, zPos: 25),
        LeafData(assetId: 18, imgX:   -69.8, imgY:   351.0, width:  133.7, height:   77.7, anchorX: 0.95, anchorY: 0.72, zPos: 26),
        LeafData(assetId: 19, imgX:    27.8, imgY:   443.1, width:   93.3, height:   50.7, anchorX: 0.05, anchorY: 0.05, zPos: 27),
        LeafData(assetId: 20, imgX:   -50.0, imgY:   462.4, width:   76.9, height:   92.8, anchorX: 0.07, anchorY: 0.05, zPos: 28),
        LeafData(assetId: 21, imgX:    -6.9, imgY:   378.8, width:   82.5, height:   90.1, anchorX: 0.05, anchorY: 0.05, zPos: 29),
        LeafData(assetId: 22, imgX:    19.0, imgY:   359.9, width:  126.3, height:   96.1, anchorX: 0.05, anchorY: 0.05, zPos: 30),
        LeafData(assetId: 23, imgX:   -50.2, imgY:   351.5, width:   89.4, height:   57.8, anchorX: 0.22, anchorY: 0.18, zPos: 31),
        LeafData(assetId: 24, imgX:  -129.9, imgY:   427.1, width:   36.3, height:  117.3, anchorX: 0.95, anchorY: 0.05, zPos: 32),
        LeafData(assetId: 25, imgX:  -107.8, imgY:   438.2, width:   54.7, height:  104.9, anchorX: 0.95, anchorY: 0.05, zPos: 33),
        LeafData(assetId: 26, imgX:   -50.0, imgY:   367.9, width:   98.7, height:  111.7, anchorX: 0.85, anchorY: 0.05, zPos: 34),
        LeafData(assetId: 27, imgX:  -120.4, imgY:   374.7, width:  118.6, height:   76.3, anchorX: 0.95, anchorY: 0.05, zPos: 35),
        LeafData(assetId: 28, imgX:  -128.9, imgY:   383.5, width:  116.9, height:   97.4, anchorX: 0.95, anchorY: 0.05, zPos: 36),
        LeafData(assetId: 29, imgX:   -66.0, imgY:   349.3, width:  137.7, height:   62.9, anchorX: 0.95, anchorY: 0.95, zPos: 37),
        LeafData(assetId: 30, imgX:   -48.7, imgY:   341.6, width:  107.0, height:   93.3, anchorX: 0.05, anchorY: 0.95, zPos: 38),
        LeafData(assetId: 31, imgX:   -42.1, imgY:   351.3, width:  109.0, height:  103.2, anchorX: 0.05, anchorY: 0.95, zPos: 39),
        LeafData(assetId:  5, imgX:    -4.3, imgY:    -1.8, width:  420.1, height:  252.6, anchorX: 0.42, anchorY: 0.00, zPos: 40)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant31GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = FlowerSwayMotionEffect()
    public var tapEffects: [PlantTapEffect] = [
        FloatingPetalsEffect(theme: .sakuraPink),
        SparklePollenEffect(theme: .golden),
        OxygenBubblesEffect(theme: .floralPink)
    ]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant31GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant31GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant31GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant31GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasW: CGFloat = 479.8
        let baseCanvasH: CGFloat = 794.1
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
        let baseCanvasW: CGFloat = 479.8
        let baseCanvasH: CGFloat = 794.1
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

    // MARK: - State 3+: Trưởng thành (Mature Hoa sen hồng)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 479.8
        let baseCanvasH: CGFloat = 794.1

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant31Scene.sks
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
            attachPetalsToStems()
            resumeIdleAnimation()
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -5.5)
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
        attachPetalsToStems()
        resumeIdleAnimation()
    }

    /// Gắn từng cánh hoa vào cuống hoa của cành tương ứng để cả bông hoa đung đưa theo cành và từng cánh đung đưa riêng.
    private func attachPetalsToStems() {
        let stemById: [Int: SKSpriteNode] = Dictionary(
            uniqueKeysWithValues: leafNodes.compactMap { node in
                let id = Int(node.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                return Self.stemIds.contains(id) ? (id, node) : nil
            }
        )

        for petal in leafNodes {
            let id = Int(petal.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let stemId: Int?
            if Self.topFlowerPetalIds.contains(id) {
                stemId = 2
            } else if Self.leftFlowerPetalIds.contains(id) {
                stemId = 4
            } else {
                stemId = nil
            }

            guard let targetStemId = stemId,
                  let stem = stemById[targetStemId],
                  let parent = petal.parent else { continue }

            let convertedPos = stem.convert(petal.position, from: parent)
            let convertedRot = petal.zRotation - stem.zRotation
            let convertedXScale = petal.xScale / stem.xScale
            let convertedYScale = petal.yScale / stem.yScale
            let convertedZ = petal.zPosition - stem.zPosition

            petal.removeFromParent()
            stem.addChild(petal)
            petal.position = convertedPos
            petal.zRotation = convertedRot
            petal.xScale = convertedXScale
            petal.yScale = convertedYScale
            petal.zPosition = convertedZ
            petal.restZRotation = convertedRot
        }
    }

    // MARK: - Hoạt ảnh nhàn rỗi (Hoa đung đưa + Từng cánh hoa đung đưa + Lá sen đung đưa)

    public func resumeIdleAnimation() {
        guard case .mature = growthState else { return }

        for leaf in leafNodes {
            leaf.removeAction(forKey: "leafWind")
            let rest = leaf.restZRotation
            leaf.zRotation = rest

            let id = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0

            let angle: CGFloat
            let duration: TimeInterval
            let phaseDelay: TimeInterval

            if Self.stemIds.contains(id) {
                // Cành hoa đung đưa nhẹ mang theo toàn bộ bông hoa
                angle = id == 2 ? 0.018 : 0.022
                duration = id == 2 ? 2.9 : 3.2
                phaseDelay = id == 2 ? 0.0 : 0.35
            } else if Self.lotusLeafIds.contains(id) {
                // Lá sen đung đưa dịu dàng
                angle = id == 3 ? 0.025 : 0.020
                duration = id == 3 ? 2.7 : 3.1
                phaseDelay = id == 3 ? 0.2 : 0.55
            } else {
                // Từng cánh hoa đung đưa mềm mại quanh cuống cánh
                angle = 0.032 + CGFloat(id % 4) * 0.006
                duration = 2.0 + Double(id % 5) * 0.18
                phaseDelay = Double(id % 7) * 0.12
            }

            let swayRight = SKAction.rotate(toAngle: rest + angle, duration: duration)
            swayRight.timingMode = .easeInEaseOut
            let swayLeft = SKAction.rotate(toAngle: rest - angle, duration: duration)
            swayLeft.timingMode = .easeInEaseOut

            leaf.run(.sequence([
                .wait(forDuration: phaseDelay),
                .repeatForever(.sequence([swayRight, swayLeft]))
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
        return SKScene(fileNamed: "Plant31Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant31-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant31_Asset-100@4.167x",
            "plant31_Asset-100"
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
            "plant31_Asset-200@4.167x",
            "plant31_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

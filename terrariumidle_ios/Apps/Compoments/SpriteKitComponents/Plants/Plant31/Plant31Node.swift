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

    // MARK: - Metadata cấu trúc các bộ phận Hoa sen hồng (Canvas 62.014 x 102.637)

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

    private static let stemIds: Set<Int> = [1, 15]
    private static let lotusLeafIds: Set<Int> = [2, 16]
    private static let mainFlowerPetalIds: Set<Int> = Set(3...14)

    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId:  1, imgX:    30.4, imgY:     8.2, width:  124.3, height:  768.0, anchorX: 0.50, anchorY: 0.00, zPos: 11.0),
        LeafData(assetId:  2, imgX:    30.6, imgY:     2.4, width:  354.4, height:  455.3, anchorX: 0.58, anchorY: 0.00, zPos: 11.5),
        LeafData(assetId:  3, imgX:   -68.5, imgY:   459.5, width:   70.2, height:   91.3, anchorX: 0.88, anchorY: 0.12, zPos: 12.0),
        LeafData(assetId:  4, imgX:   -19.8, imgY:   401.2, width:   82.2, height:  100.4, anchorX: 0.12, anchorY: 0.12, zPos: 12.5),
        LeafData(assetId:  5, imgX:    33.7, imgY:   437.5, width:   91.4, height:   49.6, anchorX: 0.12, anchorY: 0.12, zPos: 13.0),
        LeafData(assetId:  6, imgX:   -45.2, imgY:   459.2, width:   75.2, height:   90.9, anchorX: 0.12, anchorY: 0.12, zPos: 13.5),
        LeafData(assetId:  7, imgX:    -1.1, imgY:   401.0, width:   80.8, height:   88.1, anchorX: 0.12, anchorY: 0.39, zPos: 14.0),
        LeafData(assetId:  8, imgX:    27.2, imgY:   400.4, width:  123.7, height:   94.1, anchorX: 0.12, anchorY: 0.56, zPos: 14.5),
        LeafData(assetId:  9, imgX:   -51.8, imgY:   383.9, width:   87.5, height:   56.6, anchorX: 0.19, anchorY: 0.88, zPos: 15.0),
        LeafData(assetId: 10, imgX:  -109.9, imgY:   426.3, width:   58.0, height:  114.8, anchorX: 0.88, anchorY: 0.12, zPos: 15.5),
        LeafData(assetId: 11, imgX:   -53.9, imgY:   400.8, width:  117.0, height:  109.3, anchorX: 0.66, anchorY: 0.42, zPos: 16.0),
        LeafData(assetId: 12, imgX:  -126.9, imgY:   400.2, width:  122.8, height:  103.0, anchorX: 0.88, anchorY: 0.36, zPos: 16.5),
        LeafData(assetId: 13, imgX:   -74.0, imgY:   355.2, width:  134.9, height:   81.6, anchorX: 0.88, anchorY: 0.88, zPos: 17.0),
        LeafData(assetId: 14, imgX:   -39.3, imgY:   336.9, width:  113.1, height:  101.3, anchorX: 0.12, anchorY: 0.88, zPos: 17.5),
        LeafData(assetId: 15, imgX:   -40.9, imgY:     1.6, width:   45.9, height:  344.3, anchorX: 0.50, anchorY: 0.00, zPos: 18.0),
        LeafData(assetId: 16, imgX:    -4.2, imgY:     2.3, width:  411.3, height:  247.4, anchorX: 0.42, anchorY: 0.00, zPos: 18.5)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant31GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = ConnectedPlantSwayMotionEffect(swayAngle: 0.065, bounceScale: 1.12, flowerNodeNames: ["leaf_1", "leaf_15"])
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
        let baseCanvasW: CGFloat = 469.834533827
        let baseCanvasH: CGFloat = 777.629081117
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
        fallbackGroup.position = CGPoint(x: 0.000000000, y: 0.000000000)

        let node = SKSpriteNode(texture: loadSeedTexture())
        node.name = "seedSprite"
        node.size = CGSize(width: 10.339952878, height: 7.754964658)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -2.391114103)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
    }

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasW: CGFloat = 469.834533827
        let baseCanvasH: CGFloat = 777.629081117
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
        fallbackGroup.position = CGPoint(x: 0.000000000, y: 0.000000000)

        let node = SKSpriteNode(texture: loadSproutTexture())
        node.name = "sproutSprite"
        node.size = CGSize(width: 18.094917536, height: 20.679905756)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -2.391114103)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
    }

    // MARK: - State 3+: Trưởng thành (Mature Hoa sen hồng)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 469.834533827
        let baseCanvasH: CGFloat = 777.629081117

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
        fallbackGroup.position = CGPoint(x: 0.000000000, y: -0.710871760)
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
            guard Self.mainFlowerPetalIds.contains(id),
                  let stem = stemById[15],
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
                // Cả cụm hoa chính và nụ hoa trên đung đưa rõ nét theo gió (mang theo toàn bộ cánh hoa không vỡ khớp)
                angle = id == 1 ? 0.045 : 0.055
                duration = id == 1 ? 2.1 : 2.3
                phaseDelay = id == 1 ? 0.0 : 0.25
            } else if Self.lotusLeafIds.contains(id) {
                // Lá sen đung đưa mạnh mẽ, mềm mại theo gió quanh gốc cuống
                angle = id == 2 ? 0.060 : 0.050
                duration = id == 2 ? 2.0 : 2.4
                phaseDelay = id == 2 ? 0.15 : 0.45
            } else {
                // Các cánh hoa (3...14) là mảng ghép liền khối gắn trên cành leaf_15:
                // giữ nguyên góc nghỉ để bông hoa đung đưa đồng bộ theo cành, không bị hở vết cắt giữa các cánh.
                continue
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

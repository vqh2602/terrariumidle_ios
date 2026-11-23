//
//  Plant29Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Xương rồng trụ xoắn (Plant29 - Cereus forbesii spiralis)

public enum Plant29GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant29

public final class Plant29Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng trụ xoắn (Canvas 449.561 x 795.577)

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
        LeafData(assetId: 2, imgX:  -58.692682927, imgY:   -5.255284553, width:  370.471544715, height: 768.000000000, anchorX: 0.34, anchorY: 0.00, zPos: 11),
        LeafData(assetId: 3, imgX:  -155.889430894, imgY:  549.151219512, width:  85.853658537, height:  70.764227642, anchorX: 0.62, anchorY: 0.00, zPos: 12),
        LeafData(assetId: 4, imgX:  -112.234146341, imgY:   140.591869919, width:  91.056910569, height:  98.341463415, anchorX: 0.47, anchorY: 0.00, zPos: 13),
        LeafData(assetId: 5, imgX:  -129.769105691, imgY:  608.260162602, width:   32.780487805, height:   36.943089431, anchorX: 0.47, anchorY: 0.00, zPos: 14),
        LeafData(assetId: 6, imgX:  -62.855284553, imgY:  664.195121951, width:   41.105691057, height:   35.382113821, anchorX: 0.35, anchorY: 0.00, zPos: 15),
        LeafData(assetId: 7, imgX:   85.801626016, imgY:   161.248780488, width:   44.747967480, height:  67.642276423, anchorX: 0.45, anchorY: 0.00, zPos: 16),
        LeafData(assetId: 8, imgX:  -85.489430894, imgY:   458.354471545, width:  118.113821138, height:  163.382113821, anchorX: 0.46, anchorY: 0.00, zPos: 17),
        LeafData(assetId: 9, imgX:   162.237398374, imgY:   163.382113821, width:  123.837398374, height:  123.837398374, anchorX: 0.49, anchorY: 0.00, zPos: 18),
        LeafData(assetId: 10, imgX:  -125.242276423, imgY:   404.136585366, width:  123.317073171, height:  96.780487805, anchorX: 0.73, anchorY: 0.00, zPos: 19),
        LeafData(assetId: 11, imgX:  -181.177235772, imgY:  612.370731707, width:  112.390243902, height:  108.227642276, anchorX: 0.39, anchorY: 0.00, zPos: 20),
        LeafData(assetId: 12, imgX:    5.775609756, imgY:   177.639024390, width:  145.691056911, height:  197.723577236, anchorX: 0.53, anchorY: 0.00, zPos: 21),
        LeafData(assetId: 13, imgX:   -10.510569106, imgY:   385.456910569, width:  184.195121951, height:  165.983739837, anchorX: 0.29, anchorY: 0.00, zPos: 22),
        LeafData(assetId: 14, imgX:     4.058536585, imgY:  663.934959350, width:  111.869918699, height:  126.439024390, anchorX: 0.62, anchorY: 0.00, zPos: 23),
        LeafData(assetId: 15, imgX:   158.699186992, imgY:   285.710569106, width:  76.487804878, height:  107.707317073, anchorX: 0.60, anchorY: 0.00, zPos: 24)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant29GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = ConnectedPlantSwayMotionEffect(swayAngle: 0.075)
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .goldenSun)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant29GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant29GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant29GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant29GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasW: CGFloat = 449.560975610
        let baseCanvasH: CGFloat = 795.577235772
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
        node.size = CGSize(width: 41.626016260, height: 31.219512195)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -9.626016260)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
    }

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasW: CGFloat = 449.560975610
        let baseCanvasH: CGFloat = 795.577235772
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
        node.size = CGSize(width: 72.845528455, height: 83.252032520)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -9.626016260)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
    }

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng trụ xoắn)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 449.560975610
        let baseCanvasH: CGFloat = 795.577235772

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant29Scene.sks
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
            resumeIdleAnimation()
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0.000000000, y: -5.203252033)
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
        resumeIdleAnimation()
    }

    // MARK: - Hoạt ảnh nhàn rỗi (Idle Animation)

    public func resumeIdleAnimation() {
        guard case .mature = growthState else { return }

        // Một phép xoay chung giữ nguyên mọi điểm nối giữa thân, cành, hoa và nụ.
        // Key này được stopIdleActions() dừng sạch trước khi chạy hiệu ứng tap.
        plantRootNode.removeAction(forKey: "plantSway")
        plantRootNode.zRotation = 0
        let lean = SKAction.rotate(toAngle: 0.028, duration: 1.2)
        let rebound = SKAction.rotate(toAngle: -0.020, duration: 1.8)
        let followThrough = SKAction.rotate(toAngle: 0.010, duration: 1.0)
        let settle = SKAction.rotate(toAngle: 0, duration: 0.8)
        for action in [lean, rebound, followThrough, settle] {
            action.timingMode = .easeInEaseOut
        }
        plantRootNode.run(.repeatForever(.sequence([
            lean, rebound, followThrough, settle
        ])), withKey: "plantSway")
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
        return SKScene(fileNamed: "Plant29Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant29-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant29_Asset-100@4.167x",
            "plant29_Asset-100"
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
            "plant29_Asset-200@4.167x",
            "plant29_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

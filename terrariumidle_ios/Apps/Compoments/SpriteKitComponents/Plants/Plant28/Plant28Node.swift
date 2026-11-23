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

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng myrtle xanh (Canvas 566.487 x 603.491)

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
        LeafData(assetId: 2, imgX:     2.078640810, imgY:  396.198075356, width:  50.252854758, height:  205.123016241, anchorX: 0.08, anchorY: 0.00, isLeft: false, zPos: 11.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 3, imgX:  -78.508664457, imgY:  374.383767950, width:  50.252854758, height:  205.123016241, anchorX: 0.08, anchorY: 0.00, isLeft: true , zPos: 11.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 4, imgX:    21.403147686, imgY:  302.773449919, width:  152.814362879, height: 229.107333285, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 12.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 5, imgX:  -32.024773805, imgY:   108.683219518, width:  145.276434665, height: 251.721117926, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 12.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 6, imgX:   52.559917636, imgY:   211.061989985, width:  145.276434665, height: 251.721117926, anchorX: 0.42, anchorY: 0.00, isLeft: false, zPos: 13.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 7, imgX:   121.657592929, imgY:   149.913402627, width:  206.950392778, height:  197.585088027, anchorX: 0.22, anchorY: 0.00, isLeft: false, zPos: 13.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 8, imgX:    18.159554333, imgY:   88.719130855, width:  185.021874338, height: 279.588610110, anchorX: 0.34, anchorY: 0.00, isLeft: false, zPos: 14.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 9, imgX:    16.446388830, imgY:  326.643555929, width:  97.307800578, height: 265.198019884, anchorX: 0.62, anchorY: 0.00, isLeft: false, zPos: 14.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 10, imgX:  -33.715097102, imgY:   199.092673670, width:  157.839648355, height: 286.898116257, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 15.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 11, imgX:    10.872890393, imgY:  235.091991442, width:  107.358371529, height: 347.201541967, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 15.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 12, imgX:   -8.862776203, imgY:   116.860729520, width:  83.374054485, height: 269.309617091, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 16.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 13, imgX:   121.771803962, imgY:   177.895105845, width:  145.276434665, height: 251.721117926, anchorX: 0.42, anchorY: 0.00, isLeft: false, zPos: 16.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 14, imgX:   119.053581364, imgY:   177.506788331, width:  178.397634392, height:  84.287742754, anchorX: 0.08, anchorY: 0.00, isLeft: false, zPos: 17.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 15, imgX:   83.145632418, imgY:   178.443318806, width:  63.729756716, height:  205.808282442, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 17.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 16, imgX:  -116.929256140, imgY:   144.271377570, width:  162.636511763, height:  144.819590531, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 18.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 17, imgX:  -57.745098559, imgY:  268.647193097, width:  152.814362879, height: 229.107333285, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 18.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 18, imgX:  -172.253080788, imgY:  255.627135273, width:  145.276434665, height: 251.721117926, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 19.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 19, imgX:  -137.875559692, imgY:   133.284276143, width:  185.021874338, height: 279.588610110, anchorX: 0.66, anchorY: 0.00, isLeft: true , zPos: 19.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 20, imgX:  -110.830386949, imgY:   161.425874808, width:  83.374054485, height: 269.309617091, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 20.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 21, imgX:  -79.445194932, imgY:   144.705379497, width:  145.276434665, height: 251.721117926, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 20.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 22, imgX:  -44.153985567, imgY:  259.327572760, width:  97.307800578, height: 265.198019884, anchorX: 0.38, anchorY: 0.00, isLeft: true , zPos: 21.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 23, imgX:  -41.115972075, imgY:   123.781918153, width:  114.667877676, height: 301.745550617, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 21.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 24, imgX:  -38.877435818, imgY:   167.776008273, width:  107.358371529, height: 347.201541967, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 22.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 25, imgX:  -132.256376841, imgY:   125.449399242, width:  188.676627411, height:  214.945165126, anchorX: 0.80, anchorY: 0.00, isLeft: true , zPos: 22.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 26, imgX:  -122.205805890, imgY:   45.752940037, width:  83.374054485, height: 269.309617091, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 23.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 27, imgX:  -90.820613872, imgY:   29.032444726, width:  145.276434665, height: 251.721117926, anchorX: 0.58, anchorY: 0.00, isLeft: true , zPos: 23.5, bendAngle: 0.076, duration: 2.8, shouldSway: true),
        LeafData(assetId: 28, imgX:  -52.491391016, imgY:    8.108983381, width:  114.667877676, height: 301.745550617, anchorX: 0.37, anchorY: 0.00, isLeft: true , zPos: 24.0, bendAngle: 0.058, duration: 2.8, shouldSway: true),
        LeafData(assetId: 29, imgX:   64.643444985, imgY:   131.388372986, width:  220.198872668, height: 244.411611779, anchorX: 0.21, anchorY: 0.00, isLeft: false, zPos: 24.5, bendAngle: 0.064, duration: 2.8, shouldSway: true),
        LeafData(assetId: 30, imgX:  -50.252854758, imgY:   52.103073502, width:  107.358371529, height: 347.201541967, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 25.0, bendAngle: 0.070, duration: 2.8, shouldSway: true),
        LeafData(assetId: 31, imgX:    15.624069389, imgY:    -1.941587570, width:  107.358371529, height: 347.201541967, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 25.5, bendAngle: 0.076, duration: 2.8, shouldSway: true)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant28GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = FlowerSwayMotionEffect()
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
        let baseCanvasW: CGFloat = 566.486726367
        let baseCanvasH: CGFloat = 603.491101234
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
        node.size = CGSize(width: 18.273765367, height: 13.705324025)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -4.225808241)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
    }

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasW: CGFloat = 566.486726367
        let baseCanvasH: CGFloat = 603.491101234
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
        node.size = CGSize(width: 31.979089392, height: 36.547530733)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -4.225808241)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
    }

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng myrtle xanh)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 566.486726367
        let baseCanvasH: CGFloat = 603.491101234

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

            for leaf in sortedLeaves {
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leaf.restZRotation = leaf.zRotation
                leafNodes.append(leaf)

                let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetId })

                if let meta = meta {
                    leaf.zPosition = meta.zPos
                }

                if leaf.texture == nil {
                    leaf.texture = loadPlantTexture(assetId: assetId)
                }

                if meta?.shouldSway ?? true {
                    let bend = meta?.bendAngle ?? 0.035
                    let dur = meta?.duration ?? 3.2
                    startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur)
                }
            }
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0.000000000, y: -2.284220671)
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

            if leafData.shouldSway {
                startLeafIdleAnimation(leaf: leaf, bendAngle: leafData.bendAngle, duration: leafData.duration)
            }
        }
    }

    // MARK: - Hoạt ảnh nhàn rỗi (Idle Animation)

    private func startLeafIdleAnimation(leaf: SKSpriteNode, bendAngle: CGFloat, duration: TimeInterval) {
        leaf.removeAction(forKey: "leafWind")
        let rest = leaf.restZRotation
        leaf.zRotation = rest

        // Gió lướt qua các cành theo vị trí tán, giữ hoa và cuống chuyển động liền khối.
        let phaseDelay = Double(min(max((leaf.frame.midX + 1240) / 2480, 0), 1)) * 0.42
        let lean = SKAction.rotate(toAngle: rest + bendAngle, duration: duration * 0.64)
        let rebound = SKAction.rotate(toAngle: rest - bendAngle * 0.38, duration: duration * 0.66)
        let flutter = SKAction.rotate(toAngle: rest + bendAngle * 0.16, duration: duration * 0.30)
        let settle = SKAction.rotate(toAngle: rest, duration: duration * 0.40)
        for action in [lean, rebound, flutter, settle] {
            action.timingMode = .easeInEaseOut
        }
        leaf.run(.sequence([
            .wait(forDuration: phaseDelay),
            .repeatForever(.sequence([lean, rebound, flutter, settle]))
        ]), withKey: "leafWind")
    }

    // MARK: - Khôi phục chuyển động nhàn rỗi sau Tap

    public func resumeIdleAnimation() {
        for leaf in leafNodes {
            let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetId })
            if meta?.shouldSway ?? true {
                let bend = meta?.bendAngle ?? 0.035
                let dur = meta?.duration ?? 3.2
                startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur)
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
            containerSize: containerSize
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

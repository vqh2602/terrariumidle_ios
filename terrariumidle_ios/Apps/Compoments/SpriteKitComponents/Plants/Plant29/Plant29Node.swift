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

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng trụ xoắn (Canvas 864 x 1529)

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
        LeafData(assetId: 2, imgX:  -112.8, imgY:   -10.1, width:  712.0, height: 1476.0, anchorX: 0.34, anchorY: 0.00, zPos: 11),
        LeafData(assetId: 3, imgX:  -299.6, imgY:  1055.4, width:  165.0, height:  136.0, anchorX: 0.62, anchorY: 0.00, zPos: 12),
        LeafData(assetId: 4, imgX:  -215.7, imgY:   270.2, width:  175.0, height:  189.0, anchorX: 0.47, anchorY: 0.00, zPos: 13),
        LeafData(assetId: 5, imgX:  -249.4, imgY:  1169.0, width:   63.0, height:   71.0, anchorX: 0.47, anchorY: 0.00, zPos: 14),
        LeafData(assetId: 6, imgX:  -120.8, imgY:  1276.5, width:   79.0, height:   68.0, anchorX: 0.35, anchorY: 0.00, zPos: 15),
        LeafData(assetId: 7, imgX:   164.9, imgY:   309.9, width:   86.0, height:  130.0, anchorX: 0.45, anchorY: 0.00, zPos: 16),
        LeafData(assetId: 8, imgX:  -164.3, imgY:   880.9, width:  227.0, height:  314.0, anchorX: 0.46, anchorY: 0.00, zPos: 17),
        LeafData(assetId: 9, imgX:   311.8, imgY:   314.0, width:  238.0, height:  238.0, anchorX: 0.49, anchorY: 0.00, zPos: 18),
        LeafData(assetId: 10, imgX:  -240.7, imgY:   776.7, width:  237.0, height:  186.0, anchorX: 0.73, anchorY: 0.00, zPos: 19),
        LeafData(assetId: 11, imgX:  -348.2, imgY:  1176.9, width:  216.0, height:  208.0, anchorX: 0.39, anchorY: 0.00, zPos: 20),
        LeafData(assetId: 12, imgX:    11.1, imgY:   341.4, width:  280.0, height:  380.0, anchorX: 0.53, anchorY: 0.00, zPos: 21),
        LeafData(assetId: 13, imgX:   -20.2, imgY:   740.8, width:  354.0, height:  319.0, anchorX: 0.29, anchorY: 0.00, zPos: 22),
        LeafData(assetId: 14, imgX:     7.8, imgY:  1276.0, width:  215.0, height:  243.0, anchorX: 0.62, anchorY: 0.00, zPos: 23),
        LeafData(assetId: 15, imgX:   305.0, imgY:   549.1, width:  147.0, height:  207.0, anchorX: 0.60, anchorY: 0.00, zPos: 24)
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
        let baseCanvasW: CGFloat = 864.0
        let baseCanvasH: CGFloat = 1529.0
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
        let baseCanvasW: CGFloat = 864.0
        let baseCanvasH: CGFloat = 1529.0
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

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng trụ xoắn)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 864.0
        let baseCanvasH: CGFloat = 1529.0

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

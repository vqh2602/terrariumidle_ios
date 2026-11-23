//
//  Plant27Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Xương rồng cột Andes (Plant27 - Oreocereus celsianus)

public enum Plant27GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant27

public final class Plant27Node: SKNode {

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng cột Andes (Canvas 447 x 859)

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
        LeafData(assetId: 3, imgX:    -1.4, imgY:   -11.0, width:   20.0, height:  679.0, anchorX: 0.40, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: 0.003, duration: 2.6, shouldSway: true),
        LeafData(assetId: 4, imgX:    12.0, imgY:   270.3, width:  222.0, height:  144.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 12, bendAngle: 0.075, duration: 2.6, shouldSway: true),
        LeafData(assetId: 5, imgX:   -10.8, imgY:   386.0, width:  227.0, height:  144.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 13, bendAngle: 0.080, duration: 2.6, shouldSway: true),
        LeafData(assetId: 6, imgX:  -114.1, imgY:   170.7, width:  139.0, height:  147.0, anchorX: 0.16, anchorY: 0.00, isLeft: true , zPos: 14, bendAngle: 0.065, duration: 2.6, shouldSway: true),
        LeafData(assetId: 7, imgX:     7.6, imgY:   532.3, width:  181.0, height:  206.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 15, bendAngle: 0.075, duration: 2.6, shouldSway: true),
        LeafData(assetId: 8, imgX:     3.5, imgY:   580.5, width:  337.0, height:  271.0, anchorX: 0.51, anchorY: 0.00, isLeft: true , zPos: 16, bendAngle: 0.055, duration: 2.6, shouldSway: true),
        LeafData(assetId: 9, imgX:    10.5, imgY:   485.1, width:  172.0, height:  171.0, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 17, bendAngle: 0.085, duration: 2.6, shouldSway: true),
        LeafData(assetId: 10, imgX:    -7.0, imgY:   444.0, width:  130.0, height:  140.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 18, bendAngle: 0.080, duration: 2.6, shouldSway: true),
        LeafData(assetId: 11, imgX:  -114.4, imgY:   326.9, width:  175.0, height:  124.0, anchorX: 0.36, anchorY: 0.00, isLeft: true , zPos: 19, bendAngle: 0.085, duration: 2.6, shouldSway: true),
        LeafData(assetId: 12, imgX:   107.3, imgY:   194.2, width:  192.0, height:  115.0, anchorX: 0.58, anchorY: 0.00, isLeft: false, zPos: 20, bendAngle: 0.080, duration: 2.6, shouldSway: true),
        LeafData(assetId: 13, imgX:    23.9, imgY:   394.4, width:  222.0, height:  174.0, anchorX: 0.12, anchorY: 0.00, isLeft: false, zPos: 21, bendAngle: 0.070, duration: 2.6, shouldSway: true),
        LeafData(assetId: 14, imgX:    -6.3, imgY:   529.0, width:  137.0, height:  172.0, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 22, bendAngle: 0.075, duration: 2.6, shouldSway: true)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant27GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = BroadleafWindMotionEffect(stemNodeNames: ["leaf_3"])
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .goldenSun)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant27GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant27GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant27GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant27GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        let baseCanvasW: CGFloat = 447.0
        let baseCanvasH: CGFloat = 859.0
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
        let baseCanvasW: CGFloat = 447.0
        let baseCanvasH: CGFloat = 859.0
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

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng cột Andes)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 447.0
        let baseCanvasH: CGFloat = 859.0

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant27Scene.sks
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

        // Cùng chiều gió, lệch pha nhẹ từ lá thấp lên ngọn; không co giãn cuống lá.
        let phaseDelay = Double(min(max(leaf.position.y / 859.0, 0), 1)) * 0.32
        let gust = SKAction.rotate(toAngle: rest + bendAngle, duration: duration * 0.60)
        let recoil = SKAction.rotate(toAngle: rest - bendAngle * 0.30, duration: duration * 0.62)
        let flutter = SKAction.rotate(toAngle: rest + bendAngle * 0.12, duration: duration * 0.32)
        let settle = SKAction.rotate(toAngle: rest, duration: duration * 0.46)
        for action in [gust, recoil, flutter, settle] {
            action.timingMode = .easeInEaseOut
        }
        leaf.run(.sequence([
            .wait(forDuration: phaseDelay),
            .repeatForever(.sequence([gust, recoil, flutter, settle]))
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
        return SKScene(fileNamed: "Plant27Scene")
    }

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {
        let name = "plant27-\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return nil
    }

    private func loadSeedTexture() -> SKTexture {
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant27_Asset-100@4.167x",
            "plant27_Asset-100"
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
            "plant27_Asset-200@4.167x",
            "plant27_Asset-200"
        ]
        for name in candidates {
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 { return tex }
        }
        return SKTexture()
    }
}

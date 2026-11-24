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

    // MARK: - Metadata cấu trúc các bộ phận Xương rồng thùng hồng (Canvas 654.478 x 608.061)

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
        LeafData(assetId: 2, imgX:    17.986533040, imgY:    -3.249180162, width:  306.931483171, height:  437.478900399, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 11, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 3, imgX:    20.191333865, imgY:    -2.262821899, width:  200.172706416, height:  123.584888309, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 12, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 4, imgX:   -46.242796236, imgY:    -4.351580574, width:  297.648111280, height:  175.803855200, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 13, bendAngle:  0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 5, imgX:    26.341567743, imgY:     1.276463635, width:  323.177383982, height:  302.870007969, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 14, bendAngle: -0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 6, imgX:   -33.768265256, imgY:    -0.986358263, width:  215.258185740, height:  309.252326144, anchorX: 0.62, anchorY: 0.00, isLeft: true , zPos: 15, bendAngle:  0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 7, imgX:    25.181146256, imgY:    -3.423243385, width:  178.124698173, height:  201.913338646, anchorX: 0.05, anchorY: 0.00, isLeft: false, zPos: 16, bendAngle: -0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 8, imgX:   -33.710244182, imgY:     3.771369831, width:  290.105371618, height: 601.098329991, anchorX: 0.37, anchorY: 0.00, isLeft: false, zPos: 17, bendAngle: -0.035, duration: 3.70, shouldSway: true),
        LeafData(assetId: 9, imgX:   -25.529272702, imgY:    6.498360324, width:  305.190850942, height:  539.015780465, anchorX: 0.95, anchorY: 0.00, isLeft: true , zPos: 18, bendAngle:  0.035, duration: 4.05, shouldSway: true),
        LeafData(assetId: 10, imgX:   -15.259542547, imgY:    -0.464168595, width:  319.115908779, height:  558.162734992, anchorX: 0.36, anchorY: 0.00, isLeft: false, zPos: 19, bendAngle: -0.035, duration: 3.00, shouldSway: true),
        LeafData(assetId: 11, imgX:  -149.578329606, imgY:   77.690218519, width:  228.603032835, height:  228.603032835, anchorX: 0.33, anchorY: 0.00, isLeft: true , zPos: 20, bendAngle:  0.035, duration: 3.35, shouldSway: true),
        LeafData(assetId: 12, imgX:    -1.682611155, imgY:    -3.713348757, width:  116.042148647, height:   17.406322297, anchorX: 0.57, anchorY: 0.00, isLeft: true , zPos: 21, bendAngle:  0.035, duration: 3.70, shouldSway: true)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant25GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    public var motionEffect: PlantMotionEffect = ConnectedPlantSwayMotionEffect(
        swayAngle: 0.052,
        bounceScale: 1.14,
        flowerNodeNames: ["leaf_11"]
    )
    public var tapEffects: [PlantTapEffect] = [
        FloatingPetalsEffect(),
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
        let baseCanvasW: CGFloat = 654.477718369
        let baseCanvasH: CGFloat = 608.060858910
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
            startPlantIdleAnimation()
            return
        }

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "seedNode"
        fallbackGroup.position = CGPoint(x: 0.000000000, y: 0.000000000)

        let node = SKSpriteNode(texture: loadSeedTexture())
        node.name = "seedSprite"
        node.size = CGSize(width: 46.416859459, height: 34.812644594)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -10.733898750)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
        startPlantIdleAnimation()
    }

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasW: CGFloat = 654.477718369
        let baseCanvasH: CGFloat = 608.060858910
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
            startPlantIdleAnimation()
            return
        }

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "sproutNode"
        fallbackGroup.position = CGPoint(x: 0.000000000, y: 0.000000000)

        let node = SKSpriteNode(texture: loadSproutTexture())
        node.name = "sproutSprite"
        node.size = CGSize(width: 81.229504053, height: 92.833718918)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0.000000000, y: -10.733898750)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
        startPlantIdleAnimation()
    }

    // MARK: - State 3+: Trưởng thành (Mature Xương rồng thùng hồng)

    private func buildMatureState() {
        let baseCanvasW: CGFloat = 654.477718369
        let baseCanvasH: CGFloat = 608.060858910

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
        fallbackGroup.position = CGPoint(x: 0.000000000, y: -5.802107432)
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

    // MARK: - Hoạt ảnh nhàn rỗi (Idle Animation)

    /// Toàn bộ thân cây xương rồng đu đưa nhịp nhàng + thở đàn hồi mọng nước, bông hoa đỉnh đung đưa nhẹ đón gió
    private func startPlantIdleAnimation() {
        plantRootNode.removeAction(forKey: "plantSway")
        plantRootNode.removeAction(forKey: "idleSway")
        plantRootNode.zRotation = 0
        plantRootNode.setScale(baseScale)

        for leaf in leafNodes {
            leaf.removeAction(forKey: "leafSway")
            leaf.removeAction(forKey: "plantIdleAction")
            leaf.zRotation = leaf.restZRotation
            leaf.setScale(1)
        }

        switch growthState {
        case .seed:
            // Hạt giống: nhấp nháy phát sáng & thở nhẹ
            guard let seed = seedNode else { return }
            seed.removeAction(forKey: "seedBreath")
            let b1 = SKAction.scale(to: 1.07, duration: 1.6)
            b1.timingMode = .easeInEaseOut
            let b2 = SKAction.scale(to: 1.0, duration: 1.8)
            b2.timingMode = .easeInEaseOut
            seed.run(.repeatForever(.sequence([b1, b2])), withKey: "seedBreath")

        case .sprout:
            // Cây con: đung đưa nhẹ mầm non
            guard let sprout = sproutNode else { return }
            sprout.removeAction(forKey: "sproutSway")
            let s1 = SKAction.rotate(toAngle: 0.040, duration: 1.5)
            s1.timingMode = .easeInEaseOut
            let s2 = SKAction.rotate(toAngle: -0.040, duration: 1.9)
            s2.timingMode = .easeInEaseOut
            let s3 = SKAction.rotate(toAngle: 0, duration: 1.4)
            s3.timingMode = .easeInEaseOut
            sprout.run(.repeatForever(.sequence([s1, s2, s3])), withKey: "sproutSway")

        case .mature:
            // 1. Toàn bộ thân cây xương rồng: Đu đưa nhịp nhàng + Nhịp thở đàn hồi mọng nước
            let swayRight = SKAction.rotate(toAngle: 0.024, duration: 2.2)
            swayRight.timingMode = .easeInEaseOut
            let swayLeft = SKAction.rotate(toAngle: -0.020, duration: 2.6)
            swayLeft.timingMode = .easeInEaseOut
            let swaySettle = SKAction.rotate(toAngle: 0, duration: 1.8)
            swaySettle.timingMode = .easeInEaseOut
            let swaySeq = SKAction.sequence([swayRight, swayLeft, swaySettle])

            let breatheUp = SKAction.scaleX(to: baseScale * 0.985, y: baseScale * 1.025, duration: 2.2)
            breatheUp.timingMode = .easeInEaseOut
            let breatheDown = SKAction.scaleX(to: baseScale * 1.015, y: baseScale * 0.985, duration: 2.4)
            breatheDown.timingMode = .easeInEaseOut
            let breatheSettle = SKAction.scale(to: baseScale, duration: 2.0)
            breatheSettle.timingMode = .easeInEaseOut
            let breatheSeq = SKAction.sequence([breatheUp, breatheDown, breatheSettle])

            plantRootNode.run(.repeatForever(SKAction.group([swaySeq, breatheSeq])), withKey: "plantSway")

            // 2. Bông hoa hồng trên đỉnh (leaf_11): Đung đưa nhẹ quanh cuống đón gió
            if let flower = leafNodes.first(where: { $0.name == "leaf_11" }) {
                let rest = flower.restZRotation
                let fRight = SKAction.rotate(toAngle: rest + 0.038, duration: 1.8)
                fRight.timingMode = .easeInEaseOut
                let fLeft = SKAction.rotate(toAngle: rest - 0.032, duration: 2.2)
                fLeft.timingMode = .easeInEaseOut
                let fBack = SKAction.rotate(toAngle: rest, duration: 1.6)
                fBack.timingMode = .easeInEaseOut
                flower.run(.repeatForever(.sequence([fRight, fLeft, fBack])), withKey: "leafSway")
            }
        }
    }

    public func resumeIdleAnimation() {
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

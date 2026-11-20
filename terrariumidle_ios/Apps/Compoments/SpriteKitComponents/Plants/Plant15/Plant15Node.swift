//
//  Plant15Node.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Chuỗi Tim (Plant15 - Ceropegia woodii)

public enum Plant15GrowthState: Equatable {
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant15

public final class Plant15Node: SKNode {

    // MARK: - Metadata cấu trúc 6 nhánh dây lá tim Ceropegia woodii (Canvas 657 x 763)

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
    }

    /// Tọa độ pixel và điểm neo cuống dây lá tim Ceropegia woodii (Canvas 657 x 763)
    /// Đung đưa mềm mại tự nhiên như dây leo rủ trong gió
    private static let leavesMetadata: [LeafData] = [
        LeafData(assetId: 2, imgX:  94.0, imgY: 178.0, width: 263, height: 260, anchorX: 0.85, anchorY: 0.01, isLeft: true , zPos: 13, bendAngle: 0.095, duration: 4.2),
        LeafData(assetId: 3, imgX: 169.0, imgY:   0.0, width: 204, height: 436, anchorX: 0.75, anchorY: 0.01, isLeft: true , zPos: 11, bendAngle: 0.060, duration: 5.4),
        LeafData(assetId: 4, imgX: 387.0, imgY: 304.0, width: 197, height: 134, anchorX: 0.15, anchorY: 0.01, isLeft: false, zPos: 14, bendAngle: 0.110, duration: 3.8),
        LeafData(assetId: 5, imgX: 367.0, imgY: 110.0, width: 194, height: 326, anchorX: 0.15, anchorY: 0.01, isLeft: false, zPos: 12, bendAngle: 0.080, duration: 4.8),
        LeafData(assetId: 6, imgX: 335.0, imgY: 392.0, width: 322, height: 371, anchorX: 0.12, anchorY: 0.01, isLeft: false, zPos: 16, bendAngle: 0.090, duration: 4.5),
        LeafData(assetId: 7, imgX:   0.0, imgY: 336.0, width: 322, height: 230, anchorX: 0.88, anchorY: 0.01, isLeft: true , zPos: 15, bendAngle: 0.105, duration: 4.0),
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant15GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Danh sách các hiệu ứng thị giác khi tap vào cây (mặc định Bọt khí Oxy Deep Ocean)
    public var tapEffects: [PlantTapEffect] = [OxygenBubblesEffect(theme: .deepOcean)]

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant15GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant15GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant15GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant15GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
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
        case .mature(let level):
            buildMatureState(level: level)
        }
    }

    // MARK: - Level 1: Hạt giống (Seed)

    private func buildSeedState() {
        let baseCanvasWidth: CGFloat = 657.0
        let baseCanvasHeight: CGFloat = 763.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp seedNode từ Plant15Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSeedNode = scene.childNode(withName: "seedNode") {
            let seedSprite = templateSeedNode.childNode(withName: "seedSprite") as? SKSpriteNode

            templateSeedNode.removeFromParent()
            templateSeedNode.isHidden = false
            templateSeedNode.isPaused = false
            templateSeedNode.speed = 1.0

            if let sprite = seedSprite {
                if sprite.texture == nil {
                    sprite.texture = loadTexture(assetId: 100)
                }
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.initialSeedPosition = sprite.position
                self.seedNode = sprite
            }

            plantRootNode.addChild(templateSeedNode)
            startSeedAnimation()
            return
        }

        // 2. Fallback procedural
        guard let seedTexture = loadTexture(assetId: 100) else { return }
        let seed = SKSpriteNode(texture: seedTexture)
        seed.name = "seedSprite"
        seed.size = CGSize(width: 80, height: 60)
        seed.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        seed.position = CGPoint(x: 0, y: -18.5)
        seed.zPosition = 10
        seed.isPaused = false
        seed.speed = 1.0

        plantRootNode.addChild(seed)
        self.seedNode = seed
        self.initialSeedPosition = seed.position
        startSeedAnimation()
    }

    // MARK: - Level 2: Cây con (Sprout)

    private func buildSproutState() {
        let baseCanvasWidth: CGFloat = 657.0
        let baseCanvasHeight: CGFloat = 763.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH) * 1.05
        plantRootNode.setScale(baseScale)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp sproutNode từ Plant15Scene.sks
        if let scene = loadSceneTemplate(),
           let templateSproutNode = scene.childNode(withName: "sproutNode") {
            let sproutSprite = templateSproutNode.childNode(withName: "sproutSprite") as? SKSpriteNode

            templateSproutNode.removeFromParent()
            templateSproutNode.isHidden = false
            templateSproutNode.isPaused = false
            templateSproutNode.speed = 1.0

            if let sprite = sproutSprite {
                if sprite.texture == nil {
                    sprite.texture = loadTexture(assetId: 200)
                }
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.initialSproutPosition = sprite.position
                self.sproutNode = sprite
            }

            plantRootNode.addChild(templateSproutNode)
            startSproutAnimation()
            return
        }

        // 2. Fallback procedural
        guard let sproutTexture = loadTexture(assetId: 200) else { return }
        let sprout = SKSpriteNode(texture: sproutTexture)
        sprout.name = "sproutSprite"
        sprout.size = CGSize(width: 140, height: 160)
        sprout.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        sprout.position = CGPoint(x: 0, y: -18.5)
        sprout.zPosition = 10
        sprout.isPaused = false
        sprout.speed = 1.0

        plantRootNode.addChild(sprout)
        self.sproutNode = sprout
        self.initialSproutPosition = sprout.position
        startSproutAnimation()
    }

    // MARK: - Level 3+: Cây trưởng thành (Mature - 6 nhánh dây Ceropegia woodii)

    private func buildMatureState(level: Int) {
        let baseCanvasWidth: CGFloat = 657.0
        let baseCanvasHeight: CGFloat = 763.0

        let fitW = containerSize.width / baseCanvasWidth
        let fitH = containerSize.height / baseCanvasHeight
        baseScale = min(fitW, fitH)

        let levelBonus = CGFloat(min(level, 10) - 3) * 0.015
        plantRootNode.setScale(baseScale * (1.0 + levelBonus))

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp matureNode từ Plant15Scene.sks
        if let scene = loadSceneTemplate(),
           let matureGroup = scene.childNode(withName: "matureNode") {
            matureGroup.removeFromParent()
            matureGroup.isHidden = false
            matureGroup.isPaused = false
            matureGroup.speed = 1.0
            plantRootNode.addChild(matureGroup)

            let sortedLeaves = matureGroup.children.compactMap { $0 as? SKSpriteNode }.sorted {
                let id1 = Int($0.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let id2 = Int($1.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                return id1 < id2
            }

            for (idx, leaf) in sortedLeaves.enumerated() {
                let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                if leaf.texture == nil {
                    leaf.texture = loadTexture(assetId: assetNum)
                }
                if let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum }) {
                    leaf.size = CGSize(width: meta.width, height: meta.height)
                    leaf.anchorPoint = CGPoint(x: meta.anchorX, y: meta.anchorY)
                }
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leafNodes.append(leaf)

                let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
                let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                let bendAngle = meta?.bendAngle ?? 0.055
                let duration = meta?.duration ?? 3.2
                let phaseDelay = Double(idx) * 0.20
                let isMainVine = (assetNum == 3)

                startVineAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: phaseDelay, isMainVine: isMainVine)
            }

            addTrunkSwayAnimation()
            return
        }

        // 2. Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -10)
        plantRootNode.addChild(fallbackGroup)

        for (idx, data) in Self.leavesMetadata.enumerated() {
            guard let leafTexture = loadTexture(assetId: data.assetId) else { continue }

            let leaf = SKSpriteNode(texture: leafTexture)
            leaf.name = "leaf_\(data.assetId)"
            leaf.size = CGSize(width: data.width, height: data.height)
            leaf.anchorPoint = CGPoint(x: data.anchorX, y: data.anchorY)

            let skX = (data.imgX + data.anchorX * data.width) - (baseCanvasWidth / 2.0)
            let skY = baseCanvasHeight - data.imgY - (1.0 - data.anchorY) * data.height

            leaf.position = CGPoint(x: skX, y: skY)
            leaf.zPosition = data.zPos
            leaf.isPaused = false
            leaf.speed = 1.0

            fallbackGroup.addChild(leaf)
            leafNodes.append(leaf)

            let phaseDelay = Double(idx) * 0.20
            let isMainVine = (data.assetId == 3)
            startVineAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration, phaseDelay: phaseDelay, isMainVine: isMainVine)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        plantRootNode.removeAction(forKey: "trunkSway")

        let angle: CGFloat = 0.006
        let swayLeft = SKAction.rotate(toAngle: angle, duration: 4.8)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: -angle, duration: 4.8)
        swayRight.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([swayLeft, swayRight])
        plantRootNode.run(SKAction.repeatForever(sequence), withKey: "trunkSway")
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Plant15Scene")
    }

    // MARK: - Texture Loader

    private func loadTexture(assetId: Int) -> SKTexture? {
        let nameVariants: [String]
        switch assetId {
        case 100:
            nameVariants = ["plant1_Asset-100@4.167x", "plant1_Asset-100", "seed"]
        case 200:
            nameVariants = ["plant1_Asset-200@4.167x", "plant1_Asset-200", "sprout"]
        default:
            nameVariants = [
                "Plant15-\(assetId)@4.167x",
                "plant15_Asset-\(assetId)@4.167x",
                "Plant15-\(assetId)",
                "plant15_\(assetId)"
            ]
        }

        for name in nameVariants {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }
        return nil
    }

    // MARK: - Animation & Phản hồi tương tác Tap

    public func playTapAnimation() {
        switch growthState {
        case .seed:
            playSeedTapAnimation()
        case .sprout:
            playSproutTapAnimation()
        case .mature:
            playMatureTapAnimation()
        }

        // Kích hoạt danh sách hiệu ứng tap đã đăng ký (Bọt khí Oxy Deep Ocean 3D...)
        let lvl = growthState.rawLevel
        for effect in tapEffects {
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }
    }

    private func playSeedTapAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedTapHop")
        node.position = initialSeedPosition

        let squash = SKAction.scaleX(to: 1.28, y: 0.72, duration: 0.08)
        squash.timingMode = .easeIn

        let jumpUp = SKAction.group([
            SKAction.moveTo(y: initialSeedPosition.y + 10, duration: 0.12),
            SKAction.scaleX(to: 0.85, y: 1.20, duration: 0.12)
        ])
        jumpUp.timingMode = .easeOut

        let fallDown = SKAction.group([
            SKAction.moveTo(y: initialSeedPosition.y, duration: 0.12),
            SKAction.scaleX(to: 1.12, y: 0.90, duration: 0.12)
        ])
        fallDown.timingMode = .easeIn

        let settle = SKAction.scale(to: 1.0, duration: 0.10)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([squash, jumpUp, fallDown, settle]), withKey: "seedTapHop")
    }

    private func playSproutTapAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutTapBounce")

        let squash = SKAction.scaleX(to: 1.18, y: 0.84, duration: 0.08)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: 0.90, y: 1.12, duration: 0.14)
        stretch.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([squash, stretch, settle]), withKey: "sproutTapBounce")
    }

    private func playMatureTapAnimation() {
        // Cây dây leo chuỗi tim: khi tap thì cành lá đung đưa lắc lư tự nhiên theo gió thay vì nhún nhảy co giãn
        for (idx, leaf) in leafNodes.enumerated() {
            let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })
            let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
            let impulseAngle: CGFloat = (isLeft ? -1.0 : 1.0) * CGFloat.random(in: 0.12...0.18)

            let delay = SKAction.wait(forDuration: Double(idx) * 0.04)
            // Lượn mạnh theo chiều gió rồi đung đưa êm dần về nhịp đung đưa tự nhiên
            let sway1 = SKAction.rotate(byAngle: impulseAngle, duration: 0.35)
            sway1.timingMode = .easeOut
            let sway2 = SKAction.rotate(byAngle: -impulseAngle * 1.4, duration: 0.55)
            sway2.timingMode = .easeInEaseOut
            let sway3 = SKAction.rotate(byAngle: impulseAngle * 0.6, duration: 0.50)
            sway3.timingMode = .easeInEaseOut
            let swayBack = SKAction.rotate(toAngle: 0.0, duration: 0.40)
            swayBack.timingMode = .easeInEaseOut

            let resumeNormalSway = SKAction.run { [weak self, weak leaf] in
                guard let self = self, let leaf = leaf else { return }
                let bendAngle = meta?.bendAngle ?? 0.09
                let duration = meta?.duration ?? 4.0
                let isMainVine = (assetNum == 3)
                self.startVineAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration, phaseDelay: 0, isMainVine: isMainVine)
            }

            let flutter = SKAction.sequence([delay, sway1, sway2, sway3, swayBack, resumeNormalSway])
            leaf.run(flutter, withKey: "leafTapJiggle")
        }
    }

    // MARK: - Animation tự nhiên dây leo Chuỗi Tim

    private func startVineAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval, isMainVine: Bool) {
        leaf.removeAction(forKey: "vineSway")

        let effectiveAngle = isMainVine ? (bendAngle * 0.25) : bendAngle
        let primaryAngle = isLeft ? -effectiveAngle : effectiveAngle
        let secondaryAngle = isLeft ? (effectiveAngle * 0.75) : (-effectiveAngle * 0.75)

        let bendOut = SKAction.rotate(toAngle: primaryAngle, duration: duration * 0.52)
        bendOut.timingMode = .easeInEaseOut
        let bendBack = SKAction.rotate(toAngle: secondaryAngle, duration: duration * 0.48)
        bendBack.timingMode = .easeInEaseOut

        let swaySequence = SKAction.sequence([bendOut, bendBack])
        let infiniteSway = SKAction.repeatForever(swaySequence)

        if phaseDelay > 0 {
            let delayAction = SKAction.wait(forDuration: phaseDelay)
            leaf.run(SKAction.sequence([delayAction, infiniteSway]), withKey: "vineSway")
        } else {
            leaf.run(infiniteSway, withKey: "vineSway")
        }
    }

    private func startSeedAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedBreathing")

        let breatheIn = SKAction.scale(to: 1.04, duration: 1.8)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scale(to: 0.98, duration: 1.8)
        breatheOut.timingMode = .easeInEaseOut

        node.run(SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut])), withKey: "seedBreathing")
    }

    private func startSproutAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutSway")

        let swayLeft = SKAction.rotate(toAngle: -0.04, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.04, duration: 2.2)
        swayRight.timingMode = .easeInEaseOut

        node.run(SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])), withKey: "sproutSway")
    }

    // MARK: - Hiệu ứng Bọt Khí Oxy (Oxygen Bubbles Convention - Lấy Plant1 làm chuẩn)

    private func spawnOxygenBubbles() {
        let bubbleCount: Int
        switch growthState {
        case .seed:
            bubbleCount = Int.random(in: 1...2)
        case .sprout:
            bubbleCount = Int.random(in: 3...4)
        case .mature:
            bubbleCount = Int.random(in: 8...12)
        }

        for i in 0..<bubbleCount {
            let radius: CGFloat
            let spawnX: CGFloat
            let spawnY: CGFloat
            let floatDistance: CGFloat

            switch growthState {
            case .seed:
                radius = CGFloat.random(in: 1.8...3.0)
                spawnX = CGFloat.random(in: -containerSize.width * 0.08...containerSize.width * 0.08)
                spawnY = CGFloat.random(in: containerSize.height * 0.03...containerSize.height * 0.12)
                floatDistance = CGFloat.random(in: 18...35)
            case .sprout:
                radius = CGFloat.random(in: 2.2...3.8)
                spawnX = CGFloat.random(in: -containerSize.width * 0.10...containerSize.width * 0.10)
                spawnY = CGFloat.random(in: containerSize.height * 0.05...containerSize.height * 0.20)
                floatDistance = CGFloat.random(in: 25...45)
            case .mature:
                radius = CGFloat.random(in: 3.5...7.5)
                floatDistance = CGFloat.random(in: 60...115)
                if !leafNodes.isEmpty && Bool.random() {
                    let randomLeaf = leafNodes.randomElement()!
                    let leafPos = randomLeaf.parent?.convert(randomLeaf.position, to: self) ?? randomLeaf.position
                    spawnX = leafPos.x + CGFloat.random(in: -20...20)
                    spawnY = max(containerSize.height * 0.18, min(containerSize.height * 0.90, leafPos.y + CGFloat.random(in: -15...25)))
                } else {
                    spawnX = CGFloat.random(in: -containerSize.width * 0.44...containerSize.width * 0.44)
                    spawnY = CGFloat.random(in: containerSize.height * 0.18...containerSize.height * 0.85)
                }
            }

            let bubble = SKShapeNode(circleOfRadius: radius)
            bubble.fillColor = UIColor(red: 0.65, green: 0.95, blue: 1.0, alpha: 0.70)
            bubble.strokeColor = UIColor(white: 1.0, alpha: 0.95)
            bubble.lineWidth = max(0.6, radius * 0.18)
            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 200
            bubble.alpha = 0.0
            bubble.setScale(0.3)

            // Điểm sáng phản chiếu trắng 3D căng bóng
            let highlightRadius = max(0.6, radius * 0.30)
            let highlight = SKShapeNode(circleOfRadius: highlightRadius)
            highlight.fillColor = UIColor(white: 1.0, alpha: 0.80)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -radius * 0.35, y: radius * 0.35)
            highlight.zPosition = 1
            bubble.addChild(highlight)

            // BẮT BUỘC add trực tiếp vào chính Node cây (addChild(bubble))
            addChild(bubble)

            let delay = Double(i) * Double.random(in: 0.04...0.09)
            let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.82...0.96), duration: 0.12)
            let scaleUp = SKAction.scale(to: 1.30, duration: 0.15)
            let appear = SKAction.group([fadeIn, scaleUp])

            let floatTime = Double.random(in: 1.1...1.8)
            let wobbleRange = CGFloat.random(in: 6...16)
            let wobbleCount = Int.random(in: 2...4)
            var wobbleActions: [SKAction] = []
            for w in 0..<wobbleCount {
                let dx = (w % 2 == 0) ? wobbleRange : -wobbleRange
                let wobble = SKAction.moveBy(x: dx, y: floatDistance / CGFloat(wobbleCount), duration: floatTime / Double(wobbleCount))
                wobble.timingMode = .easeInEaseOut
                wobbleActions.append(wobble)
            }
            let wobbleMotion = SKAction.sequence(wobbleActions)

            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: floatTime * 0.65),
                SKAction.fadeAlpha(to: 0.0, duration: floatTime * 0.35)
            ])

            let moveAndFade = SKAction.group([wobbleMotion, fadeOut])
            let fullSequence = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                appear,
                moveAndFade,
                SKAction.removeFromParent()
            ])

            bubble.run(fullSequence)
        }
    }
}

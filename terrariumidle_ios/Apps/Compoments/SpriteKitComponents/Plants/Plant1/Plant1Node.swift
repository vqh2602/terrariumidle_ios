//
//  Plant1Node.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng Cây Cỏ Loe (Plant1)

/// Định nghĩa 3 trạng thái sinh trưởng của Cây Cỏ Loe theo cấp độ game (Level 1 - 2 - 3):
/// - Level 1: Gieo hạt (sử dụng asset `Asset-100`)
/// - Level 2: Cây con (sử dụng asset `Asset-200`)
/// - Level 3+: Cây trưởng thành (ghép hoàn toàn từ các hoạt ảnh lá `Asset-2`...`Asset-19`, `Asset-1` là ảnh đại diện tĩnh đối chiếu)
public enum Plant1GrowthState: Equatable {
    /// Level 1: Gieo hạt (load Asset-100)
    case seed
    /// Level 2: Cây con (load Asset-200)
    case sprout
    /// Level 3+: Cây trưởng thành (load Assets 2...19 lá uốn cong)
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

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant1

public final class Plant1Node: SKNode {

    // MARK: - Metadata cấu trúc 18 phiến lá trên thân cây (Canvas 428 x 862)

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

    /// Tọa độ pixel chính xác và điểm neo cuống lá tương ứng trên ảnh gốc Asset-1 (428 x 862)
    private static let leavesMetadata: [LeafData] = [
        // MARK: Lớp lá bóng đổ phía sau (Back Shadow Leaves - Assets 2...10)
        LeafData(assetId: 2,  imgX: 208, imgY: 370, width: 163, height: 333, anchorX: 0.05, anchorY: 0.05, isLeft: false, zPos: 11, bendAngle: 0.045, duration: 2.8),
        LeafData(assetId: 3,  imgX: 0,   imgY: 212, width: 182, height: 487, anchorX: 0.95, anchorY: 0.05, isLeft: true,  zPos: 12, bendAngle: 0.050, duration: 3.2),
        LeafData(assetId: 4,  imgX: 194, imgY: 208, width: 79,  height: 468, anchorX: 0.08, anchorY: 0.05, isLeft: false, zPos: 13, bendAngle: 0.040, duration: 2.6),
        LeafData(assetId: 5,  imgX: 46,  imgY: 120, width: 180, height: 568, anchorX: 0.85, anchorY: 0.05, isLeft: true,  zPos: 14, bendAngle: 0.055, duration: 3.4),
        LeafData(assetId: 6,  imgX: 108, imgY: 212, width: 170, height: 389, anchorX: 0.95, anchorY: 0.05, isLeft: true,  zPos: 15, bendAngle: 0.045, duration: 2.9),
        LeafData(assetId: 7,  imgX: 206, imgY: 364, width: 163, height: 333, anchorX: 0.05, anchorY: 0.05, isLeft: false, zPos: 16, bendAngle: 0.045, duration: 2.7),
        LeafData(assetId: 8,  imgX: 46,  imgY: 112, width: 175, height: 487, anchorX: 0.95, anchorY: 0.05, isLeft: true,  zPos: 17, bendAngle: 0.050, duration: 3.1),
        LeafData(assetId: 9,  imgX: 192, imgY: 206, width: 79,  height: 468, anchorX: 0.08, anchorY: 0.05, isLeft: false, zPos: 18, bendAngle: 0.040, duration: 2.5),
        LeafData(assetId: 10, imgX: 46,  imgY: 116, width: 160, height: 568, anchorX: 0.90, anchorY: 0.05, isLeft: true,  zPos: 19, bendAngle: 0.055, duration: 3.3),

        // MARK: Lớp lá tiền cảnh đón sáng (Front Highlight Leaves - Assets 11...19)
        LeafData(assetId: 11, imgX: 102, imgY: 194, width: 170, height: 389, anchorX: 0.95, anchorY: 0.05, isLeft: true,  zPos: 31, bendAngle: 0.048, duration: 2.7),
        LeafData(assetId: 12, imgX: 78,  imgY: 146, width: 114, height: 514, anchorX: 0.92, anchorY: 0.05, isLeft: true,  zPos: 32, bendAngle: 0.052, duration: 3.0),
        LeafData(assetId: 13, imgX: 154, imgY: 0,   width: 61,  height: 749, anchorX: 0.90, anchorY: 0.03, isLeft: true,  zPos: 33, bendAngle: 0.038, duration: 3.5),
        LeafData(assetId: 14, imgX: 202, imgY: 142, width: 130, height: 545, anchorX: 0.08, anchorY: 0.05, isLeft: false, zPos: 34, bendAngle: 0.052, duration: 2.8),
        LeafData(assetId: 15, imgX: 196, imgY: 352, width: 223, height: 358, anchorX: 0.05, anchorY: 0.05, isLeft: false, zPos: 35, bendAngle: 0.046, duration: 2.6),
        LeafData(assetId: 16, imgX: 90,  imgY: 144, width: 99,  height: 514, anchorX: 0.92, anchorY: 0.05, isLeft: true,  zPos: 36, bendAngle: 0.050, duration: 3.1),
        LeafData(assetId: 17, imgX: 174, imgY: 0,   width: 40,  height: 749, anchorX: 0.85, anchorY: 0.03, isLeft: true,  zPos: 37, bendAngle: 0.035, duration: 3.6),
        LeafData(assetId: 18, imgX: 208, imgY: 132, width: 125, height: 545, anchorX: 0.05, anchorY: 0.05, isLeft: false, zPos: 38, bendAngle: 0.048, duration: 2.9),
        LeafData(assetId: 19, imgX: 204, imgY: 340, width: 223, height: 358, anchorX: 0.05, anchorY: 0.05, isLeft: false, zPos: 39, bendAngle: 0.045, duration: 2.5)
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant1GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Gốc rễ của các lá và thân cây
    private let plantRootNode = SKNode()
    /// Danh sách các sprite lá đang hiển thị để quản lý hiệu ứng
    private var leafNodes: [SKSpriteNode] = []
    /// Sprite hiển thị hạt giống (State 100)
    private var seedNode: SKSpriteNode?
    /// Sprite hiển thị cây con (State 200)
    private var sproutNode: SKSpriteNode?
    /// Vị trí toạ độ ban đầu của hạt giống (chống trôi khi tap liên tục)
    private var initialSeedPosition: CGPoint = .zero
    /// Vị trí toạ độ ban đầu của cây con (chống trôi khi tap liên tục)
    private var initialSproutPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở để áp dụng squash & stretch khi tương tác
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant1GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = false) {
        self.init(growthState: Plant1GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }

    // MARK: - Configuration

    public func configure(growthState: Plant1GrowthState, containerSize: CGSize, isHanging: Bool = false) {
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = false) {
        configure(growthState: Plant1GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }

    // MARK: - Build Scene theo trạng thái

    public func build() {
        plantRootNode.removeAllChildren()
        plantRootNode.removeAllActions()
        leafNodes.removeAll()
        seedNode = nil
        sproutNode = nil

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

    // MARK: - SKS Scene Loader (Hybrid Visual Architecture)

    /// Tải scene mẫu thiết kế trực quan từ Xcode (.sks)
    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Plant1Scene") {
            return scene
        }
        return nil
    }

    // MARK: - State 100: Gieo hạt (Seed Stage)

    private func buildSeedState() {
        plantRootNode.setScale(1.0)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height * 0.70 : 0)
        self.baseScale = 1.0

        // Tải texture hạt giống (Asset-100)
        guard let seedTexture = loadTexture(assetId: 100) else { return }

        // Kích thước hạt giống tí hon nằm gọn trong lòng đất (~18% chiều rộng container)
        let targetW = containerSize.width * 0.18
        let aspect: CGFloat = 257.0 / 259.0
        let targetH = targetW * aspect

        let node = SKSpriteNode(texture: seedTexture)
        node.size = CGSize(width: targetW, height: targetH)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = CGPoint(x: 0, y: 0)
        node.zPosition = 10

        plantRootNode.addChild(node)
        self.seedNode = node
        self.initialSeedPosition = node.position

        // 1. Hiệu ứng thở hạt mầm sinh động (Gentle organic breathing pulse)
        let breatheIn = SKAction.scaleX(to: 1.10, y: 0.90, duration: 1.0)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scaleX(to: 0.92, y: 1.08, duration: 1.0)
        breatheOut.timingMode = .easeInEaseOut
        let breatheSeq = SKAction.sequence([breatheIn, breatheOut])
        node.run(SKAction.repeatForever(breatheSeq), withKey: "seedBreath")

        // 2. Hiệu ứng hạt cựa quậy nhẹ nhàng trong đất (Gentle seed wiggle)
        let tiltL = SKAction.rotate(toAngle: -0.08, duration: 1.2)
        tiltL.timingMode = .easeInEaseOut
        let tiltR = SKAction.rotate(toAngle: 0.08, duration: 1.2)
        tiltR.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([tiltL, tiltR])), withKey: "seedWiggle")

        // 3. Vòng hào quang sinh khí mầm xanh phát sáng phía sau hạt
        startSeedGlowEffect(on: node, radius: targetW * 0.55)
    }

    private func startSeedGlowEffect(on node: SKNode, radius: CGFloat = 14) {
        let glowNode = SKShapeNode(circleOfRadius: radius)
        glowNode.fillColor = UIColor(red: 0.35, green: 0.92, blue: 0.60, alpha: 0.28)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: radius * 0.6)
        glowNode.zPosition = -1
        glowNode.name = "seedGlowNode"
        node.addChild(glowNode)

        let glowUp = SKAction.group([
            SKAction.fadeAlpha(to: 0.55, duration: 1.4),
            SKAction.scale(to: 1.25, duration: 1.4)
        ])
        glowUp.timingMode = .easeInEaseOut

        let glowDown = SKAction.group([
            SKAction.fadeAlpha(to: 0.18, duration: 1.4),
            SKAction.scale(to: 0.88, duration: 1.4)
        ])
        glowDown.timingMode = .easeInEaseOut

        glowNode.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])), withKey: "seedGlowPulse")
    }

    // MARK: - State 200: Cây con (Sprout Stage)

    private func buildSproutState() {
        plantRootNode.setScale(1.0)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height * 0.70 : 0)
        self.baseScale = 1.0

        guard let sproutTexture = loadTexture(assetId: 200) else { return }

        // Kích thước mầm cây con nhỏ xinh mới nhú (~22% chiều cao container)
        let targetH = containerSize.height * 0.22
        let aspect: CGFloat = 235.0 / 253.0
        let targetW = min(targetH * aspect, containerSize.width * 0.28)

        let node = SKSpriteNode(texture: sproutTexture)
        node.size = CGSize(width: targetW, height: targetH)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = CGPoint(x: 0, y: 0)
        node.zPosition = 10

        plantRootNode.addChild(node)
        self.sproutNode = node
        self.initialSproutPosition = node.position

        // 1. Hiệu ứng mầm non đung đưa đón nắng rõ rệt (Lively wind swaying)
        let swayLeft = SKAction.rotate(toAngle: -0.15, duration: 1.6)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.15, duration: 1.6)
        swayRight.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])), withKey: "sproutSway")

        // 2. Hiệu ứng thân mầm vươn nhún nhảy (Vertical spring bobbing)
        let bobUp = SKAction.scaleY(to: 1.08, duration: 1.3)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.scaleY(to: 0.92, duration: 1.3)
        bobDown.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "sproutBob")

        // 3. Hào quang mầm non sinh trưởng
        startSproutGlowEffect(on: node, radius: targetW * 0.50)
    }

    private func startSproutGlowEffect(on node: SKNode, radius: CGFloat = 16) {
        let glowNode = SKShapeNode(circleOfRadius: radius)
        glowNode.fillColor = UIColor(red: 0.40, green: 0.92, blue: 0.65, alpha: 0.22)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: radius * 0.8)
        glowNode.zPosition = -1
        glowNode.name = "sproutGlowNode"
        node.addChild(glowNode)

        let glowUp = SKAction.group([
            SKAction.fadeAlpha(to: 0.48, duration: 1.6),
            SKAction.scale(to: 1.20, duration: 1.6)
        ])
        glowUp.timingMode = .easeInEaseOut

        let glowDown = SKAction.group([
            SKAction.fadeAlpha(to: 0.12, duration: 1.6),
            SKAction.scale(to: 0.90, duration: 1.6)
        ])
        glowDown.timingMode = .easeInEaseOut

        glowNode.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])), withKey: "sproutGlowPulse")
    }

    // MARK: - State Level 3+: Cây trưởng thành (Kiến trúc lai .sks + Swift Animation)

    private func buildMatureState(level: Int) {
        // Tỉ lệ phát triển theo level: Level 3 = 88%, Level 10+ = 100%
        let growthRatio: CGFloat = 0.88 + (CGFloat(max(3, min(10, level)) - 3) / 7.0) * 0.12

        let baseCanvasWidth: CGFloat = 428.0
        let baseCanvasHeight: CGFloat = 862.0

        let fitW = (containerSize.width * 0.92) / baseCanvasWidth
        let fitH = (containerSize.height * 0.92) / baseCanvasHeight
        let scale = min(fitW, fitH) * growthRatio
        self.baseScale = scale

        plantRootNode.setScale(scale)
        plantRootNode.position = CGPoint(x: 0, y: isHanging ? containerSize.height : 0)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Đọc trực tiếp các lá từ file trực quan Plant1Scene.sks
        // Khi người thiết kế kéo thả chuột đổi vị trí trong Xcode, code tự động lấy vị trí mới đó!
        if let scene = loadSceneTemplate(),
           let matureGroup = scene.childNode(withName: "matureNode"),
           !matureGroup.children.isEmpty {

            var extractedLeaves: [SKSpriteNode] = []
            for child in matureGroup.children {
                if let sprite = child as? SKSpriteNode {
                    extractedLeaves.append(sprite)
                }
            }

            if !extractedLeaves.isEmpty {
                for leaf in extractedLeaves {
                    leaf.removeFromParent()
                    leaf.isHidden = false
                    plantRootNode.addChild(leaf)
                    leafNodes.append(leaf)

                    // Tìm metadata bổ trợ góc uốn/thời gian nếu có, hoặc suy ra từ vị trí trực quan
                    let assetNum = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                    let meta = Self.leavesMetadata.first(where: { $0.assetId == assetNum })

                    let isLeft = meta?.isLeft ?? (leaf.position.x < 0)
                    let bendAngle = meta?.bendAngle ?? 0.046
                    let duration = meta?.duration ?? 2.8

                    startLeafBendingAnimation(leaf: leaf, isLeft: isLeft, bendAngle: bendAngle, duration: duration)
                }

                addTrunkSwayAnimation()
                return
            }
        }

        // 2. FALLBACK CODE PROCEDURAL: Nếu file .sks chưa có lá thì sinh qua metadata chuẩn
        for data in Self.leavesMetadata {
            guard let leafTexture = loadTexture(assetId: data.assetId) else { continue }

            let leaf = SKSpriteNode(texture: leafTexture)
            leaf.name = "leaf_\(data.assetId)"
            leaf.size = CGSize(width: data.width, height: data.height)
            leaf.anchorPoint = CGPoint(x: data.anchorX, y: data.anchorY)

            let skX = data.imgX + data.anchorX * data.width
            let skY = baseCanvasHeight - data.imgY - (1.0 - data.anchorY) * data.height

            leaf.position = CGPoint(x: skX - (baseCanvasWidth / 2.0), y: skY)
            leaf.zPosition = data.zPos

            plantRootNode.addChild(leaf)
            leafNodes.append(leaf)

            startLeafBendingAnimation(leaf: leaf, isLeft: data.isLeft, bendAngle: data.bendAngle, duration: data.duration)
        }

        addTrunkSwayAnimation()
    }

    private func addTrunkSwayAnimation() {
        let trunkSwayLeft = SKAction.rotate(toAngle: -0.016, duration: 3.6)
        trunkSwayLeft.timingMode = .easeInEaseOut
        let trunkSwayRight = SKAction.rotate(toAngle: 0.016, duration: 3.6)
        trunkSwayRight.timingMode = .easeInEaseOut
        plantRootNode.run(SKAction.repeatForever(SKAction.sequence([trunkSwayLeft, trunkSwayRight])), withKey: "trunkSway")
    }

    // MARK: - Animation: Uốn cong lá mềm mại theo gió (Organic Leaf Bend)

    private func startLeafBendingAnimation(leaf: SKSpriteNode, isLeft: Bool, bendAngle: CGFloat, duration: TimeInterval) {
        leaf.removeAction(forKey: "leafBend")

        let angleDelta = isLeft ? -bendAngle : bendAngle

        let bendForward = SKAction.rotate(byAngle: angleDelta, duration: duration * 0.5)
        bendForward.timingMode = .easeInEaseOut

        let bendBackward = SKAction.rotate(byAngle: -angleDelta, duration: duration * 0.5)
        bendBackward.timingMode = .easeInEaseOut

        let flexIn = SKAction.scaleX(to: 0.97, y: 1.02, duration: duration * 0.5)
        flexIn.timingMode = .easeInEaseOut

        let flexOut = SKAction.scaleX(to: 1.02, y: 0.98, duration: duration * 0.5)
        flexOut.timingMode = .easeInEaseOut

        let forwardGroup = SKAction.group([bendForward, flexIn])
        let backwardGroup = SKAction.group([bendBackward, flexOut])

        let bendSequence = SKAction.sequence([forwardGroup, backwardGroup])

        let initialWait = SKAction.wait(forDuration: Double.random(in: 0.0...1.6))
        leaf.run(SKAction.sequence([initialWait, SKAction.repeatForever(bendSequence)]), withKey: "leafBend")
    }

    // MARK: - Phản hồi tương tác người dùng (Tap Bounce)

    public func playTapAnimation() {
        switch growthState {
        case .seed:
            playSeedTapAnimation()
        case .sprout:
            playSproutTapAnimation()
        case .mature:
            playMatureTapAnimation()
        }

        // Nhả bong bóng oxy tương ứng theo giai đoạn
        spawnOxygenBubbles()
    }

    /// Hiệu ứng khi tap vào hạt giống: Nảy tưng lên phấn khích + bừng sáng hào quang
    private func playSeedTapAnimation() {
        guard let node = seedNode else { return }
        node.removeAction(forKey: "seedTapHop")

        // Đưa ngay về toạ độ gốc để triệt tiêu việc cộng dồn toạ độ Y khi người dùng click dồn dập
        node.position = initialSeedPosition

        // 1. Nhún nén rồi nảy vọt lên trên không (dùng moveTo thay vì moveBy để không bao giờ bị lệch vị trí)
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

        // 2. Hào quang bừng sáng
        if let glow = node.childNode(withName: "seedGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.08),
                SKAction.fadeAlpha(to: 0.28, duration: 0.25)
            ])
            glow.run(flash)
        }
    }

    /// Hiệu ứng khi tap vào cây con: Nảy đàn hồi lò xo + 2 lá mầm rung rinh
    private func playSproutTapAnimation() {
        guard let node = sproutNode else { return }
        node.removeAction(forKey: "sproutTapBounce")

        // Reset vị trí & góc xoay cơ sở để tránh trôi lệch khi tap liên tục
        node.position = initialSproutPosition
        node.zRotation = 0

        // 1. Nén nhún đàn hồi lò xo
        let squash = SKAction.scaleX(to: 1.26, y: 0.74, duration: 0.08)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: 0.84, y: 1.22, duration: 0.12)
        stretch.timingMode = .easeOut
        let bounceBack = SKAction.scaleX(to: 1.08, y: 0.94, duration: 0.10)
        let settle = SKAction.scale(to: 1.0, duration: 0.12)
        settle.timingMode = .easeInEaseOut

        // 2. Rung lắc 2 lá mầm (dùng toAngle góc tuyệt đối để không trôi góc quay)
        let shakeL = SKAction.rotate(toAngle: -0.15, duration: 0.07)
        let shakeR = SKAction.rotate(toAngle: 0.15, duration: 0.08)
        let shakeBack = SKAction.rotate(toAngle: 0, duration: 0.07)
        let shakeSeq = SKAction.sequence([shakeL, shakeR, shakeBack])

        let combined = SKAction.group([
            SKAction.sequence([squash, stretch, bounceBack, settle]),
            shakeSeq
        ])

        node.run(combined, withKey: "sproutTapBounce")

        // 3. Hào quang sinh trưởng bừng sáng
        if let glow = node.childNode(withName: "sproutGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.75, duration: 0.08),
                SKAction.fadeAlpha(to: 0.22, duration: 0.25)
            ])
            glow.run(flash)
        }
    }

    /// Hiệu ứng khi tap vào cây trưởng thành: Toàn cây nhún nảy + 18 lá xao động
    private func playMatureTapAnimation() {
        let squash = SKAction.scaleX(to: baseScale * 1.15, y: baseScale * 0.85, duration: 0.12)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: baseScale * 0.92, y: baseScale * 1.14, duration: 0.16)
        stretch.timingMode = .easeOut
        let settle = SKAction.scale(to: baseScale, duration: 0.18)
        settle.timingMode = .easeInEaseOut

        plantRootNode.run(SKAction.sequence([squash, stretch, settle]))

        for leaf in leafNodes {
            let jiggle = SKAction.rotate(byAngle: CGFloat.random(in: -0.07...0.07), duration: 0.08)
            let returnJiggle = jiggle.reversed()
            leaf.run(SKAction.sequence([jiggle, returnJiggle]))
        }
    }

    private func spawnOxygenBubbles() {
        // Số lượng bọt khí tăng dần theo giai đoạn sinh trưởng:
        // - Hạt giống (Lv.1): 1 - 2 bọt nhỏ thoát ra từ gốc hạt
        // - Cây con (Lv.2): 3 - 4 bọt vừa thoát ra từ 2 mầm lá non
        // - Cây trưởng thành (Lv.3+): 7 - 10 bọt dồi dào phủ khắp toàn bộ tán cây
        let bubbleCount: Int
        switch growthState {
        case .seed:
            bubbleCount = Int.random(in: 1...2)
        case .sprout:
            bubbleCount = Int.random(in: 3...4)
        case .mature:
            bubbleCount = Int.random(in: 7...10)
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
                // Nếu đã có các node lá, chọn ngẫu nhiên các phiến lá trên cây để bọt khí thoát ra từ khắp nơi
                if !leafNodes.isEmpty && Bool.random() {
                    let randomLeaf = leafNodes.randomElement()!
                    let leafPos = randomLeaf.position
                    spawnX = leafPos.x + CGFloat.random(in: -18...18)
                    spawnY = max(containerSize.height * 0.18, min(containerSize.height * 0.92, leafPos.y + CGFloat.random(in: -10...20)))
                } else {
                    // Trải đều toàn bộ tán cây từ mép trái sang mép phải (-46%...46%) và từ gốc lên ngọn (18%...90%)
                    spawnX = CGFloat.random(in: -containerSize.width * 0.46...containerSize.width * 0.46)
                    spawnY = CGFloat.random(in: containerSize.height * 0.18...containerSize.height * 0.90)
                }
            }

            let bubble = SKShapeNode(circleOfRadius: radius)
            bubble.fillColor = UIColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 0.85)
            bubble.strokeColor = UIColor.white.withAlphaComponent(0.7)
            bubble.lineWidth = 1.0

            // Điểm sáng phản chiếu bên trong bọt khí
            let highlight = SKShapeNode(circleOfRadius: radius * 0.3)
            highlight.fillColor = UIColor.white.withAlphaComponent(0.8)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -radius * 0.3, y: radius * 0.3)
            bubble.addChild(highlight)

            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 100
            bubble.alpha = 0.0
            addChild(bubble)

            // Hiệu ứng bay lên tự nhiên, tản đều và biến mất
            let floatDuration = Double.random(in: 0.8...1.5)
            let driftX = CGFloat.random(in: -20...20)

            let delay = SKAction.wait(forDuration: Double(i) * 0.04)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.12)
            let floatUp = SKAction.moveBy(x: driftX, y: floatDistance, duration: floatDuration)
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: floatDuration * 0.6)
            let scaleUp = SKAction.scale(by: 1.30, duration: floatDuration)

            let motionGroup = SKAction.group([
                floatUp,
                SKAction.sequence([SKAction.wait(forDuration: floatDuration * 0.4), fadeOut]),
                scaleUp
            ])

            bubble.run(SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Texture Loader

    private func loadTexture(assetId: Int) -> SKTexture? {
        let names = [
            "plant1_Asset-\(assetId)@4.167x",
            "plant1_Asset-\(assetId)",
            "Asset-\(assetId)@4.167x",
            "Asset-\(assetId)",
            "plant1/plant1_Asset-\(assetId)@4.167x",
            "plant1/Asset-\(assetId)"
        ]

        for name in names {
            if let image = UIImage(named: name) {
                return SKTexture(image: image)
            }
        }

        // Fallback: Tìm trực tiếp trong bundle hoặc file system
        if let bundleUrl = Bundle.main.url(forResource: "plant1_Asset-\(assetId)@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "Asset-\(assetId)@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "Asset-\(assetId)", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let image = UIImage(data: data) {
                return SKTexture(image: image)
            }
        }

        return nil
    }
}

//
//  Pot4Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 4: "Chậu trái tim trắng" (pot4)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot4Scene.sks` nếu có
/// - Kích thước & toạ độ chuẩn theo ảnh `Pot4@4.167x.png` (302 x 263)
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ đáy ~45%)
/// - Hiệu ứng đặc trưng: "Trái tim nhịp đập" (Heartbeat pulse & floating hearts)
///   - Idle: Biểu tượng trái tim co bóp theo nhịp đập tự nhiên (lub-dub) kèm hào quang hồng ngọc
///   - Tap: Nhún nảy lò xo đàn hồi + bung tỏa chùm trái tim mini bồng bềnh bay lên
public final class Pot4Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Gốc rễ chậu và hiệu ứng
    private let potRootNode = SKNode()
    /// Sprite hiển thị chậu cây
    private var potNode: SKSpriteNode?
    /// Bóng đổ dưới đáy chậu
    private var shadowNode: SKNode?
    /// Node hiệu ứng hào quang trái tim nhịp đập
    private var heartGlowNode: SKShapeNode?

    /// Toạ độ ban đầu của chậu (chống trôi toạ độ khi tap liên tục)
    private var initialPotPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 85), isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(potRootNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(potRootNode)
    }

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    // MARK: - Build Scene

    public func build() {
        potRootNode.removeAllChildren()
        potRootNode.removeAllActions()
        potNode = nil
        shadowNode = nil
        heartGlowNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tỉ lệ ảnh gốc: 302 x 263 (aspect ~ 0.8709)
        let aspect: CGFloat = 263.0 / 302.0
        let targetH = containerSize.height * 0.98
        let targetW = min(targetH / aspect, containerSize.width * 0.96)

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        // pot4 có đáy chiếm ~45% bề rộng
        if !isHanging {
            let baseContactW = targetW * 0.45
            let shadowW = max(26.0, baseContactW * 1.14)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot4Scene.sks nếu có
        if let scene = loadSceneTemplate(),
           let templatePot = scene.childNode(withName: "potNode") as? SKSpriteNode,
           templatePot.texture != nil {
            templatePot.removeFromParent()
            templatePot.isHidden = false
            templatePot.isPaused = false
            templatePot.speed = 1.0
            potRootNode.addChild(templatePot)
            self.potNode = templatePot
            self.initialPotPosition = templatePot.position

            startHeartbeatEffect(potBounds: templatePot.size)
            return
        }

        // 3. Fallback nạp texture ảnh pot4 (Pot4@4.167x.png)
        guard let texture = loadPot4Texture() else { return }

        let node = SKSpriteNode(texture: texture)
        node.name = "potNode"
        node.size = CGSize(width: targetW, height: targetH)
        node.zPosition = 10
        node.isPaused = false
        node.speed = 1.0

        if isHanging {
            node.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            node.position = CGPoint(x: 0, y: 0)
        } else {
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: 0, y: 0)
        }

        potRootNode.addChild(node)
        self.potNode = node
        self.initialPotPosition = node.position

        // 4. Kích hoạt hiệu ứng đặc trưng "Trái tim nhịp đập"
        startHeartbeatEffect(potBounds: CGSize(width: targetW, height: targetH))
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot4Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot4Texture() -> SKTexture? {
        let candidates = [
            "Pot4@4.167x",
            "pot4@4.167x",
            "Pot4",
            "pot4",
            "pot4-Asset-1@4.167x",
            "pot4_Asset-1@4.167x",
            "pot4-Asset-1",
            "pot4_Asset-1",
            "i_pot4",
            "pot_pot4"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        if let bundleUrl = Bundle.main.url(forResource: "Pot4@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "pot4", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot4", isHanging: isHanging).texture
    }

    // MARK: - Hiệu ứng Idle: "Trái tim nhịp đập" (Heartbeat Pulse)

    private func startHeartbeatEffect(potBounds: CGSize) {
        guard let pot = potNode else { return }
        removeAction(forKey: "potHeartbeat")

        // Tạo điểm sáng / hào quang trái tim khảm giữa thân chậu
        let heartY: CGFloat
        if isHanging {
            heartY = -potBounds.height * 0.48
        } else {
            heartY = potBounds.height * 0.48
        }

        let heart = createHeartNode(size: CGSize(width: 14, height: 13), color: UIColor(red: 1.0, green: 0.35, blue: 0.50, alpha: 0.75))
        heart.position = CGPoint(x: 0, y: heartY)
        heart.zPosition = 15
        heart.name = "heartEmblem"
        pot.addChild(heart)
        self.heartGlowNode = heart

        // Nhịp đập tim đôi chân thực (Thump-thump ... Pause)
        let beat1Up = SKAction.scale(to: 1.25, duration: 0.11)
        beat1Up.timingMode = .easeOut
        let beat1Down = SKAction.scale(to: 0.96, duration: 0.09)
        beat1Down.timingMode = .easeIn

        let beat2Up = SKAction.scale(to: 1.38, duration: 0.13)
        beat2Up.timingMode = .easeOut
        let beat2Down = SKAction.scale(to: 1.0, duration: 0.16)
        beat2Down.timingMode = .easeInEaseOut

        let rest = SKAction.wait(forDuration: 1.35)
        let heartbeatLoop = SKAction.sequence([beat1Up, beat1Down, beat2Up, beat2Down, rest])
        heart.run(SKAction.repeatForever(heartbeatLoop), withKey: "heartPulse")

        // Thỉnh thoảng tỏa một bong bóng trái tim mini bay lên
        let waitMini = SKAction.wait(forDuration: Double.random(in: 2.2...3.5))
        let spawnMini = SKAction.run { [weak self] in
            guard let self = self, let pot = self.potNode else { return }
            self.emitFloatingMiniHeart(on: pot, originY: heartY)
        }
        let miniLoop = SKAction.sequence([waitMini, spawnMini])
        run(SKAction.repeatForever(miniLoop), withKey: "potHeartbeat")
    }

    private func emitFloatingMiniHeart(on pot: SKNode, originY: CGFloat) {
        let size = CGFloat.random(in: 7.0...10.0)
        let heart = createHeartNode(size: CGSize(width: size, height: size * 0.92), color: UIColor(red: 1.0, green: 0.45, blue: 0.65, alpha: 0.85))

        let rx = CGFloat.random(in: -10...10)
        heart.position = CGPoint(x: rx, y: originY)
        heart.zPosition = 25
        heart.alpha = 0.0
        heart.setScale(0.3)
        pot.addChild(heart)

        let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.22)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.22)
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: 28...45), duration: 0.85)
        floatUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.35)

        let intro = SKAction.group([fadeIn, scaleUp])
        let anim = SKAction.sequence([
            intro,
            floatUp,
            fadeOut,
            SKAction.removeFromParent()
        ])
        heart.run(anim)
    }

    // MARK: - Phản hồi tương tác Tap (Tap Animation)

    public func playTapAnimation() {
        guard let node = potNode else { return }
        node.removeAction(forKey: "potTapBounce")
        node.position = initialPotPosition

        // 1. Squash & Stretch nén nảy đàn hồi
        let compress = SKAction.scaleX(to: 1.10, y: 0.90, duration: 0.09)
        compress.timingMode = .easeIn
        let rebound = SKAction.scaleX(to: 0.95, y: 1.07, duration: 0.13)
        rebound.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        settle.timingMode = .easeInEaseOut
        node.run(SKAction.sequence([compress, rebound, settle]), withKey: "potTapBounce")

        if isHanging {
            let swing = SKAction.sequence([
                SKAction.rotate(toAngle: -0.05, duration: 0.08),
                SKAction.rotate(toAngle: 0.05, duration: 0.10),
                SKAction.rotate(toAngle: 0, duration: 0.10)
            ])
            node.run(swing)
        }

        // 2. Bóng co giãn theo nhịp nảy
        if let shadow = shadowNode {
            shadow.removeAction(forKey: "shadowBounce")
            let shrink = SKAction.scale(to: 0.86, duration: 0.09)
            let restore = SKAction.scale(to: 1.0, duration: 0.28)
            restore.timingMode = .easeOut
            shadow.run(SKAction.sequence([shrink, restore]), withKey: "shadowBounce")
        }

        // 3. Bung toả chùm trái tim lấp lánh (Heart Burst)
        spawnHeartBurst()
    }

    private func spawnHeartBurst() {
        guard let pot = potNode else { return }
        let potFrame = pot.frame
        let burstCount = Int.random(in: 7...10)

        for i in 0..<burstCount {
            let size = CGFloat.random(in: 8.0...14.0)
            let heartColor = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.35, blue: 0.55, alpha: 0.95)
                : UIColor(red: 1.0, green: 0.70, blue: 0.82, alpha: 0.95)

            let heart = createHeartNode(size: CGSize(width: size, height: size * 0.92), color: heartColor)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.2)...(potFrame.maxX - potFrame.width * 0.2))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.3)...(potFrame.maxY - potFrame.height * 0.2))
            heart.position = CGPoint(x: startX, y: startY)
            heart.zPosition = 50
            heart.alpha = 0.0
            heart.setScale(0.3)
            potRootNode.addChild(heart)

            let flyAngle = CGFloat.random(in: .pi * 0.2...(.pi * 0.8)) // Bay vút lên trên
            let distance = CGFloat.random(in: 30...65)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.60)
            floatOut.timingMode = .easeOut
            let wobble = SKAction.sequence([
                SKAction.rotate(byAngle: 0.25, duration: 0.15),
                SKAction.rotate(byAngle: -0.50, duration: 0.30),
                SKAction.rotate(byAngle: 0.25, duration: 0.15)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.28),
                SKAction.fadeOut(withDuration: 0.32)
            ])

            let motionGroup = SKAction.group([floatOut, wobble, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])
            heart.run(fullSeq)
        }
    }

    // MARK: - Helper vẽ hình trái tim Bezier (Heart Shape)

    private func createHeartNode(size: CGSize, color: UIColor) -> SKShapeNode {
        let path = UIBezierPath()
        let w = size.width
        let h = size.height

        path.move(to: CGPoint(x: 0, y: -h * 0.45))
        path.addCurve(
            to: CGPoint(x: -w * 0.5, y: h * 0.1),
            controlPoint1: CGPoint(x: -w * 0.3, y: -h * 0.2),
            controlPoint2: CGPoint(x: -w * 0.5, y: -h * 0.05)
        )
        path.addArc(
            withCenter: CGPoint(x: -w * 0.25, y: h * 0.2),
            radius: w * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addArc(
            withCenter: CGPoint(x: w * 0.25, y: h * 0.2),
            radius: w * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -h * 0.45),
            controlPoint1: CGPoint(x: w * 0.5, y: -h * 0.05),
            controlPoint2: CGPoint(x: w * 0.3, y: -h * 0.2)
        )
        path.close()

        let heartNode = SKShapeNode(path: path.cgPath)
        heartNode.fillColor = color
        heartNode.strokeColor = UIColor.white.withAlphaComponent(0.7)
        heartNode.lineWidth = 0.6
        return heartNode
    }
}

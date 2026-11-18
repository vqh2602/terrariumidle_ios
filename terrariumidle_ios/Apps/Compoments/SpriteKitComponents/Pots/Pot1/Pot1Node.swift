//
//  Pot1Node.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 1: "Chậu hồng chấm đỏ" (pot1)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot1Scene.sks` nếu có
/// - Kích thước & toạ độ chuẩn theo ảnh `pot1-Asset-1@4.167x.png` (276 x 195)
/// - Đổ bóng mềm mại phía dưới đáy chậu
/// - Hiệu ứng đặc trưng: "Đá lấp lánh" (Sparkle / Glitter effect)
///   - Idle: Các hạt sao lấp lánh nhẹ nhàng điểm xuyết trên viền chậu
///   - Tap: Nhún nảy lò xo đàn hồi (chống trôi toạ độ) + bung tỏa chùm tia sáng lấp lánh
public final class Pot1Node: SKNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

    /// Gốc rễ chậu và hiệu ứng
    private let potRootNode = SKNode()
    /// Sprite hiển thị chậu cây
    private var potNode: SKSpriteNode?
    /// Bóng đổ dưới đáy chậu
    private var shadowNode: SKShapeNode?

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

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tỉ lệ ảnh gốc: 276 x 195 (aspect ~ 0.7065)
        let aspect: CGFloat = 195.0 / 276.0
        let fitW = containerSize.width * 0.90
        let targetH = min(fitW * aspect, containerSize.height * 0.88)
        let targetW = targetH / aspect

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        if !isHanging {
            let shadowW = targetW * 0.86
            let shadowH = targetH * 0.18
            let shadow = SKShapeNode(ellipseOf: CGSize(width: shadowW, height: shadowH))
            shadow.fillColor = UIColor.black.withAlphaComponent(0.20)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: 0)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot1Scene.sks nếu đã thiết kế trong Xcode
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

            startIdleSparkleEffect(potBounds: templatePot.size)
            return
        }

        // 3. Fallback nạp texture ảnh pot1 (pot1-Asset-1@4.167x.png)
        guard let texture = loadPot1Texture() else { return }

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

        // 4. Kích hoạt hiệu ứng đặc trưng "Đá lấp lánh" (Sparkle Twinkle)
        startIdleSparkleEffect(potBounds: CGSize(width: targetW, height: targetH))
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot1Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot1Texture() -> SKTexture? {
        let candidates = [
            "pot1-Asset-1@4.167x",
            "pot1",
            "pot1-Asset-1",
            "pot1_Asset-1@4.167x",
            "pot1_Asset-1",
            "i_pot1",
            "pot_pot1"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        // Fallback file hệ thống nếu chạy preview độc lập
        if let bundleUrl = Bundle.main.url(forResource: "pot1-Asset-1@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "pot1", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return SKTexture(image: img)
            }
        }

        // Fallback procedural
        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot1", isHanging: isHanging)
    }

    // MARK: - Hiệu ứng Idle: "Đá lấp lánh" (Sparkle Twinkle)

    private func startIdleSparkleEffect(potBounds: CGSize) {
        removeAction(forKey: "potIdleSparkle")

        let waitTime = SKAction.wait(forDuration: Double.random(in: 1.2...2.2))
        let spawnSparkle = SKAction.run { [weak self] in
            guard let self = self, let pot = self.potNode else { return }
            self.emitSingleSparkle(on: pot, potBounds: potBounds)
        }

        let loop = SKAction.sequence([waitTime, spawnSparkle])
        run(SKAction.repeatForever(loop), withKey: "potIdleSparkle")
    }

    private func emitSingleSparkle(on pot: SKNode, potBounds: CGSize) {
        let star = createStarSparkleNode(radius: CGFloat.random(in: 3.5...5.5), color: UIColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 0.95))

        // Vị trí xuất hiện ngẫu nhiên dọc thân hoặc viền trên chậu (xử lý chính xác cả chậu đứng và chậu treo)
        let halfW = potBounds.width * 0.38
        let rx = CGFloat.random(in: -halfW...halfW)
        let ry: CGFloat
        if isHanging {
            // Chậu treo có anchorPoint (0.5, 1.0) nên toạ độ Y nằm ở nửa dưới âm
            ry = -CGFloat.random(in: potBounds.height * 0.20...potBounds.height * 0.85)
        } else {
            // Chậu đứng có anchorPoint (0.5, 0.0) nên toạ độ Y nằm ở nửa trên dương
            ry = CGFloat.random(in: potBounds.height * 0.25...potBounds.height * 0.80)
        }

        star.position = CGPoint(x: rx, y: ry)
        star.zPosition = 25
        star.alpha = 0.0
        star.setScale(0.2)
        pot.addChild(star)

        let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.20)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.20)
        let rotate = SKAction.rotate(byAngle: .pi * 0.5, duration: 0.55)

        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.35)
        let scaleDown = SKAction.scale(to: 0.2, duration: 0.35)

        let intro = SKAction.group([fadeIn, scaleUp])
        let outro = SKAction.group([fadeOut, scaleDown])

        let anim = SKAction.sequence([
            intro,
            SKAction.wait(forDuration: 0.15),
            outro,
            SKAction.removeFromParent()
        ])

        star.run(SKAction.group([anim, rotate]))
    }

    // MARK: - Phản hồi tương tác Tap (Tap Animation)

    public func playTapAnimation() {
        guard let node = potNode else { return }
        node.removeAction(forKey: "potTapBounce")

        // Reset vị trí toạ độ gốc để không bao giờ bị trôi toạ độ khi tap liên tục
        node.position = initialPotPosition

        // 1. Squash & Stretch nén nảy đàn hồi
        let compress = SKAction.scaleX(to: 1.12, y: 0.88, duration: 0.09)
        compress.timingMode = .easeIn
        let rebound = SKAction.scaleX(to: 0.94, y: 1.08, duration: 0.13)
        rebound.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([compress, rebound, settle]), withKey: "potTapBounce")

        // Với chậu treo: Thêm hiệu ứng chao nghiêng nhẹ khi chạm vào
        if isHanging {
            let swing = SKAction.sequence([
                SKAction.rotate(toAngle: -0.06, duration: 0.08),
                SKAction.rotate(toAngle: 0.06, duration: 0.10),
                SKAction.rotate(toAngle: 0, duration: 0.10)
            ])
            node.run(swing)
        }

        // 2. Bóng co giãn theo nhịp nảy (chỉ chậu đứng có bóng)
        if let shadow = shadowNode {
            shadow.removeAction(forKey: "shadowBounce")
            let shrink = SKAction.scale(to: 0.85, duration: 0.09)
            let restore = SKAction.scale(to: 1.0, duration: 0.28)
            restore.timingMode = .easeOut
            shadow.run(SKAction.sequence([shrink, restore]), withKey: "shadowBounce")
        }

        // 3. Bung toả chùm hạt sáng lấp lánh (Sparkle Glitter Burst)
        spawnSparkleBurst()
    }

    /// Tung ra các hạt đá lấp lánh bay toả ra xung quanh chậu khi chạm vào
    private func spawnSparkleBurst() {
        guard let pot = potNode else { return }
        let potFrame = pot.frame
        let burstCount = Int.random(in: 7...10)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: 4.0...6.5)
            let starColor = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.95) // Vàng hoàng yến lấp lánh
                : UIColor(red: 1.0, green: 0.65, blue: 0.78, alpha: 0.95) // Hồng phấn lấp lánh

            let star = createStarSparkleNode(radius: radius, color: starColor)

            // Vị trí xuất phát từ lòng/thân chậu (dựa trên potFrame chuẩn xác dù là chậu đứng hay chậu treo)
            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.18)...(potFrame.maxY - potFrame.height * 0.15))
            star.position = CGPoint(x: startX, y: startY)
            star.zPosition = 50
            star.alpha = 0.0
            star.setScale(0.25)
            potRootNode.addChild(star)

            // Góc bay toả đều 360 độ xung quanh chậu
            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...60)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.025)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.55)
            floatOut.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.0...3.0), duration: 0.55)
            let scalePulse = SKAction.sequence([
                SKAction.scale(to: 1.35, duration: 0.18),
                SKAction.scale(to: 0.25, duration: 0.37)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.22),
                SKAction.fadeOut(withDuration: 0.33)
            ])

            let motionGroup = SKAction.group([floatOut, rotate, scalePulse, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            star.run(fullSeq)
        }
    }

    // MARK: - Helper tạo hình ngôi sao 4 cánh lấp lánh (4-Point Diamond Star)

    private func createStarSparkleNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let path = CGMutablePath()
        let r = radius
        let innerR = radius * 0.25

        // Ngôi sao 4 cánh nhọn tỏa sáng
        path.move(to: CGPoint(x: 0, y: r))
        path.addLine(to: CGPoint(x: innerR, y: innerR))
        path.addLine(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: innerR, y: -innerR))
        path.addLine(to: CGPoint(x: 0, y: -r))
        path.addLine(to: CGPoint(x: -innerR, y: -innerR))
        path.addLine(to: CGPoint(x: -r, y: 0))
        path.addLine(to: CGPoint(x: -innerR, y: innerR))
        path.closeSubpath()

        let starNode = SKShapeNode(path: path)
        starNode.fillColor = color
        starNode.strokeColor = UIColor.white.withAlphaComponent(0.8)
        starNode.lineWidth = 0.5

        // Điểm sáng trắng trung tâm
        let centerPoint = SKShapeNode(circleOfRadius: innerR * 0.8)
        centerPoint.fillColor = .white
        centerPoint.strokeColor = .clear
        starNode.addChild(centerPoint)

        return starNode
    }
}

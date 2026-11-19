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
    private var widthFill: CGFloat = 0.0

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

    /// Danh sách hiệu ứng khi tap vào chậu (có thể tùy biến, thay đổi hoặc gán thêm để tái sử dụng)
    public var tapEffects: [PotTapEffect] = [HeartBurstEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 85), isHanging: Bool = false, widthFill: CGFloat = 0.0) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        super.init()

        addChild(potRootNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(potRootNode)
    }

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = false, widthFill: CGFloat = 0.0) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
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
        let baseW = min(targetH / aspect, containerSize.width * 0.96)
        let maxW = containerSize.width * 0.96
        let targetW = baseW + (maxW - baseW) * widthFill

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
            if widthFill > 0 {
                let extraW = (containerSize.width * 0.96 - templatePot.size.width) * widthFill
                if extraW > 0 {
                    templatePot.size.width += extraW
                }
            }
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

        let heart = HeartBurstEffect.createHeartNode(size: CGSize(width: 14, height: 13), color: UIColor(red: 1.0, green: 0.35, blue: 0.50, alpha: 0.75))
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
        let heart = HeartBurstEffect.createHeartNode(size: CGSize(width: size, height: size * 0.92), color: UIColor(red: 1.0, green: 0.45, blue: 0.65, alpha: 0.85))

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

        // 1. Squash & Stretch nén nảy đàn hồi + bóng đổ + đu đưa chậu treo
        PotBounceAnimator.applyBounce(
            to: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging,
            config: .standard
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

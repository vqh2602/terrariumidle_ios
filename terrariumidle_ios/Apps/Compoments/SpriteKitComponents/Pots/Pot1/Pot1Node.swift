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
public final class Pot1Node: SKNode, PotInteractiveNode {

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

    /// Toạ độ ban đầu của chậu (chống trôi toạ độ khi tap liên tục)
    private var initialPotPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở
    private var baseScale: CGFloat = 1.0

    /// Danh sách hiệu ứng khi tap vào chậu (có thể tùy biến, thay đổi hoặc gán thêm để tái sử dụng)
    public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]

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

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tỉ lệ ảnh gốc: 276 x 195 (aspect ~ 0.7065)
        let aspect: CGFloat = 195.0 / 276.0
        // Fit theo chiều cao container để chậu chạm mép trên, không bao giờ có khoảng trắng hở
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        // pot1 có đáy chiếm ~52% bề rộng, bóng đổ radial gradient ôm sát đáy chậu mềm mại tự nhiên
        if !isHanging {
            let baseContactW = targetW * 0.52
            let shadowW = max(28.0, baseContactW * 1.12)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
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
            if widthFill > 0 {
                let extraW = (containerSize.width * 0.96 - templatePot.size.width) * widthFill
                if extraW > 0 {
                    templatePot.size.width += extraW
                }
            }
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
        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot1", isHanging: isHanging).texture
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
        let star = SparkleBurstEffect.createStarSparkleNode(radius: CGFloat.random(in: 3.5...5.5), color: UIColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 0.95))

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

        // 1. Squash & Stretch nén nảy đàn hồi + bóng đổ + đu đưa chậu treo
        PotBounceAnimator.applyBounce(
            to: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging,
            config: .init(
                compressX: 1.12,
                compressY: 0.88,
                compressDuration: 0.09,
                reboundX: 0.94,
                reboundY: 1.08,
                reboundDuration: 0.13,
                settleDuration: 0.15,
                shadowShrink: 0.85
            )
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

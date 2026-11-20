//
//  Pot6Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 6: "Chậu tam thạch anh hồng" (pot6)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot6Scene.sks` nếu có
/// - Kích thước & toạ độ chuẩn theo ảnh `Pot6@4.167x.png` (361 x 207)
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ đáy ~40%)
/// - Hiệu ứng đặc trưng: "Tam thạch anh hồng" (Rose quartz crystals glow & prism twinkle)
///   - Idle: 3 cụm tinh thể thạch anh hồng tỏa hào quang thanh khiết, lấp lánh ánh kim cương
///   - Tap: Nhún nảy đàn hồi + bung tỏa chùm mảnh tinh thể pha lê & bụi sao hồng phấn
public final class Pot6Node: SKNode, PotInteractiveNode {

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
    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Toạ độ ban đầu của chậu (chống trôi toạ độ khi tap liên tục)
    private var initialPotPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở
    private var baseScale: CGFloat = 1.0

    /// Danh sách hiệu ứng khi tap vào chậu (có thể tùy biến, thay đổi hoặc gán thêm để tái sử dụng)
    public var tapEffects: [PotTapEffect] = [QuartzBurstEffect()]

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
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tỉ lệ ảnh gốc: 361 x 207 (aspect ~ 0.5734)
        let aspect: CGFloat = 207.0 / 361.0
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        // pot6 có thân bè rộng nhưng đáy tiếp xúc chỉ ~40% bề rộng
        if !isHanging {
            let baseContactW = targetW * 0.40
            let shadowW = max(26.0, baseContactW * 1.15)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot6Scene.sks nếu có
        if let scene = loadSceneTemplate(),
           let templatePot = scene.childNode(withName: "potNode") as? SKSpriteNode,
           templatePot.texture != nil {
            templatePot.removeFromParent()
            templatePot.isHidden = false
            templatePot.isPaused = false
            templatePot.speed = 1.0
            templatePot.size = CGSize(width: targetW, height: targetH)
            templatePot.anchorPoint = CGPoint(x: 0.5, y: isHanging ? 1.0 : 0.0)
            templatePot.position = CGPoint(x: 0, y: 0)
            templatePot.zPosition = 50
            potRootNode.addChild(templatePot)
            self.potNode = templatePot
            self.initialPotPosition = templatePot.position

            // Nạp socket cắm cây từ scene Pot6Scene.sks
            if let mount = scene.childNode(withName: "plantMount") {
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                let scaleX = targetW / 361.0
                let scaleY = targetH / 207.0
                mount.position = CGPoint(x: mount.position.x * scaleX, y: mount.position.y * scaleY)
                mount.zPosition = 10
                potRootNode.addChild(mount)
                self.plantMountNode = mount
            }

            startRoseQuartzGlow(potBounds: templatePot.size)
            return
        }

        // 3. Fallback nạp texture ảnh pot6 (Pot6@4.167x.png)
        guard let texture = loadPot6Texture() else { return }

        let node = SKSpriteNode(texture: texture)
        node.name = "potNode"
        node.size = CGSize(width: targetW, height: targetH)
        node.zPosition = 50
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

        // Socket cắm cây mặc định nếu chưa nạp được scene
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: isHanging ? -targetH * 0.65 : targetH * 0.88)
        mount.zPosition = 10
        potRootNode.addChild(mount)
        self.plantMountNode = mount

        // 4. Kích hoạt hiệu ứng đặc trưng "Tam thạch anh hồng"
        startRoseQuartzGlow(potBounds: CGSize(width: targetW, height: targetH))
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot6Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot6Texture() -> SKTexture? {
        let candidates = [
            "Pot6@4.167x",
            "pot6@4.167x",
            "Pot6",
            "pot6",
            "pot6-Asset-1@4.167x",
            "pot6_Asset-1@4.167x",
            "pot6-Asset-1",
            "pot6_Asset-1",
            "i_pot6",
            "pot_pot6"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        if let bundleUrl = Bundle.main.url(forResource: "Pot6@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "pot6", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot6", isHanging: isHanging).texture
    }

    // MARK: - Hiệu ứng Idle: "Tam thạch anh hồng" (Rose Quartz Crystals)

    private func startRoseQuartzGlow(potBounds: CGSize) {
        guard let pot = potNode else { return }
        removeAction(forKey: "potQuartzGlow")

        // 3 điểm tỏa sáng tinh thể thạch anh (Tam thạch anh: Trái, Giữa, Phải)
        let baseY: CGFloat = isHanging ? -potBounds.height * 0.50 : potBounds.height * 0.50
        let crystalPositions = [
            CGPoint(x: -potBounds.width * 0.28, y: baseY),
            CGPoint(x: 0, y: baseY + (isHanging ? -potBounds.height * 0.08 : potBounds.height * 0.08)),
            CGPoint(x: potBounds.width * 0.28, y: baseY)
        ]

        for (idx, pos) in crystalPositions.enumerated() {
            let glow = SKShapeNode(circleOfRadius: 4.5)
            glow.fillColor = UIColor(red: 1.0, green: 0.60, blue: 0.80, alpha: 0.45)
            glow.strokeColor = .clear
            glow.position = pos
            glow.zPosition = 14
            glow.name = "quartzGlow_\(idx)"
            pot.addChild(glow)

            let delay = Double(idx) * 0.4
            let pulseUp = SKAction.scale(to: 1.45, duration: 1.1)
            pulseUp.timingMode = .easeInEaseOut
            let fadeUp = SKAction.fadeAlpha(to: 0.70, duration: 1.1)
            let pulseDown = SKAction.scale(to: 0.85, duration: 1.2)
            pulseDown.timingMode = .easeInEaseOut
            let fadeDown = SKAction.fadeAlpha(to: 0.25, duration: 1.2)

            let loop = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([pulseUp, fadeUp]),
                    SKAction.group([pulseDown, fadeDown])
                ]))
            ])
            glow.run(loop)
        }

        // Tinh thể nhấp nháy phát sáng định kỳ
        let waitTwinkle = SKAction.wait(forDuration: Double.random(in: 1.5...2.8))
        let spawnTwinkle = SKAction.run { [weak self] in
            guard let self = self, let pot = self.potNode else { return }
            let randomTarget = crystalPositions.randomElement() ?? .zero
            self.emitQuartzSparkle(on: pot, at: randomTarget)
        }
        let twinkleLoop = SKAction.sequence([waitTwinkle, spawnTwinkle])
        run(SKAction.repeatForever(twinkleLoop), withKey: "potQuartzGlow")
    }

    private func emitQuartzSparkle(on pot: SKNode, at basePos: CGPoint) {
        let sparkle = QuartzBurstEffect.createDiamondCrystalNode(radius: CGFloat.random(in: 3.5...5.5), color: UIColor(red: 1.0, green: 0.80, blue: 0.92, alpha: 0.95))
        sparkle.position = CGPoint(
            x: basePos.x + CGFloat.random(in: -8...8),
            y: basePos.y + CGFloat.random(in: -6...6)
        )
        sparkle.zPosition = 25
        sparkle.alpha = 0.0
        sparkle.setScale(0.2)
        pot.addChild(sparkle)

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.18)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.18)
        let rotate = SKAction.rotate(byAngle: .pi * 0.5, duration: 0.50)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.32)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.32)

        let anim = SKAction.sequence([
            SKAction.group([fadeIn, scaleUp]),
            SKAction.wait(forDuration: 0.12),
            SKAction.group([fadeOut, scaleDown]),
            SKAction.removeFromParent()
        ])
        sparkle.run(SKAction.group([anim, rotate]))
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
                compressX: 1.11,
                compressY: 0.89,
                compressDuration: 0.09,
                reboundX: 0.95,
                reboundY: 1.07,
                reboundDuration: 0.13,
                settleDuration: 0.15,
                shadowShrink: 0.86
            )
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

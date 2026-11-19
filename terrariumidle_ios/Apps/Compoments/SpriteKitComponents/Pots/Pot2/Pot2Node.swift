//
//  Pot2Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 2: "Chậu sọc đôi vàng" (pot2)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot2Scene.sks` nếu có
/// - Kích thước & toạ độ chuẩn theo ảnh `Pot2-1@4.167x.png` (294 x 255)
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ đáy ~78%)
/// - Đặc trưng chậu sọc đôi vàng: Đáy vững chãi, hai viền sọc vàng kim tinh tế
public final class Pot2Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false

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

        // Tỉ lệ ảnh gốc: 294 x 255 (aspect ~ 0.8673)
        let aspect: CGFloat = 255.0 / 294.0
        let targetH = containerSize.height * 0.98
        let targetW = min(targetH / aspect, containerSize.width * 0.96)

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        // pot2 có đáy chiếm ~78% bề rộng, đế vững
        if !isHanging {
            let baseContactW = targetW * 0.78
            let shadowW = max(30.0, baseContactW * 1.10)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot2Scene.sks nếu có
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
            return
        }

        // 3. Fallback nạp texture ảnh pot2 (Pot2-1@4.167x.png)
        guard let texture = loadPot2Texture() else { return }

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
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot2Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot2Texture() -> SKTexture? {
        let candidates = [
            "Pot2-1@4.167x",
            "Pot2-1",
            "pot2-Asset-1@4.167x",
            "pot2_Asset-1@4.167x",
            "pot2-Asset-1",
            "pot2_Asset-1",
            "pot2",
            "Pot2",
            "i_pot2",
            "pot_pot2"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        if let bundleUrl = Bundle.main.url(forResource: "Pot2-1@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "pot2", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot2", isHanging: isHanging).texture
    }

    // MARK: - Phản hồi tương tác Tap (Tap Animation)

    public func playTapAnimation() {
        guard let node = potNode else { return }
        node.removeAction(forKey: "potTapBounce")
        node.position = initialPotPosition

        let compress = SKAction.scaleX(to: 1.09, y: 0.91, duration: 0.08)
        compress.timingMode = .easeIn
        let rebound = SKAction.scaleX(to: 0.96, y: 1.05, duration: 0.12)
        rebound.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: 0.14)
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

        if let shadow = shadowNode {
            shadow.removeAction(forKey: "shadowBounce")
            let shrink = SKAction.scale(to: 0.88, duration: 0.08)
            let restore = SKAction.scale(to: 1.0, duration: 0.26)
            restore.timingMode = .easeOut
            shadow.run(SKAction.sequence([shrink, restore]), withKey: "shadowBounce")
        }

        spawnGoldGlint()
    }

    private func spawnGoldGlint() {
        guard let pot = potNode else { return }
        let potFrame = pot.frame
        let count = Int.random(in: 4...6)

        for i in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.8))
            spark.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.9) // Ánh vàng hoàng kim
            spark.strokeColor = .clear

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.25))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 35
            spark.alpha = 0.0
            potRootNode.addChild(spark)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.08)
            let move = SKAction.moveBy(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: 8...24), duration: 0.38)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.24)
            let seq = SKAction.sequence([delay, fadeIn, SKAction.group([move, fadeOut]), SKAction.removeFromParent()])
            spark.run(seq)
        }
    }
}

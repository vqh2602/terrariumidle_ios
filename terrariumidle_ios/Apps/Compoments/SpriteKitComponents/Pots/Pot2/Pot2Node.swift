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
    public var tapEffects: [PotTapEffect] = [GoldGlintEffect()]

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

        // Tỉ lệ ảnh gốc: 294 x 255 (aspect ~ 0.8673)
        let aspect: CGFloat = 255.0 / 294.0
        let targetH = containerSize.height * 0.98
        let baseW = min(targetH / aspect, containerSize.width * 0.96)
        let maxW = containerSize.width * 0.96
        let targetW = baseW + (maxW - baseW) * widthFill

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
            if widthFill > 0 {
                let extraW = (containerSize.width * 0.96 - templatePot.size.width) * widthFill
                if extraW > 0 {
                    templatePot.size.width += extraW
                }
            }
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

        // 1. Squash & Stretch nén nảy đàn hồi + bóng đổ + đu đưa chậu treo
        PotBounceAnimator.applyBounce(
            to: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging,
            config: .firm
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

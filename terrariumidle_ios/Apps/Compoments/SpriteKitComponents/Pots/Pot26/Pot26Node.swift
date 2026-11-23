//
//  Pot26Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 26: "Chậu đá đa giác phấn hồng" (pot26)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot26Scene.sks` nếu có
/// - Kích thước chuẩn: (304.0 x 327.0)
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ tiếp xúc đáy ~86%)
public final class Pot26Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false
    private var widthFill: CGFloat = Pot26View.defaultWidthFill

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

    /// Hiệu ứng chuyển động rung / nảy / đu đưa khi tap vào chậu
    public var motionEffect: PotMotionEffect = FirmBounceMotionEffect()

    /// Danh sách hiệu ứng thị giác khi tap vào chậu
    public var tapEffects: [PotTapEffect] = [QuartzBurstEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 95), isHanging: Bool = false, widthFill: CGFloat = Pot26View.defaultWidthFill) {
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

    public func configure(containerSize: CGSize, isHanging: Bool = false, widthFill: CGFloat = Pot26View.defaultWidthFill) {
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

        let aspect: CGFloat = 327.0 / 304.0
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        if !isHanging {
            let baseContactW = targetW * 0.86
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

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot26Scene.sks nếu có
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

            // Nạp socket cắm cây từ scene Pot26Scene.sks
            if let mount = scene.childNode(withName: "plantMount") {
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                let scaleX = targetW / 304.0
                let scaleY = targetH / 327.0
                mount.position = CGPoint(x: mount.position.x * scaleX, y: mount.position.y * scaleY)
                mount.zPosition = 10
                potRootNode.addChild(mount)
                self.plantMountNode = mount
            }
            return
        }

        // 3. Fallback nạp texture ảnh pot26
        guard let texture = loadPot26Texture() else { return }

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
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot26Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot26Texture() -> SKTexture? {
        let candidates = [
            "Pot26-1@4.167x",
            "pot26-1@4.167x",
            "pot26_Asset-1@4.167x",
            "pot26"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot26", isHanging: isHanging).texture
    }

    // MARK: - Phản hồi tương tác Tap (Motion & Visual Tap Animation)

    public func playTapAnimation() {
        guard let node = potNode else { return }

        // 1. Kích hoạt hiệu ứng chuyển động rung/nảy
        motionEffect.apply(
            targetNode: node,
            potNode: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

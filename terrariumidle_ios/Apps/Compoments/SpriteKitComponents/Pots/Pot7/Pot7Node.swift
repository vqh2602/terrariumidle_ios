//
//  Pot7Node.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 7: "Chậu đất sét" (pot7)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot7Scene.sks` nếu có
/// - Kích thước & toạ độ chuẩn theo ảnh `Pot7@4.167x.png` (266 x 211)
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ đáy ~50%)
/// - Đặc trưng chậu đất sét: Màu nâu mộc mạc, thoát nước tốt, phản hồi nén nảy êm ái
public final class Pot7Node: SKNode, PotInteractiveNode {

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

    /// Hiệu ứng chuyển động rung / nảy / đu đưa khi tap vào chậu (mặc định: StandardBounce)
    public var motionEffect: PotMotionEffect = StandardBounceMotionEffect()

    /// Danh sách hiệu ứng khi tap vào chậu (có thể tùy biến, thay đổi hoặc gán thêm để tái sử dụng)
    public var tapEffects: [PotTapEffect] = [EarthenParticlesEffect()]

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

        // Tỉ lệ ảnh gốc: 266 x 211 (aspect ~ 0.7932)
        let aspect: CGFloat = 211.0 / 266.0
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        // pot7 có đáy chiếm ~50% bề rộng
        if !isHanging {
            let baseContactW = targetW * 0.50
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

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot7Scene.sks nếu có
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

            // Nạp socket cắm cây từ scene Pot7Scene.sks
            if let mount = scene.childNode(withName: "plantMount") {
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                let scaleX = targetW / 266.0
                let scaleY = targetH / 211.0
                mount.position = CGPoint(x: mount.position.x * scaleX, y: mount.position.y * scaleY)
                mount.zPosition = 10
                potRootNode.addChild(mount)
                self.plantMountNode = mount
            }
            return
        }

        // 3. Fallback nạp texture ảnh pot7 (Pot7@4.167x.png)
        guard let texture = loadPot7Texture() else { return }

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
        if let scene = SKScene(fileNamed: "Pot7Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot7Texture() -> SKTexture? {
        let candidates = [
            "Pot7@4.167x",
            "pot7@4.167x",
            "Pot7",
            "pot7",
            "pot7-Asset-1@4.167x",
            "pot7_Asset-1@4.167x",
            "pot7-Asset-1",
            "pot7_Asset-1",
            "i_pot7",
            "pot_pot7"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        if let bundleUrl = Bundle.main.url(forResource: "Pot7@4.167x", withExtension: "png") ??
                           Bundle.main.url(forResource: "pot7", withExtension: "png") {
            if let data = try? Data(contentsOf: bundleUrl), let img = UIImage(data: data) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot7", isHanging: isHanging).texture
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

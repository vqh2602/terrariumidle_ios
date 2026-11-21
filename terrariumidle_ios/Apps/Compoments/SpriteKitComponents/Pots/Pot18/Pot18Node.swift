//
//  Pot18Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 18: "Chậu đất kiềng" (pot18 - Chậu treo / Hanging Pot)
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot18Scene.sks` (anchorPoint = (0.5, 1.0) tại móc treo)
/// - Kích thước & toạ độ chuẩn theo ảnh `Pot18@4.167x.png` (497 x 821)
/// - Mặc định là Chậu treo (isHanging = true), đu đưa con lắc gió tự nhiên quanh đỉnh móc treo
/// - Hỗ trợ linh hoạt cả 2 chế độ: Chậu treo (isHanging = true) và Chậu để bàn (isHanging = false)
/// - Hiệu ứng đặc trưng: Bụi đất nung terracotta bay toả khi chạm (EarthenParticlesEffect)
public final class Pot18Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = true
    private var widthFill: CGFloat = 0.0

    /// Gốc rễ chậu và khung treo đu đưa
    private let potRootNode = SKNode()
    /// Rig đu đưa chậu treo (xoay quanh điểm móc treo (0, 0))
    private let hangingRigNode = SKNode()

    /// Sprite hiển thị chậu cây
    private var potNode: SKSpriteNode?
    /// Bóng đổ dưới đáy chậu (khi để bàn)
    private var shadowNode: SKNode?
    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Toạ độ ban đầu của chậu (chống trôi toạ độ khi tap liên tục)
    private var initialPotPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở
    private var baseScale: CGFloat = 1.0

    /// Hiệu ứng chuyển động rung / nảy / đu đưa khi tap vào chậu (mặc định: SpringPendulum)
    public var motionEffect: PotMotionEffect = SpringPendulumMotionEffect()

    /// Danh sách hiệu ứng thị giác dạng hạt khi tap vào chậu
    public var tapEffects: [PotTapEffect] = [EarthenParticlesEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 180), isHanging: Bool = true, widthFill: CGFloat = 0.0) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        super.init()

        addChild(potRootNode)
        potRootNode.addChild(hangingRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(potRootNode)
        potRootNode.addChild(hangingRigNode)
    }

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = true, widthFill: CGFloat = 0.0) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        build()
    }

    // MARK: - Build Scene

    public func build() {
        potRootNode.removeAllChildren()
        potRootNode.removeAllActions()
        hangingRigNode.removeAllChildren()
        hangingRigNode.removeAllActions()
        hangingRigNode.zRotation = 0.0
        potRootNode.addChild(hangingRigNode)

        potNode = nil
        shadowNode = nil
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tỉ lệ ảnh gốc: 497 x 821 (aspect ~ 1.6519)
        let aspect: CGFloat = 821.0 / 497.0
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu là chậu để bàn)
        if !isHanging {
            let baseContactW = targetW * 0.50
            let shadowW = max(28.0, baseContactW * 1.10)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }

        let mountParentNode: SKNode = isHanging ? hangingRigNode : potRootNode
        let potParentNode: SKNode = isHanging ? hangingRigNode : potRootNode

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot18Scene.sks nếu có
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
            potParentNode.addChild(templatePot)
            self.potNode = templatePot
            self.initialPotPosition = templatePot.position

            // Nạp socket cắm cây từ scene Pot18Scene.sks
            if let mount = scene.childNode(withName: "plantMount") {
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                let scaleY = targetH / 821.0
                if isHanging {
                    // Khi treo: miệng chậu tại toạ độ Y âm tính từ đỉnh móc treo (-485pt trong canvas 821)
                    mount.position = CGPoint(x: 0, y: -485.0 * scaleY)
                } else {
                    // Khi để bàn: miệng chậu tại toạ độ Y dương tính từ đáy (336pt trong canvas 821)
                    mount.position = CGPoint(x: 0, y: 336.0 * scaleY)
                }
                mount.zPosition = 10
                mountParentNode.addChild(mount)
                self.plantMountNode = mount
            }

            if isHanging {
                addIdlePendulumSway()
            }
            return
        }

        // 3. Fallback nạp texture ảnh Pot18 (Pot18@4.167x.png)
        guard let texture = loadPot18Texture() else { return }

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

        potParentNode.addChild(node)
        self.potNode = node
        self.initialPotPosition = node.position

        // Socket cắm cây mặc định nếu chưa nạp được scene
        let mount = SKNode()
        mount.name = "plantMount"
        let scaleY = targetH / 821.0
        mount.position = CGPoint(x: 0, y: isHanging ? -485.0 * scaleY : 336.0 * scaleY)
        mount.zPosition = 10
        mountParentNode.addChild(mount)
        self.plantMountNode = mount

        if isHanging {
            addIdlePendulumSway()
        }
    }

    // MARK: - Mount Point
    public var plantMountPoint: CGPoint {
        if let mount = plantMountNode {
            return mount.position
        }
        let targetH = containerSize.height * 0.98
        let scaleY = targetH / 821.0
        return CGPoint(x: 0, y: isHanging ? -485.0 * scaleY : 336.0 * scaleY)
    }

    // MARK: - Idle Pendulum Sway (Chậu treo đu đưa êm dịu trong gió)

    private func addIdlePendulumSway() {
        hangingRigNode.removeAction(forKey: "idleSway")
        let swayLeft = SKAction.rotate(toAngle: -0.016, duration: 3.6)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.016, duration: 3.6)
        swayRight.timingMode = .easeInEaseOut
        let swaySequence = SKAction.sequence([swayLeft, swayRight])
        hangingRigNode.run(SKAction.repeatForever(swaySequence), withKey: "idleSway")
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Pot18Scene") {
            return scene
        }
        return nil
    }

    // MARK: - Texture Loader

    private func loadPot18Texture() -> SKTexture? {
        let candidates = [
            "Pot18@4.167x",
            "pot18@4.167x",
            "Pot18",
            "pot18",
            "pot18-1@4.167x",
            "pot18_Asset-1@4.167x",
            "i_pot18",
            "pot_pot18"
        ]

        for name in candidates {
            if let img = UIImage(named: name) {
                return SKTexture(image: img)
            }
        }

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot18", isHanging: isHanging).texture
    }

    // MARK: - Phản hồi tương tác Tap (Motion & Visual Tap Animation)

    public func playTapAnimation() {
        guard let node = potNode else { return }

        // 1. Kích hoạt hiệu ứng chuyển động rung/lắc/nảy
        let target = isHanging ? hangingRigNode : node
        motionEffect.apply(
            targetNode: target,
            potNode: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging,
            onComplete: { [weak self] in
                if self?.isHanging == true {
                    self?.addIdlePendulumSway()
                }
            }
        )

        // 2. Kích hoạt danh sách hiệu ứng hạt tap đã đăng ký
        for effect in tapEffects {
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }
    }
}

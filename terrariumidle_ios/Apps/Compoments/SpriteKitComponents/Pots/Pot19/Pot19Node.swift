//
//  Pot19Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 19: "Chậu lam ngọc tròn" (pot19)
/// - Mô hình Chậu Treo Phân Lớp (Layered Hanging Pot - `hanging,front`):
///   * `backRope` (Dây treo sau): zPos = 5, y = -723pt (nằm sau cây)
///   * `plantMount` (Socket cắm cây): zPos = 10, y = -774pt
///   * `potBody` (Bầu chậu lam ngọc tròn): zPos = 50 (che cuống cây đứng, nằm sau cành lá rủ)
///   * `frontRope` (Dây treo trước vắt chéo): zPos = 100 (vắt đè lên cành lá cây)
/// - Tự động nạp toạ độ pixel chuẩn từ `Pot19Scene.sks` (khớp chính xác 100% với `Pot19.svg`)
/// - Hiệu ứng đu đưa vật lý (Pendulum Swing & Squash) khi chạm
public final class Pot19Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = true
    private var widthFill: CGFloat = 0.0

    /// Gốc rễ chậu và khung treo đu đưa
    private let potRootNode = SKNode()
    /// Rig đu đưa chậu treo (xoay quanh điểm móc treo (0, 0))
    private let hangingRigNode = SKNode()

    /// Các layer thành phần của chậu
    private var backRopeNode: SKSpriteNode?
    private var potBodyNode: SKSpriteNode?
    private var frontRopeNode: SKSpriteNode?

    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Hiệu ứng chuyển động đu đưa con lắc vật lý khi tap vào chậu (mặc định: ElasticPendulum)
    public var motionEffect: PotMotionEffect = ElasticPendulumMotionEffect()

    /// Danh sách hiệu ứng thị giác dạng hạt khi tap vào chậu (ánh ngọc lam lấp lánh)
    public var tapEffects: [PotTapEffect] = [QuartzBurstEffect()]

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

    // MARK: - PotInteractiveNode Protocol

    public var asNode: SKNode { self }

    public var plantMountPoint: CGPoint {
        if let mount = plantMountNode {
            return mount.position
        }
        let scaleY = (containerSize.height * 0.98) / 1193.0
        return CGPoint(x: 0, y: -774.0 * scaleY)
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
        hangingRigNode.removeAllChildren()
        hangingRigNode.removeAllActions()
        hangingRigNode.zRotation = 0
        hangingRigNode.yScale = 1.0
        hangingRigNode.xScale = 1.0

        backRopeNode = nil
        potBodyNode = nil
        frontRopeNode = nil
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 301 x 1193 (aspect ~ 3.963)
        let baseCanvasW: CGFloat = 301.0
        let baseCanvasH: CGFloat = 1193.0
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        let scaleX = targetW / baseCanvasW
        let scaleY = targetH / baseCanvasH

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Pot19Scene.sks
        if let scene = loadSceneTemplate() {
            // Nạp Dây sau backRope (z = 51)
            if let backRope = scene.childNode(withName: "backRope") as? SKSpriteNode {
                backRope.removeFromParent()
                backRope.isHidden = false
                backRope.isPaused = false
                backRope.size = CGSize(width: backRope.size.width * scaleX, height: backRope.size.height * scaleY)
                backRope.position = CGPoint(x: backRope.position.x * scaleX, y: backRope.position.y * scaleY)
                backRope.zPosition = 51
                hangingRigNode.addChild(backRope)
                self.backRopeNode = backRope
            }

            // Nạp Socket cắm cây plantMount (z = 10)
            if let mount = scene.childNode(withName: "plantMount") {
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                mount.position = CGPoint(x: mount.position.x * scaleX, y: mount.position.y * scaleY)
                mount.zPosition = 10
                hangingRigNode.addChild(mount)
                self.plantMountNode = mount
            }

            // Nạp Thân chậu potBody (z = 50)
            if let potBody = scene.childNode(withName: "potBody") as? SKSpriteNode {
                potBody.removeFromParent()
                potBody.isHidden = false
                potBody.isPaused = false
                potBody.size = CGSize(width: potBody.size.width * scaleX, height: potBody.size.height * scaleY)
                potBody.position = CGPoint(x: potBody.position.x * scaleX, y: potBody.position.y * scaleY)
                potBody.zPosition = 50
                hangingRigNode.addChild(potBody)
                self.potBodyNode = potBody
            }

            // Nạp Dây trước frontRope (z = 100)
            if let frontRope = scene.childNode(withName: "frontRope") as? SKSpriteNode {
                frontRope.removeFromParent()
                frontRope.isHidden = false
                frontRope.isPaused = false
                frontRope.size = CGSize(width: frontRope.size.width * scaleX, height: frontRope.size.height * scaleY)
                frontRope.position = CGPoint(x: frontRope.position.x * scaleX, y: frontRope.position.y * scaleY)
                frontRope.zPosition = 100
                hangingRigNode.addChild(frontRope)
                self.frontRopeNode = frontRope
            }

            addIdlePendulumSway()
            return
        }

        // 2. Procedural Fallback nếu chưa tải được .sks
        buildProceduralPot(scaleX: scaleX, scaleY: scaleY)
        addIdlePendulumSway()
    }

    private func buildProceduralPot(scaleX: CGFloat, scaleY: CGFloat) {
        // Dây sau (z = 5)
        let backRope = SKSpriteNode(texture: loadTexture(named: "pot19-3@4.167x"))
        backRope.name = "backRope"
        backRope.size = CGSize(width: 301.0 * scaleX, height: 918.0 * scaleY)
        backRope.position = CGPoint(x: 0, y: -723.0 * scaleY)
        backRope.zPosition = 5
        hangingRigNode.addChild(backRope)
        self.backRopeNode = backRope

        // Socket cắm cây (z = 10)
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: -774.0 * scaleY)
        mount.zPosition = 10
        hangingRigNode.addChild(mount)
        self.plantMountNode = mount

        // Thân chậu lam ngọc tròn (z = 50)
        let potBody = SKSpriteNode(texture: loadTexture(named: "pot19-2@4.167x"))
        potBody.name = "potBody"
        potBody.size = CGSize(width: 278.0 * scaleX, height: 253.0 * scaleY)
        potBody.position = CGPoint(x: 0, y: -900.5 * scaleY)
        potBody.zPosition = 50
        hangingRigNode.addChild(potBody)
        self.potBodyNode = potBody

        // Dây trước (z = 100)
        let frontRope = SKSpriteNode(texture: loadTexture(named: "pot19-4@4.167x"))
        frontRope.name = "frontRope"
        frontRope.size = CGSize(width: 273.0 * scaleX, height: 834.0 * scaleY)
        frontRope.position = CGPoint(x: 0, y: -425.0 * scaleY)
        frontRope.zPosition = 100
        hangingRigNode.addChild(frontRope)
        self.frontRopeNode = frontRope
    }

    // MARK: - Idle Pendulum Sway (Đu đưa con lắc tự nhiên trong gió)

    private func addIdlePendulumSway() {
        hangingRigNode.removeAction(forKey: "idlePendulum")
        let swayLeft = SKAction.rotate(toAngle: -0.015, duration: 3.4)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.015, duration: 3.4)
        swayRight.timingMode = .easeInEaseOut
        let swaySequence = SKAction.sequence([swayLeft, swayRight])
        hangingRigNode.run(SKAction.repeatForever(swaySequence), withKey: "idlePendulum")
    }

    // MARK: - Phản hồi tương tác Tap (Motion & Particles)

    public func playTapAnimation() {
        // 1. Kích hoạt hiệu ứng chuyển động rung/lắc/nảy trên hangingRigNode
        motionEffect.apply(
            targetNode: hangingRigNode,
            potNode: potBodyNode,
            shadowNode: nil,
            initialPosition: .zero,
            isHanging: isHanging,
            containerSize: containerSize
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã đăng ký
        if let body = potBodyNode {
            for effect in tapEffects {
                effect.trigger(on: body, in: potRootNode, isHanging: isHanging)
            }
        }
    }

    // MARK: - Helpers

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Pot19Scene")
    }

    private func loadTexture(named name: String) -> SKTexture {
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 { return tex }
        return SKTexture()
    }
}

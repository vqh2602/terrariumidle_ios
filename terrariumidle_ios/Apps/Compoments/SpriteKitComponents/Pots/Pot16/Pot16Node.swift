//
//  Pot16Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 16: "Chậu sứ mạ vàng" (pot16)
/// - Mô hình Chậu Treo Phân Lớp (Layered Hanging Pot - `hanging,front`):
///   * `plantMount` (Socket cắm cây): zPos = 10, y = -353pt
///   * `potBody` (Bầu chậu sứ vàng): zPos = 50 (che cuống cây đứng, nằm sau cành lá rủ)
///   * `potRim` (Miệng chậu viền vàng): zPos = 52
///   * `frontLeftRope` + `frontRightRope` (2 dây trước + móc treo): zPos = 100 (vắt đè lên cành lá cây)
/// - Tự động nạp toạ độ pixel chuẩn từ `Pot16Scene.sks` (khớp chính xác 100% với `Pot16.svg`)
/// - Hiệu ứng đu đưa vật lý (Pendulum Swing & Squash) khi chạm
public final class Pot16Node: SKNode, PotInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = true
    private var widthFill: CGFloat = 0.0

    /// Gốc rễ chậu và khung treo đu đưa
    private let potRootNode = SKNode()
    /// Rig đu đưa chậu treo (xoay quanh điểm móc treo (0, 0))
    private let hangingRigNode = SKNode()

    /// Các layer thành phần của chậu
    private var potBodyNode: SKSpriteNode?
    private var potRimNode: SKSpriteNode?
    private var frontLeftRopeNode: SKSpriteNode?
    private var frontRightRopeNode: SKSpriteNode?

    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Danh sách hiệu ứng khi tap vào chậu
    public var tapEffects: [PotTapEffect] = [SparkleBurstEffect()]

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
        let scaleY = (containerSize.height * 0.98) / 494.0
        return CGPoint(x: 0, y: -353.0 * scaleY)
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

        potBodyNode = nil
        potRimNode = nil
        frontLeftRopeNode = nil
        frontRightRopeNode = nil
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 155 x 494 (aspect ~ 3.187)
        let baseCanvasW: CGFloat = 155.0
        let baseCanvasH: CGFloat = 494.0
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        let scaleX = targetW / baseCanvasW
        let scaleY = targetH / baseCanvasH

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Pot16Scene.sks
        if let scene = loadSceneTemplate() {
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

            // Nạp Miệng chậu potRim (z = 52)
            if let potRim = scene.childNode(withName: "potRim") as? SKSpriteNode {
                potRim.removeFromParent()
                potRim.isHidden = false
                potRim.isPaused = false
                potRim.size = CGSize(width: potRim.size.width * scaleX, height: potRim.size.height * scaleY)
                potRim.position = CGPoint(x: potRim.position.x * scaleX, y: potRim.position.y * scaleY)
                potRim.zPosition = 52
                hangingRigNode.addChild(potRim)
                self.potRimNode = potRim
            }

            // Nạp Dây trước trái frontLeftRope (z = 100)
            if let frontLeft = scene.childNode(withName: "frontLeftRope") as? SKSpriteNode {
                frontLeft.removeFromParent()
                frontLeft.isHidden = false
                frontLeft.isPaused = false
                frontLeft.size = CGSize(width: frontLeft.size.width * scaleX, height: frontLeft.size.height * scaleY)
                frontLeft.position = CGPoint(x: frontLeft.position.x * scaleX, y: frontLeft.position.y * scaleY)
                frontLeft.zPosition = 100
                hangingRigNode.addChild(frontLeft)
                self.frontLeftRopeNode = frontLeft
            }

            // Nạp Dây trước phải frontRightRope (z = 100)
            if let frontRight = scene.childNode(withName: "frontRightRope") as? SKSpriteNode {
                frontRight.removeFromParent()
                frontRight.isHidden = false
                frontRight.isPaused = false
                frontRight.size = CGSize(width: frontRight.size.width * scaleX, height: frontRight.size.height * scaleY)
                frontRight.position = CGPoint(x: frontRight.position.x * scaleX, y: frontRight.position.y * scaleY)
                frontRight.zPosition = 100
                hangingRigNode.addChild(frontRight)
                self.frontRightRopeNode = frontRight
            }

            return
        }

        // 2. FALLBACK PROCEDURAL (Nếu chưa nạp được scene)
        buildProceduralLayers(scaleX: scaleX, scaleY: scaleY)
    }

    private func buildProceduralLayers(scaleX: CGFloat, scaleY: CGFloat) {
        // 1. Socket cắm cây
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: -353.0 * scaleY)
        mount.zPosition = 10
        hangingRigNode.addChild(mount)
        self.plantMountNode = mount

        // 2. Thân chậu mạ vàng
        if let bodyTex = loadTexture(name: "pot16-4@4.167x") {
            let potBody = SKSpriteNode(texture: bodyTex)
            potBody.name = "potBody"
            potBody.size = CGSize(width: 155.0 * scaleX, height: 154.0 * scaleY)
            potBody.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            potBody.position = CGPoint(x: 0, y: -417.8 * scaleY)
            potBody.zPosition = 50
            hangingRigNode.addChild(potBody)
            self.potBodyNode = potBody
        }

        // 3. Miệng chậu viền vàng
        if let rimTex = loadTexture(name: "pot16-5@4.167x") {
            let potRim = SKSpriteNode(texture: rimTex)
            potRim.name = "potRim"
            potRim.size = CGSize(width: 133.0 * scaleX, height: 19.0 * scaleY)
            potRim.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            potRim.position = CGPoint(x: -1.0 * scaleX, y: -353.3 * scaleY)
            potRim.zPosition = 52
            hangingRigNode.addChild(potRim)
            self.potRimNode = potRim
        }

        // 4. Dây treo trái
        if let frontLeftTex = loadTexture(name: "pot16-2@4.167x") {
            let frontLeft = SKSpriteNode(texture: frontLeftTex)
            frontLeft.name = "frontLeftRope"
            frontLeft.size = CGSize(width: 96.0 * scaleX, height: 369.0 * scaleY)
            frontLeft.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frontLeft.position = CGPoint(x: -26.3 * scaleX, y: -185.3 * scaleY)
            frontLeft.zPosition = 100
            hangingRigNode.addChild(frontLeft)
            self.frontLeftRopeNode = frontLeft
        }

        // 5. Dây treo phải
        if let frontRightTex = loadTexture(name: "pot16-3@4.167x") {
            let frontRight = SKSpriteNode(texture: frontRightTex)
            frontRight.name = "frontRightRope"
            frontRight.size = CGSize(width: 147.0 * scaleX, height: 366.0 * scaleY)
            frontRight.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frontRight.position = CGPoint(x: -0.6 * scaleX, y: -184.9 * scaleY)
            frontRight.zPosition = 100
            hangingRigNode.addChild(frontRight)
            self.frontRightRopeNode = frontRight
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Pot16Scene")
    }

    // MARK: - Texture Loader

    private func loadTexture(name: String) -> SKTexture? {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return nil
    }

    // MARK: - Phản hồi tương tác Tap (Pendulum Swing Animation)

    public func playTapAnimation() {
        hangingRigNode.removeAction(forKey: "hangingTapSwing")

        let swingAngle: CGFloat = 0.08
        let swing1 = SKAction.rotate(toAngle: swingAngle, duration: 0.28)
        swing1.timingMode = .easeOut
        let swing2 = SKAction.rotate(toAngle: -swingAngle * 0.75, duration: 0.38)
        swing2.timingMode = .easeInEaseOut
        let swing3 = SKAction.rotate(toAngle: swingAngle * 0.40, duration: 0.34)
        swing3.timingMode = .easeInEaseOut
        let swing4 = SKAction.rotate(toAngle: -swingAngle * 0.20, duration: 0.28)
        swing4.timingMode = .easeInEaseOut
        let rest = SKAction.rotate(toAngle: 0.0, duration: 0.24)
        rest.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([swing1, swing2, swing3, swing4, rest])
        hangingRigNode.run(sequence, withKey: "hangingTapSwing")

        // Kích hoạt các hiệu ứng hạt tap (SparkleBurstEffect z = 150)
        if let body = potBodyNode {
            for effect in tapEffects {
                effect.trigger(on: body, in: potRootNode, isHanging: isHanging)
            }
        }
    }
}

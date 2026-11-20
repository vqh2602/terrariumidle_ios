//
//  Pot15Node.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 15: "Chậu sứ Msuit" (pot15)
/// - Mô hình Chậu Treo Phân Lớp (Layered Hanging Pot - `hanging,front`):
///   * `backRope` (Dây giữa phía sau): zPos = 5 (nằm sau cây)
///   * `plantMount` (Socket cắm cây): zPos = 10, y = -506pt
///   * `potBody` (Bầu chậu sứ trắng): zPos = 50 (che cuống cây đứng, nằm sau cành lá rủ)
///   * `frontLeftRope` + `frontRightRope` (2 dây trước + móc treo): zPos = 100 (vắt đè lên cành lá cây)
/// - Tự động nạp toạ độ pixel chuẩn từ `Pot15Scene.sks` (khớp chính xác 100% với `Pot15.svg`)
/// - Hiệu ứng đu đưa vật lý (Pendulum Swing & Squash) khi chạm
public final class Pot15Node: SKNode, PotInteractiveNode {

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
        let scaleY = (containerSize.height * 0.98) / 724.0
        return CGPoint(x: 0, y: -506.0 * scaleY)
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

        // Kích thước canvas thiết kế gốc: 363 x 724 (aspect ~ 1.9945)
        let baseCanvasW: CGFloat = 363.0
        let baseCanvasH: CGFloat = 724.0
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        let scaleX = targetW / baseCanvasW
        let scaleY = targetH / baseCanvasH

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Pot15Scene.sks
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

            // Nạp Dây sau backRope (z = 5)
            if let backRope = scene.childNode(withName: "backRope") as? SKSpriteNode {
                backRope.removeFromParent()
                backRope.isHidden = false
                backRope.isPaused = false
                backRope.size = CGSize(width: backRope.size.width * scaleX, height: backRope.size.height * scaleY)
                backRope.position = CGPoint(x: backRope.position.x * scaleX, y: backRope.position.y * scaleY)
                backRope.zPosition = 5
                hangingRigNode.addChild(backRope)
                self.backRopeNode = backRope
            }

            // Nạp Thân chậu potBody (z = 50)
            if let potBody = (scene.childNode(withName: "potBody") ?? scene.childNode(withName: "potNode")) as? SKSpriteNode {
                potBody.removeFromParent()
                potBody.isHidden = false
                potBody.isPaused = false
                potBody.size = CGSize(width: potBody.size.width * scaleX, height: potBody.size.height * scaleY)
                potBody.position = CGPoint(x: potBody.position.x * scaleX, y: potBody.position.y * scaleY)
                potBody.zPosition = 50
                hangingRigNode.addChild(potBody)
                self.potBodyNode = potBody
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
        // 1. Dây giữa sau
        if let backRopeTex = loadTexture(name: "Pot15-4@4.167x") {
            let backRope = SKSpriteNode(texture: backRopeTex)
            backRope.name = "backRope"
            backRope.size = CGSize(width: 10.0 * scaleX, height: 516.0 * scaleY)
            backRope.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            backRope.position = CGPoint(x: 10.5 * scaleX, y: -286.0 * scaleY)
            backRope.zPosition = 5
            hangingRigNode.addChild(backRope)
            self.backRopeNode = backRope
        }

        // 2. Socket cắm cây
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: -506.0 * scaleY)
        mount.zPosition = 10
        hangingRigNode.addChild(mount)
        self.plantMountNode = mount

        // 3. Thân chậu sứ
        if let bodyTex = loadTexture(name: "Pot15-5@4.167x") {
            let potBody = SKSpriteNode(texture: bodyTex)
            potBody.name = "potBody"
            potBody.size = CGSize(width: 363.0 * scaleX, height: 242.0 * scaleY)
            potBody.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            potBody.position = CGPoint(x: 0, y: -603.0 * scaleY)
            potBody.zPosition = 50
            hangingRigNode.addChild(potBody)
            self.potBodyNode = potBody
        }

        // 4. Dây trước trái + móc treo
        if let frontLeftTex = loadTexture(name: "Pot15-2@4.167x") {
            let frontLeft = SKSpriteNode(texture: frontLeftTex)
            frontLeft.name = "frontLeftRope"
            frontLeft.size = CGSize(width: 215.0 * scaleX, height: 506.0 * scaleY)
            frontLeft.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frontLeft.position = CGPoint(x: -74.0 * scaleX, y: -254.0 * scaleY)
            frontLeft.zPosition = 100
            hangingRigNode.addChild(frontLeft)
            self.frontLeftRopeNode = frontLeft
        }

        // 5. Dây trước phải
        if let frontRightTex = loadTexture(name: "Pot15-3@4.167x") {
            let frontRight = SKSpriteNode(texture: frontRightTex)
            frontRight.name = "frontRightRope"
            frontRight.size = CGSize(width: 168.0 * scaleX, height: 479.0 * scaleY)
            frontRight.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frontRight.position = CGPoint(x: 84.5 * scaleX, y: -240.5 * scaleY)
            frontRight.zPosition = 100
            hangingRigNode.addChild(frontRight)
            self.frontRightRopeNode = frontRight
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Pot15Scene")
    }

    // MARK: - Texture Loader

    private func loadTexture(name: String) -> SKTexture? {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return nil
    }

    // MARK: - Tap Animation

    public func playTapAnimation() {
        hangingRigNode.removeAction(forKey: "tapAnimation")

        // 1. Hiệu ứng lắc con lắc vật lý (Pendulum Swing) quanh đỉnh móc treo (0, 0)
        let swingLeft = SKAction.rotate(toAngle: 0.045, duration: 0.16)
        swingLeft.timingMode = .easeOut
        let swingRight = SKAction.rotate(toAngle: -0.038, duration: 0.20)
        swingRight.timingMode = .easeInEaseOut
        let swingBack = SKAction.rotate(toAngle: 0.018, duration: 0.18)
        swingBack.timingMode = .easeInEaseOut
        let swingRest = SKAction.rotate(toAngle: 0.0, duration: 0.22)
        swingRest.timingMode = .easeOut

        let swingAction = SKAction.sequence([swingLeft, swingRight, swingBack, swingRest])

        // 2. Hiệu ứng nhún nảy nén trục Y (Elastic Bounce)
        let squash = SKAction.scaleY(to: 0.96, duration: 0.08)
        squash.timingMode = .easeOut
        let stretch = SKAction.scaleY(to: 1.025, duration: 0.12)
        stretch.timingMode = .easeInEaseOut
        let normal = SKAction.scaleY(to: 1.0, duration: 0.12)
        normal.timingMode = .easeOut

        let bounceAction = SKAction.sequence([squash, stretch, normal])

        hangingRigNode.run(SKAction.group([swingAction, bounceAction]), withKey: "tapAnimation")

        // 3. Kích hoạt hiệu ứng hạt lấp lánh (Sparkle Particles)
        if let body = potBodyNode {
            for effect in tapEffects {
                effect.trigger(on: body, in: potRootNode, isHanging: true)
            }
        }
    }
}

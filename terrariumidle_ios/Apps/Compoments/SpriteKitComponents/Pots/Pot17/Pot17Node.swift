//
//  Pot17Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu 17: "Chậu đất treo" (pot17)
/// - Mô hình Chậu Treo Phân Lớp (Layered Hanging Pot - `hanging,front`):
///   * `backRope` (Dây treo sau): zPos = 5, y = -277pt
///   * `plantMount` (Socket cắm cây): zPos = 10, y = -475pt
///   * `potBody` (Bầu chậu đất nung): zPos = 50 (che cuống cây đứng, nằm sau cành lá rủ)
///   * `frontRope` (Dây treo trước vắt chéo): zPos = 100 (vắt đè lên cành lá cây)
/// - Tự động nạp toạ độ pixel chuẩn từ `Pot17Scene.sks` (khớp chính xác 100% với `Pot17.svg`)
/// - Hiệu ứng đu đưa vật lý (Pendulum Swing & Squash) khi chạm
public final class Pot17Node: SKNode, PotInteractiveNode {

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
    private var potBody2Node: SKSpriteNode?
    private var frontRopeNode: SKSpriteNode?

    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Danh sách hiệu ứng khi tap vào chậu
    public var tapEffects: [PotTapEffect] = [StoneDustEffect()]

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
        let scaleY = (containerSize.height * 0.98) / 883.0
        return CGPoint(x: 0, y: -475.0 * scaleY)
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
        potBody2Node = nil
        frontRopeNode = nil
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 357 x 883 (aspect ~ 2.473)
        let baseCanvasW: CGFloat = 357.0
        let baseCanvasH: CGFloat = 883.0
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        let scaleX = targetW / baseCanvasW
        let scaleY = targetH / baseCanvasH

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Pot17Scene.sks
        if let scene = loadSceneTemplate() {
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

            // Nạp Thân chậu đất potBody (z = 50)
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

            // Nạp Họa tiết đan chậu potBody2 (z = 49)
            if let potBody2 = scene.childNode(withName: "potBody2") as? SKSpriteNode {
                potBody2.removeFromParent()
                potBody2.isHidden = false
                potBody2.isPaused = false
                potBody2.size = CGSize(width: potBody2.size.width * scaleX, height: potBody2.size.height * scaleY)
                potBody2.position = CGPoint(x: potBody2.position.x * scaleX, y: potBody2.position.y * scaleY)
                potBody2.zPosition = 49
                hangingRigNode.addChild(potBody2)
                self.potBody2Node = potBody2
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

            return
        }

        // 2. FALLBACK PROCEDURAL (Nếu chưa nạp được scene)
        buildProceduralLayers(scaleX: scaleX, scaleY: scaleY)
    }

    private func buildProceduralLayers(scaleX: CGFloat, scaleY: CGFloat) {
        // 1. Dây treo sau
        if let backTex = loadTexture(name: "pot17-2@4.167x") {
            let backRope = SKSpriteNode(texture: backTex)
            backRope.name = "backRope"
            backRope.size = CGSize(width: 356.0 * scaleX, height: 554.0 * scaleY)
            backRope.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            backRope.position = CGPoint(x: 0, y: -277.0 * scaleY)
            backRope.zPosition = 5
            hangingRigNode.addChild(backRope)
            self.backRopeNode = backRope
        }

        // 2. Socket cắm cây
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: -475.0 * scaleY)
        mount.zPosition = 10
        hangingRigNode.addChild(mount)
        self.plantMountNode = mount

        // 3. Thân chậu đất
        if let bodyTex = loadTexture(name: "pot17-3@4.167x") {
            let potBody = SKSpriteNode(texture: bodyTex)
            potBody.name = "potBody"
            potBody.size = CGSize(width: 355.0 * scaleX, height: 410.0 * scaleY)
            potBody.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            potBody.position = CGPoint(x: 0, y: -678.0 * scaleY)
            potBody.zPosition = 50
            hangingRigNode.addChild(potBody)
            self.potBodyNode = potBody
        }

        // 3b. Họa tiết đan chậu potBody2
        if let body2Tex = loadTexture(name: "pot17-5@4.167x") {
            let potBody2 = SKSpriteNode(texture: body2Tex)
            potBody2.name = "potBody2"
            potBody2.size = CGSize(width: 349.0 * scaleX, height: 408.0 * scaleY)
            potBody2.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            potBody2.position = CGPoint(x: 0, y: -678.0 * scaleY)
            potBody2.zPosition = 51
            hangingRigNode.addChild(potBody2)
            self.potBody2Node = potBody2
        }

        // 4. Dây treo trước
        if let frontTex = loadTexture(name: "pot17-4@4.167x") {
            let frontRope = SKSpriteNode(texture: frontTex)
            frontRope.name = "frontRope"
            frontRope.size = CGSize(width: 212.0 * scaleX, height: 462.0 * scaleY)
            frontRope.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            frontRope.position = CGPoint(x: 13.0 * scaleX, y: -250.0 * scaleY)
            frontRope.zPosition = 100
            hangingRigNode.addChild(frontRope)
            self.frontRopeNode = frontRope
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Pot17Scene")
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

        // Kích hoạt các hiệu ứng hạt tap (StoneDustEffect z = 150)
        if let body = potBodyNode {
            for effect in tapEffects {
                effect.trigger(on: body, in: potRootNode, isHanging: isHanging)
            }
        }
    }
}

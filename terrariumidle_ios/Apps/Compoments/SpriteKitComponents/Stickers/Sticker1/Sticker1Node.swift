//
//  Sticker1Node.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Sticker 1: "Sunshine doll" (Búp bê cầu nắng - sticker1)
/// - **Mô hình Ghép Đa Thành Phần (Multi-Component Assembled Structure - `hanging,front`)**:
///   * `ropeNode` (`sticker1-2@4.167x`): Dây treo trên đỉnh, zPos = 5
///   * `dollNode` (`sticker1-3@4.167x`): Thân búp bê cầu nắng đầu tròn áo bồng bềnh, zPos = 10
///   * `ribbonLeftNode` (`sticker1-4@4.167x`): Dải nơ ruy băng ngực bên trái, zPos = 20 (front)
///   * `ribbonRightNode` (`sticker1-5@4.167x`): Dải nơ ruy băng ngực bên phải, zPos = 20 (front)
/// - **Tự động đung đưa theo gió (Idle Wind Sway)**: Khi treo trên kệ, búp bê và các dải nơ
///   liên tục đu đưa nhẹ nhàng theo làn gió tự nhiên.
/// - **Khi chạm (Tap)**:
///   * **Mặt trời tỏa sáng (Sun Radiance)**: Mặt trời vàng tươi cười bung tỏa 12 tia nắng xoay tròn,
///     vầng hào quang ấm áp và các hạt bụi nắng lấp lánh rực rỡ.
///   * **Đu đưa mạnh mẽ**: Dao động con lắc biên độ lớn rồi dịu dần về nhịp gió tự nhiên.
public final class Sticker1Node: SKNode, StickerInteractiveNode {

    // MARK: - Properties

    /// Tỉ lệ kích thước hiển thị so với ô kệ (0.3 ... 1.0, mặc định lấy từ Sticker1View.defaultFitRatio)
    public static var defaultFitRatio: CGFloat { Sticker1View.defaultFitRatio }
    public var fitRatio: CGFloat = Sticker1View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = true

    /// Gốc rễ của sticker
    private let stickerRootNode = SKNode()
    /// Rig đu đưa con lắc (xoay quanh điểm móc treo (0, 0))
    private let hangingRigNode = SKNode()

    /// Các layer thành phần ghép lại của búp bê
    private var ropeNode: SKSpriteNode?
    private var dollNode: SKSpriteNode?
    private var ribbonLeftNode: SKSpriteNode?
    private var ribbonRightNode: SKSpriteNode?

    /// Hiệu ứng chuyển động đung đưa theo gió
    public var motionEffect: StickerMotionEffect = WindSwayStickerMotionEffect()

    /// Danh sách hiệu ứng thị giác dạng hạt / ánh sáng khi chạm
    public var tapEffects: [StickerTapEffect] = [SunRadianceEffect(), SparkleBurstStickerEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 180), isHanging: Bool = true) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(stickerRootNode)
        stickerRootNode.addChild(hangingRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(stickerRootNode)
        stickerRootNode.addChild(hangingRigNode)
    }

    // MARK: - StickerInteractiveNode Protocol

    public var asNode: SKNode { self }

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = true) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    // MARK: - Build Scene

    public func build() {
        hangingRigNode.removeAllChildren()
        hangingRigNode.removeAllActions()
        hangingRigNode.zRotation = 0
        hangingRigNode.yScale = 1.0
        hangingRigNode.xScale = 1.0

        ropeNode = nil
        dollNode = nil
        ribbonLeftNode = nil
        ribbonRightNode = nil

        self.isPaused = false
        self.speed = 1.0
        stickerRootNode.isPaused = false
        stickerRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 122 x 375 (aspect ~ 3.07)
        let baseCanvasW: CGFloat = 122.0
        let baseCanvasH: CGFloat = 375.0
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let activeRatio = fitRatio
        let targetH = containerSize.height * activeRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.85)

        // Tính tỷ lệ đồng nhất (uniform scale) giữ nguyên hình dạng nguyên bản, không méo tỷ lệ
        let uniformScale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        let scaleX = uniformScale
        let scaleY = uniformScale

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Sticker1Scene.sks
        if let scene = loadSceneTemplate() {
            // Nạp Dây treo ropeNode (z = 5)
            if let rope = scene.childNode(withName: "ropeNode") as? SKSpriteNode {
                rope.removeFromParent()
                rope.isHidden = false
                rope.isPaused = false
                rope.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                rope.size = CGSize(width: 7.68 * scaleX, height: 107.27 * scaleY)
                rope.position = CGPoint(x: 0, y: 0)
                rope.zPosition = 5
                if rope.texture == nil {
                    rope.texture = loadTexture(named: "sticker1-2@4.167x")
                }
                hangingRigNode.addChild(rope)
                self.ropeNode = rope
            }

            // Nạp Thân búp bê dollNode (z = 10)
            if let doll = scene.childNode(withName: "dollNode") as? SKSpriteNode {
                doll.removeFromParent()
                doll.isHidden = false
                doll.isPaused = false
                doll.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                doll.size = CGSize(width: 121.91 * scaleX, height: 278.14 * scaleY)
                doll.position = CGPoint(x: 0, y: -96.5 * scaleY)
                doll.zPosition = 10
                if doll.texture == nil {
                    doll.texture = loadTexture(named: "sticker1-3@4.167x")
                }
                hangingRigNode.addChild(doll)
                self.dollNode = doll
            }

            // Nạp Ruy băng trái ribbonLeftNode (z = 20)
            if let ribbonLeft = scene.childNode(withName: "ribbonLeftNode") as? SKSpriteNode {
                ribbonLeft.removeFromParent()
                ribbonLeft.isHidden = false
                ribbonLeft.isPaused = false
                ribbonLeft.anchorPoint = CGPoint(x: 1.0, y: 1.0) // Neo cuống tại nút thắt nơ
                ribbonLeft.size = CGSize(width: 38.16 * scaleX, height: 62.87 * scaleY)
                ribbonLeft.position = CGPoint(x: -10.08 * scaleX, y: -174.7 * scaleY)
                ribbonLeft.zPosition = 20
                if ribbonLeft.texture == nil {
                    ribbonLeft.texture = loadTexture(named: "sticker1-4@4.167x")
                }
                hangingRigNode.addChild(ribbonLeft)
                self.ribbonLeftNode = ribbonLeft
            }

            // Nạp Ruy băng phải ribbonRightNode (z = 20)
            if let ribbonRight = scene.childNode(withName: "ribbonRightNode") as? SKSpriteNode {
                ribbonRight.removeFromParent()
                ribbonRight.isHidden = false
                ribbonRight.isPaused = false
                ribbonRight.anchorPoint = CGPoint(x: 0.0, y: 1.0) // Neo cuống tại nút thắt nơ
                ribbonRight.size = CGSize(width: 34.80 * scaleX, height: 60.71 * scaleY)
                ribbonRight.position = CGPoint(x: -9.12 * scaleX, y: -174.7 * scaleY)
                ribbonRight.zPosition = 20
                if ribbonRight.texture == nil {
                    ribbonRight.texture = loadTexture(named: "sticker1-5@4.167x")
                }
                hangingRigNode.addChild(ribbonRight)
                self.ribbonRightNode = ribbonRight
            }

            startIdleAnimation()
            return
        }

        // 2. FALLBACK PROCEDURAL (Nếu chưa nạp được file scene template)
        buildProceduralLayers(scaleX: scaleX, scaleY: scaleY)
        startIdleAnimation()
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Sticker1Scene")
    }

    // MARK: - Procedural Fallback

    private func buildProceduralLayers(scaleX: CGFloat, scaleY: CGFloat) {
        // Dây treo trên đỉnh
        let rope = SKSpriteNode(texture: loadTexture(named: "sticker1-2@4.167x"))
        rope.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        rope.size = CGSize(width: 7.68 * scaleX, height: 107.27 * scaleY)
        rope.position = CGPoint(x: 0, y: 0)
        rope.zPosition = 5
        hangingRigNode.addChild(rope)
        self.ropeNode = rope

        // Thân búp bê cầu nắng
        let doll = SKSpriteNode(texture: loadTexture(named: "sticker1-3@4.167x"))
        doll.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        doll.size = CGSize(width: 121.91 * scaleX, height: 278.14 * scaleY)
        doll.position = CGPoint(x: 0, y: -96.5 * scaleY)
        doll.zPosition = 10
        hangingRigNode.addChild(doll)
        self.dollNode = doll

        // Dải nơ ruy băng trái
        let ribbonLeft = SKSpriteNode(texture: loadTexture(named: "sticker1-4@4.167x"))
        ribbonLeft.anchorPoint = CGPoint(x: 1.0, y: 1.0)
        ribbonLeft.size = CGSize(width: 38.16 * scaleX, height: 62.87 * scaleY)
        ribbonLeft.position = CGPoint(x: -10.08 * scaleX, y: -174.7 * scaleY)
        ribbonLeft.zPosition = 20
        hangingRigNode.addChild(ribbonLeft)
        self.ribbonLeftNode = ribbonLeft

        // Dải nơ ruy băng phải
        let ribbonRight = SKSpriteNode(texture: loadTexture(named: "sticker1-5@4.167x"))
        ribbonRight.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        ribbonRight.size = CGSize(width: 34.80 * scaleX, height: 60.71 * scaleY)
        ribbonRight.position = CGPoint(x: -9.12 * scaleX, y: -174.7 * scaleY)
        ribbonRight.zPosition = 20
        hangingRigNode.addChild(ribbonRight)
        self.ribbonRightNode = ribbonRight
    }

    private func loadTexture(named name: String) -> SKTexture {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return SKTexture(imageNamed: name)
    }

    // MARK: - Motion Context Helper

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> StickerMotionContext {
        var decors: [SKNode] = []
        if let rl = ribbonLeftNode { decors.append(rl) }
        if let rr = ribbonRightNode { decors.append(rr) }

        return StickerMotionContext(
            targetNode: hangingRigNode,
            ropeNode: ropeNode,
            bodyNode: dollNode,
            frontDecorations: decors,
            initialPosition: .zero,
            isHanging: isHanging,
            containerSize: containerSize,
            onComplete: onComplete
        )
    }

    // MARK: - Idle Animation

    public func startIdleAnimation() {
        let ctx = makeMotionContext()
        motionEffect.startIdle(context: ctx)
    }

    public func stopIdleAnimation() {
        let ctx = makeMotionContext()
        motionEffect.stopIdle(context: ctx)
    }

    // MARK: - Interactive Tap

    public func playTapAnimation() {
        // 1. Kích hoạt hiệu ứng chuyển động vật lý (amplified wind sway)
        let ctx = makeMotionContext()
        motionEffect.apply(context: ctx)

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng thị giác (Mặt trời tỏa sáng & sao lấp lánh)
        let targetForTap = dollNode ?? hangingRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

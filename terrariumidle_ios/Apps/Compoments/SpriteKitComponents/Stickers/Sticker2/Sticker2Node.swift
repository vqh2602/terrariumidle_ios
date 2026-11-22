//
//  Sticker2Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Sticker 2: "Mèo thần tài" (Maneki-neko - sticker2)
/// - **Mô hình Chú Mèo Nguyên Khối Tự Nhiên (`none` - Để bàn / đặt kệ)**:
///   * `catNode` (`sticker2@4.167x`): Thân chú mèo thần tài nguyên bản ngồi trên đệm tròn, zPos = 10
///     Neo tại đáy giữa `anchorPoint = (0.5, 0.0)`.
/// - **Tự động đung đưa nhịp nhàng (Idle Bobble & Sway)**:
///   * Toàn thân chú mèo lắc lư đung đưa êm dịu qua lại quanh đế đệm (`±0.042 rad`),
///     kết hợp nhịp thở nhẹ nhàng sống động.
/// - **Khi chạm (Tap)**:
///   * **Mưa đồng xu vàng may mắn (Lucky Koban Gold Coins Burst)**: 14 đồng xu vàng Koban óng ả
///     xoay lật 3D bung tỏa cùng sao kim lung linh và vầng hào quang tài lộc rực rỡ.
///   * **Nhún nảy đàn hồi & đung đưa vui sướng**: Chú mèo nhún nảy Squash & Stretch đàn hồi
///     và lắc lư vui vẻ rồi êm dịu trở về trạng thái đung đưa ban đầu.
public final class Sticker2Node: SKNode, StickerInteractiveNode {

    // MARK: - Properties

    /// Tỉ lệ kích thước hiển thị so với ô kệ (0.3 ... 1.0, mặc định lấy từ Sticker2View.defaultFitRatio)
    public static var defaultFitRatio: CGFloat { Sticker2View.defaultFitRatio }
    public var fitRatio: CGFloat = Sticker2View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = false

    /// Gốc rễ của sticker
    private let stickerRootNode = SKNode()
    /// Rig chứa thân mèo
    private let catRigNode = SKNode()

    /// Node hiển thị chú mèo nguyên khối
    private var catNode: SKSpriteNode?

    /// Hiệu ứng chuyển động chú mèo đung đưa & nảy lò xo
    public var motionEffect: StickerMotionEffect = LuckyCatMotionEffect()

    /// Danh sách hiệu ứng thị giác khi chạm (Mưa tiền vàng Koban + Hào quang tài lộc + Sao kim)
    public var tapEffects: [StickerTapEffect] = [LuckyCoinsBurstEffect(), GoldenAuraEffect(), SparkleBurstStickerEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 140, height: 160), isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(stickerRootNode)
        stickerRootNode.addChild(catRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(stickerRootNode)
        stickerRootNode.addChild(catRigNode)
    }

    // MARK: - StickerInteractiveNode Protocol

    public var asNode: SKNode { self }

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    // MARK: - Build Scene

    public func build() {
        catRigNode.removeAllChildren()
        catRigNode.removeAllActions()
        catRigNode.zRotation = 0
        catRigNode.yScale = 1.0
        catRigNode.xScale = 1.0

        catNode = nil

        self.isPaused = false
        self.speed = 1.0
        stickerRootNode.isPaused = false
        stickerRootNode.speed = 1.0
        catRigNode.isPaused = false
        catRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 295.66 x 265.90 (aspect ~ 0.90)
        let baseCanvasW: CGFloat = 295.66
        let baseCanvasH: CGFloat = 265.90
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let activeRatio = fitRatio
        let targetH = containerSize.height * activeRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.88)

        let uniformScale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        let scaleX = uniformScale
        let scaleY = uniformScale

        // Đặt tâm mèo trên kệ: neo ở đáy (0, 0)
        catRigNode.position = .zero

        let finalW = baseCanvasW * scaleX
        let finalH = baseCanvasH * scaleY

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Sticker2Scene.sks
        if let scene = loadSceneTemplate() {
            if let node = (scene.childNode(withName: "catNode") ?? scene.childNode(withName: "catBodyNode")) as? SKSpriteNode {
                node.removeFromParent()
                node.isHidden = false
                node.isPaused = false
                node.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Neo ở đáy đệm ngồi
                node.size = CGSize(width: finalW, height: finalH)
                node.position = CGPoint(x: 0, y: isHanging ? -finalH : 0)
                node.zPosition = 10
                if node.texture == nil {
                    node.texture = loadTexture(named: "sticker2@4.167x")
                }
                catRigNode.addChild(node)
                self.catNode = node
                startIdleAnimation()
                return
            }
        }

        // 2. FALLBACK PROCEDURAL
        buildProceduralLayers(finalW: finalW, finalH: finalH)
        startIdleAnimation()
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Sticker2Scene")
    }

    // MARK: - Procedural Fallback

    private func buildProceduralLayers(finalW: CGFloat, finalH: CGFloat) {
        let cat = SKSpriteNode(texture: loadTexture(named: "sticker2@4.167x"))
        cat.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        cat.size = CGSize(width: finalW, height: finalH)
        cat.position = CGPoint(x: 0, y: isHanging ? -finalH : 0)
        cat.zPosition = 10
        catRigNode.addChild(cat)
        self.catNode = cat
    }

    private func loadTexture(named name: String) -> SKTexture {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return SKTexture(imageNamed: name)
    }

    // MARK: - Motion Context Helper

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> StickerMotionContext {
        return StickerMotionContext(
            targetNode: catRigNode,
            ropeNode: nil,
            bodyNode: catNode,
            frontDecorations: [],
            initialPosition: catRigNode.position,
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
        // 1. Kích hoạt hiệu ứng chuyển động chú mèo đung đưa & nhún nảy
        let ctx = makeMotionContext()
        motionEffect.apply(context: ctx)

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng thị giác (Mưa tiền vàng Koban + Hào quang)
        let targetForTap = catNode ?? catRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

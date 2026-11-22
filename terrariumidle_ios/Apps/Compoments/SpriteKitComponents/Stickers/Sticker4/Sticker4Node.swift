//
//  Sticker4Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Sticker 4: "Đèn thắp sáng" (Candle Lantern - sticker4)
/// - **Mô hình Khung Đèn Lồng Kính & Ngọn Nến Bập Bùng (`none` / để bàn hoặc treo)**:
///   * `lanternNode` (`sticker4@4.167x`): Thân đèn lồng kim loại cổ điển với buồng kính, zPos = 10
///   * `flameNode` (Ngọn nến bên trong): Đốm sáng ngọn lửa ấm áp bập bùng liên tục trong lồng kính, zPos = 25
/// - **Tự động đung đưa theo gió & nến bập bùng (Idle Candle Sway)**:
///   * Đèn lồng đung đưa con lắc êm dịu, đầm chắc (`±0.024 rad`).
///   * Ngọn nến bên trong nhấp nháy bập bùng ánh lửa cam vàng ấm cúng sống động.
/// - **Khi chạm (Tap)**:
///   * **Bùng sáng ánh lửa nến ấm áp (Candle Flame Burst)**: Vầng hào quang ánh nến cam vàng bung tỏa
///     rực rỡ xuyên qua lồng kính, tim đèn bừng sáng chói lọi và các hạt tàn lửa ấm áp bay bổng lên cao.
///   * **Đu đưa con lắc phản hồi lực chạm**: Đèn lồng đu đưa nhịp nhàng rồi dịu dần về nhịp êm ả.
public final class Sticker4Node: SKNode, StickerInteractiveNode {

    // MARK: - Properties

    /// Tỉ lệ kích thước hiển thị so với ô kệ (0.3 ... 1.0, mặc định lấy từ Sticker4View.defaultFitRatio)
    public static var defaultFitRatio: CGFloat { Sticker4View.defaultFitRatio }
    public var fitRatio: CGFloat = Sticker4View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = false

    /// Gốc rễ của sticker
    private let stickerRootNode = SKNode()
    /// Rig đu đưa quanh gốc neo
    private let hangingRigNode = SKNode()

    /// Các layer thành phần
    private var lanternNode: SKSpriteNode?
    private var flameNode: SKShapeNode?

    /// Hiệu ứng chuyển động đung đưa & nến bập bùng
    public var motionEffect: StickerMotionEffect = CandleLanternMotionEffect()

    /// Danh sách hiệu ứng thị giác khi chạm (Bùng sáng vầng hào quang ấm áp & tàn lửa nến bay bổng)
    public var tapEffects: [StickerTapEffect] = [CandleFlameBurstEffect(), SparkleBurstStickerEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 125, height: 185), isHanging: Bool = false) {
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

    public func configure(containerSize: CGSize, isHanging: Bool = false) {
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

        lanternNode = nil
        flameNode = nil

        self.isPaused = false
        self.speed = 1.0
        stickerRootNode.isPaused = false
        stickerRootNode.speed = 1.0
        hangingRigNode.isPaused = false
        hangingRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 215.74 x 433.17 (aspect ~ 2.01)
        let baseCanvasW: CGFloat = 215.74
        let baseCanvasH: CGFloat = 433.17
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let activeRatio = fitRatio
        let targetH = containerSize.height * activeRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.88)

        let uniformScale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        let scaleX = uniformScale
        let scaleY = uniformScale

        let finalW = baseCanvasW * scaleX
        let finalH = baseCanvasH * scaleY

        // Điểm neo của rig: nếu treo thì ở đỉnh (0, 0), nếu để bàn thì neo tại đáy (0, 0)
        hangingRigNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp các node từ file trực quan Sticker4Scene.sks
        if let scene = loadSceneTemplate() {
            // Nạp Thân đèn lồng lanternNode (z = 10) chạm sàn kệ y = 0
            if let lantern = scene.childNode(withName: "lanternNode") as? SKSpriteNode {
                lantern.removeFromParent()
                lantern.isHidden = false
                lantern.isPaused = false
                lantern.anchorPoint = CGPoint(x: 0.5, y: isHanging ? 1.0 : 0.0) // Chân đèn đứng sát sàn kệ
                lantern.size = CGSize(width: finalW, height: finalH)
                lantern.position = .zero
                lantern.zPosition = 10
                if lantern.texture == nil {
                    lantern.texture = loadTexture(named: "sticker4@4.167x")
                }
                hangingRigNode.addChild(lantern)
                self.lanternNode = lantern
            }

            // Tạo ngọn nến bập bùng ở tâm buồng kính đèn
            attachCandleFlame(finalH: finalH)
            startIdleAnimation()
            return
        }

        // 2. FALLBACK PROCEDURAL (Nếu chưa nạp được file scene template)
        buildProceduralLayers(finalW: finalW, finalH: finalH)
        attachCandleFlame(finalH: finalH)
        startIdleAnimation()
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Sticker4Scene")
    }

    // MARK: - Procedural Fallback

    private func buildProceduralLayers(finalW: CGFloat, finalH: CGFloat) {
        let lantern = SKSpriteNode(texture: loadTexture(named: "sticker4@4.167x"))
        lantern.anchorPoint = CGPoint(x: 0.5, y: isHanging ? 1.0 : 0.0)
        lantern.size = CGSize(width: finalW, height: finalH)
        lantern.position = .zero
        lantern.zPosition = 10
        hangingRigNode.addChild(lantern)
        self.lanternNode = lantern
    }

    /// Gắn ngọn nến bập bùng phát sáng ấm áp bên trong buồng kính lồng đèn
    private func attachCandleFlame(finalH: CGFloat) {
        let flameY = isHanging ? (-finalH * 0.36) : (finalH * 0.64)
        let flame = SKShapeNode(circleOfRadius: 3.5)
        flame.position = CGPoint(x: 0, y: flameY)
        flame.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.95)
        flame.strokeColor = UIColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 0.80)
        flame.lineWidth = 1.0
        flame.zPosition = 25

        // Hào quang ấm dịu nhẹ xung quanh ngọn nến
        let glow = SKShapeNode(circleOfRadius: 8.0)
        glow.fillColor = UIColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 0.35)
        glow.strokeColor = .clear
        flame.addChild(glow)

        hangingRigNode.addChild(flame)
        self.flameNode = flame
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
        if let flame = flameNode { decors.append(flame) }

        return StickerMotionContext(
            targetNode: hangingRigNode,
            ropeNode: nil,
            bodyNode: lanternNode,
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
        // 1. Kích hoạt chuyển động đu đưa con lắc phản hồi lực chạm
        let ctx = makeMotionContext()
        motionEffect.apply(context: ctx)

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng thị giác (Bùng sáng vầng hào quang ấm áp & tàn lửa)
        let targetForTap = lanternNode ?? hangingRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

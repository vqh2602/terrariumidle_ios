//
//  Sticker3Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Sticker 3: "Đèn cá chép" (Koi Windsock Lantern - sticker3)
/// - **Mô hình Đế Cố Định & Vùng Cá Đung Đưa Riêng Biệt (`front`)**:
///   * `staticBaseNode`: Chứa thanh đế cọc ngang (`barNode` - `sticker3-4@4.167x`, zPos = 5)
///     và cọc dây đỡ (`ropeNode` - `sticker3-3@4.167x`, zPos = 8) -> **GIỮ NGUYÊN ĐẾ CỐ ĐỊNH, ĐỨNG YÊN KHÔNG LẮC**.
///   * `fishRigNode`: Rig độc lập chứa 3 chú cá đèn lồng (`fishNode` - `sticker3-2@4.167x`, zPos = 15)
///     treo từ điểm móc uốn của cọc tại `(-20.64, -20.64)` -> **CHỈ CÓ VÙNG CÁ ĐUNG ĐƯA THEO GIÓ**.
/// - **Tự động đung đưa theo gió lúc mạnh lúc nhẹ (Dynamic Wind Sway)**:
///   * Chu kỳ gió đa tầng tự nhiên: lúc gió nhẹ thoảng qua êm đềm (`±0.038 rad`),
///     lúc có cơn gió mạnh tạt qua đu đưa dồn dập (`±0.095 rad`), kết hợp thân cá uốn lượn phấp phới như vải lụa.
/// - **Khi chạm (Tap)**:
///   * **Đế giữ nguyên bất động**, chỉ vùng cá vung lắc con lắc đàn hồi mạnh mẽ (`±0.16 rad`) rồi dịu dần.
///   * **Lấp lánh tam sắc Xanh dương - Đỏ - Vàng (Koi Tricolor Sparkle)**: Ba chùm sao lấp lánh bung tỏa
///     chuẩn xác từ vị trí 3 chú cá tương ứng (sao đỏ ruby, sao vàng hổ phách, sao xanh cyan đại dương).
public final class Sticker3Node: SKNode, StickerInteractiveNode {

    // MARK: - Properties

    /// Tỉ lệ kích thước hiển thị so với ô kệ (0.3 ... 1.0, mặc định lấy từ Sticker3View.defaultFitRatio)
    public static var defaultFitRatio: CGFloat { Sticker3View.defaultFitRatio }
    public var fitRatio: CGFloat = Sticker3View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = false

    /// Gốc rễ của sticker
    private let stickerRootNode = SKNode()
    /// Rig cố định: chứa thanh đế và cọc dây đỡ (ĐỨNG YÊN HOÀN TOÀN, KHÔNG LẮC)
    private let staticBaseNode = SKNode()
    /// Rig chuyển động: CHỈ CHỨA VÙNG 3 CHÚ CÁ (ĐUNG ĐƯA THEO GIÓ QUANH MÓC TREO)
    private let fishRigNode = SKNode()

    /// Các layer thành phần
    private var barNode: SKSpriteNode?
    private var ropeNode: SKSpriteNode?
    private var fishNode: SKSpriteNode?

    /// Hiệu ứng chuyển động gió lúc mạnh lúc nhẹ (chỉ áp dụng lên vùng cá)
    public var motionEffect: StickerMotionEffect = KoiWindSwayStickerMotionEffect()

    /// Danh sách hiệu ứng thị giác khi chạm (Lấp lánh tam sắc Xanh dương - Đỏ - Vàng theo màu cá)
    public var tapEffects: [StickerTapEffect] = [KoiTricolorSparkleEffect()]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 130, height: 185), isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(stickerRootNode)
        stickerRootNode.addChild(staticBaseNode)
        stickerRootNode.addChild(fishRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(stickerRootNode)
        stickerRootNode.addChild(staticBaseNode)
        stickerRootNode.addChild(fishRigNode)
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
        staticBaseNode.removeAllChildren()
        staticBaseNode.removeAllActions()
        staticBaseNode.zRotation = 0

        fishRigNode.removeAllChildren()
        fishRigNode.removeAllActions()
        fishRigNode.zRotation = 0
        fishRigNode.yScale = 1.0
        fishRigNode.xScale = 1.0

        barNode = nil
        ropeNode = nil
        fishNode = nil

        self.isPaused = false
        self.speed = 1.0
        stickerRootNode.isPaused = false
        stickerRootNode.speed = 1.0
        staticBaseNode.isPaused = false
        staticBaseNode.speed = 1.0
        fishRigNode.isPaused = false
        fishRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế gốc: 274.53 x 410.13 (aspect ~ 1.49)
        let baseCanvasW: CGFloat = 274.53
        let baseCanvasH: CGFloat = 410.13
        let aspect: CGFloat = baseCanvasH / baseCanvasW

        let activeRatio = fitRatio
        let targetH = containerSize.height * activeRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.88)

        let uniformScale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        let scaleX = uniformScale
        let scaleY = uniformScale

        // Gốc neo:
        // - Nếu để bàn (isHanging = false): đứng vững trên sàn kệ tại y = 0
        // - Nếu treo (isHanging = true): buông từ trần kệ (y = 0) xuống dưới bằng offset âm
        let totalH = baseCanvasH * scaleY
        let offsetY: CGFloat = isHanging ? (-totalH) : 0
        staticBaseNode.position = CGPoint(x: 0, y: offsetY)

        // Điểm móc treo đàn cá tại góc uốn đỉnh của cọc
        let fishHangingPoint = CGPoint(x: -20.64 * scaleX, y: (388.53 * scaleY) + offsetY)
        fishRigNode.position = fishHangingPoint

        // 1. NẠP HOẶC KHỞI TẠO CÁC LAYER
        if let scene = loadSceneTemplate() {
            // A. Nạp Thanh cọc ngang barNode (ĐẾ CỐ ĐỊNH CHẠM ĐÁY y = 0, z = 5) -> add vào staticBaseNode
            if let bar = scene.childNode(withName: "barNode") as? SKSpriteNode {
                bar.removeFromParent()
                bar.isHidden = false
                bar.isPaused = false
                bar.anchorPoint = CGPoint(x: 0.5, y: 0.0) // Neo tại mép đáy
                bar.size = CGSize(width: 249.82 * scaleX, height: 32.64 * scaleY)
                bar.position = CGPoint(x: -12.36 * scaleX, y: 0.0) // CHẠM CHÍNH XÁC MẶT SÀN KỆ (y = 0)
                bar.zPosition = 5
                if bar.texture == nil {
                    bar.texture = loadTexture(named: "sticker3-4@4.167x")
                }
                staticBaseNode.addChild(bar)
                self.barNode = bar
            }

            // B. Nạp Cọc dây đỡ ropeNode (CỌC CỐ ĐỊNH, z = 8) -> add vào staticBaseNode
            if let rope = scene.childNode(withName: "ropeNode") as? SKSpriteNode {
                rope.removeFromParent()
                rope.isHidden = false
                rope.isPaused = false
                rope.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                rope.size = CGSize(width: 200.86 * scaleX, height: 385.41 * scaleY)
                rope.position = CGPoint(x: 35.88 * scaleX, y: 216.46 * scaleY)
                rope.zPosition = 8
                if rope.texture == nil {
                    rope.texture = loadTexture(named: "sticker3-3@4.167x")
                }
                staticBaseNode.addChild(rope)
                self.ropeNode = rope
            }

            // C. Nạp 3 chú cá fishNode (CHỈ VÙNG CÁ LẮC LƯ, z = 15) -> add vào fishRigNode
            if let fish = scene.childNode(withName: "fishNode") as? SKSpriteNode {
                fish.removeFromParent()
                fish.isHidden = false
                fish.isPaused = false
                // Neo tại đỉnh đầu con cá trên cùng để lắc tự nhiên quanh móc treo
                fish.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                fish.size = CGSize(width: 128.15 * scaleX, height: 343.41 * scaleY)
                fish.position = .zero // Tâm gốc neo nằm ngay tại fishRigNode
                fish.zPosition = 15
                if fish.texture == nil {
                    fish.texture = loadTexture(named: "sticker3-2@4.167x")
                }
                fishRigNode.addChild(fish)
                self.fishNode = fish
            }

            startIdleAnimation()
            return
        }

        // 2. FALLBACK PROCEDURAL
        buildProceduralLayers(scaleX: scaleX, scaleY: scaleY)
        startIdleAnimation()
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Sticker3Scene")
    }

    // MARK: - Procedural Fallback

    private func buildProceduralLayers(scaleX: CGFloat, scaleY: CGFloat) {
        // Thanh xà cọc ngang (Đế cố định chạm sát sàn kệ y = 0)
        let bar = SKSpriteNode(texture: loadTexture(named: "sticker3-4@4.167x"))
        bar.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        bar.size = CGSize(width: 249.82 * scaleX, height: 32.64 * scaleY)
        bar.position = CGPoint(x: -12.36 * scaleX, y: 0.0)
        bar.zPosition = 5
        staticBaseNode.addChild(bar)
        self.barNode = bar

        // Cọc dây đỡ (Cố định)
        let rope = SKSpriteNode(texture: loadTexture(named: "sticker3-3@4.167x"))
        rope.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        rope.size = CGSize(width: 200.86 * scaleX, height: 385.41 * scaleY)
        rope.position = CGPoint(x: 35.88 * scaleX, y: 216.46 * scaleY)
        rope.zPosition = 8
        staticBaseNode.addChild(rope)
        self.ropeNode = rope

        // 3 chú cá đèn lồng (Đu đưa quanh móc treo fishRigNode)
        let fish = SKSpriteNode(texture: loadTexture(named: "sticker3-2@4.167x"))
        fish.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        fish.size = CGSize(width: 128.15 * scaleX, height: 343.41 * scaleY)
        fish.position = .zero
        fish.zPosition = 15
        fishRigNode.addChild(fish)
        self.fishNode = fish
    }

    private func loadTexture(named name: String) -> SKTexture {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        return SKTexture(imageNamed: name)
    }

    // MARK: - Motion Context Helper

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> StickerMotionContext {
        // CHỈ TRUYỀN fishRigNode LÀM TARGET NHẬN CHUYỂN ĐỘNG, ĐẾ staticBaseNode GIỮ NGUYÊN BẤT ĐỘNG
        return StickerMotionContext(
            targetNode: fishRigNode,
            ropeNode: nil,
            bodyNode: fishNode,
            frontDecorations: [],
            initialPosition: fishRigNode.position,
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
        // 1. Kích hoạt hiệu ứng: ĐẾ GIỮ NGUYÊN, CHỈ VÙNG CÁ LẮC MẠNH THEO GIÓ
        let ctx = makeMotionContext()
        motionEffect.apply(context: ctx)

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng thị giác (Lấp lánh tam sắc Xanh dương - Đỏ - Vàng từ 3 con cá)
        let targetForTap = fishNode ?? fishRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

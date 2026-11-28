//
//  Animal3Node.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit cho Animal 3: Túi lưới bắt sâu (`animal3` / `"Bugsnet"`)
/// - Kiến trúc lai `.sks` + Swift Code (`Animal3Scene.sks`):
///   * `bagNode` (`greenmeshbag-1@4.167x`): Túi lưới treo trên đỉnh kệ (`isHanging = true`), click vào giãn nở túi
///   * `storageSocket`: Vùng chứa bên trong túi hiển thị hình ảnh thực tế của tối đa 5 sâu/châu chấu bắt được
public final class Animal3Node: SKNode, AnimalInteractiveNode {

    // MARK: - Properties

    public static var defaultFitRatio: CGFloat { Animal3View.defaultFitRatio }
    public var fitRatio: CGFloat = Animal3View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = true
    public private(set) var capturedPests: [PestSpecies] = []

    private let animalRootNode = SKNode()
    private let bagRigNode = SKNode()
    private let bagContentsNode = SKNode()

    private var bagNode: SKSpriteNode?
    private var storageSocket: SKNode?
    private var currentScale: CGFloat = 1.0

    public var motionEffect: AnimalMotionEffect = MeshBagExpandMotionEffect()
    public var tapEffects: [AnimalTapEffect] = [MeshBagDustEffect()]

    // MARK: - Initializers

    public init(
        containerSize: CGSize = CGSize(width: 120, height: 220),
        isHanging: Bool = true,
        capturedPests: [PestSpecies] = []
    ) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.capturedPests = Array(capturedPests.prefix(5))
        super.init()

        addChild(animalRootNode)
        animalRootNode.addChild(bagRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(animalRootNode)
        animalRootNode.addChild(bagRigNode)
    }

    public var asNode: SKNode { self }

    public func configure(containerSize: CGSize, isHanging: Bool = true) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    /// Cập nhật hiển thị các con sâu/châu chấu đã bắt được bên trong túi (tối đa 5 con) bằng hình ảnh thật.
    public func updateCapturedPests(_ pests: [PestSpecies]) {
        let clamped = Array(pests.prefix(5))
        guard clamped != self.capturedPests || bagContentsNode.children.count != clamped.count else { return }
        self.capturedPests = clamped
        renderCapturedPestsInsideBag()
    }

    // MARK: - Build

    public func build() {
        animalRootNode.removeAllActions()
        bagRigNode.removeAllChildren()
        bagRigNode.removeAllActions()
        bagRigNode.zRotation = 0
        bagRigNode.xScale = 1.0
        bagRigNode.yScale = 1.0
        bagRigNode.restZRotation = 0.0

        bagNode = nil
        storageSocket = nil
        bagContentsNode.removeAllChildren()

        self.isPaused = false
        self.speed = 1.0
        animalRootNode.isPaused = false
        animalRootNode.speed = 1.0
        bagRigNode.isPaused = false
        bagRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế chuẩn sau tối ưu: 320 x 604 (từ greenmeshbag-1@4.167x)
        let baseCanvasW: CGFloat = 320.0
        let baseCanvasH: CGFloat = 604.0
        let aspect = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * fitRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.86)
        let scale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        self.currentScale = scale

        let topOffsetY: CGFloat = isHanging ? 0.0 : (baseCanvasH * scale)
        bagRigNode.position = CGPoint(x: 0, y: topOffsetY)
        bagRigNode.zPosition = 10

        if let scene = loadSceneTemplate() {
            if let templateBag = scene.childNode(withName: "bagNode") as? SKSpriteNode,
               let bag = templateBag.copy() as? SKSpriteNode {
                bag.isHidden = false
                bag.isPaused = false
                bag.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                bag.size = CGSize(width: baseCanvasW * scale, height: baseCanvasH * scale)
                bag.position = .zero
                bag.zPosition = 10
                if bag.texture == nil {
                    bag.texture = PestTextureCache.shared.texture(named: "greenmeshbag-1@4.167x")
                }
                bagRigNode.addChild(bag)
                self.bagNode = bag
            }

            if let templateSocket = scene.childNode(withName: "storageSocket"),
               let socket = templateSocket.copy() as? SKNode {
                socket.position = CGPoint(x: 0, y: -400.0 * scale)
                socket.zPosition = 15
                bagRigNode.addChild(socket)
                self.storageSocket = socket
            }

            if bagNode == nil {
                buildProceduralMissing(scale: scale, baseCanvasW: baseCanvasW, baseCanvasH: baseCanvasH)
            }
        } else {
            buildProceduralMissing(scale: scale, baseCanvasW: baseCanvasW, baseCanvasH: baseCanvasH)
        }

        // Đặt lớp sâu đã bắt nằm SAU lưới của túi (z = 8 < bagNode 10) để nhìn xuyên qua các ô lưới như đang ở bên trong túi
        bagContentsNode.position = storageSocket?.position ?? CGPoint(x: 0, y: -400.0 * scale)
        bagContentsNode.zPosition = 8
        bagRigNode.addChild(bagContentsNode)
        renderCapturedPestsInsideBag()

        startIdleAnimation()
    }

    private static var cachedTemplateScene: SKScene?
    private static var didAttemptLoadTemplate = false

    private func loadSceneTemplate() -> SKScene? {
        if !Self.didAttemptLoadTemplate {
            Self.didAttemptLoadTemplate = true
            Self.cachedTemplateScene = SKScene(fileNamed: "Animal3Scene")
        }
        return Self.cachedTemplateScene
    }

    private func buildProceduralMissing(scale: CGFloat, baseCanvasW: CGFloat, baseCanvasH: CGFloat) {
        if bagNode == nil {
            let bag = SKSpriteNode(texture: PestTextureCache.shared.texture(named: "greenmeshbag-1@4.167x"))
            bag.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            bag.size = CGSize(width: baseCanvasW * scale, height: baseCanvasH * scale)
            bag.position = .zero
            bag.zPosition = 10
            bagRigNode.addChild(bag)
            self.bagNode = bag
        }
        if storageSocket == nil {
            let socket = SKNode()
            socket.position = CGPoint(x: 0, y: -400.0 * scale)
            socket.zPosition = 15
            bagRigNode.addChild(socket)
            self.storageSocket = socket
        }
    }

    private func renderCapturedPestsInsideBag() {
        bagContentsNode.removeAllChildren()
        guard !capturedPests.isEmpty else { return }

        let bagW = 320.0 * currentScale
        let bagH = 604.0 * currentScale
        // 5 vị trí xếp theo dáng giọt nước (1 trên - 2 giữa - 2 dưới) để luôn nằm gọn trong lưới
        let layoutOffsets: [(dx: CGFloat, dy: CGFloat, rot: CGFloat, flipX: CGFloat)] = [
            ( 0.00,  0.06,  0.05,  1.0),
            (-0.15, -0.03,  0.14,  1.0),
            ( 0.15, -0.03, -0.14, -1.0),
            (-0.14, -0.13, -0.12, -1.0),
            ( 0.14, -0.13,  0.12,  1.0)
        ]

        let bugDisplayW = max(14.0, bagW * 0.22)

        for (index, species) in capturedPests.prefix(5).enumerated() {
            let tex = PestTextureCache.shared.texture(named: species.previewImageName)
            let texSize = tex.size()
            let ratio = texSize.width > 0 ? (texSize.height / texSize.width) : 0.67
            let sprite = SKSpriteNode(texture: tex)
            sprite.size = CGSize(width: bugDisplayW, height: bugDisplayW * ratio)

            let slot = layoutOffsets[index % layoutOffsets.count]
            sprite.position = CGPoint(x: slot.dx * bagW, y: slot.dy * bagH)
            sprite.zRotation = slot.rot
            sprite.xScale = slot.flipX
            sprite.alpha = 0.92
            sprite.zPosition = CGFloat(index)
            sprite.restZRotation = slot.rot
            bagContentsNode.addChild(sprite)

            // Cựa quậy nhẹ nhàng bên trong túi lưới
            let wiggleDur = Double.random(in: 0.7...1.2)
            let r1 = SKAction.rotate(toAngle: slot.rot + 0.10, duration: wiggleDur)
            r1.timingMode = .easeInEaseOut
            let r2 = SKAction.rotate(toAngle: slot.rot - 0.10, duration: wiggleDur)
            r2.timingMode = .easeInEaseOut
            sprite.run(SKAction.repeatForever(SKAction.sequence([r1, r2])), withKey: "bag_bug_wiggle")
        }
    }

    public func spawnAnchorPoint(in targetNode: SKNode) -> CGPoint {
        if let socket = storageSocket, let parent = socket.parent {
            return parent.convert(socket.position, to: targetNode)
        }
        return parent?.convert(position, to: targetNode) ?? position
    }

    /// Độ lệch tâm bụng túi lưới tính từ đỉnh-giữa slot (theo hệ UIKit +Y xuống dưới)
    public static func bagPocketOffsetFromSlotTop(slotSize: CGSize, fitRatio: CGFloat = Animal3View.defaultFitRatio) -> CGPoint {
        let baseCanvasW: CGFloat = 320.0
        let baseCanvasH: CGFloat = 604.0
        let aspect = baseCanvasH / baseCanvasW
        let targetH = slotSize.height * fitRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, slotSize.width * 0.86)
        let scale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        return CGPoint(x: 0.0, y: 400.0 * scale)
    }

    // MARK: - Animation

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> AnimalMotionContext {
        return AnimalMotionContext(
            targetNode: bagRigNode,
            branchNode: nil,
            bodyNode: bagNode,
            initialPosition: bagRigNode.position,
            isHanging: isHanging,
            containerSize: containerSize,
            onComplete: onComplete
        )
    }

    public func startIdleAnimation() {
        motionEffect.startIdle(context: makeMotionContext())
    }

    public func stopIdleAnimation() {
        motionEffect.stopIdle(context: makeMotionContext())
    }

    public func playTapAnimation() {
        motionEffect.apply(context: makeMotionContext())

        // Các chú sâu bên trong túi nảy nhẹ khi túi giãn nở
        for (idx, node) in bagContentsNode.children.enumerated() {
            node.removeAction(forKey: "bag_bug_pop")
            let hop = SKAction.moveBy(x: 0, y: 4.5, duration: 0.10)
            hop.timingMode = .easeOut
            let settle = SKAction.moveBy(x: 0, y: -4.5, duration: 0.16)
            settle.timingMode = .easeInEaseOut
            let delay = Double(idx) * 0.03
            node.run(SKAction.sequence([SKAction.wait(forDuration: delay), hop, settle]), withKey: "bag_bug_pop")
        }

        let targetForTap = bagNode ?? bagRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

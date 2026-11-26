//
//  Animal2Node.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit cho Animal 2: Gốc Cây Gỗ Mục - Nhà Bọ Rùa (`animal2` / `"lazybug"`)
/// - Kiến trúc lai `.sks` + Swift Code (`Animal2Scene.sks`):
///   * `logNode` (`rotten-wooden-base-1@4.167x`): Gốc cây gỗ mục đặt trên kệ (`isHanging = false`)
///   * `restSocket`: Điểm mặt gỗ phẳng trên đỉnh gốc cây nơi bọ rùa nghỉ (`idle`) hoặc ngủ (`sleep`)
public final class Animal2Node: SKNode, AnimalInteractiveNode {

    // MARK: - Properties

    public static var defaultFitRatio: CGFloat { Animal2View.defaultFitRatio }
    public var fitRatio: CGFloat = Animal2View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = false

    private let animalRootNode = SKNode()
    private let logRigNode = SKNode()

    private var logNode: SKSpriteNode?
    private var restSocket: SKNode?

    public var motionEffect: AnimalMotionEffect = StumpBounceMotionEffect()
    public var tapEffects: [AnimalTapEffect] = [WoodBarkFallEffect()]

    // MARK: - Initializers

    public init(containerSize: CGSize = CGSize(width: 120, height: 220), isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(animalRootNode)
        animalRootNode.addChild(logRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(animalRootNode)
        animalRootNode.addChild(logRigNode)
    }

    public var asNode: SKNode { self }

    public func configure(containerSize: CGSize, isHanging: Bool = false) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    // MARK: - Build

    public func build() {
        animalRootNode.removeAllActions()
        logRigNode.removeAllChildren()
        logRigNode.removeAllActions()
        logRigNode.zRotation = 0
        logRigNode.xScale = 1.0
        logRigNode.yScale = 1.0
        logRigNode.restZRotation = 0.0

        logNode = nil
        restSocket = nil

        self.isPaused = false
        self.speed = 1.0
        animalRootNode.isPaused = false
        animalRootNode.speed = 1.0
        logRigNode.isPaused = false
        logRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế chuẩn sau tối ưu: 512 x 184 (từ rotten-wooden-base-1@4.167x)
        let baseCanvasW: CGFloat = 512.0
        let baseCanvasH: CGFloat = 184.0
        let targetW = min(containerSize.width * fitRatio, containerSize.width * 0.96)
        let scale = targetW / baseCanvasW

        logRigNode.position = .zero
        logRigNode.zPosition = 10

        if let scene = loadSceneTemplate() {
            if let templateLog = scene.childNode(withName: "logNode") as? SKSpriteNode,
               let log = templateLog.copy() as? SKSpriteNode {
                log.isHidden = false
                log.isPaused = false
                log.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                log.size = CGSize(width: baseCanvasW * scale, height: baseCanvasH * scale)
                log.position = .zero
                log.zPosition = 10
                if log.texture == nil {
                    log.texture = LazybugTextureCache.shared.texture(named: "rotten-wooden-base-1@4.167x")
                }
                logRigNode.addChild(log)
                self.logNode = log
            }

            if let templateSocket = scene.childNode(withName: "restSocket"),
               let socket = templateSocket.copy() as? SKNode {
                socket.position = CGPoint(x: -12.0 * scale, y: 165.0 * scale)
                socket.zPosition = 15
                logRigNode.addChild(socket)
                self.restSocket = socket
            }

            if logNode == nil {
                buildProceduralMissing(scale: scale, baseCanvasW: baseCanvasW, baseCanvasH: baseCanvasH)
            }
            startIdleAnimation()
            return
        }

        buildProceduralMissing(scale: scale, baseCanvasW: baseCanvasW, baseCanvasH: baseCanvasH)
        startIdleAnimation()
    }

    private static var cachedTemplateScene: SKScene?
    private static var didAttemptLoadTemplate = false

    private func loadSceneTemplate() -> SKScene? {
        if !Self.didAttemptLoadTemplate {
            Self.didAttemptLoadTemplate = true
            Self.cachedTemplateScene = SKScene(fileNamed: "Animal2Scene")
        }
        return Self.cachedTemplateScene
    }

    private func buildProceduralMissing(scale: CGFloat, baseCanvasW: CGFloat, baseCanvasH: CGFloat) {
        if logNode == nil {
            let log = SKSpriteNode(texture: LazybugTextureCache.shared.texture(named: "rotten-wooden-base-1@4.167x"))
            log.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            log.size = CGSize(width: baseCanvasW * scale, height: baseCanvasH * scale)
            log.position = .zero
            log.zPosition = 10
            logRigNode.addChild(log)
            self.logNode = log
        }
        if restSocket == nil {
            let socket = SKNode()
            socket.position = CGPoint(x: -12.0 * scale, y: 165.0 * scale)
            socket.zPosition = 15
            logRigNode.addChild(socket)
            self.restSocket = socket
        }
    }

    public func spawnAnchorPoint(in targetNode: SKNode) -> CGPoint {
        if let socket = restSocket, let parent = socket.parent {
            return parent.convert(socket.position, to: targetNode)
        }
        return parent?.convert(position, to: targetNode) ?? position
    }

    /// Độ lệch điểm nghỉ trên mặt gốc gỗ mục tính từ đáy-giữa slot (+Y hướng lên)
    public static func logRestOffsetFromSlotBottom(slotSize: CGSize, fitRatio: CGFloat = Animal2View.defaultFitRatio) -> CGPoint {
        let baseCanvasW: CGFloat = 512.0
        let targetW = min(slotSize.width * fitRatio, slotSize.width * 0.96)
        let scale = targetW / baseCanvasW
        return CGPoint(x: -12.0 * scale, y: 165.0 * scale)
    }

    // MARK: - Animation

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> AnimalMotionContext {
        return AnimalMotionContext(
            targetNode: logRigNode,
            branchNode: nil,
            bodyNode: logNode,
            initialPosition: logRigNode.position,
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

        let targetForTap = logNode ?? logRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

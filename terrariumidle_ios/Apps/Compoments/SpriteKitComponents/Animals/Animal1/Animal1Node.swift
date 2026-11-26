//
//  Animal1Node.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit cho Animal 1: Tổ Ong Mật (`animal1` / `"bee"`)
/// - Kiến trúc lai `.sks` + Swift Code (`Animal1Scene.sks`):
///   * `branchNode` (`Beehive-2@4.167x`): Cành cây treo cố định trên trần kệ, đung đưa rất nhẹ theo gió
///   * `hiveRigNode` -> `hiveNode` (`Beehive-3@4.167x`): Tổ ong treo lắc lư con lắc quanh cuống
///   * `entranceSocket`: Tâm cửa tổ ong nơi 4 chú ong bay ra và bay về
public final class Animal1Node: SKNode, AnimalInteractiveNode {

    // MARK: - Properties

    public static var defaultFitRatio: CGFloat { Animal1View.defaultFitRatio }
    public var fitRatio: CGFloat = Animal1View.defaultFitRatio

    private var containerSize: CGSize = .zero
    public var isHanging: Bool = true

    private let animalRootNode = SKNode()
    private let hiveRigNode = SKNode()

    private var branchNode: SKSpriteNode?
    private var hiveNode: SKSpriteNode?
    private var entranceSocket: SKNode?

    public var motionEffect: AnimalMotionEffect = BeehivePendulumMotionEffect()
    public var tapEffects: [AnimalTapEffect] = [HoneySplashBurstEffect()]

    // MARK: - Initializers

    public init(containerSize: CGSize = CGSize(width: 120, height: 220), isHanging: Bool = true) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(animalRootNode)
        animalRootNode.addChild(hiveRigNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(animalRootNode)
        animalRootNode.addChild(hiveRigNode)
    }

    public var asNode: SKNode { self }

    public func configure(containerSize: CGSize, isHanging: Bool = true) {
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }

    // MARK: - Build

    public func build() {
        animalRootNode.removeAllActions()
        branchNode?.removeFromParent()
        hiveRigNode.removeAllChildren()
        hiveRigNode.removeAllActions()
        hiveRigNode.zRotation = 0
        hiveRigNode.xScale = 1.0
        hiveRigNode.yScale = 1.0
        hiveRigNode.restZRotation = 0.0

        branchNode = nil
        hiveNode = nil
        entranceSocket = nil

        self.isPaused = false
        self.speed = 1.0
        animalRootNode.isPaused = false
        animalRootNode.speed = 1.0
        hiveRigNode.isPaused = false
        hiveRigNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Kích thước canvas thiết kế chuẩn sau tối ưu: 512 x 478 (từ Beehive-1@4.167x)
        let baseCanvasW: CGFloat = 512.0
        let baseCanvasH: CGFloat = 478.0
        let aspect = baseCanvasH / baseCanvasW

        let targetH = containerSize.height * fitRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, containerSize.width * 0.92)
        let scale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)

        let topOffsetY: CGFloat = isHanging ? 0.0 : (baseCanvasH * scale)

        // Điểm neo cuống tổ ong trên cành cây (theo pixel alignment Beehive-3 trên Beehive-1)
        let pivotX: CGFloat = -72.70 * scale
        let pivotY: CGFloat = -162.59 * scale + topOffsetY
        hiveRigNode.position = CGPoint(x: pivotX, y: pivotY)
        hiveRigNode.zPosition = 10

        if let scene = loadSceneTemplate() {
            if let templateBranch = scene.childNode(withName: "branchNode") as? SKSpriteNode,
               let branch = templateBranch.copy() as? SKSpriteNode {
                branch.isHidden = false
                branch.isPaused = false
                branch.anchorPoint = CGPoint(x: 0.5, y: 1.0)
                branch.size = CGSize(width: 512.0 * scale, height: 305.0 * scale)
                branch.position = CGPoint(x: 0, y: topOffsetY)
                branch.zPosition = 5
                branch.restZRotation = 0.0
                if branch.texture == nil {
                    branch.texture = BeeTextureCache.shared.texture(named: "Beehive-2@4.167x")
                }
                animalRootNode.addChild(branch)
                self.branchNode = branch
            }

            if let templateHive = scene.childNode(withName: "hiveNode") as? SKSpriteNode,
               let hive = templateHive.copy() as? SKSpriteNode {
                hive.isHidden = false
                hive.isPaused = false
                hive.anchorPoint = CGPoint(x: 0.48, y: 1.0)
                hive.size = CGSize(width: 299.0 * scale, height: 315.0 * scale)
                hive.position = .zero
                hive.zPosition = 10
                if hive.texture == nil {
                    hive.texture = BeeTextureCache.shared.texture(named: "Beehive-3@4.167x")
                }
                hiveRigNode.addChild(hive)
                self.hiveNode = hive
            }

            if let templateSocket = scene.childNode(withName: "entranceSocket"),
               let socket = templateSocket.copy() as? SKNode {
                socket.position = CGPoint(x: 3.0 * scale, y: -195.0 * scale)
                socket.zPosition = 15
                hiveRigNode.addChild(socket)
                self.entranceSocket = socket
            }

            if branchNode == nil || hiveNode == nil {
                buildProceduralMissing(scale: scale, topOffsetY: topOffsetY)
            }
            startIdleAnimation()
            return
        }

        buildProceduralMissing(scale: scale, topOffsetY: topOffsetY)
        startIdleAnimation()
    }

    private static var cachedTemplateScene: SKScene?
    private static var didAttemptLoadTemplate = false

    private func loadSceneTemplate() -> SKScene? {
        if !Self.didAttemptLoadTemplate {
            Self.didAttemptLoadTemplate = true
            Self.cachedTemplateScene = SKScene(fileNamed: "Animal1Scene")
        }
        return Self.cachedTemplateScene
    }

    private func buildProceduralMissing(scale: CGFloat, topOffsetY: CGFloat) {
        if branchNode == nil {
            let branch = SKSpriteNode(texture: BeeTextureCache.shared.texture(named: "Beehive-2@4.167x"))
            branch.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            branch.size = CGSize(width: 512.0 * scale, height: 305.0 * scale)
            branch.position = CGPoint(x: 0, y: topOffsetY)
            branch.zPosition = 5
            branch.restZRotation = 0.0
            animalRootNode.addChild(branch)
            self.branchNode = branch
        }
        if hiveNode == nil {
            let hive = SKSpriteNode(texture: BeeTextureCache.shared.texture(named: "Beehive-3@4.167x"))
            hive.anchorPoint = CGPoint(x: 0.48, y: 1.0)
            hive.size = CGSize(width: 299.0 * scale, height: 315.0 * scale)
            hive.position = .zero
            hive.zPosition = 10
            hiveRigNode.addChild(hive)
            self.hiveNode = hive
        }
        if entranceSocket == nil {
            let socket = SKNode()
            socket.position = CGPoint(x: 3.0 * scale, y: -195.0 * scale)
            socket.zPosition = 15
            hiveRigNode.addChild(socket)
            self.entranceSocket = socket
        }
    }

    public func spawnAnchorPoint(in targetNode: SKNode) -> CGPoint {
        if let socket = entranceSocket, let parent = socket.parent {
            return parent.convert(socket.position, to: targetNode)
        }
        return parent?.convert(position, to: targetNode) ?? position
    }

    /// Độ lệch cửa tổ tính từ đỉnh-giữa slot (theo hệ UIKit +Y xuống dưới)
    public static func hiveEntranceOffsetFromSlotTop(slotSize: CGSize, fitRatio: CGFloat = Animal1View.defaultFitRatio) -> CGPoint {
        let baseCanvasW: CGFloat = 512.0
        let baseCanvasH: CGFloat = 478.0
        let aspect = baseCanvasH / baseCanvasW
        let targetH = slotSize.height * fitRatio
        let naturalW = targetH / aspect
        let targetW = min(naturalW, slotSize.width * 0.92)
        let scale = min(targetW / naturalW, 1.0) * (targetH / baseCanvasH)
        return CGPoint(x: -69.70 * scale, y: 357.59 * scale)
    }

    // MARK: - Animation

    private func makeMotionContext(onComplete: (() -> Void)? = nil) -> AnimalMotionContext {
        return AnimalMotionContext(
            targetNode: hiveRigNode,
            branchNode: branchNode,
            bodyNode: hiveNode,
            initialPosition: hiveRigNode.position,
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

        let targetForTap = hiveNode ?? hiveRigNode
        for effect in tapEffects {
            effect.trigger(on: targetForTap, in: self, isHanging: isHanging)
        }
    }
}

import SpriteKit

/// Cây có thân/cành ghép với hoa: chỉ xoay khối chung để các điểm gắn luôn liền nhau.
public final class ConnectedPlantSwayMotionEffect: PlantMotionEffect {
    public var name: String { "ConnectedPlantSway" }

    public init() {}

    public func apply(context: PlantMotionContext) {
        context.stopIdleActions()
        guard context.level > 2 else {
            WindSwayMotionEffect(durationMultiplier: 1.3).apply(context: context)
            return
        }

        let root = context.plantRootNode
        root.removeAction(forKey: "connectedPlantTap")
        root.zRotation = 0
        root.setScale(context.baseScale)

        func rotation(_ angle: CGFloat, _ duration: TimeInterval) -> SKAction {
            let action = SKAction.rotate(toAngle: angle, duration: duration)
            action.timingMode = .easeInEaseOut
            return action
        }

        // Không xoay hoặc co giãn riêng thân/hoa; toàn bộ hình ghép dùng chung biến đổi.
        root.run(.sequence([
            rotation(0.026, 0.42),
            rotation(-0.014, 0.65),
            rotation(0.006, 0.52),
            rotation(-0.002, 0.42),
            rotation(0, 0.36),
            .run { [weak root] in
                root?.zRotation = 0
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
                context.onComplete?()
            }
        ]), withKey: "connectedPlantTap")
    }
}

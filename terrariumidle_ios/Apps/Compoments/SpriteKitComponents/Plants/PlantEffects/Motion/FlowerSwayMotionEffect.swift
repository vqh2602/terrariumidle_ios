import SpriteKit

/// Các cành hoa đón gió cùng chiều, hồi theo quán tính và giữ nguyên chiều dài cuống.
public final class FlowerSwayMotionEffect: PlantMotionEffect {
    public var name: String { "FlowerSway" }

    public init() {}

    public func apply(context: PlantMotionContext) {
        context.stopIdleActions()
        guard context.level > 2 else {
            WindSwayMotionEffect(durationMultiplier: 1.3).apply(context: context)
            return
        }

        let root = context.plantRootNode
        root.removeAction(forKey: "flowerTapWind")
        root.zRotation = 0
        root.setScale(context.baseScale)

        func rotation(_ angle: CGFloat, _ duration: TimeInterval) -> SKAction {
            let action = SKAction.rotate(toAngle: angle, duration: duration)
            action.timingMode = .easeInEaseOut
            return action
        }

        // Lấy vị trí nghỉ để thứ tự làn gió ổn định cả khi tap liên tiếp.
        for flower in context.leafNodes {
            flower.removeAction(forKey: "flowerTapSway")
            flower.zRotation = flower.restZRotation
        }
        let flowers = context.leafNodes.sorted { $0.frame.midX < $1.frame.midX }
        let maxDelay = Double(max(0, flowers.count - 1)) * 0.016
        for (index, flower) in flowers.enumerated() {
            let rest = flower.restZRotation
            let height = (flower as? SKSpriteNode)?.size.height ?? 1100
            let angle = 0.055 + min(max(height / 1520, 0), 1) * 0.035
            flower.run(.sequence([
                .wait(forDuration: Double(index) * 0.016),
                rotation(rest + angle, 0.60),
                rotation(rest - angle * 0.40, 0.80),
                rotation(rest + angle * 0.17, 0.50),
                rotation(rest, 0.60),
                .run { [weak flower] in flower?.zRotation = rest }
            ]), withKey: "flowerTapSway")
        }

        root.run(.sequence([
            rotation(0.006, 0.60),
            rotation(-0.003, 0.80),
            rotation(0.001, 0.50),
            rotation(0, 0.60),
            // Chờ cả cành cuối hồi xong trước khi khởi động lại gió nghỉ.
            .wait(forDuration: maxDelay + 0.05),
            .run { [weak root] in
                root?.zRotation = 0
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
                context.onComplete?()
            }
        ]), withKey: "flowerTapWind")
    }
}

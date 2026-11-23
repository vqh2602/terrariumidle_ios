import SpriteKit

/// Gió quét qua cành lá dài, giữ gốc và hồi chậm theo quán tính.
public final class FrondWindMotionEffect: PlantMotionEffect {
    public var name: String { "FrondWind" }

    public init() {}

    public func apply(context: PlantMotionContext) {
        guard context.level > 2 else {
            WindSwayMotionEffect(durationMultiplier: 1.3).apply(context: context)
            return
        }
        context.stopIdleActions()
        let root = context.plantRootNode
        root.removeAction(forKey: "frondTapWind")
        root.zRotation = 0
        root.setScale(context.baseScale)

        func rotation(_ angle: CGFloat, _ duration: TimeInterval) -> SKAction {
            let action = SKAction.rotate(toAngle: angle, duration: duration)
            action.timingMode = .easeInEaseOut
            return action
        }

        // Tổng thời lượng bao gồm độ trễ của lá cuối, tránh idle tranh chấp với tap.
        let leafDuration: TimeInterval = 0.60 + 0.80 + 0.52 + 0.58
        let totalDuration = leafDuration + Double(max(0, context.leafNodes.count - 1)) * 0.055
        let branches = context.leafNodes.sorted { $0.frame.midX < $1.frame.midX }
        for (index, leaf) in branches.enumerated() {
            leaf.removeAction(forKey: "frondLeafWind")
            let rest = leaf.restZRotation
            leaf.zRotation = rest
            // Cành cao đón gió nhiều hơn; các cành ngắn ở gốc chỉ lay nhẹ.
            let height = (leaf as? SKSpriteNode)?.size.height ?? 400
            let angle = min(max(height / 715, 0.2), 1) * 0.075
            leaf.run(.sequence([
                .wait(forDuration: Double(index) * 0.055),
                rotation(rest + angle, 0.60),
                rotation(rest - angle * 0.38, 0.80),
                rotation(rest + angle * 0.16, 0.52),
                rotation(rest, 0.58),
                .run { [weak leaf] in leaf?.zRotation = rest }
            ]), withKey: "frondLeafWind")
        }

        root.run(.sequence([
            rotation(0.006, 0.60),
            rotation(-0.003, 0.80),
            rotation(0.001, 0.52),
            rotation(0, 0.58),
            .wait(forDuration: totalDuration - leafDuration),
            .run { [weak root] in
                root?.zRotation = 0
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
                context.onComplete?()
            }
        ]), withKey: "frondTapWind")
    }
}

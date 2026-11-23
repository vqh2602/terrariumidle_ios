import SpriteKit

/// Gió lan qua tán lá rộng: thân giữ vững, lá nghiêng cùng chiều và hồi dần.
public final class BroadleafWindMotionEffect: PlantMotionEffect {
    public var name: String { "BroadleafWind" }

    /// Các bộ phận thân/chồi chỉ lay rất nhẹ để giữ liền vị trí gắn lá.
    public var stemNodeNames: Set<String>

    public init(stemNodeNames: Set<String> = ["leaf_4", "leaf_7"]) {
        self.stemNodeNames = stemNodeNames
    }

    public func apply(context: PlantMotionContext) {
        guard context.level > 2 else {
            WindSwayMotionEffect(durationMultiplier: 1.3).apply(context: context)
            return
        }
        context.stopIdleActions()
        let root = context.plantRootNode
        root.removeAction(forKey: "broadleafTapWind")
        root.zRotation = 0
        root.setScale(context.baseScale)

        func rotation(_ angle: CGFloat, _ duration: TimeInterval) -> SKAction {
            let action = SKAction.rotate(toAngle: angle, duration: duration)
            action.timingMode = .easeInEaseOut
            return action
        }

        // Tổng thời lượng bao gồm độ trễ của lá cuối, tránh idle tranh chấp với tap.
        let leafDuration: TimeInterval = 0.48 + 0.62 + 0.44 + 0.46
        let totalDuration = leafDuration + Double(max(0, context.leafNodes.count - 1)) * 0.055
        for (index, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "broadleafLeafWind")
            let rest = leaf.restZRotation
            leaf.zRotation = rest
            // Thân và chồi giữa không uốn độc lập làm hở các điểm gắn cuống lá.
            let isStem = stemNodeNames.contains(leaf.name ?? "")
            let angle: CGFloat = isStem ? 0.004 : (leaf.position.y > 300 ? 0.10 : 0.13)
            leaf.run(.sequence([
                .wait(forDuration: Double(index) * 0.055),
                rotation(rest + angle, 0.48),
                rotation(rest - angle * 0.38, 0.62),
                rotation(rest + angle * 0.16, 0.44),
                rotation(rest, 0.46),
                .run { [weak leaf] in leaf?.zRotation = rest }
            ]), withKey: "broadleafLeafWind")
        }

        root.run(.sequence([
            rotation(0.012, 0.48),
            rotation(-0.005, 0.62),
            rotation(0.002, 0.44),
            rotation(0, 0.46),
            .wait(forDuration: totalDuration - leafDuration),
            .run { [weak root] in
                root?.zRotation = 0
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
                context.onComplete?()
            }
        ]), withKey: "broadleafTapWind")
    }
}

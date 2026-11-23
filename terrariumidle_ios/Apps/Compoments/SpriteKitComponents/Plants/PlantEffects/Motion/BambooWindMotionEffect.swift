import SpriteKit

/// Thân tre lay rất nhẹ; lá đã gắn vào thân rung riêng quanh cuống.
public final class BambooWindMotionEffect: PlantMotionEffect {
    public var name: String { "BambooWind" }
    static let stemNames: Set<String> = ["leaf_6", "leaf_17", "leaf_18", "leaf_19"]

    public init() {}

    static func motionNode(for node: SKNode) -> SKNode {
        if let pivot = node.parent, pivot.name?.hasPrefix("bambooLeafPivot_") == true {
            return pivot
        }
        return node
    }

    public func apply(context: PlantMotionContext) {
        context.stopIdleActions()
        guard context.level > 2 else {
            WindSwayMotionEffect(durationMultiplier: 1.3).apply(context: context)
            return
        }
        let root = context.plantRootNode
        root.removeAction(forKey: "bambooTapWind")
        root.zRotation = 0
        root.setScale(context.baseScale)

        let durations: [TimeInterval] = [0.32, 0.44, 0.30, 0.25, 0.35]
        let motionDuration = durations.reduce(0, +)
        let maxDelay = Double(max(0, context.leafNodes.count - 1)) * 0.012
        for (index, leaf) in context.leafNodes.enumerated() {
            let node = Self.motionNode(for: leaf)
            node.removeAction(forKey: "leafWind")
            node.removeAction(forKey: "bambooTapSway")
            let rest = node.restZRotation
            node.zRotation = rest
            let isStem = Self.stemNames.contains(leaf.name ?? "")
            let angle: CGFloat = isStem ? 0.007 : 0.18 + CGFloat(index % 3) * 0.015
            let offsets: [CGFloat] = [angle, -angle * 0.40, angle * 0.22, -angle * 0.08, 0]
            let rotations = zip(offsets, durations).map { offset, duration in
                let action = SKAction.rotate(toAngle: rest + offset, duration: duration)
                action.timingMode = .easeInEaseOut
                return action
            }
            node.run(.sequence([
                .wait(forDuration: Double(index) * 0.012)
            ] + rotations + [
                .run { [weak node] in node?.zRotation = rest }
            ]), withKey: "bambooTapSway")
        }
        root.run(.sequence([
            .wait(forDuration: motionDuration + maxDelay + 0.05),
            .run { [weak root] in
                root?.zRotation = 0
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
                context.onComplete?()
            }
        ]), withKey: "bambooTapWind")
    }
}

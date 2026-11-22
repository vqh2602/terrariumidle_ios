//
//  WindSwayMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap cây bản mới: Gió lay đu đưa mềm mại (Thân cây chao nghiêng đón gió, từng phiến lá uốn lượn nhịp nhàng)
public final class WindSwayMotionEffect: PlantMotionEffect {

    public var name: String { "WindSway" }

    /// Góc nghiêng chao đón gió cực đại của thân cây (radian)
    public var swayAngle: CGFloat
    /// Góc uốn cong của từng phiến lá
    public var leafBendAngle: CGFloat
    /// Hệ số co giãn thời gian
    public var durationMultiplier: Double

    public init(
        swayAngle: CGFloat = 0.048,
        leafBendAngle: CGFloat = 0.12,
        durationMultiplier: Double = 1.0
    ) {
        self.swayAngle = swayAngle
        self.leafBendAngle = leafBendAngle
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PlantMotionContext) {
        switch context.level {
        case 1:
            applySeedWindMotion(context: context)
        case 2:
            applySproutWindMotion(context: context)
        default:
            applyMatureWindMotion(context: context)
        }
    }

    // MARK: - Level 1: Hạt Giống Đón Gió

    private func applySeedWindMotion(context: PlantMotionContext) {
        context.stopIdleActions()

        guard let node = context.seedNode else {
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
            return
        }

        let mult = max(0.1, durationMultiplier)
        node.removeAction(forKey: "seedTapWind")
        node.position = context.initialSeedPosition
        node.setScale(1.0)
        node.zRotation = 0.0

        // Hạt lắc lư chao nghiêng nhẹ nhàng như đón làn gió thoảng
        let swayR = SKAction.rotate(toAngle: swayAngle * 1.5, duration: 0.12 * mult)
        swayR.timingMode = .easeOut
        let swayL = SKAction.rotate(toAngle: -swayAngle * 1.2, duration: 0.18 * mult)
        swayL.timingMode = .easeInEaseOut
        let settle = SKAction.rotate(toAngle: 0.0, duration: 0.15 * mult)
        settle.timingMode = .easeOut

        let hop = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.12 * mult),
            SKAction.moveTo(y: context.initialSeedPosition.y, duration: 0.18 * mult)
        ])

        let completionAction = SKAction.run {
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
        }

        node.run(SKAction.group([
            SKAction.sequence([swayR, swayL, settle, completionAction]),
            hop
        ]), withKey: "seedTapWind")

        if let glow = node.childNode(withName: "seedGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.70, duration: 0.10 * mult),
                SKAction.fadeAlpha(to: 0.28, duration: 0.30 * mult)
            ])
            glow.run(flash)
        }
    }

    // MARK: - Level 2: Lá Mầm Chao Nghiêng

    private func applySproutWindMotion(context: PlantMotionContext) {
        context.stopIdleActions()

        guard let node = context.sproutNode else {
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
            return
        }

        let mult = max(0.1, durationMultiplier)
        node.removeAction(forKey: "sproutTapWind")
        node.position = context.initialSproutPosition
        node.setScale(1.0)
        node.zRotation = 0.0

        // Mầm non đón gió uốn lượn 3 nhịp mềm mại
        let sway1 = SKAction.rotate(toAngle: swayAngle * 2.2, duration: 0.15 * mult)
        sway1.timingMode = .easeOut
        let sway2 = SKAction.rotate(toAngle: -swayAngle * 1.6, duration: 0.22 * mult)
        sway2.timingMode = .easeInEaseOut
        let sway3 = SKAction.rotate(toAngle: swayAngle * 0.8, duration: 0.18 * mult)
        sway3.timingMode = .easeInEaseOut
        let rest = SKAction.rotate(toAngle: 0.0, duration: 0.16 * mult)
        rest.timingMode = .easeOut

        let completionAction = SKAction.run {
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
        }

        node.run(SKAction.sequence([sway1, sway2, sway3, rest, completionAction]), withKey: "sproutTapWind")

        if let glow = node.childNode(withName: "sproutGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.65, duration: 0.12 * mult),
                SKAction.fadeAlpha(to: 0.22, duration: 0.32 * mult)
            ])
            glow.run(flash)
        }
    }

    // MARK: - Level 3+: Cây Trưởng Thành Uốn Lượn Theo Chiều Gió

    private func applyMatureWindMotion(context: PlantMotionContext) {
        context.stopIdleActions()

        let mult = max(0.1, durationMultiplier)
        let root = context.plantRootNode

        root.removeAction(forKey: "matureTapWind")
        root.zRotation = 0.0
        root.setScale(context.baseScale)

        let rootMotionDuration = (0.22 + 0.28 + 0.22 + 0.20) * mult // 0.92 * mult
        let maxLeafDelay = Double(max(0, context.leafNodes.count - 1)) * 0.025 * mult
        let leafMotionDuration = (0.18 + 0.26 + 0.20) * mult // 0.64 * mult
        let totalLeafDuration = maxLeafDelay + leafMotionDuration
        let totalDuration = max(rootMotionDuration, totalLeafDuration)

        // 1. Thân cây và toàn bộ tán chao nghiêng đón gió
        let windTilt = SKAction.rotate(toAngle: swayAngle, duration: 0.22 * mult)
        windTilt.timingMode = .easeOut
        let windRebound = SKAction.rotate(toAngle: -swayAngle * 0.68, duration: 0.28 * mult)
        windRebound.timingMode = .easeInEaseOut
        let windSwayBack = SKAction.rotate(toAngle: swayAngle * 0.30, duration: 0.22 * mult)
        windSwayBack.timingMode = .easeInEaseOut
        let windSettle = SKAction.rotate(toAngle: 0.0, duration: 0.20 * mult)
        windSettle.timingMode = .easeOut

        // Nhún nhịp nhàng theo chiều dọc rất nhẹ tạo độ dẻo
        let flexDown = SKAction.scaleY(to: context.baseScale * 0.97, duration: 0.12 * mult)
        let flexUp = SKAction.scaleY(to: context.baseScale * 1.02, duration: 0.24 * mult)
        let flexNormal = SKAction.scaleY(to: context.baseScale, duration: 0.20 * mult)
        let flexAction = SKAction.sequence([flexDown, flexUp, flexNormal])

        var swayActions: [SKAction] = [windTilt, windRebound, windSwayBack, windSettle]
        if totalDuration > rootMotionDuration {
            swayActions.append(SKAction.wait(forDuration: totalDuration - rootMotionDuration))
        }

        let completionAction = SKAction.run {
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
        }
        swayActions.append(completionAction)

        let mainAction = SKAction.group([
            SKAction.sequence(swayActions),
            flexAction
        ])

        root.run(mainAction, withKey: "matureTapWind")

        // 2. Từng phiến lá uốn cong mềm mại đón gió theo chuỗi sóng
        for (idx, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "leafWindSway")
            let restAngle = leaf.restZRotation
            leaf.zRotation = restAngle // Triệt tiêu tức thì góc xoay trôi dạt do ngắt action trước

            let isLeft = leaf.position.x < 0
            // Lá đón gió (bên trái) bị bẻ cong nhiều hơn, lá khuất gió uốn theo chiều gió
            let impulse = (isLeft ? 1.0 : -0.75) * leafBendAngle * CGFloat.random(in: 0.85...1.15)

            let delay = SKAction.wait(forDuration: Double(idx) * 0.025 * mult)
            let bendOut = SKAction.rotate(toAngle: restAngle + impulse, duration: 0.18 * mult)
            bendOut.timingMode = .easeOut
            let bendBack = SKAction.rotate(toAngle: restAngle - impulse * 0.35, duration: 0.26 * mult)
            bendBack.timingMode = .easeInEaseOut
            let settle = SKAction.rotate(toAngle: restAngle, duration: 0.20 * mult)
            settle.timingMode = .easeOut
            let resetEnd = SKAction.run { [weak leaf] in
                leaf?.zRotation = restAngle
            }

            leaf.run(SKAction.sequence([delay, bendOut, bendBack, settle, resetEnd]), withKey: "leafWindSway")
        }
    }
}

//
//  SubtleWobbleMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap: Rung lắc nhẹ trái phải tần số nhanh (Micro-wobble / Jiggle)
public final class SubtleWobbleMotionEffect: PotMotionEffect {

    public var name: String { "SubtleWobble" }

    public var wobbleAngle: CGFloat
    public var durationMultiplier: Double

    public init(wobbleAngle: CGFloat = 0.035, durationMultiplier: Double = 1.0) {
        self.wobbleAngle = wobbleAngle
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PotMotionContext) {
        let target = context.targetNode
        target.removeAction(forKey: "potMotionTap")

        let mult = max(0.1, durationMultiplier)

        let r1 = SKAction.rotate(toAngle: wobbleAngle, duration: 0.05 * mult)
        let r2 = SKAction.rotate(toAngle: -wobbleAngle, duration: 0.07 * mult)
        let r3 = SKAction.rotate(toAngle: wobbleAngle * 0.5, duration: 0.06 * mult)
        let r4 = SKAction.rotate(toAngle: 0.0, duration: 0.05 * mult)

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        let seq = SKAction.sequence([r1, r2, r3, r4, completionAction])
        target.run(seq, withKey: "potMotionTap")
    }
}

//
//  SpringPendulumMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap chậu treo: Lắc con lắc đàn hồi 3 nhịp + khôi phục trạng thái đu đưa tự nhiên Idle Sway (Mẫu chuẩn Pot18)
public final class SpringPendulumMotionEffect: PotMotionEffect {

    public var name: String { "SpringPendulum" }

    public var swingRightAngle: CGFloat
    public var swingLeftAngle: CGFloat
    public var durationMultiplier: Double
    public var alsoBouncePot: Bool

    public init(
        swingRightAngle: CGFloat = 0.065,
        swingLeftAngle: CGFloat = -0.050,
        durationMultiplier: Double = 1.0,
        alsoBouncePot: Bool = true
    ) {
        self.swingRightAngle = swingRightAngle
        self.swingLeftAngle = swingLeftAngle
        self.durationMultiplier = durationMultiplier
        self.alsoBouncePot = alsoBouncePot
    }

    public func apply(context: PotMotionContext) {
        let target = context.targetNode
        target.removeAction(forKey: "potMotionTap")

        let mult = max(0.1, durationMultiplier)

        if context.isHanging {
            let swingRight = SKAction.rotate(toAngle: swingRightAngle, duration: 0.28 * mult)
            swingRight.timingMode = .easeOut
            let swingLeft = SKAction.rotate(toAngle: swingLeftAngle, duration: 0.38 * mult)
            swingLeft.timingMode = .easeInEaseOut
            let settle = SKAction.rotate(toAngle: 0.0, duration: 0.32 * mult)
            settle.timingMode = .easeInEaseOut
            let resume = SKAction.run {
                context.onComplete?()
            }
            target.run(SKAction.sequence([swingRight, swingLeft, settle, resume]), withKey: "potMotionTap")
        }

        // Nếu có Sprite thân chậu và bật cờ alsoBouncePot: áp dụng Squash & Stretch
        if alsoBouncePot, let pot = context.potNode {
            PotBounceAnimator.applyBounce(
                to: pot,
                shadowNode: context.shadowNode,
                initialPosition: context.initialPosition,
                isHanging: context.isHanging,
                config: .standard
            )
        }
    }
}

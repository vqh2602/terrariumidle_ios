//
//  ElasticPendulumMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap chậu treo: Lắc con lắc vật lý quanh đỉnh móc treo kết hợp nhún nảy đàn hồi trục Y (Mẫu chuẩn Pot15)
public final class ElasticPendulumMotionEffect: PotMotionEffect {

    public var name: String { "ElasticPendulum" }

    /// Góc lắc cực đại ban đầu (radian)
    public var swingAngle: CGFloat
    /// Hệ số nén trục Y khi bắt đầu chạm (Squash)
    public var bounceScaleY: CGFloat
    /// Hệ số kéo giãn trục Y khi bật nảy (Stretch)
    public var reboundScaleY: CGFloat
    /// Hệ số co giãn thời gian (1.0 là chuẩn)
    public var durationMultiplier: Double

    public init(
        swingAngle: CGFloat = 0.045,
        bounceScaleY: CGFloat = 0.96,
        reboundScaleY: CGFloat = 1.025,
        durationMultiplier: Double = 1.0
    ) {
        self.swingAngle = swingAngle
        self.bounceScaleY = bounceScaleY
        self.reboundScaleY = reboundScaleY
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PotMotionContext) {
        let target = context.targetNode
        target.removeAction(forKey: "potMotionTap")
        target.removeAction(forKey: "idleSway")
        target.removeAction(forKey: "idlePendulum")

        let mult = max(0.1, durationMultiplier)

        // 1. Hiệu ứng lắc con lắc vật lý (Pendulum Swing) quanh đỉnh móc treo (0, 0)
        let swingLeft = SKAction.rotate(toAngle: swingAngle, duration: 0.16 * mult)
        swingLeft.timingMode = .easeOut
        let swingRight = SKAction.rotate(toAngle: -swingAngle * 0.844, duration: 0.20 * mult)
        swingRight.timingMode = .easeInEaseOut
        let swingBack = SKAction.rotate(toAngle: swingAngle * 0.40, duration: 0.18 * mult)
        swingBack.timingMode = .easeInEaseOut
        let swingRest = SKAction.rotate(toAngle: 0.0, duration: 0.22 * mult)
        swingRest.timingMode = .easeOut

        let swingAction = SKAction.sequence([swingLeft, swingRight, swingBack, swingRest])

        // 2. Hiệu ứng nhún nảy nén trục Y (Elastic Bounce)
        let squash = SKAction.scaleY(to: bounceScaleY, duration: 0.08 * mult)
        squash.timingMode = .easeOut
        let stretch = SKAction.scaleY(to: reboundScaleY, duration: 0.12 * mult)
        stretch.timingMode = .easeInEaseOut
        let normal = SKAction.scaleY(to: 1.0, duration: 0.12 * mult)
        normal.timingMode = .easeOut

        let bounceAction = SKAction.sequence([squash, stretch, normal])

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        let combined = SKAction.sequence([
            SKAction.group([swingAction, bounceAction]),
            completionAction
        ])

        target.run(combined, withKey: "potMotionTap")
    }
}

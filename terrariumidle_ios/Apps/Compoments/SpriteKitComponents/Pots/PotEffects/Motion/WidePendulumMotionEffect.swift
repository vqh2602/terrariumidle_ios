//
//  WidePendulumMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap chậu treo: Đu đưa con lắc biên độ rộng 5 nhịp tắt dần mượt mà, thuần túy góc xoay (Mẫu chuẩn Pot16, Pot17)
public final class WidePendulumMotionEffect: PotMotionEffect {

    public var name: String { "WidePendulum" }

    /// Góc lắc cực đại ban đầu (radian, mặc định 0.08 rad ~ 4.6 độ)
    public var swingAngle: CGFloat
    /// Hệ số co giãn thời gian (1.0 là chuẩn)
    public var durationMultiplier: Double

    public init(
        swingAngle: CGFloat = 0.08,
        durationMultiplier: Double = 1.0
    ) {
        self.swingAngle = swingAngle
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PotMotionContext) {
        let target = context.targetNode
        target.removeAction(forKey: "potMotionTap")

        let mult = max(0.1, durationMultiplier)

        // 5 nhịp dao động con lắc tắt dần tự nhiên
        let swing1 = SKAction.rotate(toAngle: swingAngle, duration: 0.28 * mult)
        swing1.timingMode = .easeOut
        let swing2 = SKAction.rotate(toAngle: -swingAngle * 0.75, duration: 0.38 * mult)
        swing2.timingMode = .easeInEaseOut
        let swing3 = SKAction.rotate(toAngle: swingAngle * 0.40, duration: 0.34 * mult)
        swing3.timingMode = .easeInEaseOut
        let swing4 = SKAction.rotate(toAngle: -swingAngle * 0.20, duration: 0.28 * mult)
        swing4.timingMode = .easeInEaseOut
        let rest = SKAction.rotate(toAngle: 0.0, duration: 0.24 * mult)
        rest.timingMode = .easeInEaseOut

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        let sequence = SKAction.sequence([swing1, swing2, swing3, swing4, rest, completionAction])
        target.run(sequence, withKey: "potMotionTap")
    }
}

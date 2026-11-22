//
//  LuckyCatMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Chuyển Động Chuyên Biệt cho Chú Mèo Thần Tài (Maneki-neko - Sticker2)
/// - **Nguyên khối tự nhiên (Single Whole Body)**: Không cắt ghép, toàn bộ chú mèo nguyên vẹn
/// - **Nhàn rỗi (Idle)**:
///   * Toàn thân chú mèo đung đưa nhẹ nhàng qua lại trên đế đệm như búp bê may mắn (`±0.042 rad` ~ 2.4°).
///   * Nhấp nhô nhịp thở êm ái sống động (`scaleY: 1.0 -> 1.018 -> 1.0`).
/// - **Khi Chạm (Tap)**:
///   * Chú mèo nhún nảy nén xuống bật lên đàn hồi (Squash & Stretch).
///   * Lắc lư đung đưa vui sướng với biên độ tăng cường rồi dịu dần về nhịp lắc êm ả ban đầu.
public final class LuckyCatMotionEffect: StickerMotionEffect {

    public var name: String { "luckyCat" }

    public init() {}

    public func startIdle(context: StickerMotionContext) {
        stopIdle(context: context)

        let target = context.bodyNode ?? context.targetNode
        target.zRotation = 0
        target.yScale = 1.0
        target.xScale = 1.0

        // 1. Chú mèo đung đưa lắc lư qua lại nhẹ nhàng tự nhiên quanh đáy đệm
        let swayLeft = SKAction.rotate(toAngle: -0.042, duration: 0.70)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: 0.042, duration: 0.70)
        swayRight.timingMode = .easeInEaseOut

        let swayLoop = SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight]))
        target.run(swayLoop, withKey: "cat_idle_sway")

        // 2. Nhịp thở nhấp nhô nhẹ nhàng
        let breatheUp = SKAction.scaleY(to: 1.020, duration: 1.1)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scaleY(to: 1.0, duration: 1.1)
        breatheDown.timingMode = .easeInEaseOut

        let breatheLoop = SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown]))
        target.run(breatheLoop, withKey: "cat_idle_breathe")
    }

    public func stopIdle(context: StickerMotionContext) {
        let target = context.bodyNode ?? context.targetNode
        target.removeAction(forKey: "cat_idle_sway")
        target.removeAction(forKey: "cat_idle_breathe")
        target.removeAction(forKey: "cat_tap_action")
        target.zRotation = 0
        target.xScale = 1.0
        target.yScale = 1.0
    }

    public func apply(context: StickerMotionContext) {
        let target = context.bodyNode ?? context.targetNode
        target.removeAction(forKey: "cat_idle_sway")
        target.removeAction(forKey: "cat_idle_breathe")
        target.removeAction(forKey: "cat_tap_action")

        // 1. Nhún nảy Squash & Stretch đàn hồi vui vẻ
        let squash = SKAction.group([
            SKAction.scaleX(to: 1.12, duration: 0.10),
            SKAction.scaleY(to: 0.88, duration: 0.10)
        ])
        squash.timingMode = .easeOut

        let stretch = SKAction.group([
            SKAction.scaleX(to: 0.94, duration: 0.14),
            SKAction.scaleY(to: 1.08, duration: 0.14)
        ])
        stretch.timingMode = .easeOut

        let bounceBack = SKAction.group([
            SKAction.scaleX(to: 1.03, duration: 0.12),
            SKAction.scaleY(to: 0.98, duration: 0.12)
        ])
        bounceBack.timingMode = .easeInEaseOut

        let settleScale = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.15),
            SKAction.scaleY(to: 1.0, duration: 0.15)
        ])
        settleScale.timingMode = .easeInEaseOut

        let bounceSequence = SKAction.sequence([squash, stretch, bounceBack, settleScale])

        // 2. Lắc lư đung đưa vui sướng khi nhận tương tác
        let tapSway1 = SKAction.rotate(toAngle: 0.085, duration: 0.15)
        tapSway1.timingMode = .easeOut
        let tapSway2 = SKAction.rotate(toAngle: -0.075, duration: 0.18)
        tapSway2.timingMode = .easeInEaseOut
        let tapSway3 = SKAction.rotate(toAngle: 0.050, duration: 0.20)
        tapSway3.timingMode = .easeInEaseOut
        let tapSway4 = SKAction.rotate(toAngle: -0.025, duration: 0.22)
        tapSway4.timingMode = .easeInEaseOut
        let tapSwayCenter = SKAction.rotate(toAngle: 0.0, duration: 0.25)
        tapSwayCenter.timingMode = .easeInEaseOut

        let swaySequence = SKAction.sequence([tapSway1, tapSway2, tapSway3, tapSway4, tapSwayCenter])

        let combinedAction = SKAction.group([bounceSequence, swaySequence])

        let restoreIdle = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.startIdle(context: context)
            context.onComplete?()
        }

        target.run(SKAction.sequence([combinedAction, restoreIdle]), withKey: "cat_tap_action")
    }
}

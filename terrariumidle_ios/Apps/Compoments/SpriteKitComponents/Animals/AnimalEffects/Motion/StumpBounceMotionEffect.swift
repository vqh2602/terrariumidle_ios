//
//  StumpBounceMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng nhún nảy đầm chắc cho Gốc Cây Gỗ Mục (`animal2`) khi chạm vào
public final class StumpBounceMotionEffect: AnimalMotionEffect {

    public var name: String { "stumpBounce" }

    public init() {}

    public func startIdle(context: AnimalMotionContext) {
        // Gốc cây gỗ mục đứng vững trên kệ, không lắc khi nhàn rỗi
    }

    public func stopIdle(context: AnimalMotionContext) {
        context.targetNode.removeAction(forKey: "animal_idle_action")
    }

    public func apply(context: AnimalMotionContext) {
        let target = context.targetNode
        target.removeAction(forKey: "animal_tap_motion")
        target.zRotation = 0.0
        target.xScale = 1.0
        target.yScale = 1.0

        let squash = SKAction.group([
            SKAction.scaleX(to: 1.055, duration: 0.08),
            SKAction.scaleY(to: 0.935, duration: 0.08),
            SKAction.rotate(toAngle: 0.018, duration: 0.08)
        ])
        squash.timingMode = .easeOut

        let rebound = SKAction.group([
            SKAction.scaleX(to: 0.975, duration: 0.11),
            SKAction.scaleY(to: 1.03, duration: 0.11),
            SKAction.rotate(toAngle: -0.012, duration: 0.11)
        ])
        rebound.timingMode = .easeInEaseOut

        let settle = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.12),
            SKAction.scaleY(to: 1.0, duration: 0.12),
            SKAction.rotate(toAngle: 0.0, duration: 0.12)
        ])
        settle.timingMode = .easeOut

        let finish = SKAction.run { [weak target] in
            target?.zRotation = 0.0
            target?.xScale = 1.0
            target?.yScale = 1.0
            context.onComplete?()
        }

        target.run(SKAction.sequence([squash, rebound, settle, finish]), withKey: "animal_tap_motion")
    }
}

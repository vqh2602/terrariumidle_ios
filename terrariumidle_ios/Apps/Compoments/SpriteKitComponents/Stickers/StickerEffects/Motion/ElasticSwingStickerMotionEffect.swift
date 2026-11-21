//
//  ElasticSwingStickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng con lắc đàn hồi tần số nhanh (Elastic Swing)
public final class ElasticSwingStickerMotionEffect: StickerMotionEffect {

    public var name: String { "elasticSwing" }

    public init() {}

    public func startIdle(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")
        node.removeAction(forKey: "sticker_idle_drift")

        let swingLeft = SKAction.rotate(toAngle: -0.060, duration: 1.5)
        swingLeft.timingMode = .easeInEaseOut
        let swingRight = SKAction.rotate(toAngle: 0.060, duration: 1.5)
        swingRight.timingMode = .easeInEaseOut
        let idleLoop = SKAction.sequence([swingLeft, swingRight])
        node.run(SKAction.repeatForever(idleLoop), withKey: "sticker_idle_action")
    }

    public func stopIdle(context: StickerMotionContext) {
        context.targetNode.removeAction(forKey: "sticker_idle_action")
    }

    public func apply(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")
        node.removeAction(forKey: "sticker_tap_action")

        let s1 = SKAction.rotate(toAngle: 0.18, duration: 0.16)
        s1.timingMode = .easeOut
        let s2 = SKAction.rotate(toAngle: -0.14, duration: 0.18)
        s2.timingMode = .easeInEaseOut
        let s3 = SKAction.rotate(toAngle: 0.08, duration: 0.20)
        s3.timingMode = .easeInEaseOut
        let s4 = SKAction.rotate(toAngle: 0.0, duration: 0.22)
        s4.timingMode = .easeInEaseOut

        let squash = SKAction.scaleY(to: 0.92, duration: 0.12)
        let stretch = SKAction.scaleY(to: 1.06, duration: 0.16)
        let normal = SKAction.scaleY(to: 1.0, duration: 0.20)

        let resume = SKAction.run { [weak self] in
            self?.startIdle(context: context)
            context.onComplete?()
        }

        let group = SKAction.group([
            SKAction.sequence([s1, s2, s3, s4]),
            SKAction.sequence([squash, stretch, normal])
        ])

        node.run(SKAction.sequence([group, resume]), withKey: "sticker_tap_action")
    }
}

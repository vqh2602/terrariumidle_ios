//
//  SubtleFlutterStickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng rung rinh bay bổng vi mô (Subtle Flutter)
public final class SubtleFlutterStickerMotionEffect: StickerMotionEffect {

    public var name: String { "subtleFlutter" }

    public init() {}

    public func startIdle(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")

        let jiggle1 = SKAction.rotate(byAngle: 0.025, duration: 0.8)
        let jiggle2 = SKAction.rotate(byAngle: -0.050, duration: 1.2)
        let jiggle3 = SKAction.rotate(byAngle: 0.025, duration: 0.8)
        let loop = SKAction.sequence([jiggle1, jiggle2, jiggle3])
        node.run(SKAction.repeatForever(loop), withKey: "sticker_idle_action")
    }

    public func stopIdle(context: StickerMotionContext) {
        context.targetNode.removeAction(forKey: "sticker_idle_action")
    }

    public func apply(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_tap_action")

        let j1 = SKAction.rotate(toAngle: 0.08, duration: 0.08)
        let j2 = SKAction.rotate(toAngle: -0.07, duration: 0.09)
        let j3 = SKAction.rotate(toAngle: 0.05, duration: 0.10)
        let j4 = SKAction.rotate(toAngle: 0.0, duration: 0.12)

        let resume = SKAction.run { [weak self] in
            self?.startIdle(context: context)
            context.onComplete?()
        }

        node.run(SKAction.sequence([j1, j2, j3, j4, resume]), withKey: "sticker_tap_action")
    }
}

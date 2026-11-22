//
//  StandardBounceStickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng nảy lò xo Squash & Stretch tiêu chuẩn cho Sticker để bàn hoặc dán tường
public final class StandardBounceStickerMotionEffect: StickerMotionEffect {

    public var name: String { "standardBounce" }

    public init() {}

    public func apply(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")
        node.removeAction(forKey: "sticker_idle_drift")
        node.removeAction(forKey: "sticker_tap_action")

        // 1. Squash nén xuống
        let squashX = SKAction.scaleX(to: 1.10, duration: 0.12)
        let squashY = SKAction.scaleY(to: 0.90, duration: 0.12)
        squashX.timingMode = .easeOut
        squashY.timingMode = .easeOut
        let squash = SKAction.group([squashX, squashY])

        // 2. Stretch bật lên
        let stretchX = SKAction.scaleX(to: 0.95, duration: 0.15)
        let stretchY = SKAction.scaleY(to: 1.07, duration: 0.15)
        stretchX.timingMode = .easeInEaseOut
        stretchY.timingMode = .easeInEaseOut
        let stretch = SKAction.group([stretchX, stretchY])

        // 3. Trả về kích thước gốc
        let normalX = SKAction.scaleX(to: 1.0, duration: 0.18)
        let normalY = SKAction.scaleY(to: 1.0, duration: 0.18)
        normalX.timingMode = .easeInEaseOut
        normalY.timingMode = .easeInEaseOut
        let normal = SKAction.group([normalX, normalY])

        let completion = SKAction.run {
            context.onComplete?()
        }

        node.run(SKAction.sequence([squash, stretch, normal, completion]), withKey: "sticker_tap_action")
    }
}

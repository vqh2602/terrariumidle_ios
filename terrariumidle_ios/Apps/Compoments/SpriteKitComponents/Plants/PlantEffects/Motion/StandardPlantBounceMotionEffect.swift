//
//  StandardPlantBounceMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap cây bản gốc: Nén nảy Squash & Stretch lò xo đàn hồi + Gợn sóng lan tỏa qua phiến lá
public final class StandardPlantBounceMotionEffect: PlantMotionEffect {

    public var name: String { "StandardPlantBounce" }

    public var bounceIntensity: CGFloat
    public var durationMultiplier: Double

    public init(bounceIntensity: CGFloat = 1.0, durationMultiplier: Double = 1.0) {
        self.bounceIntensity = bounceIntensity
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PlantMotionContext) {
        switch context.level {
        case 1:
            applySeedMotion(context: context)
        case 2:
            applySproutMotion(context: context)
        default:
            applyMatureMotion(context: context)
        }
    }

    // MARK: - Level 1: Hạt Giống

    private func applySeedMotion(context: PlantMotionContext) {
        guard let node = context.seedNode else {
            context.onComplete?()
            return
        }

        let mult = max(0.1, durationMultiplier)
        node.removeAction(forKey: "seedTapHop")
        node.position = context.initialSeedPosition

        let squash = SKAction.scaleX(to: 1.28, y: 0.72, duration: 0.08 * mult)
        squash.timingMode = .easeIn

        let jumpUp = SKAction.group([
            SKAction.moveTo(y: context.initialSeedPosition.y + 10, duration: 0.12 * mult),
            SKAction.scaleX(to: 0.85, y: 1.20, duration: 0.12 * mult)
        ])
        jumpUp.timingMode = .easeOut

        let fallDown = SKAction.group([
            SKAction.moveTo(y: context.initialSeedPosition.y, duration: 0.12 * mult),
            SKAction.scaleX(to: 1.12, y: 0.90, duration: 0.12 * mult)
        ])
        fallDown.timingMode = .easeIn

        let settle = SKAction.scale(to: 1.0, duration: 0.10 * mult)
        settle.timingMode = .easeInEaseOut

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        node.run(SKAction.sequence([squash, jumpUp, fallDown, settle, completionAction]), withKey: "seedTapHop")

        // Hào quang bừng sáng
        if let glow = node.childNode(withName: "seedGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.08 * mult),
                SKAction.fadeAlpha(to: 0.28, duration: 0.25 * mult)
            ])
            glow.run(flash)
        }
    }

    // MARK: - Level 2: Cây Con / Lá Mầm

    private func applySproutMotion(context: PlantMotionContext) {
        guard let node = context.sproutNode else {
            context.onComplete?()
            return
        }

        let mult = max(0.1, durationMultiplier)
        node.removeAction(forKey: "sproutTapBounce")
        node.position = context.initialSproutPosition
        node.zRotation = 0

        // 1. Nén nhún đàn hồi lò xo
        let squash = SKAction.scaleX(to: 1.26, y: 0.74, duration: 0.08 * mult)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: 0.84, y: 1.22, duration: 0.12 * mult)
        stretch.timingMode = .easeOut
        let bounceBack = SKAction.scaleX(to: 1.08, y: 0.94, duration: 0.10 * mult)
        let settle = SKAction.scale(to: 1.0, duration: 0.12 * mult)
        settle.timingMode = .easeInEaseOut

        // 2. Rung lắc 2 lá mầm
        let shakeL = SKAction.rotate(toAngle: -0.15, duration: 0.07 * mult)
        let shakeR = SKAction.rotate(toAngle: 0.15, duration: 0.08 * mult)
        let shakeBack = SKAction.rotate(toAngle: 0, duration: 0.07 * mult)
        let shakeSeq = SKAction.sequence([shakeL, shakeR, shakeBack])

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        let combined = SKAction.group([
            SKAction.sequence([squash, stretch, bounceBack, settle, completionAction]),
            shakeSeq
        ])

        node.run(combined, withKey: "sproutTapBounce")

        // Hào quang sinh trưởng bừng sáng
        if let glow = node.childNode(withName: "sproutGlowNode") {
            let flash = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.75, duration: 0.08 * mult),
                SKAction.fadeAlpha(to: 0.22, duration: 0.28 * mult)
            ])
            glow.run(flash)
        }
    }

    // MARK: - Level 3+: Cây Trưởng Thành

    private func applyMatureMotion(context: PlantMotionContext) {
        let mult = max(0.1, durationMultiplier)
        let baseScale = context.baseScale
        let root = context.plantRootNode

        root.removeAction(forKey: "matureTapBounce")

        // 1. Squash & Stretch cả cây đàn hồi lò xo
        let squashScaleX = baseScale * (1.0 + 0.15 * bounceIntensity)
        let squashScaleY = baseScale * (1.0 - 0.14 * bounceIntensity)
        let stretchScaleX = baseScale * (1.0 - 0.10 * bounceIntensity)
        let stretchScaleY = baseScale * (1.0 + 0.14 * bounceIntensity)
        let bounceScaleX = baseScale * (1.0 + 0.05 * bounceIntensity)
        let bounceScaleY = baseScale * (1.0 - 0.04 * bounceIntensity)

        let squash = SKAction.scaleX(to: squashScaleX, y: squashScaleY, duration: 0.08 * mult)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: stretchScaleX, y: stretchScaleY, duration: 0.12 * mult)
        stretch.timingMode = .easeOut
        let bounce = SKAction.scaleX(to: bounceScaleX, y: bounceScaleY, duration: 0.10 * mult)
        let settle = SKAction.scale(to: baseScale, duration: 0.10 * mult)
        settle.timingMode = .easeInEaseOut

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        root.run(SKAction.sequence([squash, stretch, bounce, settle, completionAction]), withKey: "matureTapBounce")

        // 2. Gợn sóng xao động lan tỏa qua các phiến lá
        for (idx, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "leafTapJiggle")
            let isLeft = leaf.position.x < 0
            let impulseAngle: CGFloat = (isLeft ? -1.0 : 1.0) * CGFloat.random(in: 0.08...0.12) * bounceIntensity

            let delay = SKAction.wait(forDuration: Double(idx) * 0.02 * mult)
            let jiggleOut = SKAction.rotate(byAngle: impulseAngle, duration: 0.08 * mult)
            jiggleOut.timingMode = .easeOut
            let jiggleBack = SKAction.rotate(byAngle: -impulseAngle, duration: 0.12 * mult)
            jiggleBack.timingMode = .easeInEaseOut

            leaf.run(SKAction.sequence([delay, jiggleOut, jiggleBack]), withKey: "leafTapJiggle")
        }
    }
}

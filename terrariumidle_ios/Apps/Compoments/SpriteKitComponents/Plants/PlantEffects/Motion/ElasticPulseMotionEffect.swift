//
//  ElasticPulseMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap cây bản mới: Nhún nảy đàn hồi tần số nhanh (Dành cho sen đá, xương rồng thân mọng nước)
public final class ElasticPulseMotionEffect: PlantMotionEffect {

    public var name: String { "ElasticPulse" }

    public var pulseScale: CGFloat
    public var durationMultiplier: Double

    public init(pulseScale: CGFloat = 1.08, durationMultiplier: Double = 1.0) {
        self.pulseScale = pulseScale
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PlantMotionContext) {
        let mult = max(0.1, durationMultiplier)
        let baseScale = context.baseScale
        let root = context.plantRootNode

        root.removeAction(forKey: "plantPulseTap")

        let p1 = SKAction.scale(to: baseScale * pulseScale, duration: 0.08 * mult)
        p1.timingMode = .easeOut
        let p2 = SKAction.scale(to: baseScale * (1.0 - (pulseScale - 1.0) * 0.5), duration: 0.10 * mult)
        p2.timingMode = .easeInEaseOut
        let p3 = SKAction.scale(to: baseScale, duration: 0.08 * mult)
        p3.timingMode = .easeOut

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        root.run(SKAction.sequence([p1, p2, p3, completionAction]), withKey: "plantPulseTap")

        // Rung nhẹ các lá xung quanh
        for (idx, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "leafPulseJiggle")
            let delay = SKAction.wait(forDuration: Double(idx) * 0.015 * mult)
            let jiggle = SKAction.sequence([
                delay,
                SKAction.scale(to: 1.05, duration: 0.06 * mult),
                SKAction.scale(to: 1.0, duration: 0.08 * mult)
            ])
            leaf.run(jiggle, withKey: "leafPulseJiggle")
        }
    }
}

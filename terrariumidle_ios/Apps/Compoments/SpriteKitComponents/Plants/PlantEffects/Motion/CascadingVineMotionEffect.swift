//
//  CascadingVineMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap cây bản mới: Dây leo buông rủ đung đưa theo chuỗi sóng cascading (Dành cho cây leo, chậu treo)
public final class CascadingVineMotionEffect: PlantMotionEffect {

    public var name: String { "CascadingVine" }

    public var waveAngle: CGFloat
    public var durationMultiplier: Double

    public init(waveAngle: CGFloat = 0.09, durationMultiplier: Double = 1.0) {
        self.waveAngle = waveAngle
        self.durationMultiplier = durationMultiplier
    }

    public func apply(context: PlantMotionContext) {
        let mult = max(0.1, durationMultiplier)

        // Nếu là hạt hoặc mầm: fallback sang nảy nhẹ
        if context.level <= 2 {
            let standard = StandardPlantBounceMotionEffect(bounceIntensity: 0.8, durationMultiplier: mult)
            standard.apply(context: context)
            return
        }

        let root = context.plantRootNode
        root.removeAction(forKey: "vineTapRoot")

        // Gốc cành chỉ đung đưa nhẹ quanh miệng chậu
        let rootSway1 = SKAction.rotate(toAngle: waveAngle * 0.35, duration: 0.20 * mult)
        rootSway1.timingMode = .easeOut
        let rootSway2 = SKAction.rotate(toAngle: -waveAngle * 0.25, duration: 0.26 * mult)
        rootSway2.timingMode = .easeInEaseOut
        let rootSwayRest = SKAction.rotate(toAngle: 0.0, duration: 0.22 * mult)
        rootSwayRest.timingMode = .easeOut

        let completionAction = SKAction.run {
            context.onComplete?()
        }

        root.run(SKAction.sequence([rootSway1, rootSway2, rootSwayRest, completionAction]), withKey: "vineTapRoot")

        // Chuỗi dây leo / phiến lá đung đưa lan truyền từ trên xuống dưới
        for (idx, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "vineLeafWave")

            let delay = SKAction.wait(forDuration: Double(idx) * 0.035 * mult)
            let dir: CGFloat = (idx % 2 == 0) ? 1.0 : -0.8
            let s1 = SKAction.rotate(byAngle: waveAngle * dir, duration: 0.20 * mult)
            s1.timingMode = .easeOut
            let s2 = SKAction.rotate(byAngle: -waveAngle * dir * 1.3, duration: 0.28 * mult)
            s2.timingMode = .easeInEaseOut
            let s3 = SKAction.rotate(byAngle: waveAngle * dir * 0.5, duration: 0.22 * mult)
            s3.timingMode = .easeInEaseOut
            let sRest = SKAction.rotate(toAngle: 0.0, duration: 0.18 * mult)
            sRest.timingMode = .easeOut

            leaf.run(SKAction.sequence([delay, s1, s2, s3, sRest]), withKey: "vineLeafWave")
        }
    }
}

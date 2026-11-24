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

        // 1. Tạm dừng/gỡ bỏ toàn bộ action chuyển động nhàn rỗi (idle) trên thân và các phiến lá
        // để triệt tiêu hoàn toàn xung đột zRotation/scale gây co giật cây khi bấm tap
        context.stopIdleActions()

        // Nếu là hạt hoặc mầm: fallback sang nảy nhẹ
        if context.level <= 2 {
            let standard = StandardPlantBounceMotionEffect(bounceIntensity: 0.8, durationMultiplier: mult)
            standard.apply(context: context)
            return
        }

        let root = context.plantRootNode
        root.removeAction(forKey: "vineTapRoot")
        root.zRotation = 0.0
        root.setScale(context.baseScale)

        // Tính toán tổng thời gian diễn hoạt của toàn bộ cây (thân + các phiến lá cascading)
        let rootMotionDuration = (0.20 + 0.26 + 0.22) * mult // 0.68 * mult
        let maxLeafDelay = Double(max(0, context.leafNodes.count - 1)) * 0.035 * mult
        let leafMotionDuration = (0.20 + 0.28 + 0.22 + 0.18) * mult // 0.88 * mult
        let totalLeafDuration = maxLeafDelay + leafMotionDuration
        let totalDuration = max(rootMotionDuration, totalLeafDuration)

        // Gốc cành chỉ đung đưa nhẹ quanh miệng chậu rồi nghỉ tại 0.0
        let rootSway1 = SKAction.rotate(toAngle: waveAngle * 0.35, duration: 0.20 * mult)
        rootSway1.timingMode = .easeOut
        let rootSway2 = SKAction.rotate(toAngle: -waveAngle * 0.25, duration: 0.26 * mult)
        rootSway2.timingMode = .easeInEaseOut
        let rootSwayRest = SKAction.rotate(toAngle: 0.0, duration: 0.22 * mult)
        rootSwayRest.timingMode = .easeOut

        var rootActions: [SKAction] = [rootSway1, rootSway2, rootSwayRest]
        if totalDuration > rootMotionDuration {
            rootActions.append(SKAction.wait(forDuration: totalDuration - rootMotionDuration))
        }

        let completionAction = SKAction.run {
            // Khi toàn bộ thân và lá đã trở về trạng thái nghỉ tuyệt đối -> Khôi phục nhịp gió nhàn rỗi
            if let onComplete = context.onComplete {
                onComplete()
            } else {
                (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            }
        }
        rootActions.append(completionAction)

        root.run(SKAction.sequence(rootActions), withKey: "vineTapRoot")

        // Chuỗi dây leo / phiến lá đung đưa lan truyền từ trên xuống dưới
        for (idx, leaf) in context.leafNodes.enumerated() {
            leaf.removeAction(forKey: "vineLeafWave")
            leaf.removeAction(forKey: "crownTapBounce")
            let restAngle = leaf.restZRotation
            leaf.zRotation = restAngle // Triệt tiêu tức thì góc xoay trôi dạt do ngắt action trước

            // Nếu là cụm tán / lá cắm trên miệng chậu (anchor gần đáy, không buông rủ):
            // Thực hiện nảy nhẹ Squash & Stretch đàn hồi thay vì xoay nghiêng làm bật khỏi miệng chậu
            let isCrown = ((leaf as? SKSpriteNode)?.anchorPoint.y ?? 0.0) < 0.25
            if isCrown {
                let squash = SKAction.scaleX(to: 1.05, y: 0.94, duration: 0.10 * mult)
                squash.timingMode = .easeOut
                let stretch = SKAction.scaleX(to: 0.98, y: 1.04, duration: 0.14 * mult)
                stretch.timingMode = .easeOut
                let settle = SKAction.scale(to: 1.0, duration: 0.12 * mult)
                settle.timingMode = .easeInEaseOut
                leaf.run(SKAction.sequence([squash, stretch, settle]), withKey: "crownTapBounce")
                continue
            }

            let delay = SKAction.wait(forDuration: Double(idx) * 0.035 * mult)
            let dir: CGFloat = (idx % 2 == 0) ? 1.0 : -0.8
            let s1 = SKAction.rotate(toAngle: restAngle + waveAngle * dir, duration: 0.20 * mult)
            s1.timingMode = .easeOut
            let s2 = SKAction.rotate(toAngle: restAngle - waveAngle * dir * 0.5, duration: 0.28 * mult)
            s2.timingMode = .easeInEaseOut
            let s3 = SKAction.rotate(toAngle: restAngle + waveAngle * dir * 0.2, duration: 0.22 * mult)
            s3.timingMode = .easeInEaseOut
            let sRest = SKAction.rotate(toAngle: restAngle, duration: 0.18 * mult)
            sRest.timingMode = .easeOut
            let resetEnd = SKAction.run { [weak leaf] in
                leaf?.zRotation = restAngle
            }

            leaf.run(SKAction.sequence([delay, s1, s2, s3, sRest, resetEnd]), withKey: "vineLeafWave")
        }
    }
}

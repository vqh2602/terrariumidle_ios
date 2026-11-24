//
//  ConnectedPlantSwayMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Cây có thân/cành ghép liền hoa/khối (như Xương rồng thùng hồng Plant25, Xương rồng trụ xoắn Plant29):
/// Kết hợp Squash & Stretch lò xo nén nảy và lắc lư con lắc đàn hồi trên toàn khối thống nhất,
/// giữ trọn vẹn mọi điểm tiếp giáp cuống lá / múi thân không bị hở khớp, đồng thời kích hoạt phản xạ nhún phụ trên hoa/nụ.
public final class ConnectedPlantSwayMotionEffect: PlantMotionEffect {
    public var name: String { "ConnectedPlantSway" }

    /// Góc nghiêng lắc lư chính quanh gốc cây (rad)
    public var swayAngle: CGFloat
    /// Hệ số co giãn đàn hồi nén nảy lò xo Squash & Stretch (mặc định 1.12)
    public var bounceScale: CGFloat
    /// Hệ số co giãn thời lượng chuyển động (mặc định 1.0)
    public var durationMultiplier: Double
    /// Danh sách tên node hoa hoặc nụ gắn trên đỉnh để tạo phản xạ nhún phụ đàn hồi (secondary spring)
    public var flowerNodeNames: [String]

    public init(
        swayAngle: CGFloat = 0.048,
        bounceScale: CGFloat = 1.12,
        durationMultiplier: Double = 1.0,
        flowerNodeNames: [String] = []
    ) {
        self.swayAngle = swayAngle
        self.bounceScale = bounceScale
        self.durationMultiplier = durationMultiplier
        self.flowerNodeNames = flowerNodeNames
    }

    public func apply(context: PlantMotionContext) {
        context.stopIdleActions()

        // Đối với hạt giống (Lv.1) và cây con (Lv.2), ưu tiên hiệu ứng nhảy nảy mầm bừng sáng tiêu chuẩn
        guard context.level > 2 else {
            StandardPlantBounceMotionEffect(durationMultiplier: durationMultiplier).apply(context: context)
            return
        }

        let mult = max(0.1, durationMultiplier)
        let baseScale = context.baseScale
        let root = context.plantRootNode

        root.removeAction(forKey: "connectedPlantTap")
        root.zRotation = 0
        root.setScale(baseScale)

        // 1. Squash & Stretch cả cây đàn hồi lò xo (chạy trên plantRootNode để mọi bộ phận biến đổi đồng nhất)
        let squashX = baseScale * (1.0 + (bounceScale - 1.0) * 1.15)
        let squashY = baseScale * (1.0 - (bounceScale - 1.0) * 0.95)
        let stretchX = baseScale * (1.0 - (bounceScale - 1.0) * 0.60)
        let stretchY = baseScale * (1.0 + (bounceScale - 1.0) * 0.90)
        let reboundX = baseScale * (1.0 + (bounceScale - 1.0) * 0.30)
        let reboundY = baseScale * (1.0 - (bounceScale - 1.0) * 0.20)

        let s1 = SKAction.scaleX(to: squashX, y: squashY, duration: 0.08 * mult)
        s1.timingMode = .easeIn
        let s2 = SKAction.scaleX(to: stretchX, y: stretchY, duration: 0.12 * mult)
        s2.timingMode = .easeOut
        let s3 = SKAction.scaleX(to: reboundX, y: reboundY, duration: 0.10 * mult)
        s3.timingMode = .easeInEaseOut
        let s4 = SKAction.scale(to: baseScale, duration: 0.10 * mult)
        s4.timingMode = .easeInEaseOut
        let scaleSeq = SKAction.sequence([s1, s2, s3, s4])

        // 2. Chuyển động nghiêng lắc lư con lắc đàn hồi quanh gốc
        func rotation(_ angle: CGFloat, _ duration: TimeInterval, mode: SKActionTimingMode = .easeInEaseOut) -> SKAction {
            let action = SKAction.rotate(toAngle: angle, duration: duration)
            action.timingMode = mode
            return action
        }

        let r1 = rotation(swayAngle, 0.09 * mult, mode: .easeOut)
        let r2 = rotation(-swayAngle * 0.60, 0.12 * mult)
        let r3 = rotation(swayAngle * 0.22, 0.10 * mult)
        let r4 = rotation(0, 0.09 * mult)
        let swaySeq = SKAction.sequence([r1, r2, r3, r4])

        // Kết hợp đồng bộ nén nảy và lắc lư
        let combinedRootMotion = SKAction.group([scaleSeq, swaySeq])

        let completionAction = SKAction.run { [weak root] in
            root?.zRotation = 0
            root?.setScale(baseScale)
            (context.plantNode as? PlantInteractiveNode)?.resumeIdleAnimation()
            context.onComplete?()
        }

        root.run(SKAction.sequence([combinedRootMotion, completionAction]), withKey: "connectedPlantTap")

        // 3. Phản ứng nhún phụ (Secondary Spring Nod) trên các node hoa/nụ trên đỉnh nếu được chỉ định
        for leaf in context.leafNodes {
            guard let name = leaf.name, flowerNodeNames.contains(name) else { continue }
            leaf.removeAction(forKey: "flowerTapBounce")
            let restAngle = leaf.restZRotation
            leaf.zRotation = restAngle

            let nod1 = rotation(restAngle + 0.12, 0.09 * mult, mode: .easeOut)
            let nod2 = rotation(restAngle - 0.08, 0.12 * mult)
            let nod3 = rotation(restAngle + 0.03, 0.10 * mult)
            let nodBack = rotation(restAngle, 0.09 * mult)
            let resetEnd = SKAction.run { [weak leaf] in
                leaf?.zRotation = restAngle
            }

            leaf.run(SKAction.sequence([nod1, nod2, nod3, nodBack, resetEnd]), withKey: "flowerTapBounce")
        }
    }
}

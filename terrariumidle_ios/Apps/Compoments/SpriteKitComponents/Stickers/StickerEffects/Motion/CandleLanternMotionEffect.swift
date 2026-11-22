//
//  CandleLanternMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Chuyển Động Chuyên Biệt cho Đèn Lồng Thắp Sáng (Candle Lantern - Sticker4)
/// - **Mô hình**: Đèn để bàn đứng thẳng vững chãi trên kệ
/// - **Nhàn rỗi (Idle)**:
///   * Thân đèn đứng yên thẳng thớm, không nghiêng ngả trái phải (zRotation = 0).
///   * Ngọn lửa nến bên trong buồng kính bập bùng chớp sáng ấm áp liên tục.
/// - **Khi Chạm (Tap - Nhún nảy từ trên xuống)**:
///   * Chuyển động Squash & Stretch đàn hồi thuần túy theo trục dọc Y (nén từ trên dập xuống rồi bật nẩy lên):
///     + Nhịp 1: Nén từ trên xuống (Squash): scaleY = 0.90, scaleX = 1.07 (0.12s)
///     + Nhịp 2: Nảy bật lên cao (Stretch): scaleY = 1.08, scaleX = 0.94 (0.16s)
///     + Nhịp 3: Nhún nén nhẹ: scaleY = 0.96, scaleX = 1.03 (0.14s)
///     + Nhịp 4: Nảy nhẹ: scaleY = 1.02, scaleX = 0.98 (0.15s)
///     + Nhịp 5: Khôi phục chuẩn: scale = 1.0 (0.15s)
///   * Tuyệt đối KHÔNG lắc lư hay nghiêng ngả trái phải.
public final class CandleLanternMotionEffect: StickerMotionEffect {

    public var name: String { "candleLantern" }

    public init() {}

    public func startIdle(context: StickerMotionContext) {
        stopIdle(context: context)

        let rig = context.targetNode
        rig.zRotation = 0
        rig.xScale = 1.0
        rig.yScale = 1.0

        // 1. Thân đèn đứng yên vững chãi trên sàn kệ (zRotation = 0, không lắc lư trái phải)

        // 2. Ngọn lửa nến bên trong bập bùng ấm áp liên tục (nếu có node flame)
        if let flameNode = context.frontDecorations.first {
            flameNode.removeAction(forKey: "candle_flame_flicker")
            let flicker1 = SKAction.fadeAlpha(to: 0.70, duration: 0.22)
            let flicker2 = SKAction.fadeAlpha(to: 0.98, duration: 0.32)
            let flicker3 = SKAction.fadeAlpha(to: 0.78, duration: 0.18)
            let flicker4 = SKAction.fadeAlpha(to: 1.0, duration: 0.38)
            let flickerCycle = SKAction.sequence([flicker1, flicker2, flicker3, flicker4])
            flameNode.run(SKAction.repeatForever(flickerCycle), withKey: "candle_flame_flicker")
        }
    }

    public func stopIdle(context: StickerMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "lantern_vertical_bounce")
        rig.zRotation = 0
        rig.xScale = 1.0
        rig.yScale = 1.0

        if let flameNode = context.frontDecorations.first {
            flameNode.removeAction(forKey: "candle_flame_flicker")
            flameNode.alpha = 1.0
        }
    }

    public func apply(context: StickerMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "lantern_vertical_bounce")
        rig.zRotation = 0 // Giữ thẳng đứng 100%, không nghiêng trái phải

        // Chuyển động NHÚN NẢY TỪ TRÊN XUỐNG (Vertical Bounce / Squash & Stretch)
        // 1. Nén từ trên xuống sàn kệ
        let squash1 = SKAction.group([
            SKAction.scaleY(to: 0.88, duration: 0.12),
            SKAction.scaleX(to: 1.08, duration: 0.12)
        ])
        squash1.timingMode = .easeOut

        // 2. Bật nẩy vọt lên cao
        let stretch1 = SKAction.group([
            SKAction.scaleY(to: 1.09, duration: 0.16),
            SKAction.scaleX(to: 0.93, duration: 0.16)
        ])
        stretch1.timingMode = .easeOut

        // 3. Nhún nén lại nhẹ
        let squash2 = SKAction.group([
            SKAction.scaleY(to: 0.96, duration: 0.14),
            SKAction.scaleX(to: 1.03, duration: 0.14)
        ])
        squash2.timingMode = .easeInEaseOut

        // 4. Nảy nhẹ đàn hồi
        let stretch2 = SKAction.group([
            SKAction.scaleY(to: 1.02, duration: 0.15),
            SKAction.scaleX(to: 0.98, duration: 0.15)
        ])
        stretch2.timingMode = .easeInEaseOut

        // 5. Khôi phục trạng thái tĩnh ban đầu
        let restoreScale = SKAction.group([
            SKAction.scaleY(to: 1.0, duration: 0.15),
            SKAction.scaleX(to: 1.0, duration: 0.15)
        ])
        restoreScale.timingMode = .easeInEaseOut

        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.startIdle(context: context)
            context.onComplete?()
        }

        rig.run(SKAction.sequence([
            squash1, stretch1, squash2, stretch2, restoreScale, restore
        ]), withKey: "lantern_vertical_bounce")
    }
}

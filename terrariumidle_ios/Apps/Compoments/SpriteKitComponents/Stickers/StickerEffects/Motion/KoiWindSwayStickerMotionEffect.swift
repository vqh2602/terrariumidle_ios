//
//  KoiWindSwayStickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Chuyển Động Chuyên Biệt cho Đèn Cá Chép (Koi Windsock Lantern - Sticker3)
/// - **Nhàn rỗi (Idle - Gió lúc mạnh lúc nhẹ)**:
///   * Chu kỳ gió đa tầng biến thiên: lúc gió thoảng êm đềm (`±0.035 rad`),
///     lúc có cơn gió mạnh tạt qua khiến đèn cá đu đưa dồn dập (`±0.092 rad`),
///     sau đó gió dịu dần trở lại nhịp êm ả tự nhiên.
///   * Thân các chú cá (`fishNode`) có độ trễ uốn lượn mềm mại như cờ vải lụa bay trong gió.
/// - **Khi Chạm (Tap)**:
///   * Dao động con lắc biên độ lớn (`±0.15 rad` ~ 8.6°) tắt dần qua 4 nhịp mượt mà.
public final class KoiWindSwayStickerMotionEffect: StickerMotionEffect {

    public var name: String { "koiWindSway" }

    public init() {}

    public func startIdle(context: StickerMotionContext) {
        stopIdle(context: context)

        let rig = context.targetNode
        rig.zRotation = 0

        // ==========================================
        // 1. Chu kỳ Gió Biến Thiên (Lúc Mạnh Lúc Nhẹ)
        // ==========================================

        // Pha 1: Gió thoảng nhẹ (Calm Breeze)
        let gentleLeft = SKAction.rotate(toAngle: -0.035, duration: 1.2)
        gentleLeft.timingMode = .easeInEaseOut
        let gentleRight = SKAction.rotate(toAngle: 0.032, duration: 1.1)
        gentleRight.timingMode = .easeInEaseOut
        let gentleCenter = SKAction.rotate(toAngle: 0.0, duration: 1.0)
        gentleCenter.timingMode = .easeInEaseOut
        let breezePhase = SKAction.sequence([gentleLeft, gentleRight, gentleLeft, gentleCenter])

        // Pha 2: Cơn gió mạnh tạt qua (Gust of Wind)
        let gustLeft = SKAction.rotate(toAngle: 0.092, duration: 0.55)
        gustLeft.timingMode = .easeOut
        let gustRight = SKAction.rotate(toAngle: -0.085, duration: 0.60)
        gustRight.timingMode = .easeInEaseOut
        let gustSwing2 = SKAction.rotate(toAngle: 0.070, duration: 0.65)
        gustSwing2.timingMode = .easeInEaseOut
        let gustSwing3 = SKAction.rotate(toAngle: -0.055, duration: 0.70)
        gustSwing3.timingMode = .easeInEaseOut
        let gustPhase = SKAction.sequence([gustLeft, gustRight, gustSwing2, gustSwing3])

        // Pha 3: Gió dịu dần (Diminishing Lull)
        let calmSway1 = SKAction.rotate(toAngle: 0.040, duration: 0.90)
        calmSway1.timingMode = .easeInEaseOut
        let calmSway2 = SKAction.rotate(toAngle: -0.030, duration: 0.95)
        calmSway2.timingMode = .easeInEaseOut
        let calmCenter = SKAction.rotate(toAngle: 0.0, duration: 1.0)
        calmCenter.timingMode = .easeInEaseOut
        let lullPhase = SKAction.sequence([calmSway1, calmSway2, calmCenter])

        // Vòng lặp tuần hoàn gió tự nhiên
        let fullWindCycle = SKAction.sequence([
            breezePhase,
            SKAction.wait(forDuration: 0.4),
            gustPhase,
            SKAction.wait(forDuration: 0.2),
            lullPhase,
            SKAction.wait(forDuration: 0.5)
        ])
        rig.run(SKAction.repeatForever(fullWindCycle), withKey: "koi_rig_wind_cycle")

        // 2. Thân các chú cá uốn lượn phấp phới nhẹ (Fish wave ripple)
        if let fishNode = context.bodyNode {
            fishNode.removeAction(forKey: "koi_fish_ripple")
            let waveLeft = SKAction.rotate(toAngle: -0.025, duration: 0.85)
            waveLeft.timingMode = .easeInEaseOut
            let waveRight = SKAction.rotate(toAngle: 0.028, duration: 0.90)
            waveRight.timingMode = .easeInEaseOut
            let rippleCycle = SKAction.sequence([waveLeft, waveRight])
            fishNode.run(SKAction.repeatForever(rippleCycle), withKey: "koi_fish_ripple")
        }
    }

    public func stopIdle(context: StickerMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "koi_rig_wind_cycle")
        rig.removeAction(forKey: "koi_rig_tap_swing")
        rig.zRotation = 0

        if let fishNode = context.bodyNode {
            fishNode.removeAction(forKey: "koi_fish_ripple")
            fishNode.zRotation = 0
        }
    }

    public func apply(context: StickerMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "koi_rig_wind_cycle")
        rig.removeAction(forKey: "koi_rig_tap_swing")

        // Dao động con lắc biên độ lớn tắt dần
        let swing1 = SKAction.rotate(toAngle: 0.155, duration: 0.35)
        swing1.timingMode = .easeOut
        let swing2 = SKAction.rotate(toAngle: -0.115, duration: 0.45)
        swing2.timingMode = .easeInEaseOut
        let swing3 = SKAction.rotate(toAngle: 0.075, duration: 0.55)
        swing3.timingMode = .easeInEaseOut
        let swing4 = SKAction.rotate(toAngle: -0.040, duration: 0.65)
        swing4.timingMode = .easeInEaseOut
        let swingCenter = SKAction.rotate(toAngle: 0.0, duration: 0.70)
        swingCenter.timingMode = .easeInEaseOut

        let restoreWind = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.startIdle(context: context)
            context.onComplete?()
        }

        rig.run(SKAction.sequence([
            swing1, swing2, swing3, swing4, swingCenter, restoreWind
        ]), withKey: "koi_rig_tap_swing")
    }
}

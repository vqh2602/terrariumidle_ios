//
//  WindSwayStickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động đung đưa theo gió tự nhiên cho Sticker treo (Wind Sway)
/// - **Nhàn rỗi (Idle)**: Tự động đung đưa con lắc quanh đỉnh móc treo theo làn gió mềm mại,
///   kết hợp trôi bồng bềnh trục Y và rung rinh dải nơ ruy băng trước ngực.
/// - **Khi chạm (Tap)**: Đu đưa mạnh mẽ biên độ lớn (0.16 rad ~ 9.2°), dao động 4 nhịp tắt dần mượt mà,
///   sau đó tự động hòa nhập trở lại nhịp đung đưa gió tự nhiên mà không bị khựng lại.
public final class WindSwayStickerMotionEffect: StickerMotionEffect {

    public var name: String { "windSway" }

    public init() {}

    // MARK: - Start Idle Wind Sway

    public func startIdle(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")
        node.removeAction(forKey: "sticker_idle_drift")

        // 1. Con lắc gió tự nhiên (Sinusoidal Gentle Sway)
        let swingLeft = SKAction.rotate(toAngle: -0.048, duration: 2.1)
        swingLeft.timingMode = .easeInEaseOut

        let swingRight = SKAction.rotate(toAngle: 0.044, duration: 2.3)
        swingRight.timingMode = .easeInEaseOut

        let swingCenter = SKAction.rotate(toAngle: -0.020, duration: 1.8)
        swingCenter.timingMode = .easeInEaseOut

        let swingReturn = SKAction.rotate(toAngle: 0.038, duration: 2.0)
        swingReturn.timingMode = .easeInEaseOut

        let idleSequence = SKAction.sequence([swingLeft, swingRight, swingCenter, swingReturn])
        node.run(SKAction.repeatForever(idleSequence), withKey: "sticker_idle_action")

        // 2. Độ nhấp nhô trôi nổi bồng bềnh trục Y (Breeze Vertical Drift)
        let floatUp = SKAction.moveBy(x: 0, y: 2.2, duration: 1.7)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -2.2, duration: 1.7)
        floatDown.timingMode = .easeInEaseOut

        let driftSequence = SKAction.sequence([floatUp, floatDown])
        node.run(SKAction.repeatForever(driftSequence), withKey: "sticker_idle_drift")

        // 3. Rung rinh các dải nơ / chi tiết trang trí phía trước (Front Ribbon Flutter)
        for (index, decor) in context.frontDecorations.enumerated() {
            decor.removeAction(forKey: "ribbon_idle_flutter")
            let phaseDelay = Double(index) * 0.35
            let angle: CGFloat = (index % 2 == 0) ? 0.055 : -0.050

            let flutterOut = SKAction.rotate(byAngle: angle, duration: 1.4 + phaseDelay * 0.5)
            flutterOut.timingMode = .easeInEaseOut
            let flutterBack = SKAction.rotate(byAngle: -angle, duration: 1.4 + phaseDelay * 0.5)
            flutterBack.timingMode = .easeInEaseOut

            let ribbonLoop = SKAction.sequence([flutterOut, flutterBack])
            decor.run(SKAction.repeatForever(ribbonLoop), withKey: "ribbon_idle_flutter")
        }
    }

    // MARK: - Stop Idle Wind Sway

    public func stopIdle(context: StickerMotionContext) {
        context.targetNode.removeAction(forKey: "sticker_idle_action")
        context.targetNode.removeAction(forKey: "sticker_idle_drift")
        for decor in context.frontDecorations {
            decor.removeAction(forKey: "ribbon_idle_flutter")
        }
    }

    // MARK: - Apply Tap Motion

    public func apply(context: StickerMotionContext) {
        let node = context.targetNode
        node.removeAction(forKey: "sticker_idle_action")
        node.removeAction(forKey: "sticker_idle_drift")
        node.removeAction(forKey: "sticker_tap_action")

        // Dao động con lắc biên độ lớn tắt dần khi tap
        // Nhịp 1: Lắc mạnh sang phải kèm nén nhún nhẹ
        let swing1 = SKAction.rotate(toAngle: 0.160, duration: 0.22)
        swing1.timingMode = .easeOut

        // Nhịp 2: Bật ngược sang trái
        let swing2 = SKAction.rotate(toAngle: -0.125, duration: 0.26)
        swing2.timingMode = .easeInEaseOut

        // Nhịp 3: Đảo lại sang phải vừa phải
        let swing3 = SKAction.rotate(toAngle: 0.075, duration: 0.28)
        swing3.timingMode = .easeInEaseOut

        // Nhịp 4: Trả nhẹ sang trái
        let swing4 = SKAction.rotate(toAngle: -0.035, duration: 0.30)
        swing4.timingMode = .easeInEaseOut

        // Nhịp 5: Khôi phục trạng thái chuẩn và tiếp tục idle sway
        let swingReset = SKAction.rotate(toAngle: 0.0, duration: 0.25)
        swingReset.timingMode = .easeInEaseOut

        // Nhún nảy đàn hồi trục Y (Squash & Stretch theo con lắc)
        let squashY = SKAction.scaleY(to: 0.95, duration: 0.15)
        squashY.timingMode = .easeOut
        let stretchY = SKAction.scaleY(to: 1.035, duration: 0.20)
        stretchY.timingMode = .easeInEaseOut
        let normalY = SKAction.scaleY(to: 1.0, duration: 0.25)
        normalY.timingMode = .easeInEaseOut
        let bounceScale = SKAction.sequence([squashY, stretchY, normalY])

        let resumeIdle = SKAction.run { [weak self] in
            self?.startIdle(context: context)
            context.onComplete?()
        }

        let tapGroup = SKAction.group([
            SKAction.sequence([swing1, swing2, swing3, swing4, swingReset]),
            bounceScale
        ])

        node.run(SKAction.sequence([tapGroup, resumeIdle]), withKey: "sticker_tap_action")

        // Ruy băng đung đưa mạnh theo nhịp tap
        for (index, decor) in context.frontDecorations.enumerated() {
            decor.removeAction(forKey: "ribbon_idle_flutter")
            let ribAngle: CGFloat = (index % 2 == 0) ? 0.14 : -0.14
            let rib1 = SKAction.rotate(toAngle: ribAngle, duration: 0.20)
            let rib2 = SKAction.rotate(toAngle: -ribAngle * 0.7, duration: 0.24)
            let rib3 = SKAction.rotate(toAngle: 0.0, duration: 0.26)
            decor.run(SKAction.sequence([rib1, rib2, rib3]))
        }
    }
}

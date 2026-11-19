//
//  PotBounceAnimator.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Bộ điều khiển hiệu ứng vật lý nén nảy (Squash & Stretch spring bounce) dùng chung cho tất cả các chậu
public struct PotBounceAnimator {

    /// Cấu hình thông số hiệu ứng nảy
    public struct BounceConfig {
        public var compressX: CGFloat
        public var compressY: CGFloat
        public var compressDuration: TimeInterval
        public var reboundX: CGFloat
        public var reboundY: CGFloat
        public var reboundDuration: TimeInterval
        public var settleDuration: TimeInterval
        public var shadowShrink: CGFloat

        public static let standard = BounceConfig(
            compressX: 1.10,
            compressY: 0.90,
            compressDuration: 0.09,
            reboundX: 0.95,
            reboundY: 1.07,
            reboundDuration: 0.13,
            settleDuration: 0.15,
            shadowShrink: 0.86
        )

        public static let firm = BounceConfig(
            compressX: 1.08,
            compressY: 0.92,
            compressDuration: 0.08,
            reboundX: 0.96,
            reboundY: 1.05,
            reboundDuration: 0.12,
            settleDuration: 0.14,
            shadowShrink: 0.88
        )
    }

    /// Áp dụng hiệu ứng nhún nảy lò xo đàn hồi lên Sprite chậu và bóng đổ
    /// - Parameters:
    ///   - potNode: Sprite hiển thị chậu
    ///   - shadowNode: Node bóng đổ dưới đáy chậu (nếu có)
    ///   - initialPosition: Tọa độ gốc ban đầu (để reset chống trôi tọa độ khi tap dồn dập)
    ///   - isHanging: Có phải chậu treo hay không (sẽ thêm hiệu ứng chao nghiêng nhẹ)
    ///   - config: Bộ thông số đàn hồi
    public static func applyBounce(
        to potNode: SKSpriteNode,
        shadowNode: SKNode? = nil,
        initialPosition: CGPoint,
        isHanging: Bool = false,
        config: BounceConfig = .standard
    ) {
        potNode.removeAction(forKey: "potTapBounce")
        potNode.position = initialPosition

        // 1. Squash & Stretch: Nén bề ngang nở bề dọc rồi đàn hồi về cân bằng
        let compress = SKAction.scaleX(to: config.compressX, y: config.compressY, duration: config.compressDuration)
        compress.timingMode = .easeIn
        let rebound = SKAction.scaleX(to: config.reboundX, y: config.reboundY, duration: config.reboundDuration)
        rebound.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: config.settleDuration)
        settle.timingMode = .easeInEaseOut

        potNode.run(SKAction.sequence([compress, rebound, settle]), withKey: "potTapBounce")

        // 2. Chậu treo: Thêm chuyển động chao nghiêng đu đưa tự nhiên
        if isHanging {
            potNode.removeAction(forKey: "potTapSwing")
            let swing = SKAction.sequence([
                SKAction.rotate(toAngle: -0.055, duration: 0.08),
                SKAction.rotate(toAngle: 0.055, duration: 0.10),
                SKAction.rotate(toAngle: 0, duration: 0.10)
            ])
            potNode.run(swing, withKey: "potTapSwing")
        }

        // 3. Bóng đổ: Co giãn nhịp nhàng ôm sát đáy chậu
        if let shadow = shadowNode {
            shadow.removeAction(forKey: "shadowBounce")
            let shrink = SKAction.scale(to: config.shadowShrink, duration: config.compressDuration)
            let restore = SKAction.scale(to: 1.0, duration: config.reboundDuration + config.settleDuration)
            restore.timingMode = .easeOut
            shadow.run(SKAction.sequence([shrink, restore]), withKey: "shadowBounce")
        }
    }
}

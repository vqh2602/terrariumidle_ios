//
//  StandardBounceMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động Tap chậu để bàn tiêu chuẩn: Nén nảy Squash & Stretch lò xo đàn hồi + co giãn bóng đổ
public final class StandardBounceMotionEffect: PotMotionEffect {

    public var name: String { "StandardBounce" }

    public var config: PotBounceAnimator.BounceConfig

    public init(config: PotBounceAnimator.BounceConfig = .standard) {
        self.config = config
    }

    public func apply(context: PotMotionContext) {
        let potSprite = context.potNode ?? (context.targetNode as? SKSpriteNode)

        if let pot = potSprite {
            PotBounceAnimator.applyBounce(
                to: pot,
                shadowNode: context.shadowNode,
                initialPosition: context.initialPosition,
                isHanging: context.isHanging,
                config: config
            )
        }

        context.onComplete?()
    }
}

/// Hiệu ứng chuyển động Tap chậu để bàn đầm chắc: Dành cho chậu đá/gốm sứ dày nặng
public final class FirmBounceMotionEffect: PotMotionEffect {

    public var name: String { "FirmBounce" }

    private let standardBounce: StandardBounceMotionEffect

    public init() {
        self.standardBounce = StandardBounceMotionEffect(config: .firm)
    }

    public func apply(context: PotMotionContext) {
        standardBounce.apply(context: context)
    }
}

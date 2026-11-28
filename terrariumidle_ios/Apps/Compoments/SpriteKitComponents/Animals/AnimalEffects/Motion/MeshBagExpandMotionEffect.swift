//
//  MeshBagExpandMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng đung đưa treo nhẹ nhàng và giãn nở phồng túi lưới khi chạm (`animal3` / Bugsnet)
/// - Tuyệt đối chỉ dùng `SKAction.rotate(toAngle:)` tính từ `restZRotation` để chống trôi góc khi spam tap.
public final class MeshBagExpandMotionEffect: AnimalMotionEffect {

    public var name: String { "meshBagExpand" }

    public init() {}

    public func startIdle(context: AnimalMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "animal_idle_action")

        let rest = rig.restZRotation
        let swayLeft = SKAction.rotate(toAngle: rest - 0.024, duration: 2.2)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SKAction.rotate(toAngle: rest + 0.022, duration: 2.4)
        swayRight.timingMode = .easeInEaseOut

        rig.run(
            SKAction.repeatForever(SKAction.sequence([swayLeft, swayRight])),
            withKey: "animal_idle_action"
        )
    }

    public func stopIdle(context: AnimalMotionContext) {
        context.targetNode.removeAction(forKey: "animal_idle_action")
    }

    public func apply(context: AnimalMotionContext) {
        let rig = context.targetNode
        stopIdle(context: context)
        rig.removeAction(forKey: "animal_tap_action")

        let rest = rig.restZRotation
        rig.zRotation = rest
        rig.xScale = 1.0
        rig.yScale = 1.0

        // Giãn nở túi lưới sang hai bên & phồng nhẹ rồi thu về đàn hồi
        let expand = SKAction.group([
            SKAction.scaleX(to: 1.18, duration: 0.11),
            SKAction.scaleY(to: 1.08, duration: 0.11),
            SKAction.rotate(toAngle: rest + 0.065, duration: 0.11)
        ])
        expand.timingMode = .easeOut

        let contract = SKAction.group([
            SKAction.scaleX(to: 0.93, duration: 0.13),
            SKAction.scaleY(to: 0.96, duration: 0.13),
            SKAction.rotate(toAngle: rest - 0.050, duration: 0.13)
        ])
        contract.timingMode = .easeInEaseOut

        let rebound = SKAction.group([
            SKAction.scaleX(to: 1.05, duration: 0.12),
            SKAction.scaleY(to: 1.02, duration: 0.12),
            SKAction.rotate(toAngle: rest + 0.024, duration: 0.12)
        ])
        rebound.timingMode = .easeInEaseOut

        let settle = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.14),
            SKAction.scaleY(to: 1.0, duration: 0.14),
            SKAction.rotate(toAngle: rest, duration: 0.14)
        ])
        settle.timingMode = .easeOut

        let resume = SKAction.run { [weak self, weak rig] in
            rig?.zRotation = rest
            rig?.xScale = 1.0
            rig?.yScale = 1.0
            self?.startIdle(context: context)
            context.onComplete?()
        }

        rig.run(SKAction.sequence([expand, contract, rebound, settle, resume]), withKey: "animal_tap_action")
    }
}

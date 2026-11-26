//
//  BeehivePendulumMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng chuyển động con lắc cho Tổ Ong treo trên cành cây
/// - Tuyệt đối chỉ dùng `SKAction.rotate(toAngle:)` tính từ `restZRotation` để chống trôi góc khi spam tap.
public final class BeehivePendulumMotionEffect: AnimalMotionEffect {

    public var name: String { "beehivePendulum" }

    public init() {}

    public func startIdle(context: AnimalMotionContext) {
        let rig = context.targetNode
        rig.removeAction(forKey: "animal_idle_action")

        let rest = rig.restZRotation
        let swingLeft = SKAction.rotate(toAngle: rest - 0.032, duration: 2.0)
        swingLeft.timingMode = .easeInEaseOut
        let swingRight = SKAction.rotate(toAngle: rest + 0.030, duration: 2.2)
        swingRight.timingMode = .easeInEaseOut
        let swingMid = SKAction.rotate(toAngle: rest - 0.015, duration: 1.7)
        swingMid.timingMode = .easeInEaseOut
        let swingBack = SKAction.rotate(toAngle: rest + 0.022, duration: 1.9)
        swingBack.timingMode = .easeInEaseOut

        rig.run(
            SKAction.repeatForever(SKAction.sequence([swingLeft, swingRight, swingMid, swingBack])),
            withKey: "animal_idle_action"
        )

        if let branch = context.branchNode {
            branch.removeAction(forKey: "animal_branch_idle")
            let bRest = branch.restZRotation
            let b1 = SKAction.rotate(toAngle: bRest + 0.010, duration: 2.6)
            b1.timingMode = .easeInEaseOut
            let b2 = SKAction.rotate(toAngle: bRest - 0.008, duration: 2.6)
            b2.timingMode = .easeInEaseOut
            branch.run(
                SKAction.repeatForever(SKAction.sequence([b1, b2])),
                withKey: "animal_branch_idle"
            )
        }
    }

    public func stopIdle(context: AnimalMotionContext) {
        context.targetNode.removeAction(forKey: "animal_idle_action")
        context.branchNode?.removeAction(forKey: "animal_branch_idle")
    }

    public func apply(context: AnimalMotionContext) {
        let rig = context.targetNode
        stopIdle(context: context)
        rig.removeAction(forKey: "animal_tap_action")

        let rest = rig.restZRotation
        rig.zRotation = rest
        rig.xScale = 1.0
        rig.yScale = 1.0

        let s1 = SKAction.rotate(toAngle: rest + 0.145, duration: 0.16)
        s1.timingMode = .easeOut
        let s2 = SKAction.rotate(toAngle: rest - 0.115, duration: 0.22)
        s2.timingMode = .easeInEaseOut
        let s3 = SKAction.rotate(toAngle: rest + 0.068, duration: 0.24)
        s3.timingMode = .easeInEaseOut
        let s4 = SKAction.rotate(toAngle: rest - 0.030, duration: 0.24)
        s4.timingMode = .easeInEaseOut
        let sReset = SKAction.rotate(toAngle: rest, duration: 0.22)
        sReset.timingMode = .easeInEaseOut

        let squash = SKAction.group([
            SKAction.scaleX(to: 1.08, duration: 0.10),
            SKAction.scaleY(to: 0.91, duration: 0.10)
        ])
        squash.timingMode = .easeOut
        let stretch = SKAction.group([
            SKAction.scaleX(to: 0.95, duration: 0.14),
            SKAction.scaleY(to: 1.05, duration: 0.14)
        ])
        stretch.timingMode = .easeInEaseOut
        let normalize = SKAction.group([
            SKAction.scaleX(to: 1.0, duration: 0.18),
            SKAction.scaleY(to: 1.0, duration: 0.18)
        ])
        normalize.timingMode = .easeInEaseOut

        let tapGroup = SKAction.group([
            SKAction.sequence([s1, s2, s3, s4, sReset]),
            SKAction.sequence([squash, stretch, normalize])
        ])

        let resume = SKAction.run { [weak self, weak rig] in
            rig?.zRotation = rest
            rig?.xScale = 1.0
            rig?.yScale = 1.0
            self?.startIdle(context: context)
            context.onComplete?()
        }

        rig.run(SKAction.sequence([tapGroup, resume]), withKey: "animal_tap_action")
    }
}

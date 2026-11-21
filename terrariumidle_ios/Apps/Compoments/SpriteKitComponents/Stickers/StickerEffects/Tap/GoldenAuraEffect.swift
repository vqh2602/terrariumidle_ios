//
//  GoldenAuraEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Vòng Hào Quang Vàng Kim (Golden Aura Effect)
public final class GoldenAuraEffect: StickerTapEffect {

    public var name: String { "goldenAura" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let origin: CGPoint
        if let parent = targetNode.parent {
            origin = parent.convert(targetNode.position, to: containerNode)
        } else {
            origin = targetNode.position
        }
        rig.position = CGPoint(x: origin.x, y: origin.y - (isHanging ? 85.0 : -35.0))
        containerNode.addChild(rig)

        for ringIndex in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: 28.0 + CGFloat(ringIndex) * 8.0)
            ring.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 0.75)
            ring.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.50, alpha: 0.15)
            ring.lineWidth = 1.8
            ring.setScale(0.3)
            ring.alpha = 0.0
            rig.addChild(ring)

            let delay = Double(ringIndex) * 0.12
            let expand = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.8, duration: 0.75),
                    SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.8, duration: 0.2),
                        SKAction.fadeOut(withDuration: 0.55)
                    ])
                ])
            ])
            ring.run(expand)
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
    }
}

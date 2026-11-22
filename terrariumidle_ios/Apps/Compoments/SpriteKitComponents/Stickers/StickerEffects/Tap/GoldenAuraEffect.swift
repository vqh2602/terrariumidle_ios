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

        let dollSprite = targetNode as? SKSpriteNode
        let dollW = dollSprite?.size.width ?? 75.0
        let dollH = dollSprite?.size.height ?? 170.0

        let dollOrigin: CGPoint
        if let parent = targetNode.parent {
            dollOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            dollOrigin = targetNode.position
        }

        let originY = isHanging ? (dollOrigin.y - dollH * 0.16) : (dollOrigin.y + dollH * 0.72)
        rig.position = CGPoint(x: dollOrigin.x, y: originY)
        containerNode.addChild(rig)

        let sceneW = targetNode.scene?.size.width ?? (dollW * 1.5)
        let sceneH = targetNode.scene?.size.height ?? (dollH * 1.3)
        let safeRadius = max(28.0, min(sceneW * 0.34, sceneH * 0.22, 46.0))

        let baseR = safeRadius * 0.42
        for ringIndex in 0..<3 {
            let ring = SKShapeNode(circleOfRadius: baseR + CGFloat(ringIndex) * 5.0)
            ring.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 0.75)
            ring.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.50, alpha: 0.12)
            ring.lineWidth = 1.4
            ring.setScale(0.3)
            ring.alpha = 0.0
            rig.addChild(ring)

            let delay = Double(ringIndex) * 0.10
            let expand = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.45, duration: 0.65),
                    SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.75, duration: 0.18),
                        SKAction.fadeOut(withDuration: 0.47)
                    ])
                ])
            ])
            ring.run(expand)
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            SKAction.removeFromParent()
        ]))
    }
}

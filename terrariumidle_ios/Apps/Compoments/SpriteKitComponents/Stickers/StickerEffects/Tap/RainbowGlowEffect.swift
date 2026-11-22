//
//  RainbowGlowEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Cầu Vồng Tươi Sáng Sau Mưa (Rainbow Glow Effect)
public final class RainbowGlowEffect: StickerTapEffect {

    public var name: String { "rainbowGlow" }

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

        let colors: [UIColor] = [
            UIColor(red: 1.00, green: 0.35, blue: 0.35, alpha: 0.85),
            UIColor(red: 1.00, green: 0.65, blue: 0.20, alpha: 0.85),
            UIColor(red: 1.00, green: 0.90, blue: 0.25, alpha: 0.85),
            UIColor(red: 0.35, green: 0.85, blue: 0.45, alpha: 0.85),
            UIColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 0.85),
            UIColor(red: 0.65, green: 0.40, blue: 0.95, alpha: 0.85)
        ]

        let baseRadius = safeRadius * 0.45
        for (i, color) in colors.enumerated() {
            let r = baseRadius + CGFloat(i) * 2.0
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: r, startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: false)

            let arc = SKShapeNode(path: path)
            arc.strokeColor = color
            arc.lineWidth = 1.8
            arc.lineCap = .round
            arc.alpha = 0.0
            arc.setScale(0.7)
            rig.addChild(arc)

            let delay = Double(i) * 0.03
            let show = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.22),
                    SKAction.fadeAlpha(to: 0.85, duration: 0.22)
                ]),
                SKAction.wait(forDuration: 0.55),
                SKAction.group([
                    SKAction.scale(to: 1.10, duration: 0.30),
                    SKAction.fadeOut(withDuration: 0.30)
                ])
            ])
            arc.run(show)
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.25),
            SKAction.removeFromParent()
        ]))
    }
}

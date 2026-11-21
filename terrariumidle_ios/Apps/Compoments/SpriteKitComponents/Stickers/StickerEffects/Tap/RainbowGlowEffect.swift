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

        let origin: CGPoint
        if let parent = targetNode.parent {
            origin = parent.convert(targetNode.position, to: containerNode)
        } else {
            origin = targetNode.position
        }
        rig.position = CGPoint(x: origin.x, y: origin.y - (isHanging ? 95.0 : -35.0))
        containerNode.addChild(rig)

        let colors: [UIColor] = [
            UIColor(red: 1.00, green: 0.35, blue: 0.35, alpha: 0.85), // Đỏ
            UIColor(red: 1.00, green: 0.65, blue: 0.20, alpha: 0.85), // Cam
            UIColor(red: 1.00, green: 0.90, blue: 0.25, alpha: 0.85), // Vàng
            UIColor(red: 0.35, green: 0.85, blue: 0.45, alpha: 0.85), // Lục
            UIColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 0.85), // Lam
            UIColor(red: 0.65, green: 0.40, blue: 0.95, alpha: 0.85)  // Tím
        ]

        let baseRadius: CGFloat = 32.0
        for (i, color) in colors.enumerated() {
            let r = baseRadius + CGFloat(i) * 2.8
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: r, startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: false)

            let arc = SKShapeNode(path: path)
            arc.strokeColor = color
            arc.lineWidth = 2.4
            arc.lineCap = .round
            arc.alpha = 0.0
            arc.setScale(0.7)
            rig.addChild(arc)

            let delay = Double(i) * 0.03
            let show = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.25),
                    SKAction.fadeAlpha(to: 0.9, duration: 0.25)
                ]),
                SKAction.wait(forDuration: 0.6),
                SKAction.group([
                    SKAction.scale(to: 1.15, duration: 0.35),
                    SKAction.fadeOut(withDuration: 0.35)
                ])
            ])
            arc.run(show)
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.4),
            SKAction.removeFromParent()
        ]))
    }
}

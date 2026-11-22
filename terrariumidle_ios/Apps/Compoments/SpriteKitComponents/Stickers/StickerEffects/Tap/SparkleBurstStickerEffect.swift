//
//  SparkleBurstStickerEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Bung tỏa Ngôi sao Lấp lánh (Sparkle Star Burst)
public final class SparkleBurstStickerEffect: StickerTapEffect {

    public var name: String { "sparkleBurst" }

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

        let starCount = 14
        for _ in 0..<starCount {
            let star = createStar(maxRadius: safeRadius * 0.13)
            rig.addChild(star)

            let angle = CGFloat.random(in: 0...(.pi * 2.0))
            let distance = CGFloat.random(in: (safeRadius * 0.30)...(safeRadius * 0.75))
            let tx = cos(angle) * distance
            let ty = sin(angle) * distance + CGFloat.random(in: 0.0...15.0)

            let dur = Double.random(in: 0.5...0.85)
            let move = SKAction.move(to: CGPoint(x: tx, y: ty), duration: dur)
            move.timingMode = .easeOut
            let rot = SKAction.rotate(byAngle: CGFloat.random(in: -3.0...3.0), duration: dur)
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.3),
                SKAction.fadeOut(withDuration: dur * 0.7)
            ])
            let scale = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.0...1.3), duration: dur * 0.3),
                SKAction.scale(to: 0.1, duration: dur * 0.7)
            ])
            star.run(SKAction.group([move, rot, fade, scale]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }

    private func createStar(maxRadius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter: CGFloat = CGFloat.random(in: (maxRadius * 0.7)...maxRadius)
        let rInner: CGFloat = rOuter * 0.25

        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4.0)
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.70, alpha: 0.95)
        star.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 0.90)
        star.lineWidth = 0.7
        star.setScale(0.1)
        return star
    }
}

//
//  MeshBagDustEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng hạt bụi lưới và ánh xanh dịu nhẹ tỏa ra khi chạm hoặc bắt sâu vào Túi lưới (`animal3` / Bugsnet).
public final class MeshBagDustEffect: AnimalTapEffect {

    public var name: String { "meshBagDust" }

    private let colors: [UIColor] = [
        UIColor(red: 0.45, green: 0.85, blue: 0.48, alpha: 1.0),
        UIColor(red: 0.72, green: 0.94, blue: 0.62, alpha: 1.0),
        UIColor(red: 0.96, green: 0.95, blue: 0.72, alpha: 1.0)
    ]

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let bagSprite = targetNode as? SKSpriteNode
        let bagW = bagSprite?.size.width ?? 80.0
        let bagH = bagSprite?.size.height ?? 150.0

        let origin: CGPoint
        if let parent = targetNode.parent {
            origin = parent.convert(targetNode.position, to: containerNode)
        } else {
            origin = targetNode.position
        }

        // Tâm phần bụng lưới (anchorPoint ở đỉnh (0.5, 1.0))
        let pocketOffsetY = isHanging ? (-bagH * 0.68) : (bagH * 0.32)
        rig.position = CGPoint(x: origin.x, y: origin.y + pocketOffsetY)
        containerNode.addChild(rig)

        let tex = PestTextureCache.shared.sparkleTexture
        let count = 10

        for i in 0..<count {
            let dot = SKSpriteNode(texture: tex)
            dot.color = colors[i % colors.count]
            dot.colorBlendFactor = 1.0
            let sz = CGFloat.random(in: 3.5...7.0)
            dot.size = CGSize(width: sz, height: sz)
            dot.position = CGPoint(
                x: CGFloat.random(in: -bagW * 0.28...bagW * 0.28),
                y: CGFloat.random(in: -bagH * 0.16...bagH * 0.14)
            )
            rig.addChild(dot)

            let angle = CGFloat(i) * (.pi * 2.0 / CGFloat(count)) + CGFloat.random(in: -0.25...0.25)
            let dist = CGFloat.random(in: 14.0...34.0)
            let dur = Double.random(in: 0.38...0.65)
            let move = SKAction.move(by: CGVector(dx: cos(angle) * dist, dy: sin(angle) * dist), duration: dur)
            move.timingMode = .easeOut
            let scale = SKAction.scale(to: 0.25, duration: dur)
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.3),
                SKAction.fadeOut(withDuration: dur * 0.7)
            ])
            dot.run(SKAction.group([move, scale, fade]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.72),
            SKAction.removeFromParent()
        ]))
    }
}

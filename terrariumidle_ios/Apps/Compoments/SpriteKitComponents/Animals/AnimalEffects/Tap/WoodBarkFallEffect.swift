//
//  WoodBarkFallEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng rơi các mảnh vỏ cây gỗ mục ra bên ngoài khi click vào tổ gỗ mục (`animal2`):
/// - 12 mảnh vỏ gỗ nâu sẫm / nâu sáng tách ra hai bên gốc cây, xoay lật và rơi xuống tự nhiên
/// - 8 hạt mùn cưa & lá cỏ nhỏ bay nhẹ xung quanh
public final class WoodBarkFallEffect: AnimalTapEffect {

    public var name: String { "woodBarkFall" }

    private let barkColors: [UIColor] = [
        UIColor(red: 0.45, green: 0.27, blue: 0.14, alpha: 1.0),
        UIColor(red: 0.60, green: 0.38, blue: 0.20, alpha: 1.0),
        UIColor(red: 0.34, green: 0.20, blue: 0.10, alpha: 1.0),
        UIColor(red: 0.74, green: 0.52, blue: 0.32, alpha: 1.0)
    ]

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let logSprite = targetNode as? SKSpriteNode
        let logW = logSprite?.size.width ?? 110.0
        let logH = logSprite?.size.height ?? 42.0

        let origin: CGPoint
        if let parent = targetNode.parent {
            origin = parent.convert(targetNode.position, to: containerNode)
        } else {
            origin = targetNode.position
        }

        // Tâm thân gốc cây gỗ mục (anchorPoint ở đáy (0.5, 0.0))
        rig.position = CGPoint(x: origin.x, y: origin.y + logH * 0.48)
        containerNode.addChild(rig)

        let chipTex = LazybugTextureCache.shared.barkChipTexture
        let dustTex = LazybugTextureCache.shared.sawdustTexture

        // 1. Các mảnh vỏ gỗ bật ra 2 bên và rơi xuống
        let chipCount = 12
        for i in 0..<chipCount {
            let chip = SKSpriteNode(texture: chipTex)
            chip.color = barkColors[i % barkColors.count]
            chip.colorBlendFactor = 1.0

            let w = CGFloat.random(in: 7.0...12.5)
            let h = w * CGFloat.random(in: 0.52...0.72)
            chip.size = CGSize(width: w, height: h)

            // Xuất phát dọc theo mép thân gỗ hai bên
            let side: CGFloat = (i % 2 == 0) ? -1.0 : 1.0
            let startX = side * CGFloat.random(in: logW * 0.10...logW * 0.32)
            let startY = CGFloat.random(in: -logH * 0.15...logH * 0.42)
            chip.position = CGPoint(x: startX, y: startY)
            chip.zRotation = CGFloat.random(in: 0...(.pi * 2.0))
            rig.addChild(chip)

            let outDx = side * CGFloat.random(in: 22.0...52.0)
            let popDy = CGFloat.random(in: 10.0...26.0)
            let fallDy = -CGFloat.random(in: logH * 0.65...logH * 1.25)
            let dur = Double.random(in: 0.55...0.88)

            let rise = SKAction.move(by: CGVector(dx: outDx * 0.45, dy: popDy), duration: dur * 0.32)
            rise.timingMode = .easeOut
            let fall = SKAction.move(by: CGVector(dx: outDx * 0.55, dy: fallDy), duration: dur * 0.68)
            fall.timingMode = .easeIn

            let spin = SKAction.rotate(toAngle: chip.zRotation + side * CGFloat.random(in: 1.8...3.6), duration: dur)
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.55),
                SKAction.fadeOut(withDuration: dur * 0.45)
            ])

            chip.run(SKAction.group([SKAction.sequence([rise, fall]), spin, fade]))
        }

        // 2. Các hạt mùn cưa & rêu nhỏ bay nhẹ
        let dustCount = 8
        for i in 0..<dustCount {
            let dust = SKSpriteNode(texture: dustTex)
            let isMoss = (i % 4 == 0)
            dust.color = isMoss
                ? UIColor(red: 0.18, green: 0.58, blue: 0.36, alpha: 1.0)
                : UIColor(red: 0.86, green: 0.68, blue: 0.44, alpha: 1.0)
            dust.colorBlendFactor = 1.0

            let sz = CGFloat.random(in: 3.5...6.0)
            dust.size = CGSize(width: sz, height: sz)
            dust.position = CGPoint(
                x: CGFloat.random(in: -logW * 0.28...logW * 0.28),
                y: CGFloat.random(in: -logH * 0.10...logH * 0.35)
            )
            rig.addChild(dust)

            let dx = CGFloat.random(in: -34.0...34.0)
            let dy = CGFloat.random(in: -24.0...18.0)
            let dur = Double.random(in: 0.42...0.70)

            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: dur)
            move.timingMode = .easeOut
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.35),
                SKAction.fadeOut(withDuration: dur * 0.65)
            ])
            dust.run(SKAction.group([move, fade]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.95),
            SKAction.removeFromParent()
        ]))
    }
}

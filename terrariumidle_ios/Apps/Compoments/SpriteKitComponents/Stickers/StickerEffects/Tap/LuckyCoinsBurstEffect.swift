//
//  LuckyCoinsBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Thị Giác Mưa Đồng Xu Vàng May Mắn (Lucky Koban Gold Coins Burst)
/// - Dành riêng cho Chú Mèo Thần Tài (Maneki-neko - Sticker2)
/// - Bung tỏa 14-18 đồng tiền vàng Koban truyền thống Nhật Bản óng ả (hình bầu dục có viền vàng cam và lỗ ở giữa)
/// - Đồng xu lật 3D trong không gian (`xScale` dao động) kết hợp cùng chùm sao vàng kim lấp lánh
/// - Tỏa hào quang tài lộc ấm áp rực rỡ từ ngực chú mèo
public final class LuckyCoinsBurstEffect: StickerTapEffect {

    public var name: String { "luckyCoinsBurst" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let catSprite = targetNode as? SKSpriteNode
        let catW = catSprite?.size.width ?? 120.0
        let catH = catSprite?.size.height ?? 110.0

        let catOrigin: CGPoint
        if let parent = targetNode.parent {
            catOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            catOrigin = targetNode.position
        }

        // Điểm xuất phát: ngực chú mèo / vòng cổ chuông vàng
        let originY = isHanging ? (catOrigin.y - catH * 0.4) : (catOrigin.y + catH * 0.55)
        rig.position = CGPoint(x: catOrigin.x, y: originY)
        containerNode.addChild(rig)

        // 1. Vầng hào quang tài lộc (Golden Wealth Aura) mở rộng
        let aura = SKShapeNode(circleOfRadius: 18.0)
        aura.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.65)
        aura.strokeColor = UIColor(red: 1.0, green: 0.70, blue: 0.0, alpha: 0.90)
        aura.lineWidth = 1.5
        rig.addChild(aura)

        let expandAura = SKAction.group([
            SKAction.scale(to: 3.5, duration: 0.65),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.85, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.50)
            ])
        ])
        expandAura.timingMode = .easeOut
        aura.run(SKAction.sequence([expandAura, SKAction.removeFromParent()]))

        // 2. Bung tỏa các đồng xu vàng Koban may mắn (14 đồng xu)
        let coinCount = 14
        for _ in 0..<coinCount {
            let coin = createKobanCoin()
            rig.addChild(coin)

            let angle = CGFloat.random(in: 0.15...(.pi - 0.15)) // Hướng chủ yếu vồng lên trên
            let speed = CGFloat.random(in: 45.0...95.0)
            let tx = cos(angle) * speed * (Bool.random() ? 1.0 : -1.0)
            let ty = sin(angle) * speed + CGFloat.random(in: 15.0...40.0)

            let dur = Double.random(in: 0.65...1.0)

            // Quỹ đạo vồng parabol mượt mà
            let moveUp = SKAction.move(by: CGVector(dx: tx * 0.6, dy: ty), duration: dur * 0.45)
            moveUp.timingMode = .easeOut
            let moveFall = SKAction.move(by: CGVector(dx: tx * 0.4, dy: -CGFloat.random(in: 25.0...60.0)), duration: dur * 0.55)
            moveFall.timingMode = .easeIn
            let trajectory = SKAction.sequence([moveUp, moveFall])

            // Hiệu ứng lật đồng xu 3D trong không gian (Coin Flip)
            let flipSpeed = Double.random(in: 0.12...0.22)
            let flipDown = SKAction.scaleX(to: 0.08, duration: flipSpeed)
            let flipUp = SKAction.scaleX(to: 1.0, duration: flipSpeed)
            let flipLoop = SKAction.repeatForever(SKAction.sequence([flipDown, flipUp]))

            // Xoay nhẹ theo góc
            let rot = SKAction.rotate(byAngle: CGFloat.random(in: -2.5...2.5), duration: dur)

            // Mờ dần ở cuối hành trình
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.55),
                SKAction.fadeOut(withDuration: dur * 0.45)
            ])

            coin.run(SKAction.group([trajectory, flipLoop, rot, fade]))
        }

        // 3. Chùm ngôi sao vàng lấp lánh (Golden Sparkles)
        let starCount = 10
        for _ in 0..<starCount {
            let star = createStar()
            rig.addChild(star)

            let angle = CGFloat.random(in: 0...(.pi * 2.0))
            let dist = CGFloat.random(in: 20.0...65.0)
            let tx = cos(angle) * dist
            let ty = sin(angle) * dist

            let dur = Double.random(in: 0.5...0.8)
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
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
    }

    /// Tạo hình đồng xu vàng Koban truyền thống hình bầu dục
    private func createKobanCoin() -> SKNode {
        let coinRoot = SKNode()

        let w: CGFloat = CGFloat.random(in: 9.0...12.0)
        let h: CGFloat = w * 1.35

        let path = CGPath(ellipseIn: CGRect(x: -w/2, y: -h/2, width: w, height: h), transform: nil)
        let coin = SKShapeNode(path: path)
        coin.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.98) // Vàng kim óng ả
        coin.strokeColor = UIColor(red: 0.95, green: 0.60, blue: 0.0, alpha: 0.95) // Viền vàng cam
        coin.lineWidth = 1.0
        coinRoot.addChild(coin)

        // Lỗ chữ nhật nhỏ ở tâm đồng Koban
        let innerHole = SKShapeNode(rectOf: CGSize(width: w * 0.28, height: h * 0.22))
        innerHole.fillColor = UIColor(red: 0.85, green: 0.55, blue: 0.0, alpha: 0.85)
        innerHole.strokeColor = .clear
        coinRoot.addChild(innerHole)

        // Điểm phản chiếu ánh kim trắng lấp lánh
        let highlight = SKShapeNode(circleOfRadius: w * 0.12)
        highlight.position = CGPoint(x: -w * 0.22, y: h * 0.26)
        highlight.fillColor = UIColor(white: 1.0, alpha: 0.85)
        highlight.strokeColor = .clear
        coinRoot.addChild(highlight)

        coinRoot.setScale(CGFloat.random(in: 0.85...1.15))
        return coinRoot
    }

    private func createStar() -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter: CGFloat = CGFloat.random(in: 3.5...5.5)
        let rInner: CGFloat = rOuter * 0.25

        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4.0)
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.60, alpha: 0.95)
        star.strokeColor = UIColor(red: 1.0, green: 0.75, blue: 0.10, alpha: 0.90)
        star.lineWidth = 0.6
        star.setScale(0.1)
        return star
    }
}

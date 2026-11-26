//
//  HoneySplashBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng mật ong bắn ra khi click vào tổ ong:
/// - Quầng sáng mật ong ấm áp lan tỏa từ cửa tổ
/// - 14 giọt mật ong vàng óng (hình giọt nước + điểm phản chiếu trắng) bắn vồng ra rồi rơi xuống tự nhiên
/// - 8 tia lấp lánh vàng mật ong
public final class HoneySplashBurstEffect: AnimalTapEffect {

    public var name: String { "honeySplashBurst" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let hiveSprite = targetNode as? SKSpriteNode
        let hiveH = hiveSprite?.size.height ?? 90.0

        let hiveOrigin: CGPoint
        if let parent = targetNode.parent {
            hiveOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            hiveOrigin = targetNode.position
        }

        // Tâm cửa tổ ong (anchorPoint của hiveNode nằm ở cuống trên (0.48, 1.0))
        let originY = isHanging ? (hiveOrigin.y - hiveH * 0.60) : (hiveOrigin.y + hiveH * 0.40)
        rig.position = CGPoint(x: hiveOrigin.x, y: originY)
        containerNode.addChild(rig)

        // 1. Vầng hào quang mật ong ấm áp
        let aura = SKShapeNode(circleOfRadius: 15.0)
        aura.fillColor = UIColor(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.55)
        aura.strokeColor = UIColor(red: 0.96, green: 0.55, blue: 0.0, alpha: 0.85)
        aura.lineWidth = 1.4
        rig.addChild(aura)

        let expandAura = SKAction.group([
            SKAction.scale(to: 3.1, duration: 0.55),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.78, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.43)
            ])
        ])
        expandAura.timingMode = .easeOut
        aura.run(SKAction.sequence([expandAura, SKAction.removeFromParent()]))

        // 2. Các giọt mật ong vàng óng bắn văng ra xung quanh
        let dropCount = 14
        for i in 0..<dropCount {
            let drop = createHoneyDroplet()
            rig.addChild(drop)

            let spreadAngle = CGFloat.random(in: -0.35...(.pi + 0.35))
            let speed = CGFloat.random(in: 36.0...88.0)
            let dx = cos(spreadAngle) * speed * ((i % 2 == 0) ? 1.0 : -1.0) * 0.85
            let upDy = max(12.0, sin(spreadAngle) * speed * 0.75 + CGFloat.random(in: 8.0...26.0))
            let fallDy = -CGFloat.random(in: 38.0...72.0)

            let duration = Double.random(in: 0.55...0.90)
            let rise = SKAction.move(by: CGVector(dx: dx * 0.55, dy: upDy), duration: duration * 0.40)
            rise.timingMode = .easeOut
            let fall = SKAction.move(by: CGVector(dx: dx * 0.45, dy: fallDy), duration: duration * 0.60)
            fall.timingMode = .easeIn

            let scalePop = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.05...1.30), duration: duration * 0.25),
                SKAction.scale(to: 0.45, duration: duration * 0.75)
            ])
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: duration * 0.55),
                SKAction.fadeOut(withDuration: duration * 0.45)
            ])

            let tilt = atan2(dx, upDy) * 0.45
            drop.zRotation = -tilt

            drop.run(SKAction.group([SKAction.sequence([rise, fall]), scalePop, fade]))
        }

        // 3. Các hạt sao lấp lánh ánh mật ong
        let starCount = 8
        for _ in 0..<starCount {
            let star = createHoneySparkle()
            rig.addChild(star)

            let angle = CGFloat.random(in: 0...(.pi * 2.0))
            let dist = CGFloat.random(in: 22.0...62.0)
            let dur = Double.random(in: 0.42...0.72)

            let move = SKAction.move(to: CGPoint(x: cos(angle) * dist, y: sin(angle) * dist), duration: dur)
            move.timingMode = .easeOut
            let scale = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 0.9...1.25), duration: dur * 0.3),
                SKAction.scale(to: 0.1, duration: dur * 0.7)
            ])
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.25),
                SKAction.fadeOut(withDuration: dur * 0.75)
            ])
            star.run(SKAction.group([move, scale, fade]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.05),
            SKAction.removeFromParent()
        ]))
    }

    private func createHoneyDroplet() -> SKNode {
        let root = SKNode()
        let r = CGFloat.random(in: 3.4...5.8)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: r * 1.45))
        path.addQuadCurve(to: CGPoint(x: r, y: -r * 0.2), control: CGPoint(x: r * 0.95, y: r * 0.55))
        path.addArc(center: CGPoint(x: 0, y: -r * 0.2), radius: r, startAngle: 0, endAngle: .pi, clockwise: true)
        path.addQuadCurve(to: CGPoint(x: 0, y: r * 1.45), control: CGPoint(x: -r * 0.95, y: r * 0.55))
        path.closeSubpath()

        let drop = SKShapeNode(path: path)
        drop.fillColor = UIColor(red: 1.0, green: 0.73, blue: 0.08, alpha: 0.96)
        drop.strokeColor = UIColor(red: 0.92, green: 0.48, blue: 0.0, alpha: 0.90)
        drop.lineWidth = 0.8
        root.addChild(drop)

        let highlight = SKShapeNode(circleOfRadius: r * 0.26)
        highlight.position = CGPoint(x: -r * 0.30, y: -r * 0.05)
        highlight.fillColor = UIColor(white: 1.0, alpha: 0.88)
        highlight.strokeColor = .clear
        root.addChild(highlight)

        return root
    }

    private func createHoneySparkle() -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter = CGFloat.random(in: 3.0...4.8)
        let rInner = rOuter * 0.28
        for i in 0..<8 {
            let a = CGFloat(i) * (.pi / 4.0)
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cos(a) * r, y: sin(a) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = UIColor(red: 1.0, green: 0.94, blue: 0.55, alpha: 0.95)
        star.strokeColor = UIColor(red: 1.0, green: 0.72, blue: 0.05, alpha: 0.85)
        star.lineWidth = 0.5
        star.setScale(0.1)
        return star
    }
}

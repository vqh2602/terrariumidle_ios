//
//  WoodPollenEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bụi phấn gỗ thơm" (Wood Pollen & Amber Glow)
/// - Tung ra chùm hạt phấn gỗ thơm ấm áp màu hổ phách / mật ong, bay bổng nhẹ nhàng quanh chậu gỗ
public final class WoodPollenEffect: PotTapEffect {

    public let name: String = "WoodPollenEffect"

    public var burstCountRange: ClosedRange<Int> = 8...12
    public var minRadius: CGFloat = 2.5
    public var maxRadius: CGFloat = 4.5

    public init(burstCountRange: ClosedRange<Int> = 8...12) {
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = (i % 3 == 0)
                ? UIColor(red: 0.95, green: 0.75, blue: 0.45, alpha: 0.95) // Hổ phách mật ong
                : (i % 3 == 1)
                    ? UIColor(red: 0.88, green: 0.58, blue: 0.32, alpha: 0.90) // Nâu gỗ ấm
                    : UIColor(red: 1.0, green: 0.90, blue: 0.65, alpha: 0.95)  // Vàng phấn sáng

            let particle = Self.createPollenNode(radius: radius, color: color)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.20)...(potFrame.maxY - potFrame.height * 0.15))
            particle.position = CGPoint(x: startX, y: startY)
            particle.zPosition = 150
            particle.alpha = 0.0
            particle.setScale(0.3)
            containerNode.addChild(particle)

            let flyAngle = CGFloat.random(in: 0.1 * .pi ... 0.9 * .pi) // Hướng bay bổng lên trên
            let distance = CGFloat.random(in: 30...65)
            let dx = cos(flyAngle) * distance * 0.7
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.12)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.65)
            floatOut.timingMode = .easeOut
            let wobble = SKAction.sequence([
                SKAction.rotate(byAngle: 0.35, duration: 0.3),
                SKAction.rotate(byAngle: -0.35, duration: 0.35)
            ])
            let scalePulse = SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.20),
                SKAction.scale(to: 0.3, duration: 0.45)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.30),
                SKAction.fadeOut(withDuration: 0.35)
            ])

            let motionGroup = SKAction.group([floatOut, wobble, scalePulse, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            particle.run(fullSeq)
        }
    }

    public static func createPollenNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.strokeColor = UIColor.white.withAlphaComponent(0.6)
        node.lineWidth = 0.5

        let glow = SKShapeNode(circleOfRadius: radius * 0.4)
        glow.fillColor = .white
        glow.strokeColor = .clear
        glow.alpha = 0.8
        node.addChild(glow)

        return node
    }
}

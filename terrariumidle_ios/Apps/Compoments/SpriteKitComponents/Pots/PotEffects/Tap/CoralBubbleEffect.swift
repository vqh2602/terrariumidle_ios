//
//  CoralBubbleEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bọt ngọc san hô" (Coral Luminescent Pearls)
/// - Tung ra chùm bọt ngọc và hoa san hô lấp lánh màu hồng san hô dịu dàng (#F6BDB6, #FF99C8, #FCB7AF)
/// - Bay bổng phập phồng nhẹ nhàng quanh bình gốm san hô cổ cao
public final class CoralBubbleEffect: PotTapEffect {

    public let name: String = "CoralBubbleEffect"

    public var burstCountRange: ClosedRange<Int> = 8...12
    public var minRadius: CGFloat = 3.0
    public var maxRadius: CGFloat = 5.5

    public init(burstCountRange: ClosedRange<Int> = 8...12) {
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = (i % 3 == 0)
                ? UIColor(red: 0.96, green: 0.74, blue: 0.71, alpha: 0.95) // Hồng san hô (#F6BDB6)
                : (i % 3 == 1)
                    ? UIColor(red: 1.0, green: 0.60, blue: 0.78, alpha: 0.95)  // Hồng phấn rực (#FF99C8)
                    : UIColor(red: 0.99, green: 0.88, blue: 0.86, alpha: 0.95)  // San hô trắng kem (#FDEEE6)

            let pearl = Self.createCoralPearlNode(radius: radius, color: color)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.15)...(potFrame.maxY - potFrame.height * 0.15))
            pearl.position = CGPoint(x: startX, y: startY)
            pearl.zPosition = 150
            pearl.alpha = 0.0
            pearl.setScale(0.25)
            containerNode.addChild(pearl)

            let flyAngle = CGFloat.random(in: 0.15 * .pi ... 0.85 * .pi) // Bay bổng lên trên
            let distance = CGFloat.random(in: 35...75)
            let dx = cos(flyAngle) * distance * 0.6
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.12)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.65)
            floatOut.timingMode = .easeOut
            let wobble = SKAction.sequence([
                SKAction.scaleX(to: 1.25, y: 0.85, duration: 0.18),
                SKAction.scaleX(to: 0.88, y: 1.15, duration: 0.22),
                SKAction.scale(to: 0.3, duration: 0.25)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.30),
                SKAction.fadeOut(withDuration: 0.35)
            ])

            let motionGroup = SKAction.group([floatOut, wobble, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            pearl.run(fullSeq)
        }
    }

    public static func createCoralPearlNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.strokeColor = UIColor.white.withAlphaComponent(0.85)
        node.lineWidth = 0.6

        // Điểm phản chiếu ánh sáng 3D
        let highlight = SKShapeNode(circleOfRadius: radius * 0.32)
        highlight.fillColor = .white
        highlight.strokeColor = .clear
        highlight.alpha = 0.9
        highlight.position = CGPoint(x: -radius * 0.25, y: radius * 0.25)
        node.addChild(highlight)

        return node
    }
}

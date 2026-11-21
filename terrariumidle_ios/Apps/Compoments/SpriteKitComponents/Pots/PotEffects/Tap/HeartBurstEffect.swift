//
//  HeartBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Trái tim bồng bềnh" (Heart Burst)
/// - Bung toả chùm trái tim màu hồng ngọc bay vút lên trên lượn sóng và mờ dần
public final class HeartBurstEffect: PotTapEffect {

    public let name: String = "HeartBurstEffect"

    public var burstCountRange: ClosedRange<Int> = 7...10
    public var minSize: CGFloat = 8.0
    public var maxSize: CGFloat = 14.0

    public init(burstCountRange: ClosedRange<Int> = 7...10) {
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)

        for i in 0..<burstCount {
            let size = CGFloat.random(in: minSize...maxSize)
            let heartColor = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.35, blue: 0.55, alpha: 0.95)
                : UIColor(red: 1.0, green: 0.70, blue: 0.82, alpha: 0.95)

            let heart = Self.createHeartNode(size: CGSize(width: size, height: size * 0.92), color: heartColor)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.2)...(potFrame.maxX - potFrame.width * 0.2))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.3)...(potFrame.maxY - potFrame.height * 0.2))
            heart.position = CGPoint(x: startX, y: startY)
            heart.zPosition = 150
            heart.alpha = 0.0
            heart.setScale(0.3)
            containerNode.addChild(heart)

            let flyAngle = CGFloat.random(in: .pi * 0.2...(.pi * 0.8)) // Bay vút lên trên
            let distance = CGFloat.random(in: 30...65)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.60)
            floatOut.timingMode = .easeOut
            let wobble = SKAction.sequence([
                SKAction.rotate(byAngle: 0.25, duration: 0.15),
                SKAction.rotate(byAngle: -0.50, duration: 0.30),
                SKAction.rotate(byAngle: 0.25, duration: 0.15)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.28),
                SKAction.fadeOut(withDuration: 0.32)
            ])

            let motionGroup = SKAction.group([floatOut, wobble, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])
            heart.run(fullSeq)
        }
    }

    // MARK: - Helper vẽ hình trái tim Bezier (Heart Shape)

    public static func createHeartNode(size: CGSize, color: UIColor) -> SKShapeNode {
        let path = UIBezierPath()
        let w = size.width
        let h = size.height

        path.move(to: CGPoint(x: 0, y: -h * 0.45))
        path.addCurve(
            to: CGPoint(x: -w * 0.5, y: h * 0.1),
            controlPoint1: CGPoint(x: -w * 0.3, y: -h * 0.2),
            controlPoint2: CGPoint(x: -w * 0.5, y: -h * 0.05)
        )
        path.addArc(
            withCenter: CGPoint(x: -w * 0.25, y: h * 0.2),
            radius: w * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addArc(
            withCenter: CGPoint(x: w * 0.25, y: h * 0.2),
            radius: w * 0.25,
            startAngle: .pi,
            endAngle: 0,
            clockwise: true
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -h * 0.45),
            controlPoint1: CGPoint(x: w * 0.5, y: -h * 0.05),
            controlPoint2: CGPoint(x: w * 0.3, y: -h * 0.2)
        )
        path.close()

        let heartNode = SKShapeNode(path: path.cgPath)
        heartNode.fillColor = color
        heartNode.strokeColor = UIColor.white.withAlphaComponent(0.7)
        heartNode.lineWidth = 0.6
        return heartNode
    }
}

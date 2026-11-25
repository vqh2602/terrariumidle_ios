//
//  BambooMistEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Sương mai thiền tịnh" (Zen Bamboo Mist & Dew)
/// - Tung ra chùm hạt sương mai thanh khiết và đốm sáng xanh mạ thiền tịnh (#A7D7C5, #E4E978, #C9E4DE)
/// - Bay lượn tản mát nhẹ nhàng quanh chậu ống tre mộc nâu sẫm
public final class BambooMistEffect: PotTapEffect {

    public enum Theme: CaseIterable, Hashable {
        case zenDew     // Xanh ngọc tre non, Vàng chanh sương sớm, Sương bạc (mặc định)
        case morningSky // Xanh da trời nhạt, Sương trắng, Bạc hà
        case autumnZen  // Vàng thu nhạt, Cam sương, Kem ấm

        public var shadeColors: [UIColor] {
            switch self {
            case .zenDew:
                return [
                    UIColor(red: 0.65, green: 0.84, blue: 0.77, alpha: 0.95), // Xanh ngọc tre non (#A7D7C5)
                    UIColor(red: 0.89, green: 0.91, blue: 0.47, alpha: 0.95), // Vàng chanh sương sớm (#E4E978)
                    UIColor(red: 0.79, green: 0.89, blue: 0.87, alpha: 0.95)  // Sương bạc thanh tịnh (#C9E4DE)
                ]
            case .morningSky:
                return [
                    UIColor(red: 0.68, green: 0.89, blue: 0.98, alpha: 0.95),
                    UIColor(red: 0.92, green: 0.97, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.68, green: 0.94, blue: 0.86, alpha: 0.95)
                ]
            case .autumnZen:
                return [
                    UIColor(red: 0.96, green: 0.84, blue: 0.56, alpha: 0.95),
                    UIColor(red: 0.98, green: 0.74, blue: 0.54, alpha: 0.95),
                    UIColor(red: 0.98, green: 0.94, blue: 0.84, alpha: 0.95)
                ]
            }
        }
    }

    public let name: String = "BambooMistEffect"

    public var theme: Theme = .zenDew
    public var burstCountRange: ClosedRange<Int> = 8...12
    public var minRadius: CGFloat = 2.5
    public var maxRadius: CGFloat = 5.0

    public init(theme: Theme = .zenDew, burstCountRange: ClosedRange<Int> = 8...12) {
        self.theme = theme
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)
        let shades = theme.shadeColors

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = shades[i % shades.count]

            let mist = Self.createDewDropNode(radius: radius, color: color)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.15)...(potFrame.maxY - potFrame.height * 0.15))
            mist.position = CGPoint(x: startX, y: startY)
            mist.zPosition = 150
            mist.alpha = 0.0
            mist.setScale(0.3)
            containerNode.addChild(mist)

            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...60)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 0.90, duration: 0.15)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.70)
            floatOut.timingMode = .easeOut
            let scaleSeq = SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.25),
                SKAction.scale(to: 0.25, duration: 0.45)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ])

            let motionGroup = SKAction.group([floatOut, scaleSeq, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            mist.run(fullSeq)
        }
    }

    public static func createDewDropNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.strokeColor = UIColor.white.withAlphaComponent(0.8)
        node.lineWidth = 0.5

        let highlight = SKShapeNode(circleOfRadius: radius * 0.35)
        highlight.fillColor = .white
        highlight.strokeColor = .clear
        highlight.alpha = 0.85
        highlight.position = CGPoint(x: -radius * 0.2, y: radius * 0.2)
        node.addChild(highlight)

        return node
    }
}

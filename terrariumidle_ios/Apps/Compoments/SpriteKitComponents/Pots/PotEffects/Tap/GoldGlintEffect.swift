//
//  GoldGlintEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Ánh vàng kim" (Gold Glint)
/// - Phát ra các tia/chấm sáng vàng hoàng kim bay nhẹ lên trên và mờ dần
public final class GoldGlintEffect: PotTapEffect {

    public let name: String = "GoldGlintEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let count = Int.random(in: countRange)

        for i in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.8))
            spark.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.9) // Ánh vàng hoàng kim
            spark.strokeColor = .clear

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.25))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 150
            spark.alpha = 0.0
            containerNode.addChild(spark)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.08)
            let move = SKAction.moveBy(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: 8...24), duration: 0.38)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.24)
            let seq = SKAction.sequence([delay, fadeIn, SKAction.group([move, fadeOut]), SKAction.removeFromParent()])
            spark.run(seq)
        }
    }
}

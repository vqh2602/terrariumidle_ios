//
//  StoneDustEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bụi đá xám" (Stone Dust)
/// - Tung ra các hạt bụi đá màu xám bạc tự nhiên khi chạm vào chậu đá
public final class StoneDustEffect: PotTapEffect {

    public let name: String = "StoneDustEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let count = Int.random(in: countRange)

        for i in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.6))
            spark.fillColor = UIColor(white: 0.82, alpha: 0.85) // Bụi đá xám bạc
            spark.strokeColor = .clear

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.2)...(potFrame.maxX - potFrame.width * 0.2))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.25))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 150
            spark.alpha = 0.0
            containerNode.addChild(spark)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 0.85, duration: 0.08)
            let move = SKAction.moveBy(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: 8...22), duration: 0.38)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.24)
            let seq = SKAction.sequence([delay, fadeIn, SKAction.group([move, fadeOut]), SKAction.removeFromParent()])
            spark.run(seq)
        }
    }
}

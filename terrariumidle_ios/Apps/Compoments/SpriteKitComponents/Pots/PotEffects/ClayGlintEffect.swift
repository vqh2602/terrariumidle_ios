//
//  ClayGlintEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Ánh gốm nung" (Clay Glint)
/// - Tung ra các chấm sáng màu đất nung ấm áp khi chạm vào chậu gạch nung caro
public final class ClayGlintEffect: PotTapEffect {

    public let name: String = "ClayGlintEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let count = Int.random(in: countRange)

        for i in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.8))
            spark.fillColor = UIColor(red: 0.95, green: 0.85, blue: 0.72, alpha: 0.85) // Màu đất nung sữa ấm
            spark.strokeColor = .clear

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.2)...(potFrame.maxY - potFrame.height * 0.2))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 35
            spark.alpha = 0.0
            containerNode.addChild(spark)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.08)
            let move = SKAction.moveBy(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: 10...30), duration: 0.40)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.25)
            let seq = SKAction.sequence([delay, fadeIn, SKAction.group([move, fadeOut]), SKAction.removeFromParent()])
            spark.run(seq)
        }
    }
}

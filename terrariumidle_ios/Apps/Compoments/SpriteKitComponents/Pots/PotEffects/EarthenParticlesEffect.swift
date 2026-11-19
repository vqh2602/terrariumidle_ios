//
//  EarthenParticlesEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Hạt đất sét" (Earthen Dust / Particles)
/// - Tung ra các hạt bụi đất sét màu nâu cam mộc mạc, tự nhiên khi chạm vào
public final class EarthenParticlesEffect: PotTapEffect {

    public let name: String = "EarthenParticlesEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let count = Int.random(in: countRange)

        for i in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.6))
            spark.fillColor = UIColor(red: 0.82, green: 0.65, blue: 0.50, alpha: 0.85) // Màu đất sét nung mộc
            spark.strokeColor = .clear

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.18)...(potFrame.maxX - potFrame.width * 0.18))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.2)...(potFrame.maxY - potFrame.height * 0.2))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 35
            spark.alpha = 0.0
            containerNode.addChild(spark)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 0.85, duration: 0.08)
            let move = SKAction.moveBy(x: CGFloat.random(in: -14...14), y: CGFloat.random(in: 8...26), duration: 0.40)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.25)
            let seq = SKAction.sequence([delay, fadeIn, SKAction.group([move, fadeOut]), SKAction.removeFromParent()])
            spark.run(seq)
        }
    }
}

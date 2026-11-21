//
//  SparklePollenEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bụi phấn hoa lấp lánh" (Sparkle Pollen Effect)
/// - Tung ra các hạt bụi phấn hoa vàng kim nhấp nháy lấp lánh từ các phiến lá
public final class SparklePollenEffect: PlantTapEffect {

    public let name: String = "SparklePollenEffect"

    public init() {}

    public func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        let count = level <= 2 ? 4 : 10

        for i in 0..<count {
            let radius = CGFloat.random(in: 1.8...3.2)
            let particle = SKShapeNode(circleOfRadius: radius)
            particle.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.45, alpha: 0.95)
            particle.strokeColor = .clear

            let spawnX: CGFloat
            let spawnY: CGFloat

            if !leaves.isEmpty && Bool.random() {
                let leaf = leaves.randomElement()!
                let leafPos = leaf.parent != nil ? leaf.parent!.convert(leaf.position, to: plantNode) : leaf.position
                spawnX = leafPos.x + CGFloat.random(in: -12...12)
                spawnY = leafPos.y + CGFloat.random(in: -8...15)
            } else {
                spawnX = CGFloat.random(in: -containerSize.width * 0.38...containerSize.width * 0.38)
                spawnY = CGFloat.random(in: containerSize.height * 0.25...containerSize.height * 0.85)
            }

            particle.position = CGPoint(x: spawnX, y: spawnY)
            particle.zPosition = 200
            particle.alpha = 0.0
            plantNode.addChild(particle)

            let delay = SKAction.wait(forDuration: Double(i) * 0.03)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let move = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 20...50), duration: 0.65)
            move.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.35)
            let twinkle = SKAction.sequence([
                SKAction.scale(to: 1.4, duration: 0.15),
                SKAction.scale(to: 0.4, duration: 0.35)
            ])

            let group = SKAction.group([move, twinkle, SKAction.sequence([SKAction.wait(forDuration: 0.30), fadeOut])])
            particle.run(SKAction.sequence([delay, fadeIn, group, SKAction.removeFromParent()]))
        }
    }
}

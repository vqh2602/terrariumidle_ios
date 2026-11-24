//
//  FloatingPetalsEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Cánh hoa rơi lượn" (Floating Petals Effect)
/// - Thả những cánh hoa/lá non nhỏ rơi lượn bồng bềnh hình sin
public final class FloatingPetalsEffect: PlantTapEffect {

    public let name: String = "FloatingPetalsEffect"

    private static var petalTexture: SKTexture = {
        let width: CGFloat = 24.0
        let height: CGFloat = 38.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 1, y: 1, width: width - 2, height: height - 2)
            cgCtx.setFillColor(UIColor(red: 0.98, green: 0.65, blue: 0.75, alpha: 0.85).cgColor)
            cgCtx.fillEllipse(in: rect)
        }
        return SKTexture(image: img)
    }()

    public init() {}

    public func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        var existingCount = 0
        for child in plantNode.children where child.name == "petalParticle" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let count = min(level <= 2 ? 3 : 6, 16 - existingCount)

        for i in 0..<count {
            let petalW = CGFloat.random(in: 4.5...7.5)
            let petalH = petalW * 1.6
            let petal = SKSpriteNode(texture: Self.petalTexture, size: CGSize(width: petalW, height: petalH))
            petal.name = "petalParticle"

            let spawnX = CGFloat.random(in: -containerSize.width * 0.35...containerSize.width * 0.35)
            let spawnY = CGFloat.random(in: containerSize.height * 0.55...containerSize.height * 0.85)

            petal.position = CGPoint(x: spawnX, y: spawnY)
            petal.zPosition = 200
            petal.alpha = 0.0
            plantNode.addChild(petal)

            let delay = SKAction.wait(forDuration: Double(i) * 0.06)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.15)
            let fallDistance = CGFloat.random(in: 45...85)
            let swayX = CGFloat.random(in: -25...25)
            let fallDown = SKAction.moveBy(x: swayX, y: -fallDistance, duration: 1.2)
            fallDown.timingMode = .easeInEaseOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -2.0...2.0), duration: 1.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.45)

            let motion = SKAction.group([
                fallDown,
                rotate,
                SKAction.sequence([SKAction.wait(forDuration: 0.75), fadeOut])
            ])

            petal.run(SKAction.sequence([delay, fadeIn, motion, SKAction.removeFromParent()]))
        }
    }
}

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
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt tối đa 16
public final class EarthenParticlesEffect: PotTapEffect {

    public let name: String = "EarthenParticlesEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache
    private static var particleTexture: SKTexture?

    private static func getParticleTexture() -> SKTexture {
        if let cached = particleTexture {
            return cached
        }
        let dimension: CGFloat = 16.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 1, y: 1, width: dimension - 2, height: dimension - 2)
            cgCtx.setFillColor(UIColor(red: 0.82, green: 0.65, blue: 0.50, alpha: 0.95).cgColor)
            cgCtx.fillEllipse(in: rect)
        }
        let texture = SKTexture(image: img)
        particleTexture = texture
        return texture
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        var existingCount = 0
        for child in containerNode.children where child.name == "potEarthenParticle" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let potFrame = potNode.frame
        let burstCount = min(Int.random(in: countRange), 16 - existingCount)
        let texture = Self.getParticleTexture()

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: 1.5...2.6)
            let spark = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
            spark.name = "potEarthenParticle"

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.18)...(potFrame.maxX - potFrame.width * 0.18))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.2)...(potFrame.maxY - potFrame.height * 0.2))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 150
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

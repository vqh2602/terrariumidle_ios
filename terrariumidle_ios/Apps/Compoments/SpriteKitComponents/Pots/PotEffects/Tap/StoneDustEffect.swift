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
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt tối đa 16
public final class StoneDustEffect: PotTapEffect {

    public let name: String = "StoneDustEffect"

    public var countRange: ClosedRange<Int> = 4...6

    public init(countRange: ClosedRange<Int> = 4...6) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache
    private static var dustTexture: SKTexture?

    private static func getDustTexture() -> SKTexture {
        if let cached = dustTexture {
            return cached
        }
        let dimension: CGFloat = 16.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 1, y: 1, width: dimension - 2, height: dimension - 2)
            cgCtx.setFillColor(UIColor(white: 0.82, alpha: 0.95).cgColor)
            cgCtx.fillEllipse(in: rect)
        }
        let texture = SKTexture(image: img)
        dustTexture = texture
        return texture
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        var existingCount = 0
        for child in containerNode.children where child.name == "potStoneDust" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let potFrame = potNode.frame
        let burstCount = min(Int.random(in: countRange), 16 - existingCount)
        let texture = Self.getDustTexture()

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: 1.5...2.6)
            let spark = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
            spark.name = "potStoneDust"

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

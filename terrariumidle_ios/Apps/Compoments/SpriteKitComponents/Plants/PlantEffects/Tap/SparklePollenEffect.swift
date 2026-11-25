//
//  SparklePollenEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bụi phấn hoa lấp lánh" (Sparkle Pollen Effect)
/// - Tung ra các hạt bụi phấn hoa nhấp nháy lấp lánh nhiều sắc độ từ các phiến lá
public final class SparklePollenEffect: PlantTapEffect {

    // MARK: - Themes

    public enum Theme: CaseIterable, Hashable {
        case golden           // Vàng kim / hổ phách ấm áp (mặc định)
        case floralPink       // Hồng phấn / hồng đào rạng rỡ
        case emeraldMint      // Xanh ngọc / bạc hà tươi mát
        case aquaFrost        // Xanh băng / lam ngọc thanh khiết
        case lavenderAmethyst // Tím thạch anh / oải hương huyền bí
        case sunsetCoral      // Cam san hô / vàng nắng rực rỡ
        case multicolor       // Đa sắc lấp lánh (vàng, hồng, ngọc, tím, trắng)

        public var shadeColors: [UIColor] {
            switch self {
            case .golden:
                return [
                    UIColor(red: 1.00, green: 0.92, blue: 0.45, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.82, blue: 0.28, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.97, blue: 0.72, alpha: 0.92)
                ]
            case .floralPink:
                return [
                    UIColor(red: 1.00, green: 0.70, blue: 0.84, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.84, blue: 0.92, alpha: 0.94),
                    UIColor(red: 0.96, green: 0.54, blue: 0.74, alpha: 0.95)
                ]
            case .emeraldMint:
                return [
                    UIColor(red: 0.45, green: 0.96, blue: 0.72, alpha: 0.95),
                    UIColor(red: 0.72, green: 1.00, blue: 0.84, alpha: 0.94),
                    UIColor(red: 0.85, green: 0.98, blue: 0.56, alpha: 0.92)
                ]
            case .aquaFrost:
                return [
                    UIColor(red: 0.55, green: 0.92, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.82, green: 0.97, blue: 1.00, alpha: 0.94),
                    UIColor(red: 0.36, green: 0.80, blue: 0.98, alpha: 0.95)
                ]
            case .lavenderAmethyst:
                return [
                    UIColor(red: 0.82, green: 0.64, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.92, green: 0.80, blue: 1.00, alpha: 0.94),
                    UIColor(red: 0.72, green: 0.46, blue: 0.94, alpha: 0.95)
                ]
            case .sunsetCoral:
                return [
                    UIColor(red: 1.00, green: 0.64, blue: 0.44, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.84, blue: 0.46, alpha: 0.95),
                    UIColor(red: 0.98, green: 0.48, blue: 0.52, alpha: 0.95)
                ]
            case .multicolor:
                return [
                    UIColor(red: 1.00, green: 0.92, blue: 0.45, alpha: 0.95), // Gold
                    UIColor(red: 1.00, green: 0.70, blue: 0.84, alpha: 0.95), // Pink
                    UIColor(red: 0.48, green: 0.95, blue: 0.74, alpha: 0.95), // Mint
                    UIColor(red: 0.56, green: 0.90, blue: 1.00, alpha: 0.95), // Aqua
                    UIColor(red: 0.84, green: 0.68, blue: 1.00, alpha: 0.95), // Lavender
                    UIColor(red: 1.00, green: 0.98, blue: 0.92, alpha: 0.95)  // Pearl
                ]
            }
        }
    }

    // MARK: - Texture Cache

    private struct TextureCacheKey: Hashable {
        let theme: Theme
        let shadeIndex: Int
    }

    private static var textureCache: [TextureCacheKey: SKTexture] = [:]

    private static func getPollenTexture(theme: Theme, shadeIndex: Int) -> SKTexture {
        let shades = theme.shadeColors
        let safeIndex = max(0, min(shadeIndex, shades.count - 1))
        let key = TextureCacheKey(theme: theme, shadeIndex: safeIndex)

        if let cached = textureCache[key] {
            return cached
        }

        let dimension: CGFloat = 24.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 1, y: 1, width: dimension - 2, height: dimension - 2)
            cgCtx.setFillColor(shades[safeIndex].cgColor)
            cgCtx.fillEllipse(in: rect)
        }
        let texture = SKTexture(image: img)
        textureCache[key] = texture
        return texture
    }

    // MARK: - Properties

    public let name: String = "SparklePollenEffect"
    public var theme: Theme = .golden

    public init(theme: Theme = .golden) {
        self.theme = theme
    }

    public func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        var existingCount = 0
        for child in plantNode.children where child.name == "pollenParticle" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let count = min(level <= 2 ? 4 : 10, 16 - existingCount)
        let shadeCount = theme.shadeColors.count

        for i in 0..<count {
            let texture = Self.getPollenTexture(theme: theme, shadeIndex: Int.random(in: 0..<shadeCount))
            let radius = CGFloat.random(in: 1.8...3.2)
            let particle = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
            particle.name = "pollenParticle"

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

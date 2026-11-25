//
//  FloatingPetalsEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Cánh hoa rơi lượn" (Floating Petals Effect)
/// - Thả những cánh hoa/lá non nhỏ nhiều sắc độ rơi lượn bồng bềnh hình sin
public final class FloatingPetalsEffect: PlantTapEffect {

    // MARK: - Themes

    public enum Theme: CaseIterable, Hashable {
        case sakuraPink     // Hồng anh đào / hồng phấn (mặc định)
        case autumnLeaves   // Lá mùa thu: cam cháy / vàng hổ phách / đỏ phong
        case emeraldLeaves  // Lá non xanh ngọc / xanh bạc hà / xanh lá
        case lavender       // Cánh hoa oải hương: tím nhạt / tím thạch anh
        case lotusWhite     // Bạch liên: trắng ngà / hồng phớt / vàng nhụy
        case goldenSun      // Cánh hoa vàng: vàng nắng / vàng cúc / cam nhạt
        case multicolor     // Đa sắc cánh hoa rơi

        public var shadeColors: [UIColor] {
            switch self {
            case .sakuraPink:
                return [
                    UIColor(red: 0.98, green: 0.65, blue: 0.75, alpha: 0.88),
                    UIColor(red: 1.00, green: 0.80, blue: 0.88, alpha: 0.86),
                    UIColor(red: 0.95, green: 0.50, blue: 0.66, alpha: 0.88)
                ]
            case .autumnLeaves:
                return [
                    UIColor(red: 0.95, green: 0.48, blue: 0.24, alpha: 0.88),
                    UIColor(red: 0.96, green: 0.72, blue: 0.28, alpha: 0.88),
                    UIColor(red: 0.84, green: 0.28, blue: 0.24, alpha: 0.88)
                ]
            case .emeraldLeaves:
                return [
                    UIColor(red: 0.36, green: 0.84, blue: 0.56, alpha: 0.88),
                    UIColor(red: 0.54, green: 0.92, blue: 0.68, alpha: 0.86),
                    UIColor(red: 0.24, green: 0.72, blue: 0.46, alpha: 0.88)
                ]
            case .lavender:
                return [
                    UIColor(red: 0.78, green: 0.64, blue: 0.96, alpha: 0.88),
                    UIColor(red: 0.88, green: 0.78, blue: 0.99, alpha: 0.86),
                    UIColor(red: 0.68, green: 0.48, blue: 0.90, alpha: 0.88)
                ]
            case .lotusWhite:
                return [
                    UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 0.90),
                    UIColor(red: 1.00, green: 0.88, blue: 0.92, alpha: 0.88),
                    UIColor(red: 0.98, green: 0.94, blue: 0.78, alpha: 0.86)
                ]
            case .goldenSun:
                return [
                    UIColor(red: 1.00, green: 0.86, blue: 0.36, alpha: 0.88),
                    UIColor(red: 1.00, green: 0.93, blue: 0.56, alpha: 0.86),
                    UIColor(red: 0.98, green: 0.72, blue: 0.28, alpha: 0.88)
                ]
            case .multicolor:
                return [
                    UIColor(red: 0.98, green: 0.65, blue: 0.75, alpha: 0.88), // Sakura
                    UIColor(red: 1.00, green: 0.86, blue: 0.38, alpha: 0.88), // Gold
                    UIColor(red: 0.78, green: 0.64, blue: 0.96, alpha: 0.88), // Lavender
                    UIColor(red: 0.48, green: 0.90, blue: 0.68, alpha: 0.88), // Mint
                    UIColor(red: 1.00, green: 0.62, blue: 0.46, alpha: 0.88), // Coral
                    UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 0.88)  // White
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

    private static func getPetalTexture(theme: Theme, shadeIndex: Int) -> SKTexture {
        let shades = theme.shadeColors
        let safeIndex = max(0, min(shadeIndex, shades.count - 1))
        let key = TextureCacheKey(theme: theme, shadeIndex: safeIndex)

        if let cached = textureCache[key] {
            return cached
        }

        let width: CGFloat = 24.0
        let height: CGFloat = 38.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 1, y: 1, width: width - 2, height: height - 2)
            cgCtx.setFillColor(shades[safeIndex].cgColor)
            cgCtx.fillEllipse(in: rect)
        }
        let texture = SKTexture(image: img)
        textureCache[key] = texture
        return texture
    }

    // MARK: - Properties

    public let name: String = "FloatingPetalsEffect"
    public var theme: Theme = .sakuraPink

    public init(theme: Theme = .sakuraPink) {
        self.theme = theme
    }

    public func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        var existingCount = 0
        for child in plantNode.children where child.name == "petalParticle" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let count = min(level <= 2 ? 3 : 6, 16 - existingCount)
        let shadeCount = theme.shadeColors.count

        for i in 0..<count {
            let texture = Self.getPetalTexture(theme: theme, shadeIndex: Int.random(in: 0..<shadeCount))
            let petalW = CGFloat.random(in: 4.5...7.5)
            let petalH = petalW * 1.6
            let petal = SKSpriteNode(texture: texture, size: CGSize(width: petalW, height: petalH))
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

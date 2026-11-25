//
//  SparkleBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Đá lấp lánh" (Sparkle Glitter Burst)
/// - Tung ra chùm ngôi sao 4 cánh nhọn phát sáng lấp lánh, xoay 360 độ và bung toả quanh chậu
public final class SparkleBurstEffect: PotTapEffect {

    public enum Theme: CaseIterable, Hashable {
        case classic      // Vàng hoàng yến & Hồng phấn (mặc định)
        case golden       // Vàng kim, Hổ phách, Kem nắng
        case emeraldJade  // Xanh ngọc bích, Bạc hà, Trắng ngọc
        case sapphireAqua // Xanh lam ngọc, Xanh băng, Tím chàm
        case amethystRose // Tím thạch anh, Hồng phấn, Oải hương
        case rainbow      // Đa sắc cầu vồng rực rỡ

        public var shadeColors: [UIColor] {
            switch self {
            case .classic:
                return [
                    UIColor(red: 1.00, green: 0.92, blue: 0.55, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.65, blue: 0.78, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.97, blue: 0.88, alpha: 0.95)
                ]
            case .golden:
                return [
                    UIColor(red: 1.00, green: 0.88, blue: 0.38, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.76, blue: 0.24, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.96, blue: 0.68, alpha: 0.95)
                ]
            case .emeraldJade:
                return [
                    UIColor(red: 0.42, green: 0.94, blue: 0.72, alpha: 0.95),
                    UIColor(red: 0.66, green: 0.98, blue: 0.86, alpha: 0.95),
                    UIColor(red: 0.28, green: 0.82, blue: 0.64, alpha: 0.95)
                ]
            case .sapphireAqua:
                return [
                    UIColor(red: 0.44, green: 0.86, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.72, green: 0.94, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.46, green: 0.64, blue: 0.98, alpha: 0.95)
                ]
            case .amethystRose:
                return [
                    UIColor(red: 0.82, green: 0.56, blue: 0.98, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.68, blue: 0.86, alpha: 0.95),
                    UIColor(red: 0.90, green: 0.82, blue: 1.00, alpha: 0.95)
                ]
            case .rainbow:
                return [
                    UIColor(red: 1.00, green: 0.90, blue: 0.45, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.64, blue: 0.80, alpha: 0.95),
                    UIColor(red: 0.44, green: 0.94, blue: 0.72, alpha: 0.95),
                    UIColor(red: 0.46, green: 0.86, blue: 1.00, alpha: 0.95),
                    UIColor(red: 0.82, green: 0.62, blue: 1.00, alpha: 0.95),
                    UIColor(red: 1.00, green: 0.66, blue: 0.46, alpha: 0.95)
                ]
            }
        }
    }

    public let name: String = "SparkleBurstEffect"

    public var theme: Theme = .classic
    public var burstCountRange: ClosedRange<Int> = 7...10
    public var minRadius: CGFloat = 4.0
    public var maxRadius: CGFloat = 6.5

    public init(theme: Theme = .classic, burstCountRange: ClosedRange<Int> = 7...10) {
        self.theme = theme
        self.burstCountRange = burstCountRange
    }

    // MARK: - Texture Cache (Tối ưu Metal Batching)
    private struct TextureCacheKey: Hashable {
        let theme: Theme
        let shadeIndex: Int
    }

    private static var starTextureCache: [TextureCacheKey: SKTexture] = [:]

    private static func getStarTexture(theme: Theme, shadeIndex: Int) -> SKTexture {
        let shades = theme.shadeColors
        let safeIndex = max(0, min(shadeIndex, shades.count - 1))
        let key = TextureCacheKey(theme: theme, shadeIndex: safeIndex)

        if let cached = starTextureCache[key] {
            return cached
        }
        let dimension: CGFloat = 40.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dimension / 2, y: dimension / 2)
            let r = (dimension - 4) / 2
            let innerR = r * 0.25

            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - r))
            path.addLine(to: CGPoint(x: center.x + innerR, y: center.y - innerR))
            path.addLine(to: CGPoint(x: center.x + r, y: center.y))
            path.addLine(to: CGPoint(x: center.x + innerR, y: center.y + innerR))
            path.addLine(to: CGPoint(x: center.x, y: center.y + r))
            path.addLine(to: CGPoint(x: center.x - innerR, y: center.y + innerR))
            path.addLine(to: CGPoint(x: center.x - r, y: center.y))
            path.addLine(to: CGPoint(x: center.x - innerR, y: center.y - innerR))
            path.closeSubpath()

            cgCtx.addPath(path)
            cgCtx.setFillColor(shades[safeIndex].cgColor)
            cgCtx.fillPath()

            cgCtx.addPath(path)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
            cgCtx.setLineWidth(1.0)
            cgCtx.strokePath()

            // Điểm sáng trắng trung tâm
            let dotRect = CGRect(x: center.x - innerR * 0.8, y: center.y - innerR * 0.8, width: innerR * 1.6, height: innerR * 1.6)
            cgCtx.setFillColor(UIColor.white.cgColor)
            cgCtx.fillEllipse(in: dotRect)
        }
        let texture = SKTexture(image: img)
        starTextureCache[key] = texture
        return texture
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        var existingCount = 0
        for child in containerNode.children where child.name == "potSparkle" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let potFrame = potNode.frame
        let burstCount = min(Int.random(in: burstCountRange), 16 - existingCount)
        let shadeCount = theme.shadeColors.count

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let texture = Self.getStarTexture(theme: theme, shadeIndex: i % shadeCount)

            let star = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
            star.name = "potSparkle"

            // Vị trí xuất phát từ lòng/thân chậu (xử lý chính xác dựa trên frame chuẩn của potNode)
            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.18)...(potFrame.maxY - potFrame.height * 0.15))
            star.position = CGPoint(x: startX, y: startY)
            star.zPosition = 150
            star.alpha = 0.0
            star.setScale(0.25)
            containerNode.addChild(star)

            // Góc bay toả đều 360 độ xung quanh chậu
            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...60)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.025)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.55)
            floatOut.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.0...3.0), duration: 0.55)
            let scalePulse = SKAction.sequence([
                SKAction.scale(to: 1.35, duration: 0.18),
                SKAction.scale(to: 0.25, duration: 0.37)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.22),
                SKAction.fadeOut(withDuration: 0.33)
            ])

            let motionGroup = SKAction.group([floatOut, rotate, scalePulse, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            star.run(fullSeq)
        }
    }

    // MARK: - Helper tạo hình ngôi sao 4 cánh lấp lánh (4-Point Diamond Star)

    public static func createStarSparkleNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let path = CGMutablePath()
        let r = radius
        let innerR = radius * 0.25

        // Ngôi sao 4 cánh nhọn tỏa sáng
        path.move(to: CGPoint(x: 0, y: r))
        path.addLine(to: CGPoint(x: innerR, y: innerR))
        path.addLine(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: innerR, y: -innerR))
        path.addLine(to: CGPoint(x: 0, y: -r))
        path.addLine(to: CGPoint(x: -innerR, y: -innerR))
        path.addLine(to: CGPoint(x: -r, y: 0))
        path.addLine(to: CGPoint(x: -innerR, y: innerR))
        path.closeSubpath()

        let starNode = SKShapeNode(path: path)
        starNode.fillColor = color
        starNode.strokeColor = UIColor.white.withAlphaComponent(0.8)
        starNode.lineWidth = 0.5

        // Điểm sáng trắng trung tâm
        let centerPoint = SKShapeNode(circleOfRadius: innerR * 0.8)
        centerPoint.fillColor = .white
        centerPoint.strokeColor = .clear
        starNode.addChild(centerPoint)

        return starNode
    }
}

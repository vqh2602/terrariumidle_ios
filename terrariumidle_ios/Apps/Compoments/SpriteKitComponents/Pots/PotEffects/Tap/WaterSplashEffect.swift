//
//  WaterSplashEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 27/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Nước bắn ra ngoài" (Water Splash Effect)
/// - Khi tap vào chậu nước (như chậu sen Pot31), tung ra chùm giọt nước trong suốt bắn văng lên và tỏa ra hai bên miệng chậu theo quỹ đạo parabol rơi tự do.
/// - zPosition chuẩn = 150 (hiển thị nổi bật trước thân chậu z = 50 và dưới hiệu ứng cây z = 200).
public final class WaterSplashEffect: PotTapEffect {

    public enum Theme: CaseIterable, Hashable {
        case crystalAqua  // Xanh nước trong veo & trắng bọt (mặc định)
        case lotusDew     // Nước ngọc lam dịu nhẹ ánh hồng sen
        case oceanSpray   // Xanh biển đậm & bọt trắng

        public var shadeColors: [UIColor] {
            switch self {
            case .crystalAqua:
                return [
                    UIColor(red: 0.48, green: 0.88, blue: 1.00, alpha: 0.90),
                    UIColor(red: 0.72, green: 0.95, blue: 1.00, alpha: 0.88),
                    UIColor(red: 0.30, green: 0.76, blue: 0.96, alpha: 0.92),
                    UIColor(red: 0.92, green: 0.98, blue: 1.00, alpha: 0.85)
                ]
            case .lotusDew:
                return [
                    UIColor(red: 0.56, green: 0.92, blue: 0.96, alpha: 0.90),
                    UIColor(red: 0.82, green: 0.97, blue: 1.00, alpha: 0.88),
                    UIColor(red: 0.98, green: 0.86, blue: 0.92, alpha: 0.82)
                ]
            case .oceanSpray:
                return [
                    UIColor(red: 0.20, green: 0.72, blue: 0.95, alpha: 0.92),
                    UIColor(red: 0.45, green: 0.86, blue: 0.98, alpha: 0.88),
                    UIColor(red: 0.88, green: 0.97, blue: 1.00, alpha: 0.90)
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

    private static func getDropletTexture(theme: Theme, shadeIndex: Int) -> SKTexture {
        let shades = theme.shadeColors
        let safeIndex = max(0, min(shadeIndex, shades.count - 1))
        let key = TextureCacheKey(theme: theme, shadeIndex: safeIndex)

        if let cached = textureCache[key] {
            return cached
        }

        let size = CGSize(width: 22, height: 28)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let w = size.width
            let h = size.height

            // Hình giọt nước thon nhọn phía trên, tròn đầy phía dưới
            let path = UIBezierPath()
            path.move(to: CGPoint(x: w * 0.5, y: 2))
            path.addCurve(
                to: CGPoint(x: w - 2, y: h * 0.62),
                controlPoint1: CGPoint(x: w * 0.68, y: h * 0.25),
                controlPoint2: CGPoint(x: w - 2, y: h * 0.42)
            )
            path.addArc(
                withCenter: CGPoint(x: w * 0.5, y: h * 0.62),
                radius: (w - 4) * 0.5,
                startAngle: 0,
                endAngle: .pi,
                clockwise: true
            )
            path.addCurve(
                to: CGPoint(x: w * 0.5, y: 2),
                controlPoint1: CGPoint(x: 2, y: h * 0.42),
                controlPoint2: CGPoint(x: w * 0.32, y: h * 0.25)
            )
            path.close()

            cgCtx.addPath(path.cgPath)
            cgCtx.setFillColor(shades[safeIndex].cgColor)
            cgCtx.fillPath()

            cgCtx.addPath(path.cgPath)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.75).cgColor)
            cgCtx.setLineWidth(1.2)
            cgCtx.strokePath()

            // Điểm sáng phản chiếu 3D
            cgCtx.setFillColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            cgCtx.fillEllipse(in: CGRect(x: w * 0.28, y: h * 0.52, width: w * 0.22, height: w * 0.22))
        }

        let texture = SKTexture(image: img)
        textureCache[key] = texture
        return texture
    }

    // MARK: - Properties

    public let name: String = "WaterSplashEffect"
    public var theme: Theme = .crystalAqua
    public var splashCountRange: ClosedRange<Int> = 12...16

    public init(theme: Theme = .crystalAqua, splashCountRange: ClosedRange<Int> = 12...16) {
        self.theme = theme
        self.splashCountRange = splashCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let count = Int.random(in: splashCountRange)
        let shadesCount = theme.shadeColors.count

        let rimY = isHanging
            ? (potFrame.maxY - potFrame.height * 0.14)
            : (potFrame.maxY - potFrame.height * 0.12)

        for i in 0..<count {
            let shadeIndex = i % shadesCount
            let texture = Self.getDropletTexture(theme: theme, shadeIndex: shadeIndex)
            let dropSize = CGFloat.random(in: 5.5...10.5)

            let droplet = SKSpriteNode(texture: texture, size: CGSize(width: dropSize * 0.78, height: dropSize))
            let spreadFactor = CGFloat.random(in: -0.38...0.38)
            let startX = potFrame.midX + potFrame.width * spreadFactor
            let startY = rimY + CGFloat.random(in: -4...4)

            droplet.position = CGPoint(x: startX, y: startY)
            droplet.zPosition = 150
            droplet.alpha = 0.0
            droplet.setScale(0.35)
            containerNode.addChild(droplet)

            // Hướng văng ra ngoài miệng chậu (trái/phải theo vị trí xuất phát)
            let sideSign: CGFloat = spreadFactor >= 0 ? 1.0 : -1.0
            let outX = sideSign * CGFloat.random(in: 18...52)
            let peakY = CGFloat.random(in: 24...58)
            let dropY = peakY + CGFloat.random(in: 18...38)

            let upDuration = Double.random(in: 0.18...0.26)
            let downDuration = Double.random(in: 0.24...0.34)
            let delay = SKAction.wait(forDuration: Double(i % 4) * 0.015)

            let moveUp = SKAction.moveBy(x: outX * 0.52, y: peakY, duration: upDuration)
            moveUp.timingMode = .easeOut

            let moveDown = SKAction.moveBy(x: outX * 0.48, y: -dropY, duration: downDuration)
            moveDown.timingMode = .easeIn

            // Xoay giọt nước nghiêng theo hướng bắn
            let tiltAngle: CGFloat = -sideSign * CGFloat.random(in: 0.35...0.85)
            let rotateOut = SKAction.rotate(toAngle: tiltAngle, duration: upDuration + downDuration)

            let scalePop = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: upDuration * 0.6),
                SKAction.scale(to: 0.45, duration: upDuration * 0.4 + downDuration)
            ])

            let fadeSeq = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.95, duration: 0.06),
                SKAction.wait(forDuration: upDuration * 0.6),
                SKAction.fadeOut(withDuration: downDuration + upDuration * 0.4)
            ])

            let arcMotion = SKAction.sequence([moveUp, moveDown])
            let group = SKAction.group([arcMotion, rotateOut, scalePop, fadeSeq])

            droplet.run(SKAction.sequence([delay, group, SKAction.removeFromParent()]))
        }
    }
}

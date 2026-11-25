//
//  GoldGlintEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Ánh vàng kim" (Gold Glint)
/// - Quét vệt ánh kim hoàng gia lướt ngang thân chậu kết hợp chùm tia sao vàng 4 cánh và mảnh vàng lá lấp lánh
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt
public final class GoldGlintEffect: PotTapEffect {

    public let name: String = "GoldGlintEffect"

    public var countRange: ClosedRange<Int> = 8...11

    public init(countRange: ClosedRange<Int> = 8...11) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache

    private enum GoldKind: Int {
        case crossFlare
        case goldLeaf
    }

    private static var textureCache: [GoldKind: SKTexture] = [:]
    private static var streakTexture: SKTexture?

    private static func getParticleTexture(kind: GoldKind) -> SKTexture {
        if let cached = textureCache[kind] {
            return cached
        }
        let texture: SKTexture
        switch kind {
        case .crossFlare:
            texture = renderCrossFlareTexture()
        case .goldLeaf:
            texture = renderGoldLeafTexture()
        }
        textureCache[kind] = texture
        return texture
    }

    private static func getStreakTexture() -> SKTexture {
        if let cached = streakTexture {
            return cached
        }
        let tex = PotTapEffectHelper.createSheenStreakTexture(
            width: 110.0,
            height: 26.0,
            coreColor: UIColor(red: 1.0, green: 0.98, blue: 0.85, alpha: 0.95),
            glowColor: UIColor(red: 1.0, green: 0.78, blue: 0.18, alpha: 0.85)
        )
        streakTexture = tex
        return tex
    }

    private static func renderCrossFlareTexture() -> SKTexture {
        let dim: CGFloat = 52.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dim * 0.5, y: dim * 0.5)

            // Vầng hào quang vàng hổ phách mềm ở trung tâm
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let haloColors = [
                UIColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 0.75).cgColor,
                UIColor(red: 1.0, green: 0.70, blue: 0.10, alpha: 0.0).cgColor
            ] as CFArray
            if let grad = CGGradient(colorsSpace: colorSpace, colors: haloColors, locations: [0.0, 1.0]) {
                cgCtx.drawRadialGradient(
                    grad,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: dim * 0.44,
                    options: .drawsAfterEndLocation
                )
            }

            // Ngôi sao 4 cánh vươn dài sắc nét (dáng ánh kim phản chiếu)
            let rLong = dim * 0.45
            let rShort = dim * 0.36
            let inner = dim * 0.09
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - rLong))
            path.addLine(to: CGPoint(x: center.x + inner, y: center.y - inner))
            path.addLine(to: CGPoint(x: center.x + rShort, y: center.y))
            path.addLine(to: CGPoint(x: center.x + inner, y: center.y + inner))
            path.addLine(to: CGPoint(x: center.x, y: center.y + rLong))
            path.addLine(to: CGPoint(x: center.x - inner, y: center.y + inner))
            path.addLine(to: CGPoint(x: center.x - rShort, y: center.y))
            path.addLine(to: CGPoint(x: center.x - inner, y: center.y - inner))
            path.closeSubpath()

            cgCtx.addPath(path)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.24, alpha: 1.0).cgColor)
            cgCtx.fillPath()

            // Viền vàng đồng mảnh giúp nổi bật trên cả nền sáng
            cgCtx.addPath(path)
            cgCtx.setStrokeColor(UIColor(red: 0.82, green: 0.50, blue: 0.05, alpha: 0.80).cgColor)
            cgCtx.setLineWidth(1.2)
            cgCtx.strokePath()

            // Lõi sáng trắng vàng chói ở giữa
            let coreRect = CGRect(x: center.x - inner * 0.9, y: center.y - inner * 0.9, width: inner * 1.8, height: inner * 1.8)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.99, blue: 0.92, alpha: 1.0).cgColor)
            cgCtx.fillEllipse(in: coreRect)
        }
        return SKTexture(image: img)
    }

    private static func renderGoldLeafTexture() -> SKTexture {
        let w: CGFloat = 32.0
        let h: CGFloat = 36.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: w * 0.5, y: h * 0.5)
            let rw = w * 0.36
            let rh = h * 0.40

            // Nửa trên trái sáng champagne
            let topFacet = CGMutablePath()
            topFacet.move(to: CGPoint(x: center.x, y: center.y - rh))
            topFacet.addLine(to: CGPoint(x: center.x + rw, y: center.y))
            topFacet.addLine(to: CGPoint(x: center.x - rw, y: center.y))
            topFacet.closeSubpath()

            cgCtx.addPath(topFacet)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.93, blue: 0.55, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            // Nửa dưới phải vàng hoàng kim đậm tạo độ khối ánh kim
            let bottomFacet = CGMutablePath()
            bottomFacet.move(to: CGPoint(x: center.x - rw, y: center.y))
            bottomFacet.addLine(to: CGPoint(x: center.x + rw, y: center.y))
            bottomFacet.addLine(to: CGPoint(x: center.x, y: center.y + rh))
            bottomFacet.closeSubpath()

            cgCtx.addPath(bottomFacet)
            cgCtx.setFillColor(UIColor(red: 0.94, green: 0.64, blue: 0.08, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            // Viền vàng hổ phách sắc nét
            let border = CGMutablePath()
            border.move(to: CGPoint(x: center.x, y: center.y - rh))
            border.addLine(to: CGPoint(x: center.x + rw, y: center.y))
            border.addLine(to: CGPoint(x: center.x, y: center.y + rh))
            border.addLine(to: CGPoint(x: center.x - rw, y: center.y))
            border.closeSubpath()
            cgCtx.addPath(border)
            cgCtx.setStrokeColor(UIColor(red: 0.68, green: 0.38, blue: 0.02, alpha: 0.78).cgColor)
            cgCtx.setLineWidth(1.3)
            cgCtx.strokePath()
        }
        return SKTexture(image: img)
    }

    // MARK: - Trigger

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = PotTapEffectHelper.resolvedPotFrame(for: potNode, in: containerNode)
        let scale = PotTapEffectHelper.scaleFactor(for: potFrame)

        // 1. Vệt ánh kim quét chéo lướt ngang mặt chậu (chỉ chạy 1 vệt tại một thời điểm)
        if containerNode.childNode(withName: "potGoldStreak") == nil {
            let streak = SKSpriteNode(
                texture: Self.getStreakTexture(),
                size: CGSize(width: max(68.0, potFrame.width * 0.78), height: 18.0 * scale)
            )
            streak.name = "potGoldStreak"
            streak.zPosition = 152
            streak.zRotation = 0.42
            streak.alpha = 0.0
            streak.setScale(0.65)
            streak.position = CGPoint(
                x: potFrame.minX + potFrame.width * 0.25,
                y: potFrame.minY + potFrame.height * 0.35
            )
            containerNode.addChild(streak)

            let glide = SKAction.move(
                to: CGPoint(x: potFrame.maxX - potFrame.width * 0.22, y: potFrame.maxY - potFrame.height * 0.28),
                duration: 0.34
            )
            glide.timingMode = .easeInEaseOut

            let streakPulse = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.95, duration: 0.12),
                    SKAction.scale(to: 1.10, duration: 0.12)
                ]),
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.22),
                    SKAction.scale(to: 0.75, duration: 0.22)
                ])
            ])
            streak.run(SKAction.sequence([
                SKAction.group([glide, streakPulse]),
                SKAction.removeFromParent()
            ]))
        }

        // 2. Chùm tia sao vàng & mảnh vàng lá bung tỏa lấp lánh
        let budget = PotTapEffectHelper.remainingBudget(in: containerNode, nodeName: "potGoldGlint", maxActive: 22)
        guard budget > 0 else { return }
        let burstCount = min(Int.random(in: countRange), budget)

        for i in 0..<burstCount {
            let isFlare = (i % 2 == 0)
            let kind: GoldKind = isFlare ? .crossFlare : .goldLeaf
            let texture = Self.getParticleTexture(kind: kind)

            let baseSize = isFlare
                ? CGFloat.random(in: 12.0...19.0) * scale
                : CGFloat.random(in: 7.5...12.0) * scale
            let nodeSize = isFlare
                ? CGSize(width: baseSize, height: baseSize)
                : CGSize(width: baseSize, height: baseSize * 1.15)

            let spark = SKSpriteNode(texture: texture, size: nodeSize)
            spark.name = "potGoldGlint"

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.12)...(potFrame.maxX - potFrame.width * 0.12))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.18)...(potFrame.maxY - potFrame.height * 0.14))
            spark.position = CGPoint(x: startX, y: startY)
            spark.zPosition = 150
            spark.alpha = 0.0
            spark.setScale(0.20)
            containerNode.addChild(spark)

            let flyAngle = CGFloat.random(in: 0.08 * .pi ... 0.92 * .pi)
            let distance = CGFloat.random(in: 28.0...62.0) * scale
            let dx = cos(flyAngle) * distance * 0.85
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.022)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.09)

            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.62)
            floatOut.timingMode = .easeOut

            let rotate = SKAction.rotate(
                byAngle: isFlare ? CGFloat.random(in: -1.4...1.4) : CGFloat.random(in: -3.2...3.2),
                duration: 0.62
            )

            // Nhịp nháy lấp lánh 2 lần đặc trưng ánh kim
            let twinkle = SKAction.sequence([
                SKAction.scale(to: 1.32, duration: 0.14),
                SKAction.scale(to: 0.78, duration: 0.12),
                SKAction.scale(to: 1.16, duration: 0.12),
                SKAction.scale(to: 0.18, duration: 0.24)
            ])

            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.28),
                SKAction.fadeOut(withDuration: 0.34)
            ])

            let seq = SKAction.sequence([
                delay,
                fadeIn,
                SKAction.group([floatOut, rotate, twinkle, fadeOut]),
                SKAction.removeFromParent()
            ])
            spark.run(seq)
        }
    }
}

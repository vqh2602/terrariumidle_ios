//
//  ClayGlintEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Ánh gốm nung" (Clay Glint)
/// - Phản chiếu vệt bóng men gốm ấm áp kết hợp chùm ánh sáng men gốm nung cam đào & mảnh gốm tráng men sắc nét
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt
public final class ClayGlintEffect: PotTapEffect {

    public let name: String = "ClayGlintEffect"

    public var countRange: ClosedRange<Int> = 8...11

    public init(countRange: ClosedRange<Int> = 8...11) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache

    private enum ClayKind: Int {
        case glazeSparkle
        case ceramicTileFacet
    }

    private static var textureCache: [ClayKind: SKTexture] = [:]
    private static var sheenTexture: SKTexture?

    private static func getParticleTexture(kind: ClayKind) -> SKTexture {
        if let cached = textureCache[kind] {
            return cached
        }
        let texture: SKTexture
        switch kind {
        case .glazeSparkle:
            texture = renderGlazeSparkleTexture()
        case .ceramicTileFacet:
            texture = renderCeramicTileTexture()
        }
        textureCache[kind] = texture
        return texture
    }

    private static func getSheenTexture() -> SKTexture {
        if let cached = sheenTexture {
            return cached
        }
        let tex = PotTapEffectHelper.createSheenStreakTexture(
            width: 96.0,
            height: 24.0,
            coreColor: UIColor(red: 1.0, green: 0.95, blue: 0.88, alpha: 0.92),
            glowColor: UIColor(red: 0.96, green: 0.56, blue: 0.36, alpha: 0.78)
        )
        sheenTexture = tex
        return tex
    }

    private static func renderGlazeSparkleTexture() -> SKTexture {
        let dim: CGFloat = 48.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dim * 0.5, y: dim * 0.5)

            // Vầng sáng men nung ấm áp
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let haloColors = [
                UIColor(red: 0.98, green: 0.62, blue: 0.42, alpha: 0.72).cgColor,
                UIColor(red: 0.90, green: 0.44, blue: 0.26, alpha: 0.0).cgColor
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

            // Ngôi sao 4 cánh bo cong mềm mại mang nét men sứ ấm
            let r = dim * 0.42
            let ctrl = dim * 0.11
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - r))
            path.addQuadCurve(to: CGPoint(x: center.x + r, y: center.y), control: CGPoint(x: center.x + ctrl, y: center.y - ctrl))
            path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + r), control: CGPoint(x: center.x + ctrl, y: center.y + ctrl))
            path.addQuadCurve(to: CGPoint(x: center.x - r, y: center.y), control: CGPoint(x: center.x - ctrl, y: center.y + ctrl))
            path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - r), control: CGPoint(x: center.x - ctrl, y: center.y - ctrl))
            path.closeSubpath()

            cgCtx.addPath(path)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.66, blue: 0.45, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            cgCtx.addPath(path)
            cgCtx.setStrokeColor(UIColor(red: 0.76, green: 0.28, blue: 0.14, alpha: 0.85).cgColor)
            cgCtx.setLineWidth(1.3)
            cgCtx.strokePath()

            // Lõi sáng kem sứ ấm ở tâm
            let coreRadius = dim * 0.11
            let coreRect = CGRect(x: center.x - coreRadius, y: center.y - coreRadius, width: coreRadius * 2, height: coreRadius * 2)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.96, blue: 0.89, alpha: 1.0).cgColor)
            cgCtx.fillEllipse(in: coreRect)
        }
        return SKTexture(image: img)
    }

    private static func renderCeramicTileTexture() -> SKTexture {
        let dim: CGFloat = 34.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dim * 0.5, y: dim * 0.5)
            let r = dim * 0.36

            // Mảnh gốm hình thoi chia 2 mặt men sáng/ấm đặc trưng họa tiết caro & gốm nung
            let topLeft = CGMutablePath()
            topLeft.move(to: CGPoint(x: center.x, y: center.y - r))
            topLeft.addLine(to: CGPoint(x: center.x + r, y: center.y))
            topLeft.addLine(to: CGPoint(x: center.x - r, y: center.y))
            topLeft.closeSubpath()
            cgCtx.addPath(topLeft)
            cgCtx.setFillColor(UIColor(red: 1.0, green: 0.90, blue: 0.78, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            let bottomRight = CGMutablePath()
            bottomRight.move(to: CGPoint(x: center.x - r, y: center.y))
            bottomRight.addLine(to: CGPoint(x: center.x + r, y: center.y))
            bottomRight.addLine(to: CGPoint(x: center.x, y: center.y + r))
            bottomRight.closeSubpath()
            cgCtx.addPath(bottomRight)
            cgCtx.setFillColor(UIColor(red: 0.91, green: 0.44, blue: 0.27, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            let outline = CGMutablePath()
            outline.move(to: CGPoint(x: center.x, y: center.y - r))
            outline.addLine(to: CGPoint(x: center.x + r, y: center.y))
            outline.addLine(to: CGPoint(x: center.x, y: center.y + r))
            outline.addLine(to: CGPoint(x: center.x - r, y: center.y))
            outline.closeSubpath()
            cgCtx.addPath(outline)
            cgCtx.setStrokeColor(UIColor(red: 0.62, green: 0.21, blue: 0.10, alpha: 0.80).cgColor)
            cgCtx.setLineWidth(1.4)
            cgCtx.strokePath()
        }
        return SKTexture(image: img)
    }

    // MARK: - Trigger

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = PotTapEffectHelper.resolvedPotFrame(for: potNode, in: containerNode)
        let scale = PotTapEffectHelper.scaleFactor(for: potFrame)

        // 1. Vệt bóng men gốm ấm phản chiếu trên thân chậu
        if containerNode.childNode(withName: "potClaySheen") == nil {
            let sheen = SKSpriteNode(
                texture: Self.getSheenTexture(),
                size: CGSize(width: max(58.0, potFrame.width * 0.68), height: 16.0 * scale)
            )
            sheen.name = "potClaySheen"
            sheen.zPosition = 152
            sheen.zRotation = -0.35
            sheen.alpha = 0.0
            sheen.setScale(0.70)
            sheen.position = CGPoint(
                x: potFrame.minX + potFrame.width * 0.28,
                y: potFrame.maxY - potFrame.height * 0.30
            )
            containerNode.addChild(sheen)

            let glide = SKAction.move(
                to: CGPoint(x: potFrame.maxX - potFrame.width * 0.24, y: potFrame.minY + potFrame.height * 0.34),
                duration: 0.32
            )
            glide.timingMode = .easeInEaseOut

            let sheenPulse = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 0.90, duration: 0.11),
                    SKAction.scale(to: 1.08, duration: 0.11)
                ]),
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.21),
                    SKAction.scale(to: 0.72, duration: 0.21)
                ])
            ])
            sheen.run(SKAction.sequence([
                SKAction.group([glide, sheenPulse]),
                SKAction.removeFromParent()
            ]))
        }

        // 2. Chùm ánh men gốm & mảnh gốm phản chiếu bung tỏa
        let budget = PotTapEffectHelper.remainingBudget(in: containerNode, nodeName: "potClayGlint", maxActive: 22)
        guard budget > 0 else { return }
        let burstCount = min(Int.random(in: countRange), budget)

        for i in 0..<burstCount {
            let isSparkle = (i % 2 == 0)
            let kind: ClayKind = isSparkle ? .glazeSparkle : .ceramicTileFacet
            let texture = Self.getParticleTexture(kind: kind)

            let sizeVal = isSparkle
                ? CGFloat.random(in: 11.0...17.5) * scale
                : CGFloat.random(in: 7.5...11.5) * scale

            let glint = SKSpriteNode(texture: texture, size: CGSize(width: sizeVal, height: sizeVal))
            glint.name = "potClayGlint"

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.14)...(potFrame.maxX - potFrame.width * 0.14))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.18)...(potFrame.maxY - potFrame.height * 0.14))
            glint.position = CGPoint(x: startX, y: startY)
            glint.zPosition = 150
            glint.alpha = 0.0
            glint.setScale(0.25)
            containerNode.addChild(glint)

            let flyAngle = CGFloat.random(in: -0.15 * .pi ... 1.15 * .pi)
            let distance = CGFloat.random(in: 24.0...56.0) * scale
            let dx = cos(flyAngle) * distance
            let dy = abs(sin(flyAngle)) * distance * 0.85 + CGFloat.random(in: 4.0...14.0) * scale

            let delay = SKAction.wait(forDuration: Double(i) * 0.022)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.09)
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.56)
            move.timingMode = .easeOut

            let rotate = SKAction.rotate(
                byAngle: isSparkle ? CGFloat.random(in: -1.6...1.6) : CGFloat.random(in: -3.2...3.2),
                duration: 0.56
            )
            let scalePulse = SKAction.sequence([
                SKAction.scale(to: 1.28, duration: 0.15),
                SKAction.scale(to: 0.88, duration: 0.14),
                SKAction.scale(to: 0.20, duration: 0.27)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.24),
                SKAction.fadeOut(withDuration: 0.32)
            ])

            glint.run(SKAction.sequence([
                delay,
                fadeIn,
                SKAction.group([move, rotate, scalePulse, fadeOut]),
                SKAction.removeFromParent()
            ]))
        }
    }
}

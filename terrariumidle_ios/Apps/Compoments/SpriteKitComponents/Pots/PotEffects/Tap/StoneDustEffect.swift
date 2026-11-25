//
//  StoneDustEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bụi đá xám" (Stone Dust)
/// - Tỏa làn khói bụi đá xám khoáng mịn hai bên thân chậu kết hợp mảnh đá góc cạnh văng theo trọng lực và hạt mica ánh bạc
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt
public final class StoneDustEffect: PotTapEffect {

    public let name: String = "StoneDustEffect"

    public var countRange: ClosedRange<Int> = 10...14

    public init(countRange: ClosedRange<Int> = 10...14) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache

    private enum StoneKind: Int {
        case slateDustPuff
        case graniteChipA
        case graniteChipB
        case silverMicaFlecks
    }

    private static var textureCache: [StoneKind: SKTexture] = [:]

    private static func getTexture(for kind: StoneKind) -> SKTexture {
        if let cached = textureCache[kind] {
            return cached
        }
        let texture: SKTexture
        switch kind {
        case .slateDustPuff:
            texture = PotTapEffectHelper.createSoftPuffTexture(
                dimension: 52.0,
                innerColor: UIColor(red: 0.42, green: 0.47, blue: 0.53, alpha: 0.72),
                midColor: UIColor(red: 0.66, green: 0.71, blue: 0.77, alpha: 0.38)
            )
        case .graniteChipA:
            texture = renderChiseledStoneChip(
                darkColor: UIColor(red: 0.31, green: 0.36, blue: 0.42, alpha: 0.98),
                lightColor: UIColor(red: 0.64, green: 0.69, blue: 0.75, alpha: 0.98),
                borderColor: UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 0.85),
                vertices: [
                    CGPoint(x: 0.22, y: 0.14),
                    CGPoint(x: 0.76, y: 0.18),
                    CGPoint(x: 0.90, y: 0.56),
                    CGPoint(x: 0.54, y: 0.88),
                    CGPoint(x: 0.14, y: 0.64)
                ]
            )
        case .graniteChipB:
            texture = renderChiseledStoneChip(
                darkColor: UIColor(red: 0.44, green: 0.42, blue: 0.40, alpha: 0.98),
                lightColor: UIColor(red: 0.74, green: 0.72, blue: 0.69, alpha: 0.98),
                borderColor: UIColor(red: 0.20, green: 0.19, blue: 0.18, alpha: 0.85),
                vertices: [
                    CGPoint(x: 0.34, y: 0.10),
                    CGPoint(x: 0.84, y: 0.30),
                    CGPoint(x: 0.78, y: 0.78),
                    CGPoint(x: 0.32, y: 0.90),
                    CGPoint(x: 0.10, y: 0.48)
                ]
            )
        case .silverMicaFlecks:
            texture = renderMicaFleckTexture()
        }
        textureCache[kind] = texture
        return texture
    }

    private static func renderChiseledStoneChip(
        darkColor: UIColor,
        lightColor: UIColor,
        borderColor: UIColor,
        vertices: [CGPoint]
    ) -> SKTexture {
        let dim: CGFloat = 32.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext

            let path = CGMutablePath()
            if let first = vertices.first {
                path.move(to: CGPoint(x: first.x * dim, y: first.y * dim))
                for pt in vertices.dropFirst() {
                    path.addLine(to: CGPoint(x: pt.x * dim, y: pt.y * dim))
                }
                path.closeSubpath()
            }

            // Nền đá xám tối
            cgCtx.addPath(path)
            cgCtx.setFillColor(darkColor.cgColor)
            cgCtx.fillPath()

            // Mặt cắt vát sáng phía trên tạo hiệu ứng khối đá sắc cạnh
            if vertices.count >= 4 {
                let facet = CGMutablePath()
                facet.move(to: CGPoint(x: vertices[0].x * dim, y: vertices[0].y * dim))
                facet.addLine(to: CGPoint(x: vertices[1].x * dim, y: vertices[1].y * dim))
                facet.addLine(to: CGPoint(x: dim * 0.52, y: dim * 0.52))
                facet.addLine(to: CGPoint(x: vertices.last!.x * dim, y: vertices.last!.y * dim))
                facet.closeSubpath()
                cgCtx.addPath(facet)
                cgCtx.setFillColor(lightColor.cgColor)
                cgCtx.fillPath()
            }

            // Viền cạnh đá đậm nét
            cgCtx.addPath(path)
            cgCtx.setStrokeColor(borderColor.cgColor)
            cgCtx.setLineWidth(1.6)
            cgCtx.setLineJoin(.miter)
            cgCtx.strokePath()
        }
        return SKTexture(image: img)
    }

    private static func renderMicaFleckTexture() -> SKTexture {
        let dim: CGFloat = 28.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dim * 0.5, y: dim * 0.5)
            let rw = dim * 0.30
            let rh = dim * 0.40

            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - rh))
            path.addLine(to: CGPoint(x: center.x + rw, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + rh))
            path.addLine(to: CGPoint(x: center.x - rw, y: center.y))
            path.closeSubpath()

            cgCtx.addPath(path)
            cgCtx.setFillColor(UIColor(red: 0.89, green: 0.92, blue: 0.96, alpha: 0.98).cgColor)
            cgCtx.fillPath()

            cgCtx.addPath(path)
            cgCtx.setStrokeColor(UIColor(red: 0.32, green: 0.38, blue: 0.46, alpha: 0.85).cgColor)
            cgCtx.setLineWidth(1.3)
            cgCtx.strokePath()

            let glintRect = CGRect(x: center.x - 2.2, y: center.y - 2.2, width: 4.4, height: 4.4)
            cgCtx.setFillColor(UIColor.white.cgColor)
            cgCtx.fillEllipse(in: glintRect)
        }
        return SKTexture(image: img)
    }

    // MARK: - Trigger

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let budget = PotTapEffectHelper.remainingBudget(in: containerNode, nodeName: "potStoneDust", maxActive: 24)
        guard budget > 0 else { return }

        let potFrame = PotTapEffectHelper.resolvedPotFrame(for: potNode, in: containerNode)
        let scale = PotTapEffectHelper.scaleFactor(for: potFrame)
        let burstCount = min(Int.random(in: countRange), budget)

        for i in 0..<burstCount {
            let bucket = i % 5

            if bucket == 0 || bucket == 3 {
                // Làn khói bụi đá xám mịn tỏa ngang hai bên chậu
                let puffSize = CGFloat.random(in: 16.0...25.0) * scale
                let puff = SKSpriteNode(
                    texture: Self.getTexture(for: .slateDustPuff),
                    size: CGSize(width: puffSize, height: puffSize)
                )
                puff.name = "potStoneDust"

                let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.10)...(potFrame.maxX - potFrame.width * 0.10))
                let minYRatio: CGFloat = isHanging ? 0.18 : 0.08
                let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * minYRatio)...(potFrame.maxY - potFrame.height * 0.20))
                puff.position = CGPoint(x: startX, y: startY)
                puff.zPosition = 149
                puff.alpha = 0.0
                puff.setScale(0.35)
                containerNode.addChild(puff)

                let sideSign: CGFloat = startX < potFrame.midX ? -1.0 : 1.0
                let dx = sideSign * CGFloat.random(in: 18.0...44.0) * scale
                let dy = CGFloat.random(in: -2.0...22.0) * scale

                let delay = SKAction.wait(forDuration: Double(i) * 0.015)
                let fadeIn = SKAction.fadeAlpha(to: 0.85, duration: 0.11)
                let drift = SKAction.moveBy(x: dx, y: dy, duration: 0.58)
                drift.timingMode = .easeOut
                let expand = SKAction.scale(to: 1.60, duration: 0.58)
                let fadeOut = SKAction.sequence([
                    SKAction.wait(forDuration: 0.18),
                    SKAction.fadeOut(withDuration: 0.40)
                ])

                puff.run(SKAction.sequence([
                    delay,
                    fadeIn,
                    SKAction.group([drift, expand, fadeOut]),
                    SKAction.removeFromParent()
                ]))
            } else {
                // Mảnh vụn đá góc cạnh hoặc hạt khoáng mica ánh bạc văng nặng rồi rơi xuống
                let isMica = (bucket == 4)
                let kind: StoneKind = isMica ? .silverMicaFlecks : (bucket == 1 ? .graniteChipA : .graniteChipB)
                let chipSize = isMica
                    ? CGFloat.random(in: 6.0...9.0) * scale
                    : CGFloat.random(in: 6.5...10.5) * scale

                let chip = SKSpriteNode(
                    texture: Self.getTexture(for: kind),
                    size: CGSize(width: chipSize, height: chipSize)
                )
                chip.name = "potStoneDust"

                let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.14)...(potFrame.maxX - potFrame.width * 0.14))
                let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.24)...(potFrame.maxY - potFrame.height * 0.14))
                chip.position = CGPoint(x: startX, y: startY)
                chip.zPosition = 150
                chip.zRotation = CGFloat.random(in: 0...(.pi * 2))
                chip.alpha = 0.0
                chip.setScale(0.35)
                containerNode.addChild(chip)

                let sideBias: CGFloat = startX < potFrame.midX ? -1.0 : 1.0
                let horizontalSpread = (sideBias * CGFloat.random(in: 16.0...40.0) + CGFloat.random(in: -6.0...6.0)) * scale
                let upY = CGFloat.random(in: 12.0...28.0) * scale
                let downY = -CGFloat.random(in: 22.0...40.0) * scale

                PotTapEffectHelper.runGravityHop(
                    on: chip,
                    delay: Double(i) * 0.016,
                    upDX: horizontalSpread * 0.65,
                    upDY: upY,
                    downDX: horizontalSpread * 0.45,
                    downDY: downY,
                    spinAngle: CGFloat.random(in: -5.2...5.2),
                    peakAlpha: 1.0
                )
            }
        }
    }
}

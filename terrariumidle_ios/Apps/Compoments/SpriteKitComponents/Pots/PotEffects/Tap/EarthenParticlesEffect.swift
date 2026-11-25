//
//  EarthenParticlesEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Hạt đất sét" (Earthen Dust / Particles)
/// - Bắn tung các vụn đất sét góc cạnh nảy parabol có trọng lực kết hợp làn bụi đất nung ấm áp mộc mạc
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt
public final class EarthenParticlesEffect: PotTapEffect {

    public let name: String = "EarthenParticlesEffect"

    public var countRange: ClosedRange<Int> = 9...13

    public init(countRange: ClosedRange<Int> = 9...13) {
        self.countRange = countRange
    }

    // MARK: - Texture Cache

    private enum ParticleKind: Int {
        case terracottaCrumb
        case loamCrumb
        case ochrePebble
        case earthDustPuff
    }

    private static var textureCache: [ParticleKind: SKTexture] = [:]

    private static func getTexture(for kind: ParticleKind) -> SKTexture {
        if let cached = textureCache[kind] {
            return cached
        }
        let texture: SKTexture
        switch kind {
        case .terracottaCrumb:
            texture = renderOrganicCrumbTexture(
                fillColor: UIColor(red: 0.78, green: 0.39, blue: 0.23, alpha: 0.98),
                highlightColor: UIColor(red: 0.93, green: 0.62, blue: 0.44, alpha: 0.90),
                borderColor: UIColor(red: 0.42, green: 0.18, blue: 0.09, alpha: 0.75),
                points: [
                    CGPoint(x: 0.22, y: 0.14),
                    CGPoint(x: 0.68, y: 0.10),
                    CGPoint(x: 0.90, y: 0.38),
                    CGPoint(x: 0.80, y: 0.80),
                    CGPoint(x: 0.42, y: 0.90),
                    CGPoint(x: 0.12, y: 0.62)
                ]
            )
        case .loamCrumb:
            texture = renderOrganicCrumbTexture(
                fillColor: UIColor(red: 0.55, green: 0.29, blue: 0.16, alpha: 0.98),
                highlightColor: UIColor(red: 0.76, green: 0.48, blue: 0.31, alpha: 0.85),
                borderColor: UIColor(red: 0.30, green: 0.13, blue: 0.06, alpha: 0.78),
                points: [
                    CGPoint(x: 0.30, y: 0.12),
                    CGPoint(x: 0.78, y: 0.22),
                    CGPoint(x: 0.88, y: 0.60),
                    CGPoint(x: 0.62, y: 0.88),
                    CGPoint(x: 0.20, y: 0.78),
                    CGPoint(x: 0.10, y: 0.40)
                ]
            )
        case .ochrePebble:
            texture = renderOrganicCrumbTexture(
                fillColor: UIColor(red: 0.86, green: 0.63, blue: 0.39, alpha: 0.98),
                highlightColor: UIColor(red: 0.97, green: 0.82, blue: 0.62, alpha: 0.90),
                borderColor: UIColor(red: 0.50, green: 0.31, blue: 0.14, alpha: 0.75),
                points: [
                    CGPoint(x: 0.24, y: 0.18),
                    CGPoint(x: 0.62, y: 0.12),
                    CGPoint(x: 0.88, y: 0.46),
                    CGPoint(x: 0.72, y: 0.84),
                    CGPoint(x: 0.28, y: 0.86),
                    CGPoint(x: 0.12, y: 0.50)
                ]
            )
        case .earthDustPuff:
            texture = PotTapEffectHelper.createSoftPuffTexture(
                dimension: 48.0,
                innerColor: UIColor(red: 0.82, green: 0.53, blue: 0.35, alpha: 0.68),
                midColor: UIColor(red: 0.89, green: 0.69, blue: 0.52, alpha: 0.36)
            )
        }
        textureCache[kind] = texture
        return texture
    }

    private static func renderOrganicCrumbTexture(
        fillColor: UIColor,
        highlightColor: UIColor,
        borderColor: UIColor,
        points: [CGPoint]
    ) -> SKTexture {
        let dim: CGFloat = 32.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let path = CGMutablePath()
            if let first = points.first {
                path.move(to: CGPoint(x: first.x * dim, y: first.y * dim))
                for pt in points.dropFirst() {
                    path.addLine(to: CGPoint(x: pt.x * dim, y: pt.y * dim))
                }
                path.closeSubpath()
            }

            cgCtx.addPath(path)
            cgCtx.setFillColor(fillColor.cgColor)
            cgCtx.fillPath()

            // Mảng sáng mặt trên tạo cảm giác hạt đất 3D mộc mạc
            let sheenRect = CGRect(x: dim * 0.24, y: dim * 0.22, width: dim * 0.34, height: dim * 0.22)
            cgCtx.setFillColor(highlightColor.cgColor)
            cgCtx.fillEllipse(in: sheenRect)

            cgCtx.addPath(path)
            cgCtx.setStrokeColor(borderColor.cgColor)
            cgCtx.setLineWidth(1.5)
            cgCtx.setLineJoin(.round)
            cgCtx.strokePath()
        }
        return SKTexture(image: img)
    }

    // MARK: - Trigger

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let budget = PotTapEffectHelper.remainingBudget(in: containerNode, nodeName: "potEarthenParticle", maxActive: 24)
        guard budget > 0 else { return }

        let potFrame = PotTapEffectHelper.resolvedPotFrame(for: potNode, in: containerNode)
        let scale = PotTapEffectHelper.scaleFactor(for: potFrame)
        let burstCount = min(Int.random(in: countRange), budget)

        for i in 0..<burstCount {
            let isDustPuff = (i % 3 == 2)

            if isDustPuff {
                let puffSize = CGFloat.random(in: 14.0...22.0) * scale
                let puff = SKSpriteNode(
                    texture: Self.getTexture(for: .earthDustPuff),
                    size: CGSize(width: puffSize, height: puffSize)
                )
                puff.name = "potEarthenParticle"

                let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.14)...(potFrame.maxX - potFrame.width * 0.14))
                let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.12))
                puff.position = CGPoint(x: startX, y: startY)
                puff.zPosition = 149
                puff.alpha = 0.0
                puff.setScale(0.35)
                containerNode.addChild(puff)

                let sideSign: CGFloat = startX < potFrame.midX ? -1.0 : 1.0
                let dx = sideSign * CGFloat.random(in: 14.0...34.0) * scale
                let dy = CGFloat.random(in: 12.0...30.0) * scale

                let delay = SKAction.wait(forDuration: Double(i) * 0.015)
                let fadeIn = SKAction.fadeAlpha(to: 0.78, duration: 0.12)
                let drift = SKAction.moveBy(x: dx, y: dy, duration: 0.56)
                drift.timingMode = .easeOut
                let expand = SKAction.scale(to: 1.55, duration: 0.56)
                let fadeOut = SKAction.sequence([
                    SKAction.wait(forDuration: 0.18),
                    SKAction.fadeOut(withDuration: 0.38)
                ])

                puff.run(SKAction.sequence([
                    delay,
                    fadeIn,
                    SKAction.group([drift, expand, fadeOut]),
                    SKAction.removeFromParent()
                ]))
            } else {
                let crumbKinds: [ParticleKind] = [.terracottaCrumb, .loamCrumb, .ochrePebble]
                let kind = crumbKinds[i % crumbKinds.count]
                let crumbSize = CGFloat.random(in: 6.0...10.5) * scale

                let crumb = SKSpriteNode(
                    texture: Self.getTexture(for: kind),
                    size: CGSize(width: crumbSize, height: crumbSize)
                )
                crumb.name = "potEarthenParticle"

                let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.16)...(potFrame.maxX - potFrame.width * 0.16))
                let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.35)...(potFrame.maxY - potFrame.height * 0.10))
                crumb.position = CGPoint(x: startX, y: startY)
                crumb.zPosition = 150
                crumb.zRotation = CGFloat.random(in: 0...(.pi * 2))
                crumb.alpha = 0.0
                crumb.setScale(0.35)
                containerNode.addChild(crumb)

                // Hướng bắn tỏa hai bên thành/miệng chậu rồi rơi theo trọng lực
                let sideBias: CGFloat = startX < potFrame.midX ? -1.0 : 1.0
                let horizontalSpeed = (sideBias * CGFloat.random(in: 12.0...34.0) + CGFloat.random(in: -8.0...8.0)) * scale
                let upY = CGFloat.random(in: 18.0...38.0) * scale
                let downY = -CGFloat.random(in: 24.0...42.0) * scale

                PotTapEffectHelper.runGravityHop(
                    on: crumb,
                    delay: Double(i) * 0.018,
                    upDX: horizontalSpeed * 0.65,
                    upDY: upY,
                    downDX: horizontalSpeed * 0.45,
                    downDY: downY,
                    spinAngle: CGFloat.random(in: -4.2...4.2),
                    peakAlpha: 1.0
                )
            }
        }
    }
}

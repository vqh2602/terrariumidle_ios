//
//  QuartzBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Tam thạch anh hồng" (Rose Quartz Crystal Burst)
/// - Bung tỏa các tinh thể hình thoi thạch anh hồng phấn và tím pha lê lấp lánh xoay 360 độ
/// - Tối ưu 100% Metal Batching bằng bộ đệm SKTexture chung + giới hạn ngân sách hạt tối đa 16
public final class QuartzBurstEffect: PotTapEffect {

    public let name: String = "QuartzBurstEffect"

    public var burstCountRange: ClosedRange<Int> = 6...8
    public var minRadius: CGFloat = 3.5
    public var maxRadius: CGFloat = 6.0

    public init(burstCountRange: ClosedRange<Int> = 6...8) {
        self.burstCountRange = burstCountRange
    }

    // MARK: - Texture Cache
    private static var crystalTextureCache: [Bool: SKTexture] = [:] // true: pink, false: purple

    private static func getCrystalTexture(isPink: Bool) -> SKTexture {
        if let cached = crystalTextureCache[isPink] {
            return cached
        }
        let w: CGFloat = 36.0
        let h: CGFloat = 64.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: w / 2, y: h / 2)
            let rw = (w - 4) / 2
            let rh = (h - 4) / 2

            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - rh))
            path.addLine(to: CGPoint(x: center.x + rw, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + rh))
            path.addLine(to: CGPoint(x: center.x - rw, y: center.y))
            path.closeSubpath()

            let color = isPink
                ? UIColor(red: 1.0, green: 0.72, blue: 0.88, alpha: 0.95)
                : UIColor(red: 0.95, green: 0.85, blue: 1.0, alpha: 0.95)

            cgCtx.addPath(path)
            cgCtx.setFillColor(color.cgColor)
            cgCtx.fillPath()

            cgCtx.addPath(path)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            cgCtx.setLineWidth(1.2)
            cgCtx.strokePath()

            // Đường vân phản chiếu bên trong
            let facetPath = CGMutablePath()
            facetPath.move(to: CGPoint(x: center.x, y: center.y - rh * 0.6))
            facetPath.addLine(to: CGPoint(x: center.x + rw * 0.45, y: center.y))
            facetPath.addLine(to: CGPoint(x: center.x, y: center.y + rh * 0.6))
            cgCtx.addPath(facetPath)
            cgCtx.setStrokeColor(UIColor.white.withAlphaComponent(0.65).cgColor)
            cgCtx.setLineWidth(1.0)
            cgCtx.strokePath()
        }
        let texture = SKTexture(image: img)
        crystalTextureCache[isPink] = texture
        return texture
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        var existingCount = 0
        for child in containerNode.children where child.name == "potQuartzCrystal" {
            existingCount += 1
        }
        guard existingCount < 16 else { return }

        let potFrame = potNode.frame
        let burstCount = min(Int.random(in: burstCountRange), 16 - existingCount)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let isPink = (i % 2 == 0)
            let texture = Self.getCrystalTexture(isPink: isPink)

            let crystal = SKSpriteNode(texture: texture, size: CGSize(width: radius * 1.5, height: radius * 2.7))
            crystal.name = "potQuartzCrystal"

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.15))
            crystal.position = CGPoint(x: startX, y: startY)
            crystal.zPosition = 150
            crystal.alpha = 0.0
            crystal.setScale(0.3)
            containerNode.addChild(crystal)

            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...65)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.12)
            let appearGroup = SKAction.group([fadeIn, scaleUp])

            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.55)
            floatOut.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.5...3.5), duration: 0.55)
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.25),
                SKAction.fadeOut(withDuration: 0.30)
            ])

            let motionGroup = SKAction.group([floatOut, rotate, fadeOut])
            let fullSeq = SKAction.sequence([delay, appearGroup, motionGroup, SKAction.removeFromParent()])
            crystal.run(fullSeq)
        }
    }

    // MARK: - Compatibility Helper (cho Pot6Node hoặc các hiệu ứng tĩnh)

    public static func createDiamondCrystalNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let path = CGMutablePath()
        let rw = radius * 0.75
        let rh = radius * 1.35

        path.move(to: CGPoint(x: 0, y: rh))
        path.addLine(to: CGPoint(x: rw, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -rh))
        path.addLine(to: CGPoint(x: -rw, y: 0))
        path.closeSubpath()

        let crystalNode = SKShapeNode(path: path)
        crystalNode.fillColor = color
        crystalNode.strokeColor = UIColor.white.withAlphaComponent(0.85)
        crystalNode.lineWidth = 0.5

        let facetPath = CGMutablePath()
        facetPath.move(to: CGPoint(x: 0, y: rh * 0.6))
        facetPath.addLine(to: CGPoint(x: rw * 0.45, y: 0))
        facetPath.addLine(to: CGPoint(x: 0, y: -rh * 0.6))
        let facet = SKShapeNode(path: facetPath)
        facet.strokeColor = UIColor.white.withAlphaComponent(0.65)
        facet.lineWidth = 0.4
        crystalNode.addChild(facet)

        return crystalNode
    }
}

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
public final class QuartzBurstEffect: PotTapEffect {

    public let name: String = "QuartzBurstEffect"

    public var burstCountRange: ClosedRange<Int> = 8...12
    public var minRadius: CGFloat = 3.5
    public var maxRadius: CGFloat = 6.5

    public init(burstCountRange: ClosedRange<Int> = 8...12) {
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.72, blue: 0.88, alpha: 0.95) // Hồng thạch anh phấn
                : UIColor(red: 0.95, green: 0.85, blue: 1.0, alpha: 0.95) // Ánh pha lê tím nhạt

            let crystal = Self.createDiamondCrystalNode(radius: radius, color: color)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.25)...(potFrame.maxY - potFrame.height * 0.15))
            crystal.position = CGPoint(x: startX, y: startY)
            crystal.zPosition = 150
            crystal.alpha = 0.0
            crystal.setScale(0.2)
            containerNode.addChild(crystal)

            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 25...65)
            let dx = cos(flyAngle) * distance
            let dy = sin(flyAngle) * distance

            let delay = SKAction.wait(forDuration: Double(i) * 0.02)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.55)
            floatOut.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.5...3.5), duration: 0.55)
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.25),
                SKAction.fadeOut(withDuration: 0.30)
            ])

            let motionGroup = SKAction.group([floatOut, rotate, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])
            crystal.run(fullSeq)
        }
    }

    // MARK: - Helper tạo hình thoi thạch anh (Diamond Quartz Crystal)

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

        // Đường vân lăng kính phản chiếu bên trong
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

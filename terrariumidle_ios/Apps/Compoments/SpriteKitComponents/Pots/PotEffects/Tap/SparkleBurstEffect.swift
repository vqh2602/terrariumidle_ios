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

    public let name: String = "SparkleBurstEffect"

    public var burstCountRange: ClosedRange<Int> = 7...10
    public var minRadius: CGFloat = 4.0
    public var maxRadius: CGFloat = 6.5

    public init(burstCountRange: ClosedRange<Int> = 7...10) {
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let starColor = (i % 2 == 0)
                ? UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.95) // Vàng hoàng yến lấp lánh
                : UIColor(red: 1.0, green: 0.65, blue: 0.78, alpha: 0.95) // Hồng phấn lấp lánh

            let star = Self.createStarSparkleNode(radius: radius, color: starColor)

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

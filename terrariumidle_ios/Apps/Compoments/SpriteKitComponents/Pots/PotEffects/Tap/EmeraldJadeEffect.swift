//
//  EmeraldJadeEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Ánh ngọc bích băng tuyết" (Emerald & Ice Jade Luminescence)
/// - Tung ra chùm tinh thể ngọc lam ngọc bích phát sáng lung linh (#64DFDF, #48CAE4, #90E0EF, #CAF0F8)
/// - Xoay 360 độ và tỏa ra xung quanh khối ngọc trong trẻo mát lạnh
public final class EmeraldJadeEffect: PotTapEffect {

    public enum Theme: CaseIterable, Hashable {
        case iceJade       // Lam ngọc bích & Băng thanh (mặc định)
        case imperialGreen // Ngọc lục bảo đậm & Xanh ngọc tươi
        case amethystJade  // Ngọc tím thạch anh & Oải hương

        public var shadeColors: [UIColor] {
            switch self {
            case .iceJade:
                return [
                    UIColor(red: 0.39, green: 0.87, blue: 0.87, alpha: 0.95), // Lam ngọc bích sáng (#64DFDF)
                    UIColor(red: 0.28, green: 0.79, blue: 0.89, alpha: 0.95), // Băng thanh (#48CAE4)
                    UIColor(red: 0.79, green: 0.94, blue: 0.97, alpha: 0.95)  // Băng tuyết trắng ngọc (#CAF0F8)
                ]
            case .imperialGreen:
                return [
                    UIColor(red: 0.18, green: 0.80, blue: 0.56, alpha: 0.95),
                    UIColor(red: 0.36, green: 0.92, blue: 0.68, alpha: 0.95),
                    UIColor(red: 0.74, green: 0.98, blue: 0.86, alpha: 0.95)
                ]
            case .amethystJade:
                return [
                    UIColor(red: 0.72, green: 0.44, blue: 0.90, alpha: 0.95),
                    UIColor(red: 0.84, green: 0.66, blue: 0.98, alpha: 0.95),
                    UIColor(red: 0.94, green: 0.88, blue: 1.00, alpha: 0.95)
                ]
            }
        }
    }

    public let name: String = "EmeraldJadeEffect"

    public var theme: Theme = .iceJade
    public var burstCountRange: ClosedRange<Int> = 8...12
    public var minRadius: CGFloat = 3.5
    public var maxRadius: CGFloat = 6.0

    public init(theme: Theme = .iceJade, burstCountRange: ClosedRange<Int> = 8...12) {
        self.theme = theme
        self.burstCountRange = burstCountRange
    }

    public func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool) {
        let potFrame = potNode.frame
        let burstCount = Int.random(in: burstCountRange)
        let shades = theme.shadeColors

        for i in 0..<burstCount {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = shades[i % shades.count]

            let crystal = Self.createJadeCrystalNode(radius: radius, color: color)

            let startX = CGFloat.random(in: (potFrame.minX + potFrame.width * 0.15)...(potFrame.maxX - potFrame.width * 0.15))
            let startY = CGFloat.random(in: (potFrame.minY + potFrame.height * 0.15)...(potFrame.maxY - potFrame.height * 0.15))
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
            let floatOut = SKAction.moveBy(x: dx, y: dy, duration: 0.60)
            floatOut.timingMode = .easeOut
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -3.5...3.5), duration: 0.60)
            let scalePulse = SKAction.sequence([
                SKAction.scale(to: 1.30, duration: 0.18),
                SKAction.scale(to: 0.20, duration: 0.42)
            ])
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.25),
                SKAction.fadeOut(withDuration: 0.35)
            ])

            let motionGroup = SKAction.group([floatOut, rotate, scalePulse, fadeOut])
            let fullSeq = SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()])

            crystal.run(fullSeq)
        }
    }

    public static func createJadeCrystalNode(radius: CGFloat, color: UIColor) -> SKShapeNode {
        let path = CGMutablePath()
        let r = radius
        let w = radius * 0.65

        // Tinh thể hình thoi kim cương 6 góc vát
        path.move(to: CGPoint(x: 0, y: r))
        path.addLine(to: CGPoint(x: w, y: r * 0.4))
        path.addLine(to: CGPoint(x: w, y: -r * 0.4))
        path.addLine(to: CGPoint(x: 0, y: -r))
        path.addLine(to: CGPoint(x: -w, y: -r * 0.4))
        path.addLine(to: CGPoint(x: -w, y: r * 0.4))
        path.closeSubpath()

        let node = SKShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = UIColor.white.withAlphaComponent(0.9)
        node.lineWidth = 0.6

        let core = SKShapeNode(circleOfRadius: radius * 0.3)
        core.fillColor = .white
        core.strokeColor = .clear
        node.addChild(core)

        return node
    }
}

//
//  OxygenBubblesEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng: "Bọt khí Oxy 3D" (3D Oxygen Bubbles Effect)
/// - Cấu tạo bọt 3D căng bóng với điểm sáng phản chiếu góc Tây-Bắc (White Highlight)
/// - Số lượng bọt tự động tăng theo cấp độ sinh trưởng:
///   * Level 1 (Hạt giống): 1 - 2 bọt nhỏ thoát ra từ đáy hạt
///   * Level 2 (Cây con): 3 - 4 bọt vừa thoát ra từ hai mầm lá non
///   * Level 3+ (Trưởng thành): 8 - 12 bọt dồi dào toả ra từ khắp các phiến lá trên cây
/// - zPosition chuẩn = 200 (luôn nổi trên chậu và tán lá)
public final class OxygenBubblesEffect: PlantTapEffect {

    // MARK: - Themes

    public enum Theme {
        case emerald    // Xanh ngọc lục bảo tươi mát (mặc định cho cây lá)
        case deepOcean  // Xanh lam ngọc đại dương sâu thẳm
        case goldenSun  // Vàng ấm áp rạng ngời
        case floralPink // Hồng phấn dịu dàng
        case amethyst   // Tím thạch anh huyền bí (dành cho cây lá tím như Oxalis)

        public var fillColor: UIColor {
            switch self {
            case .emerald:
                return UIColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 0.85)
            case .deepOcean:
                return UIColor(red: 0.25, green: 0.82, blue: 0.95, alpha: 0.85)
            case .goldenSun:
                return UIColor(red: 1.0, green: 0.88, blue: 0.38, alpha: 0.88)
            case .floralPink:
                return UIColor(red: 1.0, green: 0.68, blue: 0.82, alpha: 0.88)
            case .amethyst:
                return UIColor(red: 0.76, green: 0.42, blue: 0.88, alpha: 0.88)
            }
        }

        public var strokeColor: UIColor {
            return UIColor.white.withAlphaComponent(0.75)
        }
    }

    // MARK: - Properties

    public let name: String = "OxygenBubblesEffect"
    public var theme: Theme = .emerald

    // MARK: - Initializer

    public init(theme: Theme = .emerald) {
        self.theme = theme
    }

    // MARK: - Trigger Effect

    public func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        let bubbleCount: Int
        if level <= 1 {
            bubbleCount = Int.random(in: 1...2)
        } else if level == 2 {
            bubbleCount = Int.random(in: 3...4)
        } else {
            bubbleCount = Int.random(in: 8...12)
        }

        for i in 0..<bubbleCount {
            let radius: CGFloat
            let spawnX: CGFloat
            let spawnY: CGFloat
            let floatDistance: CGFloat

            if level <= 1 {
                // Hạt giống: bọt nhỏ li ti sát đáy hạt
                radius = CGFloat.random(in: 1.8...3.0)
                spawnX = CGFloat.random(in: -containerSize.width * 0.08...containerSize.width * 0.08)
                spawnY = CGFloat.random(in: containerSize.height * 0.03...containerSize.height * 0.12)
                floatDistance = CGFloat.random(in: 18...35)
            } else if level == 2 {
                // Cây con: bọt vừa ở quanh 2 mầm lá non
                radius = CGFloat.random(in: 2.2...3.8)
                spawnX = CGFloat.random(in: -containerSize.width * 0.10...containerSize.width * 0.10)
                spawnY = CGFloat.random(in: containerSize.height * 0.05...containerSize.height * 0.20)
                floatDistance = CGFloat.random(in: 25...45)
            } else {
                // Cây trưởng thành: bọt to tròn căng bóng bay lên từ các phiến lá
                radius = CGFloat.random(in: 3.5...7.5)
                floatDistance = CGFloat.random(in: 60...115)

                if !leaves.isEmpty && Bool.random() {
                    // Chọn ngẫu nhiên một phiến lá và chuyển toạ độ sang plantNode
                    let leaf = leaves.randomElement()!
                    let leafPos = leaf.parent != nil ? leaf.parent!.convert(leaf.position, to: plantNode) : leaf.position
                    spawnX = leafPos.x + CGFloat.random(in: -16...16)
                    spawnY = max(containerSize.height * 0.18, min(containerSize.height * 0.92, leafPos.y + CGFloat.random(in: -10...18)))
                } else {
                    // Trải đều tự nhiên khắp toàn bộ tán cây
                    spawnX = CGFloat.random(in: -containerSize.width * 0.44...containerSize.width * 0.44)
                    spawnY = CGFloat.random(in: containerSize.height * 0.18...containerSize.height * 0.90)
                }
            }

            // Tạo bong bóng 3D
            let bubble = Self.create3DBubble(radius: radius, theme: theme)
            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 200
            bubble.alpha = 0.0
            plantNode.addChild(bubble)

            // Hoạt ảnh bay uốn lượn hình sin, giãn nở và mờ dần
            let floatDuration = Double.random(in: 0.85...1.55)
            let driftX = CGFloat.random(in: -22...22)

            let delay = SKAction.wait(forDuration: Double(i) * 0.035)
            let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.12)
            let floatUp = SKAction.moveBy(x: driftX, y: floatDistance, duration: floatDuration)
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: floatDuration * 0.55)
            let scaleUp = SKAction.scale(by: 1.30, duration: floatDuration)

            let motionGroup = SKAction.group([
                floatUp,
                SKAction.sequence([SKAction.wait(forDuration: floatDuration * 0.45), fadeOut]),
                scaleUp
            ])

            bubble.run(SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Factory Tạo Bong Bóng 3D Căng Bóng

    private static func create3DBubble(radius: CGFloat, theme: Theme) -> SKShapeNode {
        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.fillColor = theme.fillColor
        bubble.strokeColor = theme.strokeColor
        bubble.lineWidth = 1.0

        // Điểm sáng phản chiếu 3D góc Tây-Bắc (Highlight)
        let highlight = SKShapeNode(circleOfRadius: radius * 0.30)
        highlight.fillColor = UIColor.white.withAlphaComponent(0.85)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -radius * 0.32, y: radius * 0.32)
        bubble.addChild(highlight)

        return bubble
    }
}

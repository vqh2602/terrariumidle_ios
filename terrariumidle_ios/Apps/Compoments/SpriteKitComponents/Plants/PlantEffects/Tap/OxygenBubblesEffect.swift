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

    public enum Theme: CaseIterable, Hashable {
        // Sắc độ Xanh lá
        case emerald       // Xanh ngọc lục bảo tươi mát (mặc định cho cây lá)
        case mintDew       // Xanh bạc hà sương mai dịu nhẹ
        case forestMoss    // Xanh rêu rừng sâu thẳm
        // Sắc độ Xanh dương / Lam
        case deepOcean     // Xanh lam ngọc đại dương sâu thẳm
        case iceAqua       // Xanh băng tuyết / ngọc lam nhạt
        case cobaltIndigo  // Xanh chàm đậm huyền ảo
        // Sắc độ Vàng / Cam / Đỏ
        case goldenSun     // Vàng nắng ấm áp rạng ngời
        case coralSunset   // Cam san hô rực rỡ
        case crimsonRuby   // Đỏ hồng ngọc ấm áp
        // Sắc độ Hồng / Tím
        case floralPink    // Hồng phấn dịu dàng
        case lavenderMist  // Tím oải hương nhạt thanh thoát
        case amethyst      // Tím thạch anh huyền bí (dành cho cây lá tím như Oxalis)
        // Sắc độ Trung tính & Đa sắc
        case pearlWhite    // Trắng ngọc trai tinh khôi
        case rainbowPrism  // Đa sắc cầu vồng pastel

        public var fillColor: UIColor {
            return shadeColors[0]
        }

        /// Danh sách các sắc độ đậm/nhạt hài hoà trong cùng tông màu để bọt khí sinh ra có chiều sâu tự nhiên
        public var shadeColors: [UIColor] {
            switch self {
            case .emerald:
                return [
                    UIColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 0.85),
                    UIColor(red: 0.50, green: 0.96, blue: 0.74, alpha: 0.82),
                    UIColor(red: 0.22, green: 0.82, blue: 0.56, alpha: 0.88)
                ]
            case .mintDew:
                return [
                    UIColor(red: 0.62, green: 0.97, blue: 0.84, alpha: 0.85),
                    UIColor(red: 0.74, green: 0.99, blue: 0.90, alpha: 0.82),
                    UIColor(red: 0.48, green: 0.90, blue: 0.76, alpha: 0.86)
                ]
            case .forestMoss:
                return [
                    UIColor(red: 0.36, green: 0.76, blue: 0.44, alpha: 0.86),
                    UIColor(red: 0.48, green: 0.84, blue: 0.52, alpha: 0.84),
                    UIColor(red: 0.26, green: 0.65, blue: 0.38, alpha: 0.88)
                ]
            case .deepOcean:
                return [
                    UIColor(red: 0.25, green: 0.82, blue: 0.95, alpha: 0.85),
                    UIColor(red: 0.42, green: 0.89, blue: 0.98, alpha: 0.82),
                    UIColor(red: 0.16, green: 0.68, blue: 0.88, alpha: 0.88)
                ]
            case .iceAqua:
                return [
                    UIColor(red: 0.64, green: 0.93, blue: 1.00, alpha: 0.85),
                    UIColor(red: 0.78, green: 0.96, blue: 1.00, alpha: 0.82),
                    UIColor(red: 0.48, green: 0.85, blue: 0.96, alpha: 0.86)
                ]
            case .cobaltIndigo:
                return [
                    UIColor(red: 0.34, green: 0.54, blue: 0.96, alpha: 0.86),
                    UIColor(red: 0.48, green: 0.66, blue: 0.99, alpha: 0.84),
                    UIColor(red: 0.25, green: 0.42, blue: 0.86, alpha: 0.88)
                ]
            case .goldenSun:
                return [
                    UIColor(red: 1.00, green: 0.88, blue: 0.38, alpha: 0.88),
                    UIColor(red: 1.00, green: 0.93, blue: 0.56, alpha: 0.84),
                    UIColor(red: 0.96, green: 0.76, blue: 0.24, alpha: 0.88)
                ]
            case .coralSunset:
                return [
                    UIColor(red: 1.00, green: 0.58, blue: 0.44, alpha: 0.86),
                    UIColor(red: 1.00, green: 0.70, blue: 0.54, alpha: 0.84),
                    UIColor(red: 0.96, green: 0.46, blue: 0.38, alpha: 0.88)
                ]
            case .crimsonRuby:
                return [
                    UIColor(red: 0.95, green: 0.36, blue: 0.48, alpha: 0.86),
                    UIColor(red: 0.98, green: 0.50, blue: 0.60, alpha: 0.84),
                    UIColor(red: 0.84, green: 0.24, blue: 0.38, alpha: 0.88)
                ]
            case .floralPink:
                return [
                    UIColor(red: 1.00, green: 0.68, blue: 0.82, alpha: 0.88),
                    UIColor(red: 1.00, green: 0.80, blue: 0.90, alpha: 0.84),
                    UIColor(red: 0.96, green: 0.54, blue: 0.72, alpha: 0.88)
                ]
            case .lavenderMist:
                return [
                    UIColor(red: 0.78, green: 0.68, blue: 0.98, alpha: 0.86),
                    UIColor(red: 0.86, green: 0.78, blue: 1.00, alpha: 0.82),
                    UIColor(red: 0.66, green: 0.54, blue: 0.92, alpha: 0.88)
                ]
            case .amethyst:
                return [
                    UIColor(red: 0.76, green: 0.42, blue: 0.88, alpha: 0.88),
                    UIColor(red: 0.84, green: 0.56, blue: 0.94, alpha: 0.84),
                    UIColor(red: 0.64, green: 0.30, blue: 0.78, alpha: 0.88)
                ]
            case .pearlWhite:
                return [
                    UIColor(red: 0.94, green: 0.97, blue: 1.00, alpha: 0.85),
                    UIColor(red: 0.98, green: 0.95, blue: 0.98, alpha: 0.82),
                    UIColor(red: 0.86, green: 0.92, blue: 0.96, alpha: 0.86)
                ]
            case .rainbowPrism:
                return [
                    UIColor(red: 0.40, green: 0.92, blue: 0.68, alpha: 0.86), // Emerald
                    UIColor(red: 0.35, green: 0.85, blue: 0.98, alpha: 0.86), // Aqua
                    UIColor(red: 1.00, green: 0.86, blue: 0.42, alpha: 0.86), // Gold
                    UIColor(red: 1.00, green: 0.66, blue: 0.80, alpha: 0.86), // Pink
                    UIColor(red: 0.76, green: 0.56, blue: 0.96, alpha: 0.86), // Lavender
                    UIColor(red: 1.00, green: 0.60, blue: 0.46, alpha: 0.86)  // Coral
                ]
            }
        }

        public var strokeColor: UIColor {
            return UIColor.white.withAlphaComponent(0.75)
        }
    }

    // MARK: - Texture Cache (Tối ưu SpriteKit Metal Batching)
    private struct TextureCacheKey: Hashable {
        let theme: Theme
        let shadeIndex: Int
    }

    private static var textureCache: [TextureCacheKey: SKTexture] = [:]

    private static func getBubbleTexture(theme: Theme, shadeIndex: Int) -> SKTexture {
        let shades = theme.shadeColors
        let safeIndex = max(0, min(shadeIndex, shades.count - 1))
        let key = TextureCacheKey(theme: theme, shadeIndex: safeIndex)

        if let cached = textureCache[key] {
            return cached
        }

        let dimension: CGFloat = 48.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let rect = CGRect(x: 2, y: 2, width: dimension - 4, height: dimension - 4)

            // Vỏ bọt khí 3D căng bóng
            cgCtx.setFillColor(shades[safeIndex].cgColor)
            cgCtx.fillEllipse(in: rect)

            cgCtx.setStrokeColor(theme.strokeColor.cgColor)
            cgCtx.setLineWidth(1.5)
            cgCtx.strokeEllipse(in: rect)

            // Điểm sáng phản chiếu góc Tây-Bắc (White Highlight)
            let hlSize: CGFloat = (dimension - 4) * 0.30
            let hlRect = CGRect(
                x: rect.midX - (dimension - 4) * 0.32 - hlSize * 0.5,
                y: rect.midY - (dimension - 4) * 0.32 - hlSize * 0.5,
                width: hlSize,
                height: hlSize
            )
            cgCtx.setFillColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            cgCtx.fillEllipse(in: hlRect)
        }

        let texture = SKTexture(image: img)
        textureCache[key] = texture
        return texture
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
        // Kiểm tra ngân sách hạt (Particle Budget Cap) để ngăn tràn GPU/CPU khi tap nhiều cây cùng lúc
        var existingBubbleCount = 0
        for child in plantNode.children where child.name == "oxygenBubble" {
            existingBubbleCount += 1
        }
        guard existingBubbleCount < 16 else { return }

        let bubbleCount: Int
        if level <= 1 {
            bubbleCount = Int.random(in: 1...2)
        } else if level == 2 {
            bubbleCount = Int.random(in: 3...4)
        } else {
            bubbleCount = Int.random(in: 8...12)
        }

        let allowedCount = min(bubbleCount, 16 - existingBubbleCount)
        let shadeCount = theme.shadeColors.count

        for i in 0..<allowedCount {
            let texture = Self.getBubbleTexture(theme: theme, shadeIndex: Int.random(in: 0..<shadeCount))
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

                if let leaf = leaves.randomElement() {
                    // Sample the blade itself, rather than its stalk anchor or a
                    // positive-height container band (which lies inside hanging ropes).
                    let point = Self.emissionPoint(on: leaf, relativeTo: plantNode)
                    spawnX = point.x
                    spawnY = point.y
                } else {
                    spawnX = CGFloat.random(in: -containerSize.width * 0.44...containerSize.width * 0.44)
                    spawnY = CGFloat.random(in: containerSize.height * 0.18...containerSize.height * 0.90)
                }
            }

            // Tạo bong bóng 3D từ SpriteKit Texture chia sẻ (100% Metal batching, cực nhẹ)
            let diameter = radius * 2.0
            let bubble = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
            bubble.name = "oxygenBubble"
            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 200
            bubble.alpha = 0.0
            plantNode.addChild(bubble)

            // Hoạt ảnh bay uốn lượn hình sin, giãn nở và mờ dần
            let floatDuration = Double.random(in: 0.85...1.55)
            // Drift away from the centre so hanging foliage releases bubbles
            // outward instead of drawing them back into the rope frame.
            let side: CGFloat = spawnX == 0 ? (Bool.random() ? 1 : -1) : (spawnX > 0 ? 1 : -1)
            let driftX = side * CGFloat.random(in: 10...28)

            let delay = SKAction.wait(forDuration: Double(i) * 0.035)
            let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 0.12)
            let offset = Self.riseOffset(on: plantNode, distance: floatDistance, drift: driftX)
            let floatUp = SKAction.moveBy(x: offset.dx, y: offset.dy, duration: floatDuration)
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

    static func emissionPoint(on leaf: SKNode, relativeTo plantNode: SKNode) -> CGPoint {
        if let sprite = leaf as? SKSpriteNode {
            // Stay in the central blade area; respect its authored stalk anchor.
            let point = CGPoint(
                x: (CGFloat.random(in: 0.25...0.75) - sprite.anchorPoint.x) * sprite.size.width,
                y: (CGFloat.random(in: 0.30...0.80) - sprite.anchorPoint.y) * sprite.size.height
            )
            return sprite.convert(point, to: plantNode)
        }
        return leaf.convert(CGPoint.zero, to: plantNode)
    }

    static func riseOffset(on plantNode: SKNode, distance: CGFloat, drift: CGFloat) -> CGVector {
        guard let scene = plantNode.scene else { return CGVector(dx: drift, dy: distance) }
        // Rising means screen/scene up, even while the hanging rig is rotated or scaled.
        let origin = plantNode.convert(CGPoint.zero, to: scene)
        let target = plantNode.convert(CGPoint(x: origin.x + drift, y: origin.y + distance), from: scene)
        return CGVector(dx: target.x, dy: target.y)
    }

}

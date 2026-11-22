//
//  CandleFlameBurstEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Thị Giác Bùng Sáng Ánh Lửa Nến Ấm Áp (Warm Candle Flame & Embers Glow)
/// - Dành riêng cho Đèn Lồng Thắp Sáng (Candle Lantern - Sticker4)
/// - Theo yêu cầu: "click hiệu ứng phát sáng như đèn đốt nến ý"
/// - **Vầng hào quang nến ấm áp (Warm Ambient Candle Halo)**: Lan tỏa vầng sáng vàng cam dịu ấm cúng
///   xuyên qua lồng kính chiếu rọi ra không gian xung quanh
/// - **Ngọn lửa bừng sáng rạng ngời**: Tim nến trung tâm bừng sáng rực rỡ tức thì
/// - **Tàn lửa ấm bay bổng (Floating Candle Embers)**: Các đốm tàn lửa tro ấm nhỏ li ti màu cam lửa,
///   vàng kim và đỏ ấm uốn lượn bay bổng nhẹ nhàng lên cao theo luồng khí nóng
public final class CandleFlameBurstEffect: StickerTapEffect {

    public var name: String { "candleFlameBurst" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let lanternSprite = targetNode as? SKSpriteNode
        let lanternH = lanternSprite?.size.height ?? 180.0

        let baseOrigin: CGPoint
        if let parent = targetNode.parent {
            baseOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            baseOrigin = targetNode.position
        }

        // Tâm của ngọn nến (nằm ở khoảng 35% từ đỉnh buồng đèn)
        let flameY = isHanging ? (baseOrigin.y - lanternH * 0.36) : (baseOrigin.y + lanternH * 0.60)
        let flameCenter = CGPoint(x: baseOrigin.x, y: flameY)

        rig.position = flameCenter
        containerNode.addChild(rig)

        // 1. Vầng hào quang ánh nến ấm áp (Warm Candle Halo Glow)
        let warmHalo = SKShapeNode(circleOfRadius: 24.0)
        warmHalo.fillColor = UIColor(red: 1.0, green: 0.72, blue: 0.18, alpha: 0.75) // Vàng cam ấm áp
        warmHalo.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.90) // Viền vàng sáng
        warmHalo.lineWidth = 1.2
        rig.addChild(warmHalo)

        let expandHalo = SKAction.group([
            SKAction.scale(to: 3.8, duration: 0.65),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.90, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.53)
            ])
        ])
        expandHalo.timingMode = .easeOut
        warmHalo.run(SKAction.sequence([expandHalo, SKAction.removeFromParent()]))

        // Vầng hào quang lớp ngoài mềm mại
        let outerGlow = SKShapeNode(circleOfRadius: 36.0)
        outerGlow.fillColor = UIColor(red: 1.0, green: 0.50, blue: 0.05, alpha: 0.35)
        outerGlow.strokeColor = .clear
        rig.addChild(outerGlow)

        let expandOuter = SKAction.group([
            SKAction.scale(to: 2.8, duration: 0.75),
            SKAction.fadeOut(withDuration: 0.75)
        ])
        expandOuter.timingMode = .easeOut
        outerGlow.run(SKAction.sequence([expandOuter, SKAction.removeFromParent()]))

        // 2. Ngọn lửa nến trung tâm bừng sáng (Central Flame Flare)
        let flameFlare = createFlameTeardrop()
        flameFlare.setScale(0.5)
        rig.addChild(flameFlare)

        let flareGrow = SKAction.group([
            SKAction.scale(to: 2.2, duration: 0.18),
            SKAction.fadeAlpha(to: 1.0, duration: 0.18)
        ])
        flareGrow.timingMode = .easeOut

        let flareShrink = SKAction.group([
            SKAction.scale(to: 0.1, duration: 0.50),
            SKAction.fadeOut(withDuration: 0.50)
        ])
        flareShrink.timingMode = .easeInEaseOut

        flameFlare.run(SKAction.sequence([flareGrow, flareShrink, SKAction.removeFromParent()]))

        // 3. Tàn tro lửa nến ấm bay bổng lên cao (Floating Candle Embers)
        let emberCount = 18
        for _ in 0..<emberCount {
            let ember = createEmberParticle()
            rig.addChild(ember)

            let offsetX = CGFloat.random(in: -22.0...22.0)
            let ty = CGFloat.random(in: 45.0...105.0) // Bay bổng vút lên trên theo luồng nhiệt đối lưu
            let swayX = CGFloat.random(in: -25.0...25.0)

            let dur = Double.random(in: 0.65...1.10)

            let moveUp = SKAction.move(by: CGVector(dx: offsetX + swayX, dy: ty), duration: dur)
            moveUp.timingMode = .easeOut

            let scalePulse = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.1...1.4), duration: dur * 0.3),
                SKAction.scale(to: 0.1, duration: dur * 0.7)
            ])

            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.35),
                SKAction.fadeOut(withDuration: dur * 0.65)
            ])

            ember.run(SKAction.group([moveUp, scalePulse, fade]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.25),
            SKAction.removeFromParent()
        ]))
    }

    /// Tạo ngọn lửa hình giọt nước ấm áp phát sáng
    private func createFlameTeardrop() -> SKShapeNode {
        let path = CGMutablePath()
        let w: CGFloat = 14.0
        let h: CGFloat = 26.0

        path.move(to: CGPoint(x: 0, y: h * 0.5)) // Đỉnh nhọn ngọn lửa
        path.addCurve(to: CGPoint(x: w * 0.5, y: -h * 0.2), control1: CGPoint(x: w * 0.3, y: h * 0.2), control2: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: -h * 0.5), control1: CGPoint(x: w * 0.5, y: -h * 0.4), control2: CGPoint(x: w * 0.2, y: -h * 0.5))
        path.addCurve(to: CGPoint(x: -w * 0.5, y: -h * 0.2), control1: CGPoint(x: -w * 0.2, y: -h * 0.5), control2: CGPoint(x: -w * 0.5, y: -h * 0.4))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.5), control1: CGPoint(x: -w * 0.5, y: 0), control2: CGPoint(x: -w * 0.3, y: h * 0.2))
        path.closeSubpath()

        let flame = SKShapeNode(path: path)
        flame.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.98) // Vàng trắng sáng chói
        flame.strokeColor = UIColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 0.90) // Viền cam lửa
        flame.lineWidth = 1.0
        return flame
    }

    /// Tạo hạt tàn lửa nhỏ li ti phát sáng
    private func createEmberParticle() -> SKShapeNode {
        let r = CGFloat.random(in: 1.5...3.2)
        let ember = SKShapeNode(circleOfRadius: r)

        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.88, blue: 0.30, alpha: 0.95), // Vàng kim ấm
            UIColor(red: 1.0, green: 0.58, blue: 0.10, alpha: 0.95), // Cam lửa
            UIColor(red: 1.0, green: 0.32, blue: 0.10, alpha: 0.90)  // Đỏ cam nồng ấm
        ]
        ember.fillColor = colors.randomElement() ?? colors[0]
        ember.strokeColor = .clear
        return ember
    }
}

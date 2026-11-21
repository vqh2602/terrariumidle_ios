//
//  SunRadianceEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Mặt trời Tỏa Sáng (Sun Radiance Effect)
/// - Kích hoạt khi chạm vào Búp bê cầu nắng (Sunshine doll / Teru Teru Bōzu):
///   1. **Vầng hào quang ấm áp (Golden Halo Glow)**: Bung tỏa vòng sáng mềm mại mở rộng ra xung quanh.
///   2. **Mặt trời vàng rạng rỡ (Smiling Sun Core)**: Mặt trời tròn vàng óng với khuôn mặt cười tươi hạnh phúc và hai má hồng đáng yêu.
///   3. **12 Tia nắng tỏa rực (12 Rotating Sunbeams)**: Các tia sáng dài ngắn so le tỏa ra xung quanh, xoay đều nhẹ nhàng như bánh xe ánh sáng.
///   4. **Bụi nắng lấp lánh (Solar Sparkle Glints)**: Chùm sao vàng 4 cánh bung tỏa bay bổng lơ lửng rồi tan dần vào không trung.
public final class SunRadianceEffect: StickerTapEffect {

    public var name: String { "sunRadiance" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let sunRig = SKNode()
        sunRig.zPosition = 200

        // Xác định tâm búp bê trong toạ độ của containerNode
        let targetCenter: CGPoint
        if let parent = targetNode.parent {
            targetCenter = parent.convert(targetNode.position, to: containerNode)
        } else {
            targetCenter = targetNode.position
        }

        // Vị trí mặt trời tỏa sáng: Ngay trên đầu hoặc trước ngực búp bê
        let sunOrigin = CGPoint(x: targetCenter.x, y: targetCenter.y - (isHanging ? 85.0 : -40.0))
        sunRig.position = sunOrigin
        containerNode.addChild(sunRig)

        // MARK: - 1. Vầng hào quang bung tỏa (Aura / Lens Flare Halo)
        let halo = SKShapeNode(circleOfRadius: 36.0)
        halo.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.45)
        halo.strokeColor = UIColor(red: 1.0, green: 0.95, blue: 0.65, alpha: 0.60)
        halo.lineWidth = 2.0
        halo.setScale(0.3)
        halo.zPosition = 1
        sunRig.addChild(halo)

        let haloExpand = SKAction.group([
            SKAction.scale(to: 2.4, duration: 1.1),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.65, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.9)
            ])
        ])
        halo.run(haloExpand)

        // MARK: - 2. Cụm tia nắng tỏa xoay (12 Rotating Sunbeams)
        let raysNode = SKNode()
        raysNode.zPosition = 2
        raysNode.setScale(0.1)
        sunRig.addChild(raysNode)

        let rayCount = 12
        let innerRadius: CGFloat = 24.0
        for i in 0..<rayCount {
            let angle = (CGFloat(i) / CGFloat(rayCount)) * .pi * 2.0
            let isLong = (i % 2 == 0)
            let rayLength: CGFloat = isLong ? 26.0 : 16.0
            let rayThickness: CGFloat = isLong ? 3.0 : 2.2

            let rayPath = CGMutablePath()
            let startX = cos(angle) * innerRadius
            let startY = sin(angle) * innerRadius
            let endX = cos(angle) * (innerRadius + rayLength)
            let endY = sin(angle) * (innerRadius + rayLength)

            rayPath.move(to: CGPoint(x: startX, y: startY))
            rayPath.addLine(to: CGPoint(x: endX, y: endY))

            let ray = SKShapeNode(path: rayPath)
            ray.strokeColor = isLong ? UIColor(red: 1.0, green: 0.76, blue: 0.12, alpha: 0.95)
                                     : UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.90)
            ray.lineWidth = rayThickness
            ray.lineCap = .round
            raysNode.addChild(ray)
        }

        // Tia nắng nảy ra và xoay tròn nhẹ
        let raysPop = SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.14)
        ])
        let raysRotate = SKAction.rotate(byAngle: .pi / 3.0, duration: 1.2)
        raysRotate.timingMode = .easeOut
        let raysFade = SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.fadeOut(withDuration: 0.45)
        ])
        raysNode.run(SKAction.group([raysPop, raysRotate, raysFade]))

        // MARK: - 3. Mặt trời vàng tròn rạng rỡ (Sun Core & Face)
        let sunCore = SKNode()
        sunCore.zPosition = 3
        sunCore.setScale(0.1)
        sunRig.addChild(sunCore)

        // Bầu tròn mặt trời vàng cam ấm áp
        let sunCircle = SKShapeNode(circleOfRadius: 21.0)
        sunCircle.fillColor = UIColor(red: 1.0, green: 0.78, blue: 0.15, alpha: 1.0) // Vàng óng nắng
        sunCircle.strokeColor = UIColor(red: 1.0, green: 0.60, blue: 0.05, alpha: 1.0) // Viền cam tươi
        sunCircle.lineWidth = 1.8
        sunCore.addChild(sunCircle)

        // Điểm sáng phản chiếu nhẹ góc trên (Highlight)
        let sunHighlight = SKShapeNode(ellipseOf: CGSize(width: 8.0, height: 4.5))
        sunHighlight.fillColor = UIColor(white: 1.0, alpha: 0.55)
        sunHighlight.strokeColor = .clear
        sunHighlight.position = CGPoint(x: -6.0, y: 8.0)
        sunHighlight.zRotation = 0.4
        sunCore.addChild(sunHighlight)

        // Mắt cười híp tít (Joyful curved eyes)
        let eyeColor = UIColor(red: 0.35, green: 0.18, blue: 0.08, alpha: 1.0)
        for eyeOffset in [-6.5, 6.5] {
            let eyePath = CGMutablePath()
            eyePath.addArc(center: CGPoint(x: eyeOffset, y: 3.5), radius: 3.5, startAngle: 0.2, endAngle: .pi - 0.2, clockwise: false)
            let eye = SKShapeNode(path: eyePath)
            eye.strokeColor = eyeColor
            eye.lineWidth = 1.8
            eye.lineCap = .round
            sunCore.addChild(eye)
        }

        // Nụ cười tươi rạng rỡ (Open warm smile)
        let mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: 0, y: -2.0), radius: 6.0, startAngle: .pi + 0.3, endAngle: -.pi * 2.0 - 0.3, clockwise: false)
        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = eyeColor
        mouth.fillColor = UIColor(red: 0.88, green: 0.25, blue: 0.25, alpha: 0.85) // Lưỡi/miệng hồng
        mouth.lineWidth = 1.5
        sunCore.addChild(mouth)

        // Hai má hồng xinh xắn (Blush cheeks)
        for blushOffset in [-11.0, 11.0] {
            let blush = SKShapeNode(circleOfRadius: 3.2)
            blush.fillColor = UIColor(red: 1.0, green: 0.45, blue: 0.55, alpha: 0.65)
            blush.strokeColor = .clear
            blush.position = CGPoint(x: blushOffset, y: -0.5)
            sunCore.addChild(blush)
        }

        // Animation mặt trời nảy lò xo & biến mất êm dịu
        let sunScaleIn = SKAction.sequence([
            SKAction.scale(to: 1.28, duration: 0.20),
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.wait(forDuration: 0.50),
            SKAction.group([
                SKAction.scale(to: 1.25, duration: 0.40),
                SKAction.fadeOut(withDuration: 0.40)
            ])
        ])
        sunCore.run(sunScaleIn)

        // MARK: - 4. Bụi hạt nắng lấp lánh (Solar Sparkle Glints)
        let sparkleCount = 14
        for _ in 0..<sparkleCount {
            let sparkle = createSparkleStar()
            sparkle.zPosition = 4
            sunRig.addChild(sparkle)

            let randomAngle = CGFloat.random(in: 0...(.pi * 2.0))
            let randomDistance = CGFloat.random(in: 35.0...85.0)
            let targetX = cos(randomAngle) * randomDistance
            let targetY = sin(randomAngle) * randomDistance + CGFloat.random(in: 10.0...35.0) // Bay nhẹ lên trên

            let burstDuration = Double.random(in: 0.65...1.05)
            let moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: burstDuration)
            moveAction.timingMode = .easeOut

            let spinAction = SKAction.rotate(byAngle: CGFloat.random(in: -2.5...2.5), duration: burstDuration)
            let fadeAction = SKAction.sequence([
                SKAction.wait(forDuration: burstDuration * 0.4),
                SKAction.fadeOut(withDuration: burstDuration * 0.6)
            ])
            let scaleAction = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.1...1.5), duration: burstDuration * 0.3),
                SKAction.scale(to: 0.2, duration: burstDuration * 0.7)
            ])

            sparkle.run(SKAction.group([moveAction, spinAction, fadeAction, scaleAction]))
        }

        // Tự động giải phóng node sau khi hiệu ứng hoàn tất
        let cleanUp = SKAction.sequence([
            SKAction.wait(forDuration: 1.35),
            SKAction.removeFromParent()
        ])
        sunRig.run(cleanUp)
    }

    // MARK: - Helper tạo ngôi sao 4 cánh lấp lánh

    private func createSparkleStar() -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter: CGFloat = CGFloat.random(in: 4.5...7.5)
        let rInner: CGFloat = rOuter * 0.26

        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi / 4.0)
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        let isGold = Bool.random()
        star.fillColor = isGold ? UIColor(red: 1.0, green: 0.90, blue: 0.40, alpha: 0.95)
                                : UIColor(white: 1.0, alpha: 0.95)
        star.strokeColor = isGold ? UIColor(red: 1.0, green: 0.75, blue: 0.20, alpha: 0.9)
                                  : UIColor(red: 1.0, green: 0.92, blue: 0.60, alpha: 0.8)
        star.lineWidth = 0.8
        star.setScale(0.1)
        return star
    }
}

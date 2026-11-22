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
/// - **Quy chuẩn chống cắt biên (Anti-Clipping)**: Tự động tính toán bán kính an toàn (`safeRadius`)
///   dựa trên kích thước khung ô và neo chính xác tại khuôn mặt búp bê, đảm bảo không bao giờ bị cắt mép khung.
public final class SunRadianceEffect: StickerTapEffect {

    public var name: String { "sunRadiance" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let sunRig = SKNode()
        sunRig.zPosition = 200

        // 1. Xác định kích thước và vị trí khuôn mặt búp bê trong toạ độ containerNode
        let dollSprite = targetNode as? SKSpriteNode
        let dollW = dollSprite?.size.width ?? 75.0
        let dollH = dollSprite?.size.height ?? 170.0

        let dollOrigin: CGPoint
        if let parent = targetNode.parent {
            dollOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            dollOrigin = targetNode.position
        }

        // Với anchorPoint (0.5, 1.0), đỉnh đầu búp bê ở dollOrigin.y.
        // Khuôn mặt cười của búp bê nằm ở khoảng 16% chiều cao búp bê tính từ đỉnh đầu xuống.
        let sunY: CGFloat
        if isHanging {
            sunY = dollOrigin.y - (dollH * 0.16)
        } else {
            sunY = dollOrigin.y + (dollH * 0.72)
        }
        let sunOrigin = CGPoint(x: dollOrigin.x, y: sunY)
        sunRig.position = sunOrigin
        containerNode.addChild(sunRig)

        // 2. Tính toán bán kính an toàn (Safe Radius) chống cắt mép khung
        let sceneW = targetNode.scene?.size.width ?? (dollW * 1.5)
        let sceneH = targetNode.scene?.size.height ?? (dollH * 1.3)

        // Bán kính tối đa được khống chế ở mức 34% chiều rộng và 22% chiều cao khung
        // để toàn bộ vầng sáng, tia nắng và bụi sao luôn nằm 100% trong vùng đệm an toàn.
        let safeRadius = max(20.0, min(sceneW * 0.34, sceneH * 0.22, 38.0))

        // MARK: - 1. Vầng hào quang bung tỏa (Aura / Lens Flare Halo)
        let haloRadius = safeRadius * 0.50
        let halo = SKShapeNode(circleOfRadius: haloRadius)
        halo.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.40)
        halo.strokeColor = UIColor(red: 1.0, green: 0.95, blue: 0.65, alpha: 0.55)
        halo.lineWidth = 1.5
        halo.setScale(0.3)
        halo.zPosition = 1
        sunRig.addChild(halo)

        let haloExpand = SKAction.group([
            SKAction.scale(to: 1.65, duration: 0.95),
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.60, duration: 0.20),
                SKAction.fadeOut(withDuration: 0.75)
            ])
        ])
        halo.run(haloExpand)

        // MARK: - 2. Cụm tia nắng tỏa xoay (12 Rotating Sunbeams)
        let raysNode = SKNode()
        raysNode.zPosition = 2
        raysNode.setScale(0.1)
        sunRig.addChild(raysNode)

        let rayCount = 12
        let innerRadius = safeRadius * 0.36
        for i in 0..<rayCount {
            let angle = (CGFloat(i) / CGFloat(rayCount)) * .pi * 2.0
            let isLong = (i % 2 == 0)
            let rayLength = isLong ? (safeRadius * 0.28) : (safeRadius * 0.16)
            let rayThickness: CGFloat = isLong ? 2.4 : 1.8

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

        let raysPop = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.14)
        ])
        let raysRotate = SKAction.rotate(byAngle: .pi / 3.0, duration: 1.1)
        raysRotate.timingMode = .easeOut
        let raysFade = SKAction.sequence([
            SKAction.wait(forDuration: 0.65),
            SKAction.fadeOut(withDuration: 0.45)
        ])
        raysNode.run(SKAction.group([raysPop, raysRotate, raysFade]))

        // MARK: - 3. Mặt trời vàng tròn rạng rỡ (Sun Core & Face)
        let sunCore = SKNode()
        sunCore.zPosition = 3
        sunCore.setScale(0.1)
        sunRig.addChild(sunCore)

        let coreRadius = safeRadius * 0.32

        // Bầu tròn mặt trời vàng cam ấm áp
        let sunCircle = SKShapeNode(circleOfRadius: coreRadius)
        sunCircle.fillColor = UIColor(red: 1.0, green: 0.78, blue: 0.15, alpha: 1.0)
        sunCircle.strokeColor = UIColor(red: 1.0, green: 0.60, blue: 0.05, alpha: 1.0)
        sunCircle.lineWidth = 1.6
        sunCore.addChild(sunCircle)

        // Điểm sáng phản chiếu nhẹ góc trên (Highlight)
        let sunHighlight = SKShapeNode(ellipseOf: CGSize(width: coreRadius * 0.42, height: coreRadius * 0.24))
        sunHighlight.fillColor = UIColor(white: 1.0, alpha: 0.55)
        sunHighlight.strokeColor = .clear
        sunHighlight.position = CGPoint(x: -coreRadius * 0.30, y: coreRadius * 0.40)
        sunHighlight.zRotation = 0.4
        sunCore.addChild(sunHighlight)

        // Mắt cười híp tít (Joyful curved eyes)
        let eyeColor = UIColor(red: 0.35, green: 0.18, blue: 0.08, alpha: 1.0)
        let eyeOffset = coreRadius * 0.32
        let eyeRadius = coreRadius * 0.18
        for offset in [-eyeOffset, eyeOffset] {
            let eyePath = CGMutablePath()
            eyePath.addArc(center: CGPoint(x: offset, y: coreRadius * 0.18), radius: eyeRadius, startAngle: 0.2, endAngle: .pi - 0.2, clockwise: false)
            let eye = SKShapeNode(path: eyePath)
            eye.strokeColor = eyeColor
            eye.lineWidth = 1.6
            eye.lineCap = .round
            sunCore.addChild(eye)
        }

        // Nụ cười tươi rạng rỡ (Open warm smile)
        let mouthPath = CGMutablePath()
        mouthPath.addArc(center: CGPoint(x: 0, y: -coreRadius * 0.10), radius: coreRadius * 0.30, startAngle: .pi + 0.3, endAngle: -.pi * 2.0 - 0.3, clockwise: false)
        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = eyeColor
        mouth.fillColor = UIColor(red: 0.88, green: 0.25, blue: 0.25, alpha: 0.85)
        mouth.lineWidth = 1.4
        sunCore.addChild(mouth)

        // Hai má hồng xinh xắn (Blush cheeks)
        let blushOffset = coreRadius * 0.55
        let blushRadius = coreRadius * 0.16
        for offset in [-blushOffset, blushOffset] {
            let blush = SKShapeNode(circleOfRadius: blushRadius)
            blush.fillColor = UIColor(red: 1.0, green: 0.45, blue: 0.55, alpha: 0.65)
            blush.strokeColor = .clear
            blush.position = CGPoint(x: offset, y: -coreRadius * 0.04)
            sunCore.addChild(blush)
        }

        // Animation mặt trời nảy lò xo & mờ dần
        let sunScaleIn = SKAction.sequence([
            SKAction.scale(to: 1.20, duration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.14),
            SKAction.wait(forDuration: 0.45),
            SKAction.group([
                SKAction.scale(to: 1.18, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ])
        ])
        sunCore.run(sunScaleIn)

        // MARK: - 4. Bụi hạt nắng lấp lánh (Solar Sparkle Glints)
        let sparkleCount = 12
        for _ in 0..<sparkleCount {
            let sparkle = createSparkleStar(maxRadius: safeRadius * 0.14)
            sparkle.zPosition = 4
            sunRig.addChild(sparkle)

            let randomAngle = CGFloat.random(in: 0...(.pi * 2.0))
            let randomDistance = CGFloat.random(in: (safeRadius * 0.35)...(safeRadius * 0.78))
            let targetX = cos(randomAngle) * randomDistance
            let targetY = sin(randomAngle) * randomDistance + CGFloat.random(in: 5.0...18.0)

            let burstDuration = Double.random(in: 0.60...0.95)
            let moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: burstDuration)
            moveAction.timingMode = .easeOut

            let spinAction = SKAction.rotate(byAngle: CGFloat.random(in: -2.0...2.0), duration: burstDuration)
            let fadeAction = SKAction.sequence([
                SKAction.wait(forDuration: burstDuration * 0.4),
                SKAction.fadeOut(withDuration: burstDuration * 0.6)
            ])
            let scaleAction = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.0...1.3), duration: burstDuration * 0.3),
                SKAction.scale(to: 0.2, duration: burstDuration * 0.7)
            ])

            sparkle.run(SKAction.group([moveAction, spinAction, fadeAction, scaleAction]))
        }

        // Tự động giải phóng node sau khi hiệu ứng kết thúc
        let cleanUp = SKAction.sequence([
            SKAction.wait(forDuration: 1.20),
            SKAction.removeFromParent()
        ])
        sunRig.run(cleanUp)
    }

    // MARK: - Helper tạo ngôi sao 4 cánh lấp lánh

    private func createSparkleStar(maxRadius: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter: CGFloat = CGFloat.random(in: (maxRadius * 0.7)...maxRadius)
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
        star.lineWidth = 0.7
        star.setScale(0.1)
        return star
    }
}

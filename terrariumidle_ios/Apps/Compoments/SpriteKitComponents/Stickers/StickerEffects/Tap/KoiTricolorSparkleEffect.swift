//
//  KoiTricolorSparkleEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng Thị Giác Lấp Lánh Tam Sắc (Tricolor Sparkle: Xanh Dương, Đỏ, Vàng)
/// - Dành riêng cho Đèn Cá Chép (Koi Windsock Lantern - Sticker3)
/// - Theo yêu cầu: "click sẽ có hiệu ứng lấp lánh xanh dương, đỏ, vàng theo như màu cá"
/// - Phân bổ chuẩn xác theo 3 vị trí tương ứng của 3 chú cá:
///   * Cá Đỏ (trên cùng): bung tỏa chùm sao đỏ ruby & hồng san hô rực rỡ
///   * Cá Vàng (ở giữa): bung tỏa chùm sao vàng kim & cam hổ phách chói lọi
///   * Cá Xanh Dương (dưới cùng): bung tỏa chùm sao xanh cyan & đại dương lộng lẫy
public final class KoiTricolorSparkleEffect: StickerTapEffect {

    public var name: String { "koiTricolorSparkle" }

    public init() {}

    public func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool) {
        let rig = SKNode()
        rig.zPosition = 200

        let baseOrigin: CGPoint
        if let parent = targetNode.parent {
            baseOrigin = parent.convert(targetNode.position, to: containerNode)
        } else {
            baseOrigin = targetNode.position
        }

        rig.position = baseOrigin
        containerNode.addChild(rig)

        let fishSprite = targetNode as? SKSpriteNode
        let fishH = fishSprite?.size.height ?? 140.0

        // ==============================================================
        // 3 TẦNG CÁ THEO THÂN SPRITE (ĐỎ Ở TRÊN, VÀNG Ở GIỮA, XANH Ở DƯỚI)
        // ==============================================================

        // 1. Tầng Cá Đỏ (Red Koi Fish) - đỉnh cụm cá (khoảng 20% từ đỉnh móc xuống)
        let redY = -fishH * 0.20
        let redColor = UIColor(red: 1.0, green: 0.23, blue: 0.35, alpha: 0.95)
        let redStroke = UIColor(red: 1.0, green: 0.10, blue: 0.25, alpha: 0.90)
        spawnFishSparkles(in: rig, origin: CGPoint(x: 0, y: redY), mainColor: redColor, strokeColor: redStroke, count: 9)

        // 2. Tầng Cá Vàng (Golden Amber Koi Fish) - giữa cụm cá (khoảng 55% từ đỉnh móc xuống)
        let yellowY = -fishH * 0.55
        let yellowColor = UIColor(red: 1.0, green: 0.82, blue: 0.0, alpha: 0.95)
        let yellowStroke = UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 0.90)
        spawnFishSparkles(in: rig, origin: CGPoint(x: 0, y: yellowY), mainColor: yellowColor, strokeColor: yellowStroke, count: 10)

        // 3. Tầng Cá Xanh Dương (Ocean Blue Koi Fish) - đáy cụm cá (khoảng 85% từ đỉnh móc xuống)
        let blueY = -fishH * 0.85
        let blueColor = UIColor(red: 0.05, green: 0.58, blue: 1.0, alpha: 0.95)
        let blueStroke = UIColor(red: 0.35, green: 0.80, blue: 1.0, alpha: 0.90)
        spawnFishSparkles(in: rig, origin: CGPoint(x: 0, y: blueY), mainColor: blueColor, strokeColor: blueStroke, count: 9)

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnFishSparkles(
        in parent: SKNode,
        origin: CGPoint,
        mainColor: UIColor,
        strokeColor: UIColor,
        count: Int
    ) {
        // Vầng hào quang màu tương ứng
        let halo = SKShapeNode(circleOfRadius: 16.0)
        halo.position = origin
        halo.fillColor = mainColor.withAlphaComponent(0.35)
        halo.strokeColor = strokeColor.withAlphaComponent(0.70)
        halo.lineWidth = 1.0
        parent.addChild(halo)

        let expandHalo = SKAction.group([
            SKAction.scale(to: 2.2, duration: 0.55),
            SKAction.fadeOut(withDuration: 0.55)
        ])
        expandHalo.timingMode = .easeOut
        halo.run(SKAction.sequence([expandHalo, SKAction.removeFromParent()]))

        // Sinh các ngôi sao lấp lánh tỏa ra từ vị trí cá
        for _ in 0..<count {
            let isOctagon = Bool.random()
            let star = createStar(mainColor: mainColor, strokeColor: strokeColor, isOctagon: isOctagon)
            star.position = origin
            parent.addChild(star)

            let angle = CGFloat.random(in: 0...(.pi * 2.0))
            let dist = CGFloat.random(in: 18.0...52.0)
            let tx = origin.x + cos(angle) * dist
            let ty = origin.y + sin(angle) * dist + CGFloat.random(in: 2.0...12.0) // Trôi nhẹ lên trên theo gió

            let dur = Double.random(in: 0.55...0.90)

            let move = SKAction.move(to: CGPoint(x: tx, y: ty), duration: dur)
            move.timingMode = .easeOut

            let rot = SKAction.rotate(byAngle: CGFloat.random(in: -3.5...3.5), duration: dur)

            // Hiệu ứng nhấp nháy lấp lánh (Twinkle pulse scale)
            let pulseScale = SKAction.sequence([
                SKAction.scale(to: CGFloat.random(in: 1.1...1.4), duration: dur * 0.35),
                SKAction.scale(to: 0.05, duration: dur * 0.65)
            ])

            let fade = SKAction.sequence([
                SKAction.wait(forDuration: dur * 0.4),
                SKAction.fadeOut(withDuration: dur * 0.6)
            ])

            star.run(SKAction.group([move, rot, pulseScale, fade]))
        }
    }

    private func createStar(mainColor: UIColor, strokeColor: UIColor, isOctagon: Bool) -> SKShapeNode {
        let path = CGMutablePath()
        let rOuter: CGFloat = CGFloat.random(in: 3.8...5.8)
        let rInner: CGFloat = rOuter * (isOctagon ? 0.28 : 0.20)
        let points = isOctagon ? 8 : 4

        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * (.pi / CGFloat(points))
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = mainColor
        star.strokeColor = strokeColor
        star.lineWidth = 0.6
        star.setScale(0.1)
        return star
    }
}

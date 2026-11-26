//
//  BeeStartledSparkEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Hiệu ứng thị giác giật mình khi người dùng chạm vào chú ong đang bay hoặc đang lấy mật
public enum BeeStartledSparkEffect {

    public static func trigger(at position: CGPoint, in containerNode: SKNode) {
        let rig = SKNode()
        rig.position = position
        rig.zPosition = 260
        containerNode.addChild(rig)

        // 1. Vòng sóng giật mình trắng-vàng
        let ring = SKShapeNode(circleOfRadius: 10.0)
        ring.fillColor = .clear
        ring.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.95)
        ring.lineWidth = 2.0
        rig.addChild(ring)

        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.5, duration: 0.28),
                SKAction.fadeOut(withDuration: 0.28)
            ]),
            SKAction.removeFromParent()
        ]))

        // 2. 3 tia giật mình tỏa phía trên đầu chú ong
        let spikeAngles: [CGFloat] = [.pi * 0.32, .pi * 0.50, .pi * 0.68]
        for angle in spikeAngles {
            let linePath = CGMutablePath()
            linePath.move(to: CGPoint(x: 0, y: 0))
            linePath.addLine(to: CGPoint(x: 0, y: 11.0))

            let spike = SKShapeNode(path: linePath)
            spike.strokeColor = UIColor(red: 1.0, green: 0.42, blue: 0.25, alpha: 0.95)
            spike.lineWidth = 2.2
            spike.lineCap = .round
            spike.position = CGPoint(x: cos(angle) * 14.0, y: sin(angle) * 14.0 + 4.0)
            spike.zRotation = angle - .pi / 2.0
            rig.addChild(spike)

            let burst = SKAction.group([
                SKAction.moveBy(x: cos(angle) * 10.0, y: sin(angle) * 10.0, duration: 0.26),
                SKAction.fadeOut(withDuration: 0.26)
            ])
            burst.timingMode = .easeOut
            spike.run(SKAction.sequence([burst, SKAction.removeFromParent()]))
        }

        // 3. Chấm nhỏ phấn hoa văng nhẹ
        for _ in 0..<5 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.8...3.0))
            dot.fillColor = UIColor(red: 1.0, green: 0.84, blue: 0.25, alpha: 0.95)
            dot.strokeColor = .clear
            rig.addChild(dot)

            let a = CGFloat.random(in: 0...(.pi * 2))
            let d = CGFloat.random(in: 18...34)
            let move = SKAction.move(to: CGPoint(x: cos(a) * d, y: sin(a) * d), duration: 0.34)
            move.timingMode = .easeOut
            dot.run(SKAction.sequence([
                SKAction.group([move, SKAction.fadeOut(withDuration: 0.34)]),
                SKAction.removeFromParent()
            ]))
        }

        rig.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.45),
            SKAction.removeFromParent()
        ]))
    }
}

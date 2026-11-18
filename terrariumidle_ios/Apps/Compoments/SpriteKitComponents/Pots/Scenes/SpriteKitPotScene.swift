//
//  SpriteKitPotScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - SpriteKit Scene cho Chậu cây trong Terrarium
public final class SpriteKitPotScene: SKScene {
    // MARK: - Properties

    private var potNode: SKSpriteNode?
    private var shadowNode: SKShapeNode?
    private var potId: String = "pot1"
    private var isHanging: Bool = false
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public override init() {
        super.init(size: .zero)
        setupBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBasics()
    }

    private func setupBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    // MARK: - Configuration

    public func configure(potId: String, isHanging: Bool = false) {
        self.potId = potId
        self.isHanging = isHanging

        if size.width > 0 && size.height > 0 {
            buildPot()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        if potNode == nil && size.width > 0 && size.height > 0 {
            buildPot()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if size.width > 0 && size.height > 0 {
            buildPot()
        }
    }

    // MARK: - Build Pot Node

    private func buildPot() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()

        // 1. Bóng đổ dưới đáy chậu (nếu không treo)
        if !isHanging {
            let shadowWidth = size.width * 0.65
            let shadowHeight = size.height * 0.12
            let shadow = SKShapeNode(ellipseOf: CGSize(width: shadowWidth, height: shadowHeight))
            shadow.fillColor = UIColor.black.withAlphaComponent(0.18)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: size.width / 2, y: size.height * 0.08)
            shadow.zPosition = 1
            addChild(shadow)
            self.shadowNode = shadow
        }

        // 2. Chậu cây chính
        let texture = loadPotTexture()
        let node = SKSpriteNode(texture: texture)

        let fitWidth = (size.width * 0.85) / texture.size().width
        let fitHeight = (size.height * 0.82) / texture.size().height
        self.baseScale = min(fitWidth, fitHeight)
        node.setScale(baseScale)

        if isHanging {
            node.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            node.position = CGPoint(x: size.width / 2, y: size.height)
        } else {
            node.anchorPoint = CGPoint(x: 0.5, y: 0.08)
            node.position = CGPoint(x: size.width / 2, y: 0)
        }
        node.zPosition = 10

        addChild(node)
        self.potNode = node
    }

    // MARK: - Animation: Phản hồi khi chạm vào chậu

    public func playTapAnimation() {
        guard let node = potNode else { return }

        let compress = SKAction.scaleX(to: baseScale * 1.08, y: baseScale * 0.88, duration: 0.10)
        compress.timingMode = .easeIn
        let rebound = SKAction.scaleX(to: baseScale * 0.94, y: baseScale * 1.06, duration: 0.14)
        rebound.timingMode = .easeOut
        let settle = SKAction.scale(to: baseScale, duration: 0.16)
        settle.timingMode = .easeInEaseOut

        node.run(SKAction.sequence([compress, rebound, settle]))

        // Hiệu ứng bóng co giãn nhẹ theo nhịp nảy
        if let shadow = shadowNode {
            let shrink = SKAction.scale(to: 0.88, duration: 0.10)
            let restore = SKAction.scale(to: 1.0, duration: 0.30)
            shadow.run(SKAction.sequence([shrink, restore]))
        }
    }

    // MARK: - Texture Loader & Procedural Fallback

    private func loadPotTexture() -> SKTexture {
        let candidates = [potId, "i_\(potId)", "pot_\(potId)"]
        for name in candidates {
            if let image = UIImage(named: name) {
                return SKTexture(image: image)
            }
        }

        return Self.generateProceduralPotTexture(potId: potId, isHanging: isHanging)
    }

    public static func generateProceduralPotTexture(potId: String, isHanging: Bool) -> SKTexture {
        let size = CGSize(width: 120, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext

            if isHanging {
                // Dây treo macrame từ trên xuống
                let stringPath = UIBezierPath()
                stringPath.move(to: CGPoint(x: 60, y: 4))
                stringPath.addLine(to: CGPoint(x: 25, y: 50))
                stringPath.move(to: CGPoint(x: 60, y: 4))
                stringPath.addLine(to: CGPoint(x: 95, y: 50))
                UIColor(red: 0.82, green: 0.75, blue: 0.65, alpha: 0.9).setStroke()
                stringPath.lineWidth = 1.8
                stringPath.stroke()

                // Chậu bán cầu treo
                let potRect = CGRect(x: 22, y: 45, width: 76, height: 48)
                let potPath = UIBezierPath(roundedRect: potRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 36, height: 36))
                UIColor(red: 0.94, green: 0.90, blue: 0.85, alpha: 0.98).setFill()
                potPath.fill()

                // Viền miệng chậu
                let rim = UIBezierPath(roundedRect: CGRect(x: 20, y: 42, width: 80, height: 8), cornerRadius: 3)
                UIColor(red: 0.85, green: 0.78, blue: 0.70, alpha: 1.0).setFill()
                rim.fill()
            } else {
                // Chậu gốm nung Terracotta cổ điển hình thang
                let potPath = UIBezierPath()
                potPath.move(to: CGPoint(x: 20, y: 22))
                potPath.addLine(to: CGPoint(x: 100, y: 22))
                potPath.addLine(to: CGPoint(x: 88, y: 88))
                potPath.addLine(to: CGPoint(x: 32, y: 88))
                potPath.close()

                UIColor(red: 0.85, green: 0.48, blue: 0.32, alpha: 0.98).setFill()
                potPath.fill()

                // Vành miệng chậu
                let rim = UIBezierPath(roundedRect: CGRect(x: 15, y: 14, width: 90, height: 12), cornerRadius: 4)
                UIColor(red: 0.90, green: 0.54, blue: 0.36, alpha: 1.0).setFill()
                rim.fill()

                // Họa tiết dải màu trang trí nhẹ trên thân chậu
                let band = UIBezierPath()
                band.move(to: CGPoint(x: 25, y: 40))
                band.addLine(to: CGPoint(x: 95, y: 40))
                UIColor.white.withAlphaComponent(0.35).setStroke()
                band.lineWidth = 2.0
                band.stroke()
            }
        }
        return SKTexture(image: image)
    }
}

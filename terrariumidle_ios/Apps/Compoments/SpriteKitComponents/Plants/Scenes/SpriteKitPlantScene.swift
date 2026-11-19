//
//  SpriteKitPlantScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - SpriteKit Scene cho Cây cảnh trong Terrarium
public final class SpriteKitPlantScene: SKScene {
    // MARK: - Properties

    private var plantNode: SKSpriteNode?
    private var plant1Node: Plant1Node?
    private var plant2Node: Plant2Node?
    private var plant3Node: Plant3Node?
    private var plantId: String = "plant1"
    private var plantLevel: Int = 1
    private var isHanging: Bool = false

    private var baseScale: CGFloat = 1.0

    private var hasActivePlantNode: Bool {
        plantNode != nil || plant1Node != nil || plant2Node != nil || plant3Node != nil
    }

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
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
    }

    // MARK: - Configuration

    public func configure(plantId: String, level: Int = 1, isHanging: Bool = false) {
        let changed = self.plantId != plantId || self.plantLevel != level || self.isHanging != isHanging
        self.plantId = plantId
        self.plantLevel = level
        self.isHanging = isHanging

        if (changed || !hasActivePlantNode) && size.width > 0 && size.height > 0 {
            buildPlant()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        view.isPaused = false
        self.isPaused = false
        if !hasActivePlantNode && size.width > 0 && size.height > 0 {
            buildPlant()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !hasActivePlantNode || abs(oldSize.width - size.width) > 2 || abs(oldSize.height - size.height) > 2 {
            if size.width > 0 && size.height > 0 {
                buildPlant()
            }
        }
    }

    // MARK: - Build Plant Node

    private func buildPlant() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()
        plantNode = nil
        plant1Node = nil
        plant2Node = nil
        plant3Node = nil
        anchorPoint = CGPoint(x: 0.5, y: 0.0) // Luôn neo gốc tọa độ tại đáy giữa

        // ĐẶC BIỆT: Cây Cỏ Loe (plant1) hỗ trợ 3 trạng thái và 18 lá uốn lượn riêng biệt
        if plantId.lowercased() == "plant1" {
            let p1 = Plant1Node(level: plantLevel, containerSize: size, isHanging: isHanging)
            p1.position = CGPoint(x: 0, y: isHanging ? size.height : 0)
            addChild(p1)
            self.plant1Node = p1
            return
        }

        // ĐẶC BIỆT: Cây Nha Đam (plant2 - Aloe Vera) với 8 bẹ mọng nước uốn lượn
        if plantId.lowercased() == "plant2" {
            let p2 = Plant2Node(level: plantLevel, containerSize: size, isHanging: isHanging)
            p2.position = CGPoint(x: 0, y: isHanging ? size.height : 0)
            addChild(p2)
            self.plant2Node = p2
            return
        }

        // ĐẶC BIỆT: Cây Begonia Rex (plant3 - Thu hải đường lá rộng) với 15 phiến lá bản rộng
        if plantId.lowercased() == "plant3" {
            let p3 = Plant3Node(level: plantLevel, containerSize: size, isHanging: isHanging)
            p3.position = CGPoint(x: 0, y: isHanging ? size.height : 0)
            addChild(p3)
            self.plant3Node = p3
            return
        }

        // Không dùng mockup nữa: Những cây chưa có asset sẽ hiển thị thông báo update
        if !PlantAvailability.isAvailable(plantId: plantId) {
            let label = SKLabelNode(text: "<update app để hiển thị>")
            label.fontSize = 10
            label.fontColor = UIColor.secondaryLabel
            label.position = CGPoint(x: 0, y: size.height * 0.45)
            label.zPosition = 20
            addChild(label)
            return
        }

        // 1. Tạo hoặc tải texture cây (cho các cây khác)
        let texture = loadPlantTexture()
        let node = SKSpriteNode(texture: texture)

        // Tính tỉ lệ tăng trưởng theo cấp độ (Level 1: mầm non, Level 2: đang lớn, Level 3+: trưởng thành)
        let levelRatio: CGFloat
        switch plantLevel {
        case 1: levelRatio = 0.72
        case 2: levelRatio = 0.86
        default: levelRatio = 1.0
        }

        let fitWidthRatio = (size.width * 0.88) / texture.size().width
        let fitHeightRatio = (size.height * 0.88) / texture.size().height
        self.baseScale = min(fitWidthRatio, fitHeightRatio) * levelRatio

        node.setScale(baseScale)

        if isHanging {
            // Cây treo: neo từ đỉnh chúc xuống
            node.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            node.position = CGPoint(x: 0, y: size.height)
        } else {
            // Cây bình thường: neo từ gốc chậu mọc lên
            node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
            node.position = CGPoint(x: 0, y: 0)
        }

        addChild(node)
        self.plantNode = node

        // 2. Kích hoạt hiệu ứng đung đưa tự nhiên trong gió (Gentle idle sway)
        startIdleSway(node: node)
    }

    // MARK: - Animation: Đung đưa theo gió

    private func startIdleSway(node: SKNode) {
        node.removeAction(forKey: "idleSway")

        let swayAngle: CGFloat = isHanging ? 0.045 : 0.035
        let swayDuration: Double = Double.random(in: 2.2...3.2)

        let swayLeft = SKAction.rotate(toAngle: -swayAngle, duration: swayDuration)
        swayLeft.timingMode = .easeInEaseOut

        let swayRight = SKAction.rotate(toAngle: swayAngle, duration: swayDuration)
        swayRight.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([swayLeft, swayRight])
        node.run(SKAction.repeatForever(sequence), withKey: "idleSway")
    }

    // MARK: - Animation: Phản hồi khi người dùng chạm vào cây (Tap Bounce)

    public func playTapAnimation() {
        if let p1 = plant1Node {
            p1.playTapAnimation()
            return
        }
        if let p2 = plant2Node {
            p2.playTapAnimation()
            return
        }
        if let p3 = plant3Node {
            p3.playTapAnimation()
            return
        }
        guard let node = plantNode else { return }

        // Hiệu ứng nảy Squash & Stretch
        let squash = SKAction.scaleX(to: baseScale * 1.15, y: baseScale * 0.86, duration: 0.12)
        squash.timingMode = .easeIn
        let stretch = SKAction.scaleX(to: baseScale * 0.92, y: baseScale * 1.14, duration: 0.16)
        stretch.timingMode = .easeOut
        let settle = SKAction.scale(to: baseScale, duration: 0.18)
        settle.timingMode = .easeInEaseOut

        let bounceSequence = SKAction.sequence([squash, stretch, settle])
        node.run(bounceSequence)

        // Bắn ra 2-3 bong bóng oxy phát sáng bay lên
        spawnOxygenBubbles()
    }

    private func spawnOxygenBubbles() {
        guard let _ = plantNode else { return }

        let bubbleCount: Int
        switch plantLevel {
        case 1, 100:
            bubbleCount = Int.random(in: 1...2)
        case 2, 200:
            bubbleCount = Int.random(in: 3...4)
        default:
            bubbleCount = Int.random(in: 7...10)
        }

        for i in 0..<bubbleCount {
            let radius: CGFloat
            let spawnX: CGFloat
            let spawnY: CGFloat
            let floatDistance: CGFloat

            switch plantLevel {
            case 1, 100:
                radius = CGFloat.random(in: 1.8...3.0)
                spawnX = CGFloat.random(in: -size.width * 0.08...size.width * 0.08)
                spawnY = CGFloat.random(in: size.height * 0.03...size.height * 0.12)
                floatDistance = CGFloat.random(in: 18...35)
            case 2, 200:
                radius = CGFloat.random(in: 2.2...3.8)
                spawnX = CGFloat.random(in: -size.width * 0.10...size.width * 0.10)
                spawnY = CGFloat.random(in: size.height * 0.05...size.height * 0.20)
                floatDistance = CGFloat.random(in: 25...45)
            default:
                radius = CGFloat.random(in: 3.5...7.5)
                spawnX = CGFloat.random(in: -size.width * 0.46...size.width * 0.46)
                spawnY = CGFloat.random(in: size.height * 0.18...size.height * 0.88)
                floatDistance = CGFloat.random(in: 60...115)
            }

            let bubble = SKShapeNode(circleOfRadius: radius)
            bubble.fillColor = UIColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 0.85)
            bubble.strokeColor = UIColor.white.withAlphaComponent(0.7)
            bubble.lineWidth = 1.0

            let highlight = SKShapeNode(circleOfRadius: radius * 0.3)
            highlight.fillColor = UIColor.white.withAlphaComponent(0.8)
            highlight.strokeColor = .clear
            highlight.position = CGPoint(x: -radius * 0.3, y: radius * 0.3)
            bubble.addChild(highlight)

            bubble.position = CGPoint(x: spawnX, y: spawnY)
            bubble.zPosition = 100
            bubble.alpha = 0.0
            addChild(bubble)

            let floatDuration = Double.random(in: 0.8...1.5)
            let driftX = CGFloat.random(in: -20...20)

            let delay = SKAction.wait(forDuration: Double(i) * 0.04)
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.12)
            let floatUp = SKAction.moveBy(x: driftX, y: floatDistance, duration: floatDuration)
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: floatDuration * 0.6)
            let scaleUp = SKAction.scale(by: 1.30, duration: floatDuration)

            let motionGroup = SKAction.group([
                floatUp,
                SKAction.sequence([SKAction.wait(forDuration: floatDuration * 0.4), fadeOut]),
                scaleUp
            ])

            bubble.run(SKAction.sequence([delay, fadeIn, motionGroup, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Texture Loader & Procedural Fallback

    private func loadPlantTexture() -> SKTexture {
        // 1. Thử tải ảnh thật từ Assets nếu có
        let candidates = [plantId, "i_\(plantId)", "plant_\(plantId)"]
        for name in candidates {
            if let image = UIImage(named: name) {
                return SKTexture(image: image)
            }
        }

        // 2. Tự vẽ cây vector sinh học nếu chưa có ảnh
        return Self.generateProceduralPlantTexture(plantId: plantId, isHanging: isHanging)
    }

    public static func generateProceduralPlantTexture(plantId: String, isHanging: Bool) -> SKTexture {
        let size = CGSize(width: 140, height: 160)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let midX: CGFloat = 70

            if isHanging {
                // Cây rủ xuống (Hanging Ivy / Dây leo)
                let stemPath = UIBezierPath()
                stemPath.move(to: CGPoint(x: midX, y: 10))
                stemPath.addCurve(to: CGPoint(x: midX - 25, y: 140), controlPoint1: CGPoint(x: midX - 35, y: 60), controlPoint2: CGPoint(x: midX - 10, y: 100))
                stemPath.move(to: CGPoint(x: midX, y: 10))
                stemPath.addCurve(to: CGPoint(x: midX + 28, y: 130), controlPoint1: CGPoint(x: midX + 35, y: 55), controlPoint2: CGPoint(x: midX + 10, y: 95))

                UIColor(red: 0.28, green: 0.60, blue: 0.32, alpha: 0.9).setStroke()
                stemPath.lineWidth = 2.5
                stemPath.stroke()

                // Các lá mọc dọc dây leo
                let leafColor = UIColor(red: 0.38, green: 0.78, blue: 0.40, alpha: 0.95)
                leafColor.setFill()
                for y in stride(from: 30, to: 130, by: 22) {
                    let leafRect1 = CGRect(x: midX - 40, y: CGFloat(y), width: 18, height: 12)
                    context.fillEllipse(in: leafRect1)
                    let leafRect2 = CGRect(x: midX + 24, y: CGFloat(y + 8), width: 18, height: 12)
                    context.fillEllipse(in: leafRect2)
                }
            } else {
                // Thân cây chính
                let stem = UIBezierPath()
                stem.move(to: CGPoint(x: midX, y: 155))
                stem.addCurve(to: CGPoint(x: midX, y: 40), controlPoint1: CGPoint(x: midX - 8, y: 110), controlPoint2: CGPoint(x: midX + 6, y: 70))
                UIColor(red: 0.32, green: 0.58, blue: 0.28, alpha: 0.95).setStroke()
                stem.lineWidth = 3.5
                stem.stroke()

                // Tán lá xum xuê mềm mại
                let foliageColors = [
                    UIColor(red: 0.28, green: 0.72, blue: 0.42, alpha: 0.92),
                    UIColor(red: 0.42, green: 0.82, blue: 0.48, alpha: 0.92),
                    UIColor(red: 0.22, green: 0.62, blue: 0.35, alpha: 0.92)
                ]

                let leafClusters: [(CGRect, Int)] = [
                    (CGRect(x: midX - 35, y: 65, width: 34, height: 24), 0),
                    (CGRect(x: midX + 5, y: 55, width: 36, height: 24), 1),
                    (CGRect(x: midX - 30, y: 35, width: 32, height: 22), 2),
                    (CGRect(x: midX + 2, y: 25, width: 35, height: 22), 0),
                    (CGRect(x: midX - 18, y: 10, width: 36, height: 28), 1)
                ]

                for (rect, colorIdx) in leafClusters {
                    foliageColors[colorIdx].setFill()
                    context.fillEllipse(in: rect)
                }
            }
        }
        return SKTexture(image: image)
    }
}

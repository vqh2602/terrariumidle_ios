//
//  FirefliesScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - SpriteKit Scene cho hiệu ứng Đom đóm bay lượn phát sáng
public final class FirefliesScene: SKScene {
    // MARK: - Properties

    private var fireflyTextures: [SKTexture] = []
    private var fireflyCount: Int = 24
    private var isConfigured = false

    // MARK: - Initializer

    public override init() {
        super.init(size: .zero)
        setupSceneBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupSceneBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSceneBasics()
    }

    private func setupSceneBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    // MARK: - Configuration

    public func configure(count: Int = 24, customImages: [UIImage] = []) {
        self.fireflyCount = count

        var textures: [SKTexture] = []
        for img in customImages.prefix(6) {
            textures.append(SKTexture(image: img))
        }

        // Tự sinh 3 loại texture đom đóm phát sáng (vàng chanh, vàng kim, xanh lục phát quang)
        if textures.isEmpty {
            textures = [
                Self.generateGlowTexture(coreColor: UIColor(red: 1.0, green: 0.98, blue: 0.70, alpha: 1.0),
                                         haloColor: UIColor(red: 0.82, green: 0.98, blue: 0.35, alpha: 0.55)),
                Self.generateGlowTexture(coreColor: UIColor(red: 1.0, green: 0.95, blue: 0.50, alpha: 1.0),
                                         haloColor: UIColor(red: 0.98, green: 0.85, blue: 0.25, alpha: 0.60)),
                Self.generateGlowTexture(coreColor: UIColor(red: 0.85, green: 1.0, blue: 0.75, alpha: 1.0),
                                         haloColor: UIColor(red: 0.45, green: 0.95, blue: 0.50, alpha: 0.50))
            ]
        }

        self.fireflyTextures = textures

        if size.width > 0 && size.height > 0 {
            startFireflies()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear

        if !isConfigured && size.width > 0 && size.height > 0 {
            startFireflies()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !isConfigured && size.width > 0 && size.height > 0 {
            startFireflies()
        }
    }

    // MARK: - Fireflies Emitter

    private func startFireflies() {
        guard !isConfigured, size.width > 0, size.height > 0 else { return }
        isConfigured = true

        removeAllChildren()

        // 1. Ưu tiên nạp hiệu ứng hạt từ file Fireflies.sks
        if let emitter = SKEmitterNode(fileNamed: "Fireflies.sks") ?? SKEmitterNode(fileNamed: "Fireflies") {
            emitter.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
            emitter.particlePositionRange = CGVector(dx: size.width * 0.9, dy: size.height * 0.7)
            emitter.zPosition = 10
            addChild(emitter)
            return
        }

        // 2. Fallback procedural đom đóm
        for _ in 0..<fireflyCount {
            spawnFirefly()
        }
    }

    private func spawnFirefly() {
        guard !fireflyTextures.isEmpty, size.width > 0, size.height > 0 else { return }

        let texture = fireflyTextures.randomElement()!
        let firefly = SKSpriteNode(texture: texture)

        let initialX = CGFloat.random(in: 20...(size.width - 20))
        let initialY = CGFloat.random(in: 40...(size.height - 40))
        firefly.position = CGPoint(x: initialX, y: initialY)

        let baseScale = CGFloat.random(in: 0.45...0.90)
        firefly.setScale(baseScale)
        firefly.alpha = CGFloat.random(in: 0.2...0.9)
        firefly.zPosition = CGFloat.random(in: 1...10)

        // Blend mode add để tạo cảm giác ánh sáng lung linh cộng dồn
        firefly.blendMode = .add

        addChild(firefly)

        // 1. Chuyển động bay lượn ngẫu nhiên (Wandering motion)
        animateWandering(node: firefly)

        // 2. Hiệu ứng nhấp nháy phát sáng (Pulsing / Glowing)
        animatePulsing(node: firefly, baseScale: baseScale)
    }

    private func animateWandering(node: SKNode) {
        // Mỗi bước đom đóm bay đến một vị trí gần đó trong 2.5 - 4.5s
        let stepDuration = Double.random(in: 2.2...4.5)
        let deltaX = CGFloat.random(in: -70...70)
        let deltaY = CGFloat.random(in: -50...50)

        // Giữ đom đóm trong khung màn hình
        var targetX = node.position.x + deltaX
        var targetY = node.position.y + deltaY

        let padding: CGFloat = 30
        if targetX < padding { targetX = padding + CGFloat.random(in: 20...60) }
        if targetX > size.width - padding { targetX = size.width - padding - CGFloat.random(in: 20...60) }
        if targetY < padding { targetY = padding + CGFloat.random(in: 20...60) }
        if targetY > size.height - padding { targetY = size.height - padding - CGFloat.random(in: 20...60) }

        let moveAction = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: stepDuration)
        moveAction.timingMode = .easeInEaseOut

        node.run(moveAction) { [weak self, weak node] in
            guard let self = self, let node = node, node.parent != nil else { return }
            self.animateWandering(node: node)
        }
    }

    private func animatePulsing(node: SKNode, baseScale: CGFloat) {
        let pulseDuration = Double.random(in: 1.0...2.2)
        let darkDuration = Double.random(in: 0.3...1.2)

        let fadeOut = SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.35), duration: pulseDuration * 0.7)
        fadeOut.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: baseScale * 0.75, duration: pulseDuration * 0.7)
        scaleDown.timingMode = .easeInEaseOut
        let dimGroup = SKAction.group([fadeOut, scaleDown])

        let rest = SKAction.wait(forDuration: darkDuration)

        let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.85...1.0), duration: pulseDuration)
        fadeIn.timingMode = .easeInEaseOut
        let scaleUp = SKAction.scale(to: baseScale * 1.25, duration: pulseDuration)
        scaleUp.timingMode = .easeInEaseOut
        let brightGroup = SKAction.group([fadeIn, scaleUp])

        let pulseSequence = SKAction.sequence([dimGroup, rest, brightGroup])
        node.run(SKAction.repeatForever(pulseSequence), withKey: "pulse")
    }

    // MARK: - Procedural Texture Generator

    public static func generateGlowTexture(coreColor: UIColor, haloColor: UIColor) -> SKTexture {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let center = CGPoint(x: 16, y: 16)

            // Vòng hào quang phát sáng bên ngoài (Radial Gradient)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                haloColor.cgColor,
                haloColor.withAlphaComponent(0.2).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.55, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 2,
                    endCenter: center,
                    endRadius: 15,
                    options: .drawsAfterEndLocation
                )
            }

            // Tâm sáng trắng/vàng đậm ở giữa
            context.setFillColor(coreColor.cgColor)
            context.fillEllipse(in: CGRect(x: 13, y: 13, width: 6, height: 6))
        }
        return SKTexture(image: image)
    }
}

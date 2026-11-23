//
//  Landscape6Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 6: "Minamoto no Yuuhi" (源の夕陽 - Cội nguồn Hoàng hôn)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape6Scene.sks` kết hợp Fallback Procedural
/// - Bố cục dọc Portrait tối ưu toàn màn hình (1700 x 1943.233)
/// - Tối ưu hóa siêu tiết kiệm bộ nhớ (Ultra-Low Memory Footprint):
///   1. `bgNode` (z = 0): Dùng màu nền Metal thuần túy (#F9DFAD), tiêu tốn 0 MB VRAM texture
///   2. `sunGlowNode` (z = 4): Hào quang hoàng hôn phân tầng không dùng blur shader tốn GPU
///   3. `sunNode` (z = 5): Vầng thái dương hoàng hôn tối ưu kích thước
///   4. `mountainNodes` 11 -> 1 (z = 10 -> 20): 11 Tầng núi nạp qua texture cache tĩnh dùng chung
///   5. `effectsGroupNode` (z = 30): Giới hạn tối đa hạt bụi nắng, tự động thu dọn bộ nhớ
public final class Landscape6Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Texture Cache Dùng Chung (Tránh nạp lại texture vào VRAM)

    private static var sharedTextureCache: [String: SKTexture] = [:]

    // MARK: - Constants & Design Coordinates

    /// Kích thước canvas thiết kế chuẩn từ file SVG gốc
    private let baseDesignWidth: CGFloat = 1700.0
    private let baseDesignHeight: CGFloat = 1943.233
    private var activeScale: CGFloat = 1.0
    private var containerSize: CGSize = .zero

    // MARK: - Layer Nodes

    private let landscapeRootNode = SKNode()

    // 1. Nền bầu trời
    private var bgNode: SKSpriteNode?

    // 2. Thái dương & Hào quang
    private var sunNode: SKSpriteNode?
    private var sunGlowNode: SKNode?

    // 3. 11 Tầng núi (mountain_11 xa nhất -> mountain_1 gần nhất)
    private var mountainNodes: [SKSpriteNode] = []

    // 4. Nhóm hiệu ứng động & tương tác chạm
    private let effectsGroupNode = SKNode()
    private let tapRippleGroupNode = SKNode()

    // Ghi nhớ toạ độ nghỉ (Rest Positions) để chống trôi lệch toạ độ tuyệt đối
    private var restPositions: [String: CGPoint] = [:]

    // Metadata 11 Tầng núi
    private struct MountainData {
        let name: String
        let textureName: String
        let height: CGFloat
        let zPos: CGFloat
        let fillColorHex: String
    }

    private static let mountainConfigs: [MountainData] = [
        MountainData(name: "mountain_11", textureName: "landscape6-11@4.167x", height: 1310.444, zPos: 10.0, fillColorHex: "#F7C784"),
        MountainData(name: "mountain_10", textureName: "landscape6-10@4.167x", height: 1180.411, zPos: 11.0, fillColorHex: "#F4B870"),
        MountainData(name: "mountain_9",  textureName: "landscape6-9@4.167x",  height: 1113.356, zPos: 12.0, fillColorHex: "#F1AA61"),
        MountainData(name: "mountain_8",  textureName: "landscape6-8@4.167x",  height: 1052.683, zPos: 13.0, fillColorHex: "#DF8F54"),
        MountainData(name: "mountain_7",  textureName: "landscape6-7@4.167x",  height:  943.730, zPos: 14.0, fillColorHex: "#DC864C"),
        MountainData(name: "mountain_6",  textureName: "landscape6-6@4.167x",  height:  813.835, zPos: 15.0, fillColorHex: "#E39D5F"),
        MountainData(name: "mountain_5",  textureName: "landscape6-5@4.167x",  height:  734.039, zPos: 16.0, fillColorHex: "#DA9054"),
        MountainData(name: "mountain_4",  textureName: "landscape6-4@4.167x",  height:  764.875, zPos: 17.0, fillColorHex: "#D1824C"),
        MountainData(name: "mountain_3",  textureName: "landscape6-3@4.167x",  height:  859.211, zPos: 18.0, fillColorHex: "#523627"),
        MountainData(name: "mountain_2",  textureName: "landscape6-2@4.167x",  height:  651.727, zPos: 19.0, fillColorHex: "#794C35"),
        MountainData(name: "mountain_1",  textureName: "landscape6-1@4.167x",  height:  789.317, zPos: 20.0, fillColorHex: "#20201E"),
    ]

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 393, height: 852)) {
        self.containerSize = containerSize
        super.init()

        addChild(landscapeRootNode)
        landscapeRootNode.addChild(effectsGroupNode)
        landscapeRootNode.addChild(tapRippleGroupNode)
        effectsGroupNode.zPosition = 30.0
        tapRippleGroupNode.zPosition = 35.0

        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(landscapeRootNode)
        landscapeRootNode.addChild(effectsGroupNode)
        landscapeRootNode.addChild(tapRippleGroupNode)
        effectsGroupNode.zPosition = 30.0
        tapRippleGroupNode.zPosition = 35.0
    }

    // MARK: - Configuration

    public func configure(containerSize: CGSize) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        if abs(self.containerSize.width - containerSize.width) > 1 || abs(self.containerSize.height - containerSize.height) > 1 {
            self.containerSize = containerSize
            build()
        }
    }

    // MARK: - Build Scene

    public func build() {
        landscapeRootNode.removeAllActions()
        effectsGroupNode.removeAllChildren()
        effectsGroupNode.removeAllActions()
        tapRippleGroupNode.removeAllChildren()
        tapRippleGroupNode.removeAllActions()
        restPositions.removeAll()

        bgNode?.removeFromParent()
        sunNode?.removeFromParent()
        sunGlowNode?.removeFromParent()
        mountainNodes.forEach { $0.removeFromParent() }

        bgNode = nil
        sunNode = nil
        sunGlowNode = nil
        mountainNodes.removeAll()

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tính tỉ lệ aspect-fill toàn màn hình
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        landscapeRootNode.setScale(activeScale)
        // Neo tâm ở giữa màn hình
        landscapeRootNode.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape6Scene.sks
        if let scene = loadSceneTemplate() {
            buildArtwork(scene: scene)
            setupSunGlow()
            startAmbientAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildArtwork(scene: nil)
        setupSunGlow()
        startAmbientAnimations()
    }

    // MARK: - Load Scene Template

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Landscape6Scene") {
            return scene
        }
        if let scene = SKScene(fileNamed: "Landscape6Scene.sks") {
            return scene
        }
        return nil
    }

    // MARK: - Build Artwork

    private func buildArtwork(scene: SKScene?) {
        let bottomY: CGFloat = -baseDesignHeight / 2.0
        let warmSkyColor = UIColor(red: 249.0 / 255.0, green: 223.0 / 255.0, blue: 173.0 / 255.0, alpha: 1.0)

        // 1. Background bầu trời (z = 0.0) - Dùng màu thuần túy, 0 MB VRAM!
        if let scene = scene, let skBg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            skBg.removeFromParent()
            skBg.texture = nil
            skBg.color = warmSkyColor
            skBg.size = CGSize(width: baseDesignWidth, height: 2400.0)
            skBg.zPosition = 0.0
            landscapeRootNode.addChild(skBg)
            self.bgNode = skBg
            restPositions["bgNode"] = skBg.position
        } else {
            let bg = SKSpriteNode(color: warmSkyColor, size: CGSize(width: baseDesignWidth, height: 2400.0))
            bg.name = "bgNode"
            bg.position = .zero
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.zPosition = 0.0
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
            restPositions["bgNode"] = bg.position
        }

        // 2. Mặt trời hoàng hôn (z = 5.0)
        let sunPos = CGPoint(x: 0.0, y: 616.4385)
        let sunDiameter: CGFloat = 710.356

        if let scene = scene, let skSun = scene.childNode(withName: "sunNode") as? SKSpriteNode {
            skSun.removeFromParent()
            if skSun.texture == nil {
                skSun.texture = loadTexture(name: "landscape6-sun-2@4.167x")
            }
            skSun.zPosition = 5.0
            landscapeRootNode.addChild(skSun)
            self.sunNode = skSun
            restPositions["sunNode"] = skSun.position
        } else {
            let sun = SKSpriteNode(texture: loadTexture(name: "landscape6-sun-2@4.167x"), size: CGSize(width: sunDiameter, height: sunDiameter))
            sun.name = "sunNode"
            sun.position = sunPos
            sun.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            sun.zPosition = 5.0
            landscapeRootNode.addChild(sun)
            self.sunNode = sun
            restPositions["sunNode"] = sun.position
        }

        // 3. 11 Tầng núi (z = 10.0 -> 20.0)
        for cfg in Self.mountainConfigs {
            if let scene = scene, let skM = scene.childNode(withName: cfg.name) as? SKSpriteNode {
                skM.removeFromParent()
                if skM.texture == nil {
                    skM.texture = loadTexture(name: cfg.textureName)
                }
                skM.zPosition = cfg.zPos
                landscapeRootNode.addChild(skM)
                self.mountainNodes.append(skM)
                restPositions[cfg.name] = skM.position
            } else {
                let m = SKSpriteNode(texture: loadTexture(name: cfg.textureName), size: CGSize(width: baseDesignWidth, height: cfg.height))
                m.name = cfg.name
                m.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                m.position = CGPoint(x: 0.0, y: bottomY)
                m.zPosition = cfg.zPos
                landscapeRootNode.addChild(m)
                self.mountainNodes.append(m)
                restPositions[cfg.name] = m.position
            }
        }
    }

    // MARK: - Setup Sun Glow (Hào quang hoàng hôn siêu nhẹ)

    private func setupSunGlow() {
        guard let sun = sunNode else { return }

        // Nhóm hào quang phân tầng không dùng shader blur để tối ưu GPU
        let glowGroup = SKNode()
        glowGroup.name = "sunGlowNode"
        glowGroup.position = sun.position
        glowGroup.zPosition = 4.0

        let baseR = 710.356 / 2.0

        // Lớp hào quang trong
        let innerAura = SKShapeNode(circleOfRadius: baseR + 25.0)
        innerAura.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.72, alpha: 0.20)
        innerAura.strokeColor = .clear
        glowGroup.addChild(innerAura)

        // Lớp hào quang ngoài
        let outerAura = SKShapeNode(circleOfRadius: baseR + 55.0)
        outerAura.fillColor = UIColor(red: 1.0, green: 0.90, blue: 0.68, alpha: 0.10)
        outerAura.strokeColor = .clear
        glowGroup.addChild(outerAura)

        landscapeRootNode.addChild(glowGroup)
        self.sunGlowNode = glowGroup
        restPositions["sunGlowNode"] = glowGroup.position
    }

    // MARK: - Ambient Animations

    private func startAmbientAnimations() {
        // --- 1. Nhịp thở quang năng hoàng hôn (Sun Subtle Optical Breathing) ---
        if let sun = sunNode {
            let scaleUp = SKAction.scale(to: 1.025, duration: 4.2)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SKAction.scale(to: 1.0, duration: 4.2)
            scaleDown.timingMode = .easeInEaseOut
            let sunSequence = SKAction.sequence([scaleUp, scaleDown])
            sun.run(SKAction.repeatForever(sunSequence), withKey: "sun_opticalPulse")
        }

        if let glow = sunGlowNode {
            let glowFadeUp = SKAction.fadeAlpha(to: 0.95, duration: 3.8)
            glowFadeUp.timingMode = .easeInEaseOut
            let glowFadeDown = SKAction.fadeAlpha(to: 0.65, duration: 3.8)
            glowFadeDown.timingMode = .easeInEaseOut
            let glowSequence = SKAction.sequence([glowFadeUp, glowFadeDown])
            glow.run(SKAction.repeatForever(glowSequence), withKey: "glow_pulse")
        }

        // --- 2. Bụi nắng hoàng hôn lơ lửng (Ambient Golden Dust Motes) ---
        let spawnMote = SKAction.run { [weak self] in
            self?.spawnGoldenMote()
        }
        let wait = SKAction.wait(forDuration: 0.75, withRange: 0.35)
        let moteLoop = SKAction.repeatForever(SKAction.sequence([spawnMote, wait]))
        effectsGroupNode.run(moteLoop, withKey: "golden_dust_loop")
    }

    /// Sinh 1 hạt bụi vàng óng ánh trôi từ các thung lũng núi lên bầu trời
    private func spawnGoldenMote() {
        guard effectsGroupNode.parent != nil else { return }
        // Giới hạn tối đa 12 hạt để không làm tăng bộ nhớ
        guard effectsGroupNode.children.count < 12 else { return }

        let radius = CGFloat.random(in: 1.5...3.0)
        let mote = SKShapeNode(circleOfRadius: radius)

        let colors = [
            UIColor(red: 1.0, green: 0.92, blue: 0.70, alpha: 0.85),
            UIColor(red: 1.0, green: 0.85, blue: 0.60, alpha: 0.90),
            UIColor(red: 0.98, green: 0.80, blue: 0.55, alpha: 0.80)
        ]
        mote.fillColor = colors.randomElement() ?? colors[0]
        mote.strokeColor = .clear

        let startX = CGFloat.random(in: -650...650)
        let startY = CGFloat.random(in: -550...150)
        mote.position = CGPoint(x: startX, y: startY)
        mote.alpha = 0.0

        effectsGroupNode.addChild(mote)

        let duration = Double.random(in: 5.0...8.0)
        let riseY = CGFloat.random(in: 120...240)
        let driftX = CGFloat.random(in: -40...40)

        let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.65...0.90), duration: duration * 0.25)
        let moveUp = SKAction.moveBy(x: driftX, y: riseY, duration: duration)
        moveUp.timingMode = .easeOut

        let flickerOut = SKAction.fadeAlpha(to: 0.35, duration: duration * 0.2)
        let flickerIn = SKAction.fadeAlpha(to: 0.80, duration: duration * 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.35)

        let flickerSeq = SKAction.sequence([fadeIn, flickerOut, flickerIn, fadeOut, SKAction.removeFromParent()])
        mote.run(SKAction.group([moveUp, flickerSeq]))
    }

    // MARK: - Interactive Tap Animation (playTapAnimation)

    public func playTapAnimation(at location: CGPoint) {
        let rootLocation = landscapeRootNode.convert(location, from: self)

        // --- 1. Vòng sóng hào quang hoàng hôn (Sunset Shimmer Ring) ---
        let startRadius: CGFloat = 8.0
        let endRadius: CGFloat = CGFloat.random(in: 60...80)
        let ringDuration: Double = 0.65

        let ring = SKShapeNode(circleOfRadius: startRadius)
        ring.position = rootLocation
        ring.strokeColor = UIColor(red: 1.0, green: 0.92, blue: 0.68, alpha: 0.85)
        ring.fillColor = UIColor(red: 1.0, green: 0.90, blue: 0.65, alpha: 0.12)
        ring.lineWidth = 2.0
        tapRippleGroupNode.addChild(ring)

        let expand = SKAction.scale(to: endRadius / startRadius, duration: ringDuration)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: ringDuration)
        fade.timingMode = .easeIn

        ring.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))

        // --- 2. Chùm hạt sao vàng toé ra từ điểm chạm ---
        for _ in 0..<6 {
            let burstParticle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.8...3.0))
            burstParticle.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 0.95)
            burstParticle.strokeColor = .clear
            burstParticle.position = rootLocation
            tapRippleGroupNode.addChild(burstParticle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 25...55)
            let burstMove = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist + 12.0, duration: 0.50)
            burstMove.timingMode = .easeOut
            let burstFade = SKAction.fadeOut(withDuration: 0.50)

            burstParticle.run(SKAction.sequence([SKAction.group([burstMove, burstFade]), SKAction.removeFromParent()]))
        }

        // --- 3. Cộng hưởng Thái Dương (Sun Flare Resonance) ---
        if let sun = sunNode {
            sun.removeAction(forKey: "sun_tapFlare")
            let flareUp = SKAction.scale(to: 1.05, duration: 0.20)
            flareUp.timingMode = .easeOut
            let flareDown = SKAction.scale(to: 1.0, duration: 0.40)
            flareDown.timingMode = .easeInEaseOut

            let flareSequence = SKAction.sequence([
                flareUp,
                flareDown,
                SKAction.run { [weak self] in
                    self?.sunNode?.setScale(1.0)
                }
            ])
            sun.run(flareSequence, withKey: "sun_tapFlare")
        }

        if let glow = sunGlowNode {
            glow.removeAction(forKey: "glow_tapFlare")
            let glowBright = SKAction.fadeAlpha(to: 1.0, duration: 0.20)
            let glowDim = SKAction.fadeAlpha(to: 0.65, duration: 0.45)
            glow.run(SKAction.sequence([glowBright, glowDim]), withKey: "glow_tapFlare")
        }
    }

    // MARK: - Helper Texture Loading với Cache

    private func loadTexture(name: String) -> SKTexture? {
        if let cached = Self.sharedTextureCache[name] {
            return cached
        }

        let cleanName = name.replacingOccurrences(of: "@4.167x", with: "")
        let texture: SKTexture?

        if let img = UIImage(named: name) {
            texture = SKTexture(image: img)
        } else if let img = UIImage(named: cleanName) {
            texture = SKTexture(image: img)
        } else {
            texture = nil
        }

        if let tex = texture {
            tex.filteringMode = .linear
            Self.sharedTextureCache[name] = tex
        }
        return texture
    }
}

//
//  Landscape1Node.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 1: "Ban công quang đãng" (landscape1 / sky_sun_day)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape1Scene.sks`
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thành phần:
///   1. `bgNode`: Nền trời xanh trong trẻo (`bg1-1@4.167x`)
///   2. `sunGroup`: Mặt trời trung tâm (`sunbg1-2@4.167x`) & 4 lớp hào quang (`sunbg1-3`..`sunbg1-6`)
///      - Hoạt ảnh hào quang xoay đa tầng ngược chiều nhau (Multi-layer counter-rotation)
///      - Nhịp thở ánh sáng mờ tỏ (Breathing Glow)
///   3. `cloudsGroup`: 8 cụm mây trắng (`Cloudbg1-1`..`Cloudbg1-8`) bồng bềnh trôi Parallax
public final class Landscape1Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private let landscapeRootNode = SKNode()

    // Layer Nodes
    private var bgNode: SKSpriteNode?
    private var sunGroupNode: SKNode?
    private var cloudsGroupNode: SKNode?

    // Sun Components
    private var sunCore: SKSpriteNode?
    private var sunAuras: [SKSpriteNode] = []

    // Clouds Components
    private var cloudSprites: [SKSpriteNode] = []
    private var cloudSpeeds: [CGFloat] = []

    // Tỉ lệ scale so với canvas thiết kế chuẩn (750 x 1334)
    private let baseDesignWidth: CGFloat = 750.0
    private let baseDesignHeight: CGFloat = 1334.0
    private var activeScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 393, height: 852)) {
        self.containerSize = containerSize
        super.init()

        addChild(landscapeRootNode)
        build()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addChild(landscapeRootNode)
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
        landscapeRootNode.removeAllChildren()
        landscapeRootNode.removeAllActions()
        bgNode = nil
        sunGroupNode = nil
        cloudsGroupNode = nil
        sunCore = nil
        sunAuras.removeAll()
        cloudSprites.removeAll()
        cloudSpeeds.removeAll()

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tính scale để fit dọc theo chiều cao màn hình (Aspect Fill)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape1Scene.sks
        if let scene = loadSceneTemplate() {
            buildFromSceneTemplate(scene: scene)
            startAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildProceduralFallback()
        startAnimations()
    }

    // MARK: - Build from Scene Template

    private func buildFromSceneTemplate(scene: SKScene) {
        // 1. Nạp bgNode
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
            let fillSize = max(containerSize.width, containerSize.height) * 1.3
            bg.size = CGSize(width: fillSize, height: fillSize)
            bg.zPosition = 0
            if bg.texture == nil {
                bg.texture = loadTexture(name: "bg1-1@4.167x")
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // 2. Nạp sunGroup
        if let sunGroup = scene.childNode(withName: "sunGroup") {
            sunGroup.removeFromParent()
            // Đặt mặt trời ở góc trên bên phải của màn hình hiện tại
            let sunX = containerSize.width * 0.72
            let sunY = containerSize.height * 0.78
            sunGroup.position = CGPoint(x: sunX, y: sunY)
            sunGroup.setScale(activeScale)
            sunGroup.zPosition = 10
            landscapeRootNode.addChild(sunGroup)
            self.sunGroupNode = sunGroup

            if let core = sunGroup.childNode(withName: "sunCore") as? SKSpriteNode {
                self.sunCore = core
            }

            for auraName in ["sunAura1", "sunAura2", "sunAura3", "sunAura4"] {
                if let aura = sunGroup.childNode(withName: auraName) as? SKSpriteNode {
                    self.sunAuras.append(aura)
                }
            }
        }

        // 3. Nạp cloudsGroup
        if let cloudsGroup = scene.childNode(withName: "cloudsGroup") {
            cloudsGroup.removeFromParent()
            cloudsGroup.position = .zero
            cloudsGroup.zPosition = 20
            landscapeRootNode.addChild(cloudsGroup)
            self.cloudsGroupNode = cloudsGroup

            for i in 1...8 {
                if let cloud = cloudsGroup.childNode(withName: "cloud_\(i)") as? SKSpriteNode {
                    // Chuẩn hoá toạ độ mây theo tỉ lệ container thực tế
                    let normX = (cloud.position.x / (baseDesignWidth / 2.0)) * (containerSize.width / 2.0) + (containerSize.width / 2.0)
                    let normY = (cloud.position.y / (baseDesignHeight / 2.0)) * (containerSize.height / 2.0) + (containerSize.height / 2.0)
                    cloud.position = CGPoint(x: normX, y: normY)
                    cloud.size = CGSize(width: cloud.size.width * activeScale, height: cloud.size.height * activeScale)
                    cloudSprites.append(cloud)

                    // Vận tốc mây trôi parallax (từ 10 đến 26 pt/giây)
                    let baseSpeed: CGFloat = CGFloat(8 + (i * 3) % 18)
                    cloudSpeeds.append(baseSpeed)
                }
            }
        }
    }

    // MARK: - Procedural Fallback

    private func buildProceduralFallback() {
        // 1. Nền
        let bgTex = loadTexture(name: "bg1-1@4.167x")
        let fillSize = max(containerSize.width, containerSize.height) * 1.3
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillSize, height: fillSize))
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // 2. Nhóm Mặt trời
        let sunGroup = SKNode()
        let sunX = containerSize.width * 0.72
        let sunY = containerSize.height * 0.78
        sunGroup.position = CGPoint(x: sunX, y: sunY)
        sunGroup.setScale(activeScale)
        sunGroup.zPosition = 10
        landscapeRootNode.addChild(sunGroup)
        self.sunGroupNode = sunGroup

        // Các lớp hào quang
        let auraConfigs: [(name: String, tex: String, size: CGSize, alpha: CGFloat, z: CGFloat)] = [
            ("sunAura4", "sunbg1-6@4.167x", CGSize(width: 680, height: 530), 0.55, 11),
            ("sunAura3", "sunbg1-5@4.167x", CGSize(width: 500, height: 440), 0.70, 12),
            ("sunAura2", "sunbg1-4@4.167x", CGSize(width: 340, height: 340), 0.82, 13),
            ("sunAura1", "sunbg1-3@4.167x", CGSize(width: 200, height: 200), 0.90, 14)
        ]

        for config in auraConfigs {
            if let tex = loadTexture(name: config.tex) {
                let aura = SKSpriteNode(texture: tex, size: config.size)
                aura.name = config.name
                aura.alpha = config.alpha
                aura.zPosition = config.z
                sunGroup.addChild(aura)
                sunAuras.append(aura)
            }
        }

        // Mặt trời chính
        if let coreTex = loadTexture(name: "sunbg1-2@4.167x") {
            let core = SKSpriteNode(texture: coreTex, size: CGSize(width: 120, height: 120))
            core.name = "sunCore"
            core.zPosition = 15
            sunGroup.addChild(core)
            self.sunCore = core
        }

        // 3. Nhóm Mây
        let cloudsGroup = SKNode()
        cloudsGroup.zPosition = 20
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        let cloudConfigs: [(tex: String, pos: CGPoint, size: CGSize, alpha: CGFloat, speed: CGFloat)] = [
            ("Cloudbg1-1@4.167x", CGPoint(x: containerSize.width * 0.25, y: containerSize.height * 0.85), CGSize(width: 320, height: 185), 0.85, 12.0),
            ("Cloudbg1-2@4.167x", CGPoint(x: containerSize.width * 0.75, y: containerSize.height * 0.68), CGSize(width: 280, height: 160), 0.90, 16.0),
            ("Cloudbg1-3@4.167x", CGPoint(x: containerSize.width * 0.35, y: containerSize.height * 0.58), CGSize(width: 340, height: 140), 0.75, 10.0),
            ("Cloudbg1-4@4.167x", CGPoint(x: containerSize.width * 0.70, y: containerSize.height * 0.80), CGSize(width: 310, height: 190), 0.80, 18.0),
            ("Cloudbg1-5@4.167x", CGPoint(x: containerSize.width * 0.20, y: containerSize.height * 0.72), CGSize(width: 180, height: 130), 0.70, 22.0),
            ("Cloudbg1-6@4.167x", CGPoint(x: containerSize.width * 0.55, y: containerSize.height * 0.90), CGSize(width: 150, height: 135), 0.65, 25.0),
            ("Cloudbg1-7@4.167x", CGPoint(x: containerSize.width * 0.40, y: containerSize.height * 0.48), CGSize(width: 360, height: 160), 0.85, 14.0),
            ("Cloudbg1-8@4.167x", CGPoint(x: containerSize.width * 0.80, y: containerSize.height * 0.52), CGSize(width: 220, height: 150), 0.80, 20.0)
        ]

        for (index, cfg) in cloudConfigs.enumerated() {
            if let tex = loadTexture(name: cfg.tex) {
                let cloud = SKSpriteNode(texture: tex, size: CGSize(width: cfg.size.width * activeScale, height: cfg.size.height * activeScale))
                cloud.name = "cloud_\(index + 1)"
                cloud.position = cfg.pos
                cloud.alpha = cfg.alpha
                cloud.zPosition = CGFloat(20 + index)
                cloudsGroup.addChild(cloud)
                cloudSprites.append(cloud)
                cloudSpeeds.append(cfg.speed)
            }
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Landscape1Scene")
    }

    // MARK: - Texture Loader Helper

    private func loadTexture(name: String) -> SKTexture? {
        if let img = UIImage(named: name) {
            return SKTexture(image: img)
        }
        let cleanName = name.replacingOccurrences(of: "@4.167x", with: "")
        if let img = UIImage(named: cleanName) {
            return SKTexture(image: img)
        }
        return nil
    }

    // MARK: - Animations (Diễn hoạt Mặt Trời & Mây Trôi)

    private func startAnimations() {
        // 1. Hoạt ảnh Mặt trời chính (Thở nhẹ)
        if let core = sunCore {
            core.removeAllActions()
            let pulseUp = SKAction.scale(to: 1.05, duration: 2.8)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.scale(to: 1.0, duration: 2.8)
            pulseDown.timingMode = .easeInEaseOut
            core.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))
        }

        // 2. Hoạt ảnh Hào quang mặt trời (Xoay ngược chiều nhau & thở mờ tỏ)
        let auraRotations: [(duration: Double, clockwise: Bool, minA: CGFloat, maxA: CGFloat)] = [
            (90.0, true, 0.75, 0.95),   // sunAura1
            (120.0, false, 0.65, 0.85), // sunAura2
            (150.0, true, 0.50, 0.72),  // sunAura3
            (180.0, false, 0.35, 0.55)  // sunAura4
        ]

        for (index, aura) in sunAuras.enumerated() {
            aura.removeAllActions()
            let config = auraRotations[min(index, auraRotations.count - 1)]

            // Xoay liên tục
            let angle = config.clockwise ? -CGFloat.pi * 2 : CGFloat.pi * 2
            let rotate = SKAction.rotate(byAngle: angle, duration: config.duration)
            aura.run(SKAction.repeatForever(rotate))

            // Thở mờ tỏ
            let fadeOut = SKAction.fadeAlpha(to: config.minA, duration: 3.5 + Double(index) * 0.5)
            fadeOut.timingMode = .easeInEaseOut
            let fadeIn = SKAction.fadeAlpha(to: config.maxA, duration: 3.5 + Double(index) * 0.5)
            fadeIn.timingMode = .easeInEaseOut
            aura.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        }

        // 3. Hoạt ảnh Mây trôi Parallax (Drifting & Wrap-around)
        for (index, cloud) in cloudSprites.enumerated() {
            cloud.removeAllActions()
            let speed = cloudSpeeds[min(index, cloudSpeeds.count - 1)]
            animateDriftingCloud(cloud, speed: speed)
        }
    }

    private func animateDriftingCloud(_ cloud: SKSpriteNode, speed: CGFloat) {
        let screenW = containerSize.width
        let cloudW = cloud.size.width
        let targetX = screenW + cloudW * 0.6
        let distance = targetX - cloud.position.x
        let duration = max(4.0, Double(distance / speed))

        let moveRight = SKAction.moveTo(x: targetX, duration: duration)
        let resetLeft = SKAction.run { [weak cloud, weak self] in
            guard let cloud = cloud, let self = self else { return }
            cloud.position.x = -cloudW * 0.6
            // Nhẹ nhàng đổi độ cao Y ngẫu nhiên tự nhiên
            let deltaY = CGFloat.random(in: -25.0...25.0)
            cloud.position.y = max(self.containerSize.height * 0.35, min(self.containerSize.height * 0.92, cloud.position.y + deltaY))
            self.animateDriftingCloud(cloud, speed: speed)
        }

        cloud.run(SKAction.sequence([moveRight, resetLeft]))
    }

    // MARK: - Tap Interaction Animation

    public func playTapAnimation(at location: CGPoint) {
        // Kiểm tra xem vị trí chạm có gần mặt trời không
        if let sun = sunGroupNode {
            let dist = hypot(location.x - sun.position.x, location.y - sun.position.y)
            if dist < 180.0 * activeScale {
                playSunBurstAnimation()
                return
            }
        }

        // Nếu chạm vào mây: đám mây gần nhất nhấp nhô bồng bềnh
        var closestCloud: SKSpriteNode?
        var minDistance: CGFloat = 140.0
        for cloud in cloudSprites {
            let dist = hypot(location.x - cloud.position.x, location.y - cloud.position.y)
            if dist < minDistance {
                minDistance = dist
                closestCloud = cloud
            }
        }

        if let cloud = closestCloud {
            let bobUp = SKAction.moveBy(x: 0, y: 15, duration: 0.3)
            bobUp.timingMode = .easeOut
            let bobDown = SKAction.moveBy(x: 0, y: -15, duration: 0.45)
            bobDown.timingMode = .easeInEaseOut
            cloud.run(SKAction.sequence([bobUp, bobDown]))
        }

        // Sinh hiệu ứng tia nắng / hạt ánh sáng vàng ấm áp
        spawnSunlightSparkles(at: location)
    }

    private func playSunBurstAnimation() {
        guard let sun = sunGroupNode else { return }

        // Bừng sáng mặt trời
        let burstUp = SKAction.scale(to: activeScale * 1.14, duration: 0.22)
        burstUp.timingMode = .easeOut
        let burstDown = SKAction.scale(to: activeScale, duration: 0.45)
        burstDown.timingMode = .easeInEaseOut
        sun.run(SKAction.sequence([burstUp, burstDown]))

        // Tăng sáng hào quang tức thời
        for aura in sunAuras {
            let glow = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            let fade = SKAction.fadeAlpha(to: aura.alpha, duration: 0.8)
            aura.run(SKAction.sequence([glow, fade]))
        }

        // Bắn ra các tia nắng lấp lánh xung quanh
        spawnSunlightSparkles(at: sun.position, count: 16)
    }

    private func spawnSunlightSparkles(at center: CGPoint, count: Int = 8) {
        let sparkleGroup = SKNode()
        sparkleGroup.position = center
        sparkleGroup.zPosition = 35
        landscapeRootNode.addChild(sparkleGroup)

        for _ in 0..<count {
            let radius = CGFloat.random(in: 2.5...5.0)
            let particle = SKShapeNode(circleOfRadius: radius)
            particle.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 0.9)
            particle.strokeColor = .clear
            sparkleGroup.addChild(particle)

            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 25.0...75.0)
            let dest = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)

            let move = SKAction.move(to: dest, duration: Double.random(in: 0.5...0.9))
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: Double.random(in: 0.4...0.8))
            let scale = SKAction.scale(to: 0.2, duration: 0.6)
            let group = SKAction.group([move, fade, scale])

            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        sparkleGroup.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
    }
}

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
            bg.zPosition = 0.0
            bg.isPaused = false
            bg.speed = 1.0
            // Luôn nạp đè texture thật từ bundle
            if let realBgTex = loadTexture(name: "bg1-1@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // 2. Nạp sunGroup: ăn theo toạ độ người dùng đã kéo trong Landscape1Scene.sks
        if let sunGroup = scene.childNode(withName: "sunGroup") {
            sunGroup.removeFromParent()
            // Chuyển đổi toạ độ từ canvas thiết kế (750x1334, anchorPoint 0.5, 0.5) sang containerSize thực tế
            let normSunX = (sunGroup.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normSunY = (sunGroup.position.y / baseDesignHeight + 0.5) * containerSize.height
            sunGroup.position = CGPoint(x: normSunX, y: normSunY)
            sunGroup.setScale(activeScale)
            // Giữ nguyên zPosition từ scene (10.0)
            sunGroup.isPaused = false
            sunGroup.speed = 1.0
            landscapeRootNode.addChild(sunGroup)
            self.sunGroupNode = sunGroup

            if let core = sunGroup.childNode(withName: "sunCore") as? SKSpriteNode {
                if let coreTex = loadTexture(name: "sunbg1-2@4.167x") {
                    core.texture = coreTex
                }
                core.isPaused = false
                core.speed = 1.0
                // Giữ nguyên toạ độ, scale (2.0, 2.0), zPosition (15.0) từ scene
                self.sunCore = core
            }

            // Thứ tự các lớp hào quang từ sau ra trước chuẩn index scene:
            // sunAura4 (z=11), sunAura3 (z=12), sunAura2 (z=13), sunAura1 (z=14)
            let auraConfigs: [(name: String, tex: String)] = [
                ("sunAura4", "sunbg1-6@4.167x"),
                ("sunAura3", "sunbg1-5@4.167x"),
                ("sunAura2", "sunbg1-4@4.167x"),
                ("sunAura1", "sunbg1-3@4.167x")
            ]
            for item in auraConfigs {
                if let aura = sunGroup.childNode(withName: item.name) as? SKSpriteNode {
                    if let auraTex = loadTexture(name: item.tex) {
                        aura.texture = auraTex
                    }
                    aura.isPaused = false
                    aura.speed = 1.0
                    // Lưu baseAlpha để diễn hoạt nhịp thở mờ tỏ
                    aura.userData = ["baseAlpha": aura.alpha]
                    self.sunAuras.append(aura)
                }
            }
        }

        // 3. Nạp cloudsGroup: giữ nguyên index zPosition chuẩn từ scene
        if let cloudsGroup = scene.childNode(withName: "cloudsGroup") {
            cloudsGroup.removeFromParent()
            cloudsGroup.position = .zero
            // Giữ nguyên zPosition từ scene (20.0)
            cloudsGroup.isPaused = false
            cloudsGroup.speed = 1.0
            landscapeRootNode.addChild(cloudsGroup)
            self.cloudsGroupNode = cloudsGroup

            for i in 1...8 {
                if let cloud = cloudsGroup.childNode(withName: "cloud_\(i)") as? SKSpriteNode {
                    // Luôn luôn nạp đè texture thật để tránh lỗi unarchived resource
                    if let cloudTex = loadTexture(name: "Cloudbg1-\(i)@4.167x") {
                        cloud.texture = cloudTex
                    }
                    cloud.isHidden = false
                    cloud.isPaused = false
                    cloud.speed = 1.0

                    // Chuẩn hoá toạ độ mây theo tỉ lệ container thực tế
                    let normX = (cloud.position.x / baseDesignWidth + 0.5) * containerSize.width
                    let normY = (cloud.position.y / baseDesignHeight + 0.5) * containerSize.height
                    cloud.position = CGPoint(x: normX, y: normY)
                    cloud.size = CGSize(width: cloud.size.width * activeScale, height: cloud.size.height * activeScale)
                    // Giữ nguyên zPosition từ scene (cloud_6: 18, cloud_5: 19, cloud_3: 20, cloud_1,8: 21, cloud_2: 22, cloud_4: 23, cloud_7: 24)
                    cloudSprites.append(cloud)

                    // Vận tốc mây trôi rõ nét, sinh động (từ 28 đến 55 pt/giây)
                    let baseSpeed: CGFloat = CGFloat(28 + (i * 7) % 28)
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
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // 2. Nhóm Mặt trời (pos chuẩn từ scene: (140, 380))
        let sunGroup = SKNode()
        let normSunX = (140.0 / baseDesignWidth + 0.5) * containerSize.width
        let normSunY = (380.0 / baseDesignHeight + 0.5) * containerSize.height
        sunGroup.position = CGPoint(x: normSunX, y: normSunY)
        sunGroup.setScale(activeScale)
        sunGroup.zPosition = 10.0
        landscapeRootNode.addChild(sunGroup)
        self.sunGroupNode = sunGroup

        // Các lớp hào quang (Toạ độ và zPosition chuẩn xác từ Landscape1Scene.sks)
        let auraConfigs: [(name: String, tex: String, pos: CGPoint, size: CGSize, alpha: CGFloat, z: CGFloat)] = [
            ("sunAura4", "sunbg1-6@4.167x", CGPoint(x: 31.5727, y: 22.0004), CGSize(width: 680, height: 530), 0.55, 11.0),
            ("sunAura3", "sunbg1-5@4.167x", CGPoint(x: 10.0001, y: 67.0005), CGSize(width: 500, height: 440), 0.70, 12.0),
            ("sunAura2", "sunbg1-4@4.167x", CGPoint(x: -4.9997, y: 99.9996), CGSize(width: 340, height: 340), 0.82, 13.0),
            ("sunAura1", "sunbg1-3@4.167x", CGPoint(x: -18.8816, y: 151.7301), CGSize(width: 200, height: 200), 0.90, 14.0)
        ]

        for config in auraConfigs {
            if let tex = loadTexture(name: config.tex) {
                let aura = SKSpriteNode(texture: tex, size: config.size)
                aura.name = config.name
                aura.position = config.pos
                aura.alpha = config.alpha
                aura.zPosition = config.z
                aura.userData = ["baseAlpha": config.alpha]
                sunGroup.addChild(aura)
                sunAuras.append(aura)
            }
        }

        // Mặt trời chính (pos: (-14.4003, 136.9997), scale: 2.0, z: 15.0)
        if let coreTex = loadTexture(name: "sunbg1-2@4.167x") {
            let core = SKSpriteNode(texture: coreTex, size: CGSize(width: 120, height: 120))
            core.name = "sunCore"
            core.position = CGPoint(x: -14.4003, y: 136.9997)
            core.xScale = 2.0
            core.yScale = 2.0
            core.zPosition = 15.0
            sunGroup.addChild(core)
            self.sunCore = core
        }

        // 3. Nhóm Mây
        let cloudsGroup = SKNode()
        cloudsGroup.position = .zero
        cloudsGroup.zPosition = 20.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        // Danh sách mây với toạ độ và zPosition chuẩn xác từ Landscape1Scene.sks
        let cloudConfigs: [(tex: String, pos: CGPoint, size: CGSize, alpha: CGFloat, speed: CGFloat, z: CGFloat)] = [
            ("Cloudbg1-1@4.167x", CGPoint(x: (-180.0 / baseDesignWidth + 0.5) * containerSize.width, y: (480.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 320, height: 185), 0.85, 26.0, 21.0),
            ("Cloudbg1-2@4.167x", CGPoint(x: (190.0 / baseDesignWidth + 0.5) * containerSize.width,  y: (240.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 280, height: 160), 0.90, 32.0, 22.0),
            ("Cloudbg1-3@4.167x", CGPoint(x: (-120.0 / baseDesignWidth + 0.5) * containerSize.width, y: (120.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 340, height: 140), 0.75, 24.0, 20.0),
            ("Cloudbg1-4@4.167x", CGPoint(x: (160.0 / baseDesignWidth + 0.5) * containerSize.width,  y: (420.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 310, height: 190), 0.80, 36.0, 23.0),
            ("Cloudbg1-5@4.167x", CGPoint(x: (-230.0 / baseDesignWidth + 0.5) * containerSize.width, y: (290.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 180, height: 130), 0.70, 42.0, 19.0),
            ("Cloudbg1-6@4.167x", CGPoint(x: (40.0 / baseDesignWidth + 0.5) * containerSize.width,   y: (520.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 150, height: 135), 0.65, 46.0, 18.0),
            ("Cloudbg1-7@4.167x", CGPoint(x: (-60.0 / baseDesignWidth + 0.5) * containerSize.width,  y: (-20.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 360, height: 160), 0.85, 28.0, 24.0),
            ("Cloudbg1-8@4.167x", CGPoint(x: (210.0 / baseDesignWidth + 0.5) * containerSize.width,  y: (50.0 / baseDesignHeight + 0.5) * containerSize.height),  CGSize(width: 220, height: 150), 0.80, 38.0, 21.0)
        ]

        for (index, cfg) in cloudConfigs.enumerated() {
            if let tex = loadTexture(name: cfg.tex) {
                let cloud = SKSpriteNode(texture: tex, size: CGSize(width: cfg.size.width * activeScale, height: cfg.size.height * activeScale))
                cloud.name = "cloud_\(index + 1)"
                cloud.position = cfg.pos
                cloud.alpha = cfg.alpha
                cloud.zPosition = cfg.z
                cloud.isPaused = false
                cloud.speed = 1.0
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
        // Đảm bảo toàn bộ hệ thống node không bị paused
        isPaused = false
        speed = 1.0
        landscapeRootNode.isPaused = false
        landscapeRootNode.speed = 1.0
        cloudsGroupNode?.isPaused = false
        cloudsGroupNode?.speed = 1.0
        sunGroupNode?.isPaused = false
        sunGroupNode?.speed = 1.0

        // 1. Hoạt ảnh Mặt trời chính (Thở nhẹ - giữ nguyên scale cơ sở từ scene)
        if let core = sunCore {
            startSunCoreBreathing(core: core)
        }

        // 2. Hoạt ảnh Hào quang mặt trời (Breathing Glow đa tầng mờ tỏ, giữ tuyệt đối toạ độ không bị lệch)
        for (index, aura) in sunAuras.enumerated() {
            startAuraBreathing(aura: aura, index: index)
        }

        // 3. Hoạt ảnh Mây trôi Parallax (Di chuyển liên tục không ngắt quãng bằng repeatForever)
        for (index, cloud) in cloudSprites.enumerated() {
            cloud.removeAction(forKey: "cloudDrift")
            cloud.isPaused = false
            cloud.speed = 1.0
            let speed = cloudSpeeds[min(index, cloudSpeeds.count - 1)]
            animateDriftingCloud(cloud, speed: speed)
        }
    }

    private func startSunCoreBreathing(core: SKSpriteNode) {
        core.removeAction(forKey: "sunCoreBreathing")
        // Giữ tỉ lệ scale gốc từ scene (ví dụ scale = 2.0)
        let baseScaleX = core.xScale
        let baseScaleY = core.yScale
        let pulseUp = SKAction.scaleX(to: baseScaleX * 1.06, y: baseScaleY * 1.06, duration: 2.8)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scaleX(to: baseScaleX, y: baseScaleY, duration: 2.8)
        pulseDown.timingMode = .easeInEaseOut
        core.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "sunCoreBreathing")
    }

    private func startAuraBreathing(aura: SKSpriteNode, index: Int? = nil) {
        aura.removeAction(forKey: "auraBreathing")
        let baseAlpha = aura.userData?["baseAlpha"] as? CGFloat ?? aura.alpha
        let idx = index ?? sunAuras.firstIndex(of: aura) ?? 0
        let period = 3.2 + Double(idx) * 0.6

        let minA = baseAlpha * 0.82
        let maxA = min(1.0, baseAlpha * 1.15)
        let fadeOut = SKAction.fadeAlpha(to: minA, duration: period)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: maxA, duration: period)
        fadeIn.timingMode = .easeInEaseOut
        aura.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])), withKey: "auraBreathing")
    }

    private func animateDriftingCloud(_ cloud: SKSpriteNode, speed: CGFloat) {
        let screenW = containerSize.width
        let cloudW = max(cloud.size.width, 100.0)
        let targetX = screenW + cloudW * 0.7
        let resetX = -cloudW * 0.7
        let currentX = cloud.position.x
        let safeSpeed = max(15.0, speed)

        // 1. Quãng đường ban đầu từ vị trí hiện tại đến mép phải
        let distanceInitial = max(5.0, targetX - currentX)
        let durationInitial = Double(distanceInitial / safeSpeed)
        let initialMove = SKAction.moveTo(x: targetX, duration: durationInitial)

        // 2. Chu kỳ trôi toàn phần lặp vô tận từ resetX sang targetX
        let fullDistance = targetX - resetX
        let fullDuration = Double(fullDistance / safeSpeed)
        let resetPos = SKAction.run { [weak cloud, weak self] in
            guard let cloud = cloud, let self = self else { return }
            cloud.position.x = resetX
            // Đổi nhẹ độ cao Y ngẫu nhiên tự nhiên
            let deltaY = CGFloat.random(in: -15.0...15.0)
            cloud.position.y = max(self.containerSize.height * 0.35, min(self.containerSize.height * 0.92, cloud.position.y + deltaY))
        }
        let fullMove = SKAction.moveTo(x: targetX, duration: fullDuration)
        let fullCycle = SKAction.repeatForever(SKAction.sequence([resetPos, fullMove]))

        // Ghép bước đầu và vòng lặp vô tận
        cloud.run(SKAction.sequence([initialMove, fullCycle]), withKey: "cloudDrift")
    }

    // MARK: - Tap Interaction Animation

    public func playTapAnimation(at location: CGPoint) {
        // 1. Kiểm tra vị trí chạm có trúng mặt trời không (tính theo tâm thực tế của sunCore)
        if let _ = sunGroupNode {
            let sunCenter = getActualSunCenter()
            let dist = hypot(location.x - sunCenter.x, location.y - sunCenter.y)
            let hitRadius = 150.0 * activeScale
            if dist < hitRadius {
                playSunBurstAnimation(at: sunCenter)
                return
            }
        }

        // 2. Nếu chạm vào mây: đám mây gần nhất nhấp nhô bồng bềnh
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
            let bobUp = SKAction.moveBy(x: 0, y: 15, duration: 0.25)
            bobUp.timingMode = .easeOut
            let bobDown = SKAction.moveBy(x: 0, y: -15, duration: 0.35)
            bobDown.timingMode = .easeInEaseOut
            cloud.run(SKAction.sequence([bobUp, bobDown]))
        }

        // 3. Sinh hiệu ứng tia nắng / hạt ánh sáng vàng ấm áp tại điểm chạm
        spawnSunlightSparkles(at: location, count: 8)
    }

    private func getActualSunCenter() -> CGPoint {
        guard let sunGroup = sunGroupNode else { return .zero }
        if let core = sunCore {
            return landscapeRootNode.convert(core.position, from: sunGroup)
        }
        return sunGroup.position
    }

    private func playSunBurstAnimation(at center: CGPoint) {
        // Bừng sáng mặt trời chính: nhún nảy đàn hồi trên chính sunCore (không làm trôi toạ độ sunGroup)
        if let core = sunCore {
            core.removeAction(forKey: "sunCoreBreathing")
            let baseScaleX = core.xScale
            let baseScaleY = core.yScale
            let burstUp = SKAction.scaleX(to: baseScaleX * 1.20, y: baseScaleY * 1.20, duration: 0.18)
            burstUp.timingMode = .easeOut
            let burstDown = SKAction.scaleX(to: baseScaleX, y: baseScaleY, duration: 0.32)
            burstDown.timingMode = .easeInEaseOut
            core.run(SKAction.sequence([burstUp, burstDown])) { [weak self, weak core] in
                guard let self = self, let core = core else { return }
                self.startSunCoreBreathing(core: core)
            }
        }

        // Tăng sáng hào quang tức thời rồi khôi phục nhịp thở mượt mà
        for aura in sunAuras {
            aura.removeAction(forKey: "auraBreathing")
            let baseAlpha = aura.userData?["baseAlpha"] as? CGFloat ?? aura.alpha
            let flashGlow = SKAction.fadeAlpha(to: min(1.0, baseAlpha * 1.35 + 0.15), duration: 0.16)
            flashGlow.timingMode = .easeOut
            let flashFade = SKAction.fadeAlpha(to: baseAlpha, duration: 0.55)
            flashFade.timingMode = .easeInEaseOut
            aura.run(SKAction.sequence([flashGlow, flashFade])) { [weak self, weak aura] in
                guard let self = self, let aura = aura else { return }
                self.startAuraBreathing(aura: aura)
            }
        }

        // Bắn ra các tia nắng lấp lánh xung quanh tâm mặt trời thực tế
        spawnSunlightSparkles(at: center, count: 18)
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
            let distance = CGFloat.random(in: 25.0...85.0)
            let dest = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)

            let move = SKAction.move(to: dest, duration: Double.random(in: 0.45...0.85))
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: Double.random(in: 0.4...0.75))
            let scale = SKAction.scale(to: 0.15, duration: 0.55)
            let group = SKAction.group([move, fade, scale])

            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        sparkleGroup.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.removeFromParent()
        ]))
    }
}

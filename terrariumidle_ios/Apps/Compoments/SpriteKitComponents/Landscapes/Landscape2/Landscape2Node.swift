//
//  Landscape2Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 2: "Ban công chiều tà" (landscape2 / sunset)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape2Scene.sks`
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thành phần & Phân tầng:
///   1. `bgNode` (z = 0): Nền trời hoàng hôn rực rỡ (`landscape2-bg@4.167x`)
///   2. `sunGroupNode` (z = 10): Mặt trời chiều tà (`landscape2-sun@4.167x`)
///      - Nằm SAU lớp phủ layer5
///      - Nhịp thở quang năng ấm áp (Breathing Warm Pulse)
///   3. `layer5Node` (z = 20): Lớp phủ sương mù / ánh sáng hoàng hôn trên nền và trước mặt trời (`landscape2-5@4.167x`)
///      - Nhịp thở sương mờ tỏ dịu êm (Subtle Atmospheric Glow)
///   4. `cloudsGroupNode` (z = 30): 13 đám mây hoàng hôn bồng bềnh (`landscape2-cloud-1`..`landscape2-cloud-13`)
///      - Trôi nhẹ nhàng Parallax êm ái
///      - Opacity mờ tỏ bay bổng dịu dàng (Gentle Opacity Breathing)
///      - Nhấp nhô bồng bềnh trục Y (Floating Sine Bobbing)
public final class Landscape2Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private let landscapeRootNode = SKNode()

    // Layer Nodes
    private var bgNode: SKSpriteNode?
    private var sunGroupNode: SKNode?
    private var sunCore: SKSpriteNode?
    private var sunGlow: SKShapeNode?
    private var layer5Node: SKSpriteNode?
    private var cloudsGroupNode: SKNode?

    // Clouds Components
    private var cloudSprites: [SKSpriteNode] = []
    private var cloudSpeeds: [CGFloat] = []
    private var cloudBaseAlphas: [CGFloat] = []

    // Tỉ lệ scale so với canvas thiết kế chuẩn (1150 x 2071)
    private let baseDesignWidth: CGFloat = 1150.0
    private let baseDesignHeight: CGFloat = 2071.0
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
        sunCore = nil
        sunGlow = nil
        layer5Node = nil
        cloudsGroupNode = nil
        cloudSprites.removeAll()
        cloudSpeeds.removeAll()
        cloudBaseAlphas.removeAll()

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Tính scale để fit dọc theo chiều cao màn hình (Aspect Fill)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape2Scene.sks
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
        // 1. Nạp bgNode (z = 0)
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
            let fillW = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
            let fillH = max(containerSize.height, baseDesignHeight * activeScale) * 1.05
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            bg.isPaused = false
            bg.speed = 1.0
            if let realBgTex = loadTexture(name: "landscape2-bg@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // 2. Nạp sunGroup (z = 10): Mặt trời nằm sau layer 5
        if let sunGroup = scene.childNode(withName: "sunGroup") {
            sunGroup.removeFromParent()
            let normSunX = (sunGroup.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normSunY = (sunGroup.position.y / baseDesignHeight + 0.5) * containerSize.height
            sunGroup.position = CGPoint(x: normSunX, y: normSunY)
            sunGroup.setScale(activeScale)
            sunGroup.zPosition = 10.0
            sunGroup.isPaused = false
            sunGroup.speed = 1.0

            if let core = sunGroup.childNode(withName: "sunCore") as? SKSpriteNode {
                if let coreTex = loadTexture(name: "landscape2-sun@4.167x") {
                    core.texture = coreTex
                }
                core.isPaused = false
                core.speed = 1.0
                core.zPosition = 12.0
                self.sunCore = core
            }

            // Tạo quầng sáng mềm mại quanh mặt trời hoàng hôn
            let glow = SKShapeNode(circleOfRadius: 180)
            glow.fillColor = UIColor(red: 1.0, green: 0.72, blue: 0.35, alpha: 0.28)
            glow.strokeColor = .clear
            glow.zPosition = 11.0
            glow.glowWidth = 40.0
            sunGroup.addChild(glow)
            self.sunGlow = glow

            landscapeRootNode.addChild(sunGroup)
            self.sunGroupNode = sunGroup
        }

        // 3. Nạp layer5Node (z = 20): Lớp phủ trên nền và mặt trời nằm sau lớp này
        if let layer5 = scene.childNode(withName: "layer5Node") as? SKSpriteNode {
            layer5.removeFromParent()
            let normX = (layer5.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (layer5.position.y / baseDesignHeight + 0.5) * containerSize.height
            layer5.position = CGPoint(x: normX, y: normY)
            let w = max(containerSize.width, 1150.0 * activeScale)
            let h = 1679.0 * activeScale
            layer5.size = CGSize(width: w, height: h)
            layer5.zPosition = 20.0
            layer5.isPaused = false
            layer5.speed = 1.0
            if let realL5Tex = loadTexture(name: "landscape2-5@4.167x") {
                layer5.texture = realL5Tex
            }
            landscapeRootNode.addChild(layer5)
            self.layer5Node = layer5
        }

        // 4. Nạp cloudsGroup (z = 30): Các đám mây trên cùng
        if let cloudsGroup = scene.childNode(withName: "cloudsGroup") {
            cloudsGroup.removeFromParent()
            cloudsGroup.position = .zero
            cloudsGroup.zPosition = 30.0
            cloudsGroup.isPaused = false
            cloudsGroup.speed = 1.0
            landscapeRootNode.addChild(cloudsGroup)
            self.cloudsGroupNode = cloudsGroup

            for i in 1...13 {
                if let cloud = cloudsGroup.childNode(withName: "cloud_\(i)") as? SKSpriteNode {
                    if let cloudTex = loadTexture(name: "landscape2-cloud-\(i)@4.167x") {
                        cloud.texture = cloudTex
                    }
                    cloud.isHidden = false
                    cloud.isPaused = false
                    cloud.speed = 1.0

                    let normX = (cloud.position.x / baseDesignWidth + 0.5) * containerSize.width
                    let normY = (cloud.position.y / baseDesignHeight + 0.5) * containerSize.height
                    cloud.position = CGPoint(x: normX, y: normY)
                    cloud.size = CGSize(width: cloud.size.width * activeScale, height: cloud.size.height * activeScale)
                    cloud.zPosition = 30.0 + CGFloat(i)

                    let baseAlpha: CGFloat = cloud.alpha > 0.05 ? cloud.alpha : 0.90
                    cloud.alpha = baseAlpha
                    cloudBaseAlphas.append(baseAlpha)
                    cloudSprites.append(cloud)

                    // Vận tốc trôi nhẹ nhàng êm ái: từ 14 đến 26 pt/s
                    let baseSpeed: CGFloat = CGFloat(14 + (i * 3) % 13)
                    cloudSpeeds.append(baseSpeed)
                }
            }
        }
    }

    // MARK: - Procedural Fallback

    private func buildProceduralFallback() {
        // 1. Nền hoàng hôn
        let bgTex = loadTexture(name: "landscape2-bg@4.167x")
        let fillW = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
        let fillH = max(containerSize.height, baseDesignHeight * activeScale) * 1.05
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillW, height: fillH))
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // 2. Nhóm Mặt trời hoàng hôn (pos: (255.0, 861.5) trên 1150x2071)
        let sunGroup = SKNode()
        let normSunX = (255.0 / baseDesignWidth + 0.5) * containerSize.width
        let normSunY = (861.5 / baseDesignHeight + 0.5) * containerSize.height
        sunGroup.position = CGPoint(x: normSunX, y: normSunY)
        sunGroup.setScale(activeScale)
        sunGroup.zPosition = 10.0
        landscapeRootNode.addChild(sunGroup)
        self.sunGroupNode = sunGroup

        // Quầng sáng hoàng hôn
        let glow = SKShapeNode(circleOfRadius: 180)
        glow.fillColor = UIColor(red: 1.0, green: 0.72, blue: 0.35, alpha: 0.28)
        glow.strokeColor = .clear
        glow.zPosition = 11.0
        glow.glowWidth = 40.0
        sunGroup.addChild(glow)
        self.sunGlow = glow

        if let coreTex = loadTexture(name: "landscape2-sun@4.167x") {
            let core = SKSpriteNode(texture: coreTex, size: CGSize(width: 302, height: 309))
            core.name = "sunCore"
            core.position = .zero
            core.zPosition = 12.0
            sunGroup.addChild(core)
            self.sunCore = core
        }

        // 3. Lớp phủ layer5Node (z = 20.0, pos: (0, 196.0))
        if let l5Tex = loadTexture(name: "landscape2-5@4.167x") {
            let normX = (0.0 / baseDesignWidth + 0.5) * containerSize.width
            let normY = (196.0 / baseDesignHeight + 0.5) * containerSize.height
            let w = max(containerSize.width, 1150.0 * activeScale)
            let h = 1679.0 * activeScale
            let layer5 = SKSpriteNode(texture: l5Tex, size: CGSize(width: w, height: h))
            layer5.name = "layer5Node"
            layer5.position = CGPoint(x: normX, y: normY)
            layer5.zPosition = 20.0
            landscapeRootNode.addChild(layer5)
            self.layer5Node = layer5
        }

        // 4. Nhóm Mây trên cùng (z = 30.0)
        let cloudsGroup = SKNode()
        cloudsGroup.position = .zero
        cloudsGroup.zPosition = 30.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        let cloudConfigs: [(tex: String, pos: CGPoint, size: CGSize, alpha: CGFloat, speed: CGFloat, z: CGFloat)] = [
            ("landscape2-cloud-1@4.167x",  CGPoint(x: ( 209.5 / baseDesignWidth + 0.5) * containerSize.width, y: ( -34.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 394, height: 222), 0.95, 18.0, 31.0),
            ("landscape2-cloud-2@4.167x",  CGPoint(x: (-260.5 / baseDesignWidth + 0.5) * containerSize.width, y: ( 359.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 310, height: 175), 0.95, 20.0, 32.0),
            ("landscape2-cloud-3@4.167x",  CGPoint(x: (  48.5 / baseDesignWidth + 0.5) * containerSize.width, y: ( 251.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 116, height:  72), 0.90, 14.0, 33.0),
            ("landscape2-cloud-4@4.167x",  CGPoint(x: ( 317.0 / baseDesignWidth + 0.5) * containerSize.width, y: ( 471.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 177, height:  65), 0.90, 22.0, 34.0),
            ("landscape2-cloud-5@4.167x",  CGPoint(x: (-157.0 / baseDesignWidth + 0.5) * containerSize.width, y: ( 493.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width:  89, height:  43), 0.88, 16.0, 35.0),
            ("landscape2-cloud-6@4.167x",  CGPoint(x: (-335.0 / baseDesignWidth + 0.5) * containerSize.width, y: ( 799.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 221, height: 144), 0.92, 24.0, 36.0),
            ("landscape2-cloud-7@4.167x",  CGPoint(x: (-508.0 / baseDesignWidth + 0.5) * containerSize.width, y: (-328.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 101, height:  39), 0.85, 15.0, 31.0),
            ("landscape2-cloud-8@4.167x",  CGPoint(x: (  10.5 / baseDesignWidth + 0.5) * containerSize.width, y: (-606.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width:  70, height:  38), 0.85, 17.0, 32.0),
            ("landscape2-cloud-9@4.167x",  CGPoint(x: ( 451.5 / baseDesignWidth + 0.5) * containerSize.width, y: ( 157.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width:  70, height:  38), 0.85, 19.0, 33.0),
            ("landscape2-cloud-10@4.167x", CGPoint(x: ( 364.0 / baseDesignWidth + 0.5) * containerSize.width, y: ( -96.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 105, height:  82), 0.90, 21.0, 34.0),
            ("landscape2-cloud-11@4.167x", CGPoint(x: ( -55.0 / baseDesignWidth + 0.5) * containerSize.width, y: ( 693.0 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 139, height:  72), 0.90, 16.0, 35.0),
            ("landscape2-cloud-12@4.167x", CGPoint(x: ( 513.0 / baseDesignWidth + 0.5) * containerSize.width, y: (-230.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 124, height: 147), 0.92, 23.0, 36.0),
            ("landscape2-cloud-13@4.167x", CGPoint(x: (-225.5 / baseDesignWidth + 0.5) * containerSize.width, y: (-223.5 / baseDesignHeight + 0.5) * containerSize.height), CGSize(width: 198, height: 103), 0.92, 18.0, 37.0)
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
                cloudBaseAlphas.append(cfg.alpha)
            }
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Landscape2Scene")
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

    // MARK: - Animations (Diễn hoạt Mặt Trời & Mây Trôi Opacity Nhẹ Nhàng)

    private func startAnimations() {
        isPaused = false
        speed = 1.0
        landscapeRootNode.isPaused = false
        landscapeRootNode.speed = 1.0
        cloudsGroupNode?.isPaused = false
        cloudsGroupNode?.speed = 1.0
        sunGroupNode?.isPaused = false
        sunGroupNode?.speed = 1.0

        // 1. Hoạt ảnh Mặt trời hoàng hôn (Nhịp thở quang năng ấm áp)
        if let core = sunCore {
            startSunCoreBreathing(core: core)
        }
        if let glow = sunGlow {
            startSunGlowPulse(glow: glow)
        }

        // 2. Hoạt ảnh Lớp phủ layer5 (Nhịp thở sương mờ êm ả)
        if let layer5 = layer5Node {
            startLayer5AtmosphericBreathing(layer5: layer5)
        }

        // 3. Hoạt ảnh Mây trôi: Parallax + Opacity Breathing + Bobbing Sine nhẹ nhàng
        for (index, cloud) in cloudSprites.enumerated() {
            cloud.removeAction(forKey: "cloudDrift")
            cloud.removeAction(forKey: "cloudOpacity")
            cloud.removeAction(forKey: "cloudBobbing")
            cloud.isPaused = false
            cloud.speed = 1.0

            let speed = cloudSpeeds[min(index, cloudSpeeds.count - 1)]
            let baseAlpha = cloudBaseAlphas[min(index, cloudBaseAlphas.count - 1)]

            // A. Bay trôi nhẹ nhàng Parallax
            animateDriftingCloud(cloud, speed: speed)

            // B. Opacity mờ tỏ bay bổng dịu dàng theo yêu cầu
            animateCloudOpacityBreathing(cloud, baseAlpha: baseAlpha, index: index)

            // C. Nhấp nhô bồng bềnh trục Y
            animateCloudFloatingBobbing(cloud, index: index)
        }
    }

    private func startSunCoreBreathing(core: SKSpriteNode) {
        core.removeAction(forKey: "sunCoreBreathing")
        let baseScaleX = core.xScale
        let baseScaleY = core.yScale
        let pulseUp = SKAction.scaleX(to: baseScaleX * 1.05, y: baseScaleY * 1.05, duration: 3.2)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scaleX(to: baseScaleX, y: baseScaleY, duration: 3.2)
        pulseDown.timingMode = .easeInEaseOut
        core.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "sunCoreBreathing")
    }

    private func startSunGlowPulse(glow: SKShapeNode) {
        glow.removeAction(forKey: "sunGlowPulse")
        let scaleUp = SKAction.scale(to: 1.12, duration: 3.2)
        scaleUp.timingMode = .easeInEaseOut
        let fadeUp = SKAction.fadeAlpha(to: 0.40, duration: 3.2)
        let groupUp = SKAction.group([scaleUp, fadeUp])

        let scaleDown = SKAction.scale(to: 0.95, duration: 3.2)
        scaleDown.timingMode = .easeInEaseOut
        let fadeDown = SKAction.fadeAlpha(to: 0.22, duration: 3.2)
        let groupDown = SKAction.group([scaleDown, fadeDown])

        glow.run(SKAction.repeatForever(SKAction.sequence([groupUp, groupDown])), withKey: "sunGlowPulse")
    }

    private func startLayer5AtmosphericBreathing(layer5: SKSpriteNode) {
        layer5.removeAction(forKey: "layer5Breathing")
        let fadeOut = SKAction.fadeAlpha(to: 0.88, duration: 5.5)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 5.5)
        fadeIn.timingMode = .easeInEaseOut
        layer5.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])), withKey: "layer5Breathing")
    }

    /// Hoạt ảnh mây bay trôi nhẹ nhàng từ trái sang phải
    private func animateDriftingCloud(_ cloud: SKSpriteNode, speed: CGFloat) {
        let screenW = containerSize.width
        let cloudW = max(cloud.size.width, 80.0)
        let targetX = screenW + cloudW * 0.7
        let resetX = -cloudW * 0.7
        let currentX = cloud.position.x
        let safeSpeed = max(10.0, speed)

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
            // Đổi nhẹ độ cao Y ngẫu nhiên tự nhiên trong khoảng chiều cao bầu trời
            let deltaY = CGFloat.random(in: -16.0...16.0)
            cloud.position.y = max(self.containerSize.height * 0.15, min(self.containerSize.height * 0.95, cloud.position.y + deltaY))
        }
        let fullMove = SKAction.moveTo(x: targetX, duration: fullDuration)
        let fullCycle = SKAction.repeatForever(SKAction.sequence([resetPos, fullMove]))

        cloud.run(SKAction.sequence([initialMove, fullCycle]), withKey: "cloudDrift")
    }

    /// Hoạt ảnh Opacity mờ tỏ bay bổng dịu dàng (Gentle Opacity Breathing)
    private func animateCloudOpacityBreathing(_ cloud: SKSpriteNode, baseAlpha: CGFloat, index: Int) {
        let duration = 4.5 + Double(index % 5) * 0.9
        let minAlpha = max(0.55, baseAlpha * 0.76)
        let maxAlpha = min(1.0, baseAlpha * 1.08)

        let fadeOut = SKAction.fadeAlpha(to: minAlpha, duration: duration)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: maxAlpha, duration: duration)
        fadeIn.timingMode = .easeInEaseOut

        // Thêm độ trễ ban đầu để các đám mây thở lệch pha nhau tự nhiên
        let initialDelay = SKAction.wait(forDuration: Double(index % 4) * 0.8)
        let loop = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
        cloud.run(SKAction.sequence([initialDelay, loop]), withKey: "cloudOpacity")
    }

    /// Hoạt ảnh Nhấp nhô bồng bềnh trục Y (Floating Sine Bobbing)
    private func animateCloudFloatingBobbing(_ cloud: SKSpriteNode, index: Int) {
        let bobDistance: CGFloat = 6.0 + CGFloat(index % 4) * 2.5
        let duration = 3.8 + Double(index % 4) * 0.7

        let bobUp = SKAction.moveBy(x: 0, y: bobDistance, duration: duration)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -bobDistance, duration: duration)
        bobDown.timingMode = .easeInEaseOut

        let initialDelay = SKAction.wait(forDuration: Double((index + 2) % 5) * 0.6)
        let loop = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        cloud.run(SKAction.sequence([initialDelay, loop]), withKey: "cloudBobbing")
    }

    // MARK: - Tap Interaction Animation

    public func playTapAnimation(at location: CGPoint) {
        // 1. Kiểm tra vị trí chạm có trúng mặt trời không
        if let sunGroup = sunGroupNode {
            let sunCenter = sunGroup.position
            let dist = hypot(location.x - sunCenter.x, location.y - sunCenter.y)
            let hitRadius = 130.0 * activeScale
            if dist < hitRadius {
                playSunBurstAnimation(at: sunCenter)
                return
            }
        }

        // 2. Nếu chạm gần đám mây: đám mây gần nhất nhún nảy bồng bềnh & rực sáng
        var closestCloud: SKSpriteNode?
        var minDistance: CGFloat = 130.0 * activeScale
        for cloud in cloudSprites {
            let dist = hypot(location.x - cloud.position.x, location.y - cloud.position.y)
            if dist < minDistance {
                minDistance = dist
                closestCloud = cloud
            }
        }

        if let cloud = closestCloud {
            // Nhún nảy đàn hồi
            let bobUp = SKAction.moveBy(x: 0, y: 16, duration: 0.22)
            bobUp.timingMode = .easeOut
            let bobDown = SKAction.moveBy(x: 0, y: -16, duration: 0.35)
            bobDown.timingMode = .easeInEaseOut
            cloud.run(SKAction.sequence([bobUp, bobDown]))

            // Rực sáng nhẹ trong chốc lát
            let flash = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            let restore = SKAction.fadeAlpha(to: 0.85, duration: 0.45)
            cloud.run(SKAction.sequence([flash, restore]))
        }

        // 3. Sinh bụi nắng hoàng hôn ấm áp lấp lánh tại điểm chạm
        spawnSunsetSparkles(at: location, count: 9)
    }

    private func playSunBurstAnimation(at center: CGPoint) {
        // Vòng sóng ánh sáng hoàng hôn bùng tỏa
        let shockwave = SKShapeNode(circleOfRadius: 40)
        shockwave.position = center
        shockwave.strokeColor = UIColor(red: 1.0, green: 0.78, blue: 0.40, alpha: 0.85)
        shockwave.fillColor = UIColor(red: 1.0, green: 0.60, blue: 0.20, alpha: 0.25)
        shockwave.lineWidth = 4.0
        shockwave.zPosition = 45.0
        landscapeRootNode.addChild(shockwave)

        let expand = SKAction.scale(to: 4.5, duration: 0.7)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.7)
        let remove = SKAction.removeFromParent()
        shockwave.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))

        // Phun trào các tia/hạt ánh sáng vàng ấm
        spawnSunsetSparkles(at: center, count: 18, maxDistance: 130.0)
    }

    private func spawnSunsetSparkles(at location: CGPoint, count: Int, maxDistance: CGFloat = 70.0) {
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 0.95), // Vàng nắng
            UIColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 0.95), // Cam đào
            UIColor(red: 1.0, green: 0.50, blue: 0.40, alpha: 0.90), // Hồng san hô hoàng hôn
            UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 0.95)  // Trắng ấm
        ]

        for _ in 0..<count {
            let radius = CGFloat.random(in: 2.2...4.5)
            let sparkle = SKShapeNode(circleOfRadius: radius)
            sparkle.fillColor = colors.randomElement() ?? .white
            sparkle.strokeColor = .clear
            sparkle.position = location
            sparkle.zPosition = 50.0
            landscapeRootNode.addChild(sparkle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20...maxDistance)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist + CGFloat.random(in: 10...30) // Bay bổng nhẹ lên trên
            let duration = Double.random(in: 0.55...1.0)

            let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration)
            let scale = SKAction.scale(to: 0.3, duration: duration)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            sparkle.run(SKAction.sequence([group, remove]))
        }
    }
}

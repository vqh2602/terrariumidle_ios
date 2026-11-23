//
//  Landscape7Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 7: "Thần Sơn Huyễn Cảnh" (landscape7 / 神山幻境)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape7Scene.sks` (có Fallback Procedural độc lập)
/// - Bóc tách chính xác 26 lớp thành phần từ file vector thiết kế gốc `landscape7.svg`:
///   1. `bgGroup` (z = 0..3):
///      - `bgNode` (z = 0): Nền canvas màu cát ấm nguyên bản (`landscape7-1@4.167x`)
///      - `skyNode` (z = 1): Bầu trời chuyển sắc từ xanh mòng két sang xanh ngọc và vàng hoàng hôn (`landscape7-12@4.167x`)
///      - `seaNode` (z = 2): Thân biển xanh ngọc bích sâu thẳm (`landscape7-2@4.167x`)
///      - `seaGlowNode` (z = 3): Vầng quang năng ánh vàng rọi trên mặt biển (`landscape7-3@4.167x`)
///   2. `sunGroup` (z = 10..12):
///      - `sunCore` (z = 10): Thái dương hoàng kim giữa khe Thần Sơn (`landscape7-25@4.167x`)
///      - `sunAura` (z = 10.5): Quầng sáng hào quang tiên khí bao bọc mặt trời
///      - `sunReflection` (z = 11): Vệt nắng lung linh phản chiếu trên mặt nước (`landscape7-26@4.167x`)
///   3. `mountainsGroup` (z = 15..22):
///      - Thần Sơn xa trái & phải kèm mây hoàng kim đỉnh núi (`landscape7-14`, `15`, `16`, `17`)
///      - Thần Sơn trung cảnh trái & phải kèm mây vàng lụa tiên (`landscape7-18`, `19`, `20`, `21`, `22`)
///   4. `cloudsGroup` (z = 25):
///      - Màn sương mây chân núi lững lờ trôi dạt đối xứng nhẹ nhàng (`landscape7-23`, `24`)
///   5. `wavesGroup` (z = 30..47):
///      - Gợn sóng lấp lánh mặt biển giữa cảnh (`landscape7-13@4.167x`)
///      - Tầng sóng xa (Wave Tier 1): thân sóng, gờ sóng & bọt sóng trắng cuộn trào ukiyo-e (`landscape7-4`, `10`, `11`)
///      - Tầng sóng giữa (Wave Tier 2): thân sóng & bọt sóng mờ (`landscape7-5`, `6`)
///      - Tầng sóng gần (Wave Tier 3): thân sóng bờ, lớp sóng đáy & bọt sóng trắng xóa (`landscape7-7`, `8`, `9`)
///   6. `sparklesGroup` (z = 50):
///      - Hạt tiên khí linh quang lơ lửng bồng lai
public final class Landscape7Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Constants & Design Coordinates

    /// Kích thước canvas thiết kế chuẩn chuẩn hóa (Portrait layout thích ứng tỷ lệ chuẩn)
    private let baseDesignWidth: CGFloat = 750.0
    private let baseDesignHeight: CGFloat = 1334.0
    private var activeScale: CGFloat = 1.0
    private var containerSize: CGSize = .zero

    // MARK: - Layer Nodes

    private let landscapeRootNode = SKNode()

    // 1. Nền & Biển
    private var bgNode: SKSpriteNode?
    private var skyNode: SKSpriteNode?
    private var seaNode: SKSpriteNode?
    private var seaGlowNode: SKSpriteNode?

    // 2. Mặt trời & Phản chiếu
    private var sunGroupNode: SKNode?
    private var sunCore: SKSpriteNode?
    private var sunAura: SKShapeNode?
    private var sunReflection: SKSpriteNode?

    // 3. Dãy Thần Sơn
    private var mountainsGroupNode: SKNode?
    private var mountainLeftFar: SKSpriteNode?
    private var mountainLeftFarMist: SKSpriteNode?
    private var mountainRightFar: SKSpriteNode?
    private var mountainRightFarMist: SKSpriteNode?
    private var mountainLeftMid: SKSpriteNode?
    private var mountainLeftMidMist: SKSpriteNode?
    private var mountainLeftAccent: SKSpriteNode?
    private var mountainRightMid: SKSpriteNode?
    private var mountainRightMidMist: SKSpriteNode?

    // 4. Mây sương chân núi
    private var cloudsGroupNode: SKNode?
    private var mistLeft: SKSpriteNode?
    private var mistRight: SKSpriteNode?

    // 5. Hệ thống sóng biển nhấp nhô
    private var wavesGroupNode: SKNode?
    private var seaRipples: SKSpriteNode?

    // Cụm sóng tầng 1 (Xa)
    private var waveTier1Node: SKNode?
    private var wave1Body: SKSpriteNode?
    private var wave1Ridge: SKSpriteNode?
    private var wave1Foam: SKSpriteNode?

    // Cụm sóng tầng 2 (Giữa)
    private var waveTier2Node: SKNode?
    private var wave2Body: SKSpriteNode?
    private var wave2Foam: SKSpriteNode?

    // Cụm sóng tầng 3 (Gần / Bờ)
    private var waveTier3Node: SKNode?
    private var wave3Body: SKSpriteNode?
    private var wave3Sub: SKSpriteNode?
    private var wave3Foam: SKSpriteNode?

    // 6. Tiên khí linh quang & Hiệu ứng chạm
    private var sparklesGroupNode: SKNode?
    private var tapRippleGroupNode: SKNode?

    // Ghi nhớ toạ độ nghỉ (Rest Positions) để chống trôi lệch toạ độ tuyệt đối
    private var restPositions: [String: CGPoint] = [:]

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
        restPositions.removeAll()

        bgNode = nil
        skyNode = nil
        seaNode = nil
        seaGlowNode = nil
        sunGroupNode = nil
        sunCore = nil
        sunAura = nil
        sunReflection = nil
        mountainsGroupNode = nil
        mountainLeftFar = nil
        mountainLeftFarMist = nil
        mountainRightFar = nil
        mountainRightFarMist = nil
        mountainLeftMid = nil
        mountainLeftMidMist = nil
        mountainLeftAccent = nil
        mountainRightMid = nil
        mountainRightMidMist = nil
        cloudsGroupNode = nil
        mistLeft = nil
        mistRight = nil
        wavesGroupNode = nil
        seaRipples = nil
        waveTier1Node = nil
        wave1Body = nil
        wave1Ridge = nil
        wave1Foam = nil
        waveTier2Node = nil
        wave2Body = nil
        wave2Foam = nil
        waveTier3Node = nil
        wave3Body = nil
        wave3Sub = nil
        wave3Foam = nil
        sparklesGroupNode = nil
        tapRippleGroupNode = nil

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape7Scene.sks
        if let scene = loadSceneTemplate() {
            buildFromSceneTemplate(scene: scene)
            setupSparklesAndRippleGroups()
            startAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildProceduralFallback()
        setupSparklesAndRippleGroups()
        startAnimations()
    }

    // MARK: - Load Scene Template

    private func loadSceneTemplate() -> SKScene? {
        if let scene = SKScene(fileNamed: "Landscape7Scene") {
            return scene
        }
        if let scene = SKScene(fileNamed: "Landscape7Scene.sks") {
            return scene
        }
        return nil
    }

    // MARK: - Build from Scene Template

    private func buildFromSceneTemplate(scene: SKScene) {
        // --- 1. bgNode (z = 0) ---
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
            let fillW = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
            let fillH = max(containerSize.height, baseDesignHeight * activeScale) * 1.05
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            if let tex = loadTexture(name: "landscape7-1@4.167x") { bg.texture = tex }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // --- 2. skyNode (z = 1) ---
        if let sky = scene.childNode(withName: "skyNode") as? SKSpriteNode {
            sky.removeFromParent()
            let normX = (sky.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (sky.position.y / baseDesignHeight + 0.5) * containerSize.height
            sky.position = CGPoint(x: normX, y: normY)
            let w = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
            let h = max(containerSize.height * 0.65, 600.0 * activeScale)
            sky.size = CGSize(width: w, height: h)
            sky.zPosition = 1.0
            if let tex = loadTexture(name: "landscape7-12@4.167x") { sky.texture = tex }
            landscapeRootNode.addChild(sky)
            self.skyNode = sky
        }

        // --- 3. seaNode & seaGlowNode (z = 2..3) ---
        if let sea = scene.childNode(withName: "seaNode") as? SKSpriteNode {
            sea.removeFromParent()
            let normX = (sea.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (sea.position.y / baseDesignHeight + 0.5) * containerSize.height
            sea.position = CGPoint(x: normX, y: normY)
            let w = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
            let h = max(containerSize.height * 0.70, 800.0 * activeScale)
            sea.size = CGSize(width: w, height: h)
            sea.zPosition = 2.0
            if let tex = loadTexture(name: "landscape7-2@4.167x") { sea.texture = tex }
            landscapeRootNode.addChild(sea)
            self.seaNode = sea
        }

        if let seaGlow = scene.childNode(withName: "seaGlowNode") as? SKSpriteNode {
            seaGlow.removeFromParent()
            let normX = (seaGlow.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (seaGlow.position.y / baseDesignHeight + 0.5) * containerSize.height
            seaGlow.position = CGPoint(x: normX, y: normY)
            seaGlow.size = CGSize(width: max(containerSize.width, 750.0 * activeScale), height: 450.57 * activeScale)
            seaGlow.zPosition = 3.0
            seaGlow.alpha = 0.60
            if let tex = loadTexture(name: "landscape7-3@4.167x") { seaGlow.texture = tex }
            landscapeRootNode.addChild(seaGlow)
            self.seaGlowNode = seaGlow
        }

        // --- 4. sunGroup (z = 10..12) ---
        let sunGroup = SKNode()
        sunGroup.name = "sunGroup"
        sunGroup.zPosition = 10.0
        landscapeRootNode.addChild(sunGroup)
        self.sunGroupNode = sunGroup

        let templateSunGroup = scene.childNode(withName: "sunGroup")

        // Sun Core
        if let templateCore = (templateSunGroup?.childNode(withName: "sunCore") ?? scene.childNode(withName: "sunCore")) as? SKSpriteNode {
            let core = SKSpriteNode()
            core.name = "sunCore"
            let normX = (templateCore.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (templateCore.position.y / baseDesignHeight + 0.5) * containerSize.height
            core.position = CGPoint(x: normX, y: normY)
            core.size = CGSize(width: 199.18 * activeScale, height: 100.97 * activeScale)
            core.zPosition = 10.0
            if let tex = loadTexture(name: "landscape7-25@4.167x") { core.texture = tex }
            sunGroup.addChild(core)
            self.sunCore = core
            restPositions["sunCore"] = core.position

            // Quầng sáng hào quang ấm áp bao quanh mặt trời
            let aura = SKShapeNode(ellipseOf: CGSize(width: 240.0 * activeScale, height: 140.0 * activeScale))
            aura.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.55, alpha: 0.25)
            aura.strokeColor = .clear
            aura.glowWidth = 25.0 * activeScale
            aura.position = core.position
            aura.zPosition = 9.5
            sunGroup.addChild(aura)
            self.sunAura = aura
        }

        // Sun Reflection
        if let templateRef = (templateSunGroup?.childNode(withName: "sunReflection") ?? scene.childNode(withName: "sunReflection")) as? SKSpriteNode {
            let ref = SKSpriteNode()
            ref.name = "sunReflection"
            let normX = (templateRef.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normY = (templateRef.position.y / baseDesignHeight + 0.5) * containerSize.height
            ref.position = CGPoint(x: normX, y: normY)
            ref.size = CGSize(width: 156.33 * activeScale, height: 48.54 * activeScale)
            ref.zPosition = 11.0
            ref.alpha = 0.50
            if let tex = loadTexture(name: "landscape7-26@4.167x") { ref.texture = tex }
            sunGroup.addChild(ref)
            self.sunReflection = ref
            restPositions["sunReflection"] = ref.position
        }

        // --- 5. mountainsGroup (z = 15..22) ---
        let mountainsGroup = SKNode()
        mountainsGroup.name = "mountainsGroup"
        mountainsGroup.zPosition = 15.0
        landscapeRootNode.addChild(mountainsGroup)
        self.mountainsGroupNode = mountainsGroup

        let templateMountains = scene.childNode(withName: "mountainsGroup")

        self.mountainLeftFar = setupSprite(from: templateMountains, or: scene, name: "mountainLeftFar", texName: "landscape7-14@4.167x", origSize: CGSize(width: 310.15, height: 85.35), defaultPos: CGPoint(x: -210.92, y: 61.16), z: 15.0, alpha: 0.5, inGroup: mountainsGroup)
        self.mountainLeftFarMist = setupSprite(from: templateMountains, or: scene, name: "mountainLeftFarMist", texName: "landscape7-15@4.167x", origSize: CGSize(width: 237.32, height: 76.04), defaultPos: CGPoint(x: -174.51, y: 56.51), z: 16.0, alpha: 1.0, inGroup: mountainsGroup)

        self.mountainRightFar = setupSprite(from: templateMountains, or: scene, name: "mountainRightFar", texName: "landscape7-16@4.167x", origSize: CGSize(width: 306.39, height: 93.44), defaultPos: CGPoint(x: 233.03, y: 64.95), z: 15.0, alpha: 0.5, inGroup: mountainsGroup)
        self.mountainRightFarMist = setupSprite(from: templateMountains, or: scene, name: "mountainRightFarMist", texName: "landscape7-17@4.167x", origSize: CGSize(width: 303.08, height: 93.18), defaultPos: CGPoint(x: 231.37, y: 65.08), z: 16.0, alpha: 1.0, inGroup: mountainsGroup)

        self.mountainLeftMid = setupSprite(from: templateMountains, or: scene, name: "mountainLeftMid", texName: "landscape7-20@4.167x", origSize: CGSize(width: 342.10, height: 37.84), defaultPos: CGPoint(x: -228.78, y: 37.25), z: 20.0, alpha: 0.3, inGroup: mountainsGroup)
        self.mountainLeftMidMist = setupSprite(from: templateMountains, or: scene, name: "mountainLeftMidMist", texName: "landscape7-21@4.167x", origSize: CGSize(width: 274.22, height: 35.54), defaultPos: CGPoint(x: -232.58, y: 38.39), z: 21.0, alpha: 0.6, inGroup: mountainsGroup)
        self.mountainLeftAccent = setupSprite(from: templateMountains, or: scene, name: "mountainLeftAccent", texName: "landscape7-22@4.167x", origSize: CGSize(width: 42.27, height: 14.98), defaultPos: CGPoint(x: -97.09, y: 38.68), z: 22.0, alpha: 0.6, inGroup: mountainsGroup)

        self.mountainRightMid = setupSprite(from: templateMountains, or: scene, name: "mountainRightMid", texName: "landscape7-18@4.167x", origSize: CGSize(width: 296.45, height: 37.68), defaultPos: CGPoint(x: 239.56, y: 37.33), z: 20.0, alpha: 0.3, inGroup: mountainsGroup)
        self.mountainRightMidMist = setupSprite(from: templateMountains, or: scene, name: "mountainRightMidMist", texName: "landscape7-19@4.167x", origSize: CGSize(width: 242.15, height: 37.68), defaultPos: CGPoint(x: 212.41, y: 37.33), z: 21.0, alpha: 0.6, inGroup: mountainsGroup)

        // --- 6. cloudsGroup (z = 25) ---
        let cloudsGroup = SKNode()
        cloudsGroup.name = "cloudsGroup"
        cloudsGroup.zPosition = 25.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        let templateClouds = scene.childNode(withName: "cloudsGroup")
        self.mistLeft = setupSprite(from: templateClouds, or: scene, name: "mistLeft", texName: "landscape7-24@4.167x", origSize: CGSize(width: 293.10, height: 35.49), defaultPos: CGPoint(x: -195.95, y: 0.74), z: 25.0, alpha: 0.8, inGroup: cloudsGroup)
        self.mistRight = setupSprite(from: templateClouds, or: scene, name: "mistRight", texName: "landscape7-23@4.167x", origSize: CGSize(width: 283.95, height: 31.24), defaultPos: CGPoint(x: 233.03, y: 2.87), z: 25.0, alpha: 0.8, inGroup: cloudsGroup)

        // --- 7. wavesGroup (z = 30..47) ---
        let wavesGroup = SKNode()
        wavesGroup.name = "wavesGroup"
        wavesGroup.zPosition = 30.0
        landscapeRootNode.addChild(wavesGroup)
        self.wavesGroupNode = wavesGroup

        let templateWaves = scene.childNode(withName: "wavesGroup")

        // Gợn sóng biển giữa
        self.seaRipples = setupSprite(from: templateWaves, or: scene, name: "seaRipples", texName: "landscape7-13@4.167x", origSize: CGSize(width: 759.36, height: 144.52), defaultPos: CGPoint(x: -0.01, y: -111.67), z: 30.0, alpha: 0.95, inGroup: wavesGroup)

        // Wave Tier 1
        let w1Group = SKNode()
        w1Group.name = "waveTier1"
        w1Group.zPosition = 35.0
        wavesGroup.addChild(w1Group)
        self.waveTier1Node = w1Group
        let templateW1 = templateWaves?.childNode(withName: "waveTier1")
        self.wave1Body = setupSprite(from: templateW1, or: scene, name: "wave1Body", texName: "landscape7-4@4.167x", origSize: CGSize(width: 750.0, height: 108.12), defaultPos: CGPoint(x: 0, y: -195.94), z: 35.0, alpha: 1.0, inGroup: w1Group)
        self.wave1Ridge = setupSprite(from: templateW1, or: scene, name: "wave1Ridge", texName: "landscape7-10@4.167x", origSize: CGSize(width: 750.0, height: 61.69), defaultPos: CGPoint(x: 0, y: -172.72), z: 36.0, alpha: 1.0, inGroup: w1Group)
        self.wave1Foam = setupSprite(from: templateW1, or: scene, name: "wave1Foam", texName: "landscape7-11@4.167x", origSize: CGSize(width: 750.0, height: 66.93), defaultPos: CGPoint(x: 0, y: -167.10), z: 37.0, alpha: 1.0, inGroup: w1Group)

        // Wave Tier 2
        let w2Group = SKNode()
        w2Group.name = "waveTier2"
        w2Group.zPosition = 40.0
        wavesGroup.addChild(w2Group)
        self.waveTier2Node = w2Group
        let templateW2 = templateWaves?.childNode(withName: "waveTier2")
        self.wave2Body = setupSprite(from: templateW2, or: scene, name: "wave2Body", texName: "landscape7-5@4.167x", origSize: CGSize(width: 750.0, height: 83.45), defaultPos: CGPoint(x: 0, y: -208.27), z: 40.0, alpha: 1.0, inGroup: w2Group)
        self.wave2Foam = setupSprite(from: templateW2, or: scene, name: "wave2Foam", texName: "landscape7-6@4.167x", origSize: CGSize(width: 750.0, height: 59.68), defaultPos: CGPoint(x: 0, y: -195.39), z: 41.0, alpha: 0.1, inGroup: w2Group)

        // Wave Tier 3
        let w3Group = SKNode()
        w3Group.name = "waveTier3"
        w3Group.zPosition = 45.0
        wavesGroup.addChild(w3Group)
        self.waveTier3Node = w3Group
        let templateW3 = templateWaves?.childNode(withName: "waveTier3")
        self.wave3Body = setupSprite(from: templateW3, or: scene, name: "wave3Body", texName: "landscape7-7@4.167x", origSize: CGSize(width: 750.0, height: 58.68), defaultPos: CGPoint(x: 0, y: -222.81), z: 45.0, alpha: 1.0, inGroup: w3Group)
        self.wave3Sub = setupSprite(from: templateW3, or: scene, name: "wave3Sub", texName: "landscape7-8@4.167x", origSize: CGSize(width: 750.0, height: 58.68), defaultPos: CGPoint(x: 0, y: -222.81), z: 46.0, alpha: 1.0, inGroup: w3Group)
        self.wave3Foam = setupSprite(from: templateW3, or: scene, name: "wave3Foam", texName: "landscape7-9@4.167x", origSize: CGSize(width: 750.0, height: 60.44), defaultPos: CGPoint(x: 0, y: -221.93), z: 47.0, alpha: 0.3, inGroup: w3Group)
    }

    // MARK: - Procedural Fallback

    private func buildProceduralFallback() {
        // 1. Base & Background
        let fillW = max(containerSize.width, baseDesignWidth * activeScale) * 1.05
        let fillH = max(containerSize.height, baseDesignHeight * activeScale) * 1.05

        let bg = SKSpriteNode(color: UIColor(red: 232/255, green: 217/255, blue: 179/255, alpha: 1.0), size: CGSize(width: fillW, height: fillH))
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0.0
        if let tex = loadTexture(name: "landscape7-1@4.167x") { bg.texture = tex }
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        let sky = SKSpriteNode(color: UIColor(red: 56/255, green: 159/255, blue: 178/255, alpha: 1.0), size: CGSize(width: fillW, height: containerSize.height * 0.65))
        sky.position = CGPoint(x: containerSize.width / 2.0, y: (350.0 / baseDesignHeight + 0.5) * containerSize.height)
        sky.zPosition = 1.0
        if let tex = loadTexture(name: "landscape7-12@4.167x") { sky.texture = tex }
        landscapeRootNode.addChild(sky)
        self.skyNode = sky

        let sea = SKSpriteNode(color: UIColor(red: 77/255, green: 181/255, blue: 184/255, alpha: 1.0), size: CGSize(width: fillW, height: containerSize.height * 0.70))
        sea.position = CGPoint(x: containerSize.width / 2.0, y: (-267.0 / baseDesignHeight + 0.5) * containerSize.height)
        sea.zPosition = 2.0
        if let tex = loadTexture(name: "landscape7-2@4.167x") { sea.texture = tex }
        landscapeRootNode.addChild(sea)
        self.seaNode = sea

        let seaGlow = SKSpriteNode(color: .clear, size: CGSize(width: fillW, height: 450.57 * activeScale))
        seaGlow.position = CGPoint(x: containerSize.width / 2.0, y: (24.72 / baseDesignHeight + 0.5) * containerSize.height)
        seaGlow.zPosition = 3.0
        seaGlow.alpha = 0.60
        if let tex = loadTexture(name: "landscape7-3@4.167x") { seaGlow.texture = tex }
        landscapeRootNode.addChild(seaGlow)
        self.seaGlowNode = seaGlow

        // 2. Sun & Reflection
        let sunGroup = SKNode()
        sunGroup.name = "sunGroup"
        sunGroup.zPosition = 10.0
        landscapeRootNode.addChild(sunGroup)
        self.sunGroupNode = sunGroup

        let core = SKSpriteNode(color: .clear, size: CGSize(width: 199.18 * activeScale, height: 100.97 * activeScale))
        core.position = CGPoint(x: (19.35 / baseDesignWidth + 0.5) * containerSize.width, y: (68.97 / baseDesignHeight + 0.5) * containerSize.height)
        core.zPosition = 10.0
        if let tex = loadTexture(name: "landscape7-25@4.167x") { core.texture = tex }
        sunGroup.addChild(core)
        self.sunCore = core
        restPositions["sunCore"] = core.position

        let aura = SKShapeNode(ellipseOf: CGSize(width: 240.0 * activeScale, height: 140.0 * activeScale))
        aura.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.55, alpha: 0.25)
        aura.strokeColor = .clear
        aura.glowWidth = 25.0 * activeScale
        aura.position = core.position
        aura.zPosition = 9.5
        sunGroup.addChild(aura)
        self.sunAura = aura

        let ref = SKSpriteNode(color: .clear, size: CGSize(width: 156.33 * activeScale, height: 48.54 * activeScale))
        ref.position = CGPoint(x: (21.76 / baseDesignWidth + 0.5) * containerSize.width, y: (-5.90 / baseDesignHeight + 0.5) * containerSize.height)
        ref.zPosition = 11.0
        ref.alpha = 0.50
        if let tex = loadTexture(name: "landscape7-26@4.167x") { ref.texture = tex }
        sunGroup.addChild(ref)
        self.sunReflection = ref
        restPositions["sunReflection"] = ref.position

        // 3. Mountains
        let mountainsGroup = SKNode()
        mountainsGroup.name = "mountainsGroup"
        mountainsGroup.zPosition = 15.0
        landscapeRootNode.addChild(mountainsGroup)
        self.mountainsGroupNode = mountainsGroup

        self.mountainLeftFar = setupSprite(from: nil, or: nil, name: "mountainLeftFar", texName: "landscape7-14@4.167x", origSize: CGSize(width: 310.15, height: 85.35), defaultPos: CGPoint(x: -210.92, y: 61.16), z: 15.0, alpha: 0.5, inGroup: mountainsGroup)
        self.mountainLeftFarMist = setupSprite(from: nil, or: nil, name: "mountainLeftFarMist", texName: "landscape7-15@4.167x", origSize: CGSize(width: 237.32, height: 76.04), defaultPos: CGPoint(x: -174.51, y: 56.51), z: 16.0, alpha: 1.0, inGroup: mountainsGroup)
        self.mountainRightFar = setupSprite(from: nil, or: nil, name: "mountainRightFar", texName: "landscape7-16@4.167x", origSize: CGSize(width: 306.39, height: 93.44), defaultPos: CGPoint(x: 233.03, y: 64.95), z: 15.0, alpha: 0.5, inGroup: mountainsGroup)
        self.mountainRightFarMist = setupSprite(from: nil, or: nil, name: "mountainRightFarMist", texName: "landscape7-17@4.167x", origSize: CGSize(width: 303.08, height: 93.18), defaultPos: CGPoint(x: 231.37, y: 65.08), z: 16.0, alpha: 1.0, inGroup: mountainsGroup)

        self.mountainLeftMid = setupSprite(from: nil, or: nil, name: "mountainLeftMid", texName: "landscape7-20@4.167x", origSize: CGSize(width: 342.10, height: 37.84), defaultPos: CGPoint(x: -228.78, y: 37.25), z: 20.0, alpha: 0.3, inGroup: mountainsGroup)
        self.mountainLeftMidMist = setupSprite(from: nil, or: nil, name: "mountainLeftMidMist", texName: "landscape7-21@4.167x", origSize: CGSize(width: 274.22, height: 35.54), defaultPos: CGPoint(x: -232.58, y: 38.39), z: 21.0, alpha: 0.6, inGroup: mountainsGroup)
        self.mountainLeftAccent = setupSprite(from: nil, or: nil, name: "mountainLeftAccent", texName: "landscape7-22@4.167x", origSize: CGSize(width: 42.27, height: 14.98), defaultPos: CGPoint(x: -97.09, y: 38.68), z: 22.0, alpha: 0.6, inGroup: mountainsGroup)
        self.mountainRightMid = setupSprite(from: nil, or: nil, name: "mountainRightMid", texName: "landscape7-18@4.167x", origSize: CGSize(width: 296.45, height: 37.68), defaultPos: CGPoint(x: 239.56, y: 37.33), z: 20.0, alpha: 0.3, inGroup: mountainsGroup)
        self.mountainRightMidMist = setupSprite(from: nil, or: nil, name: "mountainRightMidMist", texName: "landscape7-19@4.167x", origSize: CGSize(width: 242.15, height: 37.68), defaultPos: CGPoint(x: 212.41, y: 37.33), z: 21.0, alpha: 0.6, inGroup: mountainsGroup)

        // 4. Clouds & Mist
        let cloudsGroup = SKNode()
        cloudsGroup.name = "cloudsGroup"
        cloudsGroup.zPosition = 25.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        self.mistLeft = setupSprite(from: nil, or: nil, name: "mistLeft", texName: "landscape7-24@4.167x", origSize: CGSize(width: 293.10, height: 35.49), defaultPos: CGPoint(x: -195.95, y: 0.74), z: 25.0, alpha: 0.8, inGroup: cloudsGroup)
        self.mistRight = setupSprite(from: nil, or: nil, name: "mistRight", texName: "landscape7-23@4.167x", origSize: CGSize(width: 283.95, height: 31.24), defaultPos: CGPoint(x: 233.03, y: 2.87), z: 25.0, alpha: 0.8, inGroup: cloudsGroup)

        // 5. Ocean Waves
        let wavesGroup = SKNode()
        wavesGroup.name = "wavesGroup"
        wavesGroup.zPosition = 30.0
        landscapeRootNode.addChild(wavesGroup)
        self.wavesGroupNode = wavesGroup

        self.seaRipples = setupSprite(from: nil, or: nil, name: "seaRipples", texName: "landscape7-13@4.167x", origSize: CGSize(width: 759.36, height: 144.52), defaultPos: CGPoint(x: -0.01, y: -111.67), z: 30.0, alpha: 0.95, inGroup: wavesGroup)

        let w1Group = SKNode()
        w1Group.name = "waveTier1"
        w1Group.zPosition = 35.0
        wavesGroup.addChild(w1Group)
        self.waveTier1Node = w1Group
        self.wave1Body = setupSprite(from: nil, or: nil, name: "wave1Body", texName: "landscape7-4@4.167x", origSize: CGSize(width: 750.0, height: 108.12), defaultPos: CGPoint(x: 0, y: -195.94), z: 35.0, alpha: 1.0, inGroup: w1Group)
        self.wave1Ridge = setupSprite(from: nil, or: nil, name: "wave1Ridge", texName: "landscape7-10@4.167x", origSize: CGSize(width: 750.0, height: 61.69), defaultPos: CGPoint(x: 0, y: -172.72), z: 36.0, alpha: 1.0, inGroup: w1Group)
        self.wave1Foam = setupSprite(from: nil, or: nil, name: "wave1Foam", texName: "landscape7-11@4.167x", origSize: CGSize(width: 750.0, height: 66.93), defaultPos: CGPoint(x: 0, y: -167.10), z: 37.0, alpha: 1.0, inGroup: w1Group)

        let w2Group = SKNode()
        w2Group.name = "waveTier2"
        w2Group.zPosition = 40.0
        wavesGroup.addChild(w2Group)
        self.waveTier2Node = w2Group
        self.wave2Body = setupSprite(from: nil, or: nil, name: "wave2Body", texName: "landscape7-5@4.167x", origSize: CGSize(width: 750.0, height: 83.45), defaultPos: CGPoint(x: 0, y: -208.27), z: 40.0, alpha: 1.0, inGroup: w2Group)
        self.wave2Foam = setupSprite(from: nil, or: nil, name: "wave2Foam", texName: "landscape7-6@4.167x", origSize: CGSize(width: 750.0, height: 59.68), defaultPos: CGPoint(x: 0, y: -195.39), z: 41.0, alpha: 0.1, inGroup: w2Group)

        let w3Group = SKNode()
        w3Group.name = "waveTier3"
        w3Group.zPosition = 45.0
        wavesGroup.addChild(w3Group)
        self.waveTier3Node = w3Group
        self.wave3Body = setupSprite(from: nil, or: nil, name: "wave3Body", texName: "landscape7-7@4.167x", origSize: CGSize(width: 750.0, height: 58.68), defaultPos: CGPoint(x: 0, y: -222.81), z: 45.0, alpha: 1.0, inGroup: w3Group)
        self.wave3Sub = setupSprite(from: nil, or: nil, name: "wave3Sub", texName: "landscape7-8@4.167x", origSize: CGSize(width: 750.0, height: 58.68), defaultPos: CGPoint(x: 0, y: -222.81), z: 46.0, alpha: 1.0, inGroup: w3Group)
        self.wave3Foam = setupSprite(from: nil, or: nil, name: "wave3Foam", texName: "landscape7-9@4.167x", origSize: CGSize(width: 750.0, height: 60.44), defaultPos: CGPoint(x: 0, y: -221.93), z: 47.0, alpha: 0.3, inGroup: w3Group)
    }

    // MARK: - Helper Setup Sprite

    private func setupSprite(
        from group: SKNode?,
        or fallbackScene: SKScene?,
        name: String,
        texName: String,
        origSize: CGSize,
        defaultPos: CGPoint,
        z: CGFloat,
        alpha: CGFloat,
        inGroup parent: SKNode
    ) -> SKSpriteNode {
        let template = (group?.childNode(withName: name) ?? fallbackScene?.childNode(withName: name)) as? SKSpriteNode
        let sprite = SKSpriteNode()
        sprite.name = name

        let rawX = template?.position.x ?? defaultPos.x
        let rawY = template?.position.y ?? defaultPos.y
        let normX = (rawX / baseDesignWidth + 0.5) * containerSize.width
        let normY = (rawY / baseDesignHeight + 0.5) * containerSize.height

        sprite.position = CGPoint(x: normX, y: normY)
        sprite.size = CGSize(width: origSize.width * activeScale, height: origSize.height * activeScale)
        sprite.zPosition = z
        sprite.alpha = alpha

        if let tex = loadTexture(name: texName) {
            sprite.texture = tex
        }

        parent.addChild(sprite)
        restPositions[name] = sprite.position
        return sprite
    }

    private func setupSparklesAndRippleGroups() {
        let sparkles = SKNode()
        sparkles.name = "sparklesGroup"
        sparkles.zPosition = 50.0
        landscapeRootNode.addChild(sparkles)
        self.sparklesGroupNode = sparkles

        let tapGroup = SKNode()
        tapGroup.name = "tapRippleGroup"
        tapGroup.zPosition = 55.0
        landscapeRootNode.addChild(tapGroup)
        self.tapRippleGroupNode = tapGroup
    }

    // MARK: - Animations

    public func startAnimations() {
        animateWaves()
        animateCloudsAndMist()
        animateSunAndReflection()
        animateAmbientSparkles()
    }

    // MARK: 1. Hiệu Ứng Sóng Biển Nhấp Nhô Đa Tầng (Rolling Ocean Waves)

    private func animateWaves() {
        // --- 1. Gợn sóng lấp lánh mặt biển giữa cảnh (seaRipples) ---
        if let ripples = seaRipples, let rest = restPositions["seaRipples"] {
            ripples.removeAllActions()
            ripples.position = rest

            // Lượn ngang nhẹ và nhấp nhô
            let moveRight = SKAction.moveTo(x: rest.x + 8.0 * activeScale, duration: 2.4)
            moveRight.timingMode = .easeInEaseOut
            let moveLeft = SKAction.moveTo(x: rest.x - 8.0 * activeScale, duration: 2.4)
            moveLeft.timingMode = .easeInEaseOut
            ripples.run(SKAction.repeatForever(SKAction.sequence([moveRight, moveLeft])), withKey: "ripples_driftX")

            let moveUp = SKAction.moveTo(y: rest.y + 3.0 * activeScale, duration: 1.9)
            moveUp.timingMode = .easeInEaseOut
            let moveDown = SKAction.moveTo(y: rest.y - 3.0 * activeScale, duration: 1.9)
            moveDown.timingMode = .easeInEaseOut
            ripples.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])), withKey: "ripples_bobY")

            // Lấp lánh phản chiếu ánh kim
            let shimmerHigh = SKAction.fadeAlpha(to: 1.0, duration: 1.4)
            shimmerHigh.timingMode = .easeInEaseOut
            let shimmerLow = SKAction.fadeAlpha(to: 0.65, duration: 1.4)
            shimmerLow.timingMode = .easeInEaseOut
            ripples.run(SKAction.repeatForever(SKAction.sequence([shimmerHigh, shimmerLow])), withKey: "ripples_shimmer")
        }

        // --- 2. Tầng sóng xa (Wave Tier 1 - Chu kỳ 5.2s, biên độ nhô cao nhất) ---
        if let tier1 = waveTier1Node {
            tier1.removeAllActions()
            tier1.position = .zero

            let surgeY = SKAction.moveBy(x: 0, y: 7.5 * activeScale, duration: 2.6)
            surgeY.timingMode = .easeInEaseOut
            let recedeY = SKAction.moveBy(x: 0, y: -7.5 * activeScale, duration: 2.6)
            recedeY.timingMode = .easeInEaseOut

            let swayX = SKAction.moveBy(x: 6.0 * activeScale, y: 0, duration: 2.6)
            swayX.timingMode = .easeInEaseOut
            let backX = SKAction.moveBy(x: -6.0 * activeScale, y: 0, duration: 2.6)
            backX.timingMode = .easeInEaseOut

            let cycleY = SKAction.sequence([surgeY, recedeY])
            let cycleX = SKAction.sequence([swayX, backX])
            tier1.run(SKAction.repeatForever(cycleY), withKey: "tier1_rollY")
            tier1.run(SKAction.repeatForever(cycleX), withKey: "tier1_swayX")

            // Bọt sóng trắng cuộn trào (wave1Foam): giãn nở nhẹ khi sóng dâng cao
            if let foam = wave1Foam {
                foam.removeAllActions()
                foam.setScale(1.0)
                let foamExpand = SKAction.scaleY(to: 1.045, duration: 2.6)
                foamExpand.timingMode = .easeInEaseOut
                let foamContract = SKAction.scaleY(to: 0.975, duration: 2.6)
                foamContract.timingMode = .easeInEaseOut
                foam.run(SKAction.repeatForever(SKAction.sequence([foamExpand, foamContract])), withKey: "foam1_breathe")
            }
        }

        // --- 3. Tầng sóng giữa (Wave Tier 2 - Chu kỳ 4.3s, lệch pha 1.3s tạo cuộn sóng nối tiếp) ---
        if let tier2 = waveTier2Node {
            tier2.removeAllActions()
            tier2.position = .zero

            let waitDelay = SKAction.wait(forDuration: 1.3)
            let surgeY = SKAction.moveBy(x: 0, y: 6.0 * activeScale, duration: 2.15)
            surgeY.timingMode = .easeInEaseOut
            let recedeY = SKAction.moveBy(x: 0, y: -6.0 * activeScale, duration: 2.15)
            recedeY.timingMode = .easeInEaseOut

            let swayX = SKAction.moveBy(x: -7.0 * activeScale, y: 0, duration: 2.15)
            swayX.timingMode = .easeInEaseOut
            let backX = SKAction.moveBy(x: 7.0 * activeScale, y: 0, duration: 2.15)
            backX.timingMode = .easeInEaseOut

            let rollSeq = SKAction.sequence([waitDelay, SKAction.repeatForever(SKAction.sequence([surgeY, recedeY]))])
            let swaySeq = SKAction.sequence([waitDelay, SKAction.repeatForever(SKAction.sequence([swayX, backX]))])
            tier2.run(rollSeq, withKey: "tier2_rollY")
            tier2.run(swaySeq, withKey: "tier2_swayX")

            if let foam2 = wave2Foam {
                foam2.removeAllActions()
                let fadeBright = SKAction.fadeAlpha(to: 0.18, duration: 2.15)
                fadeBright.timingMode = .easeInEaseOut
                let fadeDim = SKAction.fadeAlpha(to: 0.08, duration: 2.15)
                fadeDim.timingMode = .easeInEaseOut
                foam2.run(SKAction.repeatForever(SKAction.sequence([fadeBright, fadeDim])), withKey: "foam2_fade")
            }
        }

        // --- 4. Tầng sóng gần / bờ (Wave Tier 3 - Chu kỳ 3.6s, lệch pha 2.4s dập dềnh êm dịu) ---
        if let tier3 = waveTier3Node {
            tier3.removeAllActions()
            tier3.position = .zero

            let waitDelay = SKAction.wait(forDuration: 2.4)
            let surgeY = SKAction.moveBy(x: 0, y: 4.8 * activeScale, duration: 1.8)
            surgeY.timingMode = .easeInEaseOut
            let recedeY = SKAction.moveBy(x: 0, y: -4.8 * activeScale, duration: 1.8)
            recedeY.timingMode = .easeInEaseOut

            let swayX = SKAction.moveBy(x: 5.0 * activeScale, y: 0, duration: 1.8)
            swayX.timingMode = .easeInEaseOut
            let backX = SKAction.moveBy(x: -5.0 * activeScale, y: 0, duration: 1.8)
            backX.timingMode = .easeInEaseOut

            let rollSeq = SKAction.sequence([waitDelay, SKAction.repeatForever(SKAction.sequence([surgeY, recedeY]))])
            let swaySeq = SKAction.sequence([waitDelay, SKAction.repeatForever(SKAction.sequence([swayX, backX]))])
            tier3.run(rollSeq, withKey: "tier3_rollY")
            tier3.run(swaySeq, withKey: "tier3_swayX")

            // Bọt sóng bờ trắng xoá (wave3Foam): nhịp thở lung linh
            if let foam3 = wave3Foam {
                foam3.removeAllActions()
                let shimmerUp = SKAction.fadeAlpha(to: 0.42, duration: 1.8)
                shimmerUp.timingMode = .easeInEaseOut
                let shimmerDown = SKAction.fadeAlpha(to: 0.24, duration: 1.8)
                shimmerDown.timingMode = .easeInEaseOut
                foam3.run(SKAction.repeatForever(SKAction.sequence([shimmerUp, shimmerDown])), withKey: "foam3_shimmer")
            }
        }
    }

    // MARK: 2. Hiệu Ứng Mây Bay Nhẹ Nhàng (Gentle Floating Clouds & Mist)

    private func animateCloudsAndMist() {
        // --- 1. Dải sương mây chân núi trái (mistLeft - Layer 24) ---
        if let mL = mistLeft, let rest = restPositions["mistLeft"] {
            mL.removeAllActions()
            mL.position = rest

            let driftRight = SKAction.moveTo(x: rest.x + 16.0 * activeScale, duration: 3.6)
            driftRight.timingMode = .easeInEaseOut
            let driftLeft = SKAction.moveTo(x: rest.x - 16.0 * activeScale, duration: 3.6)
            driftLeft.timingMode = .easeInEaseOut
            mL.run(SKAction.repeatForever(SKAction.sequence([driftRight, driftLeft])), withKey: "mistLeft_driftX")

            let bobUp = SKAction.moveTo(y: rest.y + 2.8 * activeScale, duration: 2.8)
            bobUp.timingMode = .easeInEaseOut
            let bobDown = SKAction.moveTo(y: rest.y - 2.8 * activeScale, duration: 2.8)
            bobDown.timingMode = .easeInEaseOut
            mL.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "mistLeft_bobY")

            let fadeDeep = SKAction.fadeAlpha(to: 0.95, duration: 3.6)
            fadeDeep.timingMode = .easeInEaseOut
            let fadeLight = SKAction.fadeAlpha(to: 0.70, duration: 3.6)
            fadeLight.timingMode = .easeInEaseOut
            mL.run(SKAction.repeatForever(SKAction.sequence([fadeDeep, fadeLight])), withKey: "mistLeft_alpha")
        }

        // --- 2. Dải sương mây chân núi phải (mistRight - Layer 23) ---
        if let mR = mistRight, let rest = restPositions["mistRight"] {
            mR.removeAllActions()
            mR.position = rest

            let driftLeft = SKAction.moveTo(x: rest.x - 15.0 * activeScale, duration: 3.9)
            driftLeft.timingMode = .easeInEaseOut
            let driftRight = SKAction.moveTo(x: rest.x + 15.0 * activeScale, duration: 3.9)
            driftRight.timingMode = .easeInEaseOut
            mR.run(SKAction.repeatForever(SKAction.sequence([driftLeft, driftRight])), withKey: "mistRight_driftX")

            let bobUp = SKAction.moveTo(y: rest.y + 2.5 * activeScale, duration: 3.1)
            bobUp.timingMode = .easeInEaseOut
            let bobDown = SKAction.moveTo(y: rest.y - 2.5 * activeScale, duration: 3.1)
            bobDown.timingMode = .easeInEaseOut
            mR.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])), withKey: "mistRight_bobY")

            let fadeDeep = SKAction.fadeAlpha(to: 0.95, duration: 3.9)
            fadeDeep.timingMode = .easeInEaseOut
            let fadeLight = SKAction.fadeAlpha(to: 0.72, duration: 3.9)
            fadeLight.timingMode = .easeInEaseOut
            mR.run(SKAction.repeatForever(SKAction.sequence([fadeDeep, fadeLight])), withKey: "mistRight_alpha")
        }

        // --- 3. Các vạt mây vàng bồng bềnh uốn lượn quanh Thần Sơn (Layers 15, 17, 19, 21, 22) ---
        let goldenClouds: [(SKSpriteNode?, String, Double, CGFloat, CGFloat)] = [
            (mountainLeftFarMist,  "mountainLeftFarMist",  5.8,  3.5, 2.0),
            (mountainRightFarMist, "mountainRightFarMist", 6.2, -3.5, 2.0),
            (mountainLeftMidMist,  "mountainLeftMidMist",  5.2,  3.0, 1.8),
            (mountainRightMidMist, "mountainRightMidMist", 5.5, -3.0, 1.8),
            (mountainLeftAccent,   "mountainLeftAccent",   4.8,  2.5, 1.5),
        ]

        for (sprite, key, duration, deltaX, deltaY) in goldenClouds {
            guard let s = sprite, let rest = restPositions[key] else { continue }
            s.removeAllActions()
            s.position = rest

            let half = duration / 2.0
            let moveX1 = SKAction.moveTo(x: rest.x + deltaX * activeScale, duration: half)
            moveX1.timingMode = .easeInEaseOut
            let moveX2 = SKAction.moveTo(x: rest.x - deltaX * activeScale, duration: half)
            moveX2.timingMode = .easeInEaseOut
            s.run(SKAction.repeatForever(SKAction.sequence([moveX1, moveX2])), withKey: "\(key)_driftX")

            let moveY1 = SKAction.moveTo(y: rest.y + deltaY * activeScale, duration: half * 0.9)
            moveY1.timingMode = .easeInEaseOut
            let moveY2 = SKAction.moveTo(y: rest.y - deltaY * activeScale, duration: half * 0.9)
            moveY2.timingMode = .easeInEaseOut
            s.run(SKAction.repeatForever(SKAction.sequence([moveY1, moveY2])), withKey: "\(key)_bobY")

            let baseAlpha = s.alpha
            let fadeUp = SKAction.fadeAlpha(to: min(1.0, baseAlpha * 1.25), duration: half * 1.1)
            fadeUp.timingMode = .easeInEaseOut
            let fadeDown = SKAction.fadeAlpha(to: baseAlpha * 0.75, duration: half * 1.1)
            fadeDown.timingMode = .easeInEaseOut
            s.run(SKAction.repeatForever(SKAction.sequence([fadeUp, fadeDown])), withKey: "\(key)_alpha")
        }
    }

    // MARK: 3. Hiệu Ứng Thái Dương & Vệt Nắng Phản Chiếu (Celestial Sun & Water Reflection)

    private func animateSunAndReflection() {
        // --- 1. Thái Dương (sunCore - Layer 25) ---
        if let sun = sunCore {
            sun.removeAllActions()
            sun.setScale(1.0)

            let scaleUp = SKAction.scale(to: 1.03, duration: 2.1)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SKAction.scale(to: 0.985, duration: 2.1)
            scaleDown.timingMode = .easeInEaseOut
            sun.run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])), withKey: "sun_pulse")

            let fadeMax = SKAction.fadeAlpha(to: 1.0, duration: 2.1)
            fadeMax.timingMode = .easeInEaseOut
            let fadeMin = SKAction.fadeAlpha(to: 0.92, duration: 2.1)
            fadeMin.timingMode = .easeInEaseOut
            sun.run(SKAction.repeatForever(SKAction.sequence([fadeMax, fadeMin])), withKey: "sun_alpha")
        }

        // Vầng hào quang (sunAura)
        if let aura = sunAura {
            aura.removeAllActions()
            aura.setScale(1.0)
            let auraExpand = SKAction.scale(to: 1.12, duration: 2.8)
            auraExpand.timingMode = .easeInEaseOut
            let auraContract = SKAction.scale(to: 0.94, duration: 2.8)
            auraContract.timingMode = .easeInEaseOut
            aura.run(SKAction.repeatForever(SKAction.sequence([auraExpand, auraContract])), withKey: "aura_pulse")

            let auraBright = SKAction.fadeAlpha(to: 0.35, duration: 2.8)
            auraBright.timingMode = .easeInEaseOut
            let auraDim = SKAction.fadeAlpha(to: 0.16, duration: 2.8)
            auraDim.timingMode = .easeInEaseOut
            aura.run(SKAction.repeatForever(SKAction.sequence([auraBright, auraDim])), withKey: "aura_alpha")
        }

        // --- 2. Vệt nắng lung linh mặt biển (sunReflection - Layer 26) ---
        if let ref = sunReflection {
            ref.removeAllActions()
            ref.setScale(1.0)

            let stretchX = SKAction.scaleX(to: 1.07, duration: 1.6)
            stretchX.timingMode = .easeInEaseOut
            let narrowX = SKAction.scaleX(to: 0.94, duration: 1.6)
            narrowX.timingMode = .easeInEaseOut
            ref.run(SKAction.repeatForever(SKAction.sequence([stretchX, narrowX])), withKey: "reflection_stretch")

            let refGlint = SKAction.fadeAlpha(to: 0.68, duration: 1.6)
            refGlint.timingMode = .easeInEaseOut
            let refDim = SKAction.fadeAlpha(to: 0.40, duration: 1.6)
            refDim.timingMode = .easeInEaseOut
            ref.run(SKAction.repeatForever(SKAction.sequence([refGlint, refDim])), withKey: "reflection_glint")
        }
    }

    // MARK: 4. Hiệu Ứng Tiên Khí Linh Quang (Mystical Ambient Floating Sparkles)

    private func animateAmbientSparkles() {
        guard let group = sparklesGroupNode else { return }
        group.removeAction(forKey: "sparkle_spawner")

        let spawn = SKAction.run { [weak self, weak group] in
            guard let self = self, let group = group else { return }
            self.spawnSingleSparkle(in: group)
        }
        let wait = SKAction.wait(forDuration: 0.45, withRange: 0.25)
        group.run(SKAction.repeatForever(SKAction.sequence([spawn, wait])), withKey: "sparkle_spawner")
    }

    private func spawnSingleSparkle(in parent: SKNode) {
        let radius = CGFloat.random(in: 1.2...2.6) * activeScale
        let sparkle = SKShapeNode(circleOfRadius: radius)

        // Phối màu tiên khí vàng hoàng kim (#ffff99) & ngọc bích (#c1e7b4)
        let isGolden = Bool.random()
        if isGolden {
            sparkle.fillColor = UIColor(red: 1.0, green: 1.0, blue: 0.60, alpha: 0.90)
        } else {
            sparkle.fillColor = UIColor(red: 0.76, green: 0.91, blue: 0.71, alpha: 0.85)
        }
        sparkle.strokeColor = .clear
        sparkle.glowWidth = radius * 1.2

        // Sinh từ vùng chân núi và mặt biển (Y từ 35% đến 60% màn hình)
        let spawnX = CGFloat.random(in: (containerSize.width * 0.15)...(containerSize.width * 0.85))
        let spawnY = CGFloat.random(in: (containerSize.height * 0.35)...(containerSize.height * 0.58))
        sparkle.position = CGPoint(x: spawnX, y: spawnY)
        sparkle.alpha = 0.0
        sparkle.setScale(0.4)

        parent.addChild(sparkle)

        // Quỹ đạo bay lượn hình sin lên trời
        let driftX = CGFloat.random(in: -25...25) * activeScale
        let riseY = CGFloat.random(in: 55...110) * activeScale
        let duration = Double.random(in: 2.2...3.8)

        let fadeIn = SKAction.fadeAlpha(to: 0.85, duration: duration * 0.25)
        let scaleUp = SKAction.scale(to: 1.0, duration: duration * 0.3)
        let move = SKAction.moveBy(x: driftX, y: riseY, duration: duration)
        move.timingMode = .easeOut

        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: duration * 0.45)
        let scaleDown = SKAction.scale(to: 0.2, duration: duration * 0.45)

        let appear = SKAction.group([fadeIn, scaleUp])
        let disappear = SKAction.group([fadeOut, scaleDown])

        let sequence = SKAction.sequence([appear, SKAction.wait(forDuration: duration * 0.3), disappear, SKAction.removeFromParent()])
        sparkle.run(SKAction.group([move, sequence]))
    }

    // MARK: - 5. Tương Tác Khi Chạm Nền (Interactive Tap Animation)

    public func playTapAnimation(at location: CGPoint) {
        // --- 1. Vòng sóng nước linh quang (Mystical Shimmer Ripple Ring) ---
        if let tapGroup = tapRippleGroupNode {
            let startRadius: CGFloat = 8.0 * activeScale
            let endRadius: CGFloat = CGFloat.random(in: 60...85) * activeScale
            let duration: Double = 0.75

            let ring = SKShapeNode(circleOfRadius: startRadius)
            ring.position = location
            ring.strokeColor = UIColor(red: 1.0, green: 1.0, blue: 0.60, alpha: 0.85)
            ring.fillColor = UIColor(red: 1.0, green: 0.95, blue: 0.60, alpha: 0.12)
            ring.lineWidth = 2.0 * activeScale
            ring.glowWidth = 4.0 * activeScale
            tapGroup.addChild(ring)

            let expand = SKAction.scale(to: endRadius / startRadius, duration: duration)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration)
            fade.timingMode = .easeIn

            ring.run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))

            // Chùm hạt sao tiên toé ra từ điểm chạm
            for _ in 0..<6 {
                let burstParticle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0) * activeScale)
                burstParticle.fillColor = UIColor(red: 1.0, green: 1.0, blue: 0.75, alpha: 0.95)
                burstParticle.strokeColor = .clear
                burstParticle.position = location
                tapGroup.addChild(burstParticle)

                let angle = CGFloat.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 25...55) * activeScale
                let burstMove = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.5)
                burstMove.timingMode = .easeOut
                let burstFade = SKAction.fadeOut(withDuration: 0.5)

                burstParticle.run(SKAction.sequence([SKAction.group([burstMove, burstFade]), SKAction.removeFromParent()]))
            }
        }

        // --- 2. Phản ứng môi trường (Landscape Resonance) ---
        // Thái dương bừng sáng dịu nhẹ
        if let sun = sunCore {
            let flareUp = SKAction.scale(to: 1.08, duration: 0.25)
            flareUp.timingMode = .easeOut
            let flareDown = SKAction.scale(to: 1.0, duration: 0.5)
            flareDown.timingMode = .easeInEaseOut
            sun.run(SKAction.sequence([flareUp, flareDown]), withKey: "sun_tapFlare")
        }

        if let aura = sunAura {
            let auraFlare = SKAction.fadeAlpha(to: 0.55, duration: 0.25)
            let auraBack = SKAction.fadeAlpha(to: 0.25, duration: 0.6)
            aura.run(SKAction.sequence([auraFlare, auraBack]), withKey: "aura_tapFlare")
        }

        // Các tầng sóng biển dâng nhẹ một nhịp phấn khích
        if let waves = wavesGroupNode {
            let lift = SKAction.moveBy(x: 0, y: 3.5 * activeScale, duration: 0.3)
            lift.timingMode = .easeOut
            let settle = SKAction.moveBy(x: 0, y: -3.5 * activeScale, duration: 0.6)
            settle.timingMode = .easeInEaseOut
            waves.run(SKAction.sequence([lift, settle]), withKey: "waves_tapSurge")
        }

        // Mây sương chân núi dạt nhẹ sang hai bên
        if let mL = mistLeft {
            let pushLeft = SKAction.moveBy(x: -8.0 * activeScale, y: 0, duration: 0.35)
            let returnRight = SKAction.moveBy(x: 8.0 * activeScale, y: 0, duration: 0.7)
            mL.run(SKAction.sequence([pushLeft, returnRight]), withKey: "mistLeft_tapPush")
        }
        if let mR = mistRight {
            let pushRight = SKAction.moveBy(x: 8.0 * activeScale, y: 0, duration: 0.35)
            let returnLeft = SKAction.moveBy(x: -8.0 * activeScale, y: 0, duration: 0.7)
            mR.run(SKAction.sequence([pushRight, returnLeft]), withKey: "mistRight_tapPush")
        }
    }

    // MARK: - Helper Texture Loading

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
}

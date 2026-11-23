//
//  Landscape7Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Phong cảnh biển Landscape7, ghép từ 26 lớp của `landscape7.svg`.
/// Giữ tỉ lệ gốc 750 x 500 và aspect-fill toàn viewport: chân trời, mặt biển
/// và bờ cát luôn liền mạch. Scene Editor và fallback dùng cùng một bố cục.
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
        activeScale = min(scaleX, scaleY)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape7Scene.sks
        if let scene = loadSceneTemplate() {
            buildArtwork(scene: scene)
            setupSparklesAndRippleGroups()
            startAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildArtwork(scene: nil)
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

    // MARK: - Shared Scene / Procedural Artwork Layout

    private struct ArtworkLayer {
        let name: String
        let assetId: Int
        let svgRect: CGRect
    }

    // SVG artwork occupies x = 24.827...774.827, y = 0...500.
    // Uniformly enlarge to the 750 x 1334 editor canvas, cropping the sides.
    // At runtime, aspect-fill the source composition without stretching its layers.
    private static let artworkLayers: [ArtworkLayer] = [
        ArtworkLayer(name: "bgNode", assetId: 1, svgRect: CGRect(x: 24.827, y: 0.0, width: 750.0, height: 500.0)),
        ArtworkLayer(name: "seaNode", assetId: 2, svgRect: CGRect(x: 24.827, y: 0.0, width: 750.0, height: 443.663822)),
        ArtworkLayer(name: "seaGlowNode", assetId: 3, svgRect: CGRect(x: 24.827, y: 0.0, width: 750.0, height: 443.663822)),
        ArtworkLayer(name: "wave1Body", assetId: 4, svgRect: CGRect(x: 24.827, y: 396.83536, width: 750.0, height: 103.16464)),
        ArtworkLayer(name: "wave2Body", assetId: 5, svgRect: CGRect(x: 24.827, y: 421.500348, width: 750.0, height: 78.499652)),
        ArtworkLayer(name: "wave2Foam", assetId: 6, svgRect: CGRect(x: 24.827, y: 420.500348, width: 750.0, height: 47.827547)),
        ArtworkLayer(name: "wave3Body", assetId: 7, svgRect: CGRect(x: 24.827, y: 448.417531, width: 750.0, height: 51.582469)),
        ArtworkLayer(name: "wave3Sub", assetId: 8, svgRect: CGRect(x: 24.827, y: 448.417531, width: 750.0, height: 51.582469)),
        ArtworkLayer(name: "wave3Foam", assetId: 9, svgRect: CGRect(x: 24.827, y: 446.66336, width: 750.0, height: 48.582462)),
        ArtworkLayer(name: "wave1Ridge", assetId: 10, svgRect: CGRect(x: 24.827, y: 396.83536, width: 750.0, height: 49.828462)),
        ArtworkLayer(name: "wave1Foam", assetId: 11, svgRect: CGRect(x: 24.827, y: 384.155516, width: 750.0, height: 59.508306)),
        ArtworkLayer(name: "skyNode", assetId: 12, svgRect: CGRect(x: 24.827, y: 0.0, width: 750.0, height: 231.515)),
        ArtworkLayer(name: "seaRipples", assetId: 13, svgRect: CGRect(x: 20.138, y: 291.643039, width: 759.355, height: 140.687232)),
        ArtworkLayer(name: "mountainLeftFar", assetId: 14, svgRect: CGRect(x: 33.827, y: 146.167, width: 310.151, height: 85.348)),
        ArtworkLayer(name: "mountainLeftFarMist", assetId: 15, svgRect: CGRect(x: 106.66, y: 155.473, width: 237.318, height: 76.042)),
        ArtworkLayer(name: "mountainRightFar", assetId: 16, svgRect: CGRect(x: 479.66, y: 138.333, width: 306.386, height: 93.297111)),
        ArtworkLayer(name: "mountainRightFarMist", assetId: 17, svgRect: CGRect(x: 479.66, y: 138.333, width: 303.076, height: 93.182)),
        ArtworkLayer(name: "mountainRightMid", assetId: 18, svgRect: CGRect(x: 491.16, y: 193.833, width: 296.453, height: 37.682)),
        ArtworkLayer(name: "mountainRightMidMist", assetId: 19, svgRect: CGRect(x: 491.16, y: 193.833, width: 242.151, height: 37.682)),
        ArtworkLayer(name: "mountainLeftMid", assetId: 20, svgRect: CGRect(x: 0.0, y: 193.833, width: 342.095, height: 37.797222)),
        ArtworkLayer(name: "mountainLeftMidMist", assetId: 21, svgRect: CGRect(x: 30.135, y: 193.833, width: 274.218, height: 35.544)),
        ArtworkLayer(name: "mountainLeftAccent", assetId: 22, svgRect: CGRect(x: 281.6, y: 203.833, width: 42.271, height: 14.983)),
        ArtworkLayer(name: "mistRight", assetId: 23, svgRect: CGRect(x: 491.070185, y: 231.515, width: 283.756815, height: 31.235)),
        ArtworkLayer(name: "mistLeft", assetId: 24, svgRect: CGRect(x: 57.327, y: 231.515, width: 293.101, height: 35.485)),
        ArtworkLayer(name: "sunCore", assetId: 25, svgRect: CGRect(x: 319.587, y: 130.549, width: 199.181, height: 100.966)),
        ArtworkLayer(name: "sunReflection", assetId: 26, svgRect: CGRect(x: 343.91999, y: 231.63, width: 155.373849, height: 48.258024)),
    ]

    private func buildArtwork(scene: SKScene?) {
        func makeGroup(_ name: String, parent: SKNode) -> SKNode {
            let group = SKNode()
            group.name = name
            parent.addChild(group)
            return group
        }

        let sun = makeGroup("sunGroup", parent: landscapeRootNode)
        let mountains = makeGroup("mountainsGroup", parent: landscapeRootNode)
        let clouds = makeGroup("cloudsGroup", parent: landscapeRootNode)
        let waves = makeGroup("wavesGroup", parent: landscapeRootNode)
        let tier1 = makeGroup("waveTier1", parent: waves)
        let tier2 = makeGroup("waveTier2", parent: waves)
        let tier3 = makeGroup("waveTier3", parent: waves)
        sunGroupNode = sun
        mountainsGroupNode = mountains
        cloudsGroupNode = clouds
        wavesGroupNode = waves
        waveTier1Node = tier1
        waveTier2Node = tier2
        waveTier3Node = tier3

        let artworkScale = max(containerSize.width / 750.0, containerSize.height / 500.0)
        let editorScale = baseDesignHeight / 500.0
        let renderScale = artworkScale / editorScale
        var sprites: [String: SKSpriteNode] = [:]

        for layer in Self.artworkLayers {
            let sprite: SKSpriteNode
            let position: CGPoint
            let designSize: CGSize
            if let scene = scene,
               let template = scene.childNode(withName: "//\(layer.name)") as? SKSpriteNode {
                // Use the editor's position, size and anchor, including parent offsets.
                let scenePosition = template.parent?.convert(template.position, to: scene) ?? template.position
                position = CGPoint(
                    x: containerSize.width / 2.0 + (scenePosition.x + (scene.anchorPoint.x - 0.5) * scene.size.width) * renderScale,
                    y: containerSize.height / 2.0 + (scenePosition.y + (scene.anchorPoint.y - 0.5) * scene.size.height) * renderScale
                )
                designSize = template.size
                template.removeFromParent()
                sprite = template
            } else {
                let rect = layer.svgRect
                position = CGPoint(
                    x: containerSize.width / 2.0 + (rect.midX - 399.827) * artworkScale,
                    y: containerSize.height / 2.0 + (250.0 - rect.midY) * artworkScale
                )
                designSize = CGSize(width: rect.width * editorScale, height: rect.height * editorScale)
                sprite = SKSpriteNode()
                sprite.name = layer.name
            }

            sprite.position = position
            sprite.size = CGSize(width: designSize.width * renderScale, height: designSize.height * renderScale)
            // Alpha is already baked into the exported PNGs. Preserve SVG paint order
            // across groups instead of adding group z offsets or opacity a second time.
            sprite.zPosition = CGFloat(layer.assetId - 1)
            sprite.alpha = 1.0
            if sprite.texture == nil {
                sprite.texture = loadTexture(name: "landscape7-\(layer.assetId)@4.167x")
            }

            let parent: SKNode
            switch layer.name {
            case "sunCore", "sunReflection": parent = sun
            case let name where name.hasPrefix("mountain"): parent = mountains
            case "mistLeft", "mistRight": parent = clouds
            case "seaRipples": parent = waves
            case let name where name.hasPrefix("wave1"): parent = tier1
            case let name where name.hasPrefix("wave2"): parent = tier2
            case let name where name.hasPrefix("wave3"): parent = tier3
            default: parent = landscapeRootNode
            }
            parent.addChild(sprite)
            sprites[layer.name] = sprite
            restPositions[layer.name] = position
        }

        self.bgNode = sprites["bgNode"]
        self.seaNode = sprites["seaNode"]
        self.seaGlowNode = sprites["seaGlowNode"]
        self.wave1Body = sprites["wave1Body"]
        self.wave2Body = sprites["wave2Body"]
        self.wave2Foam = sprites["wave2Foam"]
        self.wave3Body = sprites["wave3Body"]
        self.wave3Sub = sprites["wave3Sub"]
        self.wave3Foam = sprites["wave3Foam"]
        self.wave1Ridge = sprites["wave1Ridge"]
        self.wave1Foam = sprites["wave1Foam"]
        self.skyNode = sprites["skyNode"]
        self.seaRipples = sprites["seaRipples"]
        self.mountainLeftFar = sprites["mountainLeftFar"]
        self.mountainLeftFarMist = sprites["mountainLeftFarMist"]
        self.mountainRightFar = sprites["mountainRightFar"]
        self.mountainRightFarMist = sprites["mountainRightFarMist"]
        self.mountainRightMid = sprites["mountainRightMid"]
        self.mountainRightMidMist = sprites["mountainRightMidMist"]
        self.mountainLeftMid = sprites["mountainLeftMid"]
        self.mountainLeftMidMist = sprites["mountainLeftMidMist"]
        self.mountainLeftAccent = sprites["mountainLeftAccent"]
        self.mistRight = sprites["mistRight"]
        self.mistLeft = sprites["mistLeft"]
        self.sunCore = sprites["sunCore"]
        self.sunReflection = sprites["sunReflection"]
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
                let fadeBright = SKAction.fadeAlpha(to: 1.0, duration: 2.15)
                fadeBright.timingMode = .easeInEaseOut
                let fadeDim = SKAction.fadeAlpha(to: 0.85, duration: 2.15)
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
                let shimmerUp = SKAction.fadeAlpha(to: 1.0, duration: 1.8)
                shimmerUp.timingMode = .easeInEaseOut
                let shimmerDown = SKAction.fadeAlpha(to: 0.85, duration: 1.8)
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

        // --- 2. Vệt nắng lung linh mặt biển (sunReflection - Layer 26) ---
        if let ref = sunReflection {
            ref.removeAllActions()
            ref.setScale(1.0)

            let stretchX = SKAction.scaleX(to: 1.07, duration: 1.6)
            stretchX.timingMode = .easeInEaseOut
            let narrowX = SKAction.scaleX(to: 0.94, duration: 1.6)
            narrowX.timingMode = .easeInEaseOut
            ref.run(SKAction.repeatForever(SKAction.sequence([stretchX, narrowX])), withKey: "reflection_stretch")

            let refGlint = SKAction.fadeAlpha(to: 1.0, duration: 1.6)
            refGlint.timingMode = .easeInEaseOut
            let refDim = SKAction.fadeAlpha(to: 0.85, duration: 1.6)
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

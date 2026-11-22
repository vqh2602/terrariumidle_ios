//
//  Landscape5Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 5: "Mưa đêm giông bão" (landscape5)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape5Scene.sks` (có Fallback Procedural độc lập)
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thành phần & Phân tầng Z-Index Chuẩn:
///   1. `bgNode` (z = 0): Bầu trời đêm giông bão u tối huyền bí (`landscape5-bg-1@4.167x`)
///   2. `lightningOverlay` (z = 8): Lớp phủ chớp sấm sét môi trường khi chạm hoặc định kỳ giông bão
///   3. `cloudsGroupNode` (z = 20): 7 loại mây đen giông bão cuồn cuộn (`landscape5-2` ... `landscape5-8`)
///      - Trôi dạt mềm mại đồng nhất theo hướng GIÓ THỔI VỀ BÊN TRÁI ($v_x < 0$)
///      - Nhấp nhô bồng bềnh trục Y & thở Opacity mờ ảo giông bão
///      - Tự động Wrap-around tuần hoàn từ mép trái sang mép phải màn hình
///   4. `rainGroupNode` (z = 15 & z = 35): Hệ thống mưa tí tách đa tầng với 2 loại hạt mưa:
///      - Hạt mưa xanh đậm (`landscape5-rain-9@4.167x`)
///      - Hạt mưa xanh nhạt (`landscape5-rain-10@4.167x`)
///      - Phối hợp hài hòa 50/50 ở cả 2 tầng xa/gần
///      - Rơi chéo nghiêng về bên trái khớp chính xác với góc nghiêng nghệ thuật của asset hạt mưa
///   5. `splashGroupNode` (z = 40): Hiệu ứng giọt nước chạm đáy toé bọt nước li ti và gợn sóng xanh
public final class Landscape5Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Cloud Metadata Definition

    struct CloudData {
        let index: Int
        let texName: String
        let relativeX: CGFloat // Tỉ lệ 0.0 ... 1.0 trên bề rộng màn hình
        let relativeY: CGFloat // Tỉ lệ 0.0 ... 1.0 trên chiều cao màn hình
        let size: CGSize
        let zPos: CGFloat
        let alpha: CGFloat
        let baseSpeed: CGFloat
        let windSensitivity: CGFloat
    }

    /// 7 loại mây đen giông bão với tỉ lệ kích thước tự nhiên đúng chuẩn asset
    private static let cloudPresets: [CloudData] = [
        CloudData(index: 1, texName: "landscape5-2@4.167x", relativeX: 0.85, relativeY: 0.90, size: CGSize(width: 320, height: 168), zPos: 21.0, alpha: 0.92, baseSpeed: 18.0, windSensitivity: 1.1),
        CloudData(index: 2, texName: "landscape5-3@4.167x", relativeX: 0.25, relativeY: 0.85, size: CGSize(width: 300, height: 158), zPos: 22.0, alpha: 0.88, baseSpeed: 22.0, windSensitivity: 1.2),
        CloudData(index: 3, texName: "landscape5-4@4.167x", relativeX: 0.92, relativeY: 0.77, size: CGSize(width: 280, height: 128), zPos: 23.0, alpha: 0.95, baseSpeed: 15.0, windSensitivity: 0.9),
        CloudData(index: 4, texName: "landscape5-5@4.167x", relativeX: 0.45, relativeY: 0.71, size: CGSize(width: 270, height: 124), zPos: 24.0, alpha: 0.90, baseSpeed: 25.0, windSensitivity: 1.3),
        CloudData(index: 5, texName: "landscape5-6@4.167x", relativeX: 0.10, relativeY: 0.63, size: CGSize(width: 230, height: 145), zPos: 22.0, alpha: 0.85, baseSpeed: 19.0, windSensitivity: 1.0),
        CloudData(index: 6, texName: "landscape5-7@4.167x", relativeX: 0.72, relativeY: 0.56, size: CGSize(width: 260, height: 131), zPos: 23.0, alpha: 0.92, baseSpeed: 23.0, windSensitivity: 1.15),
        CloudData(index: 7, texName: "landscape5-8@4.167x", relativeX: 0.35, relativeY: 0.49, size: CGSize(width: 330, height: 142), zPos: 21.0, alpha: 0.86, baseSpeed: 16.0, windSensitivity: 0.95),
    ]

    // MARK: - Rain Drop Model

    private enum RainDropType {
        case darkBlue   // landscape5-rain-9 (xanh đậm)
        case lightBlue  // landscape5-rain-10 (xanh nhạt)
    }

    private final class RainDropItem {
        let sprite: SKSpriteNode
        let type: RainDropType
        var baseSpeedY: CGFloat
        var speedFactor: CGFloat
        var isForeground: Bool

        init(sprite: SKSpriteNode, type: RainDropType, baseSpeedY: CGFloat, speedFactor: CGFloat, isForeground: Bool) {
            self.sprite = sprite
            self.type = type
            self.baseSpeedY = baseSpeedY
            self.speedFactor = speedFactor
            self.isForeground = isForeground
        }
    }

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private let landscapeRootNode = SKNode()

    // Layer Nodes
    private var bgNode: SKSpriteNode?
    private var lightningOverlay: SKSpriteNode?
    private var cloudsGroupNode: SKNode?
    private var rainGroupNode: SKNode?
    private var splashGroupNode: SKNode?

    // Cloud Components
    private struct ActiveCloud {
        let node: SKNode
        let sprite: SKSpriteNode
        let baseSpeed: CGFloat
        let windSensitivity: CGFloat
        let initialRelativeY: CGFloat
    }
    private var activeClouds: [ActiveCloud] = []

    // Rain Components (2 loại texture xanh đậm & xanh nhạt)
    private var rainDrops: [RainDropItem] = []
    private var rainDarkTexture: SKTexture?
    private var rainLightTexture: SKTexture?

    // Unified Leftward Wind System (Gió CHỈ thổi về bên trái vx < 0)
    private var elapsedTime: TimeInterval = 0.0
    private var currentWindFactor: CGFloat = -0.75 // Luôn âm [ -1.0 ... -0.45 ]
    private var gustOffset: CGFloat = 0.0
    private let maxRainWindSpeed: CGFloat = 280.0  // Tốc độ dạt ngang tối đa của mưa sang trái
    private let maxCloudWindDrift: CGFloat = 36.0 // Tốc độ dạt ngang của mây sang trái
    /// Góc nghiêng gốc của asset ảnh mưa (khoảng -0.336 rad ~ -19.3 độ nghiêng sang trái)
    private let naturalRainAngle: CGFloat = -0.336

    // Tỉ lệ scale so với canvas thiết kế chuẩn (1080 x 1920)
    private let baseDesignWidth: CGFloat = 1080.0
    private let baseDesignHeight: CGFloat = 1920.0
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
        lightningOverlay = nil
        cloudsGroupNode = nil
        rainGroupNode = nil
        splashGroupNode = nil
        activeClouds.removeAll()
        rainDrops.removeAll()

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Scale fit dọc màn hình (Aspect Fill bao phủ toàn màn hình)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // Cache 2 loại rain texture (xanh đậm 9 & xanh nhạt 10)
        rainDarkTexture = loadTexture(name: "landscape5-rain-9@4.167x")
        rainLightTexture = loadTexture(name: "landscape5-rain-10@4.167x")

        // 1. Lớp phủ chớp sấm sét (Lightning Overlay)
        buildLightningOverlay()

        // 2. Nhóm váng nước chạm sàn (Splashes)
        let splashGroup = SKNode()
        splashGroup.zPosition = 40.0
        landscapeRootNode.addChild(splashGroup)
        self.splashGroupNode = splashGroup

        // 3. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape5Scene.sks
        if let scene = loadSceneTemplate() {
            buildFromSceneTemplate(scene: scene)
            buildRainSystem()
            startWeatherSimulation()
            return
        }

        // 4. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildProceduralFallback()
        buildRainSystem()
        startWeatherSimulation()
    }

    // MARK: - Lightning Overlay

    private func buildLightningOverlay() {
        let overlay = SKSpriteNode(color: UIColor(red: 0.78, green: 0.88, blue: 1.0, alpha: 1.0), size: containerSize)
        overlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        overlay.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        overlay.zPosition = 8.0
        overlay.alpha = 0.0
        landscapeRootNode.addChild(overlay)
        self.lightningOverlay = overlay
    }

    // MARK: - Build from Scene Template

    private func buildFromSceneTemplate(scene: SKScene) {
        // 1. Nạp bgNode (z = 0)
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
            let fillW = max(containerSize.width, baseDesignWidth * activeScale)
            let fillH = max(containerSize.height, baseDesignHeight * activeScale)
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            if let realBgTex = loadTexture(name: "landscape5-bg-1@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // 2. Nạp cloudsGroup: nạp 7 đám mây đen từ scene template
        let cloudsGroup = SKNode()
        cloudsGroup.name = "cloudsGroup"
        cloudsGroup.position = .zero
        cloudsGroup.zPosition = 20.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        for (idx, preset) in Self.cloudPresets.enumerated() {
            let cloudNodeName = "cloud_\(idx + 1)"
            let cloudSprite: SKSpriteNode
            if let sceneClouds = scene.childNode(withName: "cloudsGroup"),
               let existing = sceneClouds.childNode(withName: cloudNodeName) as? SKSpriteNode {
                existing.removeFromParent()
                cloudSprite = existing
            } else {
                cloudSprite = SKSpriteNode()
                cloudSprite.name = cloudNodeName
            }

            if let tex = loadTexture(name: preset.texName) {
                cloudSprite.texture = tex
            }
            cloudSprite.size = CGSize(width: preset.size.width * activeScale, height: preset.size.height * activeScale)
            cloudSprite.alpha = preset.alpha
            cloudSprite.zPosition = 0.0

            let slot = SKNode()
            slot.name = "slot_\(idx + 1)"
            let initialX = preset.relativeX * containerSize.width
            let initialY = preset.relativeY * containerSize.height
            slot.position = CGPoint(x: initialX, y: initialY)
            slot.zPosition = preset.zPos
            cloudsGroup.addChild(slot)
            slot.addChild(cloudSprite)

            let item = ActiveCloud(
                node: slot,
                sprite: cloudSprite,
                baseSpeed: preset.baseSpeed,
                windSensitivity: preset.windSensitivity,
                initialRelativeY: preset.relativeY
            )
            activeClouds.append(item)

            // Nhấp nhô bồng bềnh trục Y & Opacity breathing
            animateCloudBobbing(cloudSprite, index: idx)
            animateCloudBreathing(cloudSprite, baseAlpha: preset.alpha, index: idx)
        }
    }

    // MARK: - Procedural Fallback

    private func buildProceduralFallback() {
        // 1. Nền bầu trời đêm giông bão u tối
        let fillW = max(containerSize.width, baseDesignWidth * activeScale)
        let fillH = max(containerSize.height, baseDesignHeight * activeScale)
        let bgTex = loadTexture(name: "landscape5-bg-1@4.167x")
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillW, height: fillH))
        bg.name = "bgNode"
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // 2. Nhóm 7 đám mây đen giông bão
        let cloudsGroup = SKNode()
        cloudsGroup.name = "cloudsGroup"
        cloudsGroup.position = .zero
        cloudsGroup.zPosition = 20.0
        landscapeRootNode.addChild(cloudsGroup)
        self.cloudsGroupNode = cloudsGroup

        for (idx, preset) in Self.cloudPresets.enumerated() {
            let slot = SKNode()
            slot.name = "slot_\(idx + 1)"
            let initialX = preset.relativeX * containerSize.width
            let initialY = preset.relativeY * containerSize.height
            slot.position = CGPoint(x: initialX, y: initialY)
            slot.zPosition = preset.zPos
            cloudsGroup.addChild(slot)

            let cloudTex = loadTexture(name: preset.texName)
            let cloud = SKSpriteNode(texture: cloudTex, size: CGSize(width: preset.size.width * activeScale, height: preset.size.height * activeScale))
            cloud.name = "cloud_\(idx + 1)"
            cloud.position = .zero
            cloud.alpha = preset.alpha
            cloud.zPosition = 0.0
            slot.addChild(cloud)

            let item = ActiveCloud(
                node: slot,
                sprite: cloud,
                baseSpeed: preset.baseSpeed,
                windSensitivity: preset.windSensitivity,
                initialRelativeY: preset.relativeY
            )
            activeClouds.append(item)

            animateCloudBobbing(cloud, index: idx)
            animateCloudBreathing(cloud, baseAlpha: preset.alpha, index: idx)
        }
    }

    // MARK: - Raindrop System (2 loại hạt mưa xanh đậm & xanh nhạt phối chung)

    private func buildRainSystem() {
        let rainGroup = SKNode()
        rainGroup.name = "rainGroup"
        rainGroup.position = .zero
        rainGroup.zPosition = 15.0
        landscapeRootNode.addChild(rainGroup)
        self.rainGroupNode = rainGroup

        // Số lượng hạt mưa dày dặn tạo không khí giông bão bao trùm (88 hạt)
        let totalRainDrops = 88
        let screenW = containerSize.width
        let screenH = containerSize.height

        for i in 0..<totalRainDrops {
            let isForeground = (i % 2 == 0) // 50% tiền cảnh (rõ nét), 50% hậu cảnh (mờ xa)
            // Phối xen kẽ 50% xanh đậm (rain-9) và 50% xanh nhạt (rain-10) tạo chiều sâu chuyển sắc phong phú
            let isDarkBlue = (i % 4 == 0 || i % 4 == 3)
            let dropType: RainDropType = isDarkBlue ? .darkBlue : .lightBlue
            let texture = isDarkBlue ? rainDarkTexture : rainLightTexture

            // Kích thước vệt mưa chuẩn theo asset 26x55
            let dropW: CGFloat = isForeground ? CGFloat.random(in: 8.5...12.0) * activeScale : CGFloat.random(in: 5.5...8.0) * activeScale
            let dropH: CGFloat = isForeground ? CGFloat.random(in: 22.0...34.0) * activeScale : CGFloat.random(in: 14.0...22.0) * activeScale
            let dropAlpha: CGFloat = isForeground ? CGFloat.random(in: 0.80...0.96) : CGFloat.random(in: 0.42...0.65)
            let zPos: CGFloat = isForeground ? 35.0 : 15.0

            let sprite = SKSpriteNode(texture: texture, size: CGSize(width: dropW, height: dropH))
            sprite.name = "rainDrop_\(i)"
            sprite.alpha = dropAlpha
            sprite.zPosition = zPos

            // Khởi tạo vị trí ngẫu nhiên (mở rộng biên X sang phải để đón hạt mưa bay chéo sang trái)
            let startX = CGFloat.random(in: -40.0...(screenW + 180.0))
            let startY = CGFloat.random(in: 0.0...(screenH + 120.0))
            sprite.position = CGPoint(x: startX, y: startY)

            // Vận tốc rơi tự do
            let baseSpeedY: CGFloat = isForeground ? CGFloat.random(in: 920.0...1250.0) : CGFloat.random(in: 650.0...880.0)
            let speedFactor: CGFloat = CGFloat.random(in: 0.90...1.10)

            rainGroup.addChild(sprite)

            let dropItem = RainDropItem(
                sprite: sprite,
                type: dropType,
                baseSpeedY: baseSpeedY,
                speedFactor: speedFactor,
                isForeground: isForeground
            )
            rainDrops.append(dropItem)
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Landscape5Scene")
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

    // MARK: - Animations & Simulation Loop (Gió CHỈ thổi về bên trái)

    private func startWeatherSimulation() {
        landscapeRootNode.removeAction(forKey: "weatherLoop")

        var lastTime = CACurrentMediaTime()

        let loopAction = SKAction.repeatForever(SKAction.customAction(withDuration: 1.0) { [weak self] (_, _) in
            guard let self = self else { return }

            let now = CACurrentMediaTime()
            let dt = min(0.06, CGFloat(now - lastTime))
            lastTime = now

            self.updateWeather(dt: dt)
        })

        landscapeRootNode.run(loopAction, withKey: "weatherLoop")
    }

    /// Cập nhật chu kỳ GIÓ LUÔN THỔI VỀ BÊN TRÁI (vx < 0) và đồng nhất với mây đen + hạt mưa
    private func updateWeather(dt: CGFloat) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        elapsedTime += Double(dt)

        // 1. Tính toán chu kỳ gió thổi về bên trái (Leftward Wind Only):
        // Giá trị gió luôn âm: dao động tự nhiên trong khoảng [-0.95 ... -0.60]
        let t = elapsedTime
        let naturalLeftWind = -0.76 + CGFloat(sin(t * 0.22) * 0.14 + sin(t * 0.45 + 0.8) * 0.08)

        // Suy giảm dần gió giật sau khi chạm (Gust Damping)
        gustOffset *= 0.965

        // Gió tổng hợp bị chặn chỉ được âm (luôn thổi về bên trái)
        currentWindFactor = min(-0.45, max(-1.25, naturalLeftWind + gustOffset))

        // Vận tốc ngang của mưa (luôn âm: rơi nghiêng sang trái)
        let rainVelocityX = currentWindFactor * maxRainWindSpeed
        let screenW = containerSize.width
        let screenH = containerSize.height

        // 2. CẬP NHẬT HỆ THỐNG MƯA
        for drop in rainDrops {
            let dropSprite = drop.sprite
            let vx = rainVelocityX * drop.speedFactor
            let vy = -drop.baseSpeedY

            // Di chuyển hạt mưa theo vector vận tốc
            dropSprite.position.x += vx * dt
            dropSprite.position.y += vy * dt

            // Tính góc nghiêng quỹ đạo thực tế (luôn âm)
            let trajectoryAngle = atan2(vx, -vy)
            // Bù góc nghệ thuật sẵn có của asset ảnh (-0.336 rad) để vệt hạt mưa luôn song song 100% với quỹ đạo bay
            dropSprite.zRotation = trajectoryAngle - naturalRainAngle

            // Khi hạt mưa chạm hoặc vượt qua đáy màn hình:
            if dropSprite.position.y < -30.0 {
                // Tạo toé nước ngẫu nhiên tại vị trí tiếp đất của các hạt mưa trước
                if drop.isForeground && CGFloat.random(in: 0...1) < 0.25 {
                    let splashColor: UIColor = (drop.type == .darkBlue)
                        ? UIColor(red: 0.25, green: 0.45, blue: 0.78, alpha: 0.85)
                        : UIColor(red: 0.42, green: 0.65, blue: 0.95, alpha: 0.90)
                    spawnWaterSplash(at: CGPoint(x: dropSprite.position.x, y: CGFloat.random(in: 6.0...26.0)), color: splashColor)
                }

                // Reset hạt mưa lên trên đỉnh màn hình (offset sang phải để gió thổi bay vào giữa màn hình)
                dropSprite.position.y = screenH + CGFloat.random(in: 10.0...80.0)
                let spawnRightMargin = maxRainWindSpeed * 0.6
                dropSprite.position.x = CGFloat.random(in: -20.0...(screenW + spawnRightMargin))
            }

            // Wrap quanh trục X: nếu hạt mưa bị gió tạt bay lệch quá mép trái, đưa về mép phải
            if dropSprite.position.x < -80.0 {
                dropSprite.position.x = screenW + CGFloat.random(in: 20.0...80.0)
            }
        }

        // 3. CẬP NHẬT TRÔI DẠT CỦA 7 ĐÁM MÂY ĐEN VỀ PHÍA BÊN TRÁI
        let windDriftSpeed = abs(currentWindFactor) * maxCloudWindDrift

        for cloud in activeClouds {
            // Mây luôn trôi dạt về phía bên trái (v < 0)
            let totalSpeed = (cloud.baseSpeed + windDriftSpeed * cloud.windSensitivity) * activeScale
            cloud.node.position.x -= totalSpeed * dt

            let cloudW = cloud.sprite.size.width
            // Khi toàn bộ mây trôi hết qua mép trái màn hình:
            if cloud.node.position.x < -(cloudW / 2.0 + 30.0) {
                // Wrap-around tuần hoàn về mép phải màn hình
                cloud.node.position.x = screenW + (cloudW / 2.0) + CGFloat.random(in: 10.0...50.0)
                // Nhẹ nhàng biến thiên toạ độ Y quanh vị trí chuẩn
                let yJitter = CGFloat.random(in: -12.0...12.0) * activeScale
                cloud.node.position.y = cloud.initialRelativeY * screenH + yJitter
            }
        }
    }

    // MARK: - Cloud Secondary Animations (Nhấp nhô Y & Opacity giông bão)

    private func animateCloudBobbing(_ cloud: SKSpriteNode, index: Int) {
        let dur = 3.8 + Double(index % 4) * 0.75
        let dy = (4.0 + CGFloat(index % 3) * 2.0) * activeScale

        let up = SKAction.moveBy(x: 0, y: dy, duration: dur)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveBy(x: 0, y: -dy, duration: dur)
        down.timingMode = .easeInEaseOut

        cloud.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "cloudBobbing")
    }

    private func animateCloudBreathing(_ cloud: SKSpriteNode, baseAlpha: CGFloat, index: Int) {
        let dur = 4.2 + Double(index % 3) * 0.9
        let minAlpha = max(0.68, baseAlpha * 0.88)
        let maxAlpha = min(1.0, baseAlpha * 1.05)

        let fadeOut = SKAction.fadeAlpha(to: minAlpha, duration: dur)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: maxAlpha, duration: dur)
        fadeIn.timingMode = .easeInEaseOut

        cloud.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])), withKey: "cloudBreathing")
    }

    // MARK: - Water Splash & Ripples (Giọt nước toé đáy sàn)

    private func spawnWaterSplash(at location: CGPoint, color: UIColor = UIColor(red: 0.35, green: 0.58, blue: 0.88, alpha: 0.85)) {
        guard let splashGroup = splashGroupNode else { return }

        // 1. Gợn sóng elip li ti loang nhẹ
        let ripple = SKShapeNode(ellipseOf: CGSize(width: 14.0 * activeScale, height: 6.0 * activeScale))
        ripple.position = location
        ripple.strokeColor = color
        ripple.fillColor = .clear
        ripple.lineWidth = 1.2
        ripple.alpha = 0.85
        splashGroup.addChild(ripple)

        let expand = SKAction.scaleX(to: 2.4, y: 2.0, duration: 0.28)
        let fadeOut = SKAction.fadeOut(withDuration: 0.28)
        let remove = SKAction.removeFromParent()
        ripple.run(SKAction.sequence([SKAction.group([expand, fadeOut]), remove]))

        // 2. Các hạt nước nhỏ toé lên
        let count = Int.random(in: 2...4)
        for _ in 0..<count {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.0...1.8) * activeScale)
            spark.position = location
            spark.fillColor = color
            spark.strokeColor = .clear
            splashGroup.addChild(spark)

            let dx = CGFloat.random(in: -12.0...4.0) * activeScale // Nghiêng nhẹ sang trái theo chiều gió
            let dy = CGFloat.random(in: 5.0...16.0) * activeScale
            let fly = SKAction.moveBy(x: dx, y: dy, duration: 0.22)
            fly.timingMode = .easeOut
            let fall = SKAction.moveBy(x: dx * 0.5, y: -dy * 0.7, duration: 0.16)
            fall.timingMode = .easeIn
            let sparkFade = SKAction.fadeOut(withDuration: 0.38)

            spark.run(SKAction.sequence([SKAction.group([SKAction.sequence([fly, fall]), sparkFade]), remove]))
        }
    }

    // MARK: - Tap Interaction (Chớp Sấm Sét Giông Bão, Gió Giật Sang Trái, Toé Nước)

    public func playTapAnimation(at location: CGPoint) {
        // 1. Chớp sấm sét môi trường soi sáng bầu trời đêm
        triggerLightning()

        // 2. Gió giật mạnh hơn sang bên trái (Gust Leftward)
        gustOffset = -0.55

        // 3. Toé nước tại vị trí chạm tay
        spawnWaterSplash(at: location, color: UIColor(red: 0.50, green: 0.75, blue: 1.0, alpha: 0.95))

        // 4. Kiểm tra xem có chạm trúng đám mây nào không
        for cloud in activeClouds {
            let cloudBox = CGRect(
                x: cloud.node.position.x - cloud.sprite.size.width / 2.0,
                y: cloud.node.position.y - cloud.sprite.size.height / 2.0,
                width: cloud.sprite.size.width,
                height: cloud.sprite.size.height
            )
            if cloudBox.contains(location) {
                // Mây nhún nảy đàn hồi khi chạm
                let jiggleUp = SKAction.scale(to: 1.12, duration: 0.12)
                let jiggleDown = SKAction.scale(to: 0.94, duration: 0.16)
                let jiggleBack = SKAction.scale(to: 1.0, duration: 0.20)
                cloud.sprite.run(SKAction.sequence([jiggleUp, jiggleDown, jiggleBack]))
                break
            }
        }
    }

    /// Kích hoạt chuỗi hiệu ứng sấm sét chớp nháy tự nhiên
    public func triggerLightning() {
        guard let overlay = lightningOverlay else { return }
        overlay.removeAction(forKey: "lightning")

        // Chuỗi chớp nháy: Bừng sáng đợt 1 -> Hơi mờ -> Bừng sáng đợt 2 -> Tắt dần
        let flash1 = SKAction.fadeAlpha(to: 0.72, duration: 0.05)
        let dip = SKAction.fadeAlpha(to: 0.15, duration: 0.06)
        let flash2 = SKAction.fadeAlpha(to: 0.88, duration: 0.04)
        let fadeOut = SKAction.fadeOut(withDuration: 0.38)
        fadeOut.timingMode = .easeOut

        overlay.run(SKAction.sequence([flash1, dip, flash2, fadeOut]), withKey: "lightning")
    }
}

//
//  Landscape3Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 3: "Ban công mưa bão" (landscape3 / rain / sky_rain)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape3Scene.sks` (có Fallback Procedural độc lập)
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thành phần & Phân tầng:
///   1. `bgNode` (z = 0): Nền trời mưa u ám huyền ảo (`landscape3-1@4.167x`)
///   2. `lightningOverlay` (z = 5): Lớp phủ chớp sấm sét môi trường khi chạm hoặc giông bão
///   3. `cloudsGroupNode` (z = 20): Các đám mây giông bão (`landscape3-cloud-2`, `cloud-3`, `cloud-4`)
///      - Trôi dạt mềm mại theo hướng gió tức thời (Dynamic Wind Drift)
///      - Nhấp nhô bồng bềnh trục Y & thở Opacity mờ ảo giông bão
///   4. `rainGroupNode` (z = 15 & z = 35): Hệ thống mưa tí tách đa tầng sinh từ ảnh hạt mưa `landscape3-rain@4.167x`
///      - Tự sinh nhiều hạt mưa rơi liên tục bao phủ toàn màn hình
///      - Di chuyển rơi nghiêng chéo: lúc rơi sang trái, lúc rơi sang phải, lúc rơi thẳng
///      - Đồng nhất 1:1 giữa hướng gió, độ nghiêng vệt mưa và vận tốc trôi của mây
///      - Hiệu ứng giọt nước chạm đáy toé sóng li ti (Rain Splashes / Ripples)
public final class Landscape3Node: SKNode, LandscapeInteractiveNode {

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

    private static let cloudPresets: [CloudData] = [
        CloudData(index: 1, texName: "landscape3-cloud-4@4.167x", relativeX: 0.25, relativeY: 0.88, size: CGSize(width: 320, height: 64), zPos: 21.0, alpha: 0.85, baseSpeed: 16.0, windSensitivity: 1.1),
        CloudData(index: 2, texName: "landscape3-cloud-2@4.167x", relativeX: 0.75, relativeY: 0.84, size: CGSize(width: 250, height: 70), zPos: 22.0, alpha: 0.90, baseSpeed: 20.0, windSensitivity: 1.2),
        CloudData(index: 3, texName: "landscape3-cloud-3@4.167x", relativeX: 0.12, relativeY: 0.76, size: CGSize(width: 230, height: 65), zPos: 23.0, alpha: 0.82, baseSpeed: 14.0, windSensitivity: 0.9),
        CloudData(index: 4, texName: "landscape3-cloud-4@4.167x", relativeX: 0.60, relativeY: 0.72, size: CGSize(width: 350, height: 70), zPos: 24.0, alpha: 0.92, baseSpeed: 24.0, windSensitivity: 1.3),
        CloudData(index: 5, texName: "landscape3-cloud-2@4.167x", relativeX: 0.88, relativeY: 0.64, size: CGSize(width: 240, height: 68), zPos: 22.0, alpha: 0.80, baseSpeed: 18.0, windSensitivity: 1.0),
        CloudData(index: 6, texName: "landscape3-cloud-3@4.167x", relativeX: 0.38, relativeY: 0.58, size: CGSize(width: 260, height: 72), zPos: 23.0, alpha: 0.88, baseSpeed: 22.0, windSensitivity: 1.15),
        CloudData(index: 7, texName: "landscape3-cloud-4@4.167x", relativeX: 0.82, relativeY: 0.52, size: CGSize(width: 290, height: 62), zPos: 21.0, alpha: 0.78, baseSpeed: 15.0, windSensitivity: 0.95),
    ]

    // MARK: - Rain Drop Model

    private final class RainDropItem {
        let sprite: SKSpriteNode
        var baseSpeedY: CGFloat
        var speedFactor: CGFloat
        var isForeground: Bool

        init(sprite: SKSpriteNode, baseSpeedY: CGFloat, speedFactor: CGFloat, isForeground: Bool) {
            self.sprite = sprite
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

    // Rain Components
    private var rainDrops: [RainDropItem] = []
    private var rainTexture: SKTexture?

    // Unified Weather Wind System
    private var elapsedTime: TimeInterval = 0.0
    private var currentWindFactor: CGFloat = 0.0 // [-1.0 ... 1.0]
    private var gustOffset: CGFloat = 0.0
    private let maxRainWindSpeed: CGFloat = 260.0 // Tốc độ dạt ngang tối đa của mưa
    private let maxCloudWindDrift: CGFloat = 38.0 // Tốc độ dạt ngang của mây do gió

    // Tỉ lệ scale so với canvas thiết kế chuẩn (1085 x 2145)
    private let baseDesignWidth: CGFloat = 1085.0
    private let baseDesignHeight: CGFloat = 2145.0
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

        // Scale fit dọc màn hình (Aspect Fill)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // Cache rain texture
        rainTexture = loadTexture(name: "landscape3-rain@4.167x")

        // 1. Lớp phủ chớp sấm sét (Lightning Overlay)
        buildLightningOverlay()

        // 2. Nhóm váng nước chạm sàn (Splashes)
        let splashGroup = SKNode()
        splashGroup.zPosition = 40.0
        landscapeRootNode.addChild(splashGroup)
        self.splashGroupNode = splashGroup

        // 3. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape3Scene.sks
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
        let overlay = SKSpriteNode(color: UIColor(red: 0.82, green: 0.90, blue: 1.0, alpha: 1.0), size: containerSize)
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
            let fillW = max(containerSize.width, 1085.0 * activeScale)
            let fillH = max(containerSize.height, 2145.0 * activeScale)
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            if let realBgTex = loadTexture(name: "landscape3-1@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // 2. Nạp cloudsGroup: nạp các đám mây từ scene template
        if let cloudsGroup = scene.childNode(withName: "cloudsGroup") {
            cloudsGroup.removeFromParent()
            cloudsGroup.position = .zero
            cloudsGroup.zPosition = 20.0
            landscapeRootNode.addChild(cloudsGroup)
            self.cloudsGroupNode = cloudsGroup

            for (idx, preset) in Self.cloudPresets.enumerated() {
                let cloudNodeName = "cloud_\(idx + 1)"
                let cloudSprite: SKSpriteNode
                if let existing = cloudsGroup.childNode(withName: cloudNodeName) as? SKSpriteNode {
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
    }

    // MARK: - Procedural Fallback

    private func buildProceduralFallback() {
        // 1. Nền bầu trời mưa u ám
        let fillW = max(containerSize.width, 1085.0 * activeScale)
        let fillH = max(containerSize.height, 2145.0 * activeScale)
        let bgTex = loadTexture(name: "landscape3-1@4.167x")
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillW, height: fillH))
        bg.name = "bgNode"
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // 2. Nhóm mây giông
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

    // MARK: - Raindrop System (Tự tạo nhiều hạt mưa từ ảnh 1 hạt mưa gốc)

    private func buildRainSystem() {
        let rainGroup = SKNode()
        rainGroup.name = "rainGroup"
        rainGroup.position = .zero
        rainGroup.zPosition = 15.0
        landscapeRootNode.addChild(rainGroup)
        self.rainGroupNode = rainGroup

        // Số lượng hạt mưa phù hợp tạo màn mưa sinh động, mượt mà (75-90 hạt)
        let totalRainDrops = 84
        let screenW = containerSize.width
        let screenH = containerSize.height

        for i in 0..<totalRainDrops {
            let isForeground = (i % 2 == 0) // Nửa lớp trước (rõ), nửa lớp sau (mờ)

            // Kích thước vệt mưa:
            // Ảnh gốc 4x427, scale thanh mảnh dài khoảng 40-90pt
            let dropW: CGFloat = isForeground ? CGFloat.random(in: 2.0...2.8) : CGFloat.random(in: 1.2...1.8)
            let dropH: CGFloat = isForeground ? CGFloat.random(in: 65.0...100.0) : CGFloat.random(in: 38.0...60.0)
            let dropAlpha: CGFloat = isForeground ? CGFloat.random(in: 0.65...0.88) : CGFloat.random(in: 0.30...0.48)
            let zPos: CGFloat = isForeground ? 35.0 : 15.0

            let sprite = SKSpriteNode(texture: rainTexture, size: CGSize(width: dropW, height: dropH))
            sprite.name = "rainDrop_\(i)"
            sprite.alpha = dropAlpha
            sprite.zPosition = zPos

            // Khởi tạo vị trí ngẫu nhiên phủ khắp toàn màn hình (mở rộng biên X để khi gió tạt chéo không hở mép)
            let startX = CGFloat.random(in: -100.0...(screenW + 100.0))
            let startY = CGFloat.random(in: 0.0...(screenH + 100.0))
            sprite.position = CGPoint(x: startX, y: startY)

            // Vận tốc rơi tự do
            let baseSpeedY: CGFloat = isForeground ? CGFloat.random(in: 950.0...1280.0) : CGFloat.random(in: 680.0...920.0)
            let speedFactor: CGFloat = CGFloat.random(in: 0.90...1.10)

            rainGroup.addChild(sprite)

            let dropItem = RainDropItem(
                sprite: sprite,
                baseSpeedY: baseSpeedY,
                speedFactor: speedFactor,
                isForeground: isForeground
            )
            rainDrops.append(dropItem)
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Landscape3Scene")
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

    // MARK: - Animations & Simulation Loop (Đồng nhất Mây và Mưa)

    private func startWeatherSimulation() {
        landscapeRootNode.removeAction(forKey: "weatherLoop")

        // Sử dụng SpriteKit Frame Loop đồng bộ 100% với Scene Engine
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

    /// Cập nhật thời gian thực chu kỳ gió, độ nghiêng của mưa và hướng trôi của mây
    private func updateWeather(dt: CGFloat) {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        elapsedTime += Double(dt)

        // 1. Tính toán chu kỳ gió tự nhiên (Dynamic Wind Cycle):
        // Kết hợp 2 hàm sóng điều hoà chu kỳ dài (~36s và ~16s) tạo sự chuyển đổi mượt mà giữa:
        // Gió sang phải (dương) -> Lặng gió (0) -> Gió sang trái (âm) -> Đổi chiều
        let t = elapsedTime
        let naturalWind = CGFloat(sin(t * 0.16) * 0.72 + sin(t * 0.38 + 1.2) * 0.28)

        // Suy giảm dần gió giật sau khi tương tác chạm (Gust Damping)
        gustOffset *= 0.965

        // Gió tổng hợp bị giới hạn chuẩn [-1.0 ... 1.0]
        currentWindFactor = max(-1.0, min(1.0, naturalWind + gustOffset))

        // Vận tốc ngang của mưa và mây theo chiều gió
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

            // Tính góc nghiêng của vệt mưa đồng nhất với quỹ đạo rơi:
            // vx > 0 (gió sang phải) -> vệt mưa nghiêng sang phải (zRotation > 0)
            // vx < 0 (gió sang trái) -> vệt mưa nghiêng sang trái (zRotation < 0)
            let rainAngle = atan2(vx, -vy)
            dropSprite.zRotation = rainAngle

            // Khi hạt mưa chạm hoặc vượt qua đáy màn hình:
            if dropSprite.position.y < -30.0 {
                // Tạo toé nước ngẫu nhiên tại vị trí tiếp đất của các hạt mưa trước
                if drop.isForeground && CGFloat.random(in: 0...1) < 0.22 {
                    spawnWaterSplash(at: CGPoint(x: dropSprite.position.x, y: CGFloat.random(in: 8.0...28.0)))
                }

                // Reset hạt mưa lên trên đỉnh màn hình (mở rộng vùng rơi để mưa bao phủ kín)
                dropSprite.position.y = screenH + CGFloat.random(in: 10.0...80.0)
                // Offset điểm sinh ngược hướng gió để hạt mưa bay vào màn hình tự nhiên
                let windMargin = maxRainWindSpeed * 0.4
                dropSprite.position.x = CGFloat.random(in: (-windMargin)...(screenW + windMargin))
            }

            // Wrap quanh trục X nếu gió tạt quá mạnh ra ngoài biên ngang
            if dropSprite.position.x < -140.0 && vx < 0 {
                dropSprite.position.x = screenW + 120.0
            } else if dropSprite.position.x > screenW + 140.0 && vx > 0 {
                dropSprite.position.x = -120.0
            }
        }

        // 3. CẬP NHẬT CHUYỂN ĐỘNG CỦA MÂY (Đồng nhất hướng với mưa)
        for cloud in activeClouds {
            let slot = cloud.node
            let cloudW = max(cloud.sprite.size.width, 180.0)

            // Vận tốc mây = độ trôi tự nhiên + độ trôi đẩy theo hướng gió
            let cloudVx = (cloud.baseSpeed * 0.25 + currentWindFactor * maxCloudWindDrift * cloud.windSensitivity) * activeScale
            slot.position.x += cloudVx * dt

            // Khi mây trôi vượt mép phải: vòng lại mép trái
            if slot.position.x > screenW + cloudW * 0.65 && cloudVx > 0 {
                slot.position.x = -cloudW * 0.65
                // Đổi nhẹ độ cao tự nhiên
                let deltaY = CGFloat.random(in: -15.0...15.0)
                let baseTargetY = cloud.initialRelativeY * screenH
                slot.position.y = max(screenH * 0.40, min(screenH * 0.95, baseTargetY + deltaY))
            }
            // Khi mây trôi vượt mép trái: vòng lại mép phải
            else if slot.position.x < -cloudW * 0.65 && cloudVx < 0 {
                slot.position.x = screenW + cloudW * 0.65
                let deltaY = CGFloat.random(in: -15.0...15.0)
                let baseTargetY = cloud.initialRelativeY * screenH
                slot.position.y = max(screenH * 0.40, min(screenH * 0.95, baseTargetY + deltaY))
            }
        }
    }

    // MARK: - Cloud Secondary Animations

    private func animateCloudBobbing(_ cloud: SKSpriteNode, index: Int) {
        let bobDist: CGFloat = 5.0 + CGFloat(index % 3) * 2.0
        let dur = 3.6 + Double(index % 4) * 0.8

        let up = SKAction.moveTo(y: bobDist, duration: dur)
        up.timingMode = .easeInEaseOut
        let down = SKAction.moveTo(y: -bobDist, duration: dur)
        down.timingMode = .easeInEaseOut

        let delay = SKAction.wait(forDuration: Double(index % 4) * 0.5)
        let loop = SKAction.repeatForever(SKAction.sequence([up, down]))
        cloud.run(SKAction.sequence([delay, loop]), withKey: "cloudBobbing")
    }

    private func animateCloudBreathing(_ cloud: SKSpriteNode, baseAlpha: CGFloat, index: Int) {
        let dur = 4.2 + Double(index % 3) * 1.0
        let minAlpha = max(0.55, baseAlpha * 0.82)
        let maxAlpha = min(1.0, baseAlpha * 1.06)

        let fadeOut = SKAction.fadeAlpha(to: minAlpha, duration: dur)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: maxAlpha, duration: dur)
        fadeIn.timingMode = .easeInEaseOut

        let delay = SKAction.wait(forDuration: Double((index + 2) % 4) * 0.6)
        let loop = SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn]))
        cloud.run(SKAction.sequence([delay, loop]), withKey: "cloudBreathing")
    }

    // MARK: - Water Splash & Ripple (Toé nước khi mưa chạm đáy)

    private func spawnWaterSplash(at location: CGPoint) {
        guard let splashGroup = splashGroupNode else { return }

        // Vòng sóng nước loang rộng
        let ripple = SKShapeNode(ellipseOf: CGSize(width: 6, height: 3))
        ripple.position = location
        ripple.strokeColor = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.65)
        ripple.fillColor = .clear
        ripple.lineWidth = 1.0
        splashGroup.addChild(ripple)

        let expand = SKAction.scaleX(to: 3.8, y: 2.2, duration: 0.28)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.28)
        let remove = SKAction.removeFromParent()
        ripple.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))

        // 2 giọt nước bắn li ti toé lên
        for dx in [-3.5, 3.5] {
            let droplet = SKShapeNode(circleOfRadius: 0.9)
            droplet.position = location
            droplet.fillColor = UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 0.75)
            droplet.strokeColor = .clear
            splashGroup.addChild(droplet)

            let jump = SKAction.moveBy(x: dx, y: CGFloat.random(in: 4.0...9.0), duration: 0.22)
            jump.timingMode = .easeOut
            let dropFade = SKAction.fadeOut(withDuration: 0.22)
            droplet.run(SKAction.sequence([SKAction.group([jump, dropFade]), SKAction.removeFromParent()]))
        }
    }

    // MARK: - Tap Interaction (Chớp Sấm Sét, Gió Giật & Gợn Nước)

    public func playTapAnimation(at location: CGPoint) {
        // 1. Tạo luồng gió giật tức thời (Gust) theo vị trí chạm:
        // Chạm bên trái màn hình -> gió thổi sang phải; chạm bên phải -> gió thổi sang trái
        let screenW = containerSize.width
        if location.x < screenW * 0.45 {
            gustOffset = min(0.85, gustOffset + 0.65) // Đẩy gió sang phải
        } else if location.x > screenW * 0.55 {
            gustOffset = max(-0.85, gustOffset - 0.65) // Đẩy gió sang trái
        } else {
            // Chạm ở giữa: đảo chiều gió hiện tại
            gustOffset = (currentWindFactor >= 0) ? -0.60 : 0.60
        }

        // 2. Chớp sấm sét giông bão (Lightning Flash)
        playLightningFlash()

        // 3. Kiểm tra xem có chạm gần đám mây nào không
        var hitCloud: ActiveCloud?
        var minDistance: CGFloat = 110.0 * activeScale
        for cloud in activeClouds {
            let worldX = cloud.node.position.x
            let worldY = cloud.node.position.y
            let dist = hypot(location.x - worldX, location.y - worldY)
            if dist < minDistance {
                minDistance = dist
                hitCloud = cloud
            }
        }

        if let hit = hitCloud {
            // Mây rung nhún đàn hồi khi chạm
            let hopUp = SKAction.moveBy(x: 0, y: 14, duration: 0.18)
            hopUp.timingMode = .easeOut
            let hopDown = SKAction.moveBy(x: 0, y: -14, duration: 0.28)
            hopDown.timingMode = .easeInEaseOut
            hit.sprite.run(SKAction.sequence([hopUp, hopDown]))

            // Chớp điện tích bên trong đám mây
            let flash = SKAction.fadeAlpha(to: 1.0, duration: 0.10)
            let restore = SKAction.fadeAlpha(to: 0.85, duration: 0.35)
            hit.sprite.run(SKAction.sequence([flash, restore]))
        }

        // 4. Bung toả vòng sóng nước mưa lớn tại điểm chạm
        spawnTapWaterRipples(at: location)
    }

    /// Hiệu ứng chớp sấm sét môi trường giông bão
    private func playLightningFlash() {
        guard let overlay = lightningOverlay else { return }
        overlay.removeAction(forKey: "lightningFlash")

        // 2 nhịp chớp giật liên tiếp chuẩn hiện tượng sét đánh
        let flash1 = SKAction.fadeAlpha(to: 0.45, duration: 0.05)
        let dim1 = SKAction.fadeAlpha(to: 0.15, duration: 0.07)
        let flash2 = SKAction.fadeAlpha(to: 0.60, duration: 0.04)
        let dim2 = SKAction.fadeAlpha(to: 0.0, duration: 0.32)
        dim2.timingMode = .easeOut

        overlay.run(SKAction.sequence([flash1, dim1, flash2, dim2]), withKey: "lightningFlash")
    }

    /// Bung toả vòng sóng nước mưa tại điểm chạm
    private func spawnTapWaterRipples(at location: CGPoint) {
        guard let splashGroup = splashGroupNode else { return }

        for i in 0..<2 {
            let ripple = SKShapeNode(circleOfRadius: 10)
            ripple.position = location
            ripple.strokeColor = UIColor(red: 0.80, green: 0.90, blue: 1.0, alpha: 0.85)
            ripple.fillColor = UIColor(red: 0.60, green: 0.78, blue: 0.95, alpha: 0.15)
            ripple.lineWidth = 2.0
            splashGroup.addChild(ripple)

            let delay = SKAction.wait(forDuration: Double(i) * 0.14)
            let expand = SKAction.scale(to: CGFloat(3.5 + Double(i) * 1.5), duration: 0.55)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.55)
            let group = SKAction.group([expand, fade])
            let remove = SKAction.removeFromParent()

            ripple.run(SKAction.sequence([delay, group, remove]))
        }

        // Sinh 6 hạt nước li ti bung toả tròn
        for _ in 0..<6 {
            let droplet = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.8))
            droplet.position = location
            droplet.fillColor = UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 0.90)
            droplet.strokeColor = .clear
            splashGroup.addChild(droplet)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 25.0...65.0)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let dur = Double.random(in: 0.35...0.60)

            let move = SKAction.moveBy(x: dx, y: dy, duration: dur)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: dur)
            let scale = SKAction.scale(to: 0.2, duration: dur)
            let group = SKAction.group([move, fade, scale])
            droplet.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
}

//
//  Landscape4Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 4: "Ban công trời sao" (landscape4 / moon_night / sky_moon_night)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape4Scene.sks` (ăn theo vị trí mới của moon & overlay từ scene)
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thứ tự Z-Index Chuẩn xác theo Yêu cầu:
///   1. `bgNode` (z = 0): Nền trời đêm huyền ảo (`landscape4-BG@4.167x`)
///   2. `overlayNode` (z = 10): Lớp phủ sương mây đêm mờ ảo (`landscape4-overlay@4.167x`) - ăn theo vị trí mới từ scene
///   3. `starsGroup` (z = 20): Hệ thống sao lấp lánh đa tầng, 3 sao tròn điểm nhấn (`landscape4-215`, `216`, `217`) & Sao băng
///      - Hiệu ứng Blink có giãn cách nghỉ ngẫu nhiên, không chớp liên tục
///      - Kích thước các ngôi sao được tăng to rõ nét, lung linh
///   4. `moonGroup` (z = 30): Mặt trăng to ra theo đúng thiết kế scene kèm hào quang ánh trăng dịu êm
public final class Landscape4Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Star Preset Definition

    struct StarPreset {
        let texName: String
        let relativeX: CGFloat // 0.0 ... 1.0 bề rộng màn hình
        let relativeY: CGFloat // 0.0 ... 1.0 chiều cao màn hình
        let displaySize: CGSize
        let baseAlpha: CGFloat
        let minPause: Double
        let maxPause: Double
        let isFocalRoundStar: Bool
        let isLargeFourRayStar: Bool
    }

    private static let starPresets: [StarPreset] = [
        // ==========================================
        // 🌟 1. BA NGÔI SAO TRÒN ĐIỂM NHẤN (FOCAL ROUND STARS: 215, 216, 217)
        // ==========================================
        StarPreset(texName: "landscape4-215@4.167x", relativeX: 0.28, relativeY: 0.84, displaySize: CGSize(width: 34, height: 35), baseAlpha: 0.98, minPause: 1.8, maxPause: 3.6, isFocalRoundStar: true, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-217@4.167x", relativeX: 0.82, relativeY: 0.72, displaySize: CGSize(width: 30, height: 30), baseAlpha: 0.95, minPause: 1.5, maxPause: 3.2, isFocalRoundStar: true, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-216@4.167x", relativeX: 0.48, relativeY: 0.88, displaySize: CGSize(width: 24, height: 22), baseAlpha: 0.92, minPause: 2.0, maxPause: 4.0, isFocalRoundStar: true, isLargeFourRayStar: false),
        // Điểm nhấn sao tròn bổ trợ tạo chùm sao cân xứng
        StarPreset(texName: "landscape4-215@4.167x", relativeX: 0.68, relativeY: 0.62, displaySize: CGSize(width: 28, height: 29), baseAlpha: 0.90, minPause: 2.2, maxPause: 4.2, isFocalRoundStar: true, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-217@4.167x", relativeX: 0.14, relativeY: 0.60, displaySize: CGSize(width: 26, height: 26), baseAlpha: 0.88, minPause: 1.6, maxPause: 3.8, isFocalRoundStar: true, isLargeFourRayStar: false),

        // ==========================================
        // ✨ 2. CÁC NGÔI SAO LỚN 4 CÁNH (Tăng kích thước rõ nét, lung linh)
        // ==========================================
        StarPreset(texName: "landscape4-101@4.167x", relativeX: 0.18, relativeY: 0.89, displaySize: CGSize(width: 46, height: 46), baseAlpha: 0.95, minPause: 2.0, maxPause: 4.5, isFocalRoundStar: false, isLargeFourRayStar: true),
        StarPreset(texName: "landscape4-54@4.167x",  relativeX: 0.86, relativeY: 0.86, displaySize: CGSize(width: 48, height: 48), baseAlpha: 0.95, minPause: 2.4, maxPause: 5.0, isFocalRoundStar: false, isLargeFourRayStar: true),
        StarPreset(texName: "landscape4-103@4.167x", relativeX: 0.40, relativeY: 0.76, displaySize: CGSize(width: 42, height: 42), baseAlpha: 0.92, minPause: 1.8, maxPause: 4.2, isFocalRoundStar: false, isLargeFourRayStar: true),

        // ==========================================
        // 💫 3. CÁC NGÔI SAO VỪA (115x115 -> size 30-34pt)
        // ==========================================
        StarPreset(texName: "landscape4-95@4.167x",  relativeX: 0.32, relativeY: 0.93, displaySize: CGSize(width: 32, height: 32), baseAlpha: 0.88, minPause: 1.5, maxPause: 3.5, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-99@4.167x",  relativeX: 0.62, relativeY: 0.80, displaySize: CGSize(width: 34, height: 34), baseAlpha: 0.90, minPause: 1.7, maxPause: 3.8, isFocalRoundStar: false, isLargeFourRayStar: false),

        // ==========================================
        // 🌟 4. CÁC NGÔI SAO TRUNG BÌNH (71x71 -> size 22-26pt)
        // ==========================================
        StarPreset(texName: "landscape4-96@4.167x",  relativeX: 0.10, relativeY: 0.78, displaySize: CGSize(width: 24, height: 24), baseAlpha: 0.85, minPause: 1.4, maxPause: 3.2, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-98@4.167x",  relativeX: 0.92, relativeY: 0.76, displaySize: CGSize(width: 25, height: 25), baseAlpha: 0.85, minPause: 1.6, maxPause: 3.6, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-102@4.167x", relativeX: 0.24, relativeY: 0.70, displaySize: CGSize(width: 22, height: 22), baseAlpha: 0.80, minPause: 2.0, maxPause: 4.0, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-180@4.167x", relativeX: 0.54, relativeY: 0.70, displaySize: CGSize(width: 24, height: 24), baseAlpha: 0.82, minPause: 1.5, maxPause: 3.4, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-182@4.167x", relativeX: 0.76, relativeY: 0.66, displaySize: CGSize(width: 23, height: 23), baseAlpha: 0.80, minPause: 1.8, maxPause: 3.8, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-183@4.167x", relativeX: 0.06, relativeY: 0.68, displaySize: CGSize(width: 24, height: 24), baseAlpha: 0.85, minPause: 1.4, maxPause: 3.0, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-185@4.167x", relativeX: 0.90, relativeY: 0.58, displaySize: CGSize(width: 25, height: 25), baseAlpha: 0.82, minPause: 1.7, maxPause: 3.5, isFocalRoundStar: false, isLargeFourRayStar: false),

        // ==========================================
        // 🔹 5. CÁC NGÔI SAO NHỎ (Tăng từ 7pt lên 16-19pt để rõ nét lung linh)
        // ==========================================
        StarPreset(texName: "landscape4-184@4.167x", relativeX: 0.20, relativeY: 0.58, displaySize: CGSize(width: 18, height: 18), baseAlpha: 0.78, minPause: 1.2, maxPause: 2.8, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-186@4.167x", relativeX: 0.38, relativeY: 0.62, displaySize: CGSize(width: 17, height: 17), baseAlpha: 0.75, minPause: 1.4, maxPause: 3.0, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-187@4.167x", relativeX: 0.60, relativeY: 0.56, displaySize: CGSize(width: 18, height: 18), baseAlpha: 0.78, minPause: 1.3, maxPause: 2.9, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-188@4.167x", relativeX: 0.82, relativeY: 0.52, displaySize: CGSize(width: 17, height: 17), baseAlpha: 0.72, minPause: 1.6, maxPause: 3.2, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-189@4.167x", relativeX: 0.12, relativeY: 0.50, displaySize: CGSize(width: 18, height: 18), baseAlpha: 0.75, minPause: 1.5, maxPause: 3.0, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-190@4.167x", relativeX: 0.36, relativeY: 0.46, displaySize: CGSize(width: 16, height: 16), baseAlpha: 0.70, minPause: 1.7, maxPause: 3.4, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-191@4.167x", relativeX: 0.52, relativeY: 0.44, displaySize: CGSize(width: 17, height: 17), baseAlpha: 0.72, minPause: 1.3, maxPause: 2.8, isFocalRoundStar: false, isLargeFourRayStar: false),
        StarPreset(texName: "landscape4-192@4.167x", relativeX: 0.76, relativeY: 0.42, displaySize: CGSize(width: 16, height: 16), baseAlpha: 0.68, minPause: 1.5, maxPause: 3.2, isFocalRoundStar: false, isLargeFourRayStar: false)
    ]

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private let landscapeRootNode = SKNode()

    // Layer Nodes theo đúng thứ tự Index:
    // 1. bgNode (z = 0)
    private var bgNode: SKSpriteNode?
    // 2. overlayNode (z = 10)
    private var overlayNode: SKSpriteNode?
    // 3. starsGroup (z = 20)
    private var starsGroupNode: SKNode?
    private var shootingStarsNode: SKNode?
    // 4. moonGroup (z = 30)
    private var moonGroupNode: SKNode?
    private var moonNode: SKSpriteNode?

    // Star Sprites for Animation
    private var starSprites: [SKSpriteNode] = []

    // Tỉ lệ scale so với canvas thiết kế chuẩn trong Landscape4Scene.sks (1150 x 2071)
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
        overlayNode = nil
        starsGroupNode = nil
        shootingStarsNode = nil
        moonGroupNode = nil
        moonNode = nil
        starSprites.removeAll()

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Scale fit dọc màn hình (Aspect Fill)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape4Scene.sks (Ăn theo vị trí mới của moon & overlay)
        if let scene = loadSceneTemplate() {
            buildFromSceneTemplate(scene: scene)
            startAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildProceduralFallback()
        startAnimations()
    }

    // MARK: - 1. Build from Scene Template (Ăn theo toạ độ scene editor)

    private func buildFromSceneTemplate(scene: SKScene) {
        // --- 1. bgNode (z = 0) ---
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
            let fillW = max(containerSize.width, baseDesignWidth * activeScale)
            let fillH = max(containerSize.height, baseDesignHeight * activeScale)
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            if let realBgTex = loadTexture(name: "landscape4-BG@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // --- 2. overlayNode (z = 10) - Ăn theo toạ độ & kích thước người dùng đã kéo trong Scene Editor ---
        if let overlay = scene.childNode(withName: "overlayNode") as? SKSpriteNode {
            overlay.removeFromParent()
            overlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)

            // Chuẩn hoá toạ độ từ canvas thiết kế (1150 x 2071, anchor 0.5, 0.5) sang containerSize thực tế
            let normOverlayX = (overlay.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normOverlayY = (overlay.position.y / baseDesignHeight + 0.5) * containerSize.height
            overlay.position = CGPoint(x: normOverlayX, y: normOverlayY)

            let overlayW = max(containerSize.width, overlay.size.width * activeScale)
            let overlayH = overlay.size.height * activeScale
            overlay.size = CGSize(width: overlayW, height: overlayH)
            overlay.zPosition = 10.0
            overlay.alpha = 0.88
            if let overlayTex = loadTexture(name: "landscape4-overlay@4.167x") {
                overlay.texture = overlayTex
            }
            landscapeRootNode.addChild(overlay)
            self.overlayNode = overlay
        }

        // --- 3. starsGroup (z = 20) ---
        let starsGroup = SKNode()
        starsGroup.name = "starsGroup"
        starsGroup.position = .zero
        starsGroup.zPosition = 20.0
        landscapeRootNode.addChild(starsGroup)
        self.starsGroupNode = starsGroup

        // Node chứa các vệt sao băng bay qua
        let shootingGroup = SKNode()
        shootingGroup.name = "shootingStarsGroup"
        shootingGroup.zPosition = 25.0
        landscapeRootNode.addChild(shootingGroup)
        self.shootingStarsNode = shootingGroup

        // Nạp danh sách sao
        for (idx, preset) in Self.starPresets.enumerated() {
            let starName = "star_\(idx + 1)"
            let starSprite = SKSpriteNode()
            starSprite.name = starName

            if let tex = loadTexture(name: preset.texName) {
                starSprite.texture = tex
            }
            let baseW = preset.displaySize.width * activeScale
            let baseH = preset.displaySize.height * activeScale
            starSprite.size = CGSize(width: baseW, height: baseH)
            starSprite.position = CGPoint(x: preset.relativeX * containerSize.width, y: preset.relativeY * containerSize.height)
            starSprite.alpha = preset.baseAlpha * 0.40
            starSprite.zPosition = 20.0 + CGFloat(idx) * 0.1

            // Quầng sáng dịu cho 3 sao tròn điểm nhấn
            if preset.isFocalRoundStar {
                let halo = SKShapeNode(circleOfRadius: baseW * 0.65)
                halo.name = "starHalo"
                halo.fillColor = UIColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 0.25)
                halo.strokeColor = .clear
                halo.glowWidth = 6.5 * activeScale
                halo.zPosition = -1.0
                starSprite.addChild(halo)
            }

            starsGroup.addChild(starSprite)
            starSprites.append(starSprite)
        }

        // --- 4. moonGroup (z = 30) - Ăn theo toạ độ & Mặt trăng to ra đúng theo thiết kế Scene ---
        if let moonGroup = scene.childNode(withName: "moonGroup") {
            moonGroup.removeFromParent()

            // Chuẩn hoá toạ độ moonGroup từ canvas thiết kế
            let normMoonX = (moonGroup.position.x / baseDesignWidth + 0.5) * containerSize.width
            let normMoonY = (moonGroup.position.y / baseDesignHeight + 0.5) * containerSize.height
            moonGroup.position = CGPoint(x: normMoonX, y: normMoonY)
            moonGroup.setScale(activeScale)
            moonGroup.zPosition = 30.0
            landscapeRootNode.addChild(moonGroup)
            self.moonGroupNode = moonGroup

            // Nạp moonNode con bên trong moonGroup (Texture đã chứa sẵn vầng sáng tự nhiên tinh tế)
            if let moonNode = moonGroup.childNode(withName: "moonNode") as? SKSpriteNode {
                if let realMoonTex = loadTexture(name: "landscape4-moon@4.167x") {
                    moonNode.texture = realMoonTex
                }
                moonNode.zPosition = 30.0
                self.moonNode = moonNode
            }
        } else {
            buildMoonGroupProcedural()
        }
    }

    // MARK: - 2. Procedural Fallback (Dựa trên thông số chuẩn của scene)

    private func buildProceduralFallback() {
        // --- 1. bgNode (z = 0) ---
        let fillW = max(containerSize.width, baseDesignWidth * activeScale)
        let fillH = max(containerSize.height, baseDesignHeight * activeScale)
        let bgTex = loadTexture(name: "landscape4-BG@4.167x")
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillW, height: fillH))
        bg.name = "bgNode"
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // --- 2. overlayNode (z = 10) - Vị trí mới chuẩn từ scene: pos Y = 196.0, size: 1150 x 1679 ---
        let overlayTex = loadTexture(name: "landscape4-overlay@4.167x")
        let normOverlayX = containerSize.width / 2.0
        let normOverlayY = (196.0 / baseDesignHeight + 0.5) * containerSize.height
        let overlayW = max(containerSize.width, 1150.0 * activeScale)
        let overlayH = 1679.0 * activeScale
        let overlay = SKSpriteNode(texture: overlayTex, size: CGSize(width: overlayW, height: overlayH))
        overlay.name = "overlayNode"
        overlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        overlay.position = CGPoint(x: normOverlayX, y: normOverlayY)
        overlay.zPosition = 10.0
        overlay.alpha = 0.88
        landscapeRootNode.addChild(overlay)
        self.overlayNode = overlay

        // --- 3. starsGroup (z = 20) ---
        let starsGroup = SKNode()
        starsGroup.name = "starsGroup"
        starsGroup.position = .zero
        starsGroup.zPosition = 20.0
        landscapeRootNode.addChild(starsGroup)
        self.starsGroupNode = starsGroup

        let shootingGroup = SKNode()
        shootingGroup.name = "shootingStarsGroup"
        shootingGroup.zPosition = 25.0
        landscapeRootNode.addChild(shootingGroup)
        self.shootingStarsNode = shootingGroup

        for (idx, preset) in Self.starPresets.enumerated() {
            let tex = loadTexture(name: preset.texName)
            let baseW = preset.displaySize.width * activeScale
            let baseH = preset.displaySize.height * activeScale
            let star = SKSpriteNode(texture: tex, size: CGSize(width: baseW, height: baseH))
            star.name = "star_\(idx + 1)"
            star.position = CGPoint(x: preset.relativeX * containerSize.width, y: preset.relativeY * containerSize.height)
            star.alpha = preset.baseAlpha * 0.40
            star.zPosition = 20.0 + CGFloat(idx) * 0.1

            if preset.isFocalRoundStar {
                let halo = SKShapeNode(circleOfRadius: baseW * 0.65)
                halo.name = "starHalo"
                halo.fillColor = UIColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 0.25)
                halo.strokeColor = .clear
                halo.glowWidth = 6.5 * activeScale
                halo.zPosition = -1.0
                star.addChild(halo)
            }

            starsGroup.addChild(star)
            starSprites.append(star)
        }

        // --- 4. moonGroup (z = 30) - Mặt trăng to ra theo đúng thiết kế Scene ---
        buildMoonGroupProcedural()
    }

    // MARK: - 4. Moon Group Procedural (Chuẩn toạ độ & kích thước to của Scene: pos (255, 861.5), size 302x309)

    private func buildMoonGroupProcedural() {
        let moonGroup = SKNode()
        moonGroup.name = "moonGroup"

        // Toạ độ từ scene: moonGroup pos = (255, 861.5)
        let normMoonX = (255.0 / baseDesignWidth + 0.5) * containerSize.width
        let normMoonY = (861.5 / baseDesignHeight + 0.5) * containerSize.height
        moonGroup.position = CGPoint(x: normMoonX, y: normMoonY)
        moonGroup.setScale(activeScale)
        moonGroup.zPosition = 30.0
        landscapeRootNode.addChild(moonGroup)
        self.moonGroupNode = moonGroup

        // Mặt trăng to ra đúng kích thước thiết kế scene: 302 x 309, pos con: (43.0, -64.2)
        if let moonTex = loadTexture(name: "landscape4-moon@4.167x") {
            let moonSize = CGSize(width: 302.0, height: 309.0)
            let moon = SKSpriteNode(texture: moonTex, size: moonSize)
            moon.name = "moonNode"
            moon.position = CGPoint(x: 43.0, y: -64.2)
            moon.zPosition = 30.0
            moonGroup.addChild(moon)
            self.moonNode = moon
        }
    }

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {
        return SKScene(fileNamed: "Landscape4Scene")
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

    // MARK: - Animations (Sao Blink Giãn Cách, Sao Băng, Trăng Thở)

    private func startAnimations() {
        // 1. Hoạt ảnh lớp overlay sương đêm trôi lãng đãng quanh toạ độ mới
        if let overlay = overlayNode {
            startOverlayDrifting(overlay: overlay)
        }

        // 2. Hoạt ảnh Sao Blink Nhấp Nháy có Giãn Cách Ngẫu Nhiên
        for (idx, star) in starSprites.enumerated() {
            let preset = Self.starPresets[min(idx, Self.starPresets.count - 1)]
            startStarBlinkAnimation(star: star, preset: preset, index: idx)
        }

        // 3. Chu kỳ Sao băng định kỳ
        startShootingStarsScheduler()

        // 4. Hoạt ảnh Ánh trăng lung linh & Dao động trôi lững lờ
        if let moon = moonNode {
            startMoonBreathing(moon: moon)
        }
        if let moonGroup = moonGroupNode {
            startMoonFloatingBobbing(moonGroup: moonGroup)
        }
    }

    // MARK: - Overlay Breathing & Drift

    private func startOverlayDrifting(overlay: SKSpriteNode) {
        overlay.removeAction(forKey: "overlayDrift")
        let moveLeft = SKAction.moveBy(x: -20.0 * activeScale, y: 5.0, duration: 6.8)
        moveLeft.timingMode = .easeInEaseOut
        let moveRight = SKAction.moveBy(x: 20.0 * activeScale, y: -5.0, duration: 6.8)
        moveRight.timingMode = .easeInEaseOut

        let fadeLow = SKAction.fadeAlpha(to: 0.76, duration: 5.2)
        fadeLow.timingMode = .easeInEaseOut
        let fadeHigh = SKAction.fadeAlpha(to: 0.94, duration: 5.2)
        fadeHigh.timingMode = .easeInEaseOut

        let driftLoop = SKAction.repeatForever(SKAction.sequence([moveLeft, moveRight]))
        let fadeLoop = SKAction.repeatForever(SKAction.sequence([fadeLow, fadeHigh]))

        overlay.run(SKAction.group([driftLoop, fadeLoop]), withKey: "overlayDrift")
    }

    // MARK: - Star Blink Animation (Nhấp Nháy Có Giãn Cách Nghỉ)

    /// Hoạt ảnh Blink chuẩn bầu trời sao: Trạng thái nghỉ dịu -> Đột ngột chớp sáng rực rỡ -> Nghỉ giãn cách ngẫu nhiên -> Chớp tiếp
    private func startStarBlinkAnimation(star: SKSpriteNode, preset: StarPreset, index: Int) {
        star.removeAction(forKey: "starBlink")
        star.removeAction(forKey: "starRotate")

        // 1. Trạng thái nghỉ nền (Resting): sao sáng dịu, scale chuẩn 1.0
        let baseAlpha = preset.baseAlpha
        let restAlpha = baseAlpha * 0.28
        star.alpha = restAlpha
        star.setScale(1.0)

        // 2. Nhịp chớp sáng bừng lên (Flash In): sáng rực rỡ lên alpha = 1.0 và phóng to
        let flashDur = preset.isFocalRoundStar ? 0.18 : 0.14
        let flashScale: CGFloat = preset.isFocalRoundStar ? 1.55 : (preset.isLargeFourRayStar ? 1.45 : 1.35)

        let flashIn = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: flashDur),
            SKAction.scale(to: flashScale, duration: flashDur)
        ])
        flashIn.timingMode = .easeOut

        // 3. Nhịp mờ lại về trạng thái nghỉ (Fade Out)
        let fadeOutDur = flashDur * 1.5
        let flashOut = SKAction.group([
            SKAction.fadeAlpha(to: restAlpha, duration: fadeOutDur),
            SKAction.scale(to: 1.0, duration: fadeOutDur)
        ])
        flashOut.timingMode = .easeInEaseOut

        // Ghép chuỗi TUẦN TỰ (SKAction.sequence)
        var sequenceItems: [SKAction] = [flashIn, flashOut]

        // Thỉnh thoảng có thêm nhịp chớp đúp (Double Blink)
        if preset.isFocalRoundStar || (index % 3 == 0) {
            let miniWait = SKAction.wait(forDuration: 0.06)
            let miniFlashIn = SKAction.group([
                SKAction.fadeAlpha(to: 0.95, duration: 0.10),
                SKAction.scale(to: flashScale * 0.90, duration: 0.10)
            ])
            miniFlashIn.timingMode = .easeOut

            let miniFlashOut = SKAction.group([
                SKAction.fadeAlpha(to: restAlpha, duration: 0.16),
                SKAction.scale(to: 1.0, duration: 0.16)
            ])
            miniFlashOut.timingMode = .easeInEaseOut

            sequenceItems.append(contentsOf: [miniWait, miniFlashIn, miniFlashOut])
        }

        // 4. KHOẢNG NGHỈ GIÃN CÁCH NGẪU NHIÊN GIỮA CÁC LẦN CHỚP (Intermittent Pause):
        // Dùng wait(forDuration:withRange:) để mỗi chu kỳ lặp lại đều có thời gian nghỉ ngẫu nhiên mới!
        let pauseMean = (preset.minPause + preset.maxPause) * 0.5
        let pauseRange = (preset.maxPause - preset.minPause) * 0.8
        let pauseAction = SKAction.wait(forDuration: pauseMean, withRange: pauseRange)
        sequenceItems.append(pauseAction)

        // CHUỖI TUẦN TỰ: Flash -> Fade -> (MiniFlash) -> Nghỉ giãn cách -> LẶP LẠI
        let blinkCycle = SKAction.sequence(sequenceItems)
        let repeatBlink = SKAction.repeatForever(blinkCycle)

        // Độ trễ ban đầu so le giữa các vì sao để bầu trời rải rác chớp nháy khắp nơi
        let initialStagger = SKAction.wait(forDuration: Double(index % 8) * 0.42 + Double.random(in: 0.1...1.2))
        star.run(SKAction.sequence([initialStagger, repeatBlink]), withKey: "starBlink")

        // 5. Nếu là sao 4 cánh lớn: Xoay nhẹ nhàng độc lập (không tranh chấp với blink)
        if preset.isLargeFourRayStar {
            let rotRight = SKAction.rotate(byAngle: 0.28, duration: 2.8)
            rotRight.timingMode = .easeInEaseOut
            let rotLeft = SKAction.rotate(byAngle: -0.28, duration: 2.8)
            rotLeft.timingMode = .easeInEaseOut
            star.run(SKAction.repeatForever(SKAction.sequence([rotRight, rotLeft])), withKey: "starRotate")
        }

        // 6. Nếu là sao tròn điểm nhấn: Cho quầng sáng halo chớp sáng đồng bộ
        if let halo = star.childNode(withName: "starHalo") as? SKShapeNode {
            halo.removeAction(forKey: "haloBlink")
            let haloIn = SKAction.group([
                SKAction.fadeAlpha(to: 0.70, duration: flashDur),
                SKAction.scale(to: 1.55, duration: flashDur)
            ])
            let haloOut = SKAction.group([
                SKAction.fadeAlpha(to: 0.20, duration: fadeOutDur),
                SKAction.scale(to: 1.0, duration: fadeOutDur)
            ])
            let haloSeq = SKAction.sequence([haloIn, haloOut, pauseAction])
            halo.run(SKAction.sequence([initialStagger, SKAction.repeatForever(haloSeq)]), withKey: "haloBlink")
        }
    }

    // MARK: - Shooting Stars (Sao Băng Bay Qua)

    private func startShootingStarsScheduler() {
        landscapeRootNode.removeAction(forKey: "shootingStarsScheduler")

        let scheduleAction = SKAction.repeatForever(SKAction.sequence([
            // Khoảng nghỉ ngẫu nhiên giữa các lần sao băng xuất hiện (4.2 ... 7.8 giây)
            SKAction.wait(forDuration: Double.random(in: 4.2...7.8)),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.spawnShootingStar()
                if Double.random(in: 0...1) < 0.22 {
                    let delaySecond = SKAction.wait(forDuration: Double.random(in: 0.35...0.75))
                    let fireSecond = SKAction.run { [weak self] in self?.spawnShootingStar() }
                    self.landscapeRootNode.run(SKAction.sequence([delaySecond, fireSecond]))
                }
            }
        ]))

        landscapeRootNode.run(scheduleAction, withKey: "shootingStarsScheduler")
    }

    /// Kích hoạt một vệt sao băng bay xẹt qua bầu trời
    private func spawnShootingStar(from customStart: CGPoint? = nil) {
        guard let shootingGroup = shootingStarsNode else { return }

        let screenW = containerSize.width
        let screenH = containerSize.height

        let startX = customStart?.x ?? CGFloat.random(in: (screenW * 0.45)...(screenW * 1.05))
        let startY = customStart?.y ?? CGFloat.random(in: (screenH * 0.70)...(screenH * 0.98))
        let startPoint = CGPoint(x: startX, y: startY)

        let distanceX = -CGFloat.random(in: 190.0...330.0) * activeScale
        let distanceY = -CGFloat.random(in: 110.0...190.0) * activeScale
        let endPoint = CGPoint(x: startPoint.x + distanceX, y: startPoint.y + distanceY)
        let flightDuration = Double.random(in: 0.45...0.65)

        let meteorNode = SKNode()
        meteorNode.position = startPoint
        meteorNode.zPosition = 25.0
        shootingGroup.addChild(meteorNode)

        let angle = atan2(distanceY, distanceX)

        let trailLength = CGFloat.random(in: 55.0...95.0) * activeScale
        let trailPath = CGMutablePath()
        trailPath.move(to: .zero)
        trailPath.addLine(to: CGPoint(x: -trailLength, y: 0))

        let trail = SKShapeNode(path: trailPath)
        trail.strokeColor = UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 0.85)
        trail.lineWidth = 2.4 * activeScale
        trail.zRotation = angle
        trail.glowWidth = 3.8 * activeScale
        meteorNode.addChild(trail)

        let head = SKShapeNode(circleOfRadius: 3.0 * activeScale)
        head.fillColor = UIColor.white
        head.strokeColor = UIColor(red: 0.80, green: 0.92, blue: 1.0, alpha: 0.95)
        head.glowWidth = 4.2 * activeScale
        meteorNode.addChild(head)

        let flyMove = SKAction.move(to: endPoint, duration: flightDuration)
        flyMove.timingMode = .easeInEaseOut

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: flightDuration * 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: flightDuration * 0.7)
        fadeOut.timingMode = .easeIn
        let fadeSeq = SKAction.sequence([fadeIn, fadeOut])

        let scaleUp = SKAction.scale(to: 1.15, duration: flightDuration * 0.4)
        let scaleDown = SKAction.scale(to: 0.25, duration: flightDuration * 0.6)
        let scaleSeq = SKAction.sequence([scaleUp, scaleDown])

        let groupAction = SKAction.group([flyMove, fadeSeq, scaleSeq])
        let remove = SKAction.removeFromParent()

        meteorNode.run(SKAction.sequence([groupAction, remove]))
        spawnMeteorStardust(along: startPoint, end: endPoint, duration: flightDuration)
    }

    private func spawnMeteorStardust(along start: CGPoint, end: CGPoint, duration: Double) {
        guard let shootingGroup = shootingStarsNode else { return }

        let count = 6
        for i in 1...count {
            let progress = CGFloat(i) / CGFloat(count)
            let posX = start.x + (end.x - start.x) * progress + CGFloat.random(in: -4.0...4.0)
            let posY = start.y + (end.y - start.y) * progress + CGFloat.random(in: -4.0...4.0)
            let delay = duration * Double(progress) * 0.85

            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.2...2.0))
            spark.fillColor = UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 0.90)
            spark.strokeColor = .clear
            spark.position = CGPoint(x: posX, y: posY)
            spark.alpha = 0.0
            spark.zPosition = 24.0
            shootingGroup.addChild(spark)

            let wait = SKAction.wait(forDuration: delay)
            let appear = SKAction.fadeAlpha(to: 0.85, duration: 0.08)
            let fall = SKAction.moveBy(x: CGFloat.random(in: -5.0...5.0), y: -CGFloat.random(in: 6.0...15.0), duration: 0.35)
            fall.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.35)
            let group = SKAction.group([fall, fade])
            let remove = SKAction.removeFromParent()

            spark.run(SKAction.sequence([wait, appear, group, remove]))
        }
    }

    // MARK: - Moon Breathing & Floating

    private func startMoonBreathing(moon: SKSpriteNode) {
        moon.removeAction(forKey: "moonBreathing")
        // Ánh trăng tự nhiên từ texture mờ tỏ nhẹ nhàng (alpha 0.94 <-> 1.0, scale 0.988 <-> 1.012)
        let scaleDown = SKAction.scale(to: 0.988, duration: 4.2)
        scaleDown.timingMode = .easeInEaseOut
        let fadeDown = SKAction.fadeAlpha(to: 0.94, duration: 4.2)
        fadeDown.timingMode = .easeInEaseOut
        let groupDown = SKAction.group([scaleDown, fadeDown])

        let scaleUp = SKAction.scale(to: 1.012, duration: 4.2)
        scaleUp.timingMode = .easeInEaseOut
        let fadeUp = SKAction.fadeAlpha(to: 1.0, duration: 4.2)
        fadeUp.timingMode = .easeInEaseOut
        let groupUp = SKAction.group([scaleUp, fadeUp])

        moon.run(SKAction.repeatForever(SKAction.sequence([groupDown, groupUp])), withKey: "moonBreathing")
    }

    private func startMoonFloatingBobbing(moonGroup: SKNode) {
        moonGroup.removeAction(forKey: "moonBobbing")
        let floatUp = SKAction.moveBy(x: 0, y: 5.0 * activeScale, duration: 4.2)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = SKAction.moveBy(x: 0, y: -5.0 * activeScale, duration: 4.2)
        floatDown.timingMode = .easeInEaseOut

        moonGroup.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])), withKey: "moonBobbing")
    }

    // MARK: - Tap Interaction (Chạm Mặt Trăng, Sao Điểm Nhấn, Bắn Sao Băng)

    public func playTapAnimation(at location: CGPoint) {
        // 1. Chạm trúng Mặt Trăng to
        if let moonGroup = moonGroupNode, let moonNode = moonNode {
            let moonCenterX = moonGroup.position.x + moonNode.position.x * activeScale
            let moonCenterY = moonGroup.position.y + moonNode.position.y * activeScale
            let dist = hypot(location.x - moonCenterX, location.y - moonCenterY)
            let hitRadius = max(moonNode.size.width, moonNode.size.height) * 0.60 * activeScale
            if dist < hitRadius {
                playMoonPulseAnimation(at: CGPoint(x: moonCenterX, y: moonCenterY))
                return
            }
        }

        // 2. Chạm gần một Ngôi Sao
        var hitStar: SKSpriteNode?
        var minDistance: CGFloat = 55.0 * activeScale
        for star in starSprites {
            let dist = hypot(location.x - star.position.x, location.y - star.position.y)
            if dist < minDistance {
                minDistance = dist
                hitStar = star
            }
        }

        if let star = hitStar {
            let hopUp = SKAction.scale(to: 1.65, duration: 0.15)
            hopUp.timingMode = .easeOut
            let hopDown = SKAction.scale(to: 1.0, duration: 0.28)
            hopDown.timingMode = .easeInEaseOut
            let flash = SKAction.fadeAlpha(to: 1.0, duration: 0.12)
            star.run(SKAction.group([SKAction.sequence([hopUp, hopDown]), flash]))

            spawnStarDust(at: star.position, count: 7)
            return
        }

        // 3. Chạm vào bầu trời: Bắn ngay một vệt Sao Băng tức thì
        let shootStart = CGPoint(x: min(containerSize.width * 0.95, location.x + CGFloat.random(in: 40.0...100.0)),
                                 y: min(containerSize.height * 0.95, location.y + CGFloat.random(in: 30.0...80.0)))
        spawnShootingStar(from: shootStart)

        // 4. Bung toả bụi sao tinh tú tại điểm chạm
        spawnStarDust(at: location, count: 9)
    }

    private func playMoonPulseAnimation(at center: CGPoint) {
        let shockwave = SKShapeNode(circleOfRadius: 60.0 * activeScale)
        shockwave.position = center
        shockwave.strokeColor = UIColor(red: 1.0, green: 0.98, blue: 0.90, alpha: 0.70)
        shockwave.fillColor = .clear
        shockwave.lineWidth = 1.8 * activeScale
        shockwave.zPosition = 35.0
        landscapeRootNode.addChild(shockwave)

        let expand = SKAction.scale(to: 2.2, duration: 0.60)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.60)
        let remove = SKAction.removeFromParent()
        shockwave.run(SKAction.sequence([SKAction.group([expand, fade]), remove]))

        spawnStarDust(at: center, count: 18, isMoonDust: true)
    }

    private func spawnStarDust(at location: CGPoint, count: Int, isMoonDust: Bool = false) {
        let colors: [UIColor] = isMoonDust ? [
            UIColor(red: 1.0, green: 0.96, blue: 0.80, alpha: 0.95),
            UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.95),
            UIColor(red: 1.0, green: 0.88, blue: 0.65, alpha: 0.90)
        ] : [
            UIColor(red: 0.85, green: 0.94, blue: 1.0, alpha: 0.95),
            UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.95),
            UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 0.90)
        ]

        for _ in 0..<count {
            let radius = CGFloat.random(in: 2.2...4.5) * activeScale
            let sparkle = SKShapeNode(circleOfRadius: radius)
            sparkle.fillColor = colors.randomElement() ?? .white
            sparkle.strokeColor = .clear
            sparkle.position = location
            sparkle.zPosition = 38.0
            landscapeRootNode.addChild(sparkle)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 20.0...80.0) * activeScale
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let duration = Double.random(in: 0.45...0.80)

            let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: duration)
            let scale = SKAction.scale(to: 0.25, duration: duration)
            let group = SKAction.group([move, fade, scale])
            let remove = SKAction.removeFromParent()

            sparkle.run(SKAction.sequence([group, remove]))
        }
    }
}

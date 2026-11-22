//
//  Landscape5Node.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import UIKit

/// Node Phong cảnh chuyên biệt cho Landscape 5: "Ban công ô kính mưa" (landscape5)
/// - Mô hình Kiến trúc Lai SpriteKit: Nạp trực quan từ `Landscape5Scene.sks` (kèm Fallback Procedural độc lập)
/// - Thiết kế dọc (Portrait Layout) tối ưu cho toàn màn hình iPhone
/// - Thứ tự Z-Index Chuẩn xác theo Yêu cầu:
///   1. `bgNode` (z = 0): Nền mờ ảo ngoài trời mưa (`landscape5-1@4.167x`)
///   2. `overlayNode` (z = 10): Lớp kính mờ sương hơi nước ngưng tụ (`landscape5-2@4.167x`)
///   3. `waterDropsNode` (z = 20): Lớp các giọt nước tĩnh đọng trên mặt kính (`landscape5-3@4.167x`)
///   4. `trickleGroup` (z = 30): Hiệu ứng giọt nước ngưng tụ chảy trượt lăn dài từ trên xuống dưới
///      kèm vệt nước ẩm ướt ngoằn ngoèo tự nhiên (Water Streak Trail on Glass)
public final class Landscape5Node: SKNode, LandscapeInteractiveNode {

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private let landscapeRootNode = SKNode()

    // Layer Nodes
    private var bgNode: SKSpriteNode?
    private var overlayNode: SKSpriteNode?
    private var waterDropsNode: SKSpriteNode?
    private var trickleGroupNode: SKNode?

    // Tỉ lệ scale so với canvas thiết kế chuẩn (833 x 833)
    private let baseDesignWidth: CGFloat = 833.0
    private let baseDesignHeight: CGFloat = 833.0
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
        waterDropsNode = nil
        trickleGroupNode = nil

        guard containerSize.width > 0, containerSize.height > 0 else { return }

        // Scale fit dọc màn hình (Aspect Fill bao phủ toàn bộ màn hình không hở viền)
        let scaleX = containerSize.width / baseDesignWidth
        let scaleY = containerSize.height / baseDesignHeight
        activeScale = max(scaleX, scaleY)

        // Nhóm chứa các giọt nước đang chảy động và vệt nước kéo dài
        let trickleGroup = SKNode()
        trickleGroup.name = "trickleGroup"
        trickleGroup.zPosition = 30.0
        landscapeRootNode.addChild(trickleGroup)
        self.trickleGroupNode = trickleGroup

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ Landscape5Scene.sks
        if let scene = loadSceneTemplate() {
            buildFromSceneTemplate(scene: scene)
            startAnimations()
            return
        }

        // 2. FALLBACK PROCEDURAL CODE NẾU CHƯA NẠP ĐƯỢC SCENE
        buildProceduralFallback()
        startAnimations()
    }

    // MARK: - 1. Build from Scene Template

    private func buildFromSceneTemplate(scene: SKScene) {
        let fillW = max(containerSize.width, baseDesignWidth * activeScale)
        let fillH = max(containerSize.height, baseDesignHeight * activeScale)
        let centerPos = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)

        // --- 1. bgNode (z = 0) ---
        if let bg = scene.childNode(withName: "bgNode") as? SKSpriteNode {
            bg.removeFromParent()
            bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bg.position = centerPos
            bg.size = CGSize(width: fillW, height: fillH)
            bg.zPosition = 0.0
            if let realBgTex = loadTexture(name: "landscape5-1@4.167x") {
                bg.texture = realBgTex
            }
            landscapeRootNode.addChild(bg)
            self.bgNode = bg
        }

        // --- 2. overlayNode (z = 10) ---
        if let overlay = scene.childNode(withName: "overlayNode") as? SKSpriteNode {
            overlay.removeFromParent()
            overlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            overlay.position = centerPos
            overlay.size = CGSize(width: fillW, height: fillH)
            overlay.zPosition = 10.0
            overlay.alpha = 0.88
            if let overlayTex = loadTexture(name: "landscape5-2@4.167x") {
                overlay.texture = overlayTex
            }
            landscapeRootNode.addChild(overlay)
            self.overlayNode = overlay
        }

        // --- 3. waterDropsNode (z = 20) ---
        let dropsNode = SKSpriteNode()
        dropsNode.name = "waterDropsNode"
        dropsNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        dropsNode.position = centerPos
        dropsNode.size = CGSize(width: fillW, height: fillH)
        dropsNode.zPosition = 20.0
        dropsNode.alpha = 0.95
        if let dropsTex = loadTexture(name: "landscape5-3@4.167x") {
            dropsNode.texture = dropsTex
        }
        landscapeRootNode.addChild(dropsNode)
        self.waterDropsNode = dropsNode
    }

    // MARK: - 2. Procedural Fallback

    private func buildProceduralFallback() {
        let fillW = max(containerSize.width, baseDesignWidth * activeScale)
        let fillH = max(containerSize.height, baseDesignHeight * activeScale)
        let centerPos = CGPoint(x: containerSize.width / 2.0, y: containerSize.height / 2.0)

        // --- 1. bgNode (z = 0) ---
        let bgTex = loadTexture(name: "landscape5-1@4.167x")
        let bg = SKSpriteNode(texture: bgTex, size: CGSize(width: fillW, height: fillH))
        bg.name = "bgNode"
        bg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        bg.position = centerPos
        bg.zPosition = 0.0
        landscapeRootNode.addChild(bg)
        self.bgNode = bg

        // --- 2. overlayNode (z = 10) ---
        let overlayTex = loadTexture(name: "landscape5-2@4.167x")
        let overlay = SKSpriteNode(texture: overlayTex, size: CGSize(width: fillW, height: fillH))
        overlay.name = "overlayNode"
        overlay.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        overlay.position = centerPos
        overlay.zPosition = 10.0
        overlay.alpha = 0.88
        landscapeRootNode.addChild(overlay)
        self.overlayNode = overlay

        // --- 3. waterDropsNode (z = 20) ---
        let dropsTex = loadTexture(name: "landscape5-3@4.167x")
        let drops = SKSpriteNode(texture: dropsTex, size: CGSize(width: fillW, height: fillH))
        drops.name = "waterDropsNode"
        drops.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        drops.position = centerPos
        drops.zPosition = 20.0
        drops.alpha = 0.95
        landscapeRootNode.addChild(drops)
        self.waterDropsNode = drops
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

    // MARK: - Animations (Hơi nước thở, Giọt nước đọng lấp lánh & Giọt nước chảy trượt)

    private func startAnimations() {
        // 1. Nhịp thở hơi sương mờ trên mặt kính (overlay breath)
        if let overlay = overlayNode {
            startOverlayCondensationBreathing(overlay: overlay)
        }

        // 2. Nhịp phản chiếu ánh sáng lấp lánh của các giọt nước đọng tĩnh
        if let drops = waterDropsNode {
            startDropsShimmer(drops: drops)
        }

        // 3. Chu kỳ sinh giọt nước ngưng tụ và chảy trượt tự nhiên trên kính
        startWaterTrickleScheduler()
    }

    // MARK: - Overlay Condensation Breathing

    private func startOverlayCondensationBreathing(overlay: SKSpriteNode) {
        overlay.removeAction(forKey: "overlayBreath")
        let fadeOut = SKAction.fadeAlpha(to: 0.78, duration: 6.0)
        fadeOut.timingMode = .easeInEaseOut
        let fadeIn = SKAction.fadeAlpha(to: 0.95, duration: 6.0)
        fadeIn.timingMode = .easeInEaseOut

        overlay.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])), withKey: "overlayBreath")
    }

    private func startDropsShimmer(drops: SKSpriteNode) {
        drops.removeAction(forKey: "dropsShimmer")
        let dim = SKAction.fadeAlpha(to: 0.88, duration: 4.5)
        dim.timingMode = .easeInEaseOut
        let bright = SKAction.fadeAlpha(to: 1.0, duration: 4.5)
        bright.timingMode = .easeInEaseOut

        drops.run(SKAction.repeatForever(SKAction.sequence([dim, bright])), withKey: "dropsShimmer")
    }

    // MARK: - Water Trickle Scheduler (Thi thoảng có giọt nước ngưng tụ rồi chảy trượt xuống)

    private func startWaterTrickleScheduler() {
        landscapeRootNode.removeAction(forKey: "trickleScheduler")

        let scheduler = SKAction.repeatForever(SKAction.sequence([
            // Khoảng nghỉ ngẫu nhiên giữa các lần giọt nước chảy (3.5 ... 6.5 giây)
            SKAction.wait(forDuration: Double.random(in: 3.5...6.5)),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Sinh một giọt nước ngưng tụ và lăn dài
                self.spawnTricklingDrop()

                // Thỉnh thoảng (30% xác suất) xuất hiện thêm 1 giọt chảy song song ở vị trí khác
                if Double.random(in: 0...1) < 0.30 {
                    let delay = SKAction.wait(forDuration: Double.random(in: 0.8...1.8))
                    let spawnSecond = SKAction.run { [weak self] in self?.spawnTricklingDrop() }
                    self.landscapeRootNode.run(SKAction.sequence([delay, spawnSecond]))
                }
            }
        ]))

        landscapeRootNode.run(scheduler, withKey: "trickleScheduler")
    }

    /// Khởi tạo và diễn hoạt một giọt nước chảy trên kính (ngưng tụ -> trượt ngoằn ngoèo -> để lại vệt nước)
    private func spawnTricklingDrop(at customStart: CGPoint? = nil) {
        guard let trickleGroup = trickleGroupNode else { return }

        let screenW = containerSize.width
        let screenH = containerSize.height

        // Điểm xuất phát của giọt nước: mặc định ở 70% ... 96% chiều cao kính
        let startX = customStart?.x ?? CGFloat.random(in: (screenW * 0.12)...(screenW * 0.88))
        let startY = customStart?.y ?? CGFloat.random(in: (screenH * 0.72)...(screenH * 0.96))
        let startPoint = CGPoint(x: startX, y: startY)

        // Kích thước giọt nước: giọt to vừa hoặc giọt to lớn (như trong ảnh mẫu)
        let isLargeDrop = Double.random(in: 0...1) < 0.45
        let dropWidth: CGFloat = (isLargeDrop ? CGFloat.random(in: 14.0...18.0) : CGFloat.random(in: 10.0...13.0)) * activeScale
        let dropHeight: CGFloat = (isLargeDrop ? CGFloat.random(in: 18.0...24.0) : CGFloat.random(in: 13.0...17.0)) * activeScale

        // Node chính chứa giọt nước di động
        let dropletNode = SKNode()
        dropletNode.position = startPoint
        dropletNode.zPosition = 35.0
        trickleGroup.addChild(dropletNode)

        // 1. Thân giọt nước (Droplet Body): Hình bầu dục giọt lệ với hiệu ứng bóng đổ và độ trong suốt 3D
        let body = SKShapeNode(ellipseOf: CGSize(width: dropWidth, height: dropHeight))
        body.fillColor = UIColor(red: 0.88, green: 0.92, blue: 0.94, alpha: 0.60)
        body.strokeColor = UIColor(red: 0.25, green: 0.32, blue: 0.38, alpha: 0.45)
        body.lineWidth = 1.0 * activeScale
        dropletNode.addChild(body)

        // 2. Điểm sáng phản chiếu 3D (Highlight Specular Reflection): tạo độ căng bóng nước
        let highlight = SKShapeNode(ellipseOf: CGSize(width: dropWidth * 0.38, height: dropHeight * 0.28))
        highlight.fillColor = UIColor(white: 1.0, alpha: 0.92)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -dropWidth * 0.16, y: dropHeight * 0.18)
        dropletNode.addChild(highlight)

        // 3. Vệt bóng đổ dưới đáy giọt nước (Droplet Rim Shadow)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: dropWidth * 0.75, height: dropHeight * 0.20))
        shadow.fillColor = UIColor(red: 0.15, green: 0.20, blue: 0.25, alpha: 0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -dropHeight * 0.30)
        dropletNode.addChild(shadow)

        // 4. Vệt nước ẩm kéo dài phía sau (Water Trail Streak on Glass)
        let trailNode = SKShapeNode()
        trailNode.strokeColor = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 0.38)
        trailNode.lineWidth = dropWidth * 0.65
        trailNode.lineCap = .round
        trailNode.lineJoin = .round
        trailNode.zPosition = 32.0
        trickleGroup.addChild(trailNode)

        // Bắt đầu từ trạng thái ngưng tụ nhỏ (Swell In)
        dropletNode.setScale(0.25)
        dropletNode.alpha = 0.0

        let swellIn = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.75),
            SKAction.fadeAlpha(to: 1.0, duration: 0.75)
        ])
        swellIn.timingMode = .easeOut

        // Tạo chuỗi chuyển động trượt ngoằn ngoèo tự nhiên theo các đoạn ngắn
        // Mỗi đoạn có vận tốc khác nhau (nhấp nhô, start-stop-glide)
        let numSegments = Int.random(in: 4...6)
        let totalDropDistance = startY - CGFloat.random(in: -30.0...100.0)
        let segmentDy = totalDropDistance / CGFloat(numSegments)

        var points: [CGPoint] = [startPoint]
        var moveActions: [SKAction] = []
        var currentPoint = startPoint

        for seg in 1...numSegments {
            // Độ lệch ngoằn ngoèo trục X (Meandering Wiggle)
            let wiggleX = CGFloat.random(in: -6.0...6.0) * activeScale
            let nextX = max(30.0, min(screenW - 30.0, currentPoint.x + wiggleX))
            let nextY = currentPoint.y - segmentDy
            let nextPoint = CGPoint(x: nextX, y: nextY)
            points.append(nextPoint)

            // Vận tốc biến thiên: có đoạn trượt nhanh, có đoạn ngập ngừng chậm lại do sức căng mặt kính
            let isQuickSlide = (seg % 2 == 0)
            let segDuration = isQuickSlide ? Double.random(in: 0.28...0.48) : Double.random(in: 0.65...1.10)

            let moveSeg = SKAction.move(to: nextPoint, duration: segDuration)
            moveSeg.timingMode = isQuickSlide ? .easeIn : .easeOut

            // Cập nhật vệt nước theo thời gian thực dọc theo đường di chuyển
            let updateTrail = SKAction.run { [weak trailNode, weak self] in
                guard let trailNode = trailNode, let self = self else { return }
                self.redrawWaterTrail(trailNode: trailNode, points: points, currentTip: dropletNode.position)
            }

            // Để lại giọt nước nhỏ li ti bám lại trên kính (Micro-droplet left behind)
            let leaveMicroDrop = SKAction.run { [weak self] in
                if Double.random(in: 0...1) < 0.40 {
                    self?.spawnMicroDroplet(at: nextPoint, size: dropWidth * 0.28)
                }
            }

            moveActions.append(SKAction.group([moveSeg, updateTrail]))
            moveActions.append(leaveMicroDrop)
            currentPoint = nextPoint
        }

        // Sau khi trượt xong: Giọt nước dừng lại mờ dần và Vệt nước từ từ bốc hơi
        let fadeOutDroplet = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 1.8),
            SKAction.removeFromParent()
        ])

        let fadeOutTrail = SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeOut(withDuration: 2.8),
            SKAction.removeFromParent()
        ])

        // Thực thi toàn bộ chuỗi hành động
        let fullTrickleSequence = SKAction.sequence([
            swellIn,
            SKAction.wait(forDuration: 0.3), // Giọt nước ngập ngừng một thoáng rồi bắt đầu trượt
            SKAction.sequence(moveActions),
            SKAction.run {
                trailNode.run(fadeOutTrail)
            },
            fadeOutDroplet
        ])

        dropletNode.run(fullTrickleSequence)
    }

    /// Vẽ lại đường cong vệt nước ẩm mờ uốn lượn (Smooth Water Trail)
    private func redrawWaterTrail(trailNode: SKShapeNode, points: [CGPoint], currentTip: CGPoint) {
        guard points.count > 0 else { return }

        let path = CGMutablePath()
        path.move(to: points[0])

        if points.count == 1 {
            path.addLine(to: currentTip)
        } else {
            for i in 1..<points.count {
                let p0 = points[i - 1]
                let p1 = points[i]
                let mid = CGPoint(x: (p0.x + p1.x) * 0.5, y: (p0.y + p1.y) * 0.5)
                path.addQuadCurve(to: p1, control: mid)
            }
            path.addLine(to: currentTip)
        }

        trailNode.path = path
    }

    /// Sinh giọt nước li ti bám lại trên kính dọc đường giọt to chảy qua
    private func spawnMicroDroplet(at location: CGPoint, size: CGFloat) {
        guard let trickleGroup = trickleGroupNode else { return }

        let micro = SKShapeNode(circleOfRadius: max(1.2, size * 0.5))
        micro.fillColor = UIColor(red: 0.90, green: 0.94, blue: 0.96, alpha: 0.55)
        micro.strokeColor = UIColor(red: 0.30, green: 0.35, blue: 0.40, alpha: 0.40)
        micro.lineWidth = 0.6
        micro.position = CGPoint(x: location.x + CGFloat.random(in: -2.0...2.0), y: location.y)
        micro.zPosition = 33.0
        trickleGroup.addChild(micro)

        // Tự bốc hơi dần sau 3.5 ... 6.0 giây
        let wait = SKAction.wait(forDuration: Double.random(in: 3.5...5.5))
        let fade = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        micro.run(SKAction.sequence([wait, fade, remove]))
    }

    // MARK: - Tap Interaction (Chạm tạo giọt nước chảy tức thì & Vòng sóng nước loang trên kính)

    public func playTapAnimation(at location: CGPoint) {
        // 1. Tạo một giọt nước ngưng tụ và chảy trượt ngay từ điểm chạm!
        spawnTricklingDrop(at: location)

        // 2. Vòng sóng nước loang rộng trên mặt kính (Water Ripple on Glass)
        spawnGlassRipple(at: location)

        // 3. Hiệu ứng gạt sáng nhẹ lớp kính
        if let drops = waterDropsNode {
            let flash = SKAction.fadeAlpha(to: 1.0, duration: 0.15)
            let restore = SKAction.fadeAlpha(to: 0.95, duration: 0.45)
            drops.run(SKAction.sequence([flash, restore]))
        }
    }

    /// Gợn sóng nước lan toả trên mặt kính khi chạm ngón tay
    private func spawnGlassRipple(at location: CGPoint) {
        guard let trickleGroup = trickleGroupNode else { return }

        for i in 0..<2 {
            let ripple = SKShapeNode(circleOfRadius: 8.0 * activeScale)
            ripple.position = location
            ripple.strokeColor = UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 0.80)
            ripple.fillColor = UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 0.18)
            ripple.lineWidth = 1.5 * activeScale
            ripple.zPosition = 36.0
            trickleGroup.addChild(ripple)

            let delay = SKAction.wait(forDuration: Double(i) * 0.12)
            let expand = SKAction.scale(to: CGFloat(3.2 + Double(i) * 1.4), duration: 0.55)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.55)
            let group = SKAction.group([expand, fade])
            let remove = SKAction.removeFromParent()

            ripple.run(SKAction.sequence([delay, group, remove]))
        }
    }
}

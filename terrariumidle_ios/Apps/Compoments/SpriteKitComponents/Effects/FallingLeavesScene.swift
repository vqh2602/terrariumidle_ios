//
//  FallingLeavesScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - Cấu hình gió
public enum WindDirection: Sendable {
    case none
    case gentleLeft
    case gentleRight
    case breezeLeft
    case breezeRight
    case variable // Gió tự động đổi hướng nhẹ nhàng theo thời gian

    var baseHorizontalDrift: CGFloat {
        switch self {
        case .none: return 0
        case .gentleLeft: return -45
        case .gentleRight: return 50
        case .breezeLeft: return -90
        case .breezeRight: return 95
        case .variable: return 20
        }
    }
}

// MARK: - Mật độ lá rơi
public enum LeafDensity: Sendable {
    case low
    case medium
    case high

    var spawnInterval: TimeInterval {
        switch self {
        case .low: return 0.55
        case .medium: return 0.28
        case .high: return 0.15
        }
    }

    var initialLeavesCount: Int {
        switch self {
        case .low: return 8
        case .medium: return 16
        case .high: return 26
        }
    }
}

// MARK: - Tốc độ rơi
public enum LeafSpeed: Sendable {
    case slow
    case normal
    case fast

    var durationRange: ClosedRange<TimeInterval> {
        switch self {
        case .slow: return 6.5...9.5
        case .normal: return 4.5...7.0
        case .fast: return 2.8...4.5
        }
    }
}

// MARK: - SpriteKit Scene cho hiệu ứng lá rơi
public final class FallingLeavesScene: SKScene {
    // MARK: - Properties

    private var leafTextures: [SKTexture] = []
    private var wind: WindDirection = .gentleRight
    private var density: LeafDensity = .medium
    private var speedLevel: LeafSpeed = .normal

    private var currentWindOffset: CGFloat = 0
    private var isConfigured = false

    // MARK: - Initializer

    public override init() {
        super.init(size: .zero)
        setupSceneBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupSceneBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSceneBasics()
    }

    private func setupSceneBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    // MARK: - Configuration API

    /// Cấu hình danh sách ảnh lá (hỗ trợ từ 1 đến 6 ảnh), mật độ, hướng gió và tốc độ
    public func configure(
        imageNames: [String] = [],
        customImages: [UIImage] = [],
        customTextures: [SKTexture] = [],
        density: LeafDensity = .medium,
        wind: WindDirection = .gentleRight,
        speed: LeafSpeed = .normal
    ) {
        self.density = density
        self.wind = wind
        self.speedLevel = speed

        // 1. Chuẩn bị textures (tối đa 6 ảnh)
        var textures: [SKTexture] = []

        // Thêm từ customImages nếu có
        for image in customImages.prefix(6) {
            textures.append(SKTexture(image: image))
        }

        // Thêm từ imageNames trong Assets/JSON nếu có
        for name in imageNames.prefix(max(0, 6 - textures.count)) {
            if let uiImage = UIImage(named: name) {
                textures.append(SKTexture(image: uiImage))
            }
        }

        // Thêm từ customTextures nếu có
        for tex in customTextures.prefix(max(0, 6 - textures.count)) {
            textures.append(tex)
        }

        // Nếu không có ảnh nào hoặc ảnh bị thiếu, sinh 6 lá vector procedural tự động
        if textures.isEmpty {
            for i in 0..<6 {
                textures.append(Self.generateProceduralLeafTexture(index: i))
            }
        }

        self.leafTextures = textures
        self.currentWindOffset = wind.baseHorizontalDrift

        // Khởi động vòng lặp lá rơi nếu scene đã sẵn sàng
        if size.width > 0 && size.height > 0 {
            startLeavesEmitter()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear

        if !isConfigured && size.width > 0 {
            startLeavesEmitter()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !isConfigured && size.width > 0 && size.height > 0 {
            startLeavesEmitter()
        }
    }

    // MARK: - Emitter Management

    private func startLeavesEmitter() {
        guard !isConfigured else { return }
        isConfigured = true

        removeAction(forKey: "spawnLeaves")
        removeAction(forKey: "windGust")

        // Pre-warm: tạo trước một số lá rải đều trên màn hình khi mới mở
        prewarmLeaves()

        // Vòng lặp sinh lá mới liên tục
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnLeaf()
        }
        let waitAction = SKAction.wait(forDuration: density.spawnInterval, withRange: density.spawnInterval * 0.4)
        let loop = SKAction.sequence([spawnAction, waitAction])
        run(SKAction.repeatForever(loop), withKey: "spawnLeaves")

        // Hiệu ứng gió thoảng đổi hướng/biến thiên theo thời gian
        setupWindVariations()
    }

    /// Rải trước lá khắp màn hình để không bị trống khi màn hình vừa mở
    private func prewarmLeaves() {
        guard size.width > 0, size.height > 0 else { return }
        let count = density.initialLeavesCount

        for _ in 0..<count {
            let randomY = CGFloat.random(in: 0...size.height)
            let randomX = CGFloat.random(in: -30...(size.width + 30))
            spawnLeaf(atY: randomY, atX: randomX)
        }
    }

    private func setupWindVariations() {
        // Mỗi 6-10s tạo một cơn gió thoảng ngẫu nhiên
        let gustWait = SKAction.wait(forDuration: 7.0, withRange: 3.0)
        let gustAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            let randomShift = CGFloat.random(in: -25...35)
            self.currentWindOffset = self.wind.baseHorizontalDrift + randomShift
        }
        let restoreWait = SKAction.wait(forDuration: 3.0)
        let restoreAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.currentWindOffset = self.wind.baseHorizontalDrift
        }
        let gustSequence = SKAction.sequence([gustWait, gustAction, restoreWait, restoreAction])
        run(SKAction.repeatForever(gustSequence), withKey: "windGust")
    }

    // MARK: - Spawn Single Leaf

    private func spawnLeaf(atY startY: CGFloat? = nil, atX startX: CGFloat? = nil) {
        guard !leafTextures.isEmpty, size.width > 0, size.height > 0 else { return }

        // Chọn ngẫu nhiên 1 trong các texture lá được truyền vào
        let texture = leafTextures.randomElement()!
        let leaf = SKSpriteNode(texture: texture)

        // Kích thước và độ sâu (Parallax)
        let baseScale = CGFloat.random(in: 0.35...0.78)
        leaf.xScale = baseScale
        leaf.yScale = baseScale

        // Lá ở xa (nhỏ hơn) thì hơi mờ hơn một chút
        let alpha = CGFloat.random(in: 0.70...1.0)
        leaf.alpha = alpha

        // Vị trí bắt đầu
        let spawnY = startY ?? (size.height + 40)
        let spawnX = startX ?? CGFloat.random(in: -40...(size.width + 40))
        leaf.position = CGPoint(x: spawnX, y: spawnY)
        leaf.zRotation = CGFloat.random(in: -CGFloat.pi...CGFloat.pi)
        leaf.zPosition = CGFloat.random(in: 1...10)

        addChild(leaf)

        // Tính khoảng cách rơi và thời lượng
        let targetY: CGFloat = -50
        let totalDistance = spawnY - targetY
        let fullScreenDistance = size.height + 90
        let distanceRatio = totalDistance / fullScreenDistance

        let baseDuration = Double.random(in: speedLevel.durationRange)
        let leafDuration = max(1.0, baseDuration * Double(distanceRatio))

        // MARK: - 1. Hành động rơi xuống kết hợp dạt theo gió
        let windDrift = currentWindOffset * CGFloat(distanceRatio) + CGFloat.random(in: -20...30)
        let fallAction = SKAction.moveBy(x: windDrift, y: -totalDistance, duration: leafDuration)
        fallAction.timingMode = .linear

        // MARK: - 2. Hành động đung đưa qua lại (Swaying)
        let swayWidth = CGFloat.random(in: 25...55)
        let swayHalfPeriod = Double.random(in: 1.0...1.8)

        let swayRight = SKAction.moveBy(x: swayWidth, y: 0, duration: swayHalfPeriod)
        swayRight.timingMode = .easeInEaseOut

        let swayLeft = SKAction.moveBy(x: -swayWidth, y: 0, duration: swayHalfPeriod)
        swayLeft.timingMode = .easeInEaseOut

        let swaySequence = SKAction.sequence([swayRight, swayLeft])
        let swayLoop = SKAction.repeatForever(swaySequence)

        // MARK: - 3. Hành động lượn góc theo nhịp đung đưa (Tilt)
        let maxTilt = CGFloat.random(in: 0.25...0.65)
        let tiltRight = SKAction.rotate(byAngle: maxTilt, duration: swayHalfPeriod)
        tiltRight.timingMode = .easeInEaseOut
        let tiltLeft = SKAction.rotate(byAngle: -maxTilt * 2, duration: swayHalfPeriod * 2)
        tiltLeft.timingMode = .easeInEaseOut
        let tiltBack = SKAction.rotate(byAngle: maxTilt, duration: swayHalfPeriod)
        tiltBack.timingMode = .easeInEaseOut
        let tiltLoop = SKAction.repeatForever(SKAction.sequence([tiltRight, tiltLeft, tiltBack]))

        // MARK: - 4. Hiệu ứng lật 3D trong không gian (Tumbling Flip)
        // Lật xScale từ dương sang âm mô phỏng mặt trước/mặt sau của chiếc lá khi lượn trong gió
        let flipDuration = Double.random(in: 1.2...2.4)
        let flipToBack = SKAction.scaleX(to: -baseScale * 0.9, duration: flipDuration / 2)
        flipToBack.timingMode = .easeInEaseOut
        let flipToFront = SKAction.scaleX(to: baseScale, duration: flipDuration / 2)
        flipToFront.timingMode = .easeInEaseOut
        let flipLoop = SKAction.repeatForever(SKAction.sequence([flipToBack, flipToFront]))

        // Chạy đồng thời các hiệu ứng
        leaf.run(swayLoop, withKey: "sway")
        leaf.run(tiltLoop, withKey: "tilt")
        leaf.run(flipLoop, withKey: "flip")

        // Khi rơi xong qua đáy màn hình -> tự động huỷ node để giải phóng bộ nhớ
        leaf.run(SKAction.sequence([fallAction, SKAction.removeFromParent()]))
    }

    // MARK: - Procedural Fallback Leaves (Tự vẽ 6 loại lá vector nếu không có ảnh)

    public static func generateProceduralLeafTexture(index: Int) -> SKTexture {
        let size = CGSize(width: 38, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext

            // 6 tông màu lá tự nhiên khác nhau
            let leafPalettes: [(body: UIColor, vein: UIColor)] = [
                // 1. Lá xanh ngọc (Emerald Green)
                (UIColor(red: 0.28, green: 0.68, blue: 0.38, alpha: 0.95), UIColor(red: 0.18, green: 0.48, blue: 0.25, alpha: 0.6)),
                // 2. Lá xanh chanh tươi (Lime Green)
                (UIColor(red: 0.52, green: 0.78, blue: 0.32, alpha: 0.95), UIColor(red: 0.36, green: 0.60, blue: 0.20, alpha: 0.6)),
                // 3. Lá phong đỏ mùa thu (Autumn Maple Red)
                (UIColor(red: 0.86, green: 0.32, blue: 0.24, alpha: 0.95), UIColor(red: 0.60, green: 0.18, blue: 0.12, alpha: 0.6)),
                // 4. Lá vàng ngân hạnh (Golden Yellow)
                (UIColor(red: 0.95, green: 0.76, blue: 0.20, alpha: 0.95), UIColor(red: 0.75, green: 0.55, blue: 0.12, alpha: 0.6)),
                // 5. Cánh hoa anh đào / hồng (Sakura Pink)
                (UIColor(red: 0.96, green: 0.68, blue: 0.75, alpha: 0.95), UIColor(red: 0.85, green: 0.45, blue: 0.55, alpha: 0.6)),
                // 6. Lá cam hổ phách (Amber Orange)
                (UIColor(red: 0.92, green: 0.52, blue: 0.18, alpha: 0.95), UIColor(red: 0.70, green: 0.35, blue: 0.10, alpha: 0.6))
            ]

            let palette = leafPalettes[index % leafPalettes.count]
            let midX: CGFloat = 19
            let topY: CGFloat = 4
            let bottomY: CGFloat = 44

            context.saveGState()

            // Thân lá uốn lượn tự nhiên
            let path = UIBezierPath()
            path.move(to: CGPoint(x: midX, y: topY))
            // Cánh phải
            path.addCurve(
                to: CGPoint(x: midX, y: bottomY),
                controlPoint1: CGPoint(x: midX + 16, y: topY + 10),
                controlPoint2: CGPoint(x: midX + 13, y: bottomY - 8)
            )
            // Cánh trái
            path.addCurve(
                to: CGPoint(x: midX, y: topY),
                controlPoint1: CGPoint(x: midX - 13, y: bottomY - 8),
                controlPoint2: CGPoint(x: midX - 16, y: topY + 10)
            )
            path.close()

            palette.body.setFill()
            path.fill()

            // Gân lá chính giữa
            let vein = UIBezierPath()
            vein.move(to: CGPoint(x: midX, y: topY + 4))
            vein.addLine(to: CGPoint(x: midX, y: bottomY + 2))
            palette.vein.setStroke()
            vein.lineWidth = 1.2
            vein.lineCapStyle = .round
            vein.stroke()

            // Gân lá phụ 2 bên
            let sideVeins = UIBezierPath()
            sideVeins.move(to: CGPoint(x: midX, y: 16))
            sideVeins.addLine(to: CGPoint(x: midX + 7, y: 22))
            sideVeins.move(to: CGPoint(x: midX, y: 19))
            sideVeins.addLine(to: CGPoint(x: midX - 7, y: 25))
            sideVeins.move(to: CGPoint(x: midX, y: 26))
            sideVeins.addLine(to: CGPoint(x: midX + 6, y: 32))
            sideVeins.move(to: CGPoint(x: midX, y: 29))
            sideVeins.addLine(to: CGPoint(x: midX - 6, y: 35))
            palette.vein.withAlphaComponent(0.45).setStroke()
            sideVeins.lineWidth = 0.8
            sideVeins.stroke()

            context.restoreGState()
        }
        return SKTexture(image: image)
    }
}

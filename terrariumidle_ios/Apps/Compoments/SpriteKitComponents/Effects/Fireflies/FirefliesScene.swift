//
//  FirefliesScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - Phân tầng chiều sâu Đom đóm (Depth of Field / Bokeh)
private enum FireflyTier {
    case foreground   // Đom đóm cận cảnh: to mờ ảo, quầng sáng rộng, bay chậm
    case midground    // Đom đóm trung cảnh: kích thước vừa, lượn cong sống động, nhấp nháy phát quang
    case background   // Hậu cảnh: đốm sáng nhỏ xa & bụi sáng lấp lánh như sao
}

// MARK: - Cấu hình bảng màu phát quang (Bioluminescent Palettes)
public struct FireflyPalette: Sendable {
    public let coreColor: UIColor     // Tâm sáng rực
    public let haloColor: UIColor     // Quầng sáng trong
    public let outerColor: UIColor    // Hào quang tỏa mờ ngoài

    public init(coreColor: UIColor, haloColor: UIColor, outerColor: UIColor) {
        self.coreColor = coreColor
        self.haloColor = haloColor
        self.outerColor = outerColor
    }

    /// Vàng chanh phát quang (Chartreuse / Lime Green) - Gam màu chủ đạo
    public static let lime = FireflyPalette(
        coreColor: UIColor(red: 0.98, green: 1.0, blue: 0.88, alpha: 1.0),
        haloColor: UIColor(red: 0.78, green: 1.0, blue: 0.18, alpha: 0.95),
        outerColor: UIColor(red: 0.48, green: 0.88, blue: 0.08, alpha: 0.45)
    )

    /// Xanh ngọc / Xanh bạc hà (Cyan / Mint Turquoise) - Đốm sáng huyền ảo trong rừng đêm
    public static let cyanMint = FireflyPalette(
        coreColor: UIColor(red: 0.90, green: 1.0, blue: 1.0, alpha: 1.0),
        haloColor: UIColor(red: 0.20, green: 0.96, blue: 0.82, alpha: 0.95),
        outerColor: UIColor(red: 0.06, green: 0.72, blue: 0.60, alpha: 0.45)
    )

    /// Vàng hổ phách / Vàng kim ấm áp (Golden Amber)
    public static let goldenAmber = FireflyPalette(
        coreColor: UIColor(red: 1.0, green: 0.99, blue: 0.90, alpha: 1.0),
        haloColor: UIColor(red: 1.0, green: 0.88, blue: 0.22, alpha: 0.95),
        outerColor: UIColor(red: 0.90, green: 0.60, blue: 0.05, alpha: 0.45)
    )

    /// Xanh lục lá non (Spring Green)
    public static let springGreen = FireflyPalette(
        coreColor: UIColor(red: 0.94, green: 1.0, blue: 0.92, alpha: 1.0),
        haloColor: UIColor(red: 0.35, green: 0.98, blue: 0.48, alpha: 0.95),
        outerColor: UIColor(red: 0.12, green: 0.74, blue: 0.28, alpha: 0.45)
    )

    /// Tinh tú trắng tinh khôi (Pure Starlight)
    public static let pureSparkle = FireflyPalette(
        coreColor: UIColor(white: 1.0, alpha: 1.0),
        haloColor: UIColor(red: 0.95, green: 1.0, blue: 0.90, alpha: 0.90),
        outerColor: UIColor(red: 0.72, green: 0.96, blue: 0.32, alpha: 0.40)
    )
}

// MARK: - SpriteKit Scene cho hiệu ứng Đom đóm bay lượn phát sáng lung linh
public final class FirefliesScene: SKScene {
    // MARK: - Properties

    private var cachedTextures: [SKTexture] = []
    private var fireflyCount: Int = 26
    private var customImages: [UIImage] = []
    private var isConfigured = false

    // Container các tầng để quản lý z-depth độc lập
    private let backgroundLayer = SKNode()
    private let midgroundLayer = SKNode()
    private let foregroundLayer = SKNode()

    // MARK: - Initializers

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

        backgroundLayer.zPosition = 10
        midgroundLayer.zPosition = 20
        foregroundLayer.zPosition = 30

        addChild(backgroundLayer)
        addChild(midgroundLayer)
        addChild(foregroundLayer)
    }

    // MARK: - Configuration

    public func configure(count: Int = 26, customImages: [UIImage] = []) {
        self.fireflyCount = max(count, 18)
        self.customImages = customImages

        // Nạp hoặc khởi tạo textures phát sáng
        prepareTextures()

        if size.width > 30 && size.height > 30 {
            spawnAllFireflies()
        }
    }

    private func prepareTextures() {
        if !customImages.isEmpty {
            self.cachedTextures = customImages.prefix(6).map { SKTexture(image: $0) }
            return
        }

        // Tự sinh bộ 5 textures phát quang đa sắc độ theo ảnh thiết kế
        let palettes: [FireflyPalette] = [
            .lime,
            .lime,          // Tăng xác suất xuất hiện màu chanh chủ đạo
            .cyanMint,      // Đốm ngọc huyền diệu
            .goldenAmber,   // Ánh vàng ấm
            .springGreen,
            .pureSparkle
        ]

        self.cachedTextures = palettes.map {
            Self.generateGlowTexture(
                coreColor: $0.coreColor,
                haloColor: $0.haloColor,
                outerColor: $0.outerColor,
                dimension: 64
            )
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear

        if !isConfigured && size.width > 30 && size.height > 30 {
            spawnAllFireflies()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 30, size.height > 30 else { return }
        if !isConfigured {
            spawnAllFireflies()
        } else if oldSize.width > 0 && oldSize.height > 0 && (abs(size.width - oldSize.width) > 60 || abs(size.height - oldSize.height) > 60) {
            spawnAllFireflies()
        }
    }

    // MARK: - Spawning Fireflies Ecosystem

    private func spawnAllFireflies() {
        guard size.width > 30, size.height > 30 else { return }
        isConfigured = true

        backgroundLayer.removeAllChildren()
        midgroundLayer.removeAllChildren()
        foregroundLayer.removeAllChildren()

        if cachedTextures.isEmpty {
            prepareTextures()
        }

        // Phân bổ số lượng theo tỉ lệ chiều sâu tự nhiên:
        // - Foreground: 5-7 đom đóm cận cảnh to mềm mại
        // - Midground: 16-24 đom đóm trung cảnh lượn lờ phát sáng
        // - Background: 26-38 đốm sáng xa & bụi sáng lấp lánh
        let fgCount = max(5, Int(Double(fireflyCount) * 0.20))
        let mgCount = max(16, Int(Double(fireflyCount) * 0.65))
        let bgCount = max(26, Int(Double(fireflyCount) * 1.10))

        for _ in 0..<bgCount {
            spawnFirefly(tier: .background, parentLayer: backgroundLayer)
        }
        for _ in 0..<mgCount {
            spawnFirefly(tier: .midground, parentLayer: midgroundLayer)
        }
        for _ in 0..<fgCount {
            spawnFirefly(tier: .foreground, parentLayer: foregroundLayer)
        }
    }

    private func spawnFirefly(tier: FireflyTier, parentLayer: SKNode) {
        guard !cachedTextures.isEmpty, size.width > 30, size.height > 30 else { return }

        let texture = cachedTextures.randomElement()!

        // Root container điều khiển toạ độ bay trên màn hình
        let container = SKNode()
        let minX: CGFloat = 15
        let maxX: CGFloat = max(minX + 10, size.width - 15)
        let initialX = CGFloat.random(in: minX...maxX)

        let minY: CGFloat = 25
        let maxY: CGFloat = max(minY + 10, size.height - 25)
        let initialY = CGFloat.random(in: minY...maxY)
        container.position = CGPoint(x: initialX, y: initialY)

        // Sprite hiển thị texture phát sáng bên trong container
        let sprite = SKSpriteNode(texture: texture)
        sprite.blendMode = .add

        // Thiết lập kích thước và alpha cơ sở theo tầng chiều sâu
        let baseScale: CGFloat
        let initialAlpha: CGFloat

        switch tier {
        case .foreground:
            // Cận cảnh: Bokeh điểm xuyết mềm mại, kích thước ~14pt - 22pt
            baseScale = CGFloat.random(in: 0.22...0.34)
            initialAlpha = CGFloat.random(in: 0.60...0.85)

        case .midground:
            // Trung cảnh: Đom đóm bay lượn chính, kích thước ~7pt - 11.5pt
            baseScale = CGFloat.random(in: 0.11...0.18)
            initialAlpha = CGFloat.random(in: 0.75...0.98)

        case .background:
            // Hậu cảnh: Đốm sáng xa & bụi lấp lánh li ti ~2.5pt - 4.8pt
            baseScale = CGFloat.random(in: 0.04...0.075)
            initialAlpha = CGFloat.random(in: 0.50...0.85)
        }

        sprite.setScale(baseScale)
        sprite.alpha = initialAlpha
        container.addChild(sprite)
        parentLayer.addChild(container)

        // 1. Chuyển động bay lượn ngẫu nhiên theo đường cong mềm mại (Curved wandering)
        animateFlight(container: container, tier: tier)

        // 2. Chuyển động bồng bềnh vi mô (Micro-hovering bobbing)
        animateMicroHover(sprite: sprite, tier: tier)

        // 3. Hiệu ứng nhấp nháy phát quang & lấp lánh lung linh (Bioluminescent sparkle)
        animateBioluminescence(sprite: sprite, baseScale: baseScale, tier: tier)
    }

    // MARK: - 1. Curved Organic Flight (Bay ngẫu nhiên theo quỹ đạo cong)

    private func animateFlight(container: SKNode, tier: FireflyTier) {
        let padding: CGFloat = 20
        let minX = padding
        let maxX = max(minX + 30, size.width - padding)
        let minY = padding + 15
        let maxY = max(minY + 30, size.height - padding - 15)

        let currentPos = container.position

        // Khoảng cách di chuyển và thời lượng mỗi bước bay tùy theo tầng
        let stepDist: CGFloat
        let duration: Double
        let arcVariance: CGFloat
        let pauseChance: Double
        let pauseDuration: Double

        switch tier {
        case .foreground:
            stepDist = CGFloat.random(in: 55...125)
            duration = Double.random(in: 4.5...7.5)
            arcVariance = CGFloat.random(in: 35...65)
            pauseChance = 0.45
            pauseDuration = Double.random(in: 0.8...2.2)

        case .midground:
            stepDist = CGFloat.random(in: 35...90)
            duration = Double.random(in: 2.8...5.2)
            arcVariance = CGFloat.random(in: 25...45)
            pauseChance = 0.55
            pauseDuration = Double.random(in: 0.6...1.8)

        case .background:
            stepDist = CGFloat.random(in: 15...45)
            duration = Double.random(in: 3.5...6.5)
            arcVariance = CGFloat.random(in: 12...25)
            pauseChance = 0.65
            pauseDuration = Double.random(in: 1.0...2.8)
        }

        // Chọn hướng di chuyển có cơ chế bẻ lái mềm mại (soft-steering) tránh bay ra ngoài màn hình
        var dx: CGFloat = 0
        var dy: CGFloat = 0

        let borderMargin: CGFloat = 60
        let isNearLeft = currentPos.x < minX + borderMargin
        let isNearRight = currentPos.x > maxX - borderMargin
        let isNearBottom = currentPos.y < minY + borderMargin
        let isNearTop = currentPos.y > maxY - borderMargin

        let steerMin: CGFloat = max(10, stepDist * 0.4)
        let steerMax: CGFloat = max(steerMin, stepDist)

        if isNearLeft {
            dx = CGFloat.random(in: steerMin...steerMax)
        } else if isNearRight {
            dx = -CGFloat.random(in: steerMin...steerMax)
        } else {
            let spread = max(10, stepDist)
            dx = CGFloat.random(in: -spread...spread)
        }

        if isNearBottom {
            dy = CGFloat.random(in: steerMin...steerMax)
        } else if isNearTop {
            dy = -CGFloat.random(in: steerMin...steerMax)
        } else {
            let spread = max(10, stepDist)
            dy = CGFloat.random(in: -spread...spread)
        }

        let targetX = min(max(currentPos.x + dx, minX), maxX)
        let targetY = min(max(currentPos.y + dy, minY), maxY)
        let targetPos = CGPoint(x: targetX, y: targetY)

        // Tính điểm uốn (Control Point) vuông góc để tạo đường cong Bezier tự nhiên
        let midX = (currentPos.x + targetPos.x) / 2
        let midY = (currentPos.y + targetPos.y) / 2
        let deltaX = targetPos.x - currentPos.x
        let deltaY = targetPos.y - currentPos.y
        let chordLen = hypot(deltaX, deltaY)

        var normX: CGFloat = 0
        var normY: CGFloat = 0
        if chordLen > 0.001 {
            normX = -deltaY / chordLen
            normY = deltaX / chordLen
        }

        let arcSide: CGFloat = Bool.random() ? 1.0 : -1.0
        let arcOffset = arcVariance * arcSide
        let ctrlX = min(max(midX + normX * arcOffset, minX), maxX)
        let ctrlY = min(max(midY + normY * arcOffset, minY), maxY)

        let path = CGMutablePath()
        path.move(to: currentPos)
        path.addQuadCurve(to: targetPos, control: CGPoint(x: ctrlX, y: ctrlY))

        let flightAction = SKAction.follow(path, asOffset: false, orientToPath: false, duration: duration)
        flightAction.timingMode = .easeInEaseOut

        var flightSequence: [SKAction] = [flightAction]

        // Ngắt nhịp nghỉ lơ lửng tại chỗ
        if Double.random(in: 0...1) < pauseChance {
            flightSequence.append(SKAction.wait(forDuration: pauseDuration))
        }

        flightSequence.append(SKAction.run { [weak self, weak container] in
            guard let self = self, let container = container, container.parent != nil else { return }
            self.animateFlight(container: container, tier: tier)
        })

        container.run(SKAction.sequence(flightSequence), withKey: "flight")
    }

    // MARK: - 2. Micro-Hovering Bobbing (Bồng bềnh vi mô)

    private func animateMicroHover(sprite: SKSpriteNode, tier: FireflyTier) {
        let bobDistance: CGFloat
        let bobDuration: Double

        switch tier {
        case .foreground:
            bobDistance = CGFloat.random(in: 4...8)
            bobDuration = Double.random(in: 1.6...2.6)
        case .midground:
            bobDistance = CGFloat.random(in: 2.5...5.5)
            bobDuration = Double.random(in: 1.2...2.0)
        case .background:
            bobDistance = CGFloat.random(in: 1.0...2.5)
            bobDuration = Double.random(in: 1.4...2.2)
        }

        let dirSignX: CGFloat = Bool.random() ? 1 : -1
        let dirSignY: CGFloat = Bool.random() ? 1 : -1

        let hoverUp = SKAction.moveBy(
            x: bobDistance * 0.6 * dirSignX,
            y: bobDistance * dirSignY,
            duration: bobDuration
        )
        hoverUp.timingMode = .easeInEaseOut

        let hoverDown = SKAction.moveBy(
            x: -bobDistance * 0.6 * dirSignX,
            y: -bobDistance * dirSignY,
            duration: bobDuration
        )
        hoverDown.timingMode = .easeInEaseOut

        sprite.run(SKAction.repeatForever(SKAction.sequence([hoverUp, hoverDown])), withKey: "microHover")
    }

    // MARK: - 3. Bioluminescence & Twinkling Sparkle (Nhấp nháy & Lấp lánh phát quang)

    private func animateBioluminescence(sprite: SKSpriteNode, baseScale: CGFloat, tier: FireflyTier) {
        // Độ trễ ngẫu nhiên ban đầu để các đom đóm không nhấp nháy đồng loạt
        let initialWait = SKAction.wait(forDuration: Double.random(in: 0.1...3.8))

        let pulseSequence: SKAction

        switch tier {
        case .foreground:
            // Cận cảnh: Nhịp thở chậm rãi, quầng sáng nở nhẹ nhàng
            let riseDuration = Double.random(in: 1.4...2.4)
            let fallDuration = Double.random(in: 1.6...2.8)
            let restDuration = Double.random(in: 0.8...2.2)

            let glowUp = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.75...0.90), duration: riseDuration),
                SKAction.scale(to: baseScale * CGFloat.random(in: 1.12...1.20), duration: riseDuration)
            ])
            glowUp.timingMode = .easeInEaseOut

            // Thở nhẹ ở đỉnh sáng
            let holdBreathe = SKAction.sequence([
                SKAction.scale(to: baseScale * 1.15, duration: 0.4),
                SKAction.scale(to: baseScale * 1.18, duration: 0.4)
            ])

            let glowDown = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.28), duration: fallDuration),
                SKAction.scale(to: baseScale * 0.88, duration: fallDuration)
            ])
            glowDown.timingMode = .easeInEaseOut

            let rest = SKAction.wait(forDuration: restDuration)
            pulseSequence = SKAction.sequence([glowUp, holdBreathe, glowDown, rest])

        case .midground:
            // Trung cảnh: Nhấp nháy đom đóm đặc trưng + Lấp lánh vi mô (micro-twinkle) ở đỉnh sáng
            let riseDuration = Double.random(in: 0.6...1.2)
            let fallDuration = Double.random(in: 0.8...1.5)
            let restDuration = Double.random(in: 0.5...2.2)

            let glowUp = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.90...1.0), duration: riseDuration),
                SKAction.scale(to: baseScale * CGFloat.random(in: 1.15...1.24), duration: riseDuration)
            ])
            glowUp.timingMode = .easeInEaseOut

            // ⭐️ Hiệu ứng Lấp lánh (Twinkle Sparkle): 1 đến 2 nhịp chớp nhẹ ở đỉnh sáng
            var shimmerActions: [SKAction] = []
            let shimmerCount = Int.random(in: 1...2)
            for _ in 0..<shimmerCount {
                let shimDuration = Double.random(in: 0.07...0.12)
                let dimShim = SKAction.group([
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.68...0.78), duration: shimDuration),
                    SKAction.scale(to: baseScale * 1.08, duration: shimDuration)
                ])
                let brightShim = SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: shimDuration),
                    SKAction.scale(to: baseScale * 1.22, duration: shimDuration)
                ])
                shimmerActions.append(contentsOf: [dimShim, brightShim])
            }
            let shimmerGroup = SKAction.sequence(shimmerActions)

            let glowDown = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.10...0.25), duration: fallDuration),
                SKAction.scale(to: baseScale * 0.82, duration: fallDuration)
            ])
            glowDown.timingMode = .easeInEaseOut

            let rest = SKAction.wait(forDuration: restDuration)
            pulseSequence = SKAction.sequence([glowUp, shimmerGroup, glowDown, rest])

        case .background:
            // Hậu cảnh: Đốm sáng xa chớp tắt tinh tế như tinh tú
            let flashDuration = Double.random(in: 0.25...0.50)
            let fadeDuration = Double.random(in: 0.40...0.80)
            let darkDuration = Double.random(in: 1.0...3.2)

            let flashOn = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.85...1.0), duration: flashDuration),
                SKAction.scale(to: baseScale * 1.18, duration: flashDuration)
            ])
            flashOn.timingMode = .easeInEaseOut

            let flashOff = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.18), duration: fadeDuration),
                SKAction.scale(to: baseScale * 0.80, duration: fadeDuration)
            ])
            flashOff.timingMode = .easeInEaseOut

            let waitDark = SKAction.wait(forDuration: darkDuration)
            pulseSequence = SKAction.sequence([flashOn, flashOff, waitDark])
        }

        sprite.run(SKAction.sequence([
            initialWait,
            SKAction.repeatForever(pulseSequence)
        ]), withKey: "bioluminescence")
    }

    // MARK: - Procedural Glow Texture Generator

    /// Sinh Texture phát quang nhiều tầng (Radial Gradient 5 bậc + Tâm rực sáng)
    public static func generateGlowTexture(
        coreColor: UIColor,
        haloColor: UIColor,
        outerColor: UIColor? = nil,
        dimension: CGFloat = 64
    ) -> SKTexture {
        let outer = outerColor ?? haloColor
        let size = CGSize(width: dimension, height: dimension)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0 // Đảm bảo độ sắc nét cao trên màn hình Retina

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let center = CGPoint(x: dimension / 2, y: dimension / 2)
            let maxRadius = dimension / 2

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                coreColor.cgColor,
                coreColor.withAlphaComponent(0.96).cgColor,
                haloColor.withAlphaComponent(0.85).cgColor,
                outer.withAlphaComponent(0.40).cgColor,
                outer.withAlphaComponent(0.12).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.10, 0.28, 0.54, 0.80, 1.0]

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: maxRadius,
                    options: .drawsAfterEndLocation
                )
            }

            // Tâm sáng trắng/vàng tập trung rực rỡ ở chính giữa
            let coreRadius = dimension * 0.08
            context.setFillColor(coreColor.cgColor)
            context.fillEllipse(in: CGRect(
                x: center.x - coreRadius,
                y: center.y - coreRadius,
                width: coreRadius * 2,
                height: coreRadius * 2
            ))
        }
        return SKTexture(image: image)
    }

    /// Giữ tương thích ngược với API cũ (2 màu)
    public static func generateGlowTexture(coreColor: UIColor, haloColor: UIColor) -> SKTexture {
        return generateGlowTexture(
            coreColor: coreColor,
            haloColor: haloColor,
            outerColor: haloColor,
            dimension: 64
        )
    }
}

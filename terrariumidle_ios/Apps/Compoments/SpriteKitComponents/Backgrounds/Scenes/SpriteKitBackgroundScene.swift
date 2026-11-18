//
//  SpriteKitBackgroundScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - SpriteKit Scene cho Phong cảnh nền động
public final class SpriteKitBackgroundScene: SKScene {
    // MARK: - Properties

    private var currentThemeId: String = "sky_sun_day"
    private var isConfigured = false

    // MARK: - Initializer

    public override init() {
        super.init(size: .zero)
        setupBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBasics()
    }

    private func setupBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }

    // MARK: - Configuration

    public func configure(themeId: String) {
        self.currentThemeId = themeId
        if size.width > 0 && size.height > 0 {
            rebuildScene()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        if !isConfigured && size.width > 0 && size.height > 0 {
            rebuildScene()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if size.width > 0 && size.height > 0 {
            rebuildScene()
        }
    }

    // MARK: - Rebuild Scene động hoàn toàn từ cấu hình JSON (Không cần switch thủ công)

    private func rebuildScene() {
        guard size.width > 0, size.height > 0 else { return }
        isConfigured = true
        removeAllChildren()
        removeAllActions()

        let item = ItemDataManager.shared.getLandscape(byIdOrImage: currentThemeId)

        // 1. Lớp màu nền Gradient động từ mảng skyGradient trong JSON
        buildGradientBackground(item: item)

        // 2. Các thành phần động nạp trực tiếp từ mảng elements trong JSON
        let activeElements = item?.elements ?? ["sun", "clouds"]
        for element in activeElements {
            switch element {
            case "sun":
                buildSunNode()
            case "sun_sunset":
                buildSunsetSunNode()
            case "clouds":
                buildDriftingClouds(count: 5, color: UIColor.white.withAlphaComponent(0.85))
            case "clouds_sunset":
                buildDriftingClouds(count: 6, color: UIColor(red: 1.0, green: 0.85, blue: 0.78, alpha: 0.75))
            case "clouds_dark":
                buildDriftingClouds(count: 7, color: UIColor(red: 0.45, green: 0.50, blue: 0.58, alpha: 0.85))
            case "clouds_night":
                buildDriftingClouds(count: 3, color: UIColor.white.withAlphaComponent(0.20))
            case "rain":
                buildRainEmitter(sksFile: item?.sksFile)
            case "moon_crescent":
                buildMoonNode(isFull: false)
            case "moon_full":
                buildMoonNode(isFull: true)
            case "stars":
                buildStarfield(count: 45)
            case "stars_dense":
                buildStarfield(count: 65)
            case "shooting_stars":
                buildShootingStars()
            default:
                break
            }
        }
    }

    // MARK: - 1. Gradient Background động từ JSON

    private func buildGradientBackground(item: ItemData?) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let gradientImage = renderer.image { ctx in
            let context = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            let colors: [CGColor]
            if let hexColors = item?.skyGradient, !hexColors.isEmpty {
                colors = hexColors.map { UIColor(hexString: $0).cgColor }
            } else {
                // Fallback mặc định ban ngày nếu JSON chưa khai báo gradient
                colors = [
                    UIColor(red: 0.42, green: 0.75, blue: 0.95, alpha: 1.0).cgColor,
                    UIColor(red: 0.78, green: 0.90, blue: 0.98, alpha: 1.0).cgColor,
                    UIColor(red: 0.92, green: 0.96, blue: 0.99, alpha: 1.0).cgColor
                ]
            }

            let locations: [CGFloat]
            if colors.count == 2 {
                locations = [0.0, 1.0]
            } else if colors.count == 3 {
                locations = [0.0, 0.55, 1.0]
            } else {
                locations = (0..<colors.count).map { CGFloat($0) / CGFloat(max(1, colors.count - 1)) }
            }

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: size.width / 2, y: size.height),
                    end: CGPoint(x: size.width / 2, y: 0),
                    options: []
                )
            }
        }

        let bgNode = SKSpriteNode(texture: SKTexture(image: gradientImage))
        bgNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bgNode.size = size
        bgNode.zPosition = -100
        addChild(bgNode)
    }

    // MARK: - 2. Sun & Sunset Nodes

    private func buildSunNode() {
        let sunTexture = Self.createSunTexture(color: UIColor(red: 1.0, green: 0.94, blue: 0.55, alpha: 1.0))
        let sun = SKSpriteNode(texture: sunTexture)
        sun.position = CGPoint(x: size.width * 0.78, y: size.height * 0.82)
        sun.zPosition = -50
        sun.setScale(0.85)

        // Hiệu ứng thở nhẹ của vầng hào quang
        let pulseUp = SKAction.scale(to: 0.92, duration: 3.5)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.82, duration: 3.5)
        pulseDown.timingMode = .easeInEaseOut
        sun.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))

        addChild(sun)
    }

    private func buildSunsetSunNode() {
        let sunTexture = Self.createSunTexture(color: UIColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 1.0))
        let sun = SKSpriteNode(texture: sunTexture)
        sun.position = CGPoint(x: size.width * 0.70, y: size.height * 0.65)
        sun.zPosition = -50
        sun.setScale(1.1)

        let pulseUp = SKAction.fadeAlpha(to: 0.95, duration: 4.0)
        let pulseDown = SKAction.fadeAlpha(to: 0.75, duration: 4.0)
        sun.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))

        addChild(sun)
    }

    // MARK: - 3. Moon & Starfield

    private func buildMoonNode(isFull: Bool) {
        let moonTexture = Self.createMoonTexture(isFull: isFull)
        let moon = SKSpriteNode(texture: moonTexture)
        moon.position = CGPoint(x: size.width * 0.75, y: size.height * 0.82)
        moon.zPosition = -50
        moon.setScale(0.85)

        let glowUp = SKAction.fadeAlpha(to: 1.0, duration: 3.0)
        let glowDown = SKAction.fadeAlpha(to: 0.75, duration: 3.0)
        moon.run(SKAction.repeatForever(SKAction.sequence([glowUp, glowDown])))

        addChild(moon)
    }

    private func buildStarfield(count: Int) {
        let starTexture = Self.createStarTexture()
        for _ in 0..<count {
            let star = SKSpriteNode(texture: starTexture)
            star.position = CGPoint(
                x: CGFloat.random(in: 10...(size.width - 10)),
                y: CGFloat.random(in: (size.height * 0.35)...size.height)
            )
            star.zPosition = -70
            let scale = CGFloat.random(in: 0.3...0.85)
            star.setScale(scale)
            star.alpha = CGFloat.random(in: 0.3...0.9)

            // Hiệu ứng lấp lánh ngẫu nhiên
            let twinkleWait = SKAction.wait(forDuration: Double.random(in: 0.5...3.0))
            let dim = SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.35), duration: Double.random(in: 0.8...1.5))
            let bright = SKAction.fadeAlpha(to: CGFloat.random(in: 0.85...1.0), duration: Double.random(in: 0.8...1.5))
            star.run(SKAction.repeatForever(SKAction.sequence([twinkleWait, dim, bright])))

            addChild(star)
        }
    }

    private func buildShootingStars() {
        // Mỗi 5 - 10s xuất hiện 1 vệt sao băng xẹt qua
        let wait = SKAction.wait(forDuration: 6.0, withRange: 3.0)
        let shoot = SKAction.run { [weak self] in
            guard let self = self else { return }
            let startX = CGFloat.random(in: (self.size.width * 0.3)...(self.size.width + 50))
            let startY = CGFloat.random(in: (self.size.height * 0.75)...(self.size.height + 40))

            let meteor = SKShapeNode(rectOf: CGSize(width: 40, height: 2), cornerRadius: 1)
            meteor.fillColor = .white
            meteor.strokeColor = .clear
            meteor.position = CGPoint(x: startX, y: startY)
            meteor.zRotation = -CGFloat.pi / 4
            meteor.zPosition = -45
            meteor.alpha = 0.9

            self.addChild(meteor)

            let moveAction = SKAction.moveBy(x: -180, y: -180, duration: 0.6)
            let fadeAction = SKAction.fadeOut(withDuration: 0.6)
            let group = SKAction.group([moveAction, fadeAction])

            meteor.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        run(SKAction.repeatForever(SKAction.sequence([wait, shoot])), withKey: "shootingStars")
    }

    // MARK: - 4. Drifting Clouds

    private func buildDriftingClouds(count: Int, color: UIColor) {
        let cloudTexture = Self.createCloudTexture(tintColor: color)

        for _ in 0..<count {
            let cloud = SKSpriteNode(texture: cloudTexture)
            let startY = CGFloat.random(in: (size.height * 0.45)...(size.height * 0.88))
            let startX = CGFloat.random(in: -50...(size.width + 50))
            cloud.position = CGPoint(x: startX, y: startY)
            cloud.zPosition = -30
            let scale = CGFloat.random(in: 0.6...1.2)
            cloud.setScale(scale)
            cloud.alpha = CGFloat.random(in: 0.6...0.95)

            addChild(cloud)

            // Mây trôi ngang màn hình từ trái qua phải
            let speed = Double.random(in: 35.0...65.0)
            let distanceToEnd = (size.width + 120) - cloud.position.x
            let initialDuration = max(1.0, speed * Double(distanceToEnd / (size.width + 240)))

            let initialMove = SKAction.moveTo(x: size.width + 120, duration: initialDuration)
            let resetPos = SKAction.run { [weak cloud] in
                cloud?.position.x = -120
            }
            let fullMove = SKAction.moveTo(x: size.width + 120, duration: speed)
            let loop = SKAction.repeatForever(SKAction.sequence([resetPos, fullMove]))

            cloud.run(SKAction.sequence([initialMove, loop]))
        }
    }

    // MARK: - 5. Rain Emitter

    private func buildRainEmitter(sksFile: String? = nil) {
        // 1. Ưu tiên tải hiệu ứng hạt mưa từ file Rain.sks hoặc tên file trong JSON
        let fileName = sksFile ?? "Rain.sks"
        if let emitter = SKEmitterNode(fileNamed: fileName) ?? SKEmitterNode(fileNamed: "Rain") {
            emitter.position = CGPoint(x: size.width / 2, y: size.height + 20)
            emitter.particlePositionRange = CGVector(dx: size.width + 80, dy: 20)
            emitter.zPosition = -20
            addChild(emitter)
            return
        }

        // 2. Fallback procedural nếu file .sks chưa được nạp
        let rainTexture = Self.createRainDropTexture()

        let spawnRain = SKAction.run { [weak self] in
            guard let self = self, self.size.width > 0, self.size.height > 0 else { return }

            for _ in 0..<3 {
                let drop = SKSpriteNode(texture: rainTexture)
                drop.position = CGPoint(
                    x: CGFloat.random(in: -30...(self.size.width + 60)),
                    y: self.size.height + 20
                )
                drop.zPosition = -20
                drop.alpha = CGFloat.random(in: 0.4...0.85)
                drop.setScale(CGFloat.random(in: 0.6...1.0))
                drop.zRotation = -0.25 // Nghiêng nhẹ theo hướng gió

                self.addChild(drop)

                let fallDistance = self.size.height + 40
                let fallDuration = Double.random(in: 0.45...0.75)
                let moveAction = SKAction.moveBy(x: -70, y: -fallDistance, duration: fallDuration)

                drop.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
            }
        }

        let waitAction = SKAction.wait(forDuration: 0.08)
        run(SKAction.repeatForever(SKAction.sequence([spawnRain, waitAction])), withKey: "rainLoop")
    }

    // MARK: - Procedural Texture Factories

    private static func createSunTexture(color: UIColor) -> SKTexture {
        let size = CGSize(width: 120, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let center = CGPoint(x: 60, y: 60)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                color.cgColor,
                color.withAlphaComponent(0.4).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.45, 1.0]

            if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(grad, startCenter: center, startRadius: 10, endCenter: center, endRadius: 58, options: [])
            }
        }
        return SKTexture(image: image)
    }

    private static func createMoonTexture(isFull: Bool) -> SKTexture {
        let size = CGSize(width: 80, height: 80)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            if isFull {
                // Trăng tròn phát sáng
                context.setFillColor(UIColor(red: 1.0, green: 0.98, blue: 0.88, alpha: 0.95).cgColor)
                context.fillEllipse(in: CGRect(x: 15, y: 15, width: 50, height: 50))
            } else {
                // Trăng lưỡi liềm vàng dịu
                let path = UIBezierPath()
                path.addArc(withCenter: CGPoint(x: 40, y: 40), radius: 24, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: true)
                path.addCurve(to: CGPoint(x: 40, y: 16), controlPoint1: CGPoint(x: 52, y: 50), controlPoint2: CGPoint(x: 52, y: 30))
                path.close()
                UIColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 0.95).setFill()
                path.fill()
            }
        }
        return SKTexture(image: image)
    }

    private static func createStarTexture() -> SKTexture {
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: 6, y: 6, width: 4, height: 4))
        }
        return SKTexture(image: image)
    }

    private static func createCloudTexture(tintColor: UIColor) -> SKTexture {
        let size = CGSize(width: 140, height: 60)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(tintColor.cgColor)
            // 3 hình tròn giao nhau tạo dáng mây bồng bềnh
            context.fillEllipse(in: CGRect(x: 10, y: 15, width: 45, height: 35))
            context.fillEllipse(in: CGRect(x: 40, y: 8, width: 55, height: 45))
            context.fillEllipse(in: CGRect(x: 80, y: 16, width: 48, height: 36))
            let cloudBase = UIBezierPath(roundedRect: CGRect(x: 20, y: 25, width: 95, height: 25), cornerRadius: 12)
            cloudBase.fill()
        }
        return SKTexture(image: image)
    }

    private static func createRainDropTexture() -> SKTexture {
        let size = CGSize(width: 3, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 0.75).setFill()
            let dropPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 3, height: 24), cornerRadius: 1.5)
            dropPath.fill()
        }
        return SKTexture(image: image)
    }
}

// MARK: - Extension chuyển đổi mã màu Hex từ JSON thành UIColor
private extension UIColor {
    convenience init(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

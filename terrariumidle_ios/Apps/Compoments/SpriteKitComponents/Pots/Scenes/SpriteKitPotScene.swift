//
//  SpriteKitPotScene.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - Pot Interactive Node Protocol
public protocol PotInteractiveNode: AnyObject {
    var asNode: SKNode { get }
    func playTapAnimation()

    /// Toạ độ điểm cắm cây (Mount Point) tính trong hệ quy chiếu của chậu (hoặc của Slot Scene)
    var plantMountPoint: CGPoint { get }

    /// Node chứa điểm cắm cây nếu có trong scene template (.sks)
    var plantMountNode: SKNode? { get }
}

extension PotInteractiveNode where Self: SKNode {
    public var asNode: SKNode { self }

    public var plantMountNode: SKNode? {
        return self.childNode(withName: "//plantMount") ?? self.childNode(withName: "plantMount")
    }

    public var plantMountPoint: CGPoint {
        if let mount = plantMountNode {
            return mount.parent?.convert(mount.position, to: self) ?? mount.position
        }
        // Fallback tự động dựa trên sprite chậu
        if let potSprite = (self.childNode(withName: "//potNode") as? SKSpriteNode) ?? (self.children.compactMap { $0 as? SKSpriteNode }.first) {
            let rimY: CGFloat
            if potSprite.anchorPoint.y >= 0.9 {
                // Chậu treo (anchor 0.5, 1.0)
                rimY = potSprite.position.y - potSprite.size.height * 0.65
            } else {
                // Chậu để bàn (anchor 0.5, 0.0)
                rimY = potSprite.position.y + potSprite.size.height * 0.88
            }
            return CGPoint(x: potSprite.position.x, y: rimY)
        }
        return CGPoint(x: 0, y: 50)
    }
}

// MARK: - SpriteKit Scene cho Chậu cây trong Terrarium
public final class SpriteKitPotScene: SKScene {
    // MARK: - Properties

    private var potNode: SKSpriteNode?
    private var customPotInteractive: PotInteractiveNode?
    private var shadowNode: SKNode?
    private var potId: String = "pot1"
    private var isHanging: Bool = false
    private var widthFill: CGFloat = 0.0
    private var baseScale: CGFloat = 1.0

    /// Danh sách hiệu ứng khi tap vào chậu (dùng cho chậu generic fallback)
    public var tapEffects: [PotTapEffect] = []

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
        anchorPoint = CGPoint(x: 0.5, y: 0.0) // Luôn neo gốc toạ độ tại đáy giữa (Bottom-Center)
    }

    // MARK: - Configuration

    public func configure(potId: String, isHanging: Bool = false, widthFill: CGFloat = 0.0) {
        let cleanFill = min(max(widthFill, 0.0), 1.0)
        let changed = self.potId != potId || self.isHanging != isHanging || abs(self.widthFill - cleanFill) > 0.001
        self.potId = potId
        self.isHanging = isHanging
        self.widthFill = cleanFill

        if (changed || (potNode == nil && customPotInteractive == nil)) && size.width > 0 && size.height > 0 {
            buildPot()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        view.isPaused = false
        self.isPaused = false
        if potNode == nil && customPotInteractive == nil && size.width > 0 && size.height > 0 {
            buildPot()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if (potNode == nil && customPotInteractive == nil) || abs(oldSize.width - size.width) > 2 || abs(oldSize.height - size.height) > 2 {
            if size.width > 0 && size.height > 0 {
                buildPot()
            }
        }
    }

    // MARK: - Build Pot Node

    private func buildPot() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()
        potNode = nil
        customPotInteractive = nil
        shadowNode = nil
        anchorPoint = CGPoint(x: 0.5, y: 0.0) // Luôn neo gốc tọa độ tại đáy giữa

        let cleanId = potId.lowercased().trimmingCharacters(in: .whitespaces)

        // Sử dụng trực tiếp widthFill được cấu hình từ View (0.0 = chỉ fillheight, 100% giữ nguyên aspect ratio, không méo)
        let effectiveFill = min(max(widthFill, 0.0), 1.0)

        // TỰ ĐỘNG NẠP CÁC NODE CHẬU CHUYÊN BIỆT (Pot1 -> Pot14) QUA POTFACTORY
        let pot = PotFactory.createPot(id: cleanId, containerSize: size, isHanging: isHanging, widthFill: effectiveFill)
        pot.asNode.position = CGPoint(x: 0, y: isHanging ? size.height : 0)
        addChild(pot.asNode)
        self.customPotInteractive = pot
    }

    // MARK: - Animation: Phản hồi khi chạm vào chậu

    public func playTapAnimation() {
        if let custom = customPotInteractive {
            custom.playTapAnimation()
            return
        }
    }

    // MARK: - Soft Shadow Generator

    /// Tạo texture bóng đổ radial gradient mềm mại, tự nhiên, không bị viền sắc
    public static func createSoftShadowTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let w = max(16.0, width)
        let h = max(6.0, height)
        let size = CGSize(width: w, height: h)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            let colors = [
                UIColor.black.withAlphaComponent(0.28).cgColor,
                UIColor.black.withAlphaComponent(0.14).cgColor,
                UIColor.black.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.52, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }

            cg.saveGState()
            cg.translateBy(x: size.width / 2.0, y: size.height / 2.0)
            cg.scaleBy(x: 1.0, y: size.height / size.width)
            let radius = size.width / 2.0
            cg.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: radius, options: [.drawsAfterEndLocation])
            cg.restoreGState()
        }
        return SKTexture(image: img)
    }

    // MARK: - Base Width Ratio Detection

    private static let knownBaseRatios: [String: CGFloat] = [
        "pot1": 0.52,
        "pot2": 0.78,
        "pot3": 0.22,
        "pot4": 0.45,
        "pot5": 0.55,
        "pot6": 0.40,
        "pot7": 0.50,
        "pot8": 0.60
    ]

    /// Đo tỉ lệ bề rộng đáy chậu thực tế so với tổng chiều rộng ảnh
    private static func detectBaseRatio(for potId: String, image: UIImage?) -> CGFloat {
        let cleanId = potId.lowercased().trimmingCharacters(in: .whitespaces)
        if let ratio = knownBaseRatios[cleanId] {
            return ratio
        }
        guard let cgImg = image?.cgImage else { return 0.50 }
        let w = cgImg.width
        let h = cgImg.height
        guard w > 0, h > 0 else { return 0.50 }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        var rawData = [UInt8](repeating: 0, count: bytesPerRow * h)
        guard let context = CGContext(
            data: &rawData,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return 0.50 }

        context.draw(cgImg, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Trong toạ độ CGContext, y=0 là đáy dưới cùng
        let maxScanY = min(h, max(1, Int(Double(h) * 0.15)))
        for y in 0..<maxScanY {
            var minX = w, maxX = 0
            let rowOffset = y * bytesPerRow
            for x in 0..<w {
                let alpha = rawData[rowOffset + x * bytesPerPixel + 3]
                if alpha > 35 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                }
            }
            if minX < maxX && (maxX - minX) > 8 {
                return CGFloat(maxX - minX) / CGFloat(w)
            }
        }
        return 0.50
    }

    // MARK: - Texture Loader & Procedural Fallback

    private func loadPotTextureAndImage() -> (texture: SKTexture, image: UIImage?) {
        let potNumber = potId.filter(\.isNumber)
        let candidates = [
            "\(potId)-Asset-1@4.167x",
            potId,
            "\(potId)-Asset-1",
            "\(potId)_Asset-1@4.167x",
            "\(potId)_Asset-1",
            "Pot\(potNumber)-1@4.167x",
            "Pot\(potNumber)-1",
            "\(potId.capitalized)-1@4.167x",
            "\(potId.capitalized)-1",
            "i_\(potId)",
            "pot_\(potId)"
        ]
        for name in candidates {
            if let image = UIImage(named: name) {
                return (SKTexture(image: image), image)
            }
        }

        if let imageField = ItemDataManager.shared.getPot(byId: potId)?.image {
            for name in [imageField, "\(imageField)@4.167x"] {
                if let image = UIImage(named: name) {
                    return (SKTexture(image: image), image)
                }
            }
        }

        let proc = Self.generateProceduralPotTexture(potId: potId, isHanging: isHanging)
        return (proc.texture, proc.image)
    }

    public static func generateProceduralPotTexture(potId: String, isHanging: Bool) -> (texture: SKTexture, image: UIImage) {
        let size = CGSize(width: 120, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            if isHanging {
                // Dây treo macrame từ trên xuống
                let stringPath = UIBezierPath()
                stringPath.move(to: CGPoint(x: 60, y: 4))
                stringPath.addLine(to: CGPoint(x: 25, y: 50))
                stringPath.move(to: CGPoint(x: 60, y: 4))
                stringPath.addLine(to: CGPoint(x: 95, y: 50))
                UIColor(red: 0.82, green: 0.75, blue: 0.65, alpha: 0.9).setStroke()
                stringPath.lineWidth = 1.8
                stringPath.stroke()

                // Chậu bán cầu treo
                let potRect = CGRect(x: 22, y: 45, width: 76, height: 48)
                let potPath = UIBezierPath(roundedRect: potRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 36, height: 36))
                UIColor(red: 0.94, green: 0.90, blue: 0.85, alpha: 0.98).setFill()
                potPath.fill()

                // Viền miệng chậu
                let rim = UIBezierPath(roundedRect: CGRect(x: 20, y: 42, width: 80, height: 8), cornerRadius: 3)
                UIColor(red: 0.85, green: 0.78, blue: 0.70, alpha: 1.0).setFill()
                rim.fill()
            } else {
                // Chậu gốm nung Terracotta cổ điển hình thang
                let potPath = UIBezierPath()
                potPath.move(to: CGPoint(x: 20, y: 22))
                potPath.addLine(to: CGPoint(x: 100, y: 22))
                potPath.addLine(to: CGPoint(x: 88, y: 88))
                potPath.addLine(to: CGPoint(x: 32, y: 88))
                potPath.close()

                UIColor(red: 0.85, green: 0.48, blue: 0.32, alpha: 0.98).setFill()
                potPath.fill()

                // Vành miệng chậu
                let rim = UIBezierPath(roundedRect: CGRect(x: 15, y: 14, width: 90, height: 12), cornerRadius: 4)
                UIColor(red: 0.90, green: 0.54, blue: 0.36, alpha: 1.0).setFill()
                rim.fill()

                // Họa tiết dải màu trang trí nhẹ trên thân chậu
                let band = UIBezierPath()
                band.move(to: CGPoint(x: 25, y: 40))
                band.addLine(to: CGPoint(x: 95, y: 40))
                UIColor.white.withAlphaComponent(0.35).setStroke()
                band.lineWidth = 2.0
                band.stroke()
            }
        }
        return (SKTexture(image: image), image)
    }
}

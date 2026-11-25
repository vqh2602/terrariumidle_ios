//
//  OverlayEffectConfig.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import UIKit

// MARK: - Kiểu hiệu ứng Overlay
public enum OverlayKind: Sendable {
    case fallingLeaves(density: LeafDensity, wind: WindDirection, speed: LeafSpeed)
    case fireflies(count: Int)
}

// MARK: - Cấu hình chi tiết cho từng loại Overlay trong effects_data.json
public struct OverlayEffectConfig: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let kind: OverlayKind

    public init(id: String, name: String, kind: OverlayKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }

    /// Lấy danh sách cấu hình mặc định tương ứng với effects_data.json
    public static func config(for overlayId: String) -> OverlayEffectConfig? {
        switch overlayId {
        case "overlay1":
            // Lá rơi xanh ngọc
            return OverlayEffectConfig(
                id: "overlay1",
                name: "Lá rơi xanh ngọc".tr,
                kind: .fallingLeaves(density: .medium, wind: .gentleRight, speed: .normal)
            )

        case "overlay2":
            // Lá rơi mùa thu: gió mạnh hơn chút, lá thu nhiều màu sắc
            return OverlayEffectConfig(
                id: "overlay2",
                name: "Lá rơi mùa thu".tr,
                kind: .fallingLeaves(density: .medium, wind: .breezeRight, speed: .normal)
            )

        case "overlay3":
            // Cánh hoa oải hương: cánh hoa mỏng nhẹ rơi từ tốn, bay nhẹ sang trái
            return OverlayEffectConfig(
                id: "overlay3",
                name: "Cánh hoa oải hương".tr,
                kind: .fallingLeaves(density: .medium, wind: .gentleLeft, speed: .slow)
            )

        case "overlay4":
            // Đom đóm: phát sáng bay lượn
            return OverlayEffectConfig(
                id: "overlay4",
                name: "Đom đóm".tr,
                kind: .fireflies(count: 26)
            )

        case "overlay5":
            // Hoa đào rơi: cánh hoa đào bồng bềnh lượn theo gió đổi hướng
            return OverlayEffectConfig(
                id: "overlay5",
                name: "Hoa đào rơi".tr,
                kind: .fallingLeaves(density: .medium, wind: .variable, speed: .slow)
            )

        case "overlay6":
            // Lá phong hoàng kim
            return OverlayEffectConfig(
                id: "overlay6",
                name: "Lá phong hoàng kim".tr,
                kind: .fallingLeaves(density: .medium, wind: .breezeRight, speed: .normal)
            )

        default:
            return nil
        }
    }

    /// Sinh tối đa 6 ảnh procedural tùy theo từng chủ đề overlay
    public static func generateTextures(for overlayId: String) -> [SKTexture] {
        switch overlayId {
        case "overlay1":
            return (0..<6).map { generateEmeraldLeafTexture(index: $0) }
        case "overlay2":
            return (0..<6).map { generateAutumnLeafTexture(index: $0) }
        case "overlay3":
            return (0..<6).map { generateLavenderPetalTexture(index: $0) }
        case "overlay5":
            return (0..<6).map { generateSakuraPetalTexture(index: $0) }
        case "overlay6":
            return (0..<6).map { generateAutumnLeafTexture(index: $0) }
        default:
            return (0..<6).map { FallingLeavesScene.generateProceduralLeafTexture(index: $0) }
        }
    }

    // MARK: - 1. Bộ lá xanh ngọc (overlay1)
    private static func generateEmeraldLeafTexture(index: Int) -> SKTexture {
        let size = CGSize(width: 36, height: 48)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let greens: [(UIColor, UIColor)] = [
                (UIColor(red: 0.16, green: 0.68, blue: 0.38, alpha: 0.95), UIColor(red: 0.10, green: 0.48, blue: 0.25, alpha: 0.7)),
                (UIColor(red: 0.22, green: 0.78, blue: 0.45, alpha: 0.95), UIColor(red: 0.14, green: 0.55, blue: 0.30, alpha: 0.7)),
                (UIColor(red: 0.12, green: 0.60, blue: 0.42, alpha: 0.95), UIColor(red: 0.08, green: 0.42, blue: 0.30, alpha: 0.7)),
                (UIColor(red: 0.35, green: 0.82, blue: 0.35, alpha: 0.95), UIColor(red: 0.24, green: 0.58, blue: 0.24, alpha: 0.7)),
                (UIColor(red: 0.20, green: 0.72, blue: 0.52, alpha: 0.95), UIColor(red: 0.12, green: 0.50, blue: 0.36, alpha: 0.7)),
                (UIColor(red: 0.42, green: 0.84, blue: 0.28, alpha: 0.95), UIColor(red: 0.28, green: 0.60, blue: 0.18, alpha: 0.7))
            ]
            let color = greens[index % greens.count]
            drawLeafShape(context: context, size: size, bodyColor: color.0, veinColor: color.1)
        }
        return SKTexture(image: image)
    }

    // MARK: - 2. Bộ lá mùa thu (overlay2)
    private static func generateAutumnLeafTexture(index: Int) -> SKTexture {
        let size = CGSize(width: 40, height: 48)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let autumnColors: [(UIColor, UIColor)] = [
                // Phong đỏ
                (UIColor(red: 0.88, green: 0.26, blue: 0.20, alpha: 0.95), UIColor(red: 0.62, green: 0.14, blue: 0.10, alpha: 0.7)),
                // Cam hổ phách
                (UIColor(red: 0.94, green: 0.50, blue: 0.16, alpha: 0.95), UIColor(red: 0.70, green: 0.32, blue: 0.08, alpha: 0.7)),
                // Vàng ngân hạnh
                (UIColor(red: 0.96, green: 0.78, blue: 0.18, alpha: 0.95), UIColor(red: 0.76, green: 0.56, blue: 0.10, alpha: 0.7)),
                // Nâu hạt dẻ vàng
                (UIColor(red: 0.82, green: 0.44, blue: 0.22, alpha: 0.95), UIColor(red: 0.56, green: 0.28, blue: 0.12, alpha: 0.7)),
                // Đỏ tía thẫm
                (UIColor(red: 0.75, green: 0.18, blue: 0.28, alpha: 0.95), UIColor(red: 0.50, green: 0.10, blue: 0.18, alpha: 0.7)),
                // Vàng chanh chuyển thu
                (UIColor(red: 0.92, green: 0.68, blue: 0.18, alpha: 0.95), UIColor(red: 0.72, green: 0.48, blue: 0.10, alpha: 0.7))
            ]
            let color = autumnColors[index % autumnColors.count]

            if index % 2 == 0 {
                // Lá phong 3 đỉnh
                drawMapleLeafShape(context: context, size: size, bodyColor: color.0, veinColor: color.1)
            } else {
                // Lá elip nhọn
                drawLeafShape(context: context, size: size, bodyColor: color.0, veinColor: color.1)
            }
        }
        return SKTexture(image: image)
    }

    // MARK: - 3. Cánh hoa oải hương (overlay3)
    private static func generateLavenderPetalTexture(index: Int) -> SKTexture {
        let size = CGSize(width: 24, height: 38)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let lavenders: [UIColor] = [
                UIColor(red: 0.72, green: 0.60, blue: 0.88, alpha: 0.92), // Tím nhạt
                UIColor(red: 0.62, green: 0.48, blue: 0.82, alpha: 0.92), // Tím oải hương đậm
                UIColor(red: 0.78, green: 0.68, blue: 0.94, alpha: 0.92), // Tím sương mù
                UIColor(red: 0.55, green: 0.42, blue: 0.76, alpha: 0.92), // Tím hoàng gia
                UIColor(red: 0.82, green: 0.72, blue: 0.96, alpha: 0.92), // Lilac
                UIColor(red: 0.68, green: 0.54, blue: 0.86, alpha: 0.92)  // Tím tím ngọc
            ]
            let color = lavenders[index % lavenders.count]

            // Vẽ cánh hoa hình giọt nước thon dài mềm mại
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 12, y: 3))
            path.addCurve(to: CGPoint(x: 12, y: 35),
                          controlPoint1: CGPoint(x: 23, y: 15),
                          controlPoint2: CGPoint(x: 18, y: 30))
            path.addCurve(to: CGPoint(x: 12, y: 3),
                          controlPoint1: CGPoint(x: 6, y: 30),
                          controlPoint2: CGPoint(x: 1, y: 15))
            path.close()

            color.setFill()
            path.fill()

            // Gân nhẹ ở giữa cánh hoa
            let midVein = UIBezierPath()
            midVein.move(to: CGPoint(x: 12, y: 7))
            midVein.addLine(to: CGPoint(x: 12, y: 28))
            UIColor.white.withAlphaComponent(0.35).setStroke()
            midVein.lineWidth = 0.8
            midVein.stroke()
        }
        return SKTexture(image: image)
    }

    // MARK: - 5. Cánh hoa anh đào rơi (overlay5)
    private static func generateSakuraPetalTexture(index: Int) -> SKTexture {
        let size = CGSize(width: 28, height: 34)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let context = ctx.cgContext
            let pinks: [UIColor] = [
                UIColor(red: 0.98, green: 0.78, blue: 0.84, alpha: 0.93), // Hồng phấn sakura
                UIColor(red: 1.00, green: 0.84, blue: 0.88, alpha: 0.93), // Hồng pastel nhạt
                UIColor(red: 0.96, green: 0.70, blue: 0.78, alpha: 0.93), // Hồng đào thắm
                UIColor(red: 1.00, green: 0.88, blue: 0.92, alpha: 0.93), // Trắng ánh hồng
                UIColor(red: 0.94, green: 0.65, blue: 0.75, alpha: 0.93), // Hồng đậm
                UIColor(red: 0.98, green: 0.74, blue: 0.82, alpha: 0.93)  // Hồng cánh sen
            ]
            let color = pinks[index % pinks.count]

            // Cánh hoa đào với chỏm có vết khuyết đặc trưng (notch)
            let path = UIBezierPath()
            let midX: CGFloat = 14
            path.move(to: CGPoint(x: midX, y: 6)) // Điểm khuyết ở đỉnh
            path.addLine(to: CGPoint(x: midX + 3, y: 3))
            path.addCurve(to: CGPoint(x: midX, y: 31),
                          controlPoint1: CGPoint(x: 27, y: 10),
                          controlPoint2: CGPoint(x: 20, y: 27))
            path.addCurve(to: CGPoint(x: midX - 3, y: 3),
                          controlPoint1: CGPoint(x: 8, y: 27),
                          controlPoint2: CGPoint(x: 1, y: 10))
            path.addLine(to: CGPoint(x: midX, y: 6))
            path.close()

            color.setFill()
            path.fill()

            // Vệt highlight nhẹ
            let highlight = UIBezierPath()
            highlight.move(to: CGPoint(x: midX, y: 10))
            highlight.addLine(to: CGPoint(x: midX, y: 24))
            UIColor.white.withAlphaComponent(0.4).setStroke()
            highlight.lineWidth = 1.0
            highlight.stroke()
        }
        return SKTexture(image: image)
    }

    // MARK: - Helper vẽ dáng lá chuẩn
    private static func drawLeafShape(context: CGContext, size: CGSize, bodyColor: UIColor, veinColor: UIColor) {
        let midX = size.width / 2
        let topY: CGFloat = 4
        let bottomY = size.height - 5

        let path = UIBezierPath()
        path.move(to: CGPoint(x: midX, y: topY))
        path.addCurve(
            to: CGPoint(x: midX, y: bottomY),
            controlPoint1: CGPoint(x: midX + 16, y: topY + 10),
            controlPoint2: CGPoint(x: midX + 13, y: bottomY - 8)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: topY),
            controlPoint1: CGPoint(x: midX - 13, y: bottomY - 8),
            controlPoint2: CGPoint(x: midX - 16, y: topY + 10)
        )
        path.close()

        bodyColor.setFill()
        path.fill()

        // Gân lá chính
        let vein = UIBezierPath()
        vein.move(to: CGPoint(x: midX, y: topY + 4))
        vein.addLine(to: CGPoint(x: midX, y: bottomY + 2))
        veinColor.setStroke()
        vein.lineWidth = 1.1
        vein.stroke()
    }

    // MARK: - Helper vẽ dáng lá phong (Maple)
    private static func drawMapleLeafShape(context: CGContext, size: CGSize, bodyColor: UIColor, veinColor: UIColor) {
        let midX = size.width / 2
        let path = UIBezierPath()
        path.move(to: CGPoint(x: midX, y: 5)) // Đỉnh giữa
        path.addLine(to: CGPoint(x: midX + 9, y: 15))
        path.addLine(to: CGPoint(x: midX + 17, y: 18)) // Cánh phải
        path.addLine(to: CGPoint(x: midX + 10, y: 27))
        path.addLine(to: CGPoint(x: midX + 12, y: 38))
        path.addLine(to: CGPoint(x: midX, y: 44)) // Đáy cuống
        path.addLine(to: CGPoint(x: midX - 12, y: 38))
        path.addLine(to: CGPoint(x: midX - 10, y: 27))
        path.addLine(to: CGPoint(x: midX - 17, y: 18)) // Cánh trái
        path.addLine(to: CGPoint(x: midX - 9, y: 15))
        path.close()

        bodyColor.setFill()
        path.fill()

        // Gân lá
        let vein = UIBezierPath()
        vein.move(to: CGPoint(x: midX, y: 8))
        vein.addLine(to: CGPoint(x: midX, y: 42))
        vein.move(to: CGPoint(x: midX, y: 22))
        vein.addLine(to: CGPoint(x: midX + 12, y: 19))
        vein.move(to: CGPoint(x: midX, y: 22))
        vein.addLine(to: CGPoint(x: midX - 12, y: 19))
        veinColor.setStroke()
        vein.lineWidth = 1.0
        vein.stroke()
    }
}

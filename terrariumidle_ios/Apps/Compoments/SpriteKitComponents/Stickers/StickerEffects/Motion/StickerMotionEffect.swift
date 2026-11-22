//
//  StickerMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Sticker Motion Context

/// Ngữ cảnh chuyển động vật lý của sticker khi nhàn rỗi hoặc khi nhận tương tác Tap
public struct StickerMotionContext {
    /// Node mục tiêu chính nhận chuyển động (với sticker treo là hangingRigNode, sticker để bàn là stickerNode)
    public let targetNode: SKNode
    /// Sprite hiển thị dây treo (chỉ có ở sticker treo)
    public let ropeNode: SKSpriteNode?
    /// Sprite hiển thị thân sticker
    public let bodyNode: SKSpriteNode?
    /// Ruy băng / cánh tay / chi tiết trang trí phía trước (nếu có)
    public let frontDecorations: [SKNode]
    /// Tọa độ gốc ban đầu của targetNode (để reset chống trôi tọa độ)
    public let initialPosition: CGPoint
    /// Cờ xác định sticker treo hay sticker để bàn
    public let isHanging: Bool
    /// Kích thước khung chứa của sticker
    public let containerSize: CGSize
    /// Callback gọi khi chuỗi hiệu ứng kết thúc
    public let onComplete: (() -> Void)?

    public init(
        targetNode: SKNode,
        ropeNode: SKSpriteNode? = nil,
        bodyNode: SKSpriteNode? = nil,
        frontDecorations: [SKNode] = [],
        initialPosition: CGPoint = .zero,
        isHanging: Bool = true,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        self.targetNode = targetNode
        self.ropeNode = ropeNode
        self.bodyNode = bodyNode
        self.frontDecorations = frontDecorations
        self.initialPosition = initialPosition
        self.isHanging = isHanging
        self.containerSize = containerSize
        self.onComplete = onComplete
    }
}

// MARK: - Sticker Motion Effect Protocol

/// Giao diện chuẩn cho mọi hiệu ứng chuyển động đung đưa theo gió / nảy / rung lắc của Sticker
public protocol StickerMotionEffect: AnyObject {
    /// Tên định danh của hiệu ứng chuyển động
    var name: String { get }

    /// Bắt đầu hiệu ứng chuyển động nhàn rỗi (idle animation, ví dụ đung đưa nhẹ theo gió)
    func startIdle(context: StickerMotionContext)

    /// Dừng hiệu ứng chuyển động nhàn rỗi
    func stopIdle(context: StickerMotionContext)

    /// Áp dụng hiệu ứng phản hồi khi người dùng chạm (tap/click) vào sticker
    func apply(context: StickerMotionContext)
}

extension StickerMotionEffect {
    public func startIdle(context: StickerMotionContext) {}
    public func stopIdle(context: StickerMotionContext) {
        context.targetNode.removeAction(forKey: "sticker_idle_action")
        context.targetNode.removeAction(forKey: "sticker_idle_drift")
    }
}

// MARK: - Sticker Motion Effect Types

/// Danh mục các loại hiệu ứng chuyển động Sticker có sẵn trong game
public enum StickerMotionEffectType: String, CaseIterable {
    /// Sticker treo: Tự đung đưa bồng bềnh theo gió mềm mại (Mặc định: Sticker1 - Sunshine doll)
    case windSway = "windSway"
    /// Sticker mèo thần tài: Tay vẫy liên tục quanh khớp vai + thân nảy đàn hồi (Mặc định: Sticker2 - Maneki-neko)
    case luckyCat = "luckyCat"
    /// Sticker đèn cá chép: Đung đưa trong gió lúc mạnh lúc nhẹ uốn lượn (Mặc định: Sticker3 - Koi windsock)
    case koiWindSway = "koiWindSway"
    /// Sticker đèn lồng thắp sáng: Đung đưa đầm chắc + nến bập bùng (Mặc định: Sticker4 - Candle lantern)
    case candleLantern = "candleLantern"
    /// Sticker treo con lắc đàn hồi: Đu đưa nhịp nhanh kết hợp nhún nảy trục Y
    case elasticSwing = "elasticSwing"
    /// Sticker để bàn / dán tường: Nén nảy Squash & Stretch lò xo đàn hồi tiêu chuẩn
    case standardBounce = "standardBounce"
    /// Rung rinh bay bổng: Micro flutter tần số cao
    case subtleFlutter = "subtleFlutter"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> StickerMotionEffect {
        switch self {
        case .windSway:
            return WindSwayStickerMotionEffect()
        case .luckyCat:
            return LuckyCatMotionEffect()
        case .koiWindSway:
            return KoiWindSwayStickerMotionEffect()
        case .candleLantern:
            return CandleLanternMotionEffect()
        case .elasticSwing:
            return ElasticSwingStickerMotionEffect()
        case .standardBounce:
            return StandardBounceStickerMotionEffect()
        case .subtleFlutter:
            return SubtleFlutterStickerMotionEffect()
        }
    }
}

// MARK: - Sticker Motion Effect Factory

/// Nhà máy khởi tạo hiệu ứng chuyển động động từ Type, Name hoặc cấu hình JSON
public struct StickerMotionEffectFactory {
    /// Khởi tạo hiệu ứng từ tên định danh (chuỗi text case-insensitive)
    public static func create(named name: String) -> StickerMotionEffect {
        let cleanName = name.trimmingCharacters(in: .whitespaces).lowercased()
        switch cleanName {
        case "windsway", "wind", "sway", "doll":
            return WindSwayStickerMotionEffect()
        case "luckycat", "cat", "manekineko", "wavingarm":
            return LuckyCatMotionEffect()
        case "koiwindsway", "koi", "koifish", "fishwind":
            return KoiWindSwayStickerMotionEffect()
        case "candlelantern", "candle", "lantern", "flame":
            return CandleLanternMotionEffect()
        case "elasticswing", "swing", "pendulum":
            return ElasticSwingStickerMotionEffect()
        case "standardbounce", "bounce", "spring":
            return StandardBounceStickerMotionEffect()
        case "subtleflutter", "flutter", "jiggle":
            return SubtleFlutterStickerMotionEffect()
        default:
            return WindSwayStickerMotionEffect()
        }
    }

    /// Khởi tạo hiệu ứng từ enum type
    public static func create(type: StickerMotionEffectType) -> StickerMotionEffect {
        return type.createEffect()
    }
}

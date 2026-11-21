//
//  StickerTapEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Sticker Tap Effect Protocol

/// Giao diện chuẩn cho mọi hiệu ứng thị giác dạng hạt / ánh sáng khi click/tap vào Sticker
public protocol StickerTapEffect: AnyObject {
    /// Tên định danh của hiệu ứng
    var name: String { get }

    /// Kích hoạt hiệu ứng visual / hạt / ánh sáng
    /// - Parameters:
    ///   - targetNode: Node nhận tương tác của sticker
    ///   - containerNode: Node gốc chứa sticker để add các element thị giác (tránh bị méo bởi scale biến dạng)
    ///   - isHanging: Xác định sticker treo hay để bàn
    func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool)
}

// MARK: - Sticker Tap Effect Types

/// Danh mục các loại hiệu ứng tap có sẵn cho Sticker
public enum StickerTapEffectType: String, CaseIterable {
    /// Mặt trời vàng rực rỡ tỏa sáng kèm các tia nắng xoay tròn ấm áp (Mặc định: Sticker1 - Sunshine doll)
    case sunRadiance = "sunRadiance"
    /// Bung tỏa chùm ngôi sao 4 cánh lấp lánh (Sparkle Star Burst)
    case sparkleBurst = "sparkleBurst"
    /// Cầu vồng rực rỡ sau mưa (Rainbow Glow)
    case rainbowGlow = "rainbowGlow"
    /// Vòng hào quang vàng kim linh thiêng (Golden Aura)
    case goldenAura = "goldenAura"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> StickerTapEffect {
        switch self {
        case .sunRadiance:
            return SunRadianceEffect()
        case .sparkleBurst:
            return SparkleBurstStickerEffect()
        case .rainbowGlow:
            return RainbowGlowEffect()
        case .goldenAura:
            return GoldenAuraEffect()
        }
    }
}

// MARK: - Sticker Tap Effect Factory

/// Nhà máy khởi tạo hiệu ứng động từ Type, Name hoặc cấu hình JSON
public struct StickerTapEffectFactory {
    /// Khởi tạo hiệu ứng từ tên định danh (chuỗi text case-insensitive)
    public static func create(named name: String) -> StickerTapEffect {
        let cleanName = name.trimmingCharacters(in: .whitespaces).lowercased()
        switch cleanName {
        case "sunradiance", "sun", "sunshine", "sunbeam", "solar":
            return SunRadianceEffect()
        case "sparkleburst", "sparkle", "stars", "glitter":
            return SparkleBurstStickerEffect()
        case "rainbowglow", "rainbow", "arc":
            return RainbowGlowEffect()
        case "goldenaura", "aura", "halo", "gold":
            return GoldenAuraEffect()
        default:
            return SunRadianceEffect()
        }
    }

    /// Khởi tạo hiệu ứng từ enum type
    public static func create(type: StickerTapEffectType) -> StickerTapEffect {
        return type.createEffect()
    }
}

//
//  PotTapEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SpriteKit
import UIKit

// MARK: - Pot Tap Effect Protocol

/// Giao diện chuẩn cho mọi hiệu ứng thị giác được kích hoạt khi click/tap vào chậu cây
public protocol PotTapEffect: AnyObject {
    /// Tên định danh của hiệu ứng
    var name: String { get }

    /// Kích hoạt hiệu ứng hạt / ánh sáng / visual
    /// - Parameters:
    ///   - potNode: Sprite hiển thị của chậu cây
    ///   - containerNode: Node gốc chứa chậu để add các hạt/phần tử (không bị méo bởi scale biến dạng của potNode)
    ///   - isHanging: Có phải chậu treo hay chậu đứng
    func trigger(on potNode: SKSpriteNode, in containerNode: SKNode, isHanging: Bool)
}

// MARK: - Pot Tap Effect Types

/// Danh mục các loại hiệu ứng tap có sẵn trong game
public enum PotTapEffectType: String, CaseIterable {
    /// Chậu 1: Bung tỏa chùm ngôi sao 4 cánh lấp lánh (Sparkle Glitter Burst)
    case sparkleBurst = "sparkleBurst"
    /// Chậu 2: Vệt ánh vàng kim óng ánh (Gold Glint)
    case goldGlint = "goldGlint"
    /// Chậu 3: Bụi đá xám bạc (Stone Dust)
    case stoneDust = "stoneDust"
    /// Chậu 4: Chùm trái tim hồng ngọc bay bổng (Heart Burst)
    case heartBurst = "heartBurst"
    /// Chậu 5: Ánh gốm nung sắc nét (Clay Glint)
    case clayGlint = "clayGlint"
    /// Chậu 6: Tinh thể thạch anh hồng lăng kính (Quartz Crystal Burst)
    case quartzBurst = "quartzBurst"
    /// Chậu 7: Bụi đất sét mộc mạc (Earthen Dust)
    case earthenDust = "earthenDust"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PotTapEffect {
        switch self {
        case .sparkleBurst:
            return SparkleBurstEffect()
        case .goldGlint:
            return GoldGlintEffect()
        case .stoneDust:
            return StoneDustEffect()
        case .heartBurst:
            return HeartBurstEffect()
        case .clayGlint:
            return ClayGlintEffect()
        case .quartzBurst:
            return QuartzBurstEffect()
        case .earthenDust:
            return EarthenParticlesEffect()
        }
    }
}

// MARK: - Pot Tap Effect Factory

/// Nhà máy khởi tạo hiệu ứng động từ Type, Name hoặc cấu hình JSON
public struct PotTapEffectFactory {

    /// Tạo hiệu ứng theo enum PotTapEffectType
    public static func create(for type: PotTapEffectType) -> PotTapEffect {
        return type.createEffect()
    }

    /// Tạo hiệu ứng theo tên chuỗi hoặc thuộc tính "effect" trong pots_data.json
    public static func create(named nameOrId: String) -> PotTapEffect? {
        let clean = nameOrId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.contains("đá lấp lánh") || clean.contains("lấp lánh") || clean.contains("sparkle") {
            return SparkleBurstEffect()
        } else if clean.contains("vàng") || clean.contains("gold") {
            return GoldGlintEffect()
        } else if clean.contains("bụi đá") || clean.contains("stone") {
            return StoneDustEffect()
        } else if clean.contains("trái tim") || clean.contains("heart") {
            return HeartBurstEffect()
        } else if clean.contains("gốm") || clean.contains("caro") || clean.contains("clay") {
            return ClayGlintEffect()
        } else if clean.contains("thạch anh") || clean.contains("quartz") {
            return QuartzBurstEffect()
        } else if clean.contains("đất sét") || clean.contains("đất") || clean.contains("earthen") {
            return EarthenParticlesEffect()
        }

        return nil
    }
}

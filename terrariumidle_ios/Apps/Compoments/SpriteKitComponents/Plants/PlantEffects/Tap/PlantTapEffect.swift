//
//  PlantTapEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

// MARK: - Plant Tap Effect Protocol

/// Giao diện chuẩn cho mọi hiệu ứng thị giác được kích hoạt khi click/tap vào cây (Plant)
public protocol PlantTapEffect: AnyObject {
    /// Tên định danh của hiệu ứng
    var name: String { get }

    /// Kích hoạt hiệu ứng hạt / bọt khí / phấn hoa / cánh rơi
    /// - Parameters:
    ///   - plantNode: Node cây gốc (nơi add trực tiếp hiệu ứng để không bị ảnh hưởng bởi scale của chậu hay slot)
    ///   - containerSize: Kích thước khung hiển thị của cây
    ///   - level: Cấp độ sinh trưởng hiện tại (1: Hạt, 2: Cây con, 3+: Trưởng thành)
    ///   - leaves: Danh sách các node phiến lá trên cây (dùng để sinh hiệu ứng toả ra từ từng lá)
    func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode])
}

// MARK: - Plant Tap Effect Types

/// Danh mục các loại hiệu ứng tap của cây
public enum PlantTapEffectType: String, CaseIterable {
    /// Bọt khí Oxy xanh ngọc lục bảo tươi mát (mặc định)
    case oxygenEmerald = "oxygenEmerald"
    /// Bọt khí Oxy xanh đại dương sâu thẳm (Deep Ocean)
    case oxygenDeepOcean = "oxygenDeepOcean"
    /// Bọt khí Oxy vàng nắng ấm áp (Golden Sun)
    case oxygenGolden = "oxygenGolden"
    /// Bọt khí Oxy hồng phấn rạng rỡ (Floral Pink)
    case oxygenFloral = "oxygenFloral"
    /// Bụi phấn hoa lấp lánh (Sparkle Pollen)
    case sparklePollen = "sparklePollen"
    /// Cánh hoa / lá rụng bay lượn (Floating Petals)
    case floatingPetals = "floatingPetals"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PlantTapEffect {
        switch self {
        case .oxygenEmerald:
            return OxygenBubblesEffect(theme: .emerald)
        case .oxygenDeepOcean:
            return OxygenBubblesEffect(theme: .deepOcean)
        case .oxygenGolden:
            return OxygenBubblesEffect(theme: .goldenSun)
        case .oxygenFloral:
            return OxygenBubblesEffect(theme: .floralPink)
        case .sparklePollen:
            return SparklePollenEffect()
        case .floatingPetals:
            return FloatingPetalsEffect()
        }
    }
}

// MARK: - Plant Tap Effect Factory

/// Nhà máy khởi tạo hiệu ứng động cho cây từ Type, Name hoặc cấu hình JSON
public struct PlantTapEffectFactory {

    /// Tạo hiệu ứng theo enum PlantTapEffectType
    public static func create(for type: PlantTapEffectType) -> PlantTapEffect {
        return type.createEffect()
    }

    /// Tạo hiệu ứng theo tên chuỗi hoặc thuộc tính "effect" trong plants_data.json
    public static func create(named nameOrId: String) -> PlantTapEffect {
        let clean = nameOrId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.contains("phấn hoa") || clean.contains("pollen") {
            return SparklePollenEffect()
        } else if clean.contains("cánh hoa") || clean.contains("petals") || clean.contains("lá rơi") {
            return FloatingPetalsEffect()
        } else if clean.contains("đại dương") || clean.contains("ocean") || clean.contains("blue") {
            return OxygenBubblesEffect(theme: .deepOcean)
        } else if clean.contains("vàng") || clean.contains("gold") || clean.contains("sun") {
            return OxygenBubblesEffect(theme: .goldenSun)
        } else if clean.contains("hồng") || clean.contains("pink") || clean.contains("floral") {
            return OxygenBubblesEffect(theme: .floralPink)
        }

        // Mặc định là bọt khí Oxy ngọc lục bảo
        return OxygenBubblesEffect(theme: .emerald)
    }
}

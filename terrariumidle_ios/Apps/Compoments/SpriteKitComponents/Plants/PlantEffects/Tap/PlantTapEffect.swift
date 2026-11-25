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
    // MARK: Bọt khí Oxy (các sắc độ)
    /// Bọt khí Oxy xanh ngọc lục bảo tươi mát (mặc định)
    case oxygenEmerald = "oxygenEmerald"
    /// Bọt khí Oxy xanh bạc hà sương mai
    case oxygenMintDew = "oxygenMintDew"
    /// Bọt khí Oxy xanh rêu rừng
    case oxygenForestMoss = "oxygenForestMoss"
    /// Bọt khí Oxy xanh đại dương sâu thẳm (Deep Ocean)
    case oxygenDeepOcean = "oxygenDeepOcean"
    /// Bọt khí Oxy xanh băng tuyết (Ice Aqua)
    case oxygenIceAqua = "oxygenIceAqua"
    /// Bọt khí Oxy xanh chàm đậm (Cobalt Indigo)
    case oxygenCobaltIndigo = "oxygenCobaltIndigo"
    /// Bọt khí Oxy vàng nắng ấm áp (Golden Sun)
    case oxygenGolden = "oxygenGolden"
    /// Bọt khí Oxy cam san hô rực rỡ (Coral Sunset)
    case oxygenCoralSunset = "oxygenCoralSunset"
    /// Bọt khí Oxy đỏ hồng ngọc (Crimson Ruby)
    case oxygenCrimsonRuby = "oxygenCrimsonRuby"
    /// Bọt khí Oxy hồng phấn rạng rỡ (Floral Pink)
    case oxygenFloral = "oxygenFloral"
    /// Bọt khí Oxy tím oải hương nhạt (Lavender Mist)
    case oxygenLavenderMist = "oxygenLavenderMist"
    /// Bọt khí Oxy tím thạch anh huyền bí (Amethyst)
    case oxygenAmethyst = "oxygenAmethyst"
    /// Bọt khí Oxy trắng ngọc trai (Pearl White)
    case oxygenPearlWhite = "oxygenPearlWhite"
    /// Bọt khí Oxy đa sắc cầu vồng (Rainbow Prism)
    case oxygenRainbow = "oxygenRainbow"

    // MARK: Bụi phấn hoa lấp lánh (Sparkle Pollen)
    /// Bụi phấn hoa vàng kim (mặc định)
    case sparklePollen = "sparklePollen"
    /// Bụi phấn hoa hồng phấn
    case sparklePollenPink = "sparklePollenPink"
    /// Bụi phấn hoa xanh ngọc bạc hà
    case sparklePollenEmerald = "sparklePollenEmerald"
    /// Bụi phấn hoa xanh băng tuyết
    case sparklePollenAqua = "sparklePollenAqua"
    /// Bụi phấn hoa tím thạch anh
    case sparklePollenLavender = "sparklePollenLavender"
    /// Bụi phấn hoa cam san hô
    case sparklePollenCoral = "sparklePollenCoral"
    /// Bụi phấn hoa đa sắc lấp lánh
    case sparklePollenMulticolor = "sparklePollenMulticolor"

    // MARK: Cánh hoa / lá rơi lượn (Floating Petals)
    /// Cánh hoa anh đào hồng phấn (mặc định)
    case floatingPetals = "floatingPetals"
    /// Lá rơi mùa thu (cam, vàng, đỏ)
    case floatingPetalsAutumn = "floatingPetalsAutumn"
    /// Lá non xanh ngọc
    case floatingPetalsEmerald = "floatingPetalsEmerald"
    /// Cánh hoa oải hương tím
    case floatingPetalsLavender = "floatingPetalsLavender"
    /// Cánh hoa bạch liên trắng ngà
    case floatingPetalsLotus = "floatingPetalsLotus"
    /// Cánh hoa vàng nắng
    case floatingPetalsGolden = "floatingPetalsGolden"
    /// Cánh hoa đa sắc bay lượn
    case floatingPetalsMulticolor = "floatingPetalsMulticolor"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PlantTapEffect {
        switch self {
        case .oxygenEmerald:
            return OxygenBubblesEffect(theme: .emerald)
        case .oxygenMintDew:
            return OxygenBubblesEffect(theme: .mintDew)
        case .oxygenForestMoss:
            return OxygenBubblesEffect(theme: .forestMoss)
        case .oxygenDeepOcean:
            return OxygenBubblesEffect(theme: .deepOcean)
        case .oxygenIceAqua:
            return OxygenBubblesEffect(theme: .iceAqua)
        case .oxygenCobaltIndigo:
            return OxygenBubblesEffect(theme: .cobaltIndigo)
        case .oxygenGolden:
            return OxygenBubblesEffect(theme: .goldenSun)
        case .oxygenCoralSunset:
            return OxygenBubblesEffect(theme: .coralSunset)
        case .oxygenCrimsonRuby:
            return OxygenBubblesEffect(theme: .crimsonRuby)
        case .oxygenFloral:
            return OxygenBubblesEffect(theme: .floralPink)
        case .oxygenLavenderMist:
            return OxygenBubblesEffect(theme: .lavenderMist)
        case .oxygenAmethyst:
            return OxygenBubblesEffect(theme: .amethyst)
        case .oxygenPearlWhite:
            return OxygenBubblesEffect(theme: .pearlWhite)
        case .oxygenRainbow:
            return OxygenBubblesEffect(theme: .rainbowPrism)
        case .sparklePollen:
            return SparklePollenEffect(theme: .golden)
        case .sparklePollenPink:
            return SparklePollenEffect(theme: .floralPink)
        case .sparklePollenEmerald:
            return SparklePollenEffect(theme: .emeraldMint)
        case .sparklePollenAqua:
            return SparklePollenEffect(theme: .aquaFrost)
        case .sparklePollenLavender:
            return SparklePollenEffect(theme: .lavenderAmethyst)
        case .sparklePollenCoral:
            return SparklePollenEffect(theme: .sunsetCoral)
        case .sparklePollenMulticolor:
            return SparklePollenEffect(theme: .multicolor)
        case .floatingPetals:
            return FloatingPetalsEffect(theme: .sakuraPink)
        case .floatingPetalsAutumn:
            return FloatingPetalsEffect(theme: .autumnLeaves)
        case .floatingPetalsEmerald:
            return FloatingPetalsEffect(theme: .emeraldLeaves)
        case .floatingPetalsLavender:
            return FloatingPetalsEffect(theme: .lavender)
        case .floatingPetalsLotus:
            return FloatingPetalsEffect(theme: .lotusWhite)
        case .floatingPetalsGolden:
            return FloatingPetalsEffect(theme: .goldenSun)
        case .floatingPetalsMulticolor:
            return FloatingPetalsEffect(theme: .multicolor)
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

        if let exactType = PlantTapEffectType.allCases.first(where: { $0.rawValue.lowercased() == clean }) {
            return exactType.createEffect()
        }

        if clean.contains("phấn hoa") || clean.contains("pollen") {
            if clean.contains("đa sắc") || clean.contains("multicolor") || clean.contains("rainbow") {
                return SparklePollenEffect(theme: .multicolor)
            } else if clean.contains("hồng") || clean.contains("pink") {
                return SparklePollenEffect(theme: .floralPink)
            } else if clean.contains("bạc hà") || clean.contains("ngọc") || clean.contains("emerald") || clean.contains("mint") {
                return SparklePollenEffect(theme: .emeraldMint)
            } else if clean.contains("băng") || clean.contains("xanh") || clean.contains("aqua") {
                return SparklePollenEffect(theme: .aquaFrost)
            } else if clean.contains("tím") || clean.contains("oải hương") || clean.contains("lavender") || clean.contains("amethyst") {
                return SparklePollenEffect(theme: .lavenderAmethyst)
            } else if clean.contains("san hô") || clean.contains("cam") || clean.contains("coral") {
                return SparklePollenEffect(theme: .sunsetCoral)
            }
            return SparklePollenEffect(theme: .golden)
        } else if clean.contains("cánh hoa") || clean.contains("petals") || clean.contains("lá rơi") {
            if clean.contains("đa sắc") || clean.contains("multicolor") || clean.contains("rainbow") {
                return FloatingPetalsEffect(theme: .multicolor)
            } else if clean.contains("mùa thu") || clean.contains("thu") || clean.contains("autumn") {
                return FloatingPetalsEffect(theme: .autumnLeaves)
            } else if clean.contains("xanh") || clean.contains("ngọc") || clean.contains("emerald") {
                return FloatingPetalsEffect(theme: .emeraldLeaves)
            } else if clean.contains("oải hương") || clean.contains("tím") || clean.contains("lavender") {
                return FloatingPetalsEffect(theme: .lavender)
            } else if clean.contains("sen") || clean.contains("trắng") || clean.contains("lotus") || clean.contains("white") {
                return FloatingPetalsEffect(theme: .lotusWhite)
            } else if clean.contains("vàng") || clean.contains("gold") {
                return FloatingPetalsEffect(theme: .goldenSun)
            }
            return FloatingPetalsEffect(theme: .sakuraPink)
        } else if clean.contains("đa sắc") || clean.contains("cầu vồng") || clean.contains("rainbow") {
            return OxygenBubblesEffect(theme: .rainbowPrism)
        } else if clean.contains("bạc hà") || clean.contains("mint") {
            return OxygenBubblesEffect(theme: .mintDew)
        } else if clean.contains("rêu") || clean.contains("moss") {
            return OxygenBubblesEffect(theme: .forestMoss)
        } else if clean.contains("băng") || clean.contains("ice") || clean.contains("aqua") {
            return OxygenBubblesEffect(theme: .iceAqua)
        } else if clean.contains("chàm") || clean.contains("cobalt") || clean.contains("indigo") {
            return OxygenBubblesEffect(theme: .cobaltIndigo)
        } else if clean.contains("đại dương") || clean.contains("ocean") || clean.contains("blue") {
            return OxygenBubblesEffect(theme: .deepOcean)
        } else if clean.contains("san hô") || clean.contains("cam") || clean.contains("coral") {
            return OxygenBubblesEffect(theme: .coralSunset)
        } else if clean.contains("đỏ") || clean.contains("ruby") || clean.contains("crimson") {
            return OxygenBubblesEffect(theme: .crimsonRuby)
        } else if clean.contains("vàng") || clean.contains("gold") || clean.contains("sun") {
            return OxygenBubblesEffect(theme: .goldenSun)
        } else if clean.contains("oải hương") || clean.contains("lavender") {
            return OxygenBubblesEffect(theme: .lavenderMist)
        } else if clean.contains("tím") || clean.contains("amethyst") || clean.contains("purple") {
            return OxygenBubblesEffect(theme: .amethyst)
        } else if clean.contains("hồng") || clean.contains("pink") || clean.contains("floral") {
            return OxygenBubblesEffect(theme: .floralPink)
        } else if clean.contains("ngọc trai") || clean.contains("trắng") || clean.contains("pearl") || clean.contains("white") {
            return OxygenBubblesEffect(theme: .pearlWhite)
        }

        // Mặc định là bọt khí Oxy ngọc lục bảo
        return OxygenBubblesEffect(theme: .emerald)
    }
}

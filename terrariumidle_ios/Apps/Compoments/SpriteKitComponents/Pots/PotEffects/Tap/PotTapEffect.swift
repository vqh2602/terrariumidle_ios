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
    case sparkleGolden = "sparkleGolden"
    case sparkleEmerald = "sparkleEmerald"
    case sparkleSapphire = "sparkleSapphire"
    case sparkleAmethyst = "sparkleAmethyst"
    case sparkleRainbow = "sparkleRainbow"
    /// Chậu 2: Vệt ánh vàng kim óng ánh (Gold Glint)
    case goldGlint = "goldGlint"
    /// Chậu 3: Bụi đá xám bạc (Stone Dust)
    case stoneDust = "stoneDust"
    /// Chậu 4: Chùm trái tim hồng ngọc bay bổng (Heart Burst)
    case heartBurst = "heartBurst"
    case heartPastel = "heartPastel"
    case heartCrimson = "heartCrimson"
    case heartRainbow = "heartRainbow"
    /// Chậu 5: Ánh gốm nung sắc nét (Clay Glint)
    case clayGlint = "clayGlint"
    /// Chậu 6: Tinh thể thạch anh hồng lăng kính (Quartz Crystal Burst)
    case quartzBurst = "quartzBurst"
    case quartzCitrine = "quartzCitrine"
    case quartzAquamarine = "quartzAquamarine"
    case quartzPrism = "quartzPrism"
    /// Chậu 7: Bụi đất sét mộc mạc (Earthen Dust)
    case earthenDust = "earthenDust"
    /// Chậu 20: Bụi phấn gỗ thơm ấm áp (Wood Pollen & Amber Glow)
    case woodPollen = "woodPollen"
    case woodPollenBlossom = "woodPollenBlossom"
    case woodPollenGolden = "woodPollenGolden"
    /// Chậu 28: Tinh thể ngọc bích băng tuyết (Emerald & Ice Jade Luminescence)
    case emeraldJade = "emeraldJade"
    case emeraldImperial = "emeraldImperial"
    case emeraldAmethyst = "emeraldAmethyst"
    /// Chậu 29: Bọt ngọc san hô phập phồng (Coral Luminescent Pearls)
    case coralBubble = "coralBubble"
    case coralOceanPearl = "coralOceanPearl"
    case coralSunset = "coralSunset"
    case coralMulticolor = "coralMulticolor"
    /// Chậu 30: Sương mai thiền tịnh (Zen Bamboo Mist & Dew)
    case bambooMist = "bambooMist"
    case bambooMorningSky = "bambooMorningSky"
    case bambooAutumnZen = "bambooAutumnZen"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PotTapEffect {
        switch self {
        case .sparkleBurst:
            return SparkleBurstEffect(theme: .classic)
        case .sparkleGolden:
            return SparkleBurstEffect(theme: .golden)
        case .sparkleEmerald:
            return SparkleBurstEffect(theme: .emeraldJade)
        case .sparkleSapphire:
            return SparkleBurstEffect(theme: .sapphireAqua)
        case .sparkleAmethyst:
            return SparkleBurstEffect(theme: .amethystRose)
        case .sparkleRainbow:
            return SparkleBurstEffect(theme: .rainbow)
        case .goldGlint:
            return GoldGlintEffect()
        case .stoneDust:
            return StoneDustEffect()
        case .heartBurst:
            return HeartBurstEffect(theme: .classic)
        case .heartPastel:
            return HeartBurstEffect(theme: .pastel)
        case .heartCrimson:
            return HeartBurstEffect(theme: .crimsonPassion)
        case .heartRainbow:
            return HeartBurstEffect(theme: .rainbow)
        case .clayGlint:
            return ClayGlintEffect()
        case .quartzBurst:
            return QuartzBurstEffect(theme: .roseAmethyst)
        case .quartzCitrine:
            return QuartzBurstEffect(theme: .citrineGold)
        case .quartzAquamarine:
            return QuartzBurstEffect(theme: .aquamarine)
        case .quartzPrism:
            return QuartzBurstEffect(theme: .prism)
        case .earthenDust:
            return EarthenParticlesEffect()
        case .woodPollen:
            return WoodPollenEffect(theme: .warmAmber)
        case .woodPollenBlossom:
            return WoodPollenEffect(theme: .forestBlossom)
        case .woodPollenGolden:
            return WoodPollenEffect(theme: .goldenDust)
        case .emeraldJade:
            return EmeraldJadeEffect(theme: .iceJade)
        case .emeraldImperial:
            return EmeraldJadeEffect(theme: .imperialGreen)
        case .emeraldAmethyst:
            return EmeraldJadeEffect(theme: .amethystJade)
        case .coralBubble:
            return CoralBubbleEffect(theme: .coralPink)
        case .coralOceanPearl:
            return CoralBubbleEffect(theme: .oceanPearl)
        case .coralSunset:
            return CoralBubbleEffect(theme: .sunset)
        case .coralMulticolor:
            return CoralBubbleEffect(theme: .multicolor)
        case .bambooMist:
            return BambooMistEffect(theme: .zenDew)
        case .bambooMorningSky:
            return BambooMistEffect(theme: .morningSky)
        case .bambooAutumnZen:
            return BambooMistEffect(theme: .autumnZen)
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

        if let exactType = PotTapEffectType.allCases.first(where: { $0.rawValue.lowercased() == clean }) {
            return exactType.createEffect()
        }

        if clean.contains("đá lấp lánh".tr) || clean.contains("lấp lánh".tr) || clean.contains("sparkle") {
            if clean.contains("cầu vồng".tr) || clean.contains("đa sắc".tr) || clean.contains("rainbow") {
                return SparkleBurstEffect(theme: .rainbow)
            } else if clean.contains("ngọc".tr) || clean.contains("emerald") {
                return SparkleBurstEffect(theme: .emeraldJade)
            } else if clean.contains("lam") || clean.contains("sapphire") || clean.contains("aqua") {
                return SparkleBurstEffect(theme: .sapphireAqua)
            } else if clean.contains("tím".tr) || clean.contains("amethyst") {
                return SparkleBurstEffect(theme: .amethystRose)
            } else if clean.contains("vàng".tr) || clean.contains("gold") {
                return SparkleBurstEffect(theme: .golden)
            }
            return SparkleBurstEffect(theme: .classic)
        } else if clean.contains("vàng".tr) || clean.contains("gold") {
            return GoldGlintEffect()
        } else if clean.contains("bụi đá".tr) || clean.contains("stone") {
            return StoneDustEffect()
        } else if clean.contains("trái tim".tr) || clean.contains("heart") {
            if clean.contains("cầu vồng".tr) || clean.contains("đa sắc".tr) || clean.contains("rainbow") {
                return HeartBurstEffect(theme: .rainbow)
            } else if clean.contains("pastel") {
                return HeartBurstEffect(theme: .pastel)
            } else if clean.contains("đỏ".tr) || clean.contains("crimson") {
                return HeartBurstEffect(theme: .crimsonPassion)
            }
            return HeartBurstEffect(theme: .classic)
        } else if clean.contains("gốm".tr) || clean.contains("caro") || clean.contains("clay") {
            return ClayGlintEffect()
        } else if clean.contains("thạch anh".tr) || clean.contains("quartz") {
            if clean.contains("lăng kính".tr) || clean.contains("đa sắc".tr) || clean.contains("prism") {
                return QuartzBurstEffect(theme: .prism)
            } else if clean.contains("vàng".tr) || clean.contains("citrine") {
                return QuartzBurstEffect(theme: .citrineGold)
            } else if clean.contains("biển".tr) || clean.contains("xanh") || clean.contains("aqua") {
                return QuartzBurstEffect(theme: .aquamarine)
            }
            return QuartzBurstEffect(theme: .roseAmethyst)
        } else if clean.contains("đất sét".tr) || clean.contains("đất".tr) || clean.contains("earthen") {
            return EarthenParticlesEffect()
        } else if clean.contains("gỗ".tr) || clean.contains("pollen") || clean.contains("amber") {
            if clean.contains("hoa") || clean.contains("blossom") {
                return WoodPollenEffect(theme: .forestBlossom)
            } else if clean.contains("vàng".tr) || clean.contains("gold") {
                return WoodPollenEffect(theme: .goldenDust)
            }
            return WoodPollenEffect(theme: .warmAmber)
        } else if clean.contains("ngọc bích".tr) || clean.contains("ngọc".tr) || clean.contains("jade") || clean.contains("emerald") {
            if clean.contains("lục bảo".tr) || clean.contains("imperial") {
                return EmeraldJadeEffect(theme: .imperialGreen)
            } else if clean.contains("tím".tr) || clean.contains("amethyst") {
                return EmeraldJadeEffect(theme: .amethystJade)
            }
            return EmeraldJadeEffect(theme: .iceJade)
        } else if clean.contains("san hô".tr) || clean.contains("coral") {
            if clean.contains("đa sắc".tr) || clean.contains("multicolor") {
                return CoralBubbleEffect(theme: .multicolor)
            } else if clean.contains("ngọc trai".tr) || clean.contains("ocean") || clean.contains("pearl") {
                return CoralBubbleEffect(theme: .oceanPearl)
            } else if clean.contains("hoàng hôn".tr) || clean.contains("sunset") {
                return CoralBubbleEffect(theme: .sunset)
            }
            return CoralBubbleEffect(theme: .coralPink)
        } else if clean.contains("tre") || clean.contains("sương".tr) || clean.contains("bamboo") || clean.contains("mist") {
            if clean.contains("trời".tr) || clean.contains("sky") {
                return BambooMistEffect(theme: .morningSky)
            } else if clean.contains("thu") || clean.contains("autumn") {
                return BambooMistEffect(theme: .autumnZen)
            }
            return BambooMistEffect(theme: .zenDew)
        }

        return nil
    }
}

// MARK: - Shared Helpers

/// Helper dùng chung cho các hiệu ứng hạt của chậu (chuyển hệ tọa độ, tính tỉ lệ & giới hạn ngân sách hạt)
enum PotTapEffectHelper {
    /// Quy đổi frame của `potNode` sang hệ tọa độ của `containerNode` (hỗ trợ cả chậu treo có rig cha riêng)
    static func resolvedPotFrame(for potNode: SKSpriteNode, in containerNode: SKNode) -> CGRect {
        let localFrame = potNode.frame
        guard let parent = potNode.parent, parent !== containerNode else {
            return localFrame
        }
        let centerInParent = CGPoint(x: localFrame.midX, y: localFrame.midY)
        let centerInContainer = parent.convert(centerInParent, to: containerNode)
        return CGRect(
            x: centerInContainer.x - localFrame.width * 0.5,
            y: centerInContainer.y - localFrame.height * 0.5,
            width: localFrame.width,
            height: localFrame.height
        )
    }

    /// Hệ số tỉ lệ kích thước hạt dựa theo kích thước hiển thị thực tế của chậu
    static func scaleFactor(for potFrame: CGRect) -> CGFloat {
        let base = min(potFrame.width, potFrame.height)
        guard base > 0 else { return 1.0 }
        return min(max(base / 95.0, 0.85), 1.45)
    }

    /// Tính số lượng hạt tối đa còn được phép sinh thêm dựa trên ngân sách node đang tồn tại
    static func remainingBudget(in containerNode: SKNode, nodeName: String, maxActive: Int) -> Int {
        var existingCount = 0
        for child in containerNode.children where child.name == nodeName {
            existingCount += 1
        }
        return max(0, maxActive - existingCount)
    }

    /// Tạo texture đám bụi / sương mềm dạng radial gradient để dùng chung cho các hiệu ứng bụi đất & bụi đá
    static func createSoftPuffTexture(dimension: CGFloat = 48.0, innerColor: UIColor, midColor: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dimension, height: dimension))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: dimension * 0.5, y: dimension * 0.5)
            let radius = dimension * 0.48
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                innerColor.cgColor,
                midColor.cgColor,
                midColor.withAlphaComponent(0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.52, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: .drawsAfterEndLocation
                )
            }
        }
        return SKTexture(image: img)
    }

    /// Tạo texture vệt ánh sáng quét chéo lướt bề mặt (dùng chung cho ánh vàng kim & ánh men gốm)
    static func createSheenStreakTexture(width: CGFloat = 96.0, height: CGFloat = 24.0, coreColor: UIColor, glowColor: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let center = CGPoint(x: width * 0.5, y: height * 0.5)
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            // Vầng sáng oval mềm bao quanh
            let outerColors = [
                glowColor.withAlphaComponent(0.75).cgColor,
                glowColor.withAlphaComponent(0.0).cgColor
            ] as CFArray
            if let outerGrad = CGGradient(colorsSpace: colorSpace, colors: outerColors, locations: [0.0, 1.0]) {
                cgCtx.saveGState()
                cgCtx.translateBy(x: center.x, y: center.y)
                cgCtx.scaleBy(x: 1.0, y: height / width)
                cgCtx.drawRadialGradient(
                    outerGrad,
                    startCenter: .zero,
                    startRadius: 0,
                    endCenter: .zero,
                    endRadius: width * 0.48,
                    options: .drawsAfterEndLocation
                )
                cgCtx.restoreGState()
            }

            // Lõi tia sáng sắc nét ở tâm
            let coreColors = [
                coreColor.cgColor,
                coreColor.withAlphaComponent(0.0).cgColor
            ] as CFArray
            if let coreGrad = CGGradient(colorsSpace: colorSpace, colors: coreColors, locations: [0.0, 1.0]) {
                cgCtx.saveGState()
                cgCtx.translateBy(x: center.x, y: center.y)
                cgCtx.scaleBy(x: 1.0, y: (height * 0.42) / (width * 0.85))
                cgCtx.drawRadialGradient(
                    coreGrad,
                    startCenter: .zero,
                    startRadius: 0,
                    endCenter: .zero,
                    endRadius: width * 0.42,
                    options: .drawsAfterEndLocation
                )
                cgCtx.restoreGState()
            }
        }
        return SKTexture(image: img)
    }

    /// Chạy chuyển động nảy parabol có trọng lực (bật lên rồi rơi xuống và xoay lộn nhẹ)
    static func runGravityHop(
        on node: SKNode,
        delay: TimeInterval,
        upDX: CGFloat,
        upDY: CGFloat,
        downDX: CGFloat,
        downDY: CGFloat,
        spinAngle: CGFloat,
        peakAlpha: CGFloat = 1.0
    ) {
        let upDuration: TimeInterval = 0.22
        let downDuration: TimeInterval = 0.34
        let totalMotion = upDuration + downDuration

        let hopUp = SKAction.moveBy(x: upDX, y: upDY, duration: upDuration)
        hopUp.timingMode = .easeOut

        let fallDown = SKAction.moveBy(x: downDX, y: downDY, duration: downDuration)
        fallDown.timingMode = .easeIn

        let arcPath = SKAction.sequence([hopUp, fallDown])
        let spin = SKAction.rotate(byAngle: spinAngle, duration: totalMotion)
        let scalePop = SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.14),
            SKAction.scale(to: 0.85, duration: 0.24),
            SKAction.scale(to: 0.20, duration: 0.18)
        ])
        let fadeSeq = SKAction.sequence([
            SKAction.fadeAlpha(to: peakAlpha, duration: 0.07),
            SKAction.wait(forDuration: 0.28),
            SKAction.fadeOut(withDuration: 0.21)
        ])

        let seq = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([arcPath, spin, scalePop, fadeSeq]),
            SKAction.removeFromParent()
        ])
        node.run(seq)
    }
}

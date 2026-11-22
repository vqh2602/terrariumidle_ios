//
//  PlantMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Plant Motion Context

/// Ngữ cảnh chuyển động vật lý của cây khi nhận tương tác Tap
public struct PlantMotionContext {
    /// Node cây gốc (self)
    public let plantNode: SKNode
    /// Node gốc chứa bộ khung hiển thị cây (plantRootNode)
    public let plantRootNode: SKNode
    /// Node hạt giống (Level 1) nếu có
    public let seedNode: SKNode?
    /// Node mầm cây con (Level 2) nếu có
    public let sproutNode: SKNode?
    /// Node cây trưởng thành (Level 3+) nếu có
    public let matureNode: SKNode?
    /// Danh sách các node phiến lá trên cây
    public let leafNodes: [SKNode]
    /// Tỉ lệ scale cơ sở của cây
    public let baseScale: CGFloat
    /// Cấp độ sinh trưởng (1: Hạt, 2: Mầm, 3+: Trưởng thành)
    public let level: Int
    /// Tọa độ gốc của hạt giống (chống trôi tọa độ)
    public let initialSeedPosition: CGPoint
    /// Tọa độ gốc của mầm cây (chống trôi tọa độ)
    public let initialSproutPosition: CGPoint
    /// Kích thước khung chứa cây
    public let containerSize: CGSize
    /// Callback gọi khi chuỗi chuyển động hoàn tất
    public let onComplete: (() -> Void)?

    public init(
        plantNode: SKNode,
        plantRootNode: SKNode,
        seedNode: SKNode? = nil,
        sproutNode: SKNode? = nil,
        matureNode: SKNode? = nil,
        leafNodes: [SKNode] = [],
        baseScale: CGFloat = 1.0,
        level: Int = 3,
        initialSeedPosition: CGPoint = .zero,
        initialSproutPosition: CGPoint = .zero,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        self.plantNode = plantNode
        self.plantRootNode = plantRootNode
        self.seedNode = seedNode
        self.sproutNode = sproutNode
        self.matureNode = matureNode
        self.leafNodes = leafNodes
        self.baseScale = baseScale
        self.level = level
        self.initialSeedPosition = initialSeedPosition
        self.initialSproutPosition = initialSproutPosition
        self.containerSize = containerSize
        self.onComplete = onComplete
    }

    // MARK: - Quản lý Action Nhàn Rỗi (Idle Actions Management)

    /// Các key action nhàn rỗi chạy trên thân cây (plantRootNode)
    public static let plantRootIdleActionKeys = [
        "trunkSway", "plantSway", "trunkBob", "rootIdleWind", "idleSway"
    ]

    /// Các key action nhàn rỗi chạy trên phiến lá (leafNodes)
    public static let leafIdleActionKeys = [
        "vineWind", "heartleafWind", "vineSway", "leafBend", "leafWind", "leafSway", "butterflySway"
    ]

    /// Các key action nhàn rỗi chạy trên hạt giống (seedNode)
    public static let seedIdleActionKeys = [
        "seedBreath", "seedBreathing", "seedWiggle", "seedGlowPulse"
    ]

    /// Các key action nhàn rỗi chạy trên mầm cây con (sproutNode)
    public static let sproutIdleActionKeys = [
        "sproutSway", "sproutBob", "sproutGlowPulse"
    ]

    /// Tạm dừng/gỡ bỏ toàn bộ action chuyển động nhàn rỗi (idle) trên thân, lá, hạt và mầm
    /// để triệt tiêu hoàn toàn xung đột chuyển động (conflict zRotation/scale) gây hiện tượng giật rung cây khi tap.
    public func stopIdleActions() {
        for key in Self.plantRootIdleActionKeys {
            plantRootNode.removeAction(forKey: key)
        }
        for leaf in leafNodes {
            for key in Self.leafIdleActionKeys {
                leaf.removeAction(forKey: key)
            }
        }
        if let seed = seedNode {
            for key in Self.seedIdleActionKeys {
                seed.removeAction(forKey: key)
            }
        }
        if let sprout = sproutNode {
            for key in Self.sproutIdleActionKeys {
                sprout.removeAction(forKey: key)
            }
        }
    }
}

// MARK: - Plant Motion Effect Protocol

extension SKNode {
    private static let restZRotationKey = "restZRotation"

    /// Góc xoay nghỉ ban đầu của Node (chống trôi góc và chống hiện tượng lật xoay 180 độ khi tap liên tục dồn dập)
    public var restZRotation: CGFloat {
        get {
            if let val = userData?[Self.restZRotationKey] as? CGFloat {
                return val
            }
            let initial = zRotation
            if userData == nil {
                userData = NSMutableDictionary()
            }
            userData?[Self.restZRotationKey] = initial
            return initial
        }
        set {
            if userData == nil {
                userData = NSMutableDictionary()
            }
            userData?[Self.restZRotationKey] = newValue
        }
    }
}

/// Giao diện chuẩn cho mọi hiệu ứng chuyển động rung lắc / nảy cành lá khi chạm vào cây
public protocol PlantMotionEffect: AnyObject {
    /// Tên định danh của hiệu ứng chuyển động
    var name: String { get }

    /// Áp dụng hiệu ứng chuyển động lên cây theo ngữ cảnh
    func apply(context: PlantMotionContext)
}

extension PlantMotionEffect {
    /// Hàm tiện ích hỗ trợ gọi nhanh
    public func apply(
        plantNode: SKNode,
        plantRootNode: SKNode,
        seedNode: SKNode? = nil,
        sproutNode: SKNode? = nil,
        matureNode: SKNode? = nil,
        leafNodes: [SKNode] = [],
        baseScale: CGFloat = 1.0,
        level: Int = 3,
        initialSeedPosition: CGPoint = .zero,
        initialSproutPosition: CGPoint = .zero,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        let ctx = PlantMotionContext(
            plantNode: plantNode,
            plantRootNode: plantRootNode,
            seedNode: seedNode,
            sproutNode: sproutNode,
            matureNode: matureNode,
            leafNodes: leafNodes,
            baseScale: baseScale,
            level: level,
            initialSeedPosition: initialSeedPosition,
            initialSproutPosition: initialSproutPosition,
            containerSize: containerSize,
            onComplete: onComplete
        )
        apply(context: ctx)
    }
}

// MARK: - Plant Motion Effect Types

/// Danh mục các loại hiệu ứng chuyển động tap của cây có sẵn trong game
public enum PlantMotionEffectType: String, CaseIterable {
    /// Bản gốc: Nén nảy Squash & Stretch lò xo đàn hồi + Gợn sóng lan tỏa qua phiến lá
    case standardBounce = "standardBounce"
    /// Bản mới: Gió lay đu đưa mềm mại (Thân cây chao nghiêng nhẹ, cành lá uốn lượn đón gió)
    case windSway = "windSway"
    /// Bản mới: Dây leo rủ uốn lượn nối đuôi nhau (Dành cho cây chậu treo, rủ buông)
    case cascadingVine = "cascadingVine"
    /// Bản mới: Nhún nảy đàn hồi tần số nhanh (Dành cho sen đá, xương rồng mọng nước)
    case elasticPulse = "elasticPulse"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PlantMotionEffect {
        switch self {
        case .standardBounce:
            return StandardPlantBounceMotionEffect()
        case .windSway:
            return WindSwayMotionEffect()
        case .cascadingVine:
            return CascadingVineMotionEffect()
        case .elasticPulse:
            return ElasticPulseMotionEffect()
        }
    }
}

// MARK: - Plant Motion Effect Factory

/// Nhà máy khởi tạo hiệu ứng chuyển động tap cây từ Type hoặc Chuỗi tên định danh
public struct PlantMotionEffectFactory {
    /// Tạo hiệu ứng theo enum PlantMotionEffectType
    public static func create(for type: PlantMotionEffectType) -> PlantMotionEffect {
        return type.createEffect()
    }

    /// Tạo hiệu ứng theo tên chuỗi hoặc từ khóa
    public static func create(named nameOrId: String) -> PlantMotionEffect {
        let clean = nameOrId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.contains("wind") || clean.contains("sway") || clean.contains("gió") || clean.contains("đu đưa") {
            return WindSwayMotionEffect()
        } else if clean.contains("vine") || clean.contains("cascade") || clean.contains("leo") || clean.contains("rủ") {
            return CascadingVineMotionEffect()
        } else if clean.contains("pulse") || clean.contains("mọng nước") || clean.contains("sen đá") {
            return ElasticPulseMotionEffect()
        }

        // Mặc định là hiệu ứng nảy gốc tiêu chuẩn
        return StandardPlantBounceMotionEffect()
    }
}

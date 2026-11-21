//
//  PotMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Pot Motion Context

/// Ngữ cảnh chuyển động vật lý của chậu cây khi nhận tương tác Tap
public struct PotMotionContext {
    /// Node mục tiêu chính nhận chuyển động (với chậu treo là hangingRigNode, chậu để bàn là potNode)
    public let targetNode: SKNode
    /// Sprite hiển thị thân chậu (dùng để co giãn nảy Squash & Stretch nếu cần)
    public let potNode: SKSpriteNode?
    /// Node bóng đổ dưới đáy (chỉ có ở chậu để bàn)
    public let shadowNode: SKNode?
    /// Tọa độ gốc ban đầu của potNode (để reset chống trôi tọa độ khi click liên tục)
    public let initialPosition: CGPoint
    /// Cờ xác định chậu treo hay chậu để bàn
    public let isHanging: Bool
    /// Kích thước khung chứa của chậu
    public let containerSize: CGSize
    /// Callback gọi khi chuỗi hiệu ứng kết thúc (để khôi phục idle sway nếu có)
    public let onComplete: (() -> Void)?

    public init(
        targetNode: SKNode,
        potNode: SKSpriteNode? = nil,
        shadowNode: SKNode? = nil,
        initialPosition: CGPoint = .zero,
        isHanging: Bool = false,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        self.targetNode = targetNode
        self.potNode = potNode
        self.shadowNode = shadowNode
        self.initialPosition = initialPosition
        self.isHanging = isHanging
        self.containerSize = containerSize
        self.onComplete = onComplete
    }
}

// MARK: - Pot Motion Effect Protocol

/// Giao diện chuẩn cho mọi hiệu ứng chuyển động nảy / rung / đu đưa khi chạm vào chậu cây
public protocol PotMotionEffect: AnyObject {
    /// Tên định danh của hiệu ứng chuyển động
    var name: String { get }

    /// Áp dụng hiệu ứng chuyển động lên chậu theo ngữ cảnh
    func apply(context: PotMotionContext)
}

extension PotMotionEffect {
    /// Hàm tiện ích hỗ trợ gọi nhanh với các tham số độc lập
    public func apply(
        targetNode: SKNode,
        potNode: SKSpriteNode? = nil,
        shadowNode: SKNode? = nil,
        initialPosition: CGPoint = .zero,
        isHanging: Bool = false,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        let ctx = PotMotionContext(
            targetNode: targetNode,
            potNode: potNode,
            shadowNode: shadowNode,
            initialPosition: initialPosition,
            isHanging: isHanging,
            containerSize: containerSize,
            onComplete: onComplete
        )
        apply(context: ctx)
    }
}

// MARK: - Pot Motion Effect Types

/// Danh mục các loại hiệu ứng chuyển động tap chậu có sẵn trong game
public enum PotMotionEffectType: String, CaseIterable {
    /// Chậu để bàn chuẩn: Nén nảy Squash & Stretch lò xo đàn hồi tiêu chuẩn
    case standardBounce = "standardBounce"
    /// Chậu để bàn cứng cáp: Biên độ nhỏ, đầm chắc cho chậu đá/gốm dày
    case firmBounce = "firmBounce"
    /// Chậu treo con lắc đàn hồi: Đu đưa nhanh kết hợp nhún nảy trục Y (Pot15)
    case elasticPendulum = "elasticPendulum"
    /// Chậu treo đu đưa biên độ rộng: 5 nhịp tắt dần mềm mại, nhẹ nhàng (Pot16, Pot17)
    case widePendulum = "widePendulum"
    /// Chậu treo con lắc lò xo hồi phục: 3 nhịp lắc + resume idle sway (Pot18)
    case springPendulum = "springPendulum"
    /// Rung lắc nhẹ: Jiggle / Wobble nhẹ tần số nhanh
    case subtleWobble = "subtleWobble"

    /// Khởi tạo instance hiệu ứng tương ứng
    public func createEffect() -> PotMotionEffect {
        switch self {
        case .standardBounce:
            return StandardBounceMotionEffect()
        case .firmBounce:
            return FirmBounceMotionEffect()
        case .elasticPendulum:
            return ElasticPendulumMotionEffect()
        case .widePendulum:
            return WidePendulumMotionEffect()
        case .springPendulum:
            return SpringPendulumMotionEffect()
        case .subtleWobble:
            return SubtleWobbleMotionEffect()
        }
    }
}

// MARK: - Pot Motion Effect Factory

/// Nhà máy khởi tạo hiệu ứng chuyển động tap từ Type hoặc Chuỗi tên định danh
public struct PotMotionEffectFactory {
    /// Tạo hiệu ứng theo enum PotMotionEffectType
    public static func create(for type: PotMotionEffectType) -> PotMotionEffect {
        return type.createEffect()
    }

    /// Tạo hiệu ứng theo tên chuỗi hoặc từ khóa
    public static func create(named nameOrId: String) -> PotMotionEffect? {
        let clean = nameOrId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.contains("elastic") || clean.contains("pot15") || clean.contains("đàn hồi") {
            return ElasticPendulumMotionEffect()
        } else if clean.contains("wide") || clean.contains("pot16") || clean.contains("pot17") || clean.contains("rộng") {
            return WidePendulumMotionEffect()
        } else if clean.contains("spring") || clean.contains("pot18") || clean.contains("lò xo") {
            return SpringPendulumMotionEffect()
        } else if clean.contains("firm") || clean.contains("đá") || clean.contains("gốm") {
            return FirmBounceMotionEffect()
        } else if clean.contains("wobble") || clean.contains("vibrate") || clean.contains("rung") {
            return SubtleWobbleMotionEffect()
        } else if clean.contains("bounce") || clean.contains("standard") || clean.contains("nảy") {
            return StandardBounceMotionEffect()
        }

        return nil
    }
}

//
//  AnimalInteractiveNode.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

// MARK: - Animal Interactive Node Protocol

/// Giao diện chuẩn cho mọi Node Động Vật / Tổ Động Vật SpriteKit có khả năng tương tác
public protocol AnimalInteractiveNode: AnyObject {
    /// Node SpriteKit đại diện
    var asNode: SKNode { get }

    /// Kích hoạt hiệu ứng phản hồi khi chạm (chuyển động vật lý và hiệu ứng thị giác)
    func playTapAnimation()

    /// Cờ xác định vật phẩm treo (isHanging = true) hay đặt bàn
    var isHanging: Bool { get }

    /// Hiệu ứng chuyển động (đung đưa / con lắc / nhún nảy)
    var motionEffect: AnimalMotionEffect { get set }

    /// Danh sách hiệu ứng thị giác dạng hạt khi chạm
    var tapEffects: [AnimalTapEffect] { get set }

    /// Tọa độ cửa tổ (hoặc điểm xuất phát) quy đổi sang hệ tọa độ node cha
    func spawnAnchorPoint(in targetNode: SKNode) -> CGPoint
}

extension AnimalInteractiveNode where Self: SKNode {
    public var asNode: SKNode { self }

    public func spawnAnchorPoint(in targetNode: SKNode) -> CGPoint {
        return parent?.convert(position, to: targetNode) ?? position
    }
}

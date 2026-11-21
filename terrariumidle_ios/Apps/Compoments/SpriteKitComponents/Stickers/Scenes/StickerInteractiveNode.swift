//
//  StickerInteractiveNode.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - Sticker Interactive Node Protocol

/// Giao diện chuẩn cho mọi Node Sticker SpriteKit có khả năng tương tác
public protocol StickerInteractiveNode: AnyObject {
    /// Node SpriteKit đại diện
    var asNode: SKNode { get }

    /// Kích hoạt hiệu ứng phản hồi khi chạm (gồm cả chuyển động vật lý và hiệu ứng thị giác)
    func playTapAnimation()

    /// Cờ xác định sticker treo (isHanging = true) hay sticker để bàn
    var isHanging: Bool { get }

    /// Hiệu ứng chuyển động (đung đưa nhàn rỗi theo gió / con lắc / nảy)
    var motionEffect: StickerMotionEffect { get set }

    /// Danh sách các hiệu ứng thị giác dạng hạt / ánh sáng khi chạm
    var tapEffects: [StickerTapEffect] { get set }
}

extension StickerInteractiveNode where Self: SKNode {
    public var asNode: SKNode { self }
}

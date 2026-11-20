//
//  LandscapeProtocol.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit

/// Protocol chuẩn cho các Node Phong cảnh nền SpriteKit (Landscape Nodes)
public protocol LandscapeInteractiveNode: AnyObject {
    /// Cấu hình kích thước khung hiển thị phong cảnh
    func configure(containerSize: CGSize)
    
    /// Node đại diện để add vào Scene cha
    var asNode: SKNode { get }
    
    /// Kích hoạt hoạt ảnh tương tác khi chạm vào nền (mặt trời lấp lánh, mây dạt nhẹ)
    func playTapAnimation(at location: CGPoint)
}

extension LandscapeInteractiveNode where Self: SKNode {
    public var asNode: SKNode { self }
}

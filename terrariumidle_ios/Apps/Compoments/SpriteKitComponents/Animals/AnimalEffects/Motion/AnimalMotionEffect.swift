//
//  AnimalMotionEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

// MARK: - Animal Motion Context

/// Ngữ cảnh chuyển động vật lý của tổ/động vật khi nhàn rỗi hoặc khi nhận tương tác Tap
public struct AnimalMotionContext {
    /// Node mục tiêu chính nhận chuyển động (ví dụ: hiveRigNode)
    public let targetNode: SKNode
    /// Node nhánh phụ phía sau (ví dụ: cành cây branchNode)
    public let branchNode: SKNode?
    /// Sprite thân chính (ví dụ: hiveNode)
    public let bodyNode: SKSpriteNode?
    /// Tọa độ gốc ban đầu của targetNode
    public let initialPosition: CGPoint
    /// Cờ xác định treo hay để bàn
    public let isHanging: Bool
    /// Kích thước khung chứa
    public let containerSize: CGSize
    /// Callback khi chuỗi tap hoàn tất
    public let onComplete: (() -> Void)?

    public init(
        targetNode: SKNode,
        branchNode: SKNode? = nil,
        bodyNode: SKSpriteNode? = nil,
        initialPosition: CGPoint = .zero,
        isHanging: Bool = true,
        containerSize: CGSize = .zero,
        onComplete: (() -> Void)? = nil
    ) {
        self.targetNode = targetNode
        self.branchNode = branchNode
        self.bodyNode = bodyNode
        self.initialPosition = initialPosition
        self.isHanging = isHanging
        self.containerSize = containerSize
        self.onComplete = onComplete
    }
}

// MARK: - Animal Motion Effect Protocol

public protocol AnimalMotionEffect: AnyObject {
    var name: String { get }
    func startIdle(context: AnimalMotionContext)
    func stopIdle(context: AnimalMotionContext)
    func apply(context: AnimalMotionContext)
}

extension AnimalMotionEffect {
    public func startIdle(context: AnimalMotionContext) {}
    public func stopIdle(context: AnimalMotionContext) {
        context.targetNode.removeAction(forKey: "animal_idle_action")
        context.branchNode?.removeAction(forKey: "animal_branch_idle")
    }
}

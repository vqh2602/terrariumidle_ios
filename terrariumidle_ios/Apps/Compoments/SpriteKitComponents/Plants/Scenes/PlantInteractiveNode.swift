//
//  PlantInteractiveNode.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit

// MARK: - Plant Interactive Node Protocol
/// Giao thức chung cho mọi Node Cây SpriteKit có khả năng tương tác & diễn hoạt
public protocol PlantInteractiveNode: AnyObject {
    var asNode: SKNode { get }
    var motionEffect: PlantMotionEffect { get set }
    var tapEffects: [PlantTapEffect] { get set }
    func playTapAnimation()
    /// Khôi phục chuyển động nhàn rỗi (idle sway / wind) sau khi hoàn tất hiệu ứng tap
    func resumeIdleAnimation()
}

extension PlantInteractiveNode {
    public var motionEffect: PlantMotionEffect {
        get { StandardPlantBounceMotionEffect() }
        set { }
    }
    public var tapEffects: [PlantTapEffect] {
        get { [] }
        set { }
    }
    public func resumeIdleAnimation() {}
}

extension PlantInteractiveNode where Self: SKNode {
    public var asNode: SKNode { self }
}

// MARK: - Conformance cho 14 loài cây hiện có
extension Plant1Node: PlantInteractiveNode {}
extension Plant2Node: PlantInteractiveNode {}
extension Plant3Node: PlantInteractiveNode {}
extension Plant4Node: PlantInteractiveNode {}
extension Plant5Node: PlantInteractiveNode {}
extension Plant6Node: PlantInteractiveNode {}
extension Plant7Node: PlantInteractiveNode {}
extension Plant8Node: PlantInteractiveNode {}
extension Plant9Node: PlantInteractiveNode {}
extension Plant10Node: PlantInteractiveNode {}
extension Plant11Node: PlantInteractiveNode {}
extension Plant12Node: PlantInteractiveNode {}
extension Plant13Node: PlantInteractiveNode {}
extension Plant14Node: PlantInteractiveNode {}
extension Plant15Node: PlantInteractiveNode {}
extension Plant16Node: PlantInteractiveNode {}
extension Plant17Node: PlantInteractiveNode {}
extension Plant18Node: PlantInteractiveNode {}
extension Plant19Node: PlantInteractiveNode {}
extension Plant20Node: PlantInteractiveNode {}
extension Plant21Node: PlantInteractiveNode {}
extension Plant22Node: PlantInteractiveNode {}
extension Plant23Node: PlantInteractiveNode {}
extension Plant24Node: PlantInteractiveNode {}
extension Plant25Node: PlantInteractiveNode {}
extension Plant26Node: PlantInteractiveNode {}
extension Plant27Node: PlantInteractiveNode {}
extension Plant28Node: PlantInteractiveNode {}
extension Plant29Node: PlantInteractiveNode {}
extension Plant30Node: PlantInteractiveNode {}

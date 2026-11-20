//
//  TerrariumSlotScene.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Scene SpriteKit Hợp Nhất (Unified Slot Scene) chứa cả Chậu (Pot) và Cây (Plant)
/// - Quản lý tương tác, mount point, và phân tầng chiều sâu (Z-ordering) đa lớp
/// - Tiết kiệm tài nguyên Metal/OpenGL (gộp 2 SKView thành 1 SKView duy nhất)
/// - Giúp tán lá có thể rủ tràn qua mặt trước miệng chậu và dây treo vắt trước lá
public final class TerrariumSlotScene: SKScene {

    // MARK: - Properties

    private var potId: String = "pot1"
    private var plantId: String = "plant1"
    private var plantLevel: Int = 1
    private var isHanging: Bool = false
    private var widthFill: CGFloat = 0.0

    private var potNode: PotInteractiveNode?
    private var plantNode: PlantInteractiveNode?
    private var plantMountSocket: SKNode?

    public var onTap: (() -> Void)?

    // MARK: - Initializers

    public override init() {
        super.init(size: .zero)
        setupBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBasics()
    }

    private func setupBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.0) // Luôn neo gốc toạ độ tại đáy giữa
    }

    // MARK: - Configuration

    public func configure(
        potId: String,
        plantId: String,
        plantLevel: Int = 1,
        isHanging: Bool = false,
        widthFill: CGFloat = 0.0,
        onTap: (() -> Void)? = nil
    ) {
        let cleanPot = potId.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanPlant = plantId.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanFill = min(max(widthFill, 0.0), 1.0)

        let changed = self.potId != cleanPot ||
                      self.plantId != cleanPlant ||
                      self.plantLevel != plantLevel ||
                      self.isHanging != isHanging ||
                      abs(self.widthFill - cleanFill) > 0.001

        self.potId = cleanPot
        self.plantId = cleanPlant
        self.plantLevel = plantLevel
        self.isHanging = isHanging
        self.widthFill = cleanFill
        self.onTap = onTap

        if (changed || (potNode == nil && plantNode == nil)) && size.width > 0 && size.height > 0 {
            buildSlot()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        view.isPaused = false
        self.isPaused = false
        if (potNode == nil && plantNode == nil) && size.width > 0 && size.height > 0 {
            buildSlot()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if (potNode == nil && plantNode == nil) || abs(oldSize.width - size.width) > 2 || abs(oldSize.height - size.height) > 2 {
            if size.width > 0 && size.height > 0 {
                buildSlot()
            }
        }
    }

    // MARK: - Build Slot (Hợp nhất Pot & Plant)

    private func buildSlot() {
        guard size.width > 0, size.height > 0 else { return }

        removeAllChildren()
        potNode = nil
        plantNode = nil
        plantMountSocket = nil
        anchorPoint = CGPoint(x: 0.5, y: 0.0)

        // ==========================================
        // 1. XÂY DỰNG CHẬU (POT NODE)
        // ==========================================
        let hasPot = !potId.isEmpty && potId != "none"
        let hasPlant = !plantId.isEmpty && plantId != "none"

        var slotMountPosition = CGPoint.zero

        if hasPot {
            let potH: CGFloat
            if isHanging {
                // Chậu treo: dây treo + bầu chậu chiếm khoảng 75% chiều cao khung slot
                potH = size.height * 0.78
            } else {
                // Chậu để bàn: chiếm khoảng 25% ~ 30% chiều cao khung slot
                potH = min(size.height * 0.28, size.width * 0.46)
            }

            let potContainerSize = CGSize(width: size.width, height: potH)
            let pot = PotFactory.createPot(
                id: potId,
                containerSize: potContainerSize,
                isHanging: isHanging,
                widthFill: widthFill
            )

            if isHanging {
                // Neo tại đỉnh slot (y = size.height)
                pot.asNode.position = CGPoint(x: 0, y: size.height)
            } else {
                // Đáy chậu nằm ngay ngắn trên mặt kệ (y = 0)
                pot.asNode.position = CGPoint(x: 0, y: 0)
            }

            // Gán zPosition cơ sở cho chậu
            pot.asNode.zPosition = 5
            addChild(pot.asNode)
            self.potNode = pot

            // Xác định điểm cắm cây (Mount Point) từ chậu
            let localMount = pot.plantMountPoint
            slotMountPosition = pot.asNode.convert(localMount, to: self)
        } else {
            // Không có chậu: điểm cắm ở đáy slot
            slotMountPosition = CGPoint(x: 0, y: isHanging ? size.height : 0)
        }

        // ==========================================
        // 2. XÂY DỰNG CÂY (PLANT NODE)
        // ==========================================
        if hasPlant {
            let plantContainerH: CGFloat
            if isHanging {
                // Cây treo: mọc/rủ từ bầu chậu xuống phía dưới
                plantContainerH = max(size.height * 0.65, size.height - (size.height - slotMountPosition.y))
            } else {
                // Cây để bàn: vươn từ miệng chậu lên đến đỉnh khung slot
                plantContainerH = max(size.height * 0.74, size.height - slotMountPosition.y)
            }

            let plantContainerSize = CGSize(width: size.width, height: plantContainerH)
            if let plant = PlantFactory.createPlant(
                id: plantId,
                level: plantLevel,
                containerSize: plantContainerSize,
                isHanging: isHanging
            ) {
                // Gắn cây chính xác vào điểm mount
                plant.asNode.position = slotMountPosition
                
                // zPosition của cây:
                // z = 10 đảm bảo gốc cây mọc sau thân trước của chậu (z = 20)
                // trong khi các lá vươn trước hoặc rủ xuống có thể có z = 15..25
                plant.asNode.zPosition = 10
                
                addChild(plant.asNode)
                self.plantNode = plant
            }
        }
    }

    // MARK: - Touch Interaction

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Phân biệt tap vào vùng chậu hay vùng cây:
        // Nếu chạm ở nửa dưới (gần chậu) -> ưu tiên tap chậu
        let isLowerHalf: Bool
        if isHanging {
            // Chậu treo: bầu chậu ở khoảng giữa/trên
            isLowerHalf = location.y > size.height * 0.5
        } else {
            // Chậu để bàn: chậu ở 30% phía dưới
            isLowerHalf = location.y < size.height * 0.32
        }

        if isLowerHalf, let pot = potNode {
            pot.playTapAnimation()
        } else if let plant = plantNode {
            plant.playTapAnimation()
        } else if let pot = potNode {
            pot.playTapAnimation()
        }

        // Bắn callback ra ngoài SwiftUI
        onTap?()
    }
}

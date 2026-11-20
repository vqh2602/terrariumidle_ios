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
    private var itemTypeAttribute: ItemTypeAttribute = .none

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
        itemTypeAttribute: ItemTypeAttribute? = nil,
        onTap: (() -> Void)? = nil
    ) {
        let cleanPot = potId.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanPlant = plantId.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanFill = min(max(widthFill, 0.0), 1.0)
        let resolvedAttribute = itemTypeAttribute ?? ItemDataManager.shared.getPlant(byId: cleanPlant)?.itemTypeAttribute ?? .none
        let effectiveHanging = isHanging || resolvedAttribute.isHanging

        let changed = self.potId != cleanPot ||
                      self.plantId != cleanPlant ||
                      self.plantLevel != plantLevel ||
                      self.isHanging != effectiveHanging ||
                      self.itemTypeAttribute != resolvedAttribute ||
                      abs(self.widthFill - cleanFill) > 0.001

        self.potId = cleanPot
        self.plantId = cleanPlant
        self.plantLevel = plantLevel
        self.isHanging = effectiveHanging
        self.widthFill = cleanFill
        self.itemTypeAttribute = resolvedAttribute
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
            pot.asNode.zPosition = 0
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
                // PHÂN TẦNG CHIỀU SÂU Z-INDEX DỰA THEO itemTypeAttribute CỦA CÂY:
                // - .front: Cây nằm TRƯỚC mặt chậu (z = 70 > potBody 50) -> cành lá/dây leo phủ tràn qua miệng chậu
                // - .none: Cây mọc từ lòng chậu và nằm SAU mặt trước chậu (mount z = 10, các lá 21..29 < potBody 50) -> che giấu vết cắt cuống
                // - .hanging: Cây treo từ trên chúc xuống
                if let pot = potNode, let mount = pot.plantMountNode {
                    // Cây cắm trực tiếp vào socket plantMount của chậu
                    mount.isHidden = false
                    mount.isPaused = false
                    plant.asNode.isHidden = false
                    plant.asNode.isPaused = false
                    plant.asNode.position = .zero
                    if itemTypeAttribute.isInFront {
                        plant.asNode.zPosition = 60 // Tổng z = 10 + 60 = 70 > potNode (50) -> nằm TRƯỚC chậu
                    } else {
                        plant.asNode.zPosition = 0  // Tổng z = 10 + 0 = 10 (các lá 21..29 < potNode 50) -> nằm SAU chậu
                    }
                    mount.addChild(plant.asNode)
                    self.plantMountSocket = mount
                } else {
                    plant.asNode.isHidden = false
                    plant.asNode.isPaused = false
                    plant.asNode.position = slotMountPosition
                    if itemTypeAttribute.isInFront {
                        plant.asNode.zPosition = 70
                    } else {
                        plant.asNode.zPosition = 10
                    }
                    addChild(plant.asNode)
                }
                self.plantNode = plant
            }
        }
    }

    // MARK: - Touch Interaction

    private var lastTapTime: TimeInterval = 0

    /// Kích hoạt hiệu ứng tap đồng thời cho cả Cây và Chậu (tránh xung đột vùng bấm và không bị miss tap)
    public func handleTap() {
        let now = CACurrentMediaTime()
        guard now - lastTapTime > 0.08 else { return } // Debounce 80ms chống tap đúp
        lastTapTime = now

        // ÁP DỤNG HIỆU ỨNG TAP ĐỒNG THỜI CHO CẢ CHẬU VÀ CÂY:
        // - Chậu: nhún nảy squash & stretch đàn hồi, bóng đổ co giãn, sparkle/hiệu ứng đá
        // - Cây: nhún nảy nẩy cành lá, nhả bọt khí Oxy +O2 bay lên
        potNode?.playTapAnimation()
        plantNode?.playTapAnimation()

        // Bắn callback ra ngoài SwiftUI
        onTap?()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTap()
    }
}

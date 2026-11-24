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
    private var slotSize: CGSize = .zero
    private var widthFill: CGFloat = 0.0
    private var itemTypeAttribute: ItemTypeAttribute = .none

    private var potNode: PotInteractiveNode?
    private var plantNode: PlantInteractiveNode?
    private var plantMountSocket: SKNode?
    private var plantContainerSize: CGSize = .zero
    private var lastCareAnimationID: UUID?
    private var isPerformingCare = false

    public var onTap: (() -> Void)?
    public var onAutoTap: (() -> Void)?

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
        slotSize: CGSize = .zero,
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
                      abs(self.slotSize.width - slotSize.width) > 1 ||
                      abs(self.slotSize.height - slotSize.height) > 1 ||
                      abs(self.widthFill - cleanFill) > 0.001

        self.potId = cleanPot
        self.plantId = cleanPlant
        self.plantLevel = plantLevel
        self.isHanging = effectiveHanging
        self.slotSize = slotSize
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
        plantContainerSize = .zero
        anchorPoint = CGPoint(x: 0.5, y: 0.0)

        // ==========================================
        // 1. XÂY DỰNG CHẬU (POT NODE)
        // ==========================================
        let hasPot = !potId.isEmpty && potId != "none"
        let hasPlant = !plantId.isEmpty && plantId != "none"

        let baseW = slotSize.width > 0 ? slotSize.width : size.width
        let baseH = slotSize.height > 0 ? slotSize.height : size.height

        var slotMountPosition = CGPoint.zero

        if hasPot {
            let potH: CGFloat
            if isHanging {
                // Chậu treo: dây treo + bầu chậu chiếm khoảng 70% chiều cao khung slot
                potH = baseH * 0.70
            } else {
                // Chậu để bàn: chiếm khoảng 25% ~ 30% chiều cao khung slot
                potH = min(baseH * 0.28, baseW * 0.46)
            }

            let potContainerSize = CGSize(width: baseW, height: potH)
            let pot = PotFactory.createPot(
                id: potId,
                containerSize: potContainerSize,
                isHanging: isHanging,
                widthFill: widthFill
            )

            if isHanging {
                // Neo chính xác tại đỉnh cao nhất của Scene (y = size.height) để dính sát mép trên thanh kệ
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
            if let mountNode = pot.plantMountNode, let mountParent = mountNode.parent {
                slotMountPosition = mountParent.convert(mountNode.position, to: self)
            } else {
                let localMount = pot.plantMountPoint
                slotMountPosition = pot.asNode.convert(localMount, to: self)
            }
        } else {
            // Không có chậu: điểm cắm ở đáy slot
            slotMountPosition = CGPoint(x: 0, y: isHanging ? size.height : 0)
        }

        // ==========================================
        // 2. XÂY DỰNG CÂY (PLANT NODE)
        // ==========================================
        if hasPlant {
            // Giữ cây nằm gọn gàng, vừa vặn trong khung ô (fitRatio ~ 88% width, 86% height)
            // Không bị phóng to quá cỡ, không tràn lấn át cây bên cạnh và không đâm vào thanh kệ trên
            let plantFitW = baseW * 0.88
            let plantContainerH: CGFloat
            if isHanging {
                // Cây treo: mọc/rủ từ bầu chậu xuống phía dưới vừa vặn khung slot
                plantContainerH = baseH * 0.68
            } else {
                // Cây để bàn: vươn từ miệng chậu lên, giữ khoảng đệm 14% dưới thanh kệ trên
                plantContainerH = max(baseH * 0.50, (baseH - slotMountPosition.y) * 0.86)
            }

            let plantContainerSize = CGSize(width: plantFitW, height: plantContainerH)
            self.plantContainerSize = plantContainerSize
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

    func playCareAnimation(_ request: PlantCareAnimationRequest, completion: @escaping () -> Void) {
        guard lastCareAnimationID != request.id else { return }
        lastCareAnimationID = request.id
        isPerformingCare = true
        let target: CGPoint
        if let plant = plantNode?.asNode {
            target = plant.convert(.zero, to: self)
        } else if let pot = potNode {
            target = pot.asNode.convert(pot.plantMountPoint, to: self)
        } else {
            target = CGPoint(x: 0, y: slotSize.height * 0.25)
        }
        let originalPosition = plantNode?.asNode.position ?? .zero
        let originalRotation = plantNode?.asNode.zRotation ?? 0
        let originalAlpha = plantNode?.asNode.alpha ?? 1
        let animation = PlantCareAnimation(action: request.action, target: target,
                                           width: slotSize.width, plant: plantNode?.asNode) { [weak self] in
            self?.isPerformingCare = false
            if request.action == .remove, let plant = self?.plantNode {
                // Restore if the final resource/identity check rejects removal.
                plant.asNode.position = originalPosition
                plant.asNode.zRotation = originalRotation
                plant.asNode.alpha = originalAlpha
                plant.resumeIdleAnimation()
            }
            completion()
        }
        addChild(animation)
    }

    private var lastTapTime: TimeInterval = 0

    /// Automatic watering keeps rewards and oxygen, without sound or plant/pot motion.
    public func handleAutoTap() {
        guard !isPerformingCare, let plant = plantNode else { return }
        plant.playOxygenBubbles(containerSize: plantContainerSize, level: plantLevel)
        onAutoTap?()
    }

    /// Kích hoạt hiệu ứng tap đồng thời cho cả Cây và Chậu (tránh xung đột vùng bấm và không bị miss tap)
    public func handleTap() {
        guard !isPerformingCare else { return }
        let now = CACurrentMediaTime()
        guard now - lastTapTime > 0.12 else { return } // Debounce 120ms chống spam tap
        lastTapTime = now

        // ÁP DỤNG HIỆU ỨNG TAP ĐỒNG THỜI CHO CẢ CHẬU VÀ CÂY:
        // - Chậu: nhún nảy squash & stretch đàn hồi, bóng đổ co giãn, sparkle/hiệu ứng đá
        // - Cây: nhún nảy nẩy cành lá, nhả bọt khí Oxy +O2 bay lên
        potNode?.playTapAnimation()
        plantNode?.playTapAnimation()

        // PHÁT ÂM THANH TAP KHI CHẠM VÀO CÂY/CHẬU TRÊN BAN CÔNG:
        // Ưu tiên sound của Cây ("tap"), nếu không có cây thì dùng sound của Chậu (hoặc fallback "tap")
        let plantSound = (!plantId.isEmpty && plantId != "none") ? ItemDataManager.shared.getPlant(byId: plantId)?.clickSound : nil
        let potSound = (!potId.isEmpty && potId != "none") ? ItemDataManager.shared.getPot(byId: potId)?.clickSound : nil
        let soundName = plantSound ?? potSound ?? "tap"
        AudioPlayer.shared.playClickSound(named: soundName)

        // Bắn callback ra ngoài SwiftUI
        onTap?()
    }
}

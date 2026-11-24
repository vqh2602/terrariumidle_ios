//
//  SpriteKitStickerView.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import SwiftUI

/// Typealias ngắn gọn để tái sử dụng thuận tiện ở các màn hình
public typealias StickerView = SpriteKitStickerView

// MARK: - Sticker Availability
public enum StickerAvailability {
    public static let supportedStickerIds: Set<String> = [
        "sticker1",
        "sticker2",
        "sticker3",
        "sticker4"
    ]

    public static func isAvailable(stickerId: String) -> Bool {
        supportedStickerIds.contains(stickerId.lowercased().trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Sticker Registry (Quản lý Kích thước Tỉ lệ Hiển thị Tập Trung)
public enum StickerRegistry {
    /// Tỉ lệ kích thước hiển thị mặc định của sticker so với chiều cao ô kệ (fitRatio: 0.3 ... 1.0)
    /// - Muốn sticker to hơn: tăng số này (ví dụ 0.52 -> 0.65)
    /// - Muốn sticker nhỏ lại: giảm số này (ví dụ 0.65 -> 0.45)
    public static func defaultFitRatio(for stickerId: String) -> CGFloat {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        switch cleanId {
        case "sticker1": return Sticker1View.defaultFitRatio // Búp bê cầu nắng: 0.65 (65% chiều cao ô)
        case "sticker2": return Sticker2View.defaultFitRatio // Mèo thần tài: 0.72
        case "sticker3": return Sticker3View.defaultFitRatio // Cờ cá chép: 0.64
        case "sticker4": return Sticker4View.defaultFitRatio // Đèn thắp sáng: 0.52 (nhỏ gọn, không đụng trần)
        default: return 0.65
        }
    }
}

// MARK: - SpriteKit Sticker View
/// SwiftUI Component hiển thị Sticker / Vật trang trí bằng SpriteKit
/// - Tự động nhận diện sticker treo hay để bàn dựa trên cấu hình Data-Driven (stickers_data.json)
/// - Đung đưa theo gió hoặc nhịp thở / lắc lư tự nhiên
/// - Vùng đệm chống cắt biên (Anti-Clipping Buffer): mở rộng biên render 22% X và 15% Y
///   để hiệu ứng ánh sáng và sao lấp lánh không bao giờ bị cắt mép khung.
public struct SpriteKitStickerView: View {
    public var stickerId: String = "sticker1"
    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    /// Tỉ lệ vùng đệm an toàn để hiệu ứng ánh sáng và cành lá không chạm mép Metal GPU
    public var overflowRatioX: CGFloat = 0.22
    public var overflowRatioY: CGFloat = 0.15
    public var onTap: (() -> Void)? = nil

    private var renderWidth: CGFloat {
        width * (1.0 + overflowRatioX)
    }

    private var renderHeight: CGFloat {
        height * (1.0 + overflowRatioY)
    }

    /// Xác định trạng thái treo thực tế dựa trên JSON cấu hình (ưu tiên ItemDataManager)
    private var resolvedIsHanging: Bool {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        if let item = ItemDataManager.shared.getItem(byId: cleanId) {
            return item.itemTypeAttribute.isHanging
        }
        return isHanging
    }

    @State private var scene: SpriteKitStickerScene
    @State private var lastTapTime: TimeInterval = 0

    public init(
        stickerId: String = "sticker1",
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 180,
        overflowRatioX: CGFloat = 0.22,
        overflowRatioY: CGFloat = 0.15,
        onTap: (() -> Void)? = nil
    ) {
        self.stickerId = stickerId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.overflowRatioX = overflowRatioX
        self.overflowRatioY = overflowRatioY
        self.onTap = onTap

        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        let resolved: Bool
        if let item = ItemDataManager.shared.getItem(byId: cleanId) {
            resolved = item.itemTypeAttribute.isHanging
        } else {
            resolved = isHanging
        }

        let rW = width * (1.0 + overflowRatioX)
        let rH = height * (1.0 + overflowRatioY)
        let s = SpriteKitStickerScene(size: CGSize(width: rW, height: rH))
        s.configure(stickerId: cleanId, isHanging: resolved, slotSize: CGSize(width: width, height: height))
        _scene = State(initialValue: s)
    }

    public var body: some View {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        let activeHanging = resolvedIsHanging

        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: renderWidth, height: renderHeight)
            .frame(width: width, height: height, alignment: activeHanging ? .top : .bottom)
            .id("\(cleanId)-\(activeHanging)-\(width)-\(height)")
            .contentShape(Rectangle())
            .onTapGesture {
                let now = CACurrentMediaTime()
                guard now - lastTapTime > 0.12 else { return }
                lastTapTime = now

                scene.playTapAnimation()
                onTap?()
            }
            .onAppear {
                scene.configure(stickerId: cleanId, isHanging: activeHanging, slotSize: CGSize(width: width, height: height))
            }
            .onChange(of: stickerId) { _, newId in
                let newCleanId = newId.lowercased().trimmingCharacters(in: .whitespaces)
                let newResolved = ItemDataManager.shared.getItem(byId: newCleanId)?.itemTypeAttribute.isHanging ?? isHanging
                scene.configure(stickerId: newCleanId, isHanging: newResolved, slotSize: CGSize(width: width, height: height))
            }
            .onChange(of: isHanging) { _, _ in
                scene.configure(stickerId: cleanId, isHanging: activeHanging, slotSize: CGSize(width: width, height: height))
            }
    }
}

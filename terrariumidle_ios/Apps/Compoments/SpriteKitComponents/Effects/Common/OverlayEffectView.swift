//
//  OverlayEffectView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// View tổng hợp hiển thị toàn bộ các lớp phủ animation (Overlays) tự làm bằng SpriteKit
/// Thay thế hoàn toàn phụ thuộc vào file Rive `.riv` cho mục Overlay:
/// - overlay1: Lá rơi xanh ngọc
/// - overlay2: Lá rơi mùa thu
/// - overlay3: Cánh hoa oải hương
/// - overlay4: Đom đóm bay lượn phát sáng
/// - overlay5: Hoa đào rơi
public struct OverlayEffectView: View {
    /// ID lớp phủ từ effects_data.json (ví dụ: "overlay1", "overlay2",...)
    public var overlayId: String?

    /// Danh sách ảnh tuỳ biến (nếu người dùng muốn truyền 1 -> 6 ảnh riêng)
    public var customImages: [UIImage] = []

    /// Tạm dừng hiệu ứng
    public var isPaused: Bool = false

    public init(
        overlayId: String?,
        customImages: [UIImage] = [],
        isPaused: Bool = false
    ) {
        self.overlayId = overlayId
        self.customImages = customImages
        self.isPaused = isPaused
    }

    public var body: some View {
        if let id = overlayId, !id.isEmpty {
            let effectItem = ItemDataManager.shared.getEffect(byIdOrImage: id)
            let kind = effectItem?.kind ?? (id == "overlay4" ? "fireflies" : "fallingLeaves")

            Group {
                if kind == "fireflies" {
                    FirefliesView(
                        count: effectItem?.particleCount ?? 26,
                        customImages: customImages,
                        isPaused: isPaused
                    )
                    .id("fireflies_\(id)")
                } else {
                    let wind = WindDirection.fromString(effectItem?.wind)
                    let density = LeafDensity.fromString(effectItem?.density)
                    let speed = LeafSpeed.fromString(effectItem?.speed)
                    let configuredImages = effectItem?.images ?? []
                    let textures = configuredImages.isEmpty ? OverlayEffectConfig.generateTextures(for: id) : []

                    FallingLeavesView(
                        leafImages: configuredImages,
                        customImages: customImages,
                        customTextures: textures,
                        density: density,
                        wind: wind,
                        speed: speed,
                        isPaused: isPaused
                    )
                    .id("leaves_\(id)_\(configuredImages.joined(separator: "_"))")
                }
            }
            .allowsHitTesting(false) // ⭐️ Luôn đảm bảo click xuyên qua
            .ignoresSafeArea(.all)
        } else {
            EmptyView()
        }
    }
}

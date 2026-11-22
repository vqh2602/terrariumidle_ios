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
        "sticker1"
    ]

    public static func isAvailable(stickerId: String) -> Bool {
        supportedStickerIds.contains(stickerId.lowercased().trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - SpriteKit Sticker View
/// SwiftUI Component hiển thị Sticker / Vật trang trí bằng SpriteKit
/// - Tự động đung đưa theo gió nhịp nhàng
/// - Khi click: Mặt trời vàng rực rỡ tỏa sáng + đu đưa con lắc đàn hồi
/// - Vùng đệm chống cắt biên (Anti-Clipping Buffer): mở rộng biên render 22% X và 15% Y
///   để hiệu ứng mặt trời, tia nắng và sao lấp lánh không bao giờ bị cắt mép khung.
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
        let rW = width * (1.0 + overflowRatioX)
        let rH = height * (1.0 + overflowRatioY)
        let s = SpriteKitStickerScene(size: CGSize(width: rW, height: rH))
        s.configure(stickerId: cleanId, isHanging: isHanging, slotSize: CGSize(width: width, height: height))
        _scene = State(initialValue: s)
    }

    public var body: some View {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)

        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: renderWidth, height: renderHeight)
            .frame(width: width, height: height, alignment: isHanging ? .top : .bottom)
            .id("\(cleanId)-\(isHanging)-\(width)-\(height)")
            .contentShape(Rectangle())
            .onTapGesture {
                let now = CACurrentMediaTime()
                guard now - lastTapTime > 0.08 else { return }
                lastTapTime = now

                scene.playTapAnimation()
                onTap?()
            }
            .onAppear {
                scene.configure(stickerId: cleanId, isHanging: isHanging, slotSize: CGSize(width: width, height: height))
            }
            .onChange(of: stickerId) { _, newId in
                scene.configure(stickerId: newId, isHanging: isHanging, slotSize: CGSize(width: width, height: height))
            }
            .onChange(of: isHanging) { _, newHanging in
                scene.configure(stickerId: cleanId, isHanging: newHanging, slotSize: CGSize(width: width, height: height))
            }
    }
}

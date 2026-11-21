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
/// - Tương thích hoàn toàn với hệ thống kệ Terrarium Slot và Shop
public struct SpriteKitStickerView: View {
    public var stickerId: String = "sticker1"
    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    @State private var scene: SpriteKitStickerScene
    @State private var lastTapTime: TimeInterval = 0

    public init(
        stickerId: String = "sticker1",
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 180,
        onTap: (() -> Void)? = nil
    ) {
        self.stickerId = stickerId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap

        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        let s = SpriteKitStickerScene(size: CGSize(width: width, height: height))
        s.configure(stickerId: cleanId, isHanging: isHanging)
        _scene = State(initialValue: s)
    }

    public var body: some View {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)

        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
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
                scene.configure(stickerId: cleanId, isHanging: isHanging)
            }
            .onChange(of: stickerId) { _, newId in
                scene.configure(stickerId: newId, isHanging: isHanging)
            }
            .onChange(of: isHanging) { _, newHanging in
                scene.configure(stickerId: cleanId, isHanging: newHanging)
            }
    }
}

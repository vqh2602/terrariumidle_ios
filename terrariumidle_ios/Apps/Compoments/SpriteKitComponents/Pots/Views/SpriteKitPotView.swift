//
//  SpriteKitPotView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// Typealias ngắn gọn để tái sử dụng thuận tiện ở các nơi
public typealias PotView = SpriteKitPotView

/// SwiftUI Component hiển thị chậu cây bằng SpriteKit
/// - Đổ bóng tự nhiên dưới đáy
/// - Phản hồi nảy đàn hồi (spring bounce) khi chạm vào
/// - Hỗ trợ cả chậu đứng trên kệ và chậu treo móc
public struct SpriteKitPotView: View {
    public var potId: String = "pot1"
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    @State private var scene: SpriteKitPotScene

    public init(
        potId: String = "pot1",
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 80,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap

        let initialScene = Self.makeScene(potId: potId, isHanging: isHanging, width: width, height: height)
        _scene = State(initialValue: initialScene)
    }

    public var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                scene.playTapAnimation()
                let soundName = ItemDataManager.shared.getPot(byId: potId)?.clickSound ?? "tap"
                AudioPlayer.shared.playClickSound(named: soundName)
                onTap?()
            }
            .onChange(of: potId) { newId in
                scene.configure(potId: newId, isHanging: isHanging)
            }
            .onChange(of: isHanging) { newHanging in
                scene.configure(potId: potId, isHanging: newHanging)
            }
    }

    private static func makeScene(potId: String, isHanging: Bool, width: CGFloat, height: CGFloat) -> SpriteKitPotScene {
        let newScene = SpriteKitPotScene(size: CGSize(width: width, height: height))
        newScene.configure(potId: potId, isHanging: isHanging)
        return newScene
    }
}

// MARK: - Preview Chậu cây SpriteKit
#Preview {
    VStack(spacing: 30) {
        Text("🪴 SpriteKit Pot View Demo")
            .font(.headline)

        HStack(spacing: 24) {
            VStack {
                Text("Chậu 1 (pot1)").font(.caption)
                PotView(potId: "pot1", isHanging: false, width: 120, height: 85)
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(8)
            }

            VStack {
                Text("Chậu treo (pot1)").font(.caption)
                PotView(potId: "pot1", isHanging: true, width: 120, height: 110)
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(8)
            }
        }
    }
    .padding()
}

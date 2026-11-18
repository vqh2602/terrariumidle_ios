//
//  SpriteKitPlantView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component hiển thị cây bằng SpriteKit
/// - Đung đưa nhẹ tự nhiên trong gió
/// - Tự động mở rộng theo cấp độ cây (`plantLevel`)
/// - Phản hồi nảy và nhả bong bóng oxy khi nhấn vào
public struct SpriteKitPlantView: View {
    public var plantId: String = "plant1"
    public var plantLevel: Int = 1
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    @State private var scene: SpriteKitPlantScene

    public init(
        plantId: String = "plant1",
        plantLevel: Int = 1,
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 140,
        onTap: (() -> Void)? = nil
    ) {
        self.plantId = plantId
        self.plantLevel = plantLevel
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap

        let initialScene = Self.makeScene(plantId: plantId, level: plantLevel, isHanging: isHanging, width: width, height: height)
        _scene = State(initialValue: initialScene)
    }

    public var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                scene.playTapAnimation()
                onTap?()
            }
            .onChange(of: plantId) { newId in
                scene.configure(plantId: newId, level: plantLevel, isHanging: isHanging)
            }
            .onChange(of: plantLevel) { newLevel in
                scene.configure(plantId: plantId, level: newLevel, isHanging: isHanging)
            }
    }

    private static func makeScene(plantId: String, level: Int, isHanging: Bool, width: CGFloat, height: CGFloat) -> SpriteKitPlantScene {
        let newScene = SpriteKitPlantScene(size: CGSize(width: width, height: height))
        newScene.configure(plantId: plantId, level: level, isHanging: isHanging)
        return newScene
    }
}

// MARK: - Preview Cây Cỏ Loe (Plant1) với 3 trạng thái (Level 1, 2, 3)
private struct SpriteKitPlant3StatesDemoView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("🌿 Cây Cỏ Loe (Plant1) - SpriteKit 3 Cấp độ")
                .font(.headline)
                .padding(.top)

            HStack(spacing: 16) {
                VStack {
                    Text("Lv.1: Gieo hạt").font(.caption).bold()
                    Text("Asset 100").font(.caption2).foregroundColor(.secondary)
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 1, width: 100, height: 130)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }

                VStack {
                    Text("Lv.2: Cây con").font(.caption).bold()
                    Text("Asset 200").font(.caption2).foregroundColor(.secondary)
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 2, width: 100, height: 130)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }

                VStack {
                    Text("Lv.3: Trưởng thành").font(.caption).bold()
                    Text("Asset 1 + Lá 2->19").font(.caption2).foregroundColor(.secondary)
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 3, width: 110, height: 130)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

#Preview("Plant1 3 States") {
    SpriteKitPlant3StatesDemoView()
}

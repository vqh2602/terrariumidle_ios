//
//  SpriteKitPlantView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// Typealias ngắn gọn để tái sử dụng thuận tiện ở các nơi
public typealias PlantView = SpriteKitPlantView

// MARK: - Plant Availability

public enum PlantAvailability {
    /// Danh sách ID các cây đã được phát triển hoàn thiện tài nguyên và hoạt ảnh
    public static let supportedPlantIds: Set<String> = [
        "plant1"
    ]

    /// Kiểm tra xem loài cây này đã có trong phiên bản hiện tại chưa
    public static func isAvailable(plantId: String) -> Bool {
        let cleanId = plantId.lowercased().trimmingCharacters(in: .whitespaces)
        return supportedPlantIds.contains(cleanId)
    }
}

/// View hiển thị thông báo cho các cây chưa có asset trong phiên bản hiện tại (thay thế mockup)
public struct UnsupportedPlantPlaceholderView: View {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.30), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                )

            VStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.green.opacity(0.80))

                Text("<update app để hiển thị>")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: width, height: height)
    }
}

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
        if PlantAvailability.isAvailable(plantId: plantId) {
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
        } else {
            // Không mockup nữa - hiển thị thông báo "<update app để hiển thị>"
            UnsupportedPlantPlaceholderView(width: width, height: height)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }
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

            HStack(spacing: 12) {
                VStack {
                    Text("Lv.1: Hạt").font(.caption).bold()
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 1, width: 85, height: 120)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }

                VStack {
                    Text("Lv.2: Cây con").font(.caption).bold()
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 2, width: 85, height: 120)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }

                VStack {
                    Text("Lv.3: Trưởng thành").font(.caption).bold()
                    SpriteKitPlantView(plantId: "plant1", plantLevel: 3, width: 95, height: 120)
                        .background(Color.black.opacity(0.04))
                        .cornerRadius(8)
                }

                VStack {
                    Text("Chưa có (Plant2)").font(.caption).bold()
                    SpriteKitPlantView(plantId: "plant2", plantLevel: 1, width: 95, height: 120)
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

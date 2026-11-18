//
//  Plant1View.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Cây Cỏ Loe (Plant1)
/// - Tái sử dụng SpriteKitPlantView (PlantView) để tránh lặp lại code SpriteView và quản lý Scene lifecycle
/// - Quản lý 3 trạng thái theo level logic (Level 1, 2, 3):
///   1. Level 1: Gieo hạt (dùng asset `Asset-100`)
///   2. Level 2: Cây con (dùng asset `Asset-200`)
///   3. Level 3+: Cây trưởng thành (ghép từ 9 phiến lá hoạt ảnh động `Asset-2`...`Asset-10`, `Asset-1` là ảnh đại diện tĩnh không đưa vào scene)
public struct Plant1View: View {
    public var growthState: Plant1GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = false
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant1GrowthState = .mature(level: 3),
        width: CGFloat = 120,
        height: CGFloat = 150,
        isHanging: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.growthState = growthState
        self.width = width
        self.height = height
        self.isHanging = isHanging
        self.onTap = onTap
    }

    public init(
        level: Int = 3,
        width: CGFloat = 120,
        height: CGFloat = 150,
        isHanging: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.init(growthState: Plant1GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant1",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id(growthState.rawLevel)
    }
}

// MARK: - Interactive Preview Struct
private struct Plant1InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌿 Demo Plant1 SpriteKit")
                .font(.title2).bold()

            Plant1View(level: selectedLevel, width: 160, height: 210)
                .background(Color.black.opacity(0.04))
                .cornerRadius(12)
                .shadow(radius: 4)
                .id(selectedLevel)

            Text("Trạng thái: \(Plant1GrowthState(level: selectedLevel).title)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("Lv.1: Hạt") {
                    selectedLevel = 1
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button("Lv.2: Cây con") {
                    selectedLevel = 2
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Lv.3: Trưởng thành") {
                    selectedLevel = 3
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)

                Button("Lv.10: Cực đại") {
                    selectedLevel = 10
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding()
    }
}

#Preview("Plant1 Interactive Demo") {
    Plant1InteractiveDemoView()
}

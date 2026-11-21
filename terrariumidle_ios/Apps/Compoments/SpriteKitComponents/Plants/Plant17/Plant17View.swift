//
//  Plant17View.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Cây Cúc tần Ấn Độ (Plant17 - Vernonia elliptica)
public struct Plant17View: View {
    public var growthState: Plant17GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = true
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant17GrowthState = .mature(level: 3),
        width: CGFloat = 120,
        height: CGFloat = 160,
        isHanging: Bool = true,
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
        height: CGFloat = 160,
        isHanging: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.init(growthState: Plant17GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant17",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant17-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant17InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🪴 Demo Plant17 Vernonia elliptica SpriteKit")
                .font(.title2).bold()

            Plant17View(level: selectedLevel, width: 160, height: 220, isHanging: true)
                .background(Color.black.opacity(0.04))
                .cornerRadius(12)
                .shadow(radius: 4)
                .id(selectedLevel)

            Text("Trạng thái: \(Plant17GrowthState(level: selectedLevel).title)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button("Lv.1: Hạt") {
                    selectedLevel = 1
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button("Lv.2: Mầm") {
                    selectedLevel = 2
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                Button("Lv.3: Trưởng thành") {
                    selectedLevel = 3
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Lv.10: Cực đại") {
                    selectedLevel = 10
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding()
    }
}

#Preview {
    Plant17InteractiveDemoView()
}

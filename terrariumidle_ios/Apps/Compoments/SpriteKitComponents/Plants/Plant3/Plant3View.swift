//
//  Plant3View.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Cây Begonia Rex (Plant3 - Trầu bà lá lớn / Thu hải đường)
public struct Plant3View: View {
    public var growthState: Plant3GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = false
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant3GrowthState = .mature(level: 3),
        width: CGFloat = 140,
        height: CGFloat = 160,
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
        width: CGFloat = 140,
        height: CGFloat = 160,
        isHanging: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.init(growthState: Plant3GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant3",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant3-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant3InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌿 Demo Plant3 Begonia Rex SpriteKit")
                .font(.title2).bold()

            Plant3View(level: selectedLevel, width: 180, height: 210)
                .background(Color.black.opacity(0.04))
                .cornerRadius(12)
                .shadow(radius: 4)
                .id(selectedLevel)

            Text("Trạng thái: \(Plant3GrowthState(level: selectedLevel).title)")
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
                .tint(.purple)
            }
        }
        .padding()
    }
}

#Preview("Begonia Rex Interactive") {
    Plant3InteractiveDemoView()
}

//
//  Plant18View.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sen đá chuỗi ngọc bi (Plant18 - Curio rowleyanus / String of pearls)
public struct Plant18View: View {
    public var growthState: Plant18GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = true
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant18GrowthState = .mature(level: 3),
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
        self.init(growthState: Plant18GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant18",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant18-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant18InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🪴 Demo Plant18 Curio rowleyanus SpriteKit")
                .font(.headline)

            Plant18View(level: selectedLevel, width: 160, height: 220, isHanging: true)
                .frame(width: 160, height: 220)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)

            Text("Trạng thái: \(Plant18GrowthState(level: selectedLevel).title)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Lv.1 Hạt") {
                    selectedLevel = 1
                }
                .buttonStyle(.bordered)

                Button("Lv.2 Mầm") {
                    selectedLevel = 2
                }
                .buttonStyle(.bordered)

                Button("Lv.3 Cây") {
                    selectedLevel = 3
                }
                .buttonStyle(.borderedProminent)

                Button("Lv.10 Max") {
                    selectedLevel = 10
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    Plant18InteractiveDemoView()
}

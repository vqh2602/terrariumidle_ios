//
//  Plant22View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Thất mạt hương (Plant22 - Plectranthus hadiensis)
public struct Plant22View: View {
    public var growthState: Plant22GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = false
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant22GrowthState = .mature(level: 3),
        width: CGFloat = 120,
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
        width: CGFloat = 120,
        height: CGFloat = 160,
        isHanging: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.init(growthState: Plant22GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant22",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant22-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant22InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌱 Demo Plant22: Thất mạt hương (Plectranthus hadiensis)")
                .font(.headline)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Plant22View(
                    level: selectedLevel,
                    width: 170,
                    height: 220,
                    isHanging: false
                )
                .padding(.bottom, 15)
            }

            Picker("Trạng thái", selection: $selectedLevel) {
                Text("Gieo hạt (Lv.1)").tag(1)
                Text("Cây con (Lv.2)").tag(2)
                Text("Trưởng thành (Lv.3)").tag(3)
                Text("Cực đại (Lv.10)").tag(10)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
        }
        .padding()
    }
}

#Preview {
    Plant22InteractiveDemoView()
}

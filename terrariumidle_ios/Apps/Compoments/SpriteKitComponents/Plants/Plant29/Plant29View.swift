//
//  Plant29View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Xương rồng trụ xoắn (Plant29 - Cereus forbesii spiralis)
public struct Plant29View: View {
    public var growthState: Plant29GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = false
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant29GrowthState = .mature(level: 3),
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
        self.init(growthState: Plant29GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant29",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant29-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant29InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌱 Demo Plant29: Xương rồng trụ xoắn (Cereus forbesii spiralis)")
                .font(.headline)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Plant29View(
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
    Plant29InteractiveDemoView()
}

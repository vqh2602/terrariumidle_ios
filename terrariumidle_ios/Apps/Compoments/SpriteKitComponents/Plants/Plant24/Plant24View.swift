//
//  Plant24View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Hoa đào (Plant24 - Prunus persica)
public struct Plant24View: View {
    public var growthState: Plant24GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = false
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant24GrowthState = .mature(level: 3),
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
        self.init(growthState: Plant24GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant24",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant24-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant24InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌱 Demo Plant24: Hoa đào (Prunus persica)")
                .font(.headline)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Plant24View(
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
    Plant24InteractiveDemoView()
}

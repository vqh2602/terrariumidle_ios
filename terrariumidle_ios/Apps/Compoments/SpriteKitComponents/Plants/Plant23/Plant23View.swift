//
//  Plant23View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sen đá đinh (Plant23 - Sedum clavatum)
public struct Plant23View: View {
    public var growthState: Plant23GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = true
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant23GrowthState = .mature(level: 3),
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
        self.init(growthState: Plant23GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }

    public var body: some View {
        PlantView(
            plantId: "plant23",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant23-\(growthState.rawLevel)")
    }
}

// MARK: - Interactive Preview Struct
private struct Plant23InteractiveDemoView: View {
    @State private var selectedLevel: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            Text("🌱 Demo Plant23: Sen đá đinh (Sedum clavatum)")
                .font(.headline)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Plant23View(
                    level: selectedLevel,
                    width: 170,
                    height: 220,
                    isHanging: true
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
    Plant23InteractiveDemoView()
}

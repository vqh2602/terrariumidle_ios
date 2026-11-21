//
//  Pot19View.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 19: "Chậu lam ngọc tròn" (pot19 - Chậu treo / Hanging Pot)
public struct Pot19View: View {
    /// Độ giãn phủ chiều rộng mặc định của Chậu 19 (0.0 -> 1.0)
    public static var defaultWidthFill: CGFloat = 0.0

    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = Pot19View.defaultWidthFill
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill }
        set { widthFill = newValue }
    }

    public init(
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 180,
        widthFill: CGFloat = Pot19View.defaultWidthFill,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        self.onTap = onTap
    }

    public var body: some View {
        PotView(
            potId: "pot19",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot19InteractiveDemoView: View {
    @State private var isHanging: Bool = true
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("🪴 Demo Pot19: Chậu lam ngọc tròn (Hanging Pot)")
                .font(.headline)

            Pot19View(
                isHanging: isHanging,
                width: 130,
                height: 200,
                onTap: {
                    tapCount += 1
                }
            )
            .frame(width: 130, height: 200)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)

            Text("Số lần chạm: \(tapCount)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Toggle("Treo chậu (Hanging)", isOn: $isHanging)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    Pot19InteractiveDemoView()
}

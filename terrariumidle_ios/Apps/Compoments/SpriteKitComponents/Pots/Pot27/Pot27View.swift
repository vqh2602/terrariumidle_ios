//
//  Pot27View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 27: "Chậu sứ trắng ngà dáng cao" (pot27)
public struct Pot27View: View {
    /// Độ giãn phủ chiều rộng mặc định của Chậu 27 (0.0 -> 1.0)
    public static var defaultWidthFill: CGFloat = 0.2

    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = Pot27View.defaultWidthFill
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill }
        set { widthFill = newValue }
    }

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 95,
        widthFill: CGFloat = Pot27View.defaultWidthFill,
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
            potId: "pot27",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
        .id("pot27-\(isHanging)-\(widthFill)-\(width)-\(height)")
    }
}

// MARK: - Interactive Preview Struct
private struct Pot27InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var widthFill: CGFloat = Pot27View.defaultWidthFill
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 27 SpriteKit")
                .font(.title2).bold()

            Text("Chậu sứ trắng ngà dáng cao thanh thoát 🤍")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot27View(
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 120,
                    widthFill: widthFill,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
                .id("\(isHanging)-\(widthFill)")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Độ rộng (widthFill):")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(widthFill * 100))%")
                        .font(.caption).bold()
                }
                Slider(value: $widthFill, in: 0.0...1.0, step: 0.05)
            }
            .padding(.horizontal, 30)

            Text("Đã chạm: \(tapCount) lần")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                widthFill = Pot27View.defaultWidthFill
            }) {
                Text("Đặt lại độ rộng mặc định")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    Pot27InteractiveDemoView()
}

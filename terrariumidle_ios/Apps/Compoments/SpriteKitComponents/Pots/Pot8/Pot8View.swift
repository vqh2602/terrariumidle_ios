//
//  Pot8View.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 8: "Chậu đan giỏ tre" (pot8)
/// - Tái sử dụng SpriteKitPotView (PotView) để tránh lặp lại code SpriteView và quản lý Scene lifecycle
/// - Chất liệu đan từ tre nứa nhẹ nhàng, thanh thoát + phản hồi nén nảy tự nhiên
public struct Pot8View: View {
    /// Độ giãn phủ chiều rộng mặc định của Chậu 8 (0.0 -> 1.0)
    public static var defaultWidthFill: CGFloat = 0.0

    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = Pot8View.defaultWidthFill
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
        widthFill: CGFloat = Pot8View.defaultWidthFill,
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
            potId: "pot8",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot8InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 8 SpriteKit")
                .font(.title2).bold()

            Text("Chậu đan giỏ tre - Nhẹ nhàng & tinh tế 🎋")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot8View(
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 120,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
            }

            Text("Đã chạm: \(tapCount) lần")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        isHanging.toggle()
                    }
                }) {
                    Label(
                        isHanging ? "Chuyển chậu để bàn" : "Chuyển chậu treo",
                        systemImage: isHanging ? "table.furniture" : "arrow.up.and.down"
                    )
                    .font(.subheadline).bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

#Preview("Pot8 - Chậu đan giỏ tre") {
    Pot8InteractiveDemoView()
}

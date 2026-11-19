//
//  Pot1View.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 1: "Chậu hồng chấm đỏ" (pot1)
/// - Tái sử dụng SpriteKitPotView (PotView) để tránh lặp lại code SpriteView và quản lý Scene lifecycle
/// - Hiệu ứng đặc trưng "Đá lấp lánh" (Sparkle Twinkle & Burst) + phản hồi tương tác Tap đàn hồi
public struct Pot1View: View {
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = 0.0
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill }
        set { widthFill = newValue }
    }

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 85,
        widthFill: CGFloat = 0.0,
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
            potId: "pot1",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot1InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 1 SpriteKit")
                .font(.title2).bold()

            Text("Chậu hồng chấm đỏ - Hiệu ứng: Đá lấp lánh ✨")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot1View(
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 110,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
                .id(isHanging)
            }
            .padding()

            Text("Số lần chạm: \(tapCount)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button(action: { isHanging = false }) {
                    Label("Chậu để bàn", systemImage: "table.furniture")
                }
                .buttonStyle(.borderedProminent)
                .tint(isHanging ? .gray : .pink)

                Button(action: { isHanging = true }) {
                    Label("Chậu treo", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(isHanging ? .pink : .gray)
            }
        }
        .padding()
    }
}

#Preview {
    Pot1InteractiveDemoView()
}

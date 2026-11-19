//
//  Pot4View.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 4: "Chậu trái tim trắng" (pot4)
/// - Tái sử dụng SpriteKitPotView (PotView) để tránh lặp lại code SpriteView và quản lý Scene lifecycle
/// - Hiệu ứng đặc trưng "Trái tim nhịp đập" (Heartbeat pulse & floating hearts) + phản hồi tương tác Tap đàn hồi
public struct Pot4View: View {
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
            potId: "pot4",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot4InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 4 SpriteKit")
                .font(.title2).bold()

            Text("Chậu trái tim trắng - Hiệu ứng: Trái tim nhịp đập 💖")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot4View(
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
    Pot4InteractiveDemoView()
}

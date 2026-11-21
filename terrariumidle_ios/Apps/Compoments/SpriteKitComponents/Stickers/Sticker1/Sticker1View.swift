//
//  Sticker1View.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sticker 1: "Sunshine doll" (Búp bê cầu nắng - sticker1)
/// - Búp bê treo dây tự động đung đưa nhàn rỗi theo làn gió tự nhiên
/// - Khi click: Mặt trời vàng rực rỡ tỏa sáng kèm các tia nắng xoay tròn ấm áp và bụi sao lấp lánh
public struct Sticker1View: View {
    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 180,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        StickerView(
            stickerId: "sticker1",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Sticker1InteractiveDemoView: View {
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("☀️ Sunshine Doll - Búp Bê Cầu Nắng")
                    .font(.title3).bold()

                Text("Tự đung đưa theo gió 🍃 • Chạm vào để Mặt Trời tỏa sáng ☀️")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 280)

                Sticker1View(
                    isHanging: true,
                    width: 140,
                    height: 250,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, 12)
            }

            VStack(spacing: 8) {
                Text("Đã chạm: \(tapCount) lần")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("✨ Chạm trực tiếp vào búp bê hoặc khung hình để ngắm mặt trời tỏa sáng rạng rỡ")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding()
    }
}

#Preview {
    Sticker1InteractiveDemoView()
}

//
//  Sticker2View.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sticker 2: "Mèo thần tài" (Maneki-neko - sticker2)
/// - Hoạt ảnh chú mèo thần tài vẫy tay mời gọi tài lộc & may mắn
/// - Khi click: Mưa đồng xu vàng Koban óng ánh bung tỏa 360°, vầng hào quang tài lộc ấm áp
///   kết hợp thân mèo nhún nảy đàn hồi và vẫy tay nhanh mừng rỡ
public struct Sticker2View: View {
    /// Tỉ lệ kích thước hiển thị mặc định so với chiều cao ô kệ (fitRatio: 0.3 ... 1.0)
    /// - Muốn sticker to hơn: tăng số này lên (ví dụ 0.72 -> 0.80)
    /// - Muốn sticker nhỏ lại: giảm số này xuống (ví dụ 0.72 -> 0.60)
    public static var defaultFitRatio: CGFloat = 0.72

    public var isHanging: Bool = false
    public var width: CGFloat = 135
    public var height: CGFloat = 135
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 135,
        height: CGFloat = 135,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        StickerView(
            stickerId: "sticker2",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Demo

private struct Sticker2InteractiveDemoView: View {
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.14)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Sticker 2: Mèo Thần Tài")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Maneki-neko • Vẫy tay gọi tài lộc • Mưa tiền vàng Koban")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Khung hiển thị Sticker2
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(width: 170, height: 170)

                    Sticker2View(
                        isHanging: false,
                        width: 150,
                        height: 150,
                        onTap: {
                            tapCount += 1
                        }
                    )
                }

                Text("Số lần nhận may mắn: \(tapCount)")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.20))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)

                Text("Chạm vào chú mèo để nhận mưa đồng xu vàng may mắn!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
        }
    }
}

#Preview {
    Sticker2InteractiveDemoView()
}

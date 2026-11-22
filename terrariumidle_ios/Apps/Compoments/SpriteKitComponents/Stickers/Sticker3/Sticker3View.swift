//
//  Sticker3View.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sticker 3: "Đèn cá chép" (Koi Windsock Lantern - sticker3)
/// - Đèn lồng cá chép đu đưa trong gió lúc mạnh lúc nhẹ uốn lượn
/// - Khi click: Hiệu ứng chùm sao lấp lánh tam sắc Xanh dương, Đỏ, Vàng chuẩn màu 3 chú cá
///   kết hợp dao động con lắc đàn hồi
public struct Sticker3View: View {
    /// Tỉ lệ kích thước hiển thị mặc định so với chiều cao ô kệ (fitRatio: 0.3 ... 1.0)
    /// - Muốn sticker to hơn: tăng số này lên (ví dụ 0.64 -> 0.72)
    /// - Muốn sticker nhỏ lại: giảm số này xuống (ví dụ 0.64 -> 0.55)
    public static var defaultFitRatio: CGFloat = 0.64

    public var isHanging: Bool = false
    public var width: CGFloat = 130
    public var height: CGFloat = 185
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 130,
        height: CGFloat = 185,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        StickerView(
            stickerId: "sticker3",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Demo

private struct Sticker3InteractiveDemoView: View {
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.15, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Sticker 3: Đèn Cá Chép")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Koi Windsock • Gió lúc mạnh lúc nhẹ • Lấp lánh Xanh - Đỏ - Vàng")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Khung hiển thị Sticker3
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(width: 170, height: 220)

                    Sticker3View(
                        isHanging: true,
                        width: 140,
                        height: 200,
                        onTap: {
                            tapCount += 1
                        }
                    )
                }

                Text("Số lần chạm đèn cá: \(tapCount)")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.40, green: 0.80, blue: 1.0))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)

                Text("Chạm vào đèn cá để kích hoạt hiệu ứng lấp lánh tam sắc!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
        }
    }
}

#Preview {
    Sticker3InteractiveDemoView()
}

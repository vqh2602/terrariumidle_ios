//
//  Sticker4View.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Sticker 4: "Đèn thắp sáng" (Candle Lantern - sticker4)
/// - Đèn lồng kim loại cổ kính đu đưa êm dịu theo gió, ngọn nến bên trong bập bùng ấm cúng
/// - Khi click: Vầng hào quang ánh nến ấm áp bung tỏa rạng ngời, tim nến bừng sáng rực rỡ
///   và các đốm tàn tro lửa nến bay bổng nhẹ nhàng lên không trung
public struct Sticker4View: View {
    /// Tỉ lệ kích thước hiển thị mặc định so với chiều cao ô kệ (fitRatio: 0.3 ... 1.0)
    /// - Muốn sticker to hơn: tăng số này lên (ví dụ 0.52 -> 0.60)
    /// - Muốn sticker nhỏ lại: giảm số này xuống (ví dụ 0.52 -> 0.44)
    public static var defaultFitRatio: CGFloat = 0.52

    public var isHanging: Bool = false
    public var width: CGFloat = 125
    public var height: CGFloat = 185
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 125,
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
            stickerId: "sticker4",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Demo

private struct Sticker4InteractiveDemoView: View {
    @State private var tapCount: Int = 0

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.12, blue: 0.14)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("Sticker 4: Đèn Thắp Sáng")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Candle Lantern • Nến bập bùng • Hào quang ấm áp & Tàn lửa bay")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Khung hiển thị Sticker4
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .frame(width: 170, height: 220)

                    Sticker4View(
                        isHanging: false,
                        width: 135,
                        height: 195,
                        onTap: {
                            tapCount += 1
                        }
                    )
                }

                Text("Số lần thắp sáng: \(tapCount)")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.25))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)

                Text("Chạm vào lồng đèn để bừng sáng ánh lửa nến ấm áp!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
        }
    }
}

#Preview {
    Sticker4InteractiveDemoView()
}

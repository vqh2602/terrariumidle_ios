//
//  CurtainLoadingOverlay.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// Màn hình loading hiệu ứng kéo rèm (Theatrical / Window Curtain Reveal)
/// Khi tải xong dữ liệu, 2 cánh rèm vải xếp nếp sẽ tự động tách mở từ giữa sang hai bên,
/// hé lộ toàn cảnh khu vườn Terrarium tuyệt đẹp bên dưới.
struct CurtainLoadingOverlay: View {
    let isLoading: Bool
    let loadFailed: Bool
    let onRetry: () -> Void

    @State private var isCurtainOpen: Bool = false
    @State private var isContentFaded: Bool = false
    @State private var isDismissed: Bool = false
    @State private var isPulsing: Bool = false

    var body: some View {
        if !isDismissed {
            GeometryReader { geo in
                let halfWidth = geo.size.width / 2.0
                let totalHeight = geo.size.height

                ZStack {
                    // MARK: - Cánh rèm bên trái (Left Curtain Panel)
                    CurtainPanel(isLeft: true, width: halfWidth + 4, height: totalHeight)
                        .scaleEffect(x: isCurtainOpen ? 0.80 : 1.0, y: 1.0, anchor: .leading)
                        .offset(x: isCurtainOpen ? -(halfWidth + 35) : 0)
                        .frame(width: halfWidth + 4, height: totalHeight)
                        .position(x: (halfWidth + 4) / 2, y: totalHeight / 2)

                    // MARK: - Cánh rèm bên phải (Right Curtain Panel)
                    CurtainPanel(isLeft: false, width: halfWidth + 4, height: totalHeight)
                        .scaleEffect(x: isCurtainOpen ? 0.80 : 1.0, y: 1.0, anchor: .trailing)
                        .offset(x: isCurtainOpen ? (halfWidth + 35) : 0)
                        .frame(width: halfWidth + 4, height: totalHeight)
                        .position(x: geo.size.width - (halfWidth + 4) / 2, y: totalHeight / 2)

                    // MARK: - Nội dung loading ở chính giữa rèm
                    if !isContentFaded {
                        VStack(spacing: 16) {
                            // Biểu tượng chiếc lá thở nhẹ nhàng khi chờ
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 42))
                                .foregroundStyle(AccountStyle.green)
                                .shadow(color: AccountStyle.green.opacity(0.25), radius: 8, y: 4)
                                .scaleEffect(isPulsing ? 1.06 : 0.94)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

                            if loadFailed {
                                VStack(spacing: 8) {
                                    Text("Chưa tải được khu vườn")
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(AccountStyle.ink)

                                    Button(action: onRetry) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Thử lại")
                                        }
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundColor(AccountStyle.cream)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(AccountStyle.green, in: Capsule())
                                        .shadow(color: AccountStyle.green.opacity(0.3), radius: 4, y: 2)
                                    }
                                }
                            } else {
                                ProgressView("Đang chuẩn bị khu vườn…")
                                    .tint(AccountStyle.green)
                                    .foregroundStyle(AccountStyle.muted)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                            }
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AccountStyle.cream.opacity(0.85))
                                .shadow(color: Color(hex: "57432E").opacity(0.08), radius: 12, y: 4)
                        )
                        .transition(.scale(scale: 0.88).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .allowsHitTesting(!isCurtainOpen)
            .onAppear {
                isPulsing = true
                if !isLoading && !loadFailed {
                    openCurtain()
                }
            }
            .onChange(of: isLoading) { _, loading in
                if !loading && !loadFailed {
                    openCurtain()
                } else if loading {
                    // Reset trạng thái nếu cần load lại
                    isCurtainOpen = false
                    isContentFaded = false
                    isDismissed = false
                }
            }
        }
    }

    // MARK: - Logic hiệu ứng kéo rèm mở ra hai bên
    private func openCurtain() {
        // Bước 1: Thu nhỏ & mờ dần khối text loading ở giữa
        withAnimation(.easeOut(duration: 0.22)) {
            isContentFaded = true
        }

        // Bước 2: Bắt đầu kéo 2 cánh rèm trượt dạt sang hai mép màn hình
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.timingCurve(0.22, 0.9, 0.25, 1.0, duration: 0.85)) {
                isCurtainOpen = true
            }
        }

        // Bước 3: Huỷ bỏ overlay hoàn toàn khỏi view hierarchy để tối ưu 100% hiệu năng
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.02) {
            isDismissed = true
        }
    }
}

// MARK: - Cánh rèm vải (Curtain Panel với nếp gấp vải và viền bóng đổ 3D)
private struct CurtainPanel: View {
    let isLeft: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: isLeft ? .trailing : .leading) {
            // Nền rèm với dải chuyển màu tạo nếp gấp vải lanh ấm cúng (Linen cloth pleats)
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "FFFDF6"), location: 0.0),
                    .init(color: Color(hex: "F8F0D6"), location: 0.14),
                    .init(color: Color(hex: "FFFDF6"), location: 0.28),
                    .init(color: Color(hex: "F7EED3"), location: 0.42),
                    .init(color: Color(hex: "FFFDF6"), location: 0.56),
                    .init(color: Color(hex: "F7EED3"), location: 0.70),
                    .init(color: Color(hex: "FFFDF6"), location: 0.84),
                    .init(color: Color(hex: "EFE1BE"), location: 1.0)
                ],
                startPoint: isLeft ? .leading : .trailing,
                endPoint: isLeft ? .trailing : .leading
            )

            // Ánh bóng đổ 3D dọc mép rèm để tạo cảm giác 2 tà rèm xếp chồng lên nhau
            LinearGradient(
                colors: [
                    Color(hex: "57432E").opacity(0.18),
                    Color(hex: "57432E").opacity(0.05),
                    Color.clear
                ],
                startPoint: isLeft ? .trailing : .leading,
                endPoint: isLeft ? .leading : .trailing
            )
            .frame(width: 20)

            // Đường viền may tinh tế ở mép rèm giáp nhau
            Rectangle()
                .fill(AccountStyle.border.opacity(0.8))
                .frame(width: 2)
        }
        .frame(width: width, height: height)
        .clipped()
        .shadow(
            color: Color(hex: "57432E").opacity(0.22),
            radius: 8,
            x: isLeft ? 5 : -5,
            y: 0
        )
    }
}

#Preview {
    ZStack {
        // Giả lập khu vườn bên dưới
        Color.green.opacity(0.3).ignoresSafeArea()
        Text("🌿 Khu Vườn Terrarium")
            .font(.title)

        CurtainLoadingOverlay(
            isLoading: false,
            loadFailed: false,
            onRetry: {}
        )
    }
}

//
//  CurtainLoadingOverlay.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// Màn hình loading hiệu ứng kéo rèm (Split Curtain Reveal)
/// Giữ nguyên nền màu kem phẳng (AccountStyle.cream) nguyên bản, không vẽ thêm sọc/nếp gấp.
/// Khi tải xong dữ liệu, 2 cánh rèm phẳng sẽ tự động trượt mở sang 2 bên để lộ khu vườn.
struct CurtainLoadingOverlay: View {
    let isLoading: Bool
    let loadFailed: Bool
    let onRetry: () -> Void

    @State private var isCurtainOpen: Bool = false
    @State private var isContentFaded: Bool = false
    @State private var isDismissed: Bool = false

    var body: some View {
        if !isDismissed {
            GeometryReader { geo in
                let halfWidth = geo.size.width / 2.0
                let totalHeight = geo.size.height

                ZStack {
                    // MARK: - Cánh rèm bên trái (Nền kem phẳng như cũ)
                    AccountStyle.cream
                        .frame(width: halfWidth + 2, height: totalHeight)
                        .offset(x: isCurtainOpen ? -(halfWidth + 10) : 0)
                        .position(x: (halfWidth + 2) / 2, y: totalHeight / 2)

                    // MARK: - Cánh rèm bên phải (Nền kem phẳng như cũ)
                    AccountStyle.cream
                        .frame(width: halfWidth + 2, height: totalHeight)
                        .offset(x: isCurtainOpen ? (halfWidth + 10) : 0)
                        .position(x: geo.size.width - (halfWidth + 2) / 2, y: totalHeight / 2)

                    // MARK: - Nội dung loading nguyên bản như cũ (Không thêm khung viền hay sọc)
                    if !isContentFaded {
                        VStack(spacing: 14) {
                            Image(systemName: "leaf.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AccountStyle.green)

                            if loadFailed {
                                Text("Chưa tải được khu vườn")
                                    .foregroundStyle(AccountStyle.ink)
                                Button("Thử lại") {
                                    onRetry()
                                }
                                .tint(AccountStyle.green)
                            } else {
                                ProgressView("Đang chuẩn bị khu vườn…")
                                    .tint(AccountStyle.green)
                            }
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
            .allowsHitTesting(!isCurtainOpen)
            .onAppear {
                if !isLoading && !loadFailed {
                    openCurtain()
                }
            }
            .onChange(of: isLoading) { _, loading in
                if !loading && !loadFailed {
                    openCurtain()
                } else if loading {
                    // Reset nếu cần load lại
                    isCurtainOpen = false
                    isContentFaded = false
                    isDismissed = false
                }
            }
        }
    }

    // MARK: - Animation kéo rèm tách sang hai bên
    private func openCurtain() {
        // Bước 1: Mờ dần chữ & icon loading ở giữa
        withAnimation(.easeOut(duration: 0.2)) {
            isContentFaded = true
        }

        // Bước 2: Kéo 2 cánh rèm trượt dạt sang hai bên
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.timingCurve(0.22, 0.9, 0.25, 1.0, duration: 0.8)) {
                isCurtainOpen = true
            }
        }

        // Bước 3: Thu hồi overlay hoàn toàn khỏi view hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            isDismissed = true
        }
    }
}

#Preview {
    ZStack {
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

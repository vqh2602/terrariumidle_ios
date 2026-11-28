//
//  SplashView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 4/2/26.
//

import SwiftUI
import UIKit

struct SplashView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var splashViewModel: SplashViewModel
    @ObservedObject private var appIconManager = AppIconManager.shared

    init(router: AppRouter, auth: AuthService = .shared) {
        self.router = router
        _splashViewModel = StateObject(wrappedValue: SplashViewModel(auth: auth, router: router))
    }

    private var backgroundPalette: SplashBackgroundPalette {
        SplashBackgroundPalette.palette(for: appIconManager.currentSplashImageName)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [backgroundPalette.topColor, backgroundPalette.bottomColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image(appIconManager.currentSplashImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .mask(edgeFeatherMask)
                .padding(20)
        }
        .animation(.easeInOut(duration: 0.25), value: appIconManager.currentSplashImageName)
        .onAppear {
            Task {
                await splashViewModel.checkAuthAndNavigate()
            }
        }
    }

    /// Làm mờ nhẹ 4 cạnh logo để mép ảnh hòa quyện liền mạch vào màu nền tự động.
    private var edgeFeatherMask: some View {
        Rectangle()
            .fill(Color.black)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

/// Trích xuất và lưu cache màu nền trên/dưới từ chính viền của ảnh logo hiện tại.
private struct SplashBackgroundPalette {
    let topColor: Color
    let bottomColor: Color

    private static var cache: [String: SplashBackgroundPalette] = [:]

    static func palette(for imageName: String) -> SplashBackgroundPalette {
        if let cached = cache[imageName] {
            return cached
        }
        let extracted = extract(from: imageName)
        cache[imageName] = extracted
        return extracted
    }

    private static func extract(from imageName: String) -> SplashBackgroundPalette {
        let fallback = SplashBackgroundPalette(
            topColor: AppColors.backgroundLogin,
            bottomColor: AppColors.backgroundLogin
        )

        guard let image = UIImage(named: imageName),
              let cgImage = image.cgImage else {
            return fallback
        }

        let sampleSize = 32
        let bytesPerPixel = 4
        let bytesPerRow = sampleSize * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: sampleSize * sampleSize * bytesPerPixel)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: &pixels,
                width: sampleSize,
                height: sampleSize,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return fallback
        }

        // Lật trục Y để row 0 luôn tương ứng với mép trên của logo
        context.translateBy(x: 0, y: CGFloat(sampleSize))
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleSize, height: sampleSize))

        let top = averageColor(in: pixels, sampleSize: sampleSize, rows: 0..<2)
        let bottom = averageColor(in: pixels, sampleSize: sampleSize, rows: (sampleSize - 2)..<sampleSize)

        return SplashBackgroundPalette(
            topColor: top ?? AppColors.backgroundLogin,
            bottomColor: bottom ?? top ?? AppColors.backgroundLogin
        )
    }

    private static func averageColor(in pixels: [UInt8], sampleSize: Int, rows: Range<Int>) -> Color? {
        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0
        var count: Double = 0

        for y in rows {
            for x in 0..<sampleSize {
                let offset = (y * sampleSize + x) * 4
                let a = Double(pixels[offset + 3]) / 255.0
                guard a > 0.5 else { continue }
                // Khử premultiplied alpha để giữ đúng sắc độ gốc
                totalR += min(1.0, (Double(pixels[offset]) / 255.0) / a)
                totalG += min(1.0, (Double(pixels[offset + 1]) / 255.0) / a)
                totalB += min(1.0, (Double(pixels[offset + 2]) / 255.0) / a)
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return Color(
            .sRGB,
            red: totalR / count,
            green: totalG / count,
            blue: totalB / count,
            opacity: 1.0
        )
    }
}

#Preview {
    SplashView(router: AppRouter())
}

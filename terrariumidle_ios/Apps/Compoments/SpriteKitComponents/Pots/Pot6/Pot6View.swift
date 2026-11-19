//
//  Pot6View.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 6: "Chậu tam thạch anh hồng" (pot6)
/// - Tái sử dụng SpriteKitPotView (PotView) để tránh lặp lại code SpriteView và quản lý Scene lifecycle
/// - Hiệu ứng đặc trưng "Tam thạch anh hồng" (Rose quartz crystals glow & crystal burst)
public struct Pot6View: View {
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 85,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        PotView(
            potId: "pot6",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot6InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 6 SpriteKit")
                .font(.title2).bold()

            Text("Chậu tam thạch anh hồng - Hiệu ứng: Tam thạch anh hồng 💎")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot6View(
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
    Pot6InteractiveDemoView()
}

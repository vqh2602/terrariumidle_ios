//
//  Pot17View.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 17: "Chậu đất treo" (pot17)
/// - Chậu treo phân lớp (Layered Hanging Pot - `hanging,front`)
public struct Pot17View: View {
    /// Độ giãn phủ chiều rộng mặc định của Chậu 17 (0.0 -> 1.0)
    public static var defaultWidthFill: CGFloat = 0.0

    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = Pot17View.defaultWidthFill
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill }
        set { widthFill = newValue }
    }

    public init(
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 180,
        widthFill: CGFloat = Pot17View.defaultWidthFill,
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
            potId: "pot17",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot17InteractiveDemoView: View {
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 17 SpriteKit")
                .font(.title2).bold()

            Text("Chậu đất treo - Chậu treo phân lớp mộc mạc 🪴")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Pot17View(
                    isHanging: true,
                    width: 160,
                    height: 220,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, 16)
            }

            Text("Đã chạm: \(tapCount) lần (chạm để đu đưa chậu)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    Pot17InteractiveDemoView()
}

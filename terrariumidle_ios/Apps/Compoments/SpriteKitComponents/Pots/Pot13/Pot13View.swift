//
//  Pot13View.swift
//  terrariumidle_ios
//
//  Created by AI on 19/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu 13: "Chậu đất nung chấm bi" (pot13)
public struct Pot13View: View {
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 95,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        PotView(
            potId: "pot13",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview Struct
private struct Pot13InteractiveDemoView: View {
    @State private var isHanging: Bool = false
    @State private var tapCount: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("🪴 Demo Pot 13 SpriteKit")
                .font(.title2).bold()

            Text("Chậu đất nung chấm bi - Duyên dáng & mộc mạc 🤎")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot13View(
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 120,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
            }

            Text("Đã chạm: \(tapCount) lần")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        isHanging.toggle()
                    }
                }) {
                    Label(
                        isHanging ? "Chuyển chậu để bàn" : "Chuyển chậu treo",
                        systemImage: isHanging ? "table.furniture" : "arrow.up.and.down"
                    )
                    .font(.subheadline).bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}

#Preview("Pot13 - Chậu đất nung chấm bi") {
    Pot13InteractiveDemoView()
}

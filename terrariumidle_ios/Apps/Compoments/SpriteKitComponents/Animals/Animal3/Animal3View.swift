//
//  Animal3View.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Animal 3: Túi lưới bắt sâu (`animal3` / `"Bugsnet"`)
/// - Treo từ đỉnh kệ (`hanging,front`), click vào túi sẽ có hiệu ứng giãn nở túi đựng
/// - Hiển thị trực tiếp hình ảnh sâu (`bug1`) và châu chấu (`grasshopper`) đã bắt bên trong túi (tối đa 5 con)
public struct Animal3View: View {
    public static var defaultFitRatio: CGFloat = 0.72

    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var capturedPests: [PestSpecies] = []
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 220,
        capturedPests: [PestSpecies] = [],
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.capturedPests = capturedPests
        self.onTap = onTap
    }

    public var body: some View {
        AnimalView(
            animalId: "animal3",
            isHanging: isHanging,
            width: width,
            height: height,
            capturedPests: capturedPests,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview

private struct Animal3InteractiveDemoView: View {
    @State private var caught: [PestSpecies] = [.bug1, .grasshopper, .bug1]
    @State private var tapCount = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("🕸️ Bugsnet · Túi bắt sâu (\(caught.count)/5)")
                .font(.headline)
            Text("Chạm vào túi để giãn nở túi đựng • Lần chạm: \(tapCount)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Animal3View(
                isHanging: true,
                width: 140,
                height: 270,
                capturedPests: caught,
                onTap: { tapCount += 1 }
            )
            .frame(width: 160, height: 280)
            .background(Color(hex: "E9EED9"), in: RoundedRectangle(cornerRadius: 18))

            HStack(spacing: 12) {
                Button("+ Sâu") {
                    if caught.count < 5 { caught.append(.bug1) }
                }
                .buttonStyle(.borderedProminent)

                Button("+ Châu chấu") {
                    if caught.count < 5 { caught.append(.grasshopper) }
                }
                .buttonStyle(.borderedProminent)

                Button("Làm trống") {
                    caught.removeAll()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    Animal3InteractiveDemoView()
}

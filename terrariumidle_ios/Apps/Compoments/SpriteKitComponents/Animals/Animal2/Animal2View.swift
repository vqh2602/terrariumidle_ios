//
//  Animal2View.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Animal 2: Gốc Cây Gỗ Mục & Bọ Rùa (`animal2` / `"lazybug"`)
/// - Hiển thị gốc cây gỗ mục đặt trên kệ (`front`, `isHanging = false`)
/// - Khi chạm vào gốc cây: rơi mảnh vỏ gỗ ra ngoài; nếu bọ rùa đang ở ngoài sẽ bay về tổ
/// - Duy nhất 1 chú bọ rùa: nghỉ (`idle`) hoặc ngủ (`sleep`) trên gốc gỗ mục, bay chậm (`fly`) sang cây, bò trên lá (`move`), quay trái/phải, và giật mình bay trốn ~5s khi bị chạm
public struct Animal2View: View {
    public static var defaultFitRatio: CGFloat = 0.92

    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 220,
        onTap: (() -> Void)? = nil
    ) {
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        AnimalView(
            animalId: "animal2",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview

private struct Animal2InteractiveDemoView: View {
    @StateObject private var coordinator = GardenBeeSwarmCoordinator()
    @State private var tapCount = 0

    var body: some View {
        GeometryReader { geo in
            let itemW = (geo.size.width - 32) / 3.0
            let slotH = itemW * 1.95
            let _ = {
                coordinator.layout.viewportSize = geo.size
                coordinator.layout.slotSize = CGSize(width: itemW, height: slotH)
                coordinator.layout.shelfOffset = 0
            }()

            ZStack {
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("🐞 Gốc Gỗ Mục & Chú Bọ Rùa")
                        .font(.headline)
                    Text("Tap gốc gỗ mục để rơi vỏ cây & gọi bọ rùa về • Tap bọ rùa đang ở ngoài để giật mình trốn 5s! (\(tapCount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    HStack(spacing: 4) {
                        Animal2View(isHanging: false, width: itemW, height: slotH) {
                            tapCount += 1
                            coordinator.notifyAnimalTapped(animalId: "animal2")
                        }

                        SpriteKitPlantView(plantId: "plant1", plantLevel: 3, isHanging: false, width: itemW, height: slotH)
                            .frame(width: itemW, height: slotH, alignment: .bottom)

                        SpriteKitPlantView(plantId: "plant2", plantLevel: 3, isHanging: false, width: itemW, height: slotH)
                            .frame(width: itemW, height: slotH, alignment: .bottom)
                    }
                    .frame(height: slotH)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("previewLadybugGarden")) } action: { rect in
                        coordinator.layout.calibrate(row: 1, viewportMinY: rect.minY)
                    }

                    Rectangle()
                        .fill(Color.brown.opacity(0.6))
                        .frame(height: 16)
                        .padding(.horizontal, 16)

                    Spacer()
                }

                GardenAnimalOverlayView(coordinator: coordinator, viewportSize: geo.size)
            }
            .coordinateSpace(name: "previewLadybugGarden")
            .onAppear {
                coordinator.syncGarden(
                    hivePosition: nil,
                    ladybugHomePosition: "1,1",
                    plantTargets: [
                        BeePlantTarget(positionKey: "1,2", row: 1, column: 2, isHanging: false),
                        BeePlantTarget(positionKey: "1,3", row: 1, column: 3, isHanging: false)
                    ],
                    userFloors: 1,
                    animalId: "animal2"
                )
            }
        }
    }
}

#Preview {
    Animal2InteractiveDemoView()
}

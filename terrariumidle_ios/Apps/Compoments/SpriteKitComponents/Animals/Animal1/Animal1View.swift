//
//  Animal1View.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Animal 1: Tổ Ong Mật (`animal1` / `"bee"`)
/// - Hiển thị tổ ong treo trên cành cây (`hanging,front`)
/// - Khi chạm vào tổ: hiệu ứng mật ong bắn ra & nếu không có ong nào đang bay sẽ thả 1 chú ong đi lấy mật
/// - 4 chú ong (`bee1`..`bee4`) thỉnh thoảng bay ra ngẫu nhiên (1..4 con, lần lượt hoặc hàng loạt) đến cây lấy mật rồi bay về
public struct Animal1View: View {
    public static var defaultFitRatio: CGFloat = 0.62

    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    public init(
        isHanging: Bool = true,
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
            animalId: "animal1",
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
    }
}

// MARK: - Interactive Preview

private struct Animal1InteractiveDemoView: View {
    @StateObject private var swarm = GardenBeeSwarmCoordinator()
    @State private var tapCount = 0

    var body: some View {
        GeometryReader { geo in
            let itemW = (geo.size.width - 32) / 3.0
            let slotH = itemW * 1.95
            let _ = {
                swarm.layout.viewportSize = geo.size
                swarm.layout.slotSize = CGSize(width: itemW, height: slotH)
                swarm.layout.shelfOffset = 0
            }()

            ZStack {
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("🐝 Tổ Ong & Đàn Ong 4 Con")
                        .font(.headline)
                    Text("Tap tổ ong để bắn mật & thả ong • Tap chú ong đang bay để làm ong giật mình! (\(tapCount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()

                    HStack(spacing: 4) {
                        Animal1View(isHanging: true, width: itemW, height: slotH) {
                            tapCount += 1
                            swarm.notifyHiveTapped()
                        }

                        SpriteKitPlantView(plantId: "plant1", plantLevel: 3, isHanging: false, width: itemW, height: slotH)
                            .frame(width: itemW, height: slotH, alignment: .bottom)

                        SpriteKitPlantView(plantId: "plant2", plantLevel: 3, isHanging: false, width: itemW, height: slotH)
                            .frame(width: itemW, height: slotH, alignment: .bottom)
                    }
                    .frame(height: slotH)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("previewGarden")) } action: { rect in
                        swarm.layout.calibrate(row: 1, viewportMinY: rect.minY)
                    }

                    Rectangle()
                        .fill(Color.brown.opacity(0.6))
                        .frame(height: 16)
                        .padding(.horizontal, 16)

                    Spacer()
                }

                GardenAnimalOverlayView(coordinator: swarm, viewportSize: geo.size)
            }
            .coordinateSpace(name: "previewGarden")
            .onAppear {
                swarm.syncGarden(
                    hivePosition: "1,1",
                    plantTargets: [
                        BeePlantTarget(positionKey: "1,2", row: 1, column: 2, isHanging: false),
                        BeePlantTarget(positionKey: "1,3", row: 1, column: 3, isHanging: false)
                    ],
                    userFloors: 1,
                    animalId: "animal1"
                )
            }
        }
    }
}

#Preview {
    Animal1InteractiveDemoView()
}

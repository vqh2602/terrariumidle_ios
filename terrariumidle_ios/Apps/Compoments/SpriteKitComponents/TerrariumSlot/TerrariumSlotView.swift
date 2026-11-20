//
//  TerrariumSlotView.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component Hợp Nhất (Unified Slot View)
/// Hiển thị đồng thời cả Cây và Chậu trong một SpriteKit Scene duy nhất
/// - Đan xen chiều sâu (Lá rủ qua mặt trước chậu, dây treo trước vắt qua lá)
/// - Không còn hiện tượng lệch toạ độ hay trôi vị trí ở chậu treo
/// - Tối ưu 50% số lượng SKView trên màn hình chính
public struct TerrariumSlotView: View {

    // MARK: - Properties

    public var potId: String = "pot1"
    public var plantId: String = "plant1"
    public var plantLevel: Int = 1
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat? = nil
    public var onTap: (() -> Void)? = nil

    @State private var currentScene: TerrariumSlotScene? = nil

    // MARK: - Initializer

    public init(
        potId: String = "pot1",
        plantId: String = "plant1",
        plantLevel: Int = 1,
        isHanging: Bool = false,
        width: CGFloat,
        height: CGFloat,
        widthFill: CGFloat? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.plantId = plantId
        self.plantLevel = plantLevel
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.widthFill = widthFill
        self.onTap = onTap

        let activeFill = widthFill ?? PotRegistry.defaultWidthFill(for: potId)
        let initialScene = Self.makeScene(
            potId: potId,
            plantId: plantId,
            level: plantLevel,
            isHanging: isHanging,
            widthFill: activeFill,
            width: width,
            height: height,
            onTap: onTap
        )
        _currentScene = State(initialValue: initialScene)
    }

    // MARK: - Body

    public var body: some View {
        let activeFill = widthFill ?? PotRegistry.defaultWidthFill(for: potId)

        let scene = currentScene ?? Self.makeScene(
            potId: potId,
            plantId: plantId,
            level: plantLevel,
            isHanging: isHanging,
            widthFill: activeFill,
            width: width,
            height: height,
            onTap: onTap
        )

        // Cấu hình đồng bộ trong render pass
        scene.configure(
            potId: potId,
            plantId: plantId,
            plantLevel: plantLevel,
            isHanging: isHanging,
            widthFill: activeFill,
            onTap: onTap
        )

        return SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .id("slot-\(potId)-\(plantId)-\(plantLevel)-\(isHanging)-\(activeFill)-\(width)-\(height)")
            .onAppear {
                if currentScene == nil {
                    currentScene = scene
                }
            }
    }

    // MARK: - Helper

    private static func makeScene(
        potId: String,
        plantId: String,
        level: Int,
        isHanging: Bool,
        widthFill: CGFloat,
        width: CGFloat,
        height: CGFloat,
        onTap: (() -> Void)?
    ) -> TerrariumSlotScene {
        let newScene = TerrariumSlotScene(size: CGSize(width: width, height: height))
        newScene.configure(
            potId: potId,
            plantId: plantId,
            plantLevel: level,
            isHanging: isHanging,
            widthFill: widthFill,
            onTap: onTap
        )
        return newScene
    }
}

// MARK: - Interactive Preview

#Preview("Terrarium Slot - Preview Đan Xen Chiều Sâu") {
    struct SlotInteractivePreview: View {
        @State private var potId: String = "pot1"
        @State private var plantId: String = "plant1"
        @State private var level: Int = 3
        @State private var isHanging: Bool = false
        @State private var widthFill: CGFloat = 0.0

        let plants = (1...14).map { "plant\($0)" }
        let pots = (1...14).map { "pot\($0)" }

        var body: some View {
            VStack(spacing: 20) {
                Text("Terrarium Unified Slot")
                    .font(.title2.bold())

                // Khu vực hiển thị mô phỏng kệ cây
                ZStack(alignment: isHanging ? .top : .bottom) {
                    // Mặt kệ gỗ mô phỏng
                    if !isHanging {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.65, green: 0.45, blue: 0.32))
                            .frame(width: 260, height: 14)
                            .offset(y: 7)
                    }

                    TerrariumSlotView(
                        potId: potId,
                        plantId: plantId,
                        plantLevel: level,
                        isHanging: isHanging,
                        width: 180,
                        height: 260,
                        widthFill: widthFill,
                        onTap: {
                            print("Tapped Slot: \(plantId) in \(potId)")
                        }
                    )
                }
                .frame(width: 260, height: 280)
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(16)

                // Bộ điều khiển
                ScrollView {
                    VStack(spacing: 12) {
                        Picker("Loài cây", selection: $plantId) {
                            ForEach(plants, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Loài chậu", selection: $potId) {
                            ForEach(pots, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            Text("Cấp độ: Lv.\(level)")
                            Stepper("", value: $level, in: 1...10)
                            Spacer()
                            Toggle("Treo", isOn: $isHanging)
                                .toggleStyle(.button)
                        }

                        HStack {
                            Text("widthFill: \(String(format: "%.2f", widthFill))")
                            Slider(value: $widthFill, in: 0.0...1.0)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    return SlotInteractivePreview()
}

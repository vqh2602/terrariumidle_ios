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
    public var itemTypeAttribute: ItemTypeAttribute? = nil
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
        itemTypeAttribute: ItemTypeAttribute? = nil,
        width: CGFloat,
        height: CGFloat,
        widthFill: CGFloat? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.plantId = plantId
        self.plantLevel = plantLevel
        self.isHanging = isHanging
        self.itemTypeAttribute = itemTypeAttribute
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
            itemTypeAttribute: itemTypeAttribute,
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
            itemTypeAttribute: itemTypeAttribute,
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
            itemTypeAttribute: itemTypeAttribute,
            onTap: onTap
        )

        return SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .id("slot-\(potId)-\(plantId)-\(plantLevel)-\(isHanging)-\(itemTypeAttribute?.rawValue ?? "auto")-\(activeFill)-\(width)-\(height)")
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
        itemTypeAttribute: ItemTypeAttribute? = nil,
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
            itemTypeAttribute: itemTypeAttribute,
            onTap: onTap
        )
        return newScene
    }
}

// MARK: - Interactive Preview

#Preview("Terrarium Slot - Preview Đan Xen Chiều Sâu") {
    struct SlotInteractivePreview: View {
        @State private var potId: String = "pot1"
        @State private var plantId: String = "plant13"
        @State private var level: Int = 3
        @State private var isHanging: Bool = false
        @State private var widthFill: CGFloat = 0.0
        @State private var selectedAttribute: String = "auto" // auto, none, front, hanging

        let plants = (1...14).map { "plant\($0)" }
        let pots = (1...14).map { "pot\($0)" }

        private var currentAttribute: ItemTypeAttribute? {
            switch selectedAttribute {
            case "none": return ItemTypeAttribute.none
            case "front": return ItemTypeAttribute.front
            case "hanging": return ItemTypeAttribute.hanging
            default: return nil
            }
        }

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
                        itemTypeAttribute: currentAttribute,
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

                        VStack(alignment: .leading, spacing: 4) {
                            Text("itemTypeAttribute (Z-Index Cây/Chậu):")
                                .font(.caption.bold())
                            Picker("Vị trí Z-Index", selection: $selectedAttribute) {
                                Text("Auto (JSON)").tag("auto")
                                Text("none (sau chậu)").tag("none")
                                Text("front (trước chậu)").tag("front")
                                Text("hanging (treo)").tag("hanging")
                            }
                            .pickerStyle(.segmented)
                        }

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

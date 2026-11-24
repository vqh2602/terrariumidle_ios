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
    /// Tỉ lệ vùng đệm an toàn để cành lá đung đưa không chạm biên render (Anti-Clipping Padding)
    public var overflowRatioX: CGFloat = 0.12
    public var overflowRatioY: CGFloat = 0.08
    public var onTap: (() -> Void)? = nil
    public var autoTapTrigger: Int = 0
    public var weatherTapTrigger: Int = 0
    public var onAutoTap: (() -> Void)? = nil
    public var careAnimation: PlantCareAnimationRequest? = nil
    public var onCareAnimationCompleted: ((UUID) -> Void)? = nil

    @State private var currentScene: TerrariumSlotScene? = nil
    /// Opacity dùng để fade-in scene sau khi render frame đầu, tránh màu xám chớp lên
    @State private var sceneOpacity: Double = 0.0

    private var renderWidth: CGFloat {
        width * (1.0 + overflowRatioX)
    }

    private var renderHeight: CGFloat {
        // A mature bubble rises up to 115pt and grows to a ~10pt radius.
        // Hanging pots need this space ABOVE their hook, just like standing pots.
        height + max(height * overflowRatioY, 140)
    }

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
        overflowRatioX: CGFloat = 0.12,
        overflowRatioY: CGFloat = 0.08,
        onTap: (() -> Void)? = nil,
        autoTapTrigger: Int = 0,
        weatherTapTrigger: Int = 0,
        onAutoTap: (() -> Void)? = nil,
        careAnimation: PlantCareAnimationRequest? = nil,
        onCareAnimationCompleted: ((UUID) -> Void)? = nil
    ) {
        self.potId = potId
        self.plantId = plantId
        self.plantLevel = plantLevel
        self.isHanging = isHanging
        self.itemTypeAttribute = itemTypeAttribute
        self.width = width
        self.height = height
        self.widthFill = widthFill
        self.overflowRatioX = overflowRatioX
        self.overflowRatioY = overflowRatioY
        self.onTap = onTap
        self.autoTapTrigger = autoTapTrigger
        self.weatherTapTrigger = weatherTapTrigger
        self.onAutoTap = onAutoTap
        self.careAnimation = careAnimation
        self.onCareAnimationCompleted = onCareAnimationCompleted

        let activeFill = widthFill ?? PotRegistry.defaultWidthFill(for: potId)
        let rWidth = width * (1.0 + overflowRatioX)
        let rHeight = height + max(height * overflowRatioY, 140)
        let initialScene = Self.makeScene(
            potId: potId,
            plantId: plantId,
            level: plantLevel,
            isHanging: isHanging,
            itemTypeAttribute: itemTypeAttribute,
            widthFill: activeFill,
            slotWidth: width,
            slotHeight: height,
            renderWidth: rWidth,
            renderHeight: rHeight,
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
            slotWidth: width,
            slotHeight: height,
            renderWidth: renderWidth,
            renderHeight: renderHeight,
            onTap: onTap
        )

        // Cấu hình đồng bộ trong render pass
        scene.configure(
            potId: potId,
            plantId: plantId,
            plantLevel: plantLevel,
            isHanging: isHanging,
            slotSize: CGSize(width: width, height: height),
            widthFill: activeFill,
            itemTypeAttribute: itemTypeAttribute,
            onTap: onTap
        )
        scene.onAutoTap = onAutoTap

        return SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: renderWidth, height: renderHeight)
            // Both layouts share the logical shelf bottom. The larger render surface
            // extends upward, leaving the hanging hook below the render boundary.
            .frame(width: width, height: height, alignment: .bottom)
            .contentShape(Rectangle())
            .onTapGesture {
                scene.handleTap()
            }
            .onChange(of: autoTapTrigger) { _, _ in
                scene.handleAutoTap()
            }
            .onChange(of: weatherTapTrigger) { _, _ in
                // Rewards were already granted centrally for every floor.
                scene.handleAutoTap(grantsReward: false)
            }
            .onChange(of: careAnimation?.id) { _, _ in
                playCareAnimation(in: scene)
            }
            .opacity(sceneOpacity)
            .id("slot-\(potId)-\(plantId)-\(plantLevel)-\(isHanging)-\(itemTypeAttribute?.rawValue ?? "auto")-\(activeFill)-\(width)-\(height)")
            .onAppear {
                if currentScene == nil {
                    currentScene = scene
                }
                playCareAnimation(in: scene)
                // Fade-in sau 1 frame để tránh màu xám lúc SpriteKit chưa render xong
                let delay = SpriteKitPreloader.shared.isReady ? 0.05 : 0.15
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: 0.18)) {
                        sceneOpacity = 1.0
                    }
                }
            }
            .onChange(of: plantId) { _, _ in
                // Reset opacity khi đổi cây để tránh flash khi rebuild scene
                sceneOpacity = 0.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeIn(duration: 0.18)) {
                        sceneOpacity = 1.0
                    }
                }
            }
    }

    // MARK: - Helper

    private func playCareAnimation(in scene: TerrariumSlotScene) {
        guard let request = careAnimation else { return }
        scene.playCareAnimation(request) {
            onCareAnimationCompleted?(request.id)
        }
    }

    private static func makeScene(
        potId: String,
        plantId: String,
        level: Int,
        isHanging: Bool,
        itemTypeAttribute: ItemTypeAttribute? = nil,
        widthFill: CGFloat,
        slotWidth: CGFloat,
        slotHeight: CGFloat,
        renderWidth: CGFloat,
        renderHeight: CGFloat,
        onTap: (() -> Void)?
    ) -> TerrariumSlotScene {
        let newScene = TerrariumSlotScene(size: CGSize(width: renderWidth, height: renderHeight))
        newScene.configure(
            potId: potId,
            plantId: plantId,
            plantLevel: level,
            isHanging: isHanging,
            slotSize: CGSize(width: slotWidth, height: slotHeight),
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

        let plants = (1...15).map { "plant\($0)" }
        let pots = (1...15).map { "pot\($0)" }

        private var currentAttribute: ItemTypeAttribute? {
            switch selectedAttribute {
            case "none": return ItemTypeAttribute.none
            case "front": return ItemTypeAttribute.front
            case "hanging": return ItemTypeAttribute.hanging
            case "hanging,front": return ItemTypeAttribute.hangingFront
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
                                Text("Auto").tag("auto")
                                Text("none").tag("none")
                                Text("front").tag("front")
                                Text("hanging").tag("hanging")
                                Text("hanging,front").tag("hanging,front")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: selectedAttribute) { _, newVal in
                                if newVal == "hanging" || newVal == "hanging,front" {
                                    isHanging = true
                                } else if newVal == "none" || newVal == "front" {
                                    isHanging = false
                                }
                            }
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

//
//  FallingLeavesView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component lớp phủ lá rơi sử dụng SpriteKit
/// - Nhận từ 1 đến 6 ảnh lá
/// - Tự động tạo hiệu ứng rơi, đung đưa trong gió, lật 3D tự nhiên
/// - Hiệu năng cao (Metal/SpriteKit 60fps), giải phóng RAM khi lá rơi hết màn hình
/// - Tự động cho phép click xuyên qua (`allowsHitTesting(false)`)
public struct FallingLeavesView: View {
    // MARK: - Parameters

    /// Danh sách tên ảnh trong Assets (tối đa 1 -> 6 ảnh, ví dụ: ["leaf1", "leaf2"])
    public var leafImages: [String] = []

    /// Danh sách ảnh UIImage trực tiếp (tối đa 1 -> 6 ảnh)
    public var customImages: [UIImage] = []

    /// Danh sách SKTexture trực tiếp (tối đa 1 -> 6 texture)
    public var customTextures: [SKTexture] = []

    /// Mật độ lá rơi (.low, .medium, .high)
    public var density: LeafDensity = .medium

    /// Hướng và lực gió (.none, .gentleLeft, .gentleRight, .breezeLeft, .breezeRight, .variable)
    public var wind: WindDirection = .gentleRight

    /// Tốc độ rơi (.slow, .normal, .fast)
    public var speed: LeafSpeed = .normal

    /// Tạm dừng animation (tiết kiệm pin khi không cần hiển thị)
    public var isPaused: Bool = false

    // MARK: - Environment & State

    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: FallingLeavesScene?

    private var effectivePaused: Bool {
        isPaused || scenePhase != .active
    }

    // MARK: - Initializer

    public init(
        leafImages: [String] = [],
        customImages: [UIImage] = [],
        customTextures: [SKTexture] = [],
        density: LeafDensity = .medium,
        wind: WindDirection = .gentleRight,
        speed: LeafSpeed = .normal,
        isPaused: Bool = false
    ) {
        self.leafImages = leafImages
        self.customImages = customImages
        self.customTextures = customTextures
        self.density = density
        self.wind = wind
        self.speed = speed
        self.isPaused = isPaused
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: effectivePaused, options: [.allowsTransparency])
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.clear)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false) // ⭐️ Click xuyên qua, không chặn các nút và cây bên dưới
                    .onChange(of: geometry.size) { newSize in
                        scene.size = newSize
                    }
                    .onChange(of: effectivePaused) { paused in
                        scene.isPaused = paused
                    }
            } else {
                Color.clear
                    .onAppear {
                        let newScene = FallingLeavesScene(size: geometry.size)
                        newScene.isPaused = effectivePaused
                        newScene.configure(
                            imageNames: leafImages,
                            customImages: customImages,
                            customTextures: customTextures,
                            density: density,
                            wind: wind,
                            speed: speed
                        )
                        self.scene = newScene
                    }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "faf3e1")
            .ignoresSafeArea()

        VStack {
            Text("Terrarium Idle")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.green)
            Text("SpriteKit Falling Leaves Demo")
                .foregroundColor(.gray)
        }

        // Lớp phủ lá rơi SpriteKit (sử dụng 6 lá vector tự sinh nếu chưa truyền ảnh)
        FallingLeavesView(
            density: .medium,
            wind: .gentleRight,
            speed: .normal
        )
    }
}

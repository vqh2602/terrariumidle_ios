//
//  FirefliesView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component lớp phủ Đom đóm phát sáng bay lượn
public struct FirefliesView: View {
    public var count: Int = 26
    public var customImages: [UIImage] = []
    public var isPaused: Bool = false

    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: FirefliesScene?

    private var effectivePaused: Bool {
        isPaused || scenePhase != .active
    }

    public init(count: Int = 26, customImages: [UIImage] = [], isPaused: Bool = false) {
        self.count = count
        self.customImages = customImages
        self.isPaused = isPaused
    }

    public var body: some View {
        GeometryReader { geometry in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: effectivePaused, options: [.allowsTransparency])
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.clear)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false) // ⭐️ Không chặn thao tác chạm trên cây và nút
                    .onChange(of: geometry.size) { newSize in
                        scene.size = newSize
                    }
                    .onChange(of: effectivePaused) { paused in
                        scene.isPaused = paused
                    }
            } else {
                Color.clear
                    .onAppear {
                        let newScene = FirefliesScene(size: geometry.size)
                        newScene.isPaused = effectivePaused
                        newScene.configure(count: count, customImages: customImages)
                        self.scene = newScene
                    }
            }
        }
    }
}

#Preview("Fireflies Night Preview") {
    ZStack {
        // Nền rừng đêm huyền ảo đối chiếu với ảnh tham chiếu
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.12, blue: 0.28),
                Color(red: 0.20, green: 0.14, blue: 0.36),
                Color(red: 0.10, green: 0.18, blue: 0.26)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        FirefliesView(count: 26)
    }
}

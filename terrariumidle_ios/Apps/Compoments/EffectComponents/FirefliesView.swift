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
    public var count: Int = 24
    public var customImages: [UIImage] = []
    public var isPaused: Bool = false

    @State private var scene: FirefliesScene?

    public init(count: Int = 24, customImages: [UIImage] = [], isPaused: Bool = false) {
        self.count = count
        self.customImages = customImages
        self.isPaused = isPaused
    }

    public var body: some View {
        GeometryReader { geometry in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: isPaused, options: [.allowsTransparency])
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.clear)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false) // ⭐️ Không chặn thao tác chạm trên cây và nút
                    .onChange(of: geometry.size) { newSize in
                        scene.size = newSize
                    }
                    .onChange(of: isPaused) { paused in
                        scene.isPaused = paused
                    }
            } else {
                Color.clear
                    .onAppear {
                        let newScene = FirefliesScene(size: geometry.size)
                        newScene.configure(count: count, customImages: customImages)
                        self.scene = newScene
                    }
            }
        }
    }
}

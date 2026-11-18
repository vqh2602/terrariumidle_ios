//
//  SpriteKitBackgroundView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component lớp nền phong cảnh tự vẽ bằng SpriteKit
/// Hỗ trợ:
/// - sky_sun_day: Ban công quang đãng (mây trôi, mặt trời dịu)
/// - sky_sun_set: Ban công chiều tà (hoàng hôn rực rỡ)
/// - sky_rain: Ban công mưa bão (mây xám, mưa rơi tí tách)
/// - sky_moon_night: Ban công trời sao (trăng lưỡi liềm, sao lấp lánh)
/// - sky_moon_star: Đêm muộn trời sao (trăng tròn, sao băng xẹt qua)
/// - landscape6, landscape7: Các phong cảnh đặc biệt
public struct SpriteKitBackgroundView: View {
    public var backgroundId: String = "sky_sun_day"
    public var isPaused: Bool = false

    @State private var scene: SpriteKitBackgroundScene?

    public init(backgroundId: String = "sky_sun_day", isPaused: Bool = false) {
        self.backgroundId = backgroundId
        self.isPaused = isPaused
    }

    public var body: some View {
        GeometryReader { geometry in
            if let scene = scene {
                SpriteView(scene: scene, isPaused: isPaused, options: [.allowsTransparency])
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.clear)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
                    .onChange(of: geometry.size) { newSize in
                        scene.size = newSize
                    }
                    .onChange(of: backgroundId) { newId in
                        scene.configure(themeId: newId)
                    }
                    .onChange(of: isPaused) { paused in
                        scene.isPaused = paused
                    }
            } else {
                Color.clear
                    .onAppear {
                        // Ưu tiên nạp từ BackgroundScene.sks nếu có
                        let newScene: SpriteKitBackgroundScene
                        if let sksScene = SpriteKitBackgroundScene(fileNamed: "BackgroundScene.sks") ?? SpriteKitBackgroundScene(fileNamed: "BackgroundScene") {
                            sksScene.size = geometry.size
                            newScene = sksScene
                        } else {
                            newScene = SpriteKitBackgroundScene(size: geometry.size)
                        }
                        newScene.configure(themeId: backgroundId)
                        self.scene = newScene
                    }
            }
        }
    }
}

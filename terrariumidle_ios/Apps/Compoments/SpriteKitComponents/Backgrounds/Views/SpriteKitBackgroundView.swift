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

    public var onReady: (() -> Void)?

    @Environment(\.scenePhase) private var scenePhase
    @State private var scene: SpriteKitBackgroundScene?

    private var effectivePaused: Bool {
        isPaused || scenePhase != .active
    }

    public init(backgroundId: String = "sky_sun_day", isPaused: Bool = false, onReady: (() -> Void)? = nil) {
        self.backgroundId = backgroundId
        self.isPaused = isPaused
        self.onReady = onReady
    }

    public var body: some View {
        GeometryReader { geometry in
            let currentScene = getOrCreateScene(size: geometry.size)

            SpriteView(scene: currentScene, isPaused: effectivePaused, options: [.allowsTransparency])
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.clear)
                .ignoresSafeArea(.all)
                .allowsHitTesting(false)
                .id("\(backgroundId)-\(geometry.size.width)-\(geometry.size.height)")
                .onAppear {
                    currentScene.isPaused = effectivePaused
                    currentScene.configure(themeId: backgroundId)
                    reportPreparedScene(currentScene)
                }
                .onChange(of: geometry.size) { newSize in
                    currentScene.size = newSize
                    reportPreparedScene(currentScene)
                }
                .onChange(of: backgroundId) { newId in
                    currentScene.configure(themeId: newId)
                }
                .onChange(of: effectivePaused) { paused in
                    currentScene.isPaused = paused
                }
        }
        .ignoresSafeArea(.all)
    }

    private func reportPreparedScene(_ scene: SpriteKitBackgroundScene) {
        guard scene.size.width > 0, scene.size.height > 0 else { return }
        // configure builds the background synchronously. Do not wait for a
        // render tick: SpriteKit may pause ticks while an opaque loader covers it.
        DispatchQueue.main.async { onReady?() }
    }

    private func getOrCreateScene(size: CGSize) -> SpriteKitBackgroundScene {
        if let existing = scene {
            if size.width > 0 && size.height > 0 && (abs(existing.size.width - size.width) > 1 || abs(existing.size.height - size.height) > 1) {
                existing.size = size
            }
            return existing
        }

        let newScene: SpriteKitBackgroundScene
        if let sksScene = SpriteKitBackgroundScene(fileNamed: "BackgroundScene.sks") ?? SpriteKitBackgroundScene(fileNamed: "BackgroundScene") {
            sksScene.size = size
            sksScene.anchorPoint = .zero
            newScene = sksScene
        } else {
            newScene = SpriteKitBackgroundScene(size: size)
        }
        newScene.anchorPoint = .zero
        newScene.configure(themeId: backgroundId)
        DispatchQueue.main.async {
            self.scene = newScene
        }
        return newScene
    }
}

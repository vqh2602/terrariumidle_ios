//
//  GardenAnimalOverlayView.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import SwiftUI
import UIKit

/// SKView trong suốt cho phép mọi thao tác chạm/cuộn bên ngoài chú ong đi xuyên thẳng xuống vườn bên dưới.
public final class PassThroughBeeSKView: SKView {
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let beeScene = scene as? GardenBeeOverlayScene else { return false }
        return beeScene.hasTappableBee(atViewPoint: point)
    }
}

/// Lớp phủ toàn vườn hiển thị 4 chú ong bay giữa tổ ong và các cây trồng,
/// hỗ trợ chạm trực tiếp vào từng chú ong đang bay/lấy mật mà không chặn thao tác vuốt cuộn kệ.
public struct GardenAnimalOverlayView: UIViewRepresentable {
    @ObservedObject var coordinator: GardenBeeSwarmCoordinator
    let viewportSize: CGSize

    public init(coordinator: GardenBeeSwarmCoordinator, viewportSize: CGSize) {
        self.coordinator = coordinator
        self.viewportSize = viewportSize
    }

    public func makeUIView(context: Context) -> PassThroughBeeSKView {
        let skView = PassThroughBeeSKView(frame: CGRect(origin: .zero, size: viewportSize))
        skView.backgroundColor = .clear
        skView.isOpaque = false
        skView.allowsTransparency = true
        skView.ignoresSiblingOrder = true
        skView.shouldCullNonVisibleNodes = true
        skView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond

        let scene = GardenBeeOverlayScene(size: viewportSize)
        scene.coordinator = coordinator
        coordinator.overlayScene = scene
        skView.presentScene(scene)
        return skView
    }

    public func updateUIView(_ uiView: PassThroughBeeSKView, context: Context) {
        if abs(uiView.bounds.width - viewportSize.width) > 1 || abs(uiView.bounds.height - viewportSize.height) > 1 {
            uiView.frame = CGRect(origin: .zero, size: viewportSize)
            uiView.scene?.size = viewportSize
        }
        if let scene = uiView.scene as? GardenBeeOverlayScene {
            if scene.coordinator !== coordinator {
                scene.coordinator = coordinator
            }
            if coordinator.overlayScene !== scene {
                coordinator.overlayScene = scene
            }
            if scene.isEditing != coordinator.isEditing {
                scene.isEditing = coordinator.isEditing
            }
            let shouldPause = !coordinator.isSceneActive
            if scene.isScenePausedByLifecycle != shouldPause {
                scene.isScenePausedByLifecycle = shouldPause
            }
        }
    }
}

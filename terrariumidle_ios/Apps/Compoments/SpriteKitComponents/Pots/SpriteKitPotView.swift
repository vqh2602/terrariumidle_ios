//
//  SpriteKitPotView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component hiển thị chậu cây bằng SpriteKit
/// - Đổ bóng tự nhiên dưới đáy
/// - Phản hồi nảy đàn hồi (spring bounce) khi chạm vào
/// - Hỗ trợ cả chậu đứng trên kệ và chậu treo móc
public struct SpriteKitPotView: View {
    public var potId: String = "pot1"
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    @State private var scene: SpriteKitPotScene?

    public init(
        potId: String = "pot1",
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 80,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.onTap = onTap
    }

    public var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: width, height: height)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        scene.playTapAnimation()
                        onTap?()
                    }
                    .onChange(of: potId) { newId in
                        scene.configure(potId: newId, isHanging: isHanging)
                    }
            } else {
                Color.clear
                    .frame(width: width, height: height)
                    .onAppear {
                        let newScene = SpriteKitPotScene(size: CGSize(width: width, height: height))
                        newScene.configure(potId: potId, isHanging: isHanging)
                        self.scene = newScene
                    }
            }
        }
    }
}

//
//  SpriteKitPlantView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// SwiftUI Component hiển thị cây bằng SpriteKit
/// - Đung đưa nhẹ tự nhiên trong gió
/// - Tự động mở rộng theo cấp độ cây (`plantLevel`)
/// - Phản hồi nảy và nhả bong bóng oxy khi nhấn vào
public struct SpriteKitPlantView: View {
    public var plantId: String = "plant1"
    public var plantLevel: Int = 1
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var onTap: (() -> Void)? = nil

    @State private var scene: SpriteKitPlantScene?

    public init(
        plantId: String = "plant1",
        plantLevel: Int = 1,
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 140,
        onTap: (() -> Void)? = nil
    ) {
        self.plantId = plantId
        self.plantLevel = plantLevel
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
                    .onChange(of: plantId) { newId in
                        scene.configure(plantId: newId, level: plantLevel, isHanging: isHanging)
                    }
                    .onChange(of: plantLevel) { newLevel in
                        scene.configure(plantId: plantId, level: newLevel, isHanging: isHanging)
                    }
            } else {
                Color.clear
                    .frame(width: width, height: height)
                    .onAppear {
                        // Ưu tiên nạp từ PlantScene.sks nếu có
                        let newScene: SpriteKitPlantScene
                        if let sksScene = SpriteKitPlantScene(fileNamed: "PlantScene.sks") ?? SpriteKitPlantScene(fileNamed: "PlantScene") {
                            sksScene.size = CGSize(width: width, height: height)
                            newScene = sksScene
                        } else {
                            newScene = SpriteKitPlantScene(size: CGSize(width: width, height: height))
                        }
                        newScene.configure(plantId: plantId, level: plantLevel, isHanging: isHanging)
                        self.scene = newScene
                    }
            }
        }
    }
}

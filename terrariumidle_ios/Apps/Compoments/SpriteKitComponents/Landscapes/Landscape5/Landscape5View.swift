//
//  Landscape5View.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import SwiftUI

/// View xem trước độc lập cho Landscape 5: "Ban công ô kính mưa"
public struct Landscape5View: View {

    @State private var scene: Landscape5PreviewScene?

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            if let activeScene = scene {
                SpriteView(scene: activeScene, options: [.allowsTransparency])
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea(.all)
                    .onTapGesture { location in
                        activeScene.landscapeNode?.playTapAnimation(at: CGPoint(x: location.x, y: geo.size.height - location.y))
                    }
                    .onChange(of: geo.size) { newSize in
                        activeScene.size = newSize
                        activeScene.landscapeNode?.configure(containerSize: newSize)
                    }
            } else {
                Color.clear
                    .onAppear {
                        let newScene = Landscape5PreviewScene(size: geo.size)
                        self.scene = newScene
                    }
            }
        }
        .ignoresSafeArea(.all)
    }
}

/// Scene bọc hỗ trợ xem trước Landscape 5
final class Landscape5PreviewScene: SKScene {
    var landscapeNode: Landscape5Node?

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = .zero

        if landscapeNode == nil && size.width > 0 && size.height > 0 {
            let node = Landscape5Node(containerSize: size)
            addChild(node)
            self.landscapeNode = node
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if size.width > 0 && size.height > 0 {
            if let node = landscapeNode {
                node.configure(containerSize: size)
            } else {
                let node = Landscape5Node(containerSize: size)
                addChild(node)
                self.landscapeNode = node
            }
        }
    }
}

#Preview("Landscape 5 - Ban công ô kính mưa") {
    Landscape5View()
}

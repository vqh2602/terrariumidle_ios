//
//  Landscape6View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import SwiftUI

/// View xem trước độc lập cho Landscape 6: "Minamoto no Yuuhi" (源の夕陽 - Cội nguồn Hoàng hôn)
public struct Landscape6View: View {

    @State private var scene: Landscape6PreviewScene?

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
                    .onChange(of: geo.size) { _, newSize in
                        activeScene.size = newSize
                        activeScene.landscapeNode?.configure(containerSize: newSize)
                    }
            } else {
                Color.clear
                    .onAppear {
                        let newScene = Landscape6PreviewScene(size: geo.size)
                        self.scene = newScene
                    }
            }
        }
        .ignoresSafeArea(.all)
    }
}

/// Scene bọc hỗ trợ xem trước Landscape 6
final class Landscape6PreviewScene: SKScene {
    var landscapeNode: Landscape6Node?

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = .zero

        if landscapeNode == nil && size.width > 0 && size.height > 0 {
            let node = Landscape6Node(containerSize: size)
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
                let node = Landscape6Node(containerSize: size)
                addChild(node)
                self.landscapeNode = node
            }
        }
    }
}

#Preview("Landscape 6 - Minamoto no Yuuhi") {
    Landscape6View()
}

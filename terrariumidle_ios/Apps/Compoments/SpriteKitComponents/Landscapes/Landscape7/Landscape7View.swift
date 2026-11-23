//
//  Landscape7View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import SwiftUI

/// View xem trước độc lập cho Landscape 7: "Thần Sơn Huyễn Cảnh" (神山幻境)
public struct Landscape7View: View {

    @State private var scene: Landscape7PreviewScene?

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
                        let newScene = Landscape7PreviewScene(size: geo.size)
                        self.scene = newScene
                    }
            }
        }
        .ignoresSafeArea(.all)
    }
}

/// Scene bọc hỗ trợ xem trước Landscape 7
final class Landscape7PreviewScene: SKScene {
    var landscapeNode: Landscape7Node?

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = .zero

        if landscapeNode == nil && size.width > 0 && size.height > 0 {
            let node = Landscape7Node(containerSize: size)
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
                let node = Landscape7Node(containerSize: size)
                addChild(node)
                self.landscapeNode = node
            }
        }
    }
}

#Preview("Landscape 7 - Thần Sơn Huyễn Cảnh") {
    Landscape7View()
}

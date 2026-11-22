//
//  Landscape3View.swift
//  terrariumidle_ios
//
//  Created by AI on 22/11/26.
//

import SpriteKit
import SwiftUI

/// View xem trước độc lập cho Landscape 3: "Ban công mưa bão"
public struct Landscape3View: View {

    @State private var scene: Landscape3PreviewScene?

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
                        let newScene = Landscape3PreviewScene(size: geo.size)
                        self.scene = newScene
                    }
            }
        }
        .ignoresSafeArea(.all)
    }
}

/// Scene bọc hỗ trợ xem trước Landscape 3
final class Landscape3PreviewScene: SKScene {
    var landscapeNode: Landscape3Node?

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = .zero

        if landscapeNode == nil && size.width > 0 && size.height > 0 {
            let node = Landscape3Node(containerSize: size)
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
                let node = Landscape3Node(containerSize: size)
                addChild(node)
                self.landscapeNode = node
            }
        }
    }
}

#Preview("Landscape 3 - Ban công mưa bão") {
    Landscape3View()
}

//
//  SpriteKitStickerScene.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

// MARK: - SpriteKit Scene cho Sticker / Vật trang trí trong Terrarium
public final class SpriteKitStickerScene: SKScene {

    // MARK: - Properties

    private var customStickerInteractive: StickerInteractiveNode?
    private var stickerId: String = "sticker1"
    private var isHanging: Bool = true
    public var onTap: (() -> Void)?

    // MARK: - Initializer

    public override init() {
        super.init(size: .zero)
        setupBasics()
    }

    public override init(size: CGSize) {
        super.init(size: size)
        setupBasics()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBasics()
    }

    private func setupBasics() {
        backgroundColor = .clear
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 1.0) // Neo đỉnh giữa cho sticker treo
    }

    // MARK: - Configuration

    public func configure(stickerId: String, isHanging: Bool = true) {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        let changed = self.stickerId != cleanId || self.isHanging != isHanging
        self.stickerId = cleanId
        self.isHanging = isHanging

        anchorPoint = CGPoint(x: 0.5, y: isHanging ? 1.0 : 0.0)

        if (changed || customStickerInteractive == nil) && size.width > 0 && size.height > 0 {
            buildSticker()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        view.isPaused = false
        self.isPaused = false
        if customStickerInteractive == nil && size.width > 0 && size.height > 0 {
            buildSticker()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if customStickerInteractive == nil || abs(oldSize.width - size.width) > 2 || abs(oldSize.height - size.height) > 2 {
            if size.width > 0 && size.height > 0 {
                buildSticker()
            }
        }
    }

    // MARK: - Build Sticker Node

    private func buildSticker() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()
        customStickerInteractive = nil

        let sticker = StickerFactory.createSticker(
            id: stickerId,
            containerSize: size,
            isHanging: isHanging
        )

        sticker.asNode.position = .zero
        sticker.asNode.zPosition = 10
        addChild(sticker.asNode)
        self.customStickerInteractive = sticker
    }

    // MARK: - Tap Animation

    public func playTapAnimation() {
        customStickerInteractive?.playTapAnimation()
    }

    // MARK: - Touch Handling

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        playTapAnimation()
        onTap?()
    }
}

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
    private var slotSize: CGSize = .zero
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

    public func configure(stickerId: String, isHanging: Bool = true, slotSize: CGSize = .zero) {
        let cleanId = stickerId.lowercased().trimmingCharacters(in: .whitespaces)
        let resolved = ItemDataManager.shared.getItem(byId: cleanId)?.itemTypeAttribute.isHanging ?? isHanging
        let changed = self.stickerId != cleanId ||
                      self.isHanging != resolved ||
                      abs(self.slotSize.width - slotSize.width) > 1 ||
                      abs(self.slotSize.height - slotSize.height) > 1

        self.stickerId = cleanId
        self.isHanging = resolved
        self.slotSize = slotSize

        anchorPoint = CGPoint(x: 0.5, y: resolved ? 1.0 : 0.0)

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

        let baseW = slotSize.width > 0 ? slotSize.width : size.width
        let baseH = slotSize.height > 0 ? slotSize.height : size.height

        let sticker = StickerFactory.createSticker(
            id: stickerId,
            containerSize: CGSize(width: baseW, height: baseH),
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

        // Phát âm thanh khi tap vào Sticker từ JSON ("sound": "tap", nếu không cấu hình thì mặc định "tap")
        let soundName = ItemDataManager.shared.getSticker(byId: stickerId)?.clickSound ??
                        ItemDataManager.shared.getItem(byId: stickerId)?.clickSound ?? "tap"
        AudioPlayer.shared.playClickSound(named: soundName)
    }
}

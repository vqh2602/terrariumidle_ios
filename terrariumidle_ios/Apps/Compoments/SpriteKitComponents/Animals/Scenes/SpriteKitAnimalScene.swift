//
//  SpriteKitAnimalScene.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Scene SpriteKit cho Tổ Động Vật (ví dụ: Tổ Ong `animal1`) trên ô kệ Terrarium
public final class SpriteKitAnimalScene: SKScene {

    private var customAnimalInteractive: AnimalInteractiveNode?
    private var animalId: String = "animal1"
    private var isHanging: Bool = true
    private var slotSize: CGSize = .zero
    public var onTap: (() -> Void)?

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
        anchorPoint = CGPoint(x: 0.5, y: 1.0)
    }

    public func configure(animalId: String, isHanging: Bool = true, slotSize: CGSize = .zero) {
        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        let resolved = ItemDataManager.shared.getItem(byId: cleanId)?.itemTypeAttribute.isHanging ?? isHanging
        let changed = self.animalId != cleanId ||
                      self.isHanging != resolved ||
                      abs(self.slotSize.width - slotSize.width) > 1 ||
                      abs(self.slotSize.height - slotSize.height) > 1

        self.animalId = cleanId
        self.isHanging = resolved
        self.slotSize = slotSize

        anchorPoint = CGPoint(x: 0.5, y: resolved ? 1.0 : 0.0)

        if (changed || customAnimalInteractive == nil) && size.width > 0 && size.height > 0 {
            buildAnimal()
        }
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        view.allowsTransparency = true
        view.isPaused = false
        self.isPaused = false
        if customAnimalInteractive == nil && size.width > 0 && size.height > 0 {
            buildAnimal()
        }
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if customAnimalInteractive == nil || abs(oldSize.width - size.width) > 2 || abs(oldSize.height - size.height) > 2 {
            if size.width > 0 && size.height > 0 {
                buildAnimal()
            }
        }
    }

    private func buildAnimal() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren()
        customAnimalInteractive = nil

        let baseW = slotSize.width > 0 ? slotSize.width : size.width
        let baseH = slotSize.height > 0 ? slotSize.height : size.height

        let animal = AnimalFactory.createAnimal(
            id: animalId,
            containerSize: CGSize(width: baseW, height: baseH),
            isHanging: isHanging
        )
        animal.asNode.position = .zero
        animal.asNode.zPosition = 10
        addChild(animal.asNode)
        self.customAnimalInteractive = animal
    }

    public func playTapAnimation() {
        customAnimalInteractive?.playTapAnimation()

        let soundName = ItemDataManager.shared.getAnimal(byId: animalId)?.clickSound ??
                        ItemDataManager.shared.getItem(byId: animalId)?.clickSound ?? "tap"
        AudioPlayer.shared.playClickSound(named: soundName)
    }
}

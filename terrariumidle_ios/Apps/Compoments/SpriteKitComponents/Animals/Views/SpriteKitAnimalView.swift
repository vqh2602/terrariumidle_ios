//
//  SpriteKitAnimalView.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import SwiftUI

/// Typealias ngắn gọn đồng bộ với `StickerView`, `PotView`, `PlantView`
public typealias AnimalView = SpriteKitAnimalView

// MARK: - Animal Availability

public enum AnimalAvailability {
    public static let supportedAnimalIds: Set<String> = [
        "animal1",
        "animal2",
        "animal3"
    ]

    public static func isAvailable(animalId: String) -> Bool {
        supportedAnimalIds.contains(animalId.lowercased().trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Animal Registry

public enum AnimalRegistry {
    public static func defaultFitRatio(for animalId: String) -> CGFloat {
        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        switch cleanId {
        case "animal1": return Animal1View.defaultFitRatio
        case "animal2": return Animal2View.defaultFitRatio
        case "animal3": return Animal3View.defaultFitRatio
        default: return 0.62
        }
    }
}

// MARK: - SpriteKit Animal View

/// SwiftUI Component hiển thị Tổ Động Vật (`animal1`...) bằng SpriteKit.
/// Hoạt động tương đồng với `SpriteKitStickerView`, kèm vùng đệm chống cắt biên hiệu ứng mật ong.
public struct SpriteKitAnimalView: View {
    public var animalId: String = "animal1"
    public var isHanging: Bool = true
    public var width: CGFloat
    public var height: CGFloat
    public var overflowRatioX: CGFloat = 0.25
    public var overflowRatioY: CGFloat = 0.18
    public var capturedPests: [PestSpecies] = []
    public var onTap: (() -> Void)? = nil

    private var renderWidth: CGFloat {
        width * (1.0 + overflowRatioX)
    }

    private var renderHeight: CGFloat {
        height * (1.0 + overflowRatioY)
    }

    private var resolvedIsHanging: Bool {
        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        if let item = ItemDataManager.shared.getItem(byId: cleanId) {
            return item.itemTypeAttribute.isHanging
        }
        return isHanging
    }

    @State private var scene: SpriteKitAnimalScene
    @State private var lastTapTime: TimeInterval = 0

    public init(
        animalId: String = "animal1",
        isHanging: Bool = true,
        width: CGFloat = 120,
        height: CGFloat = 220,
        overflowRatioX: CGFloat = 0.25,
        overflowRatioY: CGFloat = 0.18,
        capturedPests: [PestSpecies] = [],
        onTap: (() -> Void)? = nil
    ) {
        self.animalId = animalId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.overflowRatioX = overflowRatioX
        self.overflowRatioY = overflowRatioY
        self.capturedPests = capturedPests
        self.onTap = onTap

        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        let resolved = ItemDataManager.shared.getItem(byId: cleanId)?.itemTypeAttribute.isHanging ?? isHanging

        let rW = width * (1.0 + overflowRatioX)
        let rH = height * (1.0 + overflowRatioY)
        let s = SpriteKitAnimalScene(size: CGSize(width: rW, height: rH))
        s.configure(animalId: cleanId, isHanging: resolved, slotSize: CGSize(width: width, height: height), capturedPests: capturedPests)
        _scene = State(initialValue: s)
    }

    public var body: some View {
        let cleanId = animalId.lowercased().trimmingCharacters(in: .whitespaces)
        let activeHanging = resolvedIsHanging

        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: renderWidth, height: renderHeight)
            .frame(width: width, height: height, alignment: activeHanging ? .top : .bottom)
            .id("\(cleanId)-\(activeHanging)-\(width)-\(height)")
            .contentShape(Rectangle())
            .onTapGesture {
                let now = CACurrentMediaTime()
                guard now - lastTapTime > 0.12 else { return }
                lastTapTime = now

                scene.playTapAnimation()
                onTap?()
            }
            .onAppear {
                scene.configure(animalId: cleanId, isHanging: activeHanging, slotSize: CGSize(width: width, height: height), capturedPests: capturedPests)
            }
            .onChange(of: animalId) { _, newId in
                let newCleanId = newId.lowercased().trimmingCharacters(in: .whitespaces)
                let newResolved = ItemDataManager.shared.getItem(byId: newCleanId)?.itemTypeAttribute.isHanging ?? isHanging
                scene.configure(animalId: newCleanId, isHanging: newResolved, slotSize: CGSize(width: width, height: height), capturedPests: capturedPests)
            }
            .onChange(of: isHanging) { _, _ in
                scene.configure(animalId: cleanId, isHanging: activeHanging, slotSize: CGSize(width: width, height: height), capturedPests: capturedPests)
            }
            .onChange(of: capturedPests) { _, newPests in
                scene.updateCapturedPests(newPests)
            }
    }
}

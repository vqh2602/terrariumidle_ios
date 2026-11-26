//
//  AnimalSelectionView.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SwiftUI

struct AnimalSelectionView: View {
    let cartAnimals: [String]
    let gardenModel: GardenModel?
    let currentPosition: String
    let onSelect: (String) -> Void
    @Binding var selectedAnimalId: String?

    private var ownedAnimals: [ItemData] {
        ItemDataManager.shared.getAllAnimals().filter { cartAnimals.contains($0.id) }
    }

    private var disabledMessages: [String: String] {
        guard let gardenModel else { return [:] }
        var result: [String: String] = [:]
        for item in ownedAnimals {
            if let maxLimit = item.maximum, maxLimit > 0,
               !gardenModel.canPlantItem(item, at: currentPosition) {
                let current = gardenModel.plantedCount(forItemId: item.id, excludingPosition: currentPosition)
                result[item.id] = "Đã đạt tối đa (%d/%d)".tr(current, maxLimit)
            }
        }
        return result
    }

    var body: some View {
        GardenItemPicker(
            items: ownedAnimals,
            placeholder: "Tìm động vật trong kho…".tr,
            selection: $selectedAnimalId,
            onSelect: onSelect,
            disabledMessages: disabledMessages
        )
    }
}

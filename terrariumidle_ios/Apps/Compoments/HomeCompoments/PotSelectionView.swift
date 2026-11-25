import SwiftUI

struct PotSelectionView: View {
    let cartPots: [String]
    let onSelect: (String) -> Void
    @Binding var selectedPotId: String?
    var recommendedPotId: String? = nil

    var body: some View {
        GardenItemPicker(items: ItemDataManager.shared.getAllPots().filter { cartPots.contains($0.id) },
                         placeholder: "Tìm chậu trong kho…".tr,
                         selection: $selectedPotId, onSelect: onSelect,
                         recommendedItemId: recommendedPotId)
    }
}

struct PotItemRow: View {
    let pot: ItemData
    let isSelected: Bool
    let onSelect: () -> Void
    var body: some View {
        GardenInventoryRow(item: pot, isSelected: isSelected, onSelect: onSelect)
    }
}

import SwiftUI

struct PlantSelectionView: View {
    let cartPlants: [String]
    let rowIndex: Int
    let columnIndex: Int
    let onSelect: (String) -> Void
    @Binding var selectedPlantId: String?
    var recommendedPlantId: String? = nil

    var body: some View {
        GardenItemPicker(items: ItemDataManager.shared.getAllPlants().filter { cartPlants.contains($0.id) },
                         placeholder: "Tìm cây trong kho…",
                         selection: $selectedPlantId, onSelect: onSelect,
                         recommendedItemId: recommendedPlantId)
    }
}

struct PlantItemRow: View {
    let plant: ItemData
    let isSelected: Bool
    let onSelect: () -> Void
    var body: some View {
        GardenInventoryRow(item: plant, isSelected: isSelected, onSelect: onSelect)
    }
}

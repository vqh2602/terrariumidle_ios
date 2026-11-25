import SwiftUI

struct DecorationSelectionView: View {
    let cartStickers: [String]
    let onSelect: (String) -> Void
    @Binding var selectedDecorationId: String?

    var body: some View {
        GardenItemPicker(items: ItemDataManager.shared.getAllDecorations().filter { cartStickers.contains($0.id) },
                         placeholder: "Tìm đồ trang trí trong kho…".tr,
                         selection: $selectedDecorationId, onSelect: onSelect)
    }
}

struct DecorationItemRow: View {
    let decoration: ItemData
    let isSelected: Bool
    let onSelect: () -> Void
    var body: some View {
        GardenInventoryRow(item: decoration, isSelected: isSelected, onSelect: onSelect)
    }
}

import SwiftUI

/// Shared inventory styling for plants, pots, and decorations.
struct GardenItemPicker: View {
    let items: [ItemData]
    let placeholder: String
    @Binding var selection: String?
    let onSelect: (String) -> Void
    var recommendedItemId: String? = nil
    var disabledMessages: [String: String] = [:]
    @State private var query = ""

    private var results: [ItemData] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = items.filter { text.isEmpty || $0.name.tr.localizedStandardContains(text) || $0.description.tr.localizedStandardContains(text) }
        return filtered.filter { $0.id == recommendedItemId } + filtered.filter { $0.id != recommendedItemId }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(AccountStyle.green)
                TextField(placeholder, text: $query)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AccountStyle.ink)
                    .submitLabel(.search)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(AccountStyle.muted)
                    }
                    .accessibilityLabel("Xóa tìm kiếm".tr)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(AccountStyle.border, lineWidth: 1) }
            .padding(.horizontal, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    if results.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "basket").font(.title2).foregroundStyle(AccountStyle.green)
                            Text(query.isEmpty ? "Kho đồ đang trống".tr : "Chưa tìm thấy vật phẩm".tr)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(AccountStyle.ink)
                            Text(query.isEmpty ? "Ghé cửa hàng để thêm đồ cho khu vườn nhé.".tr : "Thử một tên hoặc mô tả khác nhé.".tr)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(AccountStyle.muted)
                        }
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                    }
                    ForEach(results) { item in
                        let disabledMsg = disabledMessages[item.id]
                        GardenInventoryRow(item: item, isSelected: selection == item.id, onSelect: {
                            guard disabledMsg == nil else { return }
                            selection = item.id
                            onSelect(item.id)
                        }, recommendationText: item.id == recommendedItemId ? "Gợi ý · Oxygen ×2.5".tr : nil, disabledText: disabledMsg)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 2)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

struct GardenInventoryRow: View {
    let item: ItemData
    let isSelected: Bool
    let onSelect: () -> Void
    var recommendationText: String? = nil
    var disabledText: String? = nil

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                CachedAsyncImage(named: item.image) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: item.type == "plant" ? "leaf.fill" : "shippingbox.fill")
                        .foregroundStyle(AccountStyle.green.opacity(0.5))
                }
                .padding(5)
                .frame(width: 56, height: 64)
                .background(AccountStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    if let recommendationText {
                        Label(recommendationText, systemImage: "sparkles")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.green)
                    }
                    Text(item.name.tr)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                    Text(item.description.tr)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .lineLimit(2)
                    if let disabledText {
                        Label(disabledText, systemImage: "exclamationmark.circle.fill")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.danger)
                    } else if !item.displayEffect.isEmpty && item.displayEffect != "N.A" {
                        Label(item.displayEffect, systemImage: "sparkles")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(AccountStyle.green)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    Image(systemName: disabledText != nil ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                        .font(.system(size: 20))
                        .foregroundStyle(disabledText != nil ? AccountStyle.muted : (isSelected ? AccountStyle.green : AccountStyle.border))
                    HStack(spacing: 3) {
                        Image("oxygen").resizable().scaledToFit().frame(width: 14, height: 14)
                        Text(item.priceOxygen.formatted())
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            .padding(10)
            .opacity(disabledText != nil ? 0.65 : 1.0)
            .background(isSelected ? Color(hex: "F1F4DF") : AccountStyle.cream, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? AccountStyle.green : AccountStyle.border, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(disabledText != nil)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

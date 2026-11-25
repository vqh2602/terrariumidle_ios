import SwiftUI

struct EffectsSheetView: View {
    @ObservedObject private var fireStore = FireStoreService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var backgroundRive: String
    @Binding var overlayRive: String?

    private let landscapes = ItemDataManager.shared.getAllLandscapes()
    private let effects = ItemDataManager.shared.getAllEffects()
    @State private var category: Category = .landscapes
    @State private var searchText = ""
    @State private var unlockedOnly = true

    private enum Category: String, CaseIterable {
        case landscapes = "Phong cảnh"
        case effects = "Hiệu ứng"
    }

    private var unlockedIds: Set<String> {
        MusicUnlockHelper.getUnlockedMusicIds(from: fireStore.gradenModel)
    }

    private var categoryItems: [ItemData] {
        category == .landscapes ? landscapes : effects
    }

    private var visibleItems: [ItemData] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return categoryItems.filter { item in
            (!unlockedOnly || unlockedIds.contains(item.id)) &&
            (query.isEmpty || item.name.tr.localizedStandardContains(query) || item.description.tr.localizedStandardContains(query))
        }
    }

    private func isItemSelected(_ selectedId: String?, matches item: ItemData) -> Bool {
        guard let selectedId = selectedId, !selectedId.isEmpty else { return false }
        if selectedId == item.image || selectedId == item.id {
            return true
        }
        if selectedId.hasPrefix("i_") && String(selectedId.dropFirst(2)) == item.image {
            return true
        }
        if item.image.hasPrefix("i_") && selectedId == String(item.image.dropFirst(2)) {
            return true
        }
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                controls
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(visibleItems) { item in
                            let locked = !unlockedIds.contains(item.id)
                            EffectCardView(
                                item: item,
                                isSelected: isItemSelected(category == .landscapes ? backgroundRive : overlayRive, matches: item),
                                isLocked: locked
                            ) {
                                guard !locked else { return }
                                if category == .landscapes {
                                    backgroundRive = item.image
                                } else {
                                    overlayRive = item.image
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 24)
                    if visibleItems.isEmpty {
                        emptyState
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                // Each category/filter starts at the top of its own result set.
                .id("\(category.rawValue)-\(unlockedOnly)-\(searchText)")
            }
            .background {
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
            .navigationTitle("Phong cảnh & Hiệu ứng".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong".tr) { dismiss() }
                        .fontWeight(.bold)
                        .tint(AccountStyle.green)
                }
            }
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AccountStyle.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Picker("Danh mục".tr, selection: $category) {
                ForEach(Category.allCases, id: \.self) { category in
                    Text(category.rawValue.tr).tag(category)
                }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AccountStyle.green)
                    TextField("Tìm cảnh, hiệu ứng…".tr, text: $searchText)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AccountStyle.ink)
                        .submitLabel(.search)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AccountStyle.muted)
                        }
                        .accessibilityLabel("Xóa tìm kiếm".tr)
                    }
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 40)
                .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(AccountStyle.border, lineWidth: 1) }
                Menu {
                    Toggle("Chỉ hiện mục đã mở khóa".tr, isOn: $unlockedOnly)
                    if category == .effects {
                        Button("Tắt hiệu ứng".tr, systemImage: "nosign") { overlayRive = nil }
                            .disabled(overlayRive == nil)
                    }
                    Text("%d / %d lựa chọn".tr(visibleItems.count, categoryItems.count))
                } label: {
                    Image(systemName: unlockedOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 23))
                        .foregroundStyle(AccountStyle.green)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Bộ lọc, %@".tr(unlockedOnly ? "chỉ hiện đã mở khóa".tr : "hiện tất cả".tr))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 32))
                .foregroundStyle(AccountStyle.green)
            Text("Chưa có lựa chọn phù hợp".tr)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AccountStyle.ink)
            Text(unlockedOnly ? "Thử tắt bộ lọc Đã mở khóa hoặc đổi từ khóa tìm kiếm.".tr : "Thử tìm bằng một tên hoặc mô tả khác nhé.".tr)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
        }
        .multilineTextAlignment(.center)
        .padding(24)
    }
}

private struct EffectCardView: View {
    let item: ItemData
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    private var thumbnailImageName: String {
        // 1. Thử trực tiếp tên item.image (ví dụ "i_sky_sun_day", "i_overlay1")
        if UIImage(named: item.image) != nil {
            return item.image
        }
        // 2. Thử thêm tiền tố "i_" nếu chưa có (ví dụ "sky_sun_day" -> "i_sky_sun_day", "overlay1" -> "i_overlay1")
        let prefixed = item.image.hasPrefix("i_") ? item.image : "i_\(item.image)"
        if UIImage(named: prefixed) != nil {
            return prefixed
        }
        // 3. Thử bỏ tiền tố "i_" nếu có
        if item.image.hasPrefix("i_") {
            let stripped = String(item.image.dropFirst(2))
            if UIImage(named: stripped) != nil {
                return stripped
            }
        }
        return item.image
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 96, height: 58)
                    .overlay {
                        Image(thumbnailImageName).resizable().scaledToFill()
                    }
                    .clipped()
                    .overlay {
                        if isLocked {
                            Color.black.opacity(0.3)
                            Image(systemName: "lock.fill").foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name.tr)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(isLocked ? "Chưa mở khóa".tr : item.description.tr)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AccountStyle.green)
                }
            }
            .padding(10)
            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected && !isLocked ? AccountStyle.green : AccountStyle.border,
                                  lineWidth: isSelected && !isLocked ? 2 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel("\(item.name.tr). \(item.description.tr). \(isLocked ? "Chưa mở khóa".tr : (isSelected ? "Đang dùng".tr : "Chạm để chọn".tr))")
        .accessibilityAddTraits(isSelected && !isLocked ? [.isSelected] : [])
    }
}

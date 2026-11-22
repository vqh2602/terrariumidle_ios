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
            (query.isEmpty || item.name.localizedStandardContains(query) || item.description.localizedStandardContains(query))
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
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 280 : 88), spacing: 8)], spacing: 8) {
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
            .navigationTitle("Phong cảnh & Hiệu ứng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
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
            Picker("Danh mục", selection: $category) {
                ForEach(Category.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AccountStyle.green)
                    TextField("Tìm cảnh, hiệu ứng…", text: $searchText)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AccountStyle.ink)
                        .submitLabel(.search)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AccountStyle.muted)
                        }
                        .accessibilityLabel("Xóa tìm kiếm")
                    }
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 40)
                .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(AccountStyle.border, lineWidth: 1) }
                Menu {
                    Toggle("Chỉ hiện mục đã mở khóa", isOn: $unlockedOnly)
                    if category == .effects {
                        Button("Tắt hiệu ứng", systemImage: "nosign") { overlayRive = nil }
                            .disabled(overlayRive == nil)
                    }
                    Text("\(visibleItems.count) / \(categoryItems.count) lựa chọn")
                } label: {
                    Image(systemName: unlockedOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 23))
                        .foregroundStyle(AccountStyle.green)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Bộ lọc, \(unlockedOnly ? "chỉ hiện đã mở khóa" : "hiện tất cả")")
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
            Text("Chưa có lựa chọn phù hợp")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(AccountStyle.ink)
            Text(unlockedOnly ? "Thử tắt bộ lọc Đã mở khóa hoặc đổi từ khóa tìm kiếm." : "Thử tìm bằng một tên hoặc mô tả khác nhé.")
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
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(2.0, contentMode: .fit)
                    .overlay {
                        Image(thumbnailImageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .overlay {
                        if isLocked {
                            Color.black.opacity(0.28)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected && !isLocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AccountStyle.green, AccountStyle.cream)
                                .padding(5)
                        }
                    }
                Text(item.name)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AccountStyle.ink)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .topLeading)
                    .padding(7)
            }
            .background(AccountStyle.cream)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected && !isLocked ? AccountStyle.green : AccountStyle.border,
                                  lineWidth: isSelected && !isLocked ? 2.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .accessibilityLabel("\(item.name). \(item.description). \(isLocked ? "Chưa mở khóa" : (isSelected ? "Đang dùng" : "Chạm để chọn"))")
        .accessibilityAddTraits(isSelected && !isLocked ? [.isSelected] : [])
    }
}

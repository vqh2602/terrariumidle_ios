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
            VStack(spacing: 14) {
                controls
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 280 : 130), spacing: 12)], spacing: 12) {
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
                    .padding(.horizontal, 20)
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
        VStack(spacing: 12) {
            Picker("Danh mục", selection: $category) {
                ForEach(Category.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AccountStyle.green)
                TextField("Tìm tên hoặc mô tả…", text: $searchText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(AccountStyle.ink)
                    .submitLabel(.search)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AccountStyle.muted)
                            .frame(minWidth: 32, minHeight: 32)
                    }
                    .accessibilityLabel("Xóa tìm kiếm")
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(AccountStyle.border, lineWidth: 1) }
            HStack(spacing: 12) {
                Toggle("Đã mở khóa", isOn: $unlockedOnly)
                    .toggleStyle(.button)
                    .tint(AccountStyle.green)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                Spacer(minLength: 0)
                Text("\(visibleItems.count) lựa chọn")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
                if category == .effects {
                    Button { overlayRive = nil } label: {
                        Label("Tắt", systemImage: "nosign")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                    }
                    .tint(AccountStyle.green)
                    .disabled(overlayRive == nil)
                    .accessibilityLabel("Tắt hiệu ứng đang dùng")
                }
            }
            .frame(minHeight: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
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
                    .aspectRatio(16.0 / 10.0, contentMode: .fit)
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
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AccountStyle.green, AccountStyle.cream)
                                .padding(8)
                        }
                    }
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .lineLimit(2)
                        .frame(minHeight: 40, alignment: .topLeading)
                    Text(isLocked ? "Chưa mở khóa" : (isSelected ? "Đang dùng" : "Chạm để chọn"))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(isSelected && !isLocked ? AccountStyle.green : AccountStyle.muted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AccountStyle.cream)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
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

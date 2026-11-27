import SwiftUI

struct MailboxView: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var store = MailboxStore.shared
    @State private var selectedFilter: Filter = .all
    @State private var selectedItem: MailboxItem?

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case event
        case update
        case system

        var id: Self { self }
        var title: String {
            switch self {
            case .all: return "Tất cả".tr
            case .event: return "Sự kiện".tr
            case .update: return "Cập nhật".tr
            case .system: return "Hệ thống".tr
            }
        }
    }

    private var filteredItems: [MailboxItem] {
        switch selectedFilter {
        case .all:
            return store.items
        case .event:
            return store.items.filter { $0.category == .event || $0.category == .gift }
        case .update:
            return store.items.filter { $0.category == .update }
        case .system:
            return store.items.filter { $0.category == .system || $0.category == .unknown }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
            content
        }
        .foregroundStyle(AccountStyle.ink)
        .background(AccountStyle.cream.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await store.loadIfNeeded() }
        .sheet(item: $selectedItem) { item in
            MailboxDetailSheet(item: item) { action in
                selectedItem = nil
                handleAction(action)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button { router.pop() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quay lại".tr)

            Spacer()

            VStack(spacing: 2) {
                Text("Hòm thư".tr)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                if store.unreadCount > 0 {
                    Text("%d thư chưa đọc".tr(store.unreadCount))
                        .font(.caption)
                        .foregroundStyle(AccountStyle.green)
                }
            }

            Spacer()

            if store.unreadCount > 0 {
                Button {
                    AudioPlayer.shared.playTap()
                    store.markAllAsRead()
                } label: {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AccountStyle.green)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Đánh dấu đã đọc tất cả".tr)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { filter in
                    let active = selectedFilter == filter
                    Button {
                        AudioPlayer.shared.playTap()
                        selectedFilter = filter
                    } label: {
                        Text(filter.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(active ? AccountStyle.cream : AccountStyle.green)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(active ? AccountStyle.green : AccountStyle.cream, in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(active ? AccountStyle.green : AccountStyle.border, lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.items.isEmpty {
            Spacer()
            ProgressView("Đang tải hòm thư…".tr)
            Spacer()
        } else if let error = store.error, store.items.isEmpty {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AccountStyle.muted)
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AccountStyle.muted)
                Button("Thử lại".tr) {
                    Task { await store.reload() }
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.cream)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AccountStyle.green, in: Capsule())
            }
            .padding()
            Spacer()
        } else if filteredItems.isEmpty {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 36))
                    .foregroundStyle(AccountStyle.green.opacity(0.7))
                Text("Chưa có thông báo nào".tr)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
            }
            .padding(32)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if let error = store.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AccountStyle.muted)
                    }
                    ForEach(filteredItems) { item in
                        mailRow(item)
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
            .refreshable { await store.reload() }
        }
    }

    private func mailRow(_ item: MailboxItem) -> some View {
        let localized = item.localized()
        let isRead = store.isRead(item)

        return Button {
            AudioPlayer.shared.playTap()
            store.markAsRead(item)
            selectedItem = item
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Label(item.category.title, systemImage: item.category.icon)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(item.category.tint)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(item.category.tint.opacity(0.12), in: Capsule())

                    if item.pinned == true {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(AccountStyle.green)
                    }

                    Spacer()

                    Text(item.date)
                        .font(.caption)
                        .foregroundStyle(AccountStyle.muted)

                    if !isRead {
                        Circle()
                            .fill(Color(hex: "D95D39"))
                            .frame(width: 9, height: 9)
                    }
                }

                Text(localized?.title ?? "Thông báo".tr)
                    .font(.system(.headline, design: .rounded, weight: isRead ? .semibold : .bold))
                    .foregroundStyle(AccountStyle.ink)
                    .multilineTextAlignment(.leading)

                if let summary = localized?.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(AccountStyle.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                HStack {
                    Text(item.sender ?? "Ban quản trị Terrarium".tr)
                        .font(.caption)
                        .foregroundStyle(AccountStyle.muted)
                    Spacer()
                    Text("Xem chi tiết →".tr)
                        .font(.caption.bold())
                        .foregroundStyle(AccountStyle.green)
                }
            }
            .padding(16)
            .background(isRead ? Color.white.opacity(0.55) : Color.white.opacity(0.92),
                        in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(isRead ? AccountStyle.border.opacity(0.75) : AccountStyle.green.opacity(0.55),
                                  lineWidth: isRead ? 1 : 1.5)
            }
            .shadow(color: AccountStyle.border.opacity(isRead ? 0.35 : 0.65), radius: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func handleAction(_ action: MailboxItem.Action) {
        switch action.type.lowercased() {
        case "route":
            switch action.target.lowercased() {
            case "events", "event": router.push(.eventView)
            case "store": router.push(.storeView)
            case "discovery": router.push(.discoveryView)
            case "vip", "subscription": router.push(.subscriptionView)
            case "account": router.push(.accountView)
            default: break
            }
        case "url":
            if let url = URL(string: action.target), url.scheme == "https" {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }
}

private struct MailboxDetailSheet: View {
    let item: MailboxItem
    let onAction: (MailboxItem.Action) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let localized = item.localized()

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Label(item.category.title, systemImage: item.category.icon)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(item.category.tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(item.category.tint.opacity(0.12), in: Capsule())

                        Spacer()

                        Text(item.date)
                            .font(.caption)
                            .foregroundStyle(AccountStyle.muted)
                    }

                    Text(localized?.title ?? "Thông báo".tr)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)

                    Text("Từ: %@".tr(item.sender ?? "Ban quản trị Terrarium".tr))
                        .font(.caption)
                        .foregroundStyle(AccountStyle.muted)

                    if let imageStr = localized?.image, !imageStr.isEmpty {
                        CachedAsyncImage(named: imageStr) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } placeholder: {
                            EmptyView()
                        }
                    }

                    if let bodyText = localized?.body, !bodyText.isEmpty {
                        Text(bodyText)
                            .font(.body)
                            .foregroundStyle(AccountStyle.ink)
                            .lineSpacing(4)
                    }

                    if let highlights = localized?.highlights, !highlights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(highlights, id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "leaf.fill")
                                        .font(.caption)
                                        .foregroundStyle(AccountStyle.green)
                                        .padding(.top, 4)
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundStyle(AccountStyle.ink)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }

                    if let action = item.action {
                        Button {
                            AudioPlayer.shared.playTap()
                            onAction(action)
                        } label: {
                            Text(localized?.actionLabel ?? "Mở ngay →".tr)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AccountStyle.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(AccountStyle.green, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(20)
            }
            .background(AccountStyle.cream.ignoresSafeArea())
            .navigationTitle("Chi tiết thư".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng".tr) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MailboxView()
        .environmentObject(AppRouter())
}

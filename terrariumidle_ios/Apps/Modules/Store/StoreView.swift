import FirebaseAuth
import SwiftUI

struct StoreView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: StoreViewModel
    @StateObject private var fireStore: FireStoreService = .shared
    private let initialItemId: String?

    init(auth: AuthService = AuthService.shared, initialItemId: String? = nil) {
        self.initialItemId = initialItemId
        _viewModel = StateObject(wrappedValue: StoreViewModel(auth: auth))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            userStatsBar
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            tabSelector
                .padding(.bottom, 16)
            searchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            if viewModel.isLoading {
                Spacer()
                ProgressView("Đang chăm chút gian hàng…".tr)
                    .tint(AccountStyle.green)
                    .foregroundStyle(AccountStyle.muted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        HStack {
                            Label(viewModel.selectedTab.rawValue.tr, systemImage: tabIcon(viewModel.selectedTab))
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AccountStyle.ink)
                            Spacer()
                            Text("%d vật phẩm".tr(viewModel.filteredItems.count))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(AccountStyle.muted)
                        }
                        .padding(.horizontal, 4)
                        if viewModel.filteredItems.isEmpty {
                            emptyState
                        }
                        ForEach(viewModel.filteredItems) { item in
                            StoreItemCard(
                                item: item,
                                isOwned: viewModel.isOwned(item: item),
                                canAfford: viewModel.canAfford(item: item),
                                meetsLevelRequirement: viewModel.meetsLevelRequirement(item: item),
                                onPurchase: { item in
                                    Task { await viewModel.purchaseItem(item) }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background {
            LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .task {
            // Load user data
            guard let userId = AuthService.shared.currentUser?.uid else { return }
            _ = await fireStore.getDataById(userId: userId)

            // Load initial items
            if let initialItemId, let pot = ItemDataManager.shared.getPot(byId: initialItemId) {
                viewModel.loadItems(for: .pots)
                viewModel.searchText = pot.name.tr
            } else if let initialItemId, let plant = ItemDataManager.shared.getPlant(byId: initialItemId) {
                viewModel.loadItems(for: .plants)
                viewModel.searchText = plant.name.tr
            } else {
                viewModel.loadItems(for: .plants)
            }
        }
        .alert("Lỗi".tr, isPresented: $viewModel.hasError) {
            Button("OK".tr, role: .cancel) {
                viewModel.hasError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 3) {
                Text("Cửa hàng".tr)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("THÊM XANH CHO GÓC VƯỜN".tr)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AccountStyle.green)
            }
            HStack {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .frame(width: 44, height: 44)
                        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                        }
                        .compositingGroup()
                        .shadow(color: AccountStyle.border, radius: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quay lại".tr)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var userStatsBar: some View {
        // The wallet has its own row below the navigation bar. Equal-width cells
        // and single-line values keep all five resources inside narrow screens.
        HStack(spacing: 6) {
            StoreResourceBadge(icon: "oxygen", title: "Oxy", value: fireStore.gradenModel?.money.oxygen ?? 0)
            StoreResourceBadge(icon: "gemstone", title: "Đá quý".tr, value: fireStore.gradenModel?.money.gemstone ?? 0)
            StoreResourceBadge(icon: "ticket", title: "Vé".tr, value: fireStore.gradenModel?.money.ticket ?? 0)
            StoreResourceBadge(icon: "shovel", title: "Xẻng".tr, value: fireStore.gradenModel?.item.shovel ?? 0)
            StoreResourceBadge(icon: "fertilizer", title: "Phân bón".tr, value: fireStore.gradenModel?.item.fertilizer ?? 0)
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(StoreTab.allCases, id: \.self) { tab in
                    Button { viewModel.loadItems(for: tab) } label: {
                        Label(tab.rawValue.tr, systemImage: tabIcon(tab))
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(viewModel.selectedTab == tab ? AccountStyle.cream : AccountStyle.green)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(viewModel.selectedTab == tab ? AccountStyle.green : AccountStyle.cream,
                                        in: Capsule())
                            .overlay { Capsule().strokeBorder(AccountStyle.green.opacity(0.25), lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.selectedTab == tab ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AccountStyle.green)
            TextField("Tìm vật phẩm cho khu vườn…".tr, text: $viewModel.searchText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.ink)
                .submitLabel(.search)
            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AccountStyle.muted)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .accessibilityLabel("Xóa tìm kiếm".tr)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .background(AccountStyle.cream.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(AccountStyle.border, lineWidth: 1.5) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.searchText.isEmpty ? "basket" : "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(AccountStyle.green)
            Text(viewModel.searchText.isEmpty ? "Gian hàng đang trống".tr : "Chưa tìm thấy vật phẩm".tr)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.ink)
            Text(viewModel.searchText.isEmpty ? "Bạn thử ghé qua danh mục khác nhé!".tr : "Thử tìm bằng một tên khác nhé!".tr)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .modifier(AccountPanel())
    }

    private func tabIcon(_ tab: StoreTab) -> String {
        switch tab {
        case .plants: return "leaf.fill"
        case .pots: return "archivebox.fill"
        case .decorations: return "sparkles"
        case .gemstones: return "diamond.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        }
    }
}

struct StoreResourceBadge: View {
    let icon: String
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 5) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
            Text(compactValue)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(AccountStyle.ink)
                .frame(maxWidth: .infinity)
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(AccountStyle.muted)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 10)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(AccountStyle.border, lineWidth: 1) }
        .compositingGroup()
        .shadow(color: AccountStyle.border.opacity(0.6), radius: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value.formatted())")
    }

    private var compactValue: String {
        let magnitude = Double(value)
        for (threshold, suffix) in [(1_000_000_000.0, "b"), (1_000_000.0, "m"), (1_000.0, "k")] {
            if magnitude >= threshold {
                return String(format: "%.1f%@", magnitude / threshold, suffix)
            }
        }
        return "\(value)"
    }
}

#Preview("Ví tài nguyên · 320pt".tr) {
    HStack(spacing: 6) {
        StoreResourceBadge(icon: "oxygen", title: "Oxy", value: 272_100_000)
        StoreResourceBadge(icon: "gemstone", title: "Đá quý".tr, value: 799_900_000)
        StoreResourceBadge(icon: "ticket", title: "Vé".tr, value: 6_585_800_000)
        StoreResourceBadge(icon: "shovel", title: "Xẻng".tr, value: 32)
        StoreResourceBadge(icon: "fertilizer", title: "Phân bón".tr, value: 11_800)
    }
    .padding(.horizontal, 20)
    .frame(width: 320)
    .padding(.vertical)
    .background(Color(hex: "E9EED9"))
}

import FirebaseAuth
import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var model: DiscoveryViewModel
    @State private var selected: DiscoveredProfile?
    @State private var listPosition = ScrollPosition(edge: .top)
    private let repository: any DiscoveryReading

    init() {
        let repository = DiscoveryRepository()
        self.repository = repository
        _model = StateObject(wrappedValue: DiscoveryViewModel(repository: repository, ownID: AuthService.shared.currentUser?.uid))
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            categories
                .padding(.horizontal, 20)
            if model.category == .world {
                searchField.padding(.horizontal, 20)
            }
            gardenList
        }
        .foregroundStyle(AccountStyle.ink)
        .background {
            LinearGradient(colors: [Color(hex: "E5ECD6"), AccountStyle.cream, Color(hex: "F4E7CF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Image("leaf_emerald_1")
                        .resizable().scaledToFit().frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-35)).opacity(0.10)
                        .offset(x: 65, y: -30)
                        .accessibilityHidden(true)
                }
        }
        .navigationBarHidden(true)
        .task(id: model.requestKey) { await model.loadIfNeeded() }
        .fullScreenCover(item: $selected) { profile in
            VisitorGardenView(profile: profile, repository: repository) { gardenID, total in
                model.updateLikes(gardenID: gardenID, total: total)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            headerButton("chevron.left", label: "Quay lại".tr) { router.pop() }
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                Text("Khám phá".tr)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                HStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                    Text("KẾT NỐI NHỮNG GÓC XANH".tr).tracking(1.3)
                }
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(AccountStyle.green)
            }
            Spacer(minLength: 0)
            headerButton("arrow.clockwise", label: "Tải lại danh sách".tr) { model.refresh() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    private var categories: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                 count: dynamicTypeSize.isAccessibilitySize ? 2 : 4), spacing: 10) {
            ForEach(DiscoveryCategory.allCases) { category in
                let active = model.category == category
                Button { model.category = category } label: {
                    VStack(spacing: 7) {
                        Image(systemName: category.gardenIcon)
                            .font(.system(size: 19, weight: .bold))
                            .frame(height: 23)
                        Text(category.rawValue.tr)
                            .font(.system(.caption2, design: .rounded, weight: .heavy))
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(active ? AccountStyle.cream : category.gardenTint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 17)
                            .fill(active ? AccountStyle.green : AccountStyle.cream.opacity(0.85))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 17)
                            .strokeBorder(active ? Color(hex: "3F6033") : AccountStyle.border, lineWidth: 1.5)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 13).strokeBorder(.white.opacity(active ? 0.20 : 0.65), lineWidth: 1)
                            .padding(4)
                    }
                    .shadow(color: active ? Color(hex: "3F6033") : AccountStyle.border.opacity(0.65), radius: 0, y: 3)
                }
                .buttonStyle(DiscoveryPressStyle())
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AccountStyle.green)
            TextField("Tìm khu vườn bằng ID…".tr, text: $model.searchID)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .submitLabel(.search).onSubmit { model.search() }
            if !model.searchID.isEmpty || !model.submittedID.isEmpty {
                Button { model.resetSearch() } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(AccountStyle.muted)
                    .accessibilityLabel("Xóa tìm kiếm".tr)
            }
            Button { model.search() } label: {
                Text("Tìm".tr).font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.cream)
                    .padding(.horizontal, 17).frame(minHeight: 40)
                    .background(AccountStyle.green, in: RoundedRectangle(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "3F6033"), lineWidth: 1) }
            }.buttonStyle(DiscoveryPressStyle())
        }
        .padding(8).padding(.leading, 6)
        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 19))
        .overlay { RoundedRectangle(cornerRadius: 19).strokeBorder(AccountStyle.border, lineWidth: 1.5) }
        .shadow(color: AccountStyle.border.opacity(0.45), radius: 0, y: 3)
    }

    private var gardenList: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: model.category == .world ? "leaf.circle.fill" : "rosette")
                    .foregroundStyle(model.category.gardenTint)
                Text(model.category == .world ? "Vườn quanh đây".tr : "Bảng xếp hạng".tr)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                Spacer()
                Text("GHÉ THĂM & KHÁM PHÁ".tr)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .tracking(0.7).foregroundStyle(AccountStyle.muted)
            }.padding(.horizontal, 24)

            ScrollView {
                LazyVStack(spacing: 16) {
                    if let error = model.error {
                        messageCard(icon: "cloud.drizzle.fill", title: "Chờ một chút nhé".tr, detail: error)
                        Button("Thử lại".tr) { model.refresh() }
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    }
                    if model.profiles.isEmpty && !model.isLoading && model.error == nil {
                        messageCard(icon: "leaf.circle", title: "Chưa tìm thấy khu vườn".tr,
                                    detail: "Thử ID khác hoặc khám phá thêm những góc xanh mới nhé.".tr)
                    }
                    ForEach(model.profiles) { profile in
                        let isOwn = model.isOwn(profile)
                        if isOwn {
                            DiscoveryProfileCard(profile: profile, isOwnProfile: true)
                        } else {
                            Button { selected = profile } label: {
                                DiscoveryProfileCard(profile: profile)
                            }
                            .buttonStyle(DiscoveryPressStyle())
                            .accessibilityHint("Ghé thăm khu vườn này".tr)
                        }
                    }
                    if model.isLoading {
                        ProgressView("Đang tìm những góc xanh…".tr)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .tint(AccountStyle.green).padding(20)
                    }
                    if model.nextCursor != nil && !model.isLoading {
                        Button { Task { await model.load(more: true) } } label: {
                            Label("Khám phá thêm".tr, systemImage: "leaf.fill")
                                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                                .foregroundStyle(AccountStyle.green)
                                .padding(.horizontal, 24).padding(.vertical, 14)
                                .background(AccountStyle.cream, in: Capsule())
                                .overlay { Capsule().strokeBorder(AccountStyle.border, lineWidth: 1.5) }
                                .shadow(color: AccountStyle.border.opacity(0.55), radius: 0, y: 3)
                        }.buttonStyle(DiscoveryPressStyle()).padding(.top, 4)
                    }
                }
                .frame(maxWidth: 600).padding(.horizontal, 20)
                .padding(.top, 4).padding(.bottom, 28).frame(maxWidth: .infinity)
            }
            .scrollPosition($listPosition)
            .scrollIndicators(.hidden)
        }
    }

    private func headerButton(_ icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 17, weight: .bold))
                .frame(width: 44, height: 44)
                .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 15))
                .overlay { RoundedRectangle(cornerRadius: 15).strokeBorder(AccountStyle.border, lineWidth: 1.5) }
                .shadow(color: AccountStyle.border.opacity(0.7), radius: 0, y: 3)
        }.buttonStyle(DiscoveryPressStyle()).accessibilityLabel(label)
    }

    private func messageCard(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 34)).foregroundStyle(AccountStyle.green)
            Text(title).font(.system(.headline, design: .rounded, weight: .heavy))
            Text(detail).font(.system(.subheadline, design: .rounded)).foregroundStyle(AccountStyle.muted)
        }
        .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(24)
        .modifier(AccountPanel())
    }
}

private extension DiscoveryCategory {
    var gardenIcon: String {
        switch self {
        case .world: return "globe.asia.australia.fill"
        case .likes: return "heart.fill"
        case .level: return "star.fill"
        case .oxygen: return "wind"
        }
    }
    var gardenTint: Color {
        switch self {
        case .world: return AccountStyle.green
        case .likes: return Color(hex: "BC796C")
        case .level: return Color(hex: "AD813C")
        case .oxygen: return Color(hex: "608F99")
        }
    }
}

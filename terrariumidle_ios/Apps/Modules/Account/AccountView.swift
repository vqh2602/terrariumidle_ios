import SwiftUI

struct AccountView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = AccountViewModel()
    @StateObject private var fireStore: FireStoreService = .shared
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var showOnboardingGuide = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 26) {
                    if let user = fireStore.gradenModel?.user {
                        ProfileCard(
                            userName: user.userName,
                            userEmail: user.userEmail,
                            userID: user.userID,
                            userLevel: user.userLevel,
                            userLikes: user.userTotalLike,
                            userAvatar: user.userAvatar
                        )
                    }
                    settingsSection
                    AccountReminderCard()
                    servicesSection
                    accountSection
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                        Text("Một góc vườn nhỏ, một chút bình yên".tr)
                    }
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AccountStyle.muted)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    graphicsCredits
                }
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Image("leaf_emerald_1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-30))
                        .opacity(0.10)
                        .offset(x: 45, y: 40)
                        .accessibilityHidden(true)
                }
        }
        .navigationBarHidden(true)
        .alert("Đăng xuất".tr, isPresented: $viewModel.showSignOutConfirmation) {
            Button("Hủy".tr, role: .cancel) {}
            Button("Đăng xuất".tr, role: .destructive) {
                viewModel.signOut()
                router.replaceRoot(.loginView(id: ""))
            }
        } message: {
            Text("Bạn có chắc chắn muốn đăng xuất?".tr)
        }
        .alert("Xóa tài khoản".tr, isPresented: $viewModel.showDeleteConfirmation) {
            Button("Hủy".tr, role: .cancel) {}
            Button("Xóa".tr, role: .destructive) {
                viewModel.deleteAccount()
            }
        } message: {
            Text("Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.".tr)
        }
        .fullScreenCover(isPresented: $showOnboardingGuide) {
            OnboardingView(isReplay: true) {
                showOnboardingGuide = false
            }
            .environmentObject(router)
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 3) {
                Text("Tài khoản".tr)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("GÓC NHỎ CỦA BẠN".tr)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(2)
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

    private var settingsSection: some View {
        section(title: "Thiết lập khu vườn".tr, icon: "slider.horizontal.3") {
            languagePickerRow
            rowDivider
            SettingsRow(title: "Đồng bộ dữ liệu".tr, icon: "arrow.triangle.2.circlepath") {
                viewModel.syncData()
            }
            rowDivider
            SettingsRow(
                title: "Hiệu suất cao".tr, icon: "bolt.fill",
                trailingContent: .toggle(Binding(
                    get: { viewModel.highPerformanceMode },
                    set: { value in
                        if value != viewModel.highPerformanceMode { viewModel.toggleHighPerformance() }
                    }
                ))
            )
            rowDivider
            SettingsRow(
                title: "Chế độ phòng cảnh".tr, icon: "house.fill",
                trailingContent: .toggle(Binding(
                    get: { viewModel.roomSceneMode },
                    set: { value in
                        if value != viewModel.roomSceneMode { viewModel.toggleRoomScene() }
                    }
                ))
            )
        }
    }

    private var languagePickerRow: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    localization.currentLanguage = language
                } label: {
                    if language == localization.currentLanguage {
                        Label("\(language.flag) \(language.nativeName)", systemImage: "checkmark")
                    } else {
                        Text("\(language.flag) \(language.nativeName)")
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AccountStyle.green)
                    .frame(width: 36, height: 36)
                    .background(AccountStyle.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                Text("Ngôn ngữ".tr)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AccountStyle.ink)
                Spacer(minLength: 4)
                HStack(spacing: 6) {
                    Text("\(localization.currentLanguage.flag) \(localization.currentLanguage.nativeName)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AccountStyle.muted)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AccountStyle.muted)
                        .frame(width: 26, height: 26)
                        .background(AccountStyle.border.opacity(0.28), in: Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var servicesSection: some View {
        section(title: "Đồng hành cùng bạn".tr, icon: "sparkles") {
            SettingsRow(title: "Hướng dẫn khu vườn".tr, icon: "sparkles.rectangle.stack.fill") {
                showOnboardingGuide = true
            }
            rowDivider
            SettingsRow(title: "Đánh giá ứng dụng".tr, icon: "star.fill") { viewModel.openRateApp() }
            rowDivider
            SettingsRow(title: "Cẩm nang khu vườn · Wiki".tr, icon: "book.closed.fill") { viewModel.openWiki() }
            rowDivider
            SettingsRow(title: "Liên hệ hỗ trợ".tr, icon: "bubble.left.and.bubble.right.fill") { viewModel.contactSupport() }
            rowDivider
            SettingsRow(title: "Chính sách bảo mật".tr, icon: "checkmark.shield.fill") { viewModel.openPrivacyPolicy() }
            rowDivider
            SettingsRow(title: "Điều khoản sử dụng".tr, icon: "doc.text.fill") { viewModel.openTermsOfUse() }
        }
    }

    private var accountSection: some View {
        section(title: "Quản lý tài khoản".tr, icon: "person.crop.circle") {
            SettingsRow(title: "Đăng xuất".tr, icon: "rectangle.portrait.and.arrow.right") {
                viewModel.requestSignOut()
            }
            rowDivider
            SettingsRow(title: "Xóa tài khoản".tr, icon: "trash", isDestructive: true) {
                viewModel.requestDeleteAccount()
            }
        }
    }

    private var graphicsCredits: some View {
        VStack(spacing: 6) {
            Text("Nguồn tài nguyên đồ họa".tr)
                .font(.system(.caption, design: .rounded, weight: .semibold))
            Text("Hình ảnh của rattanachomphoo trên Magnific".tr)
                .font(.system(.caption2, design: .rounded))
        }
        .foregroundStyle(AccountStyle.muted)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(AccountStyle.border.opacity(0.55))
            .frame(height: 1)
            .padding(.leading, 66)
            .padding(.trailing, 18)
    }

    private func section<Content: View>(title: String, icon: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.green)
                .padding(.leading, 8)
            VStack(spacing: 0, content: content)
                .padding(.vertical, 5)
                .modifier(AccountPanel())
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppRouter())
}

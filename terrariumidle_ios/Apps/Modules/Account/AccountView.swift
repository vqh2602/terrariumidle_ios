import SwiftUI

struct AccountView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = AccountViewModel()
    @StateObject private var fireStore: FireStoreService = .shared

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
                    servicesSection
                    accountSection
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                        Text("Một góc vườn nhỏ, một chút bình yên")
                    }
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AccountStyle.muted)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
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
        .alert("Đăng xuất", isPresented: $viewModel.showSignOutConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Đăng xuất", role: .destructive) {
                viewModel.signOut()
                router.replaceRoot(.loginView(id: ""))
            }
        } message: {
            Text("Bạn có chắc chắn muốn đăng xuất?")
        }
        .alert("Xóa tài khoản", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) {
                viewModel.deleteAccount()
            }
        } message: {
            Text("Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.")
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 3) {
                Text("Tài khoản")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("GÓC NHỎ CỦA BẠN")
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
                .accessibilityLabel("Quay lại")
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var settingsSection: some View {
        section(title: "Thiết lập khu vườn", icon: "slider.horizontal.3") {
            SettingsRow(title: "Đồng bộ dữ liệu", icon: "arrow.triangle.2.circlepath") {
                viewModel.syncData()
            }
            rowDivider
            SettingsRow(
                title: "Hiệu suất cao", icon: "bolt.fill",
                trailingContent: .toggle(Binding(
                    get: { viewModel.highPerformanceMode },
                    set: { value in
                        if value != viewModel.highPerformanceMode { viewModel.toggleHighPerformance() }
                    }
                ))
            )
            rowDivider
            SettingsRow(
                title: "Chế độ phòng cảnh", icon: "house.fill",
                trailingContent: .toggle(Binding(
                    get: { viewModel.roomSceneMode },
                    set: { value in
                        if value != viewModel.roomSceneMode { viewModel.toggleRoomScene() }
                    }
                ))
            )
        }
    }

    private var servicesSection: some View {
        section(title: "Đồng hành cùng bạn", icon: "sparkles") {
            SettingsRow(title: "Đánh giá ứng dụng", icon: "star.fill") { viewModel.openRateApp() }
            rowDivider
            SettingsRow(title: "Cẩm nang khu vườn · Wiki", icon: "book.closed.fill") { viewModel.openWiki() }
            rowDivider
            SettingsRow(title: "Liên hệ hỗ trợ", icon: "bubble.left.and.bubble.right.fill") { viewModel.contactSupport() }
            rowDivider
            SettingsRow(title: "Chính sách bảo mật", icon: "checkmark.shield.fill") { viewModel.openPrivacyPolicy() }
            rowDivider
            SettingsRow(title: "Điều khoản sử dụng", icon: "doc.text.fill") { viewModel.openTermsOfUse() }
        }
    }

    private var accountSection: some View {
        section(title: "Quản lý tài khoản", icon: "person.crop.circle") {
            SettingsRow(title: "Đăng xuất", icon: "rectangle.portrait.and.arrow.right") {
                viewModel.requestSignOut()
            }
            rowDivider
            SettingsRow(title: "Xóa tài khoản", icon: "trash", isDestructive: true) {
                viewModel.requestDeleteAccount()
            }
        }
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

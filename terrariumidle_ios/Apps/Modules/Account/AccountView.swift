//
//  AccountView.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = AccountViewModel()
    @StateObject private var fireStore: FireStoreService = .shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - Header

                header
                    .padding(.horizontal, 16)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    .padding(.bottom, 16)
                    .background(.background)

                // MARK: - Content ScrollView

                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Card
                        if let user = fireStore.gradenModel?.user {
                            ProfileCard(
                                userName: user.userName,
                                userEmail: user.userEmail,
                                userID: user.userID,
                                userLevel: user.userLevel,
                                userLikes: user.userTotalLike,
                                userAvatar: user.userAvatar
                            )
                            .padding(.horizontal, 16)
                        }

                        // Settings Section
                        settingsSection

                        // Services Section
                        servicesSection

                        // Social Media Icons
                        socialMediaIcons
                            .padding(.vertical, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .top)
        }
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

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            // Title
            Text("Tài khoản")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

//            // Gemstone badge
//            if let gemstone = fireStore.gradenModel?.money.gemstone {
//                HStack(spacing: 6) {
//                    Image("gemstone")
//                        .resizable()
//                        .frame(width: 20, height: 20)
//                    Text("\(gemstone)")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundColor(.primary)
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(Color.yellow.opacity(0.2))
//                )
//            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Thiết lập")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Settings Items
            VStack(spacing: 1) {
                SettingsRow(
                    title: "Đồng bộ dữ liệu",
                    trailingContent: .chevron
                ) {
                    viewModel.syncData()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Chế độ hiệu suất cao (Bật)",
                    trailingContent: .toggle($viewModel.highPerformanceMode)
                ) {
                    viewModel.toggleHighPerformance()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Chế độ kịch mỡ phòng cảnh (Bật)",
                    trailingContent: .toggle($viewModel.roomSceneMode)
                ) {
                    viewModel.toggleRoomScene()
                }
            }
            .background(.regularMaterial)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Services Section

    private var servicesSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Dịch vụ")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Service Items
            VStack(spacing: 1) {
                SettingsRow(
                    title: "Đánh giá ứng dụng",
                    trailingContent: .chevron
                ) {
                    viewModel.openRateApp()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Wiki",
                    trailingContent: .chevron
                ) {
                    viewModel.openWiki()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Liên hệ hỗ trợ",
                    trailingContent: .chevron
                ) {
                    viewModel.contactSupport()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Chính sách bảo mật",
                    trailingContent: .chevron
                ) {
                    viewModel.openPrivacyPolicy()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Điều khoản sử dụng",
                    trailingContent: .chevron
                ) {
                    viewModel.openTermsOfUse()
                }

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Xóa tài khoản",
                    isDestructive: true,
                    trailingContent: .chevron
                ) {
                    viewModel.requestDeleteAccount()
                } .background(.regularMaterial)

                Divider().padding(.leading, 16)

                SettingsRow(
                    title: "Đăng xuất",
                    isDestructive: true,
                    trailingContent: .chevron
                ) {
                    viewModel.requestSignOut()
                } .background(.regularMaterial)
            }
            .background(.regularMaterial)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Social Media Icons

    private var socialMediaIcons: some View {
        HStack(spacing: 32) {
            // Facebook
            Button(action: {
                // TODO: Add Facebook link
            }) {
                Image(systemName: "f.square.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.6))
            }

            // Instagram
            Button(action: {
                // TODO: Add Instagram link
            }) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.5))
            }

            // Discord
            Button(action: {
                // TODO: Add Discord link
            }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.45, green: 0.53, blue: 0.93))
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppRouter())
}

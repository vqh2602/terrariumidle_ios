//
//  SplashViewModel.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 4/2/26.
//
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class SplashViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Trạng thái loading khi đang đăng nhập
    @Published var isLoading = false

    /// Có lỗi xảy ra hay không
    @Published var hasError = false

    /// Message lỗi để hiển thị
    @Published var errorMessage: String?

    /// User đã đăng nhập thành công
    @Published var isAuthenticated = false

    /// Thông tin user hiện tại
    @Published var currentUser: User?

    // MARK: - Dependencies

    private let auth: AuthService
    private let router: AppRouter

    // MARK: - Init

    init(auth: AuthService, router: AppRouter) {
        self.auth = auth
        self.router = router
        currentUser = auth.currentUser
        print("user hiện tại: \(currentUser?.email ?? "n/a")")
    }

    // MARK: - Methods

    /// Kiểm tra auth và tự động chuyển trang sau 3 giây
    /// Đồng thời preload SpriteKit texture & scene cache trong background
    func checkAuthAndNavigate() async {
        // Chạy song song: delay 3s + preload SpriteKit assets
        // Preload thường hoàn thành trong < 3s nên không tốn thêm thời gian chờ
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
            group.addTask {
                await SpriteKitPreloader.shared.preload()
            }
            // Chờ cả 2 task hoàn thành (sleep chắc chắn là task lâu hơn)
            await group.waitForAll()
        }

        let hasSession = currentUser?.uid != nil
        isAuthenticated = hasSession
        let nextRoute = OnboardingStorage.postSplashRoute(isAuthenticated: hasSession)
        router.replaceRoot(nextRoute)
        print("isAuthenticated: \(isAuthenticated), nextRoute: \(nextRoute)")
    }
}

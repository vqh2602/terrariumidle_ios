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
    func checkAuthAndNavigate() async {
        // Delay 3 giây
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3000ms = 3 giây

        if currentUser?.uid != nil {
            isAuthenticated = true
            router.replaceRoot(.homeView)
        } else {
            isAuthenticated = false
            router.replaceRoot(.loginView(id: ""))
        }
        print("isAuthenticated: \(isAuthenticated)")
    }
}

//
//  LoginViewModel.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

import Combine
import FirebaseAuth
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
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

    // MARK: - Init

    init(auth: AuthService) {
          self.auth = auth
          self.currentUser = auth.currentUser
          print("user hiện tại: \(currentUser?.email ?? "n/a")")
      }

    // MARK: - Apple Sign-In

    /// Đăng nhập bằng Apple ID
    /// Hàm này GỌI AuthService.startSignInWithAppleFlow với completion handler
    func loginWithApple() {
        print("📱 [LoginViewModel] loginWithApple() called")

        // Reset error state
        hasError = false
        errorMessage = nil
        isLoading = true

        print("📱 [LoginViewModel] Calling AuthService.startSignInWithAppleFlow...")

        // Gọi AuthService với completion handler
        auth.startSignInWithAppleFlow { [weak self] result in
            print("📱 [LoginViewModel] Received callback from AuthService")

            // Callback được gọi trên background thread, cần chuyển về main thread
            Task { @MainActor in
                self?.isLoading = false

                switch result {
                case let .success(user):
                    // Đăng nhập thành công
                    print("✅ [LoginViewModel] Apple Sign-In thành công!")
                    print("   UID: \(user.uid)")
                    print("   Email: \(user.email ?? "N/A")")
                    print("   Display Name: \(user.displayName ?? "N/A")")

                    self?.currentUser = user
                    self?.isAuthenticated = true

                    // (Optional) Lấy token để gọi API backend
                    self?.fetchUserToken()

                case let .failure(error):
                    // Đăng nhập thất bại
                    print("❌ [LoginViewModel] Apple Sign-In thất bại: \(error.localizedDescription)")

                    self?.hasError = true
                    self?.errorMessage = error.localizedDescription
                    self?.isAuthenticated = false
                }
            }
        }
    }

    // MARK: - Email/Password Login

    /// Đăng nhập bằng email và password
    func login(email: String, password: String) async {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và password"
            hasError = true
            return
        }

        hasError = false
        errorMessage = nil
        isLoading = true

        do {
            let (token, user) = try await auth.login(username: email, password: password)

            print("✅ Đăng nhập email thành công!")
            print("   Token: \(token)")

            currentUser = user
            isAuthenticated = true
            isLoading = false

        } catch {
            print("❌ Đăng nhập email thất bại: \(error.localizedDescription)")

            errorMessage = error.localizedDescription
            hasError = true
            isAuthenticated = false
            isLoading = false
        }
    }

    // MARK: - Logout

    /// Đăng xuất
    func logout() {
        do {
            try auth.logout()

            currentUser = nil
            isAuthenticated = false

            print("✅ Đăng xuất thành công")

        } catch {
            print("❌ Đăng xuất thất bại: \(error.localizedDescription)")

            errorMessage = error.localizedDescription
            hasError = true
        }
    }

    // MARK: - Helper Methods

    /// Lấy Firebase token của user hiện tại
    private func fetchUserToken() {
        Task {
            do {
                let token = try await auth.getCurrentUserToken()
                print("🔑 Firebase Token: \(token)")

                // TODO: Gọi API backend với token này
                // Example:
                // await callBackendAPI(token: token)

            } catch {
                print("⚠️ Không thể lấy token: \(error.localizedDescription)")
            }
        }
    }
}

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
    private let fireStore: FireStoreService

    // MARK: - Init

    init(auth: AuthService) {
        self.auth = auth
        currentUser = auth.currentUser
        fireStore = .shared
    
        print("user hiện tại: \(currentUser?.email ?? "n/a")")
    }

    // MARK: - Apple Sign-In

    /// Đăng nhập bằng Apple ID
    /// Hàm này GỌI AuthService.startSignInWithAppleFlow với completion handler
    ///
    func loginWithApple() async -> User? {
        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await auth.startSignInWithAppleFlowAsync()
            currentUser = user
            isAuthenticated = true
            fetchUserToken()
            fetchCurrentUser()
            return user
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            isAuthenticated = false
            return nil
        }
    }

    //    func  loginWithApple() {
    //        print("📱 [LoginViewModel] loginWithApple() called")
    //
    //        // Reset error state
    //        hasError = false
    //        errorMessage = nil
    //        isLoading = true
    //
    //        print("📱 [LoginViewModel] Calling AuthService.startSignInWithAppleFlow...")
    //
    //        // Gọi AuthService với completion handler
    //        auth.startSignInWithAppleFlow { [weak self] result in
    //            print("📱 [LoginViewModel] Received callback from AuthService")
    //
    //            // Callback được gọi trên background thread, cần chuyển về main thread
    //            Task { @MainActor in
    //                self?.isLoading = false
    //
    //                switch result {
    //                case let .success(user):
    //                    // Đăng nhập thành công
    //                    print("✅ [LoginViewModel] Apple Sign-In thành công!")
    //                    print("   UID: \(user.uid)")
    //                    print("   Email: \(user.email ?? "N/A")")
    //                    print("   Display Name: \(user.displayName ?? "N/A")")
    //
    //                    self?.currentUser = user
    //                    self?.isAuthenticated = true
    //
    //                    // (Optional) Lấy token để gọi API backend
    //                    self?.fetchUserToken()
    //
    //                case let .failure(error):
    //                    // Đăng nhập thất bại
    //                    print("❌ [LoginViewModel] Apple Sign-In thất bại: \(error.localizedDescription)")
    //
    //                    self?.hasError = true
    //                    self?.errorMessage = error.localizedDescription
    //                    self?.isAuthenticated = false
    //                }
    //            }
    //        }
    //    }

    // MARK: - Google Sign-In

    /// Đăng nhập bằng Google
    func loginWithGoogle() async -> User? {
        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await auth.signInWithGoogle()
            currentUser = user
            isAuthenticated = true
            fetchUserToken()
            fetchCurrentUser()
            return user
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            isAuthenticated = false
            return nil
        }
    }

    // MARK: - Guest Sign-In

    /// Đăng nhập với tư cách khách (Anonymous Auth)
    func loginAsGuest() async -> User? {
        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await auth.signInAsGuest()
            currentUser = user
            isAuthenticated = true
            fetchUserToken()
            fetchCurrentUser()
            return user
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            isAuthenticated = false
            return nil
        }
    }

    // MARK: - Email/Password Login & Register

    /// Đăng nhập bằng email và password
    func login(email: String, password: String) async -> User? {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và mật khẩu".tr
            hasError = true
            return nil
        }

        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let (token, user) = try await auth.login(username: email, password: password)

            print("✅ Đăng nhập email thành công!")
            print("   Token: \(token)")

            currentUser = user
            isAuthenticated = true
            fetchUserToken()
            fetchCurrentUser()
            return user
        } catch {
            print("❌ Đăng nhập email thất bại: \(error.localizedDescription)")

            errorMessage = error.localizedDescription
            hasError = true
            isAuthenticated = false
            return nil
        }
    }

    /// Đăng ký tài khoản mới bằng email và password
    func register(email: String, password: String) async -> User? {
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và mật khẩu".tr
            hasError = true
            return nil
        }

        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let (token, user) = try await auth.register(email: email, password: password)

            print("✅ Đăng ký email thành công!")
            print("   Token: \(token)")

            currentUser = user
            isAuthenticated = true
            fetchUserToken()
            fetchCurrentUser()
            return user
        } catch {
            print("❌ Đăng ký email thất bại: \(error.localizedDescription)")

            errorMessage = error.localizedDescription
            hasError = true
            isAuthenticated = false
            return nil
        }
    }

    /// Gửi email đặt lại mật khẩu
    func sendPasswordReset(email: String) async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Vui lòng nhập email".tr
            hasError = true
            return false
        }

        hasError = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(email: trimmed)
            return true
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            return false
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
///lấy dữ liệu user, nếu chưa có thì sẽ tạo mới
    private func fetchCurrentUser() {
        Task {
            do {
                guard let uid = currentUser?.uid else { return }
                //                let data =  await fireStore.getDataById(userId: uid)
                guard (await fireStore.getDataById(userId: uid)) != nil else {
                    print("‼️ User chưa có đang tạo mới: \(currentUser?.uid ?? "")")
                    try await fireStore.createDataUser(email: currentUser?.email ?? "", name: currentUser?.displayName, id: uid)
                    return
                }
                print("✅ User đã có k cần tạo mới")
            }
        }
    }
}

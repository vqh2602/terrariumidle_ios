//
//  AuthViewModel.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 30/1/26.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupAuthStateListener()
        checkCurrentUser()
    }

    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Management

    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isSignedIn = (user != nil)
            }
        }
    }

    private func checkCurrentUser() {
        currentUser = AuthService.shared.currentUser
        isSignedIn = (currentUser != nil)
    }

    // MARK: - Sign In with Apple

    func signInWithApple() {
        isLoading = true
        errorMessage = nil

        AuthService.shared.startSignInWithAppleFlow { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false

                switch result {
                case let .success(user):
                    print("✅ Đăng nhập thành công")
                    print("   UID: \(user.uid)")
                    print("   Email: \(user.email ?? "N/A")")
                    print("   Display Name: \(user.displayName ?? "N/A")")

                    self?.currentUser = user
                    self?.isSignedIn = true

                    // Lấy token để sử dụng
                    self?.fetchUserToken()

                case let .failure(error):
                    print("❌ Đăng nhập thất bại: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }
        }
    }

    // MARK: - Sign In with Email/Password

    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và password"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let (token, user) = try await AuthService.shared.login(
                    username: email,
                    password: password
                )

                print("✅ Đăng nhập thành công")
                print("   Token: \(token)")

                currentUser = user
                isSignedIn = true
                isLoading = false

            } catch {
                handleError(error)
                isLoading = false
            }
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try AuthService.shared.logout()
            currentUser = nil
            isSignedIn = false
            print("✅ Đăng xuất thành công")
        } catch {
            handleError(error)
        }
    }

    // MARK: - Token Management

    func fetchUserToken() {
        Task {
            do {
                let token = try await AuthService.shared.getCurrentUserToken()
                print("🔑 Firebase Token: \(token)")
                // Có thể lưu token vào UserDefaults hoặc Keychain nếu cần
                // hoặc gọi API backend với token này
            } catch {
                print("⚠️ Không thể lấy token: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }

    // MARK: - User Info

    var userDisplayName: String {
        currentUser?.displayName ?? "Unknown"
    }

    var userEmail: String {
        currentUser?.email ?? "No email"
    }

    var userId: String {
        currentUser?.uid ?? ""
    }

    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? false
    }
}

// MARK: - Example Usage in SwiftUI

/*

 import SwiftUI

 struct LoginView: View {
     @StateObject private var viewModel = AuthViewModel()
     @State private var email = ""
     @State private var password = ""

     var body: some View {
         if viewModel.isSignedIn {
             // Màn hình đã đăng nhập
             ProfileView(viewModel: viewModel)
         } else {
             // Màn hình đăng nhập
             LoginFormView(
                 viewModel: viewModel,
                 email: $email,
                 password: $password
             )
         }
     }
 }

 struct LoginFormView: View {
     @ObservedObject var viewModel: AuthViewModel
     @Binding var email: String
     @Binding var password: String

     var body: some View {
         VStack(spacing: 20) {
             Text("Đăng nhập")
                 .font(.largeTitle)
                 .bold()

             // Email/Password Login
             VStack(spacing: 15) {
                 TextField("Email", text: $email)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .autocapitalization(.none)
                     .keyboardType(.emailAddress)

                 SecureField("Password", text: $password)
                     .textFieldStyle(RoundedBorderTextFieldStyle())

                 Button("Đăng nhập") {
                     viewModel.signIn(email: email, password: password)
                 }
                 .buttonStyle(.borderedProminent)
                 .disabled(viewModel.isLoading)
             }

             Divider()

             // Apple Sign-In
             Button {
                 viewModel.signInWithApple()
             } label: {
                 HStack {
                     Image(systemName: "applelogo")
                     Text("Đăng nhập với Apple")
                 }
                 .frame(maxWidth: .infinity)
                 .padding()
                 .background(Color.black)
                 .foregroundColor(.white)
                 .cornerRadius(10)
             }
             .disabled(viewModel.isLoading)

             if viewModel.isLoading {
                 ProgressView()
             }
         }
         .padding()
         .alert("Lỗi", isPresented: $viewModel.showError) {
             Button("OK") { }
         } message: {
             Text(viewModel.errorMessage ?? "Unknown error")
         }
     }
 }

 struct ProfileView: View {
     @ObservedObject var viewModel: AuthViewModel

     var body: some View {
         VStack(spacing: 20) {
             Image(systemName: "person.circle.fill")
                 .font(.system(size: 100))
                 .foregroundColor(.blue)

             Text(viewModel.userDisplayName)
                 .font(.title)
                 .bold()

             Text(viewModel.userEmail)
                 .font(.subheadline)
                 .foregroundColor(.secondary)

             Text("UID: \(viewModel.userId)")
                 .font(.caption)
                 .foregroundColor(.secondary)

             Button("Đăng xuất") {
                 viewModel.signOut()
             }
             .buttonStyle(.borderedProminent)
             .tint(.red)
         }
         .padding()
     }
 }

 */

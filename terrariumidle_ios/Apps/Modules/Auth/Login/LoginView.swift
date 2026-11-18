//
//  LoginView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

import Combine

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var loginViewModel: LoginViewModel = .init(auth: AuthService.shared)
    @State private var showEmailSheet = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    Image("logo").resizable()
                        .scaledToFit().frame(
                            width: 200, // 30% chiều rộng màn hình
                            height: 200 // 30% chiều rộng màn hình
                        ).padding(20)
                    Text("Terrarium idle").textStyle(.title1).foregroundColor(AppColors.primary).fontWeight(.bold)
                    Spacer()
                    Text("Đăng nhập để tiếp tục sử dụng ứng dụng").textStyle(.caption1).foregroundColor(.black)
                    Spacer().frame(height: 20)

                    if loginViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .padding(.bottom, 10)
                    }

                    if let error = loginViewModel.errorMessage, loginViewModel.hasError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }

                    ButtonLogin(title: "Đăng nhập bằng google", icon: "google-fill", action: {
                        if let _ = await loginViewModel.loginWithGoogle() {
                            router.replaceRoot(.homeView)
                        }
                    })
                    ButtonLogin(title: "Đăng nhập bằng apple", icon: "apple-fill", action: {
                        let data = await loginViewModel.loginWithApple()
                        if data != nil {
                            router.replaceRoot(.homeView)
                        }
                    })
                    ButtonLogin(title: "Đăng nhập bằng email", icon: "shield-user-fill", action: {
                        showEmailSheet = true
                    })
                    Spacer().frame(height: 40)
                    Text("Khi bạn đăng nhập sẽ đồng ý với các điều khoản của chúng tôi").textStyle(.caption1).foregroundColor(.gray).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(AppColors.backgroundLogin)
                    .navigationBarHidden(true) // Ẩn thanh navigation và nút back

                RiveViewModel(
                    fileName: "overlay1",
                    fit: .cover
                ).view()
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                .allowsHitTesting(false) // ⭐️ Cho phép click xuyên qua animation overlay
            }
            .sheet(isPresented: $showEmailSheet) {
                EmailAuthSheet(viewModel: loginViewModel) {
                    router.replaceRoot(.homeView)
                }
            }
        }
    }
}

struct ButtonLogin: View {
    var title: String
    var icon: String? = nil
    var action: () async -> Void
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(icon).resizable().scaledToFit().frame(width: 20, height: 20)
                }
                Text(title).font(.system(size: 16, weight: .light)).foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .background(.clear)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

// MARK: - Email Auth Bottom Sheet
struct EmailAuthSheet: View {
    @ObservedObject var viewModel: LoginViewModel
    var onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isRegisterMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var validationError: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundLogin
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Picker("Chế độ", selection: $isRegisterMode) {
                            Text("Đăng nhập").tag(false)
                            Text("Đăng ký").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.top, 10)
                        .onChange(of: isRegisterMode) { _ in
                            validationError = nil
                            viewModel.errorMessage = nil
                            viewModel.hasError = false
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                TextField("example@gmail.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Mật khẩu")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                SecureField("Nhập mật khẩu", text: $password)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            if isRegisterMode {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Xác nhận mật khẩu")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    SecureField("Nhập lại mật khẩu", text: $confirmPassword)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }

                        if let error = validationError ?? viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button {
                            Task {
                                await handleAction()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 6)
                                }
                                Text(isRegisterMode ? "Tạo tài khoản" : "Đăng nhập")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top, 10)

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isRegisterMode ? "Đăng ký" : "Đăng nhập")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    private func handleAction() async {
        validationError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            validationError = "Vui lòng nhập email"
            return
        }
        guard !password.isEmpty else {
            validationError = "Vui lòng nhập mật khẩu"
            return
        }
        if isRegisterMode {
            guard password == confirmPassword else {
                validationError = "Mật khẩu xác nhận không khớp"
                return
            }
            guard password.count >= 6 else {
                validationError = "Mật khẩu phải có ít nhất 6 ký tự"
                return
            }
            if let _ = await viewModel.register(email: trimmedEmail, password: password) {
                dismiss()
                onSuccess()
            }
        } else {
            if let _ = await viewModel.login(email: trimmedEmail, password: password) {
                dismiss()
                onSuccess()
            }
        }
    }
}

#Preview {
    LoginView()
}

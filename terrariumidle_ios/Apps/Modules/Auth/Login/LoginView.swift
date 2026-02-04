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
    @StateObject private var loginViewModel: LoginViewModel = .init(auth: AuthService.shared)
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack {
                        Image("logo").resizable()
                            .scaledToFit().frame(
                                width: geometry.size.width * 0.8, // 30% chiều rộng màn hình
                                height: geometry.size.width * 0.8 // 30% chiều rộng màn hình
                            ).padding(20)
                        Text("Terrarium idle").textStyle(.title1).foregroundColor(.black)
                        Spacer()
                        Text("Đăng nhập để tiếp tục sử dụng ứng dụng").font(.system(size: 16, weight: .light)).foregroundColor(.black)
                        Spacer().frame(height: 20)
                        ButtonLogin(title: "Đăng nhập bằng google", icon: "google-fill", action: {})
                        ButtonLogin(title: "Đăng nhập bằng apple", icon: "apple-fill", action: {
                            loginViewModel.loginWithApple()
                        })
                        ButtonLogin(title: "Đăng nhập bằng email", icon: "shield-user-fill", action: {})
                        Spacer().frame(height: 40)
                        Text("Khi bạn đăng nhập sẽ đồng ý với các điều khoản của chúng tôi").font(.system(size: 12, weight: .light)).foregroundColor(.black).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .background(AppColors.backgroundLogin)
                        .navigationTitle("Đăng nhập")
                        .navigationBarTitleDisplayMode(.inline)

                    // RiveUIView ở trên cùng, hiển thị toàn màn hình
                    RiveUIView(rive: {
                        let worker = Worker()
                        let file = try await File(source: .local("overlay1", Bundle.main), worker: worker)
                        return try await Rive(file: file)
                    }).view()
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height) // Chiếm toàn bộ không gian
                        .ignoresSafeArea(.all) // Full màn hình, bao gồm status bar
                        .allowsHitTesting(false) // Chỉ hiển thị, không cho phép thao tác

                    // QuickStartView().frame(maxWidth: 100, maxHeight: 100, alignment: .top)
                }
            }
        }
    }
}

struct ButtonLogin: View {
    var title: String
    var icon: String? = nil
    var action: () -> Void
    var body: some View {
        Button {
            print("Đăng nhập")
            print(Bundle.main.url(forResource: "overlay1", withExtension: "riv") as Any)
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(icon).resizable().scaledToFit().frame(width: 20, height: 20)
                }
                Text(title).font(.system(size: 16, weight: .light)).foregroundColor(.black)
            }
        }.padding(10).background(.clear)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

#Preview {
    LoginView()
}

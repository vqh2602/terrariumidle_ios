//
//  SplashView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 4/2/26.
//

import SwiftUI

struct SplashView: View {
    @ObservedObject var router: AppRouter
    @StateObject private var splashViewModel: SplashViewModel
    @ObservedObject private var appIconManager = AppIconManager.shared

    init(router: AppRouter, auth: AuthService = .shared) {
        self.router = router
        _splashViewModel = StateObject(wrappedValue: SplashViewModel(auth: auth, router: router))
    }

    var body: some View {
        Group {
            GeometryReader { geometry in
                VStack {
                    Image(appIconManager.currentSplashImageName).resizable()
                        .scaledToFit()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: appIconManager.currentIcon == .defaultIcon ? 0 : 36
                            )
                        )
                        .frame(
                            width: 200, // 30% chiều rộng màn hình
                            height: 200 // 30% chiều rộng màn hình
                        ).padding(20)
                }.frame( width:geometry.size.width  , height: geometry.size.height , alignment: .center).background(AppColors.backgroundLogin)
            }
        }
        .onAppear {
            Task {
                await splashViewModel.checkAuthAndNavigate()
            }
        }
    }
}

#Preview {
    SplashView(router: AppRouter())
}

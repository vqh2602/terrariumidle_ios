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

    init(router: AppRouter, auth: AuthService = .shared) {
        self.router = router
        _splashViewModel = StateObject(wrappedValue: SplashViewModel(auth: auth, router: router))
    }

    var body: some View {
        Group {
            Text("Splash")
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

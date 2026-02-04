//
//  SplashView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 4/2/26.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var router: AppRouter
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Button("Nút trang chủ") {
            router.push(.homeView)
        }
        Button("Nút trang chủ") {
            router.replaceRoot(.homeView)
        }
        Button("Nút trang chủ") {
            router.push(.loginView(id: ""))
        }
    }
}

#Preview {
    SplashView()
}

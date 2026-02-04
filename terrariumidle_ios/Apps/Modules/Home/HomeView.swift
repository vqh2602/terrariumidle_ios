//
//  HomeView.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//

@_spi(RiveExperimental) import RiveRuntime
import SwiftUI

import Combine

struct HomeView: View {
    @StateObject private var loginViewModel: LoginViewModel = .init(auth: AuthService.shared)
    var body: some View {
        GeometryReader { geometry in
            let itemWidth = (geometry.size.width - 32) / 3.0
            ZStack {
                HStack(spacing: 0) {
                    Image("r1").resizable()
                        .scaledToFill().frame(
                            width: 16, // 30% chiều rộng màn hình
                            height: geometry.size.height // 30% chiều rộng màn hình
                        )
                   
                    ScrollView {
                        ForEach(1 ... 30, id: \.self) {
                            
                            _ in VStack(spacing: 0) {
                                HStack(spacing: 4,) {
                                    ForEach(1 ... 3, id: \.self) {
                                        _ in VStack(spacing: 0) {
                                            PlantRiveView(width: itemWidth,)
                                            PotRiveView(width: itemWidth,height: 75)
                                        }.frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }.frame(alignment: Alignment.center)

                                Image("r2").resizable()
                                    .scaledToFill().frame(
                                        width: geometry.size.width - 32,
                                        // 30% chiều rộng màn hình
                                        height: 16 // 30% chiều rộng màn hình
                                    )
                            }
                            .rotationEffect(.degrees(180)) // Xoay nội dung 180 độ
                        }
                    }
                    .rotationEffect(.degrees(180)) // Xoay ScrollView 180 độ để scroll từ dưới lên
                    Image("r1").resizable()
                        .scaledToFill().frame(
                            width: 16, // 30% chiều rộng màn hình
                            height: geometry.size.height // 30% chiều rộng màn hình
                        ).scaleEffect(x: -1, y: 1) // 👈 lật ngang
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(AppColors.backgroundLogin)
                    .navigationTitle("Đăng nhập")
                    .ignoresSafeArea(.all) // Full màn hình, bao gồm status bar
                    .navigationBarTitleDisplayMode(.inline)

            }.frame(alignment: .leading)
        }.ignoresSafeArea(.all) // Full màn hình, bao gồm status bar
    }
}

#Preview {
    HomeView()
}

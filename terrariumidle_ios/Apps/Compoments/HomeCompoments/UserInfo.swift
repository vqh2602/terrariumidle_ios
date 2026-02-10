//
//  UserInfo.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 8/2/26.
//

import SwiftUI

struct UserInfoCompoment: View {
    @State private var progress: Float = 0.7
    @StateObject var fireStore: FireStoreService = .shared
    var body: some View {
        HStack {
            Button {} label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level: 1").textStyle(.bodyMedium)
                    ProgressView(value: progress)
                        .progressViewStyle(.linear).frame(
                            width: 70,
                            //                        height: 10
                        )
                }.foregroundColor(.black).padding(8)
                    //                    .frame(width: 56, height: 56)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(1)))
                    .shadow(radius: 6)
            }
            Spacer()
            HStack {
                Button {} label: {
                    HStack(spacing: 16,) {
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.oxygen ?? 0), image: "oxygen")
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.gemstone ?? 0), image: "gemstone")
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.item.fertilizer ?? 0), image: "fertilizer")
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.item.shovel ?? 0), image: "shovel")
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.ticket ?? 0), image: "ticket")
                    }.padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }
            }.background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(1))).padding(4).shadow(radius: 6)
        }.frame(
            width: .infinity,
            height: .infinity
        ).padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
    }
}

private struct UserItemData: View {
    let title: String
    let image: String
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(image).resizable()
                .frame(width: 25, height: 25).padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))

            Text(title).textStyle(.caption1).bold()
        }.foregroundColor(.black).padding(0)
    }
}

#Preview {
    UserInfoCompoment()
}

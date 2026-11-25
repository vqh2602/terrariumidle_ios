//
//  SelectedItemPreview.swift
//  terrariumidle_ios
//
//  Created by AI on 10/2/26.
//

import SwiftUI

struct SelectedItemPreview: View {
    let item: ItemData
    let type: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Item Image
            CachedAsyncImage(named: item.image) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.12))
                    Image(systemName: item.type == "plant" ? "leaf" : (item.type == "pot" ? "shippingbox" : "photo"))
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .frame(width: 32, height: 32)
            .cornerRadius(6)

            // Item Info
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(.caption)
                    .foregroundColor(AccountStyle.muted)
                Text(item.name.tr)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AccountStyle.ink)
            }

            Spacer()

            // Price
            HStack(spacing: 4) {
                Image("oxygen")
                    .resizable()
                    .frame(width: 16, height: 16)
                Text("\(item.priceOxygen)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AccountStyle.green)
            }

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AccountStyle.muted)
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Bỏ chọn %@".tr(item.name.tr))
        }
        .fontDesign(.rounded)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AccountStyle.cream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AccountStyle.border, lineWidth: 1)
        )
    }
}

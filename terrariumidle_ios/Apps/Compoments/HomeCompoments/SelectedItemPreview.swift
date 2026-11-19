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
            .frame(width: 40, height: 40)
            .cornerRadius(6)

            // Item Info
            VStack(alignment: .leading, spacing: 2) {
                Text(type)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
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
                    .foregroundColor(.green)
            }

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

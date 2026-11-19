//
//  StoreItemCard.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

struct StoreItemCard: View {
    let item: ItemData
    let isOwned: Bool
    let canAfford: Bool
    let meetsLevelRequirement: Bool
    let onPurchase: (ItemData) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Item Image
            CachedAsyncImage(named: item.image) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.12))
                    Image(systemName: item.type == "plant" ? "leaf" : (item.type == "pot" ? "shippingbox" : "photo"))
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)

                if item.effect != "N.A" && !item.effect.isEmpty {
                    Text("Hiệu ứng: \(item.effect)")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }

                // Level requirement
                if !meetsLevelRequirement {
                    Text("Cấp độ mở khóa: \(item.levelUnlock)")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Purchase Button
            purchaseButton
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isOwned {
            // Already owned
            Text("Đã sở hữu")
                .textStyle(.bodyMedium)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                )
        } else if !meetsLevelRequirement {
            // Level requirement not met
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(.gray)
        } else {
            // Can purchase
            Button(action: {
                onPurchase(item)
            }) {
                HStack(spacing: 4) {
                    currencyIcon(for: item.currencyUnit)
                        .font(.system(size: 14))

                    Text("\(item.priceStore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canAfford ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                )
            }
            .disabled(!canAfford)
        }
    }

    private func currencyIcon(for currency: String) -> some View {
        Group {
            switch currency {
            case "oxygen":
                Image("oxygen")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.green)
            case "gemstone":
                Image( "gemstone")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
            case "ticket":
                Image( "ticket")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.orange)
            default:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}

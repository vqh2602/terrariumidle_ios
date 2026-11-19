//
//  PotSelectionView.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

struct PotSelectionView: View {
    let cartPots: [String]
    let onSelect: (String) -> Void
    @Binding var selectedPotId: String?

    @State private var searchText: String = ""

    private var availablePots: [ItemData] {
        let allPots = ItemDataManager.shared.getAllPots()
        var filtered = allPots.filter { cartPots.contains($0.id) }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Tìm kiếm", text: $searchText)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)

            // Pots List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(availablePots) { pot in
                        PotItemRow(
                            pot: pot,
                            isSelected: selectedPotId == pot.id,
                            onSelect: {
                                selectedPotId = pot.id
                                onSelect(pot.id)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Pot Item Row

struct PotItemRow: View {
    let pot: ItemData
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Pot Image
                CachedAsyncImage(named: pot.image) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.12))
                        VStack(spacing: 2) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 16))
                                .foregroundColor(Color.orange.opacity(0.80))
                            Text("<update>")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                // Pot Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pot.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(pot.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    if pot.effect != "N.A" && !pot.effect.isEmpty {
                        Text("Hiệu ứng: \(pot.effect)")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // Price
                HStack(spacing: 4) {
                    Image("oxygen")
                        .resizable()
                        .frame(width: 16, height: 16)

                    Text("\(pot.priceOxygen)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.15) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//
//  DecorationSelectionView.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

struct DecorationSelectionView: View {
    let cartStickers: [String]
    let onSelect: (String) -> Void
    @Binding var selectedDecorationId: String?

    @State private var searchText: String = ""

    private var availableDecorations: [ItemData] {
        let allDecorations = ItemDataManager.shared.getAllDecorations()
        var filtered = allDecorations.filter { cartStickers.contains($0.id) }

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

            // Decorations List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(availableDecorations) { decoration in
                        DecorationItemRow(
                            decoration: decoration,
                            isSelected: selectedDecorationId == decoration.id,
                            onSelect: {
                                selectedDecorationId = decoration.id
                                onSelect(decoration.id)
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

// MARK: - Decoration Item Row

struct DecorationItemRow: View {
    let decoration: ItemData
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Decoration Image
                CachedAsyncImage(named: decoration.image) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                // Decoration Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(decoration.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(decoration.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    if decoration.effect != "N.A" && !decoration.effect.isEmpty {
                        Text("Hiệu ứng: \(decoration.effect)")
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

                    Text("\(decoration.priceOxygen)")
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

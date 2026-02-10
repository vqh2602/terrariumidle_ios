//
//  PlantSelectionView.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

struct PlantSelectionView: View {
    let cartPlants: [String]
    let rowIndex: Int
    let columnIndex: Int
    let onSelect: (String) -> Void
    @Binding var selectedPlantId: String?

    @State private var selectedCategory: String = "Tất cả"
    @State private var searchText: String = "" // Tìm kiếm

    private var availablePlants: [PlantItemData] {
        let allPlants = PlantDataManager.shared.getAllPlants()
        // Filter only plants that are in cart
        var filtered = allPlants.filter { plant in
            cartPlants.contains(plant.id)
        }

        // Filter by search text (tìm kiếm theo tên hoặc mô tả)
        if !searchText.isEmpty {
            filtered = filtered.filter { plant in
                plant.name.localizedCaseInsensitiveContains(searchText) ||
                    plant.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var categories: [String] {
        var cats = Set<String>()
        cats.insert("Tất cả")
        // You can add more categories based on plant types
        return Array(cats).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Category Picker

            // tìm kiếm
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
            // Menu {
            //     ForEach(categories, id: \.self) { category in
            //         Button(category) {
            //             selectedCategory = category
            //         }
            //     }
            // } label: {
            //     HStack {
            //         Text(selectedCategory)
            //             .foregroundColor(.primary)
            //         Spacer()
            //         Image(systemName: "chevron.down")
            //             .foregroundColor(.gray)
            //     }
            //     .padding()
            //     .background(
            //         RoundedRectangle(cornerRadius: 12)
            //             .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            //     )
            //     .padding(.horizontal)
            // }

            // MARK: - Plants List

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(availablePlants) { plant in
                        PlantItemRow(
                            plant: plant,
                            isSelected: selectedPlantId == plant.id,
                            onSelect: {
                                selectedPlantId = plant.id
                                onSelect(plant.id)
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

// MARK: - Plant Item Row

struct PlantItemRow: View {
    let plant: PlantItemData
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Plant Image
                CachedAsyncImage(url: URL(string: plant.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)

                // Plant Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(plant.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)

                    if plant.effect != "N.A" {
                        Text("Hiệu ứng: \(plant.effect)")
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

                    Text("\(plant.priceOxygen)")
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

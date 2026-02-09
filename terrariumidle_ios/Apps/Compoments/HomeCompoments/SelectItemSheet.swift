//
//  SelectItemSheet.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import SwiftUI

enum SelectionTab: String, CaseIterable {
    case pot = "Chọn chậu"
    case plant = "Chọn cây"
    case decoration = "Trang trí"
}

struct SelectItemSheet: View {
//    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool

    let cartPlants: [String]
    let rowIndex: Int
    let columnIndex: Int

    @State private var selectedTab: SelectionTab = .plant

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Tab Selector

                HStack(spacing: 12) {
                    ForEach(SelectionTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTab == tab ? Color.green : Color.gray.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                Divider()
                    .padding(.vertical, 12)

                // MARK: - Content

                Group {
                    switch selectedTab {
                    case .pot:
                        PotSelectionView()
                    case .plant:
                        PlantSelectionView(
                            cartPlants: cartPlants,
                            rowIndex: rowIndex,
                            columnIndex: columnIndex,
                            onSelect: { plantId in
                                print("Selected plant: \(plantId)")
                               
                            }
                        )
                    case .decoration:
                        DecorationSelectionView()
                    }
                }
            }
            .navigationTitle("Chọn vật phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        isPresented.toggle()
                    }
                }
            }
        }
    }
}

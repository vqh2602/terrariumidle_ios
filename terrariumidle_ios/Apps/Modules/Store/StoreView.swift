//
//  StoreView.swift
//  terrariumidle_ios
//
//  Created by AI on 9/2/26.
//

import FirebaseAuth
import SwiftUI

struct StoreView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: StoreViewModel
    @StateObject private var fireStore: FireStoreService = .shared

    init(auth: AuthService = AuthService.shared) {
        _viewModel = StateObject(wrappedValue: StoreViewModel(auth: auth))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // MARK: - Top Bar: User Stats

                userStatsBar
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top + 10)
                    .padding(.bottom, 10)

                Divider()

                // MARK: - Tab Selector

                tabSelector
                    .padding(.vertical, 12)

                Divider()

                // MARK: - Search Bar

                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                // MARK: - Items List

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredItems) { item in
                                StoreItemCard(
                                    item: item,
                                    isOwned: viewModel.isOwned(item: item),
                                    canAfford: viewModel.canAfford(item: item),
                                    meetsLevelRequirement: viewModel.meetsLevelRequirement(item: item),
                                    onPurchase: { item in
                                        Task {
                                            await viewModel.purchaseItem(item)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .ignoresSafeArea(.all, edges: .top)
        }
        .task {
            // Load user data
            guard let userId = AuthService.shared.currentUser?.uid else { return }
            _ = await fireStore.getDataById(userId: userId)

            // Load initial items
            viewModel.loadItems(for: .plants)
        }
        .alert("Lỗi", isPresented: $viewModel.hasError) {
            Button("OK", role: .cancel) {
                viewModel.hasError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - User Stats Bar

    private var userStatsBar: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: {
                router.pop()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()

            if let gardenModel = fireStore.gradenModel {
                // Oxygen
                statBadge(
                    icon: "oxygen",
                    iconColor: .green,
                    value: formatNumber(gardenModel.money.oxygen)
                )

                // Gemstone
                statBadge(
                    icon: "gemstone",
                    iconColor: .blue,
                    value: formatNumber(gardenModel.money.gemstone)
                )

                // Ticket
                statBadge(
                    icon: "ticket",
                    iconColor: .orange,
                    value: formatNumber(gardenModel.money.ticket)
                )

                // shovel
                statBadge(
                    icon: "shovel",
                    iconColor: .yellow,
                    value: "\(formatNumber(gardenModel.item.shovel))"
                )
                statBadge(
                    icon: "fertilizer",
                    iconColor: .yellow,
                    value: "\(formatNumber(gardenModel.item.fertilizer))"
                )
            }
        }
    }

    private func statBadge(icon: String, iconColor: Color, value: String) -> some View {
        VStack(spacing: 4) {
            Image(icon)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(iconColor)
            Text(value)
                .textStyle(.caption1).fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StoreTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: viewModel.selectedTab == tab,
                        action: {
                            viewModel.loadItems(for: tab)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Tìm kiếm", text: $viewModel.searchText)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fm", Double(number) / 1_000_000)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Tab Button Component

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.green : Color.gray.opacity(0.2))
                )
        }
    }
}

// #Preview {
//    StoreView()
// }

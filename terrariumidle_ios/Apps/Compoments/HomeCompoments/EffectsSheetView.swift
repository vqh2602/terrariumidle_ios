//
//  EffectsSheetView.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import SwiftUI

struct EffectsSheetView: View {
    @ObservedObject private var fireStore = FireStoreService.shared
    @Environment(\.dismiss) private var dismiss

    @Binding var backgroundRive: String
    @Binding var overlayRive: String?

    private let landscapes = ItemDataManager.shared.getAllLandscapes()
    private let effects = ItemDataManager.shared.getAllEffects()

    @State private var selectedLandscapeId: String? = nil
    @State private var selectedEffectId: String? = nil
    

    private var unlockedIds: Set<String> {
        MusicUnlockHelper.getUnlockedMusicIds(from: fireStore.gradenModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(red: 0.10, green: 0.12, blue: 0.18)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Section 1: Landscapes (single select)

                        SectionHeader(icon: "🌄", title: "Phong cảnh")

                        VStack(spacing: 12) {
                            ForEach(landscapes) { item in
                                let isLocked = !unlockedIds.contains(item.id)
                                EffectCardView(
                                    item: item,
                                    isSelected: selectedLandscapeId == item.image,
                                    isLocked: isLocked,
                                    onTap: {
                                        guard !isLocked else { return }
                                        selectedLandscapeId = item.image
                                        backgroundRive = item.image
                                        print("Selected landscape: \(item.id)")
                                    }
                                )
                            }
                        }

                        // MARK: - Section 2: Effects (single select)

                        SectionHeader(icon: "✨", title: "Hiệu ứng")

                        VStack(spacing: 12) {
                            ForEach(effects) { item in
                                let isLocked = !unlockedIds.contains(item.id)
                                EffectCardView(
                                    item: item,
                                    isSelected: selectedEffectId == item.image,
                                    isLocked: isLocked,
                                    onTap: {
                                        guard !isLocked else { return }
                                        selectedEffectId = item.image
                                        overlayRive = item.image
                                        print("Selected effect: \(item.id)")
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Phong cảnh & Hiệu ứng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.10, green: 0.12, blue: 0.18), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }.task({
            selectedLandscapeId = backgroundRive
             selectedEffectId = overlayRive
        })
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 4)
    }
}

// MARK: - Effect Card (Rectangular, 1 per row)

private struct EffectCardView: View {
    let item: ItemData
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail image
                ZStack {
                    Image("i_\(item.image)")
                        .resizable()
                        .aspectRatio(16 / 9, contentMode: .fill)
                        .frame(width: 120, height: 68)
                        .clipped()
                        .cornerRadius(10)

                    // Lock overlay
                    if isLocked {
                        ZStack {
                            Color.black.opacity(0.6)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 120, height: 68)
                        .cornerRadius(10)
                    }
                }

                // Item info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected && !isLocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected && !isLocked ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected && !isLocked ? Color.green : Color.clear,
                        lineWidth: 2
                    )
            )
            .opacity(isLocked ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

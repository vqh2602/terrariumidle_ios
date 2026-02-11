//
//  MusicSheetView.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import SwiftUI

struct MusicSheetView: View {
    @ObservedObject private var audioManager = BackgroundAudioManager.shared
    @ObservedObject private var fireStore = FireStoreService.shared
    @Environment(\.dismiss) private var dismiss

    private let musics = ItemDataManager.shared.getAllMusics()
    private let sfxItems = ItemDataManager.shared.getAllMusicsSFX()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var unlockedIds: Set<String> {
        MusicUnlockHelper.getUnlockedMusicIds(from: fireStore.gradenModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color(red: 0.10, green: 0.12, blue: 0.18)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // MARK: - Section 1: Music (single select)

                            SectionHeader(icon: "⭐", title: "Âm nhạc")

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(musics) { item in
                                    let isLocked = !unlockedIds.contains(item.id)
                                    SoundCardView(
                                        item: item,
                                        isSelected: audioManager.currentBGMId == item.id,
                                        isPlaying: audioManager.currentBGMId == item.id && audioManager.isPlaying,
                                        isLocked: isLocked,
                                        onTap: {
                                            guard !isLocked else { return }
                                            audioManager.switchBGM(
                                                id: item.id,
                                                fileName: item.id,
                                                title: item.name
                                            )
                                        }
                                    )
                                }
                            }

                            // MARK: - Section 2: SFX (multi select)

                            SectionHeader(icon: "🔊", title: "Hiệu ứng âm thanh")

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(sfxItems) { item in
                                    let isLocked = !unlockedIds.contains(item.id)
                                    SoundCardView(
                                        item: item,
                                        isSelected: audioManager.activeSFXIds.contains(item.id),
                                        isPlaying: audioManager.activeSFXIds.contains(item.id),
                                        isLocked: isLocked,
                                        onTap: {
                                            guard !isLocked else { return }
                                            audioManager.toggleSFX(
                                                id: item.id,
                                                fileName: item.id
                                            )
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 120) // Space for bottom bar
                    }

                    // MARK: - Bottom Playback Bar

                    PlaybackBar(audioManager: audioManager)
                }
            }
            .navigationTitle("Âm nhạc")
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
        }
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

// MARK: - Sound Card

private struct SoundCardView: View {
    let item: ItemData
    let isSelected: Bool
    let isPlaying: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Card image
                Image(item.image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()

                // Gradient overlay + name label
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack {
                    Spacer()

                    // Playing indicator
                    if isPlaying && !isLocked {
                        Image(systemName: "waveform")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }

                    Text(item.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                }

                // Lock overlay
                if isLocked {
                    ZStack {
                        Color.black.opacity(0.6)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(minHeight: 110)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected && !isLocked ? Color.white : Color.clear,
                        lineWidth: 3
                    )
            )
            .shadow(color: isSelected && !isLocked ? Color.blue.opacity(0.4) : .clear, radius: 6)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}

// MARK: - Playback Bar

private struct PlaybackBar: View {
    @ObservedObject var audioManager: BackgroundAudioManager

    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 16) {
                // Play / Pause button
                Button {
                    audioManager.toggle()
                } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                }

                // Volume slider
                Image(systemName: "speaker.fill")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))

                Slider(
                    value: Binding(
                        get: { audioManager.bgmVolume },
                        set: { audioManager.setBGMVolume($0) }
                    ),
                    in: 0 ... 1
                )
                .tint(.white)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            Color(red: 0.12, green: 0.14, blue: 0.22)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

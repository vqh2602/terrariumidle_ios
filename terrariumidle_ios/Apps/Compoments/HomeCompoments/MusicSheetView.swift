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
                        VStack(alignment: .leading, spacing: 22) {
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
                                                title: item.name,
                                                image: item.image
                                            )
                                        }
                                    )
                                }
                            }

                            // MARK: - Section 2: Active SFX Mixer (Bộ phối âm nhiều hiệu ứng)
                            if !audioManager.activeSFXIds.isEmpty {
                                ActiveSFXMixerSection(
                                    activeIds: audioManager.activeSFXIds,
                                    allItems: sfxItems,
                                    audioManager: audioManager
                                )
                            }

                            // MARK: - Section 3: SFX Library (multi select)

                            HStack {
                                SectionHeader(icon: "🔊", title: "Hiệu ứng âm thanh")
                                Spacer()
                                Text("Phối nhiều âm thanh")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(sfxItems) { item in
                                    let isLocked = !unlockedIds.contains(item.id)
                                    let isSelected = audioManager.activeSFXIds.contains(item.id)
                                    SoundCardView(
                                        item: item,
                                        isSelected: isSelected,
                                        isPlaying: isSelected,
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
                        .padding(.bottom, 140) // Space for bottom playback bar
                    }

                    // MARK: - Bottom Playback Bar

                    PlaybackBar(audioManager: audioManager)
                }
            }
            .navigationTitle("Âm nhạc & Hiệu ứng")
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
                .font(.title3)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, 4)
    }
}

// MARK: - Active SFX Mixer Section (Điều khiển nhiều SFX đồng thời)

private struct ActiveSFXMixerSection: View {
    let activeIds: Set<String>
    let allItems: [ItemData]
    @ObservedObject var audioManager: BackgroundAudioManager

    private var activeItems: [ItemData] {
        allItems.filter { activeIds.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text("🎛️")
                        .font(.title3)
                    Text("Bộ phối âm đang phát")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text("(\(activeIds.count))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        audioManager.stopAllSFX()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 13))
                        Text("Tắt tất cả")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.35))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 10) {
                ForEach(activeItems) { item in
                    SFXMixerRow(item: item, audioManager: audioManager)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.14, green: 0.17, blue: 0.26))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - SFX Mixer Row (Điều chỉnh âm lượng riêng cho từng SFX)

private struct SFXMixerRow: View {
    let item: ItemData
    @ObservedObject var audioManager: BackgroundAudioManager

    private var volume: Float {
        audioManager.getIndividualSFXVolume(id: item.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            Image(item.image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            // Name and Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(Int(volume * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }

                HStack(spacing: 6) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Slider(
                        value: Binding(
                            get: { volume },
                            set: { audioManager.setIndividualSFXVolume(id: item.id, volume: $0) }
                        ),
                        in: 0 ... 1
                    )
                    .tint(.orange)

                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Quick Stop Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    audioManager.stopSFX(id: item.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
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

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(spacing: 4) {
                    Spacer()

                    // Playing animated waveform indicator
                    if isPlaying && !isLocked {
                        HStack(spacing: 3) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12, weight: .bold))
                            Text("Đang phát")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.blue.opacity(0.8)))
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
                        isSelected && !isLocked ? Color.blue : Color.white.opacity(0.1),
                        lineWidth: isSelected && !isLocked ? 3 : 1
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
        VStack(spacing: 10) {
            Divider()
                .background(Color.white.opacity(0.2))

            // Upper Row: Artwork, Title, Remote Buttons (Prev / Play-Pause / Next)
            HStack(spacing: 12) {
                // Current Track Artwork
                if let imageName = audioManager.currentBGMImage ?? audioManager.currentBGMId {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Title & Active SFX Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(audioManager.currentBGMTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("Terrarium Idle")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))

                        if !audioManager.activeSFXIds.isEmpty {
                            Text("• \(audioManager.activeSFXIds.count) SFX")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                // Playback Controls: Prev, Play/Pause, Next
                HStack(spacing: 14) {
                    // Previous Track
                    Button {
                        audioManager.playPreviousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // Play / Pause
                    Button {
                        audioManager.toggle()
                    } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.blue)
                    }

                    // Next Track
                    Button {
                        audioManager.playNextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 16)

            // Lower Rows: Master Volume Sliders
            VStack(spacing: 6) {
                // BGM Volume slider
                HStack(spacing: 8) {
                    Text("Âm nhạc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 60, alignment: .leading)

                    Image(systemName: "speaker.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 11))

                    Slider(
                        value: Binding(
                            get: { audioManager.bgmVolume },
                            set: { audioManager.setBGMVolume($0) }
                        ),
                        in: 0 ... 1
                    )
                    .tint(.blue)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 11))
                }

                // SFX Master Volume slider
                HStack(spacing: 8) {
                    Text("Hiệu ứng")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 60, alignment: .leading)

                    Image(systemName: "speaker.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 11))

                    Slider(
                        value: Binding(
                            get: { audioManager.sfxVolume },
                            set: { audioManager.setSFXVolume($0) }
                        ),
                        in: 0 ... 1
                    )
                    .tint(.orange)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 11))
                }
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

#Preview {
    MusicSheetView()
}


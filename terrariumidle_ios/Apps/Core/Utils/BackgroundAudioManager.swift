//
//  BackgroundAudioManager.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 7/2/26.
//

import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class BackgroundAudioManager: ObservableObject {
    static let shared = BackgroundAudioManager()

    // MARK: - Published Properties

    @Published private(set) var isPlaying: Bool = false
    @Published var currentBGMId: String? = nil
    @Published var currentBGMTitle: String = "Terrarium Idle"
    @Published var currentBGMImage: String? = nil
    @Published var bgmVolume: Float = 0.6
    @Published var sfxVolume: Float = 0.6 // Master SFX volume

    /// Danh sách các SFX đang phát đồng thời
    @Published var activeSFXIds: Set<String> = []

    /// Âm lượng riêng cho từng SFX (0.0 ... 1.0)
    @Published var sfxVolumes: [String: Float] = [:]

    // MARK: - Private Players

    private var player: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        setupRemoteCommands()
        setupInterruptionObserver()
        ensureAudioSession()
    }

    private static var isSessionConfigured = false

    /// Gọi từ AppDelegate sau khi session đã được set từ bên ngoài
    static func markSessionConfigured() {
        isSessionConfigured = true
    }

    /// Cấu hình AudioSession đồng bộ ngay trước khi phát nhạc.
    /// Dùng category .playback (không có .mixWithOthers) để kích hoạt Remote Controls và Now Playing
    /// trên thanh thông báo (Notification Center), màn hình khóa (Lock Screen) và Control Center.
    func ensureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            if session.category != .playback {
                try session.setCategory(.playback, mode: .default, options: [])
            }
            try session.setActive(true)
            Self.isSessionConfigured = true
            print("✅ BackgroundAudioManager: AVAudioSession .playback active")
        } catch {
            print("⚠️ Lỗi thiết lập AVAudioSession:", error)
        }
    }

    // MARK: - Audio File Resolution Helper

    private func findAudioURL(fileName: String, ext: String = "mp3") -> URL? {
        // 1. Tìm chính xác
        if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
            return url
        }
        // 2. Tìm với đuôi hoa (ví dụ: m5.MP3)
        if let url = Bundle.main.url(forResource: fileName, withExtension: ext.uppercased()) {
            return url
        }
        // 3. Fallback m0 <-> peacefulgarden
        if fileName == "m0" {
            if let url = Bundle.main.url(forResource: "peacefulgarden", withExtension: "mp3") {
                return url
            }
        } else if fileName == "peacefulgarden" {
            if let url = Bundle.main.url(forResource: "m0", withExtension: "mp3") {
                return url
            }
        }
        return nil
    }

    // MARK: - BGM Controls

    func startBGM(
        fileName: String,
        ext: String = "mp3",
        title: String = "Terrarium Idle",
        image: String? = nil,
        id: String? = nil
    ) {
        ensureAudioSession()

        guard let url = findAudioURL(fileName: fileName, ext: ext) else {
            print("❌ Missing BGM: \(fileName).\(ext)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = bgmVolume
            player?.prepareToPlay()

            isPlaying = true
            currentBGMTitle = title
            if let id = id {
                currentBGMId = id
            }
            if let image = image {
                currentBGMImage = image
            } else if currentBGMImage == nil {
                currentBGMImage = currentBGMId
            }

            player?.play()
            print("🎵 BGM playing: \(title) (\(fileName))")

            // Cập nhật Now Playing ngay lập tức và sau 0.2s để lock screen widget nhận diện
            updateNowPlaying(title: title)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.updateNowPlaying(title: title)
            }

        } catch {
            print("❌ startBGM error:", error)
        }
    }

    /// Chuyển đổi sang bài BGM khác
    func switchBGM(
        id: String,
        fileName: String,
        title: String = "Terrarium Idle",
        image: String? = nil
    ) {
        stop()
        currentBGMId = id
        currentBGMTitle = title
        currentBGMImage = image ?? id
        startBGM(fileName: fileName, title: title, image: currentBGMImage, id: id)
    }

    /// Phát bản nhạc BGM mặc định ("m0" - "Relax...") nếu chưa có nhạc đang phát
    func startDefaultBGM() {
        guard !isPlaying else { return }
        switchBGM(id: "m0", fileName: "m0", title: "Relax...", image: "m0")
    }

    func pause() {
        player?.pause()
        for (_, sfxPlayer) in sfxPlayers {
            sfxPlayer.pause()
        }
        isPlaying = false
        updateNowPlaying()
        print("⏸️ BGM paused")
    }

    func resume() {
        ensureAudioSession()

        // 1. Kiểm tra player BGM
        if let p = player {
            p.prepareToPlay()
            let played = p.play()
            print("🎵 resume: player.play() = \(played), currentTime = \(p.currentTime)")
            if !played {
                print("⚠️ player.play() returned false, re-creating player...")
                let trackId = currentBGMId ?? "m0"
                startBGM(fileName: trackId, title: currentBGMTitle, image: currentBGMImage, id: trackId)
                return
            }
        } else {
            // Player chưa có hoặc đã bị giải phóng -> khởi động lại track hiện tại
            print("🔄 resume: player was nil, re-starting BGM...")
            let trackId = currentBGMId ?? "m0"
            startBGM(fileName: trackId, title: currentBGMTitle, image: currentBGMImage, id: trackId)
            return
        }

        // 2. Resume các SFX đang hoạt động
        for (_, sfxPlayer) in sfxPlayers {
            sfxPlayer.play()
        }

        isPlaying = true
        updateNowPlaying()
    }

    func toggle() {
        if let p = player, p.isPlaying {
            pause()
        } else if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        updateNowPlaying()
    }

    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = max(0, min(time, p.duration))
        updateNowPlaying()
    }

    func setBGMVolume(_ vol: Float) {
        bgmVolume = max(0, min(1, vol))
        player?.volume = bgmVolume
    }

    // MARK: - Next / Previous Track (Remote Command Support)

    func playNextTrack() {
        let allMusics = ItemDataManager.shared.getAllMusics()
        guard !allMusics.isEmpty else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: FireStoreService.shared.gradenModel)
        let unlockedTracks = allMusics.filter { unlockedIds.contains($0.id) }
        let playlist = unlockedTracks.isEmpty ? allMusics : unlockedTracks

        let currentIndex = playlist.firstIndex(where: { $0.id == currentBGMId }) ?? 0
        let nextIndex = (currentIndex + 1) % playlist.count
        let nextTrack = playlist[nextIndex]

        switchBGM(
            id: nextTrack.id,
            fileName: nextTrack.id,
            title: nextTrack.name,
            image: nextTrack.image
        )
    }

    func playPreviousTrack() {
        if let p = player, p.currentTime > 3.0 {
            seek(to: 0)
            return
        }

        let allMusics = ItemDataManager.shared.getAllMusics()
        guard !allMusics.isEmpty else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: FireStoreService.shared.gradenModel)
        let unlockedTracks = allMusics.filter { unlockedIds.contains($0.id) }
        let playlist = unlockedTracks.isEmpty ? allMusics : unlockedTracks

        let currentIndex = playlist.firstIndex(where: { $0.id == currentBGMId }) ?? 0
        let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        let prevTrack = playlist[prevIndex]

        switchBGM(
            id: prevTrack.id,
            fileName: prevTrack.id,
            title: prevTrack.name,
            image: prevTrack.image
        )
    }

    // MARK: - SFX (Layered Multi-SFX Management & Mixer)

    func toggleSFX(id: String, fileName: String, ext: String = "mp3") {
        if activeSFXIds.contains(id) {
            stopSFX(id: id)
        } else {
            startSFX(id: id, fileName: fileName, ext: ext)
        }
    }

    func startSFX(id: String, fileName: String, ext: String = "mp3") {
        guard let url = findAudioURL(fileName: fileName, ext: ext) else {
            print("❌ Missing SFX: \(fileName).\(ext)")
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1

            let indVol = sfxVolumes[id] ?? 1.0
            p.volume = indVol * sfxVolume
            p.prepareToPlay()
            p.play()

            sfxPlayers[id] = p
            activeSFXIds.insert(id)
            if sfxVolumes[id] == nil {
                sfxVolumes[id] = 1.0
            }
            print("🔊 SFX playing: \(id) (vol: \(p.volume))")
        } catch {
            print("❌ SFX error:", error)
        }
    }

    func stopSFX(id: String) {
        sfxPlayers[id]?.stop()
        sfxPlayers.removeValue(forKey: id)
        activeSFXIds.remove(id)
        print("🔇 SFX stopped: \(id)")
    }

    func stopAllSFX() {
        sfxPlayers.values.forEach { $0.stop() }
        sfxPlayers.removeAll()
        activeSFXIds.removeAll()
        print("🔇 All SFX stopped")
    }

    /// Điều chỉnh âm lượng riêng cho 1 hiệu ứng SFX cụ thể (0.0 ... 1.0)
    func setIndividualSFXVolume(id: String, volume: Float) {
        let clamped = max(0, min(1, volume))
        sfxVolumes[id] = clamped
        if let p = sfxPlayers[id] {
            p.volume = clamped * sfxVolume
        }
    }

    func getIndividualSFXVolume(id: String) -> Float {
        return sfxVolumes[id] ?? 1.0
    }

    /// Điều chỉnh âm lượng tổng thể cho toàn bộ SFX
    func setSFXVolume(_ vol: Float) {
        sfxVolume = max(0, min(1, vol))
        for (id, p) in sfxPlayers {
            let indVol = sfxVolumes[id] ?? 1.0
            p.volume = indVol * sfxVolume
        }
    }

    // MARK: - Now Playing (Notification Center / Lock Screen / Control Center)

    func updateNowPlaying(title: String? = nil) {
        let displayTitle = title ?? currentBGMTitle

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: displayTitle,
            MPMediaItemPropertyArtist: "Terrarium Idle",
            MPMediaItemPropertyAlbumTitle: "Nhạc thư giãn",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime ?? 0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]

        if let duration = player?.duration, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        // Tải ảnh bìa bài hát từ Assets (m0, m1, ...)
        let imageName = currentBGMImage ?? currentBGMId ?? "m0"
        if let image = UIImage(named: imageName) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        print("📻 Now Playing updated: [\(displayTitle)] isPlaying: \(isPlaying), time: \(player?.currentTime ?? 0)")
    }

    private func updatePlaybackState() {
        updateNowPlaying()
    }

    // MARK: - Remote Commands (Lock Screen / Notification Center / Control Center)

    private nonisolated func executeOnMain(_ block: @MainActor @escaping () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                block()
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    block()
                }
            }
        }
    }

    private func setupRemoteCommands() {
        // Cho phép nhận sự kiện điều khiển từ xa
        UIApplication.shared.beginReceivingRemoteControlEvents()

        let center = MPRemoteCommandCenter.shared()

        // Xóa target cũ để tránh trùng lặp
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
        center.changePlaybackPositionCommand.removeTarget(nil)

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.executeOnMain {
                self.resume()
            }
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.executeOnMain {
                self.pause()
            }
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.executeOnMain {
                self.toggle()
            }
            return .success
        }

        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.executeOnMain {
                self.playNextTrack()
            }
            return .success
        }

        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.executeOnMain {
                self.playPreviousTrack()
            }
            return .success
        }

        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let changeEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.executeOnMain {
                self.seek(to: changeEvent.positionTime)
            }
            return .success
        }
    }

    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            if type == .began {
                Task { @MainActor [weak self] in
                    self?.pause()
                }
            } else if type == .ended {
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        Task { @MainActor [weak self] in
                            self?.resume()
                        }
                    }
                }
            }
        }
    }
}

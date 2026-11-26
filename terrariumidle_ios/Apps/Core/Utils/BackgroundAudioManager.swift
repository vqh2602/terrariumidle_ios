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

    @Published private(set) var sleepTimerDeadline: Date?
    private var sleepTimer: DispatchSourceTimer?
    private var sleepTimerDidExpire = false
    private var sleepStopGeneration = 0

    // MARK: - Private Players

    private let playback = BackgroundAudioPlayback()
    private var currentBGMFileName: String?
    private var currentBGMExtension = "mp3"
    private var isStartingBGM = false
    private var hasStartedInitialBGM = false
    private var pendingSFXIds: Set<String> = []
    private var nowPlayingGeneration = 0

    private init() {
        setupRemoteCommands()
        setupInterruptionObserver()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.expireSleepTimerIfNeeded() }
        }
        ensureAudioSession()
    }

    private var playbackGeneration = 0
    private var sfxGenerations: [String: Int] = [:]
    private var weatherGeneration = 0
    private var activeWeatherFileName: String?

    func ensureAudioSession() {
        AudioSessionController.activate()
    }

    struct AudioSnapshot {
        let wasPlaying: Bool
        let bgmId: String?
        let bgmFileName: String?
        let bgmExtension: String
        let bgmTitle: String
        let bgmImage: String?
        let activeSFXIds: Set<String>
        let sleepStopGeneration: Int
    }

    func hasAudioResource(fileName: String, ext: String = "mp3") -> Bool {
        findAudioURL(fileName: fileName, ext: ext) != nil
    }

    func captureAudioSnapshot() -> AudioSnapshot {
        AudioSnapshot(
            wasPlaying: isPlaying || isStartingBGM,
            bgmId: currentBGMId,
            bgmFileName: currentBGMFileName,
            bgmExtension: currentBGMExtension,
            bgmTitle: currentBGMTitle,
            bgmImage: currentBGMImage,
            activeSFXIds: activeSFXIds,
            sleepStopGeneration: sleepStopGeneration
        )
    }

    func restoreAudioSnapshot(_ snapshot: AudioSnapshot) {
        expireSleepTimerIfNeeded()
        guard !sleepTimerDidExpire, snapshot.sleepStopGeneration == sleepStopGeneration else { return }
        stopAllSFX()
        if snapshot.wasPlaying {
            if let fileName = snapshot.bgmFileName {
                startBGM(
                    fileName: fileName,
                    ext: snapshot.bgmExtension,
                    title: snapshot.bgmTitle,
                    image: snapshot.bgmImage,
                    id: snapshot.bgmId
                )
            } else {
                startDefaultBGM()
            }
            let sfxCatalog = Dictionary(uniqueKeysWithValues: ItemDataManager.shared.getAllMusicsSFX().map { ($0.id, $0) })
            for sfxId in snapshot.activeSFXIds {
                let fileName = sfxCatalog[sfxId]?.sound ?? sfxId
                startSFX(id: sfxId, fileName: fileName)
            }
        } else {
            pause()
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

    /// Owned by the audio manager, so closing the sheet or backgrounding the app keeps it armed.
    func setSleepTimer(minutes: Int) {
        guard (1...120).contains(minutes) else { return }
        cancelSleepTimer()
        let interval = TimeInterval(minutes * 60)
        let deadline = Date().addingTimeInterval(interval)
        sleepTimerDeadline = deadline
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(wallDeadline: .now() + interval, leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.sleepTimerDeadline == deadline else { return }
                self.expireSleepTimerIfNeeded()
            }
        }
        sleepTimer = timer
        timer.resume()
    }

    func cancelSleepTimer() {
        sleepTimer?.cancel()
        sleepTimer = nil
        sleepTimerDeadline = nil
    }

    func expireSleepTimerIfNeeded(now: Date = Date()) {
        guard let deadline = sleepTimerDeadline, deadline <= now else { return }
        cancelSleepTimer()
        sleepTimerDidExpire = true
        sleepStopGeneration += 1
        pause()
        stopAllSFX()
        stopWeatherSound()
    }

    func startBGM(
        fileName: String,
        ext: String = "mp3",
        title: String = "Terrarium Idle",
        image: String? = nil,
        id: String? = nil
    ) {
        expireSleepTimerIfNeeded()
        sleepTimerDidExpire = false // An explicit playback request may start a new listening session.
        playbackGeneration += 1
        guard AudioSessionController.isActive else {
            let generation = playbackGeneration
            AudioSessionController.activate { [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.playbackGeneration == generation else { return }
                self.startBGM(fileName: fileName, ext: ext, title: title, image: image, id: id)
            }
            return
        }

        guard let url = findAudioURL(fileName: fileName, ext: ext) else {
            isStartingBGM = false
            print("❌ Missing BGM: \(fileName).\(ext)")
            return
        }

        isStartingBGM = true
        // Discard metadata snapshots from the previous track while this one loads.
        nowPlayingGeneration += 1
        let generation = playbackGeneration
        let volume = bgmVolume
        playback.perform { [weak self] playback in
            let played: Bool
            do {
                // Keep the current track until its replacement is ready to play.
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = volume
                played = player.prepareToPlay() && player.play()
                if played {
                    playback.player?.stop()
                    playback.player = player
                }
            } catch {
                print("❌ startBGM error:", error)
                played = false
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.playbackGeneration == generation else { return }
                self.isStartingBGM = false
                guard played else {
                    self.updateNowPlaying()
                    return
                }
                self.isPlaying = true
                self.currentBGMId = id ?? fileName
                self.currentBGMTitle = title
                self.currentBGMImage = image ?? id ?? fileName
                self.currentBGMFileName = fileName
                self.currentBGMExtension = ext
                self.updateNowPlaying()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self, self.playbackGeneration == generation else { return }
                    self.updateNowPlaying()
                }
            }
        }
    }

    /// Chuyển đổi sang bài BGM khác
    func switchBGM(
        id: String,
        fileName: String,
        title: String = "Terrarium Idle",
        image: String? = nil
    ) {
        startBGM(fileName: fileName, title: title, image: image ?? id, id: id)
    }

    /// Chọn ngẫu nhiên BGM đã mở khóa sau khi tải vườn và quyền VIP, đúng 1 lần khi vào app.
    func startInitialBGMIfNeeded(gardenModel: GardenModel) {
        guard !hasStartedInitialBGM else { return }
        hasStartedInitialBGM = true
        // Preserve any track the user has already selected, including a paused one.
        guard currentBGMId == nil, !isPlaying, !isStartingBGM else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: gardenModel)
        let playlist = ItemDataManager.shared.getAllMusics().filter {
            unlockedIds.contains($0.id) && hasAudioResource(fileName: $0.sound ?? $0.id)
        }
        guard let track = playlist.randomElement() else {
            startDefaultBGM()
            return
        }
        switchBGM(
            id: track.id,
            fileName: track.sound ?? track.id,
            title: track.name,
            image: track.image
        )
    }

    /// Phát bản nhạc BGM mặc định ("m0" - "Relax...") nếu chưa có nhạc đang phát
    func startDefaultBGM() {
        guard !isPlaying, !isStartingBGM else { return }
        switchBGM(id: "music1", fileName: "m0", title: "Relax...", image: "m0")
    }

    func pause() {
        playbackGeneration += 1
        isStartingBGM = false
        let pendingIds = pendingSFXIds
        for id in pendingIds { sfxGenerations[id, default: 0] += 1 }
        pendingSFXIds.removeAll()
        activeSFXIds.subtract(pendingIds)
        playback.perform { playback in
            for id in pendingIds {
                playback.sfxPlayers.removeValue(forKey: id)?.stop()
            }
            playback.player?.pause()
            playback.sfxPlayers.values.forEach { $0.pause() }
        }
        isPlaying = false
        updateNowPlaying()
        print("⏸️ BGM paused")
    }

    func resume() {
        expireSleepTimerIfNeeded()
        sleepTimerDidExpire = false
        playbackGeneration += 1
        guard AudioSessionController.isActive else {
            let generation = playbackGeneration
            AudioSessionController.activate { [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.playbackGeneration == generation else { return }
                self.resume()
            }
            return
        }

        isStartingBGM = true
        let generation = playbackGeneration
        playback.perform { [weak self] playback in
            let played = playback.player.map { $0.prepareToPlay() && $0.play() } ?? false
            if played {
                playback.sfxPlayers.values.forEach { $0.play() }
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.playbackGeneration == generation else { return }
                self.isStartingBGM = false
                if !played {
                    let trackId = self.currentBGMId ?? "music1"
                    self.startBGM(fileName: self.currentBGMFileName ?? "m0",
                                  ext: self.currentBGMExtension, title: self.currentBGMTitle,
                                  image: self.currentBGMImage, id: trackId)
                    return
                }
                self.isPlaying = true
                self.updateNowPlaying()
            }
        }
    }

    func toggle() {
        if isPlaying || isStartingBGM {
            pause()
        } else {
            resume()
        }
    }

    func stop() {
        playbackGeneration += 1
        isStartingBGM = false
        playback.perform { playback in
            playback.player?.stop()
            playback.player = nil
        }
        isPlaying = false
        updateNowPlaying()
    }

    func seek(to time: TimeInterval) {
        playback.perform { playback in
            guard let player = playback.player else { return }
            player.currentTime = max(0, min(time, player.duration))
        }
        updateNowPlaying()
    }

    func setBGMVolume(_ vol: Float) {
        bgmVolume = max(0, min(1, vol))
        let volume = bgmVolume
        playback.perform { $0.player?.volume = volume }
    }

    // MARK: - Next / Previous Track (Remote Command Support)

    func playNextTrack() {
        let allMusics = ItemDataManager.shared.getAllMusics()
        guard !allMusics.isEmpty else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: FireStoreService.shared.gradenModel)
        let unlockedTracks = allMusics.filter { unlockedIds.contains($0.id) }
        let playlist = unlockedTracks.filter {
            findAudioURL(fileName: $0.sound ?? $0.id) != nil
        }
        guard !playlist.isEmpty else { return }

        let currentIndex = playlist.firstIndex(where: { $0.id == currentBGMId }) ?? 0
        let nextIndex = (currentIndex + 1) % playlist.count
        let nextTrack = playlist[nextIndex]

        switchBGM(
            id: nextTrack.id,
            fileName: nextTrack.sound ?? nextTrack.id,
            title: nextTrack.name,
            image: nextTrack.image
        )
    }

    func playPreviousTrack() {
        let generation = playbackGeneration
        playback.perform { [weak self] playback in
            let shouldRestart = (playback.player?.currentTime ?? 0) > 3.0
            Task { @MainActor [weak self] in
                guard let self, self.playbackGeneration == generation else { return }
                if shouldRestart {
                    self.seek(to: 0)
                } else {
                    self.switchToPreviousTrack()
                }
            }
        }
    }

    private func switchToPreviousTrack() {
        let allMusics = ItemDataManager.shared.getAllMusics()
        guard !allMusics.isEmpty else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: FireStoreService.shared.gradenModel)
        let unlockedTracks = allMusics.filter { unlockedIds.contains($0.id) }
        let playlist = unlockedTracks.filter {
            findAudioURL(fileName: $0.sound ?? $0.id) != nil
        }
        guard !playlist.isEmpty else { return }

        let currentIndex = playlist.firstIndex(where: { $0.id == currentBGMId }) ?? 0
        let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
        let prevTrack = playlist[prevIndex]

        switchBGM(
            id: prevTrack.id,
            fileName: prevTrack.sound ?? prevTrack.id,
            title: prevTrack.name,
            image: prevTrack.image
        )
    }

    // MARK: - SFX (Layered Multi-SFX Management & Mixer)

    func toggleSFX(id: String, fileName: String, ext: String = "mp3") {
        if activeSFXIds.contains(id) || pendingSFXIds.contains(id) {
            stopSFX(id: id)
        } else {
            startSFX(id: id, fileName: fileName, ext: ext)
        }
    }

    func startSFX(id: String, fileName: String, ext: String = "mp3") {
        expireSleepTimerIfNeeded()
        sleepTimerDidExpire = false
        sfxGenerations[id, default: 0] += 1
        pendingSFXIds.insert(id)
        guard AudioSessionController.isActive else {
            let generation = sfxGenerations[id]
            AudioSessionController.activate { [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.sfxGenerations[id] == generation else { return }
                self.startSFX(id: id, fileName: fileName, ext: ext)
            }
            return
        }
        guard let url = findAudioURL(fileName: fileName, ext: ext) else {
            pendingSFXIds.remove(id)
            print("❌ Missing SFX: \(fileName).\(ext)")
            return
        }

        let generation = sfxGenerations[id]
        let volume = (sfxVolumes[id] ?? 1.0) * sfxVolume
        playback.perform { [weak self] playback in
            let played: Bool
            do {
                playback.sfxPlayers.removeValue(forKey: id)?.stop()
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = volume
                played = player.prepareToPlay() && player.play()
                if played { playback.sfxPlayers[id] = player }
            } catch {
                print("❌ SFX error:", error)
                played = false
            }
            Task { @MainActor [weak self] in
                guard let self, self.sfxGenerations[id] == generation else { return }
                self.pendingSFXIds.remove(id)
                if played {
                    self.activeSFXIds.insert(id)
                    if self.sfxVolumes[id] == nil { self.sfxVolumes[id] = 1.0 }
                } else {
                    self.activeSFXIds.remove(id)
                }
            }
        }
    }

    func stopSFX(id: String) {
        sfxGenerations[id, default: 0] += 1
        pendingSFXIds.remove(id)
        playback.perform { $0.sfxPlayers.removeValue(forKey: id)?.stop() }
        activeSFXIds.remove(id)
        print("🔇 SFX stopped: \(id)")
    }

    func stopAllSFX() {
        for id in Array(sfxGenerations.keys) { sfxGenerations[id, default: 0] += 1 }
        pendingSFXIds.removeAll()
        playback.perform { playback in
            playback.sfxPlayers.values.forEach { $0.stop() }
            playback.sfxPlayers.removeAll()
        }
        activeSFXIds.removeAll()
        print("🔇 All SFX stopped")
    }

    /// Điều chỉnh âm lượng riêng cho 1 hiệu ứng SFX cụ thể (0.0 ... 1.0)
    func setIndividualSFXVolume(id: String, volume: Float) {
        let clamped = max(0, min(1, volume))
        sfxVolumes[id] = clamped
        let volume = clamped * sfxVolume
        playback.perform { $0.sfxPlayers[id]?.volume = volume }
    }

    func getIndividualSFXVolume(id: String) -> Float {
        return sfxVolumes[id] ?? 1.0
    }

    /// Điều chỉnh âm lượng tổng thể cho toàn bộ SFX
    func setSFXVolume(_ vol: Float) {
        sfxVolume = max(0, min(1, vol))
        let volume = sfxVolume
        let volumes = sfxVolumes
        playback.perform { playback in
            for (id, player) in playback.sfxPlayers {
                player.volume = (volumes[id] ?? 1.0) * volume
            }
            playback.weatherPlayer?.volume = volume
        }
    }

    // MARK: - Weather Ambient Sound

    func startWeatherSound(fileName: String, ext: String = "wav") {
        expireSleepTimerIfNeeded()
        guard !sleepTimerDidExpire else { return }
        let key = "\(fileName).\(ext)"
        guard activeWeatherFileName != key else { return }

        weatherGeneration += 1
        guard AudioSessionController.isActive else {
            let generation = weatherGeneration
            AudioSessionController.activate { [weak self] in
                guard let self else { return }
                self.expireSleepTimerIfNeeded()
                guard self.weatherGeneration == generation else { return }
                self.startWeatherSound(fileName: fileName, ext: ext)
            }
            return
        }

        guard let url = findAudioURL(fileName: fileName, ext: ext) else {
            activeWeatherFileName = nil
            print("❌ Missing weather audio: \(fileName).\(ext)")
            return
        }

        activeWeatherFileName = key
        let generation = weatherGeneration
        let volume = sfxVolume
        playback.perform { [weak self] playback in
            let played: Bool
            do {
                playback.weatherPlayer?.stop()
                playback.weatherPlayer = nil
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = volume
                played = player.prepareToPlay() && player.play()
                if played { playback.weatherPlayer = player }
            } catch {
                print("❌ Weather audio error:", error)
                played = false
            }
            Task { @MainActor [weak self] in
                guard let self, self.weatherGeneration == generation else { return }
                if !played {
                    self.activeWeatherFileName = nil
                }
            }
        }
    }

    func stopWeatherSound() {
        weatherGeneration += 1
        activeWeatherFileName = nil
        playback.perform { playback in
            playback.weatherPlayer?.stop()
            playback.weatherPlayer = nil
        }
    }

    // MARK: - Now Playing (Notification Center / Lock Screen / Control Center)

    func updateNowPlaying(title: String? = nil) {
        nowPlayingGeneration += 1
        let generation = nowPlayingGeneration
        playback.perform { [weak self] playback in
            let time = playback.player?.currentTime ?? 0
            let duration = playback.player?.duration ?? 0
            Task { @MainActor [weak self] in
                guard let self, self.nowPlayingGeneration == generation else { return }
                self.publishNowPlaying(title: title, time: time, duration: duration)
            }
        }
    }

    private func publishNowPlaying(title: String?, time: TimeInterval, duration: TimeInterval) {
        let displayTitle = title ?? currentBGMTitle

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: displayTitle,
            MPMediaItemPropertyArtist: "Terrarium Idle",
            MPMediaItemPropertyAlbumTitle: "Nhạc thư giãn".tr,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]

        if duration > 0 {
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
        print("📻 Now Playing updated: [\(displayTitle)] isPlaying: \(isPlaying), time: \(time)")
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
                    AudioSessionController.invalidate()
                    self?.pause()
                }
            } else if type == .ended {
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            self.expireSleepTimerIfNeeded()
                            guard !self.sleepTimerDidExpire else { return }
                            self.resume()
                        }
                    }
                }
            }
        }
    }
}

/// Owns all AVAudioPlayer instances. Access mutable state only inside `perform`.
/// @unchecked Sendable is safe because every operation uses the same serial queue.
nonisolated private final class BackgroundAudioPlayback: @unchecked Sendable {
    private let queue = DispatchQueue(label: "terrarium.background-audio", qos: .userInitiated)
    var player: AVAudioPlayer?
    var sfxPlayers: [String: AVAudioPlayer] = [:]
    var weatherPlayer: AVAudioPlayer?

    func perform(_ operation: @escaping @Sendable (BackgroundAudioPlayback) -> Void) {
        queue.async {
            dispatchPrecondition(condition: .notOnQueue(.main))
            operation(self)
        }
    }
}

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

@MainActor
final class BackgroundAudioManager: ObservableObject {
    static let shared = BackgroundAudioManager()

    @Published private(set) var isPlaying: Bool = false
    @Published var currentBGMId: String? = nil
    @Published var activeSFXIds: Set<String> = []
    @Published var bgmVolume: Float = 0.6
    @Published var currentBGMTitle: String = "Terrarium Idle"

    private var player: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]

    private init() {
        setupRemoteCommands()
    }

    // MARK: - BGM

    func startBGM(fileName: String, ext: String = "mp3", title: String = "Terrarium Idle") {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("❌ Missing BGM: \(fileName).\(ext)")
                return
            }

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = bgmVolume
            player?.prepareToPlay()
            player?.play()

            isPlaying = true
            currentBGMTitle = title
            updateNowPlaying(title: title)

        } catch {
            print("❌ startBGM error:", error)
        }
    }

    /// Switch to a different BGM track by item id
    func switchBGM(id: String, fileName: String, title: String = "Terrarium Idle") {
        stop()
        currentBGMId = id
        startBGM(fileName: fileName, title: title)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updatePlaybackState()
    }

    func resume() {
        player?.play()
        isPlaying = true
        updatePlaybackState()
    }

    func toggle() {
        isPlaying ? pause() : resume()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentBGMId = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func setBGMVolume(_ vol: Float) {
        bgmVolume = vol
        player?.volume = vol
    }

    // MARK: - SFX (layered ambient sounds, looping)

    func toggleSFX(id: String, fileName: String, ext: String = "mp3") {
        if activeSFXIds.contains(id) {
            // Stop this SFX
            sfxPlayers[id]?.stop()
            sfxPlayers.removeValue(forKey: id)
            activeSFXIds.remove(id)
            print("🔇 SFX stopped: \(id)")
        } else {
            // Start this SFX
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("❌ Missing SFX: \(fileName).\(ext)")
                return
            }
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.numberOfLoops = -1
                p.volume = bgmVolume
                p.prepareToPlay()
                p.play()
                sfxPlayers[id] = p
                activeSFXIds.insert(id)
                print("🔊 SFX playing: \(id)")
            } catch {
                print("❌ SFX error:", error)
            }
        }
    }

    func stopAllSFX() {
        sfxPlayers.values.forEach { $0.stop() }
        sfxPlayers.removeAll()
        activeSFXIds.removeAll()
    }

    // MARK: - Now Playing

    private func updateNowPlaying(title: String) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: "Terrarium Idle",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime ?? 0,
        ]

        if let duration = player?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        // Add artwork if app icon is available
        if let image = UIImage(named: "AppIcon") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updatePlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote controls (Control Center / Lock Screen)

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
    }
}

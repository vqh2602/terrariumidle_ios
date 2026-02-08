//
//  BackgroundAudioManager.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 7/2/26.
//


import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
final class BackgroundAudioManager: ObservableObject {
    
    static let shared = BackgroundAudioManager()

    @Published private(set) var isPlaying: Bool = false

    private var player: AVAudioPlayer?

    private init() {
        setupRemoteCommands()
    }

    func startBGM(fileName: String, ext: String = "mp3", title: String = "Terrarium Idle") {
        do {
            // 1) Audio session cho background playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            // 2) Load file
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("❌ Missing BGM: \(fileName).\(ext)")
                return
            }

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.prepareToPlay()
            player?.play()

            isPlaying = true
            updateNowPlaying(title: title)

        } catch {
            print("❌ startBGM error:", error)
        }
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
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Now Playing

    private func updateNowPlaying(title: String) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player?.currentTime ?? 0
        ]

        if let duration = player?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
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

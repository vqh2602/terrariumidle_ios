import AVFoundation

@MainActor
final class AudioPlayer {
    static let shared = AudioPlayer()

    private var bgmGeneration = 0
    private var sfxGeneration = 0
    private let playback = AudioPlaybackQueue()
    private var lastClickSoundTime: TimeInterval = 0

    var isBgmEnabled = true
    var isSfxEnabled = true

    private init() {
        configureAudioSessionAsync()
    }

    private func configureAudioSessionAsync() {
        AudioSessionController.activate { [weak self] in
            self?.playback.preload()
        }
    }

    // MARK: - Background Music

    func playBGM(fileName: String, ext: String = "mp3", volume: Float = 0.6, loop: Bool = true) {
        guard isBgmEnabled else { return }
        bgmGeneration += 1
        guard AudioSessionController.isActive else {
            let generation = bgmGeneration
            AudioSessionController.activate { [weak self] in
                guard let self, self.bgmGeneration == generation else { return }
                self.playBGM(fileName: fileName, ext: ext, volume: volume, loop: loop)
            }
            return
        }

        playback.playBGM(fileName: fileName, ext: ext, volume: volume, loop: loop)
    }

    func stopBGM() {
        bgmGeneration += 1
        playback.stopBGM()
    }

    // MARK: - Tap Sound (Sử dụng Pool tái sử dụng, không block Main Thread khi tap liên tục)

    func playTap(fileName: String = "tap", ext: String = "mp3", volume: Float = 1.0) {
        guard isSfxEnabled else { return }
        guard AudioSessionController.isActive else {
            let generation = sfxGeneration
            AudioSessionController.activate { [weak self] in
                guard let self, self.sfxGeneration == generation else { return }
                self.playTap(fileName: fileName, ext: ext, volume: volume)
            }
            return
        }

        playback.playTap(fileName: fileName, ext: ext, volume: volume)
    }

    /// Phát âm thanh click từ cấu hình JSON (nếu không truyền hoặc không tìm thấy, mặc định là "tap")
    func playClickSound(named soundName: String?, volume: Float = 1.0) {
        guard isSfxEnabled else { return }
        let now = CACurrentMediaTime()
        guard now - lastClickSoundTime >= 0.035 else { return } // Throttle click sounds chống nghẽn audio khi tap nhiều cây cùng lúc
        lastClickSoundTime = now

        let cleanName = (soundName ?? "").trimmingCharacters(in: .whitespaces)
        let targetName = cleanName.isEmpty ? "tap" : cleanName
        let baseName = (targetName as NSString).deletingPathExtension
        let fileExt = (targetName as NSString).pathExtension.isEmpty ? "mp3" : (targetName as NSString).pathExtension

        if Bundle.main.url(forResource: baseName, withExtension: fileExt) != nil {
            playTap(fileName: baseName, ext: fileExt, volume: volume)
        } else {
            playTap(fileName: "tap", ext: "mp3", volume: volume)
        }
    }

    // MARK: - Sound Effects (có thể chồng nhiều hiệu ứng)

    func playSFX(fileName: String, ext: String = "mp3", volume: Float = 1.0) {
        guard isSfxEnabled else { return }
        guard AudioSessionController.isActive else {
            let generation = sfxGeneration
            AudioSessionController.activate { [weak self] in
                guard let self, self.sfxGeneration == generation else { return }
                self.playSFX(fileName: fileName, ext: ext, volume: volume)
            }
            return
        }

        playback.playSFX(fileName: fileName, ext: ext, volume: volume)
    }

    func stopAllSFX() {
        sfxGeneration += 1
        playback.stopAllSFX()
    }
}

/// Owns every player exclusively on one serial queue, including creation and teardown.
/// @unchecked Sendable is safe because mutable state is accessed only on `queue`.
nonisolated private final class AudioPlaybackQueue: @unchecked Sendable {
    private let queue = DispatchQueue(label: "terrarium.audio-playback", qos: .userInitiated)
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private var soundPool: [String: [AVAudioPlayer]] = [:]
    private let maxPlayersPerSound = 4

    func preload() {
        queue.async { self.preloadCommonSounds() }
    }

    private func preloadCommonSounds() {
        dispatchPrecondition(condition: .onQueue(queue))
        let key = "tap.mp3"
        guard let url = Bundle.main.url(forResource: "tap", withExtension: "mp3") else { return }
        var list: [AVAudioPlayer] = []
        for _ in 0..<maxPlayersPerSound {
            if let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                list.append(p)
            }
        }
        soundPool[key] = list
    }

    /// Lấy player rảnh từ pool hoặc tạo mới nếu cần
    private func getOrCreatePlayer(fileName: String, ext: String) -> AVAudioPlayer? {
        dispatchPrecondition(condition: .onQueue(queue))
        let key = "\(fileName).\(ext)"
        if var list = soundPool[key] {
            if let idle = list.first(where: { !$0.isPlaying }) {
                return idle
            }
            if list.count < maxPlayersPerSound,
               let url = Bundle.main.url(forResource: fileName, withExtension: ext),
               let newPlayer = try? AVAudioPlayer(contentsOf: url) {
                newPlayer.prepareToPlay()
                list.append(newPlayer)
                soundPool[key] = list
                return newPlayer
            }
            return list.first
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        player.prepareToPlay()
        soundPool[key] = [player]
        return player
    }

    func playBGM(fileName: String, ext: String, volume: Float, loop: Bool) {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("❌ Không tìm thấy BGM: \(fileName).\(ext)")
                return
            }

            do {
                self.bgmPlayer = try AVAudioPlayer(contentsOf: url)
                self.bgmPlayer?.volume = volume
                self.bgmPlayer?.numberOfLoops = loop ? -1 : 0
                self.bgmPlayer?.prepareToPlay()
                self.bgmPlayer?.play()
                print("🎵 BGM playing: \(fileName).\(ext)")
            } catch {
                print("❌ Lỗi play BGM:", error)
            }
        }
    }

    func playTap(fileName: String, ext: String, volume: Float) {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            guard let player = self.getOrCreatePlayer(fileName: fileName, ext: ext) else {
                print("❌ Không tìm thấy TAP: \(fileName).\(ext)")
                return
            }

            player.volume = volume
            player.currentTime = 0
            player.play()
        }
    }

    func playSFX(fileName: String, ext: String, volume: Float) {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
                print("❌ Không tìm thấy SFX: \(fileName).\(ext)")
                return
            }

            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.volume = volume
                p.prepareToPlay()
                p.play()

                // giữ reference để không bị dealloc
                self.sfxPlayers.append(p)

                // dọn những player đã phát xong
                self.sfxPlayers.removeAll { !$0.isPlaying }

            } catch {
                print("❌ Lỗi play SFX:", error)
            }
        }
    }

    func stopBGM() {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            self.bgmPlayer?.stop()
            self.bgmPlayer = nil
        }
    }

    func stopAllSFX() {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            self.sfxPlayers.forEach { $0.stop() }
            self.sfxPlayers.removeAll()
            for list in self.soundPool.values {
                list.forEach { $0.stop() }
            }
        }
    }

}

/// Serializes process-wide session activation without blocking the UI.
@MainActor
enum AudioSessionController {
    private(set) static var isActive = false
    private static var isActivating = false
    private static var generation = 0
    private static var completions: [@MainActor () -> Void] = []
    private static let queue = DispatchQueue(label: "terrarium.audio-session", qos: .userInitiated)

    static func invalidate() {
        generation += 1
        isActive = false
        completions.removeAll()
    }

    static func activate(completion: (@MainActor () -> Void)? = nil) {
        if isActive {
            completion?()
            return
        }
        if let completion { completions.append(completion) }
        guard !isActivating else { return }
        isActivating = true
        let requestGeneration = generation
        queue.async {
            let succeeded: Bool
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                succeeded = true
            } catch {
                print("⚠️ Lỗi thiết lập AVAudioSession:", error)
                succeeded = false
            }
            Task { @MainActor in
                isActivating = false
                guard requestGeneration == generation else {
                    if !completions.isEmpty { activate() }
                    return
                }
                isActive = succeeded
                let pending = completions
                completions.removeAll()
                if succeeded { pending.forEach { $0() } }
            }
        }
    }
}

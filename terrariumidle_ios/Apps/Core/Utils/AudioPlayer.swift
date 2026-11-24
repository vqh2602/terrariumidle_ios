import AVFoundation

@MainActor
final class AudioPlayer {
    static let shared = AudioPlayer()

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []   // để chồng nhiều effect

    /// Pool player âm thanh ngắn (tối đa 4 player cho mỗi âm thanh để tap nhanh không bị trễ hay ngắt quãng)
    private var soundPool: [String: [AVAudioPlayer]] = [:]
    private let maxPlayersPerSound = 4
    private var lastClickSoundTime: TimeInterval = 0

    var isBgmEnabled = true
    var isSfxEnabled = true

    private init() {
        configureAudioSessionAsync()
        preloadCommonSounds()
    }

    /// Cấu hình AudioSession bất đồng bộ trên background thread hoàn toàn,
    /// sử dụng category .playback (không có .mixWithOthers) để kích hoạt Now Playing trên thanh thông báo/màn hình khóa iOS
    private func configureAudioSessionAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
            } catch {
                print("⚠️ Lỗi thiết lập AVAudioSession:", error)
            }
        }
    }

    private func preloadCommonSounds() {
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

    // MARK: - Background Music

    func playBGM(fileName: String, ext: String = "mp3", volume: Float = 0.6, loop: Bool = true) {
        guard isBgmEnabled else { return }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ Không tìm thấy BGM: \(fileName).\(ext)")
            return
        }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.volume = volume
            bgmPlayer?.numberOfLoops = loop ? -1 : 0
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
            print("🎵 BGM playing: \(fileName).\(ext)")
        } catch {
            print("❌ Lỗi play BGM:", error)
        }
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
    }

    // MARK: - Tap Sound (Sử dụng Pool tái sử dụng, không block Main Thread khi tap liên tục)

    func playTap(fileName: String = "tap", ext: String = "mp3", volume: Float = 1.0) {
        guard isSfxEnabled else { return }

        guard let player = getOrCreatePlayer(fileName: fileName, ext: ext) else {
            print("❌ Không tìm thấy TAP: \(fileName).\(ext)")
            return
        }

        player.volume = volume
        player.currentTime = 0
        player.play()
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
            sfxPlayers.append(p)

            // dọn những player đã phát xong
            sfxPlayers.removeAll { !$0.isPlaying }

        } catch {
            print("❌ Lỗi play SFX:", error)
        }
    }

    func stopAllSFX() {
        sfxPlayers.forEach { $0.stop() }
        sfxPlayers.removeAll()
        for list in soundPool.values {
            list.forEach { $0.stop() }
        }
    }
}

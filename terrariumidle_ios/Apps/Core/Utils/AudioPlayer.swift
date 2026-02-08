import AVFoundation

@MainActor
final class AudioPlayer {
    static let shared = AudioPlayer()

    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []   // để chồng nhiều effect
    private var tapPlayer: AVAudioPlayer?

    var isBgmEnabled = true
    var isSfxEnabled = true

    private init() {}

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

    // MARK: - Tap Sound (1 cái ngắn, không cần chồng)

    func playTap(fileName: String = "tap", ext: String = "mp3", volume: Float = 1.0) {
        guard isSfxEnabled else { return }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            print("❌ Không tìm thấy TAP: \(fileName).\(ext)")
            return
        }

        do {
            tapPlayer = try AVAudioPlayer(contentsOf: url)
            tapPlayer?.volume = volume
            tapPlayer?.prepareToPlay()
            tapPlayer?.play()
        } catch {
            print("❌ Lỗi play TAP:", error)
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
        tapPlayer?.stop()
        tapPlayer = nil
    }
}

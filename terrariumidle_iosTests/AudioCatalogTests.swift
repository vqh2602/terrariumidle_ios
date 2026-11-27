import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct AudioCatalogTests {
    @Test func defaultTrackIsUnlockedUsingItsCatalogID() {
        let unlockedIDs = MusicUnlockHelper.getUnlockedMusicIds(from: nil)
        #expect(unlockedIDs.contains("music1"))
        #expect(unlockedIDs.contains("m0"))
        #expect(!unlockedIDs.contains("music2"))
    }

    @Test func everyMusicTrackHasABundledSoundFile() {
        let tracks = ItemDataManager.shared.getAllMusics()
        #expect(!tracks.isEmpty)
        for track in tracks {
            // Catalog IDs such as music2 are distinct from audio names such as m1.
            let sound = track.sound ?? track.id
            let url = Bundle.main.url(forResource: sound, withExtension: "mp3")
                ?? Bundle.main.url(forResource: sound, withExtension: "MP3")
            #expect(url != nil, "Missing audio for \(track.id): \(sound)")
        }
    }

    @Test func everySFXHasABundledSoundFile() {
        let items = ItemDataManager.shared.getAllMusicsSFX()
        #expect(!items.isEmpty)
        for item in items {
            // Older SFX use their ID; newer SFX specify a separate audio filename.
            let sound = item.sound ?? item.id
            let url = Bundle.main.url(forResource: sound, withExtension: "mp3")
                ?? Bundle.main.url(forResource: sound, withExtension: "MP3")
            #expect(url != nil, "Missing audio for \(item.id): \(sound)")
        }
        #expect(items.first { $0.id == "sfx1" }?.sound == nil)
        #expect(items.first { $0.id == "sfx9" }?.sound == "cat_purring")
    }
}

@Suite(.serialized)
@MainActor
struct AudioSleepTimerTests {
    @Test func addingTimeExtendsDeadlineBeyondTwoHours() throws {
        let audio = BackgroundAudioManager.shared
        defer { audio.cancelSleepTimer() }
        audio.cancelSleepTimer()
        audio.addSleepTimer(minutes: 120)
        let firstDeadline = try #require(audio.sleepTimerDeadline)
        audio.addSleepTimer(minutes: 60)
        let extendedDeadline = try #require(audio.sleepTimerDeadline)
        #expect(abs(extendedDeadline.timeIntervalSince(firstDeadline) - 3600) < 0.001)
        audio.addSleepTimer(minutes: 15)
        let finalDeadline = try #require(audio.sleepTimerDeadline)
        #expect(abs(finalDeadline.timeIntervalSince(extendedDeadline) - 900) < 0.001)
        audio.expireSleepTimerIfNeeded(now: firstDeadline)
        #expect(audio.sleepTimerDeadline == finalDeadline)
        audio.addSleepTimer(minutes: 0)
        audio.addSleepTimer(minutes: -5)
        #expect(audio.sleepTimerDeadline == finalDeadline)
    }

    @Test func replacingAndCancellingTimerDoesNotStopPlayback() throws {
        let audio = BackgroundAudioManager.shared
        defer { audio.cancelSleepTimer() }
        let generation = audio.captureAudioSnapshot().sleepStopGeneration
        audio.setSleepTimer(minutes: 15)
        let oldDeadline = try #require(audio.sleepTimerDeadline)
        audio.setSleepTimer(minutes: 60)
        let newDeadline = try #require(audio.sleepTimerDeadline)
        #expect(newDeadline.timeIntervalSince(oldDeadline) > 44 * 60)
        audio.expireSleepTimerIfNeeded(now: oldDeadline)
        #expect(audio.sleepTimerDeadline == newDeadline)
        audio.cancelSleepTimer()
        audio.expireSleepTimerIfNeeded(now: newDeadline)
        #expect(audio.sleepTimerDeadline == nil)
        #expect(audio.captureAudioSnapshot().sleepStopGeneration == generation)
    }

    @Test func deadlineStopsAudioOnlyOnceAndInvalidatesOldSnapshots() throws {
        let audio = BackgroundAudioManager.shared
        defer { audio.cancelSleepTimer() }
        let snapshot = audio.captureAudioSnapshot()
        audio.setSleepTimer(minutes: 15)
        let deadline = try #require(audio.sleepTimerDeadline)
        audio.expireSleepTimerIfNeeded(now: deadline.addingTimeInterval(-1))
        #expect(audio.sleepTimerDeadline == deadline)
        audio.expireSleepTimerIfNeeded(now: deadline)
        #expect(audio.sleepTimerDeadline == nil)
        #expect(!audio.isPlaying)
        #expect(audio.activeSFXIds.isEmpty)
        #expect(audio.captureAudioSnapshot().sleepStopGeneration == snapshot.sleepStopGeneration + 1)
        audio.restoreAudioSnapshot(snapshot)
        audio.expireSleepTimerIfNeeded(now: deadline.addingTimeInterval(60))
        #expect(!audio.isPlaying)
        #expect(audio.captureAudioSnapshot().sleepStopGeneration == snapshot.sleepStopGeneration + 1)
    }
}

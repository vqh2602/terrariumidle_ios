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
}

import Foundation

enum WatchGardenCache {
    // Only the watch app and its complication share this group.
    static let group = "group.vqhapp.terrariumidle.watch"
    private static let key = "garden.snapshot.v1"

    static func read() -> WatchGardenSnapshot {
        guard let data = UserDefaults(suiteName: group)?.data(forKey: key),
              var snapshot = try? JSONDecoder().decode(WatchGardenSnapshot.self, from: data),
              snapshot.isValid else { return WatchGardenSnapshot() }
        if let weather = snapshot.weather, !weather.isFresh(at: .now) {
            snapshot.weather = nil
            write(snapshot)
        }
        return snapshot
    }

    static func write(_ snapshot: WatchGardenSnapshot) {
        var cached = snapshot
        if let weather = cached.weather, !weather.isFresh(at: .now) { cached.weather = nil }
        guard cached.isValid, let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults(suiteName: group)?.set(data, forKey: key)
    }
}

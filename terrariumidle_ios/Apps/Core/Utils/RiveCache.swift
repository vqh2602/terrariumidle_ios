//
//  RiveCache.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 2/2/26.
//

import Foundation

enum RiveCache {

    // ⏱️ thời gian cache: 1 ngày
    static let cacheDuration: TimeInterval = 60 * 60 * 24 // 24h

    static func cacheDirectory() -> URL {
        let dir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("RiveCache", isDirectory: true)

        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
        return dir
    }

    static func localURL(for remoteURL: String) -> URL {
        let fileName = URL(string: remoteURL)!.lastPathComponent
        return cacheDirectory().appendingPathComponent(fileName)
    }

    static func isCacheValid(_ url: URL) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date else {
            return false
        }
        return Date().timeIntervalSince(modified) < cacheDuration
    }

    static func getOrDownload(remoteURL: String) async throws -> URL {
        let localURL = localURL(for: remoteURL)

        // ✅ Có file & còn hạn
        if FileManager.default.fileExists(atPath: localURL.path),
           isCacheValid(localURL) {
            return localURL
        }

        // ⬇️ Hết hạn hoặc chưa có → tải lại
        let (data, _) = try await URLSession.shared.data(
            from: URL(string: remoteURL)!
        )

        try data.write(to: localURL, options: .atomic)
        return localURL
    }
}

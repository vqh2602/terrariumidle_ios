import Foundation
import Testing
import UIKit
@testable import terrariumidle_ios

struct ImageCacheTests {
    private func makeTestImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        return image.pngData()!
    }

    private func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageCacheTests-\(UUID().uuidString)", isDirectory: true)
    }

    @Test func cachesToMemoryAndPersistsAcrossInstancesOnDisk() async throws {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageData = makeTestImageData()
        let url = URL(string: "https://example.com/terrarium/plant_preview.png")!
        var networkCalls = 0
        let lock = NSLock()

        let cache1 = ImageCache(
            diskDirectory: tempDir,
            fetcher: { request in
                lock.lock()
                networkCalls += 1
                lock.unlock()
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (imageData, response)
            }
        )

        let first = await cache1.loadImage(for: url)
        #expect(first != nil)
        #expect(cache1.cachedImageInMemory(for: url) != nil)
        #expect(networkCalls == 1)

        // Second load from same instance hits memory cache
        let second = await cache1.loadImage(for: url)
        #expect(second != nil)
        #expect(networkCalls == 1)

        // Give async disk write a brief moment to complete
        try await Task.sleep(for: .milliseconds(150))

        // New ImageCache instance (empty RAM) should read from disk without hitting network
        let cache2 = ImageCache(
            diskDirectory: tempDir,
            fetcher: { _ in
                Issue.record("Expected disk cache hit without network call")
                throw URLError(.badURL)
            }
        )
        #expect(cache2.cachedImageInMemory(for: url) == nil)
        let fromDisk = await cache2.loadImage(for: url)
        #expect(fromDisk != nil)
        #expect(cache2.cachedImageInMemory(for: url) != nil)
    }

    @Test func coalescesConcurrentRequestsForSameURL() async {
        let tempDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imageData = makeTestImageData()
        let url = URL(string: "https://example.com/terrarium/avatar.png")!
        var networkCalls = 0
        let lock = NSLock()

        let cache = ImageCache(
            diskDirectory: tempDir,
            fetcher: { request in
                lock.lock()
                networkCalls += 1
                lock.unlock()
                try await Task.sleep(for: .milliseconds(80))
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (imageData, response)
            }
        )

        async let a = cache.loadImage(for: url)
        async let b = cache.loadImage(for: url)
        async let c = cache.loadImage(for: url)

        let results = await [a, b, c]
        #expect(results.allSatisfy { $0 != nil })
        #expect(networkCalls == 1)
    }
}

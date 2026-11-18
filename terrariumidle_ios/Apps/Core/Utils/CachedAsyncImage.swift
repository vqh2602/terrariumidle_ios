//
//  CachedAsyncImage.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

import AppIntents
import SwiftUI

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        // Configure memory cache limits
        cache.countLimit = 100 // Max 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit

        // Configure URLCache for disk caching
        let memoryCapacity = 50 * 1024 * 1024 // 50MB
        let diskCapacity = 200 * 1024 * 1024 // 200MB
        let urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = urlCache
    }

    func image(for url: NSURL) -> UIImage? {
        cache.object(forKey: url)
    }

    func set(_ image: UIImage, for url: NSURL) {
        // Estimate cost based on image size
        let cost = Int(image.size.width * image.size.height * 4) // 4 bytes per pixel (RGBA)
        cache.setObject(image, forKey: url, cost: cost)
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .onAppear { load() }
            }
        }
    }

    private func load() {
        guard let url else { return }

        if let cached = ImageCache.shared.image(for: url as NSURL) {
            uiImage = cached
            return
        }

        Task {
            do {
                // Use URLSession with caching enabled
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad

                let (data, response) = try await URLSession.shared.data(for: request)

                // Cache the response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200
                {
                    let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                }

                if let image = UIImage(data: data) {
                    ImageCache.shared.set(image, for: url as NSURL)
                    await MainActor.run { uiImage = image }
                }
            } catch {
                print("❌ Load image error for \(url.absoluteString):", error)
            }
        }
    }
}

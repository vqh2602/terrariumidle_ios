//
//  CachedAsyncImage.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

import SwiftUI
import AppIntents

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: NSURL) -> UIImage? { cache.object(forKey: url) }
    func set(_ image: UIImage, for url: NSURL) { cache.setObject(image, forKey: url) }
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
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    ImageCache.shared.set(image, for: url as NSURL)
                    await MainActor.run { uiImage = image }
                }
            } catch {
                print("❌ Load image error:", error)
            }
        }
    }
}

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
    let rawNameOrUrl: String?
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
        let raw = url?.absoluteString
        self.rawNameOrUrl = raw
        self.content = content
        self.placeholder = placeholder
        _uiImage = State(initialValue: Self.resolveLocalImage(from: raw))
    }

    init(
        named nameOrUrl: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.rawNameOrUrl = nameOrUrl
        self.url = nameOrUrl.flatMap { URL(string: $0) }
        self.content = content
        self.placeholder = placeholder
        _uiImage = State(initialValue: Self.resolveLocalImage(from: nameOrUrl))
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

    /// Tìm nạp ảnh từ Asset Catalog cục bộ (Zero Network)
    public static func resolveLocalImage(from rawString: String?) -> UIImage? {
        guard let raw = rawString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }

        // Bỏ qua nếu là URL mạng
        if raw.lowercased().hasPrefix("http://") || raw.lowercased().hasPrefix("https://") {
            return nil
        }

        // 1. Tìm trực tiếp theo tên
        if let img = UIImage(named: raw) { return img }

        // 2. Thử thêm hậu tố @4.167x
        if let img = UIImage(named: "\(raw)@4.167x") { return img }

        // 3. Đổi dấu gạch dưới thành gạch ngang hoặc ngược lại (pot1_Asset-1 <-> pot1-Asset-1)
        let dash = raw.replacingOccurrences(of: "_", with: "-")
        if let img = UIImage(named: dash) { return img }
        if let img = UIImage(named: "\(dash)@4.167x") { return img }

        let underscore = raw.replacingOccurrences(of: "-", with: "_")
        if let img = UIImage(named: underscore) { return img }
        if let img = UIImage(named: "\(underscore)@4.167x") { return img }

        // 4. Nếu là chuỗi dạng "plantX_Asset-1" hoặc "potX_Asset-1" -> tìm theo base ID
        if raw.contains("Asset-1") {
            let baseId = raw.replacingOccurrences(of: "_Asset-1", with: "")
                            .replacingOccurrences(of: "-Asset-1", with: "")
            if let img = UIImage(named: baseId) { return img }
            if let img = UIImage(named: "\(baseId)@4.167x") { return img }
        }

        // 5. Nếu là chuỗi base ID (như "pot1" hoặc "plant1") -> tìm các biến thể Asset-1
        let variants = [
            "\(raw)_Asset-1",
            "\(raw)-Asset-1",
            "\(raw)_Asset-1@4.167x",
            "\(raw)-Asset-1@4.167x"
        ]
        for v in variants {
            if let img = UIImage(named: v) { return img }
        }

        return nil
    }

    private func load() {
        if uiImage != nil { return }

        let rawString = rawNameOrUrl ?? url?.absoluteString

        // 1. Kiểm tra lại local asset
        if let local = Self.resolveLocalImage(from: rawString) {
            self.uiImage = local
            return
        }

        // 2. Tuyệt đối không dùng mạng nếu không phải URL http/https hợp lệ
        guard let url = url ?? (rawString.flatMap { URL(string: $0) }),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return
        }

        // 3. Fallback cho URL mạng cũ (nếu còn)
        if let cached = ImageCache.shared.image(for: url as NSURL) {
            uiImage = cached
            return
        }

        Task {
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad

                let (data, response) = try await URLSession.shared.data(for: request)

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

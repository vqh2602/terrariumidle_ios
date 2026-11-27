//
//  CachedAsyncImage.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

import AppIntents
import CryptoKit
import SwiftUI

/// Bộ nhớ đệm ảnh 2 tầng (Memory + Disk) kèm gộp request trùng lặp cho ảnh tải từ mạng.
final class ImageCache {
    static let shared = ImageCache()

    typealias DataFetcher = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskDirectory: URL
    private let maxDiskSize: Int
    private let maxCacheAge: TimeInterval
    private let fetcher: DataFetcher
    private let ioQueue = DispatchQueue(label: "vqhapp.terrariumidle.imagecache.io", qos: .utility)

    private let lock = NSLock()
    private var inFlightTasks: [URL: Task<UIImage?, Never>] = [:]

    init(
        diskDirectory: URL? = nil,
        maxMemoryCount: Int = 150,
        maxMemoryCost: Int = 60 * 1024 * 1024,
        maxDiskSize: Int = 200 * 1024 * 1024,
        maxCacheAge: TimeInterval = 7 * 24 * 60 * 60,
        fetcher: DataFetcher? = nil
    ) {
        self.memoryCache.countLimit = maxMemoryCount
        self.memoryCache.totalCostLimit = maxMemoryCost
        self.maxDiskSize = maxDiskSize
        self.maxCacheAge = maxCacheAge

        if let diskDirectory {
            self.diskDirectory = diskDirectory
        } else {
            let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.diskDirectory = caches.appendingPathComponent("TerrariumImageCache", isDirectory: true)
        }

        if let fetcher {
            self.fetcher = fetcher
        } else {
            let config = URLSessionConfiguration.default
            config.urlCache = URLCache(memoryCapacity: 32 * 1024 * 1024, diskCapacity: maxDiskSize)
            config.requestCachePolicy = .returnCacheDataElseLoad
            let session = URLSession(configuration: config)
            self.fetcher = { request in
                try await session.data(for: request)
            }
        }

        try? fileManager.createDirectory(at: self.diskDirectory, withIntermediateDirectories: true)
    }

    /// Lấy nhanh từ RAM (đồng bộ, dùng được ngay trong `init` của View để tránh chớp placeholder).
    func cachedImageInMemory(for url: URL) -> UIImage? {
        memoryCache.object(forKey: url.absoluteString as NSString)
    }

    /// Tương thích ngược với các caller cũ dùng `NSURL`.
    func image(for url: NSURL) -> UIImage? {
        cachedImageInMemory(for: url as URL)
    }

    func set(_ image: UIImage, for url: NSURL) {
        let targetURL = url as URL
        storeInMemory(image, for: targetURL)
        if let data = image.pngData() ?? image.jpegData(compressionQuality: 0.92) {
            writeToDisk(data: data, for: targetURL)
        }
    }

    /// Lấy ảnh theo thứ tự: RAM -> Disk -> Network (tự động gộp các request trùng URL).
    func loadImage(for url: URL) async -> UIImage? {
        if let memoryImage = cachedImageInMemory(for: url) {
            return memoryImage
        }

        if let diskImage = await readFromDisk(for: url) {
            storeInMemory(diskImage, for: url)
            return diskImage
        }

        let task = inFlightTask(for: url)
        return await task.value
    }

    func storeInMemory(_ image: UIImage, for url: URL) {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let cost = max(1, Int(pixelWidth * pixelHeight * 4))
        memoryCache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func clearCache() {
        memoryCache.removeAllObjects()
        ioQueue.sync {
            try? fileManager.removeItem(at: diskDirectory)
            try? fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - In-Flight Coalescing

    private func inFlightTask(for url: URL) -> Task<UIImage?, Never> {
        lock.lock()
        if let existing = inFlightTasks[url] {
            lock.unlock()
            return existing
        }

        let task = Task<UIImage?, Never> { [weak self] in
            guard let self else { return nil }
            defer { self.removeInFlightTask(for: url) }
            return await self.fetchAndCache(url: url)
        }
        inFlightTasks[url] = task
        lock.unlock()
        return task
    }

    private func removeInFlightTask(for url: URL) {
        lock.lock()
        inFlightTasks.removeValue(forKey: url)
        lock.unlock()
    }

    private func fetchAndCache(url: URL) async -> UIImage? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await fetcher(request)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                return nil
            }
            guard let image = UIImage(data: data) else {
                return nil
            }
            storeInMemory(image, for: url)
            writeToDisk(data: data, for: url)
            return image
        } catch {
            return nil
        }
    }

    // MARK: - Disk Cache

    private func diskFileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return diskDirectory.appendingPathComponent(hash, isDirectory: false)
    }

    private func readFromDisk(for url: URL) async -> UIImage? {
        let fileURL = diskFileURL(for: url)
        let maxAge = maxCacheAge

        return await withCheckedContinuation { continuation in
            ioQueue.async { [fileManager] in
                guard fileManager.fileExists(atPath: fileURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }

                if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let modified = attrs[.modificationDate] as? Date,
                   Date().timeIntervalSince(modified) > maxAge {
                    try? fileManager.removeItem(at: fileURL)
                    continuation.resume(returning: nil)
                    return
                }

                guard let data = try? Data(contentsOf: fileURL),
                      let image = UIImage(data: data) else {
                    try? fileManager.removeItem(at: fileURL)
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }

    private func writeToDisk(data: Data, for url: URL) {
        let fileURL = diskFileURL(for: url)
        let maxSize = maxDiskSize
        let maxAge = maxCacheAge
        let directory = diskDirectory

        ioQueue.async { [fileManager] in
            if !fileManager.fileExists(atPath: directory.path) {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            try? data.write(to: fileURL, options: .atomic)
            Self.trimDiskCacheIfNeeded(
                fileManager: fileManager,
                directory: directory,
                maxSize: maxSize,
                maxAge: maxAge
            )
        }
    }

    private static func trimDiskCacheIfNeeded(
        fileManager: FileManager,
        directory: URL,
        maxSize: Int,
        maxAge: TimeInterval
    ) {
        let keys: Set<URLResourceKey> = [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
        guard let urls = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        let now = Date()
        var entries: [(url: URL, modified: Date, size: Int)] = []
        var totalSize = 0

        for fileURL in urls {
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { continue }
            let modified = values.contentModificationDate ?? now
            let size = values.fileSize ?? 0

            if now.timeIntervalSince(modified) > maxAge {
                try? fileManager.removeItem(at: fileURL)
                continue
            }

            totalSize += size
            entries.append((fileURL, modified, size))
        }

        guard totalSize > maxSize else { return }

        entries.sort { $0.modified < $1.modified }
        for entry in entries {
            try? fileManager.removeItem(at: entry.url)
            totalSize -= entry.size
            if totalSize <= maxSize {
                break
            }
        }
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let rawNameOrUrl: String?
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var loadedSource: String?

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
        _uiImage = State(initialValue: Self.initialImage(from: raw, url: url))
        _loadedSource = State(initialValue: raw)
    }

    init(
        named nameOrUrl: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.rawNameOrUrl = nameOrUrl
        let resolvedURL = nameOrUrl.flatMap { URL(string: $0) }
        self.url = resolvedURL
        self.content = content
        self.placeholder = placeholder
        _uiImage = State(initialValue: Self.initialImage(from: nameOrUrl, url: resolvedURL))
        _loadedSource = State(initialValue: nameOrUrl)
    }

    var body: some View {
        Group {
            if loadedSource == rawNameOrUrl, let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: rawNameOrUrl) {
            await load()
        }
    }

    private static func initialImage(from rawString: String?, url: URL?) -> UIImage? {
        if let local = resolveLocalImage(from: rawString) {
            return local
        }
        if let url,
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            return ImageCache.shared.cachedImageInMemory(for: url)
        }
        return nil
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

        // Đổi khoảng trắng thành gạch ngang hoặc ngược lại (Dracaena trifasciata <-> Dracaena-trifasciata)
        let spaceToDash = raw.replacingOccurrences(of: " ", with: "-")
        if let img = UIImage(named: spaceToDash) { return img }
        if let img = UIImage(named: "\(spaceToDash)@4.167x") { return img }

        let dashToSpace = raw.replacingOccurrences(of: "-", with: " ")
        if let img = UIImage(named: dashToSpace) { return img }
        if let img = UIImage(named: "\(dashToSpace)@4.167x") { return img }

        if let unencoded = raw.removingPercentEncoding, unencoded != raw {
            if let img = resolveLocalImage(from: unencoded) { return img }
        }

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

    @MainActor
    private func load() async {
        guard !Task.isCancelled else { return }

        let rawString = rawNameOrUrl
        loadedSource = rawString
        uiImage = nil

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

        // 3. Nạp từ RAM -> Disk -> Network
        if let image = await ImageCache.shared.loadImage(for: url) {
            guard !Task.isCancelled, loadedSource == rawString else { return }
            uiImage = image
        }
    }
}

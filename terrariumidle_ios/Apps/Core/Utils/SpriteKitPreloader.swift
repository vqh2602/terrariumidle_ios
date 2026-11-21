//
//  SpriteKitPreloader.swift
//  terrariumidle_ios
//
//  Preload texture + scene cache trong background thread khi Splash đang hiển thị,
//  giúp các SpriteKit scene load ngay lập tức khi vào Home - không còn màu xám.
//

import SpriteKit
import UIKit

@MainActor
final class SpriteKitPreloader {

    static let shared = SpriteKitPreloader()
    private(set) var isReady: Bool = false

    private init() {}

    // MARK: - Danh sách scene & texture cần preload

    /// Tên các .sks file cần warm-up (sẽ được SKScene(fileNamed:) cache lại)
    private static let sksSceneNames: [String] = (1...19).map { "Plant\($0)Scene" }
        + (1...19).map { "Pot\($0)Scene" }
        + ["Landscape1Scene"]

    /// Tên các texture/image từ Assets.xcassets cần preload vào GPU memory
    /// nonisolated để có thể dùng từ nonisolated context (preloadTextures)
    private nonisolated static let textureNames: [String] = {
        var names: [String] = []
        // Plant assets: seed (100), sprout (200), leaves (2..12)
        for p in 1...19 {
            names.append("plant\(p)_Asset-100@4.167x")
            names.append("plant\(p)_Asset-200@4.167x")
            for leaf in 2...12 {
                names.append("plant\(p)_Asset-\(leaf)@4.167x")
            }
        }
        // Pot assets: body (1), shadow (5..8)
        for p in 1...19 {
            for part in 1...6 {
                names.append("pot\(p)_Asset-\(part)@4.167x")
            }
        }
        return names
    }()

    // MARK: - Preload Entry Point

    /// Gọi từ SplashViewModel.checkAuthAndNavigate() ở background
    /// Chạy trên nonisolated Task để không block MainActor
    nonisolated func preload() async {
        // 1. Preload textures vào GPU cache (thread-safe với SKTexture)
        await preloadTextures()

        // 2. Warm-up SKScene(fileNamed:) cache (phải trên MainActor vì SKScene init không thread-safe)
        await MainActor.run {
            warmUpSceneCache()
            isReady = true
            print("✅ SpriteKitPreloader: Hoàn thành preload \(Self.textureNames.count) textures + \(Self.sksSceneNames.count) scenes")
        }
    }

    // MARK: - Texture Preload

    private nonisolated func preloadTextures() async {
        // Lọc chỉ những texture thực sự tồn tại trong bundle
        let existingNames = Self.textureNames.filter { UIImage(named: $0) != nil }
        guard !existingNames.isEmpty else { return }

        let textures = existingNames.map { SKTexture(imageNamed: $0) }

        // SKTexture.preload() là async callback - wrap thành async/await
        await withCheckedContinuation { continuation in
            SKTexture.preload(textures) {
                continuation.resume()
            }
        }
        print("📦 SpriteKitPreloader: Preloaded \(textures.count)/\(Self.textureNames.count) textures vào GPU cache")
    }

    // MARK: - Scene Cache Warm-Up (phải chạy trên MainActor)

    @MainActor
    private func warmUpSceneCache() {
        // SKScene(fileNamed:) load và parse .sks file - iOS cache nội bộ sau lần đầu
        // Ta load rồi discard để fill cache, lần sau TerrariumSlotScene gọi lại sẽ instant
        for name in Self.sksSceneNames {
            _ = SKScene(fileNamed: name)
        }
        print("🎬 SpriteKitPreloader: Warmed up \(Self.sksSceneNames.count) .sks scene templates")
    }
}

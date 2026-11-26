//
//  BeeTextureCache.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Bộ đệm chia sẻ `SKTexture` dùng chung cho cả 4 chú ong và tổ ong.
/// Giúp tiết kiệm tối đa RAM khi nhiều chú ong xuất hiện hoặc Scene rebuild.
@MainActor
public final class BeeTextureCache {
    public static let shared = BeeTextureCache()

    private var cache: [String: SKTexture] = [:]

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cache.removeAll()
            }
        }
    }

    public func texture(named name: String) -> SKTexture {
        if let existing = cache[name] {
            return existing
        }
        let tex: SKTexture
        if let img = UIImage(named: name) {
            tex = SKTexture(image: img)
        } else {
            tex = SKTexture(imageNamed: name)
        }
        tex.filteringMode = .linear
        cache[name] = tex
        return tex
    }

    public func clear() {
        cache.removeAll()
    }
}

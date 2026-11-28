//
//  PestTextureCache.swift
//  terrariumidle_ios
//
//  Created by AI on 28/11/26.
//

import SpriteKit
import UIKit

/// Bộ đệm chia sẻ `SKTexture` cho Túi lưới (`animal3`), Sâu (`bug1`) và Châu chấu (`grasshopper`).
/// Giảm thiểu RAM tiêu thụ và tránh decode lại texture mỗi lần sinh sâu hoặc mở vườn.
@MainActor
public final class PestTextureCache {
    public static let shared = PestTextureCache()

    private var cache: [String: SKTexture] = [:]

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.clear()
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
        _sparkleTexture = nil
    }

    private var _sparkleTexture: SKTexture?

    public var sparkleTexture: SKTexture {
        if let tex = _sparkleTexture { return tex }
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 1, width: 10, height: 10))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _sparkleTexture = tex
        return tex
    }
}

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
        _honeyGlowTexture = nil
        _honeySparkleTexture = nil
    }

    private var _honeyGlowTexture: SKTexture?
    private var _honeySparkleTexture: SKTexture?

    /// Texture giọt mật + quầng sáng dùng chung cho `honeyCarryGlow` (thay thế SKShapeNode)
    public var honeyGlowTexture: SKTexture {
        if let tex = _honeyGlowTexture { return tex }
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            // Halo ngoài
            cg.setFillColor(UIColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 0.32).cgColor)
            cg.fillEllipse(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))
            // Giọt mật bên trong
            let dropRect = CGRect(x: center.x - 5.5, y: center.y - 5.5, width: 11, height: 11)
            cg.setFillColor(UIColor(red: 1.0, green: 0.78, blue: 0.12, alpha: 0.95).cgColor)
            cg.fillEllipse(in: dropRect)
            cg.setStrokeColor(UIColor(red: 0.95, green: 0.52, blue: 0.0, alpha: 0.9).cgColor)
            cg.setLineWidth(1.2)
            cg.strokeEllipse(in: dropRect)
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _honeyGlowTexture = tex
        return tex
    }

    /// Texture đốm sáng trắng dùng chung để tint màu cho hạt phấn/mật khi ong thu mật (thay thế SKShapeNode)
    public var honeySparkleTexture: SKTexture {
        if let tex = _honeySparkleTexture { return tex }
        let size = CGSize(width: 12, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 1, width: 10, height: 10))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _honeySparkleTexture = tex
        return tex
    }
}

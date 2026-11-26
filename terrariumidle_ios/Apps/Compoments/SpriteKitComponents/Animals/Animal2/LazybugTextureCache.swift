//
//  LazybugTextureCache.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Bộ đệm chia sẻ `SKTexture` cho chú Bọ Rùa (`animal2`) và Gốc Cây Gỗ Mục.
/// Giúp tiết kiệm tối đa RAM và giữ ổn định FPS khi chuyển trạng thái idle / sleep / fly / move.
@MainActor
public final class LazybugTextureCache {
    public static let shared = LazybugTextureCache()

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
        _barkChipTexture = nil
        _sawdustTexture = nil
        _sleepZTexture = nil
        _sparkleTexture = nil
    }

    private var _barkChipTexture: SKTexture?
    private var _sawdustTexture: SKTexture?
    private var _sleepZTexture: SKTexture?
    private var _sparkleTexture: SKTexture?

    /// Texture mảnh vỏ gỗ mục dùng chung (thay thế SKShapeNode để GPU batching hiệu quả)
    public var barkChipTexture: SKTexture {
        if let tex = _barkChipTexture { return tex }
        let size = CGSize(width: 18, height: 12)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 2, y: 4))
            path.addLine(to: CGPoint(x: 11, y: 1.5))
            path.addLine(to: CGPoint(x: 16.5, y: 5.5))
            path.addLine(to: CGPoint(x: 13.5, y: 10.5))
            path.addLine(to: CGPoint(x: 3.5, y: 9.5))
            path.close()

            cg.setFillColor(UIColor.white.cgColor)
            cg.addPath(path.cgPath)
            cg.fillPath()

            // Đường vân gỗ nhỏ bên trong
            cg.setStrokeColor(UIColor(white: 0.72, alpha: 0.85).cgColor)
            cg.setLineWidth(1.0)
            cg.move(to: CGPoint(x: 4.5, y: 5.5))
            cg.addLine(to: CGPoint(x: 13.0, y: 5.2))
            cg.strokePath()
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _barkChipTexture = tex
        return tex
    }

    /// Texture hạt bụi gỗ mịn dùng chung
    public var sawdustTexture: SKTexture {
        if let tex = _sawdustTexture { return tex }
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 1, y: 1, width: 6, height: 6))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _sawdustTexture = tex
        return tex
    }

    /// Texture chữ "Z" nhỏ nhẹ nhàng bay lên khi bọ rùa ngủ
    public var sleepZTexture: SKTexture {
        if let tex = _sleepZTexture { return tex }
        let size = CGSize(width: 18, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .heavy),
                .foregroundColor: UIColor(red: 0.98, green: 0.95, blue: 0.86, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "Z", attributes: attrs)
            str.draw(at: CGPoint(x: 3, y: 0))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        _sleepZTexture = tex
        return tex
    }

    /// Texture đốm sáng trắng dùng chung khi bọ rùa giật mình
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

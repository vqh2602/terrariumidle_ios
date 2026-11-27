//
//  EncryptedResourceLoader.swift
//  terrariumidle_ios
//
//  Decrypts AES-256-GCM encrypted assets from EncryptedVault/ in RAM.
//  In Debug builds (when EncryptedResourceKey.isConfigured == false),
//  all lookups transparently fall back to Bundle.main.
//

import AVFoundation
import CryptoKit
import ObjectiveC
import SpriteKit
import SwiftUI
import UIKit

final class EncryptedResourceLoader: @unchecked Sendable {
    static let shared = EncryptedResourceLoader()

    struct ManifestEntry: Codable {
        let f: String
        let s: Double?
    }

    private let vaultDirectory = "EncryptedVault"
    private let key: SymmetricKey?
    private let manifest: [String: ManifestEntry]
    private let imageCache = NSCache<NSString, UIImage>()
    private let textureCache = NSCache<NSString, SKTexture>()

    var isEncryptedMode: Bool {
        key != nil && !manifest.isEmpty
    }

    private init() {
        imageCache.countLimit = 400
        textureCache.countLimit = 400

        guard EncryptedResourceKey.isConfigured,
              let keyData = EncryptedResourceKey.resolveKeyData(),
              keyData.count == 32 else {
            self.key = nil
            self.manifest = [:]
            return
        }

        let symKey = SymmetricKey(data: keyData)
        guard let manifestURL = Bundle.main.url(forResource: "manifest", withExtension: "enc", subdirectory: vaultDirectory)
                ?? Bundle.main.url(forResource: "manifest", withExtension: "enc"),
              let encryptedManifest = try? Data(contentsOf: manifestURL),
              let sealedBox = try? AES.GCM.SealedBox(combined: encryptedManifest),
              let decryptedManifest = try? AES.GCM.open(sealedBox, using: symKey),
              let decoded = try? JSONDecoder().decode([String: ManifestEntry].self, from: decryptedManifest) else {
            self.key = nil
            self.manifest = [:]
            return
        }

        self.key = symKey
        self.manifest = decoded
    }

    // MARK: - Generic File Decryption

    func hasResource(name: String, ext: String, subdirectory: String? = nil) -> Bool {
        if resolveEntry(forResource: name, ext: ext, subdirectory: subdirectory) != nil {
            return true
        }
        if let subdirectory {
            return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) != nil
        }
        return Bundle.main.url(forResource: name, withExtension: ext) != nil
    }

    func data(forResource name: String, ext: String, subdirectory: String? = nil) -> Data? {
        if let entry = resolveEntry(forResource: name, ext: ext, subdirectory: subdirectory),
           let decrypted = decryptVaultFile(entry.f) {
            return decrypted
        }

        if let subdirectory,
           let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory),
           let raw = try? Data(contentsOf: url) {
            return raw
        }

        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let raw = try? Data(contentsOf: url) {
            return raw
        }

        return nil
    }

    func string(forResource name: String, ext: String, subdirectory: String? = nil) -> String? {
        guard let data = data(forResource: name, ext: ext, subdirectory: subdirectory) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func audioPlayer(fileName: String, ext: String) -> AVAudioPlayer? {
        if let entry = resolveEntry(forResource: fileName, ext: ext, subdirectory: nil),
           let decrypted = decryptVaultFile(entry.f) {
            return try? AVAudioPlayer(data: decrypted)
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
            return try? AVAudioPlayer(contentsOf: url)
        }
        return nil
    }

    // MARK: - Image & SpriteKit Texture Decryption

    func uiImage(named name: String) -> UIImage? {
        guard isEncryptedMode, !name.isEmpty else { return nil }

        let cacheKey = name as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let (entry, data) = resolveImageEntryAndData(named: name),
              let rawImage = UIImage(data: data) else {
            return nil
        }

        let targetScale = CGFloat(entry.s ?? 1.0)
        let finalImage: UIImage
        if abs(rawImage.scale - targetScale) > 0.01, let cgImage = rawImage.cgImage {
            finalImage = UIImage(cgImage: cgImage, scale: targetScale, orientation: rawImage.imageOrientation)
        } else {
            finalImage = rawImage
        }

        imageCache.setObject(finalImage, forKey: cacheKey)
        return finalImage
    }

    func skTexture(named name: String) -> SKTexture? {
        guard isEncryptedMode, !name.isEmpty else { return nil }

        let cacheKey = name as NSString
        if let cached = textureCache.object(forKey: cacheKey) {
            return cached
        }

        guard let image = uiImage(named: name) else {
            return nil
        }

        let texture = SKTexture(image: image)
        textureCache.setObject(texture, forKey: cacheKey)
        return texture
    }

    // MARK: - Runtime Swizzling (Active only in Encrypted Release Builds)

    private static let hooksInstalled: Void = {
        guard shared.isEncryptedMode else { return }
        swizzleClassMethod(
            cls: UIImage.self,
            original: NSSelectorFromString("imageNamed:"),
            swizzled: #selector(UIImage.encrypted_imageNamed(_:))
        )
        swizzleClassMethod(
            cls: UIImage.self,
            original: NSSelectorFromString("imageNamed:inBundle:compatibleWithTraitCollection:"),
            swizzled: #selector(UIImage.encrypted_imageNamed(_:in:compatibleWith:))
        )
        swizzleClassMethod(
            cls: SKTexture.self,
            original: NSSelectorFromString("textureWithImageNamed:"),
            swizzled: #selector(SKTexture.encrypted_textureWithImageNamed(_:))
        )
    }()

    static func installImageHooksIfNeeded() {
        _ = hooksInstalled
    }

    private static func swizzleClassMethod(cls: AnyClass, original: Selector, swizzled: Selector) {
        guard let metaClass = object_getClass(cls),
              let originalMethod = class_getClassMethod(cls, original),
              let swizzledMethod = class_getClassMethod(cls, swizzled) else {
            return
        }

        let didAdd = class_addMethod(
            metaClass,
            original,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        if didAdd {
            class_replaceMethod(
                metaClass,
                swizzled,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: - Private Resolution

    private func resolveEntry(forResource name: String, ext: String, subdirectory: String?) -> ManifestEntry? {
        guard isEncryptedMode else { return nil }
        let fileName = ext.isEmpty ? name : "\(name).\(ext)"
        if let subdirectory, let entry = manifest["file/\(subdirectory)/\(fileName)"] {
            return entry
        }
        if let entry = manifest["file/\(fileName)"] {
            return entry
        }
        return nil
    }

    private func resolveImageEntryAndData(named name: String) -> (ManifestEntry, Data)? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutPng = trimmed.hasSuffix(".png") ? String(trimmed.dropLast(4)) : trimmed

        let candidateKeys = [
            "img/\(trimmed)",
            "img/\(withoutPng)",
            "file/\(trimmed)",
            "file/\(withoutPng).png"
        ]

        for key in candidateKeys {
            if let entry = manifest[key], let data = decryptVaultFile(entry.f) {
                return (entry, data)
            }
        }
        return nil
    }

    private func decryptVaultFile(_ hashedFileName: String) -> Data? {
        guard let key else { return nil }
        let baseName = (hashedFileName as NSString).deletingPathExtension
        let ext = (hashedFileName as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: vaultDirectory)
                ?? Bundle.main.url(forResource: baseName, withExtension: ext),
              let encryptedData = try? Data(contentsOf: url),
              let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData),
              let decrypted = try? AES.GCM.open(sealedBox, using: key) else {
            return nil
        }

        return decrypted
    }
}

// MARK: - Objective-C Swizzle Targets

private extension UIImage {
    @objc class func encrypted_imageNamed(_ name: String) -> UIImage? {
        if let decrypted = EncryptedResourceLoader.shared.uiImage(named: name) {
            return decrypted
        }
        return encrypted_imageNamed(name)
    }

    @objc class func encrypted_imageNamed(
        _ name: String,
        in bundle: Bundle?,
        compatibleWith traitCollection: UITraitCollection?
    ) -> UIImage? {
        if (bundle == nil || bundle == Bundle.main),
           let decrypted = EncryptedResourceLoader.shared.uiImage(named: name) {
            return decrypted
        }
        return encrypted_imageNamed(name, in: bundle, compatibleWith: traitCollection)
    }
}

private extension SKTexture {
    @objc class func encrypted_textureWithImageNamed(_ name: String) -> SKTexture {
        if let decrypted = EncryptedResourceLoader.shared.skTexture(named: name) {
            return decrypted
        }
        return encrypted_textureWithImageNamed(name)
    }
}

// MARK: - SwiftUI Image Helper

extension Image {
    /// Loads from EncryptedVault in Release builds and falls back to Asset Catalog / Debug bundle.
    static func bundle(_ name: String) -> Image {
        if let uiImage = EncryptedResourceLoader.shared.uiImage(named: name) ?? UIImage(named: name) {
            return Image(uiImage: uiImage)
        }
        return Image(name)
    }
}

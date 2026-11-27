//
//  EncryptedResourceKey.swift
//  terrariumidle_ios
//
//  Placeholder key configuration for Debug builds.
//  During Release IPA builds, scripts/encrypt_vault.swift injects an obfuscated
//  AES-256 key and restores this file automatically after archiving.
//

import Foundation

enum EncryptedResourceKey {
    static let isConfigured: Bool = false

    static func resolveKeyData() -> Data? {
        return nil
    }
}

#!/usr/bin/env swift
//
//  encrypt_vault.swift
//  Builds EncryptedVault/ with AES-256-GCM encrypted assets and restores working tree after archiving.
//

import CryptoKit
import Foundation

struct ManifestEntry: Codable {
    let f: String
    let s: Double?
}

struct MoveRecord: Codable {
    let staged: String
    let original: String
}

let fm = FileManager.default

func sha256HexPrefix(_ input: String, length: Int = 16) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    return String(hex.prefix(length))
}

func encryptData(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealed = try AES.GCM.seal(data, using: key)
    guard let combined = sealed.combined else {
        throw NSError(domain: "EncryptVault", code: 1, userInfo: [NSLocalizedDescriptionKey: "AES.GCM combined nil"])
    }
    return combined
}

func stageItem(originalURL: URL, rootURL: URL, stagingURL: URL, moves: inout [MoveRecord]) throws {
    let relPath = originalURL.path.replacingOccurrences(of: rootURL.path + "/", with: "")
    let stagedURL = stagingURL.appendingPathComponent("files").appendingPathComponent(relPath)
    try fm.createDirectory(at: stagedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    if fm.fileExists(atPath: stagedURL.path) {
        try fm.removeItem(at: stagedURL)
    }
    try fm.moveItem(at: originalURL, to: stagedURL)
    moves.append(MoveRecord(staged: stagedURL.path, original: originalURL.path))
}

func restore(rootURL: URL) throws {
    let stagingURL = rootURL.appendingPathComponent("build/.asset_staging")
    let vaultURL = rootURL.appendingPathComponent("terrariumidle_ios/EncryptedVault")
    let movesFile = stagingURL.appendingPathComponent("moves.json")

    if fm.fileExists(atPath: movesFile.path) {
        let data = try Data(contentsOf: movesFile)
        let moves = try JSONDecoder().decode([MoveRecord].self, from: data)
        for record in moves.reversed() {
            let stagedURL = URL(fileURLWithPath: record.staged)
            let originalURL = URL(fileURLWithPath: record.original)
            guard fm.fileExists(atPath: stagedURL.path) else { continue }
            try fm.createDirectory(at: originalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: originalURL.path) {
                try fm.removeItem(at: originalURL)
            }
            try fm.moveItem(at: stagedURL, to: originalURL)
        }
    }

    if fm.fileExists(atPath: vaultURL.path) {
        try fm.removeItem(at: vaultURL)
    }
    if fm.fileExists(atPath: stagingURL.path) {
        try fm.removeItem(at: stagingURL)
    }
    print("==> Restored original assets and cleaned EncryptedVault.")
}

func parseScale(_ raw: String?) -> Double {
    guard let raw else { return 1.0 }
    if raw == "2x" { return 2.0 }
    if raw == "3x" { return 3.0 }
    return 1.0
}

func findImagesets(in directory: URL) -> [URL] {
    guard let enumerator = fm.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) else { return [] }

    var results: [URL] = []
    for case let url as URL in enumerator {
        if url.pathExtension == "imageset" {
            results.append(url)
            enumerator.skipDescendants()
        }
    }
    return results
}

func findFiles(in directory: URL, extensions: Set<String>) -> [URL] {
    guard fm.fileExists(atPath: directory.path),
          let enumerator = fm.enumerator(
              at: directory,
              includingPropertiesForKeys: [.isRegularFileKey],
              options: [.skipsHiddenFiles]
          ) else { return [] }

    var results: [URL] = []
    for case let url as URL in enumerator {
        if extensions.contains(url.pathExtension.lowercased()) {
            results.append(url)
        }
    }
    return results
}

func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    precondition(status == errSecSuccess, "SecRandomCopyBytes failed")
    return bytes
}

func writeObfuscatedKeySwift(keyBytes: [UInt8], to url: URL) throws {
    let mask = generateRandomBytes(count: keyBytes.count)
    let xored = zip(keyBytes, mask).map { $0 ^ $1 }
    let partA = xored.map { String(format: "0x%02X", $0) }.joined(separator: ", ")
    let partB = mask.map { String(format: "0x%02X", $0) }.joined(separator: ", ")

    let swiftSource = """
    //
    //  EncryptedResourceKey.swift
    //  terrariumidle_ios
    //
    //  Auto-generated during Release IPA build. Do not commit.
    //

    import Foundation

    enum EncryptedResourceKey {
        static let isConfigured: Bool = true

        private static let a: [UInt8] = [\(partA)]
        private static let b: [UInt8] = [\(partB)]

        static func resolveKeyData() -> Data? {
            guard a.count == b.count else { return nil }
            var out = [UInt8](repeating: 0, count: a.count)
            for i in 0..<a.count {
                out[i] = a[i] ^ b[i]
            }
            return Data(out)
        }
    }
    """
    try Data(swiftSource.utf8).write(to: url)
}

func encrypt(rootURL: URL) throws {
    let stagingURL = rootURL.appendingPathComponent("build/.asset_staging")
    if fm.fileExists(atPath: stagingURL.path) {
        print("==> Found leftover staging directory, restoring first...")
        try restore(rootURL: rootURL)
    }

    let vaultURL = rootURL.appendingPathComponent("terrariumidle_ios/EncryptedVault")
    try fm.createDirectory(at: stagingURL, withIntermediateDirectories: true)
    try fm.createDirectory(at: vaultURL, withIntermediateDirectories: true)

    let keyBytes = generateRandomBytes(count: 32)
    let key = SymmetricKey(data: Data(keyBytes))

    var moves: [MoveRecord] = []
    var manifest: [String: ManifestEntry] = [:]
    var usedEncNames = Set<String>()

    func writeEncryptedEntry(manifestKey: String, data: Data, scale: Double? = nil) throws {
        var encName = sha256HexPrefix(manifestKey) + ".enc"
        var salt = 1
        while usedEncNames.contains(encName) {
            encName = sha256HexPrefix("\(manifestKey)#\(salt)") + ".enc"
            salt += 1
        }
        usedEncNames.insert(encName)
        let encrypted = try encryptData(data, using: key)
        try encrypted.write(to: vaultURL.appendingPathComponent(encName))
        manifest[manifestKey] = ManifestEntry(f: encName, s: scale)
    }

    // 1. Remove design/doc files from bundle staging (.svg, .md, RawAssets)
    let designDirs = [
        "terrariumidle_ios/Resources/SVGAnimals",
        "terrariumidle_ios/Resources/SVGLandscape",
        "terrariumidle_ios/Resources/SVGPlants",
        "terrariumidle_ios/Resources/SVGPots",
        "terrariumidle_ios/Resources/SVGSticker",
        "terrariumidle_ios/Resources/RawAssets"
    ]
    for rel in designDirs {
        let dirURL = rootURL.appendingPathComponent(rel)
        if fm.fileExists(atPath: dirURL.path) {
            try stageItem(originalURL: dirURL, rootURL: rootURL, stagingURL: stagingURL, moves: &moves)
        }
    }

    let strayFiles = findFiles(
        in: rootURL.appendingPathComponent("terrariumidle_ios"),
        extensions: ["svg", "md"]
    )
    for fileURL in strayFiles {
        if fm.fileExists(atPath: fileURL.path) {
            try stageItem(originalURL: fileURL, rootURL: rootURL, stagingURL: stagingURL, moves: &moves)
        }
    }

    // 2. Encrypt standalone resource files
    let standaloneTargets: [(relDir: String, exts: Set<String>, subdirs: [String?])] = [
        ("terrariumidle_ios/Apps/Data/Items", ["json"], [nil]),
        ("terrariumidle_ios/Resources", ["json"], [nil]),
        ("terrariumidle_ios/Resources/Audios", ["mp3", "wav", "m4a", "caf", "aac"], [nil]),
        ("terrariumidle_ios/Resources/Rives", ["riv"], [nil]),
        ("terrariumidle_ios/Resources/Gifs", ["gif"], [nil]),
        ("terrariumidle_ios/Resources/Images", ["png", "jpg", "jpeg"], [nil]),
        ("terrariumidle_ios/Resources/HTML", ["html"], [nil, "HTML"])
    ]

    var encryptedFileCount = 0
    for target in standaloneTargets {
        let dirURL = rootURL.appendingPathComponent(target.relDir)
        let files: [URL]
        if target.relDir == "terrariumidle_ios/Resources" {
            // Only direct files in Resources (e.g. mailbox_terrarium.json)
            let contents = (try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)) ?? []
            files = contents.filter { target.exts.contains($0.pathExtension.lowercased()) }
        } else {
            files = findFiles(in: dirURL, extensions: target.exts)
        }

        for fileURL in files {
            let data = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            var encName = sha256HexPrefix("file/\(fileName)") + ".enc"
            var salt = 1
            while usedEncNames.contains(encName) {
                encName = sha256HexPrefix("file/\(fileName)#\(salt)") + ".enc"
                salt += 1
            }
            usedEncNames.insert(encName)
            let encrypted = try encryptData(data, using: key)
            try encrypted.write(to: vaultURL.appendingPathComponent(encName))

            for sub in target.subdirs {
                let mKey = sub == nil ? "file/\(fileName)" : "file/\(sub!)/\(fileName)"
                manifest[mKey] = ManifestEntry(f: encName, s: nil)
            }
            try stageItem(originalURL: fileURL, rootURL: rootURL, stagingURL: stagingURL, moves: &moves)
            encryptedFileCount += 1
        }
    }

    // 3. Encrypt SpriteKit & game art folders inside Assets.xcassets
    let xcassetsCategories = ["Plants", "Pots", "Stickers", "Landscapes", "Overlays", "Animals"]
    var encryptedAssetCount = 0
    for category in xcassetsCategories {
        let catURL = rootURL.appendingPathComponent("terrariumidle_ios/Assets.xcassets/\(category)")
        guard fm.fileExists(atPath: catURL.path) else { continue }

        let imagesets = findImagesets(in: catURL)
        for imagesetURL in imagesets {
            let imagesetName = imagesetURL.deletingPathExtension().lastPathComponent
            let contentsURL = imagesetURL.appendingPathComponent("Contents.json")
            guard let contentsData = try? Data(contentsOf: contentsURL),
                  let json = try? JSONSerialization.jsonObject(with: contentsData) as? [String: Any],
                  let images = json["images"] as? [[String: Any]] else {
                continue
            }

            // Prefer 1x, otherwise first image with a filename
            let chosen = images.first { ($0["scale"] as? String) == "1x" && ($0["filename"] as? String) != nil }
                ?? images.first { ($0["filename"] as? String) != nil }

            guard let entry = chosen,
                  let filename = entry["filename"] as? String else {
                continue
            }

            let imageFileURL = imagesetURL.appendingPathComponent(filename)
            guard fm.fileExists(atPath: imageFileURL.path) else { continue }

            let imageData = try Data(contentsOf: imageFileURL)
            let scale = parseScale(entry["scale"] as? String)
            try writeEncryptedEntry(manifestKey: "img/\(imagesetName)", data: imageData, scale: scale)
            encryptedAssetCount += 1
        }

        try stageItem(originalURL: catURL, rootURL: rootURL, stagingURL: stagingURL, moves: &moves)
    }

    // 4. Write encrypted manifest
    let manifestData = try JSONEncoder().encode(manifest)
    let encryptedManifest = try encryptData(manifestData, using: key)
    try encryptedManifest.write(to: vaultURL.appendingPathComponent("manifest.enc"))

    // 5. Stage and overwrite EncryptedResourceKey.swift
    let keySwiftURL = rootURL.appendingPathComponent("terrariumidle_ios/Apps/Core/Utils/EncryptedResourceKey.swift")
    try stageItem(originalURL: keySwiftURL, rootURL: rootURL, stagingURL: stagingURL, moves: &moves)
    try writeObfuscatedKeySwift(keyBytes: keyBytes, to: keySwiftURL)

    // 6. Persist move records for reliable restore
    let movesData = try JSONEncoder().encode(moves)
    try movesData.write(to: stagingURL.appendingPathComponent("moves.json"))

    print("==> Encrypted \(encryptedFileCount) standalone files + \(encryptedAssetCount) xcassets imagesets into EncryptedVault/.")
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("Usage: encrypt_vault.swift [--encrypt | --restore] [project_root]\n", stderr)
    exit(1)
}

let mode = args[1]
let rootPath = args.count >= 3 ? args[2] : fm.currentDirectoryPath
let rootURL = URL(fileURLWithPath: rootPath)

do {
    switch mode {
    case "--encrypt":
        try encrypt(rootURL: rootURL)
    case "--restore":
        try restore(rootURL: rootURL)
    default:
        fputs("Unknown mode: \(mode)\n", stderr)
        exit(1)
    }
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}

//
//  MusicUnlockHelper.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import Foundation

enum MusicUnlockHelper {
    /// Extract all unlocked music/SFX/landscape/overlay IDs from planted items.
    /// When VIP is active, all music, SFX, landscapes, and visual overlay effects are unlocked
    /// without requiring any plants to be planted.
    static func getUnlockedMusicIds(from gardenModel: GardenModel?, isVIPOverride: Bool? = nil) -> Set<String> {
        let isVIP = isVIPOverride ?? SubscriptionManager.isVIP(gardenModel: gardenModel)
        if isVIP {
            return allCatalogAudioAndVisualIds()
        }

        guard let plants = gardenModel?.plants else { return ["m0", "music1"] }

        var unlockedIds: Set<String> = []

        // Always unlock default track
        unlockedIds.formUnion(["m0", "music1"])

        for plant in plants {
            // Check plant item
            if !plant.idPlant.isEmpty,
               let plantItem = ItemDataManager.shared.getItem(byId: plant.idPlant)
            {
                extractAllUnlockedIds(from: plantItem, into: &unlockedIds)
            }

            // Check pot item
            if !plant.idPot.isEmpty,
               let potItem = ItemDataManager.shared.getItem(byId: plant.idPot)
            {
                extractAllUnlockedIds(from: potItem, into: &unlockedIds)
            }
        }

        // Legacy gardens store audio names (m0, m1); the catalog uses music1, music2.
        for track in ItemDataManager.shared.getAllMusics() {
            if unlockedIds.contains(track.sound ?? track.id) || unlockedIds.contains(track.image) {
                unlockedIds.insert(track.id)
            }
        }
        return unlockedIds
    }

    static func allCatalogAudioAndVisualIds() -> Set<String> {
        var ids: Set<String> = ["m0", "music1"]
        for track in ItemDataManager.shared.getAllMusics() {
            ids.insert(track.id)
            ids.insert(track.image)
            if let sound = track.sound, !sound.isEmpty {
                ids.insert(sound)
            }
        }
        for sfx in ItemDataManager.shared.getAllMusicsSFX() {
            ids.insert(sfx.id)
            ids.insert(sfx.image)
            if let sound = sfx.sound, !sound.isEmpty {
                ids.insert(sound)
            }
        }
        for effect in ItemDataManager.shared.getAllEffects() {
            ids.insert(effect.id)
        }
        for landscape in ItemDataManager.shared.getAllLandscapes() {
            ids.insert(landscape.id)
        }
        return ids
    }

    /// Trích xuất toàn bộ ID từ item (hỗ trợ phân tách dấu phẩy)
    private static func extractAllUnlockedIds(from item: ItemData, into ids: inout Set<String>) {
        // 1. Music (ví dụ "m0,m1")
        for m in item.unlockedMusicIds {
            ids.insert(m)
        }

        // 2. Overlay Effects (ví dụ "overlay1,overlay2")
        for eff in item.unlockedEffectIds {
            if eff.hasPrefix("overlay") || eff.hasPrefix("m") || eff.hasPrefix("sfx") || eff.hasPrefix("landscape") {
                ids.insert(eff)
            }
        }

        // 3. Landscape (ví dụ "landscape1,landscape2")
        for l in item.unlockedLandscapeIds {
            ids.insert(l)
        }

        // 4. SFX (ví dụ "sfx1,sfx5")
        for s in item.unlockedSfxIds {
            ids.insert(s)
        }

        // 5. Fallback định dạng legacy: "Description - id"
        if let legacyId = extractMusicId(from: item.effect) {
            ids.insert(legacyId)
        }
    }

    /// Extract music/SFX/landscape/overlay ID from legacy effect string
    /// Format: "Description - id" → returns "id"
    /// Example: "Tiếng bão - sfx7" → "sfx7"
    ///          "Ban công mưa bão - landscape3" → "landscape3"
    private static func extractMusicId(from effect: String) -> String? {
        guard !effect.isEmpty, effect != "N.A" else { return nil }

        // Split by " - " and take the last component
        let components = effect.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count >= 2 else { return nil }

        let id = components.last ?? ""

        // Validate it's a valid ID (music, SFX, landscape, or overlay)
        if id.hasPrefix("m") || id.hasPrefix("sfx") || id.hasPrefix("landscape") || id.hasPrefix("overlay") {
            return id
        }

        return nil
    }
}

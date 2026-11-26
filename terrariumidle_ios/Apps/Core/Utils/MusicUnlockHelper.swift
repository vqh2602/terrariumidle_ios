//
//  MusicUnlockHelper.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import Foundation

struct VisitorAtmosphere {
    let backgroundId: String
    let overlayId: String?
    let music: ItemData?
    let sfx: ItemData?
}

enum MusicUnlockHelper {
    /// Extract all unlocked music/SFX/landscape/overlay IDs from planted items.
    /// When VIP is active, all music, SFX, landscapes, and visual overlay effects are unlocked
    /// without requiring any plants to be planted.
    static func getUnlockedMusicIds(from gardenModel: GardenModel?, isVIPOverride: Bool? = nil) -> Set<String> {
        let isVIP = isVIPOverride ?? SubscriptionManager.isVIP(gardenModel: gardenModel)
        let itemIds = gardenModel?.plants.flatMap { [$0.idPlant, $0.idPot] } ?? []
        return getUnlockedIds(itemIds: itemIds, isVIP: isVIP)
    }

    /// Extract all unlocked music/SFX/landscape/overlay IDs from a list of plant/pot IDs and VIP status.
    static func getUnlockedIds(itemIds: [String], isVIP: Bool) -> Set<String> {
        if isVIP {
            return allCatalogAudioAndVisualIds()
        }

        // Always unlock default track
        var unlockedIds: Set<String> = ["m0", "music1"]

        for itemId in itemIds where !itemId.isEmpty {
            if let item = ItemDataManager.shared.getItem(byId: itemId) {
                extractAllUnlockedIds(from: item, into: &unlockedIds)
            }
        }

        mapLegacyTrackIds(into: &unlockedIds)
        return unlockedIds
    }

    /// Pick a random landscape, overlay effect, music track, and SFX unlocked by a garden's items or VIP status.
    static func randomAtmosphere(
        itemIds: [String],
        isVIP: Bool,
        hasAudioFile: (String) -> Bool = { _ in true }
    ) -> VisitorAtmosphere {
        let unlockedIds = getUnlockedIds(itemIds: itemIds, isVIP: isVIP)

        let landscapes = ItemDataManager.shared.getAllLandscapes().filter {
            unlockedIds.contains($0.id)
        }
        let backgroundId = landscapes.randomElement()?.id ?? "i_sky_sun_day"

        let overlays = ItemDataManager.shared.getAllEffects().filter {
            unlockedIds.contains($0.id)
        }
        let overlayId = overlays.randomElement()?.id

        let musics = ItemDataManager.shared.getAllMusics().filter {
            unlockedIds.contains($0.id) && hasAudioFile($0.sound ?? $0.id)
        }
        let music = musics.randomElement()

        let sfxList = ItemDataManager.shared.getAllMusicsSFX().filter {
            unlockedIds.contains($0.id) && hasAudioFile($0.sound ?? $0.id)
        }
        let sfx = sfxList.randomElement()

        return VisitorAtmosphere(
            backgroundId: backgroundId,
            overlayId: overlayId,
            music: music,
            sfx: sfx
        )
    }

    private static func mapLegacyTrackIds(into unlockedIds: inout Set<String>) {
        // Legacy gardens store audio names (m0, m1); the catalog uses music1, music2.
        for track in ItemDataManager.shared.getAllMusics() {
            if unlockedIds.contains(track.sound ?? track.id) || unlockedIds.contains(track.image) {
                unlockedIds.insert(track.id)
            }
        }
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

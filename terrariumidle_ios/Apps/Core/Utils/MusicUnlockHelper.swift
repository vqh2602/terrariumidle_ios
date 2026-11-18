//
//  MusicUnlockHelper.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import Foundation

enum MusicUnlockHelper {
    /// Extract all unlocked music/SFX IDs from planted items
    /// Scans the effect field of all planted items (plants, pots, decorations)
    /// Effect format: "Description - id" (e.g., "Tiếng bão - sfx7")
    static func getUnlockedMusicIds(from gardenModel: GardenModel?) -> Set<String> {
        guard let plants = gardenModel?.plants else { return [] }

        var unlockedIds: Set<String> = []

        // Always unlock default track
        unlockedIds.insert("m0")

        for plant in plants {
            // Check plant item
            if !plant.idPlant.isEmpty,
               let plantItem = ItemDataManager.shared.getItem(byId: plant.idPlant)
            {
                if let extractedId = extractMusicId(from: plantItem.effect) {
                    unlockedIds.insert(extractedId)
                }
            }

            // Check pot item
            if !plant.idPot.isEmpty,
               let potItem = ItemDataManager.shared.getItem(byId: plant.idPot)
            {
                if let extractedId = extractMusicId(from: potItem.effect) {
                    unlockedIds.insert(extractedId)
                }
            }
        }

        return unlockedIds
    }

    /// Extract music/SFX/landscape/overlay ID from effect string
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

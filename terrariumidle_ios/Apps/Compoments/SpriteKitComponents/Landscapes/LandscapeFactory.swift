//
//  LandscapeFactory.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit

/// Factory quản lý khởi tạo các Phong cảnh nền SpriteKit (Landscape Nodes)
public final class LandscapeFactory {

    /// Khởi tạo Node Phong cảnh theo ID và kích thước khung
    public static func createLandscape(id: String, containerSize: CGSize) -> LandscapeInteractiveNode? {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch cleanId {
        case "landscape1", "land1", "sky_sun_day", "i_sky_sun_day":
            return Landscape1Node(containerSize: containerSize)
        case "landscape2", "land2", "sunset", "sky_sunset", "i_sky_sunset", "landscape2-1@4.167x":
            return Landscape2Node(containerSize: containerSize)
        default:
            if cleanId.contains("2") || cleanId.contains("sunset") {
                return Landscape2Node(containerSize: containerSize)
            }
            // Mặc định hoặc fallback về Landscape1
            if cleanId.contains("1") || cleanId.contains("day") || cleanId.isEmpty {
                return Landscape1Node(containerSize: containerSize)
            }
            return nil
        }
    }
}

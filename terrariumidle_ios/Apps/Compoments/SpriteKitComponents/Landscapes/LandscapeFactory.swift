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
        case "landscape3", "land3", "rain", "sky_rain", "i_sky_rain", "landscape3-1@4.167x":
            return Landscape3Node(containerSize: containerSize)
        case "landscape4", "land4", "moon_night", "sky_moon_night", "i_sky_moon_night", "landscape4-bg@4.167x", "landscape4-bg":
            return Landscape4Node(containerSize: containerSize)
        case "landscape5", "land5", "sky_moon_star", "i_sky_moon_star", "storm", "night_storm", "dark_rain", "glass", "rain_glass", "water_drop", "window", "landscape5-bg-1@4.167x", "landscape5-1@4.167x", "landscape5-1":
            return Landscape5Node(containerSize: containerSize)
        case "landscape6", "land6", "i_landscape6", "minamoto_no_yuuhi", "minamoto", "yuuhi", "cội nguồn hoàng hôn", "origin_of_sunset":
            return Landscape6Node(containerSize: containerSize)
        case "landscape7", "land7", "i_landscape7", "than_son_huyen_canh", "thần sơn huyễn cảnh", "mountain_realm", "divine_mountain", "sea_mountain", "landscape7-1@4.167x", "landscape7-1":
            return Landscape7Node(containerSize: containerSize)
        default:
            if cleanId.contains("7") || cleanId.contains("than_son") || cleanId.contains("mountain") {
                return Landscape7Node(containerSize: containerSize)
            }
            if cleanId.contains("6") || cleanId.contains("minamoto") || cleanId.contains("yuuhi") {
                return Landscape6Node(containerSize: containerSize)
            }
            if cleanId.contains("5") || cleanId.contains("storm") || cleanId.contains("glass") {
                return Landscape5Node(containerSize: containerSize)
            }
            if cleanId.contains("4") || cleanId.contains("moon") {
                return Landscape4Node(containerSize: containerSize)
            }
            if cleanId.contains("3") || cleanId.contains("rain") {
                return Landscape3Node(containerSize: containerSize)
            }
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

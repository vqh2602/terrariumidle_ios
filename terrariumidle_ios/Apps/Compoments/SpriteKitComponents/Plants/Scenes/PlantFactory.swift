//
//  PlantFactory.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Factory khởi tạo các Node cây SpriteKit tập trung
public enum PlantFactory {
    /// Khởi tạo Node cây tương ứng theo ID
    public static func createPlant(
        id: String,
        level: Int = 1,
        containerSize: CGSize,
        isHanging: Bool = false
    ) -> PlantInteractiveNode? {
        let cleanId = id.lowercased().trimmingCharacters(in: .whitespaces)

        switch cleanId {
        case "plant1":
            return Plant1Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant2":
            return Plant2Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant3":
            return Plant3Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant4":
            return Plant4Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant5":
            return Plant5Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant6":
            return Plant6Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant7":
            return Plant7Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant8":
            return Plant8Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant9":
            return Plant9Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant10":
            return Plant10Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant11":
            return Plant11Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant12":
            return Plant12Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant13":
            return Plant13Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant14":
            return Plant14Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant15":
            return Plant15Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant16":
            return Plant16Node(level: level, containerSize: containerSize, isHanging: isHanging)
        case "plant17":
            return Plant17Node(level: level, containerSize: containerSize, isHanging: isHanging)
        default:
            return nil
        }
    }
}

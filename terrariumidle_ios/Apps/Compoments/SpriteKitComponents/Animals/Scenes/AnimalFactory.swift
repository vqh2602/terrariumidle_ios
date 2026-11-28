//
//  AnimalFactory.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

/// Factory khởi tạo các Node Động vật / Tổ động vật SpriteKit tập trung
public enum AnimalFactory {
    public static func createAnimal(
        id: String,
        containerSize: CGSize,
        isHanging: Bool = true
    ) -> AnimalInteractiveNode {
        let cleanId = id.lowercased().trimmingCharacters(in: .whitespaces)
        switch cleanId {
        case "animal1":
            return Animal1Node(containerSize: containerSize, isHanging: isHanging)
        case "animal2":
            return Animal2Node(containerSize: containerSize, isHanging: isHanging)
        case "animal3":
            return Animal3Node(containerSize: containerSize, isHanging: isHanging)
        default:
            return Animal1Node(containerSize: containerSize, isHanging: isHanging)
        }
    }
}

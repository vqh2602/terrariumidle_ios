//
//  PotFactory.swift
//  terrariumidle_ios
//
//  Created by AI on 20/11/26.
//

import SpriteKit
import UIKit

/// Factory khởi tạo các Node chậu SpriteKit tập trung
public enum PotFactory {
    /// Khởi tạo Node chậu tương ứng theo ID
    public static func createPot(
        id: String,
        containerSize: CGSize,
        isHanging: Bool = false,
        widthFill: CGFloat = 0.0
    ) -> PotInteractiveNode {
        let cleanId = id.lowercased().trimmingCharacters(in: .whitespaces)
        let effectiveFill = min(max(widthFill, 0.0), 1.0)

        switch cleanId {
        case "pot1":
            return Pot1Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot2":
            return Pot2Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot3":
            return Pot3Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot4":
            return Pot4Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot5":
            return Pot5Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot6":
            return Pot6Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot7":
            return Pot7Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot8":
            return Pot8Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot9":
            return Pot9Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot10":
            return Pot10Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot11":
            return Pot11Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot12":
            return Pot12Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot13":
            return Pot13Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot14":
            return Pot14Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot15":
            return Pot15Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        case "pot16":
            return Pot16Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        default:
            return Pot1Node(containerSize: containerSize, isHanging: isHanging, widthFill: effectiveFill)
        }
    }
}

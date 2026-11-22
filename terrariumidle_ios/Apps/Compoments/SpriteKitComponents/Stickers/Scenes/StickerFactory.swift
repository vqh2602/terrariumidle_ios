//
//  StickerFactory.swift
//  terrariumidle_ios
//
//  Created by AI on 21/11/26.
//

import SpriteKit
import UIKit

/// Factory khởi tạo các Node Sticker SpriteKit tập trung
public enum StickerFactory {
    /// Khởi tạo Node Sticker tương ứng theo ID
    public static func createSticker(
        id: String,
        containerSize: CGSize,
        isHanging: Bool = true
    ) -> StickerInteractiveNode {
        let cleanId = id.lowercased().trimmingCharacters(in: .whitespaces)

        switch cleanId {
        case "sticker1":
            return Sticker1Node(containerSize: containerSize, isHanging: isHanging)
        case "sticker2":
            return Sticker2Node(containerSize: containerSize, isHanging: isHanging)
        case "sticker3":
            return Sticker3Node(containerSize: containerSize, isHanging: isHanging)
        case "sticker4":
            return Sticker4Node(containerSize: containerSize, isHanging: isHanging)
        default:
            return Sticker1Node(containerSize: containerSize, isHanging: isHanging)
        }
    }
}

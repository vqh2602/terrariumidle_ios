//
//  AnimalTapEffect.swift
//  terrariumidle_ios
//
//  Created by AI on 26/11/26.
//

import SpriteKit
import UIKit

// MARK: - Animal Tap Effect Protocol

public protocol AnimalTapEffect: AnyObject {
    var name: String { get }
    func trigger(on targetNode: SKNode, in containerNode: SKNode, isHanging: Bool)
}

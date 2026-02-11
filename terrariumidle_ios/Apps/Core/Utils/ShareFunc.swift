//
//  ShareFunc.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

class ShareFunc {
    /// Calculate max EXP needed for user level up
    /// Formula: (1000 * level) * 0.75
    static func calculateUserMaxExp(level: Int) -> Int {
        return Int(Double(1000 * level) * 2)
    }
    
    /// Get drop rate and oxygen amount based on plant level
    static func getDropRate(level: Int) -> (chance: Double, oxygen: Int) {
        switch level {
        case 1: return (0.40, 3) // 60% chance, 5 oxygen
        case 2: return (0.45, 5) // 70% chance, 10 oxygen
        case 3: return (0.5, 10) // 95% chance, 20 oxygen
        default: return (0.5, level * 3)
        }
    }

    /// Calculate max EXP needed for plant level up
    /// Formula: (3000 * level) * 0.95
    static func calculatePlantMaxExp(level: Int) -> Int {
        return Int(Double(3000 * level) * 0.95)
    }
}

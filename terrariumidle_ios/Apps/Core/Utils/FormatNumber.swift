//
//  FormatNumber.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

import Foundation
class FormatNumber {
    
    
    static func formatNumber(_ number: Int) -> String {
        let num = Double(number)

        switch num {
        case 1_000_000_000_000...:
            return format(num / 1_000_000_000_000, suffix: "t") // trillion
        case 1_000_000_000...:
            return format(num / 1_000_000_000, suffix: "b")     // billion
        case 1_000_000...:
            return format(num / 1_000_000, suffix: "m")         // million
        case 1_000...:
            return format(num / 1_000, suffix: "k")             // thousand
        default:
            return "\(number)"
        }
    }

    static private func format(_ value: Double, suffix: String) -> String {
        // bỏ .0 nếu là số tròn
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)

        return "\(formatted)\(suffix)"
    }

}

//
//  FormatNumber.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 10/2/26.
//

import Foundation

class FormatNumber {
    private static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// Bảng đơn vị rút gọn theo thứ tự giảm dần (từ Decillion đến Thousand).
    private static let units: [(threshold: Double, suffix: String)] = [
        (1e33, "dc"), // decillion
        (1e30, "no"), // nonillion
        (1e27, "oc"), // octillion
        (1e24, "sp"), // septillion
        (1e21, "sx"), // sextillion
        (1e18, "qi"), // quintillion
        (1e15, "qa"), // quadrillion
        (1e12, "t"),  // trillion
        (1e9,  "b"),  // billion
        (1e6,  "m"),  // million
        (1e3,  "k")   // thousand
    ]

    static func formatNumber(_ number: Int) -> String {
        formatNumber(Double(number))
    }

    static func formatNumber(_ number: Double) -> String {
        guard number.isFinite else { return "0" }
        let sign = number < 0 ? "-" : ""
        let magnitude = abs(number)

        for (threshold, suffix) in units where magnitude >= threshold {
            return "\(sign)\(format(magnitude / threshold, suffix: suffix))"
        }

        if magnitude.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(sign)\(String(format: "%.0f", locale: posixLocale, magnitude))"
        }
        return "\(sign)\(String(format: "%.1f", locale: posixLocale, magnitude))"
    }

    private static func format(_ value: Double, suffix: String) -> String {
        let formatted = String(format: "%.1f", locale: posixLocale, value)
        let clean = formatted.hasSuffix(".0") ? String(formatted.dropLast(2)) : formatted
        return "\(clean)\(suffix)"
    }
}

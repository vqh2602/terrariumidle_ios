//
//  M3TextStyle.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//
// using:
//Text("Welcome")
//    .m3TextStyle(.headlineLarge)
//
//Text("Sign in to continue")
//    .m3TextStyle(.bodyMedium)
//    .foregroundColor(.secondary)


import SwiftUI

enum M3TextStyle {
    case displayLarge
    case displayMedium
    case displaySmall

    case headlineLarge
    case headlineMedium
    case headlineSmall

    case titleLarge
    case titleMedium
    case titleSmall

    case bodyLarge
    case bodyMedium
    case bodySmall

    case labelLarge
    case labelMedium
    case labelSmall

    var font: Font {
        switch self {

        // Display
        case .displayLarge:   return .system(size: 57, weight: .regular)
        case .displayMedium:  return .system(size: 45, weight: .regular)
        case .displaySmall:   return .system(size: 36, weight: .regular)

        // Headline
        case .headlineLarge:  return .system(size: 32, weight: .regular)
        case .headlineMedium: return .system(size: 28, weight: .regular)
        case .headlineSmall:  return .system(size: 24, weight: .regular)

        // Title
        case .titleLarge:     return .system(size: 22, weight: .medium)
        case .titleMedium:    return .system(size: 16, weight: .medium)
        case .titleSmall:     return .system(size: 14, weight: .medium)

        // Body
        case .bodyLarge:      return .system(size: 16, weight: .regular)
        case .bodyMedium:     return .system(size: 14, weight: .regular)
        case .bodySmall:      return .system(size: 12, weight: .regular)

        // Label
        case .labelLarge:     return .system(size: 14, weight: .medium)
        case .labelMedium:    return .system(size: 12, weight: .medium)
        case .labelSmall:     return .system(size: 11, weight: .medium)
        }
    }
}
extension View {
    func m3TextStyle(_ style: M3TextStyle) -> some View {
        self.font(style.font)
    }
}

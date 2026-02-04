//
//  AppTextStyle.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 29/1/26.
//
// using:
//Text("Button")
//    .textStyle(.calloutMedium)
//
//Text("Helper text")
//    .textStyle(.footnote)

import SwiftUI

enum AppTextStyle {

    // MARK: - Large Titles
    case largeTitle
    case largeTitleBold

    // MARK: - Titles
    case title1
    case title1Bold
    case title2
    case title2Semibold
    case title3
    case title3Semibold

    // MARK: - Headlines
    case headline
    case headlineSemibold

    // MARK: - Body
    case body
    case bodyMedium
    case bodySemibold

    // MARK: - Callout
    case callout
    case calloutMedium

    // MARK: - Subheadline
    case subheadline
    case subheadlineMedium

    // MARK: - Footnote
    case footnote
    case footnoteMedium

    // MARK: - Caption
    case caption1
    case caption1Medium
    case caption2
    case caption2Medium

    var font: Font {
        switch self {

        // Large Title
        case .largeTitle:           return .largeTitle
        case .largeTitleBold:       return .largeTitle.weight(.bold)

        // Title
        case .title1:               return .title
        case .title1Bold:           return .title.weight(.bold)
        case .title2:               return .title2
        case .title2Semibold:       return .title2.weight(.semibold)
        case .title3:               return .title3
        case .title3Semibold:       return .title3.weight(.semibold)

        // Headline
        case .headline:             return .headline
        case .headlineSemibold:     return .headline.weight(.semibold)

        // Body
        case .body:                 return .body
        case .bodyMedium:           return .body.weight(.medium)
        case .bodySemibold:         return .body.weight(.semibold)

        // Callout
        case .callout:              return .callout
        case .calloutMedium:        return .callout.weight(.medium)

        // Subheadline
        case .subheadline:          return .subheadline
        case .subheadlineMedium:    return .subheadline.weight(.medium)

        // Footnote
        case .footnote:             return .footnote
        case .footnoteMedium:       return .footnote.weight(.medium)

        // Caption
        case .caption1:             return .caption
        case .caption1Medium:       return .caption.weight(.medium)
        case .caption2:             return .caption2
        case .caption2Medium:       return .caption2.weight(.medium)
        }
    }
}
extension View {
    func textStyle(_ style: AppTextStyle) -> some View {
        self.font(style.font)
    }
}

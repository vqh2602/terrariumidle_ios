//
//  LocalizationManager.swift
//  terrariumidle_ios
//

import Combine
import Foundation
import SwiftUI

/// Ngôn ngữ được hỗ trợ trong ứng dụng.
/// Hỗ trợ 5 ngôn ngữ: Tiếng Anh (en), Tiếng Việt (vi), Tiếng Nhật (ja), Tiếng Trung giản thể (zh-Hans), Tiếng Hàn (ko).
enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case vi = "vi"
    case ja = "ja"
    case zhHans = "zh-Hans"
    case ko = "ko"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .en: return "English"
        case .vi: return "Tiếng Việt"
        case .ja: return "日本語"
        case .zhHans: return "简体中文"
        case .ko: return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .en: return "🇺🇸"
        case .vi: return "🇻🇳"
        case .ja: return "🇯🇵"
        case .zhHans: return "🇨🇳"
        case .ko: return "🇰🇷"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Tự động phát hiện ngôn ngữ hệ thống; nếu không khớp 5 ngôn ngữ hỗ trợ thì mặc định là Tiếng Anh (`en`).
    static func systemDefault() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            let lower = preferred.lowercased()
            if lower.hasPrefix("vi") { return .vi }
            if lower.hasPrefix("ja") { return .ja }
            if lower.hasPrefix("zh") { return .zhHans }
            if lower.hasPrefix("ko") { return .ko }
            if lower.hasPrefix("en") { return .en }
        }
        return .en
    }
}

/// Quản lý ngôn ngữ hiện tại của ứng dụng và cung cấp tra cứu chuỗi qua extension `.tr`.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let storageKey = "app_selected_language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
            bundle = Self.loadBundle(for: currentLanguage)
        }
    }

    private(set) var bundle: Bundle

    private init() {
        let initial: AppLanguage
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: saved) {
            initial = lang
        } else {
            initial = AppLanguage.systemDefault()
        }
        self.currentLanguage = initial
        self.bundle = Self.loadBundle(for: initial)
    }

    private static func loadBundle(for language: AppLanguage) -> Bundle {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return langBundle
        }
        return .main
    }

    func localized(_ key: String) -> String {
        guard !key.isEmpty else { return key }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    /// Trả về chuỗi đã được dịch theo ngôn ngữ đang chọn trong `LocalizationManager`.
    var tr: String {
        LocalizationManager.shared.localized(self)
    }

    /// Trả về chuỗi đã được dịch và format theo các tham số truyền vào.
    func tr(_ args: CVarArg...) -> String {
        String(format: self.tr, locale: LocalizationManager.shared.currentLanguage.locale, arguments: args)
    }
}

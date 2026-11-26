import Foundation

enum WatchText {
    static let languages = ["vi", "en", "ja", "zh-Hans", "ko"]

    static func language(_ code: String?) -> String {
        let candidates = code.map { [$0] } ?? Locale.preferredLanguages
        for candidate in candidates {
            if candidate.hasPrefix("zh") { return "zh-Hans" }
            if let match = languages.first(where: { candidate.hasPrefix($0) }) { return match }
        }
        return "en"
    }

    static func value(_ key: String, language code: String?) -> String {
        let selected = language(code)
        guard let path = Bundle.main.path(forResource: selected, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "WatchLocalizable")
    }

    static func format(_ key: String, language code: String?, _ args: CVarArg...) -> String {
        String(format: value(key, language: code), locale: Locale(identifier: language(code)), arguments: args)
    }
}

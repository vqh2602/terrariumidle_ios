import Foundation
import SwiftUI

struct MailboxItem: Decodable, Identifiable, Hashable {
    enum Category: String, Decodable, Hashable, CaseIterable {
        case event
        case update
        case system
        case gift
        case unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self).lowercased()
            self = Category(rawValue: raw) ?? .unknown
        }

        var title: String {
            switch self {
            case .event: return "Sự kiện".tr
            case .update: return "Cập nhật".tr
            case .system: return "Hệ thống".tr
            case .gift: return "Quà tặng".tr
            case .unknown: return "Thông báo".tr
            }
        }

        var icon: String {
            switch self {
            case .event: return "gift.fill"
            case .update: return "sparkles"
            case .system: return "megaphone.fill"
            case .gift: return "envelope.open.fill"
            case .unknown: return "bell.fill"
            }
        }

        var tint: Color {
            switch self {
            case .event: return Color(hex: "C07A53")
            case .update: return AccountStyle.green
            case .system: return Color(hex: "5E99B5")
            case .gift: return Color(hex: "D79922")
            case .unknown: return AccountStyle.muted
            }
        }
    }

    struct Action: Decodable, Hashable {
        let type: String   // "route" | "url"
        let target: String // "events", "store", "discovery", "vip", "account" hoặc "https://..."
    }

    struct LocalizedContent: Decodable, Hashable {
        let local: String
        let title: String
        let summary: String
        let body: String
        let highlights: [String]?
        let image: String?
        let actionLabel: String?
    }

    struct Feed: Decodable {
        let data: [MailboxItem]
    }

    static let feedURL = URL(string: "https://vqh2602.github.io/terrarium_data.github.io/mailbox_terrarium.json")!

    let id: String
    let category: Category
    let date: String
    let sender: String?
    let pinned: Bool?
    let minVersion: String?
    let action: Action?
    let content: [LocalizedContent]

    func localized(language: String = Locale.current.language.languageCode?.identifier ?? "en") -> LocalizedContent? {
        content.first { $0.local == language }
            ?? content.first { $0.local == "en" }
            ?? content.first
    }

    var isSupportedByCurrentVersion: Bool {
        guard let minVersion, !minVersion.isEmpty else { return true }
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return TerrariumEvent.supportsVersion(current, minimum: minVersion)
    }
}

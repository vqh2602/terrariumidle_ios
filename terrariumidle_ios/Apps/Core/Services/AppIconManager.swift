//
//  AppIconManager.swift
//  terrariumidle_ios
//

import Combine
import SwiftUI
import UIKit

/// Các lựa chọn biểu tượng ứng dụng & màn hình Splash (mở khóa cho hội viên VIP).
enum AppIconOption: String, CaseIterable, Identifiable {
    case defaultIcon = "default"
    case noel = "noel"
    case halloween = "halloween"
    case winter = "winter"
    case neon = "neon"
    case watercolor = "watercolor"

    var id: String { rawValue }

    /// Tên Alternate App Icon trong `Assets.xcassets` (`nil` = biểu tượng mặc định `AppIcon`).
    var alternateIconName: String? {
        switch self {
        case .defaultIcon: return nil
        case .noel: return "AppIconNoel"
        case .halloween: return "AppIconHalloween"
        case .winter: return "AppIconWinter"
        case .neon: return "AppIconNeon"
        case .watercolor: return "AppIconWatercolor"
        }
    }

    /// Tên image set dùng cho màn hình Splash và bản xem trước trong ứng dụng.
    var splashImageName: String {
        switch self {
        case .defaultIcon: return "logo"
        case .noel: return "logo_noel"
        case .halloween: return "logo_halloween"
        case .winter: return "logo_winter"
        case .neon: return "logo_neon"
        case .watercolor: return "logo_watercolor"
        }
    }

    var title: String {
        switch self {
        case .defaultIcon: return "Mặc định".tr
        case .noel: return "Noel".tr
        case .halloween: return "Halloween".tr
        case .winter: return "Mùa đông".tr
        case .neon: return "Neon".tr
        case .watercolor: return "Watercolor".tr
        }
    }

    var badgeText: String {
        switch self {
        case .defaultIcon: return "Classic"
        case .noel: return "Holiday"
        case .halloween: return "Spooky"
        case .winter: return "Frost"
        case .neon: return "Glow"
        case .watercolor: return "Art"
        }
    }

    var accentColor: Color {
        switch self {
        case .defaultIcon: return Color(hex: "567747")
        case .noel: return Color(hex: "B8433E")
        case .halloween: return Color(hex: "D97925")
        case .winter: return Color(hex: "5C92B5")
        case .neon: return Color(hex: "00B894")
        case .watercolor: return Color(hex: "C4776B")
        }
    }

    static func from(alternateIconName: String?) -> AppIconOption {
        guard let alternateIconName else { return .defaultIcon }
        return allCases.first { $0.alternateIconName == alternateIconName } ?? .defaultIcon
    }
}

/// Quản lý việc đổi biểu tượng ứng dụng (App Icon) và biểu tượng hiển thị tại Splash Screen.
@MainActor
final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()

    private static let storageKey = "app_selected_icon_id"

    @Published private(set) var currentIcon: AppIconOption
    @Published private(set) var isUpdating = false
    @Published var errorMessage: String?

    var currentSplashImageName: String {
        currentIcon.splashImageName
    }

    private init() {
        if let savedId = UserDefaults.standard.string(forKey: Self.storageKey),
           let savedOption = AppIconOption(rawValue: savedId) {
            self.currentIcon = savedOption
        } else {
            self.currentIcon = AppIconOption.from(alternateIconName: UIApplication.shared.alternateIconName)
        }
    }

    func selectIcon(_ option: AppIconOption) async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        // Lưu lựa chọn cho Splash Screen ngay lập tức
        currentIcon = option
        UserDefaults.standard.set(option.rawValue, forKey: Self.storageKey)

        guard UIApplication.shared.supportsAlternateIcons else { return }
        let targetName = option.alternateIconName
        guard UIApplication.shared.alternateIconName != targetName else { return }

        do {
            try await UIApplication.shared.setAlternateIconName(targetName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

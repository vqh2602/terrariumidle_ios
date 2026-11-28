import Foundation

/// Persists first-launch onboarding completion and resolves initial routes.
enum OnboardingStorage {
    static let completedKey = "app.onboarding.completed"

    static func hasCompleted(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: completedKey)
    }

    static func markCompleted(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: completedKey)
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: completedKey)
    }

    static func postSplashRoute(
        isAuthenticated: Bool,
        in defaults: UserDefaults = .standard
    ) -> AppRoute {
        if !hasCompleted(in: defaults) {
            return .onboardingView
        }
        return postOnboardingRoute(isAuthenticated: isAuthenticated)
    }

    static func postOnboardingRoute(isAuthenticated: Bool) -> AppRoute {
        isAuthenticated ? .homeView : .loginView(id: "")
    }
}

/// Represents a single page in the first-launch garden tutorial.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case care
    case gardenMenu
    case wildlife
    case relax

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .welcome: return "CHÀO MỪNG".tr
        case .care: return "CHĂM SÓC CÂY".tr
        case .gardenMenu: return "KỆ CÂY & GÓC VƯỜN".tr
        case .wildlife: return "ĐỘNG VẬT & BẢO VỆ VƯỜN".tr
        case .relax: return "THƯ GIÃN MỖI NGÀY".tr
        }
    }

    var title: String {
        switch self {
        case .welcome: return "Góc vườn nhỏ bình yên của riêng bạn".tr
        case .care: return "Chạm để tạo Oxy, giữ để chăm cây".tr
        case .gardenMenu: return "Sắp xếp kệ gỗ & mở rộng tầng mới".tr
        case .wildlife: return "Túi bắt sâu Bugsnet, xịt thuốc & thả sâu".tr
        case .relax: return "Ngủ ngon, ngắm mưa và thăm bạn bè".tr
        }
    }

    var summary: String {
        switch self {
        case .welcome:
            return "Trồng cây, thu thập Oxy và lắng nghe âm nhạc nhẹ nhàng ngay trên kệ gỗ.".tr
        case .care:
            return "Mỗi lần tương tác đều giúp cây xanh tốt hơn và tăng cấp độ khu vườn.".tr
        case .gardenMenu:
            return "Mọi công cụ trang trí, cửa hàng và túi tài nguyên đều nằm gọn ở hai góc màn hình.".tr
        case .wildlife:
            return "Đặt Bugsnet để thu thập sâu bọ bám cây (tối đa 5 con), dùng xịt hóa chất hoặc thả sâu sang vườn bạn bè.".tr
        case .relax:
            return "Kết hợp chăm sóc khu vườn cùng thói quen nghỉ ngơi và khám phá thế giới.".tr
        }
    }

    struct Highlight: Identifiable, Equatable {
        let id: String
        let icon: String
        let assetImage: String?
        let title: String
        let detail: String

        init(icon: String, assetImage: String? = nil, title: String, detail: String) {
            self.id = title
            self.icon = icon
            self.assetImage = assetImage
            self.title = title
            self.detail = detail
        }
    }

    var highlights: [Highlight] {
        switch self {
        case .welcome:
            return [
                Highlight(
                    icon: "leaf.fill",
                    assetImage: "oxygen",
                    title: "Thu thập Oxy & lên cấp".tr,
                    detail: "Dùng Oxy mở thêm tầng kệ mới và mua cây, chậu tại Cửa hàng.".tr
                ),
                Highlight(
                    icon: "music.note",
                    title: "Không gian chữa lành".tr,
                    detail: "Thay đổi phong cảnh, hiệu ứng và nhạc nền theo tâm trạng.".tr
                )
            ]
        case .care:
            return [
                Highlight(
                    icon: "hand.tap.fill",
                    assetImage: "oxygen",
                    title: "Chạm vào cây".tr,
                    detail: "Nhận Oxy và EXP để cây lớn từ hạt giống lên cây trưởng thành.".tr
                ),
                Highlight(
                    icon: "hand.point.up.left.fill",
                    assetImage: "water-can",
                    title: "Nhấn giữ cây để chăm sóc".tr,
                    detail: "Tưới cây tự tap 60s, bón phân tăng 1 cấp hoặc dùng xẻng dọn ô.".tr
                )
            ]
        case .gardenMenu:
            return [
                Highlight(
                    icon: "square.grid.2x2.fill",
                    title: "Nút Góc vườn (góc dưới phải)".tr,
                    detail: "Mở Cửa hàng, Bố cục, Thời tiết, Sức khỏe, Âm nhạc và Sự kiện.".tr
                ),
                Highlight(
                    icon: "square.grid.3x3.fill",
                    title: "Chế độ Bố cục & Huy hiệu Cấp".tr,
                    detail: "Chạm ô + để đặt cây mới, kéo thả đổi chỗ; chạm huy hiệu góc trên trái để xem ví tài nguyên.".tr
                )
            ]
        case .wildlife:
            return [
                Highlight(
                    icon: "ladybug.fill",
                    assetImage: "greenmeshbag-1@4.167x",
                    title: "Túi Bugsnet & Bắt sâu (+300 Oxy)".tr,
                    detail: "Sâu bọ làm cây tối màu và giảm 70% Oxy/EXP. Chạm sâu để nhận 300 Oxy và cất vào túi (tối đa 5 con).".tr
                ),
                Highlight(
                    icon: "aqi.medium",
                    title: "Xịt hóa chất & Thả sâu vườn bạn".tr,
                    detail: "Xịt hóa chất miễn phí 1 lần/ngày (VIP 5 lần) diệt sạch sâu trong 5s. Thả sâu vườn bạn tối đa 10 lần/ngày nhận 350 Oxy/con.".tr
                )
            ]
        case .relax:
            return [
                Highlight(
                    icon: "heart.text.square.fill",
                    assetImage: "gemstone",
                    title: "Sức khỏe nhận thưởng".tr,
                    detail: "Đạt mục tiêu Giấc ngủ và Bước chân mỗi ngày để nhận Oxy, Đá quý và Vé thời tiết.".tr
                ),
                Highlight(
                    icon: "cloud.rain.fill",
                    assetImage: "ticket",
                    title: "Thời tiết & Khám phá".tr,
                    detail: "Dùng Vé tạo mưa gió tự tap 60s, xịt hóa chất diệt sâu và ghé thăm vườn bạn bè.".tr
                )
            ]
        }
    }
}

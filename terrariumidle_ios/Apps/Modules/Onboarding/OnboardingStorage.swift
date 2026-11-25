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
    case relax

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .welcome: return "CHÀO MỪNG"
        case .care: return "CHĂM SÓC CÂY"
        case .gardenMenu: return "KỆ CÂY & GÓC VƯỜN"
        case .relax: return "THƯ GIÃN MỖI NGÀY"
        }
    }

    var title: String {
        switch self {
        case .welcome: return "Góc vườn nhỏ bình yên của riêng bạn"
        case .care: return "Chạm để tạo Oxy, giữ để chăm cây"
        case .gardenMenu: return "Sắp xếp kệ gỗ & mở rộng tầng mới"
        case .relax: return "Ngủ ngon, ngắm mưa và thăm bạn bè"
        }
    }

    var summary: String {
        switch self {
        case .welcome:
            return "Trồng cây, thu thập Oxy và lắng nghe âm nhạc nhẹ nhàng ngay trên kệ gỗ."
        case .care:
            return "Mỗi lần tương tác đều giúp cây xanh tốt hơn và tăng cấp độ khu vườn."
        case .gardenMenu:
            return "Mọi công cụ trang trí, cửa hàng và túi tài nguyên đều nằm gọn ở hai góc màn hình."
        case .relax:
            return "Kết hợp chăm sóc khu vườn cùng thói quen nghỉ ngơi và khám phá thế giới."
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
                    title: "Thu thập Oxy & lên cấp",
                    detail: "Dùng Oxy mở thêm tầng kệ mới và mua cây, chậu tại Cửa hàng."
                ),
                Highlight(
                    icon: "music.note",
                    title: "Không gian chữa lành",
                    detail: "Thay đổi phong cảnh, hiệu ứng và nhạc nền theo tâm trạng."
                )
            ]
        case .care:
            return [
                Highlight(
                    icon: "hand.tap.fill",
                    assetImage: "oxygen",
                    title: "Chạm vào cây",
                    detail: "Nhận Oxy và EXP để cây lớn từ hạt giống lên cây trưởng thành."
                ),
                Highlight(
                    icon: "hand.point.up.left.fill",
                    assetImage: "water-can",
                    title: "Nhấn giữ cây để chăm sóc",
                    detail: "Tưới cây tự tap 60s, bón phân tăng 1 cấp hoặc dùng xẻng dọn ô."
                )
            ]
        case .gardenMenu:
            return [
                Highlight(
                    icon: "square.grid.2x2.fill",
                    title: "Nút Góc vườn (góc dưới phải)",
                    detail: "Mở Cửa hàng, Bố cục, Thời tiết, Giấc ngủ, Âm nhạc và Sự kiện."
                ),
                Highlight(
                    icon: "square.grid.3x3.fill",
                    title: "Chế độ Bố cục & Huy hiệu Cấp",
                    detail: "Chạm ô + để đặt cây mới, kéo thả đổi chỗ; chạm huy hiệu góc trên trái để xem ví tài nguyên."
                )
            ]
        case .relax:
            return [
                Highlight(
                    icon: "moon.stars.fill",
                    assetImage: "gemstone",
                    title: "Giấc ngủ nhận thưởng",
                    detail: "Đạt mục tiêu ngủ mỗi ngày để nhận Oxy, Đá quý và Vé thời tiết."
                ),
                Highlight(
                    icon: "cloud.rain.fill",
                    assetImage: "ticket",
                    title: "Thời tiết & Khám phá",
                    detail: "Dùng Vé tạo mưa gió tự tap toàn vườn trong 60s và ghé thăm vườn bạn bè."
                )
            ]
        }
    }
}

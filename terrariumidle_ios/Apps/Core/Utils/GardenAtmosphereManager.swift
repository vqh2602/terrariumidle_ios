//
//  GardenAtmosphereManager.swift
//  terrariumidle_ios
//

import Combine
import Foundation

@MainActor
final class GardenAtmosphereManager: ObservableObject {
    static let shared = GardenAtmosphereManager()

    /// Khoảng thời gian tự động random lại landscape khi người dùng vẫn mở app (5 phút).
    static let landscapeRotationInterval: TimeInterval = 300

    @Published var backgroundRive: String = "i_sky_sun_day" {
        didSet {
            guard hasInitialized, backgroundRive != oldValue else { return }
            timerGeneration += 1
        }
    }
    @Published var overlayRive: String? = nil
    @Published private(set) var hasInitialized: Bool = false
    @Published private(set) var timerGeneration: Int = 0

    private init() {}

    /// Khởi tạo landscape và overlay ngẫu nhiên theo danh sách đã mở khóa đúng 1 lần khi vào app.
    /// Khi chuyển màn hình hoặc thao tác rồi quay lại HomeView sẽ không random lại.
    func initializeIfNeeded(gardenModel: GardenModel?) {
        guard !hasInitialized else { return }
        hasInitialized = true

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: gardenModel)

        let unlockedLandscapes = ItemDataManager.shared.getAllLandscapes().filter {
            unlockedIds.contains($0.id)
        }
        if !unlockedLandscapes.isEmpty {
            backgroundRive = unlockedLandscapes.randomElement()?.id ?? "Landscape1"
        }

        let unlockedOverlays = ItemDataManager.shared.getAllEffects().filter {
            unlockedIds.contains($0.id)
        }
        if !unlockedOverlays.isEmpty {
            overlayRive = unlockedOverlays.randomElement()?.id
        }

        timerGeneration += 1
    }

    /// Random 1 landscape khác trong danh sách đã mở khóa (ưu tiên khác landscape hiện tại).
    func randomizeLandscape(gardenModel: GardenModel?) {
        guard hasInitialized else { return }

        let unlockedIds = MusicUnlockHelper.getUnlockedMusicIds(from: gardenModel)
        let unlockedLandscapes = ItemDataManager.shared.getAllLandscapes().filter {
            unlockedIds.contains($0.id)
        }
        guard !unlockedLandscapes.isEmpty else { return }

        let candidates = unlockedLandscapes.filter { $0.id != backgroundRive }
        let pool = candidates.isEmpty ? unlockedLandscapes : candidates
        if let next = pool.randomElement() {
            backgroundRive = next.id
        }
    }

    func reset() {
        hasInitialized = false
        backgroundRive = "i_sky_sun_day"
        overlayRive = nil
        timerGeneration += 1
    }
}

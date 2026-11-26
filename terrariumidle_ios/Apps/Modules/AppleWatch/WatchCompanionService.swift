import Combine
import FirebaseAuth
import HealthKit
import SpriteKit
import SwiftUI
import UIKit
import WatchConnectivity

/// Read-only adapter: the existing game and sleep modules never depend on Watch code.
@MainActor
final class WatchCompanionService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchCompanionService()
    @Published private(set) var status = "Chưa kết nối Apple Watch"
    @Published private(set) var snapshot = WatchGardenSnapshot()
    @Published private(set) var healthMessage: String?
    @Published private(set) var isWatchReachable = false
    private var subscriptions = Set<AnyCancellable>()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var started = false
    private var sleepSeconds: Double?
    private var sleepMeasuredAt: Date?
    private var healthGeneration = 0
    private let healthStore = HKHealthStore()
    private var artworkKey = ""
    private var artwork: Data?
    private var thumbnailCache: [String: UIImage] = [:]

    func start() {
        guard !started else { return }
        started = true
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        FireStoreService.shared.$gradenModel.sink { [weak self] _ in
            // @Published emits before the new model is assigned.
            Task { @MainActor in self?.publish() }
        }.store(in: &subscriptions)
        LocalizationManager.shared.$currentLanguage.sink { [weak self] _ in
            Task { @MainActor in self?.publish(); self?.sendLatest() }
        }.store(in: &subscriptions)
        WatchWeatherService.shared.$weather.sink { [weak self] _ in
            Task { @MainActor in self?.publish() }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.publish() }.store(in: &subscriptions)
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { @MainActor in
                self?.clearSleep()
                WatchWeatherService.shared.reset()
                self?.publish()
                if self?.snapshot.enabled == true { WatchWeatherService.shared.refresh() }
            }
        }
        publish()
    }

    func foreground() async {
        start()
        publish()
        sendLatest()
        if snapshot.enabled { WatchWeatherService.shared.refresh() }
        if UserDefaults.standard.bool(forKey: "watch.sleepConnected") {
            await refreshSleep(requestPermission: false)
        }
    }

    private func clearSleep() {
        healthGeneration += 1
        sleepSeconds = nil
        sleepMeasuredAt = nil
    }

    func publish() {
        let defaults = UserDefaults.standard
        let garden = FireStoreService.shared.gradenModel
        // Firebase can retain the old garden during logout/account switching.
        let ownsGarden = Auth.auth().currentUser?.uid == garden?.user.userID && garden != nil
        let enabled = defaults.bool(forKey: "watch.enabled") && ownsGarden
        if !enabled || !defaults.bool(forKey: "watch.sleepConnected") { clearSleep() }
        if (!enabled || !defaults.bool(forKey: "watch.weatherEnabled")),
           WatchWeatherService.shared.weather != nil || WatchWeatherService.shared.isLoading {
            WatchWeatherService.shared.reset()
        }
        var next = WatchGardenSnapshot()
        next.enabled = enabled
        next.languageCode = LocalizationManager.shared.currentLanguage.rawValue
        if enabled, let garden {
            let plantedList = garden.plants.filter { $0.idPlant.hasPrefix("plant") && !$0.idPot.isEmpty }
            let plantedPosition = defaults.string(forKey: "watch.plantedPosition") ?? ""
            var plantID = defaults.string(forKey: "watch.plantID") ?? ""
            var potID = defaults.string(forKey: "watch.potID") ?? ""

            // Auto-select the first currently growing plant if none is chosen yet.
            if plantID.isEmpty, let first = plantedList.first {
                plantID = first.idPlant
                potID = first.idPot
                defaults.set(first.position, forKey: "watch.plantedPosition")
                defaults.set(first.idPlant, forKey: "watch.plantID")
                defaults.set(first.idPot, forKey: "watch.potID")
            }

            let selectedPlanted: GardenModel.Plant? = {
                if !plantedPosition.isEmpty,
                   let exact = plantedList.first(where: { $0.position == plantedPosition && $0.idPlant == plantID }) {
                    return exact
                }
                return plantedList.first(where: {
                    $0.idPlant == plantID && (potID.isEmpty || $0.idPot == potID)
                })
            }()

            let ownedPlants = Set(garden.cart.cartPlants + garden.plants.map(\.idPlant))
            let ownedPots = Set(garden.cart.cartPots + garden.plants.map(\.idPot))
            let resolvedPlantID = selectedPlanted?.idPlant ?? plantID
            let resolvedPotID = selectedPlanted?.idPot ?? potID
            let plant = ItemDataManager.shared.getAllPlants().first { $0.id == resolvedPlantID && ownedPlants.contains($0.id) }
            let pot = ItemDataManager.shared.getAllPots().first { $0.id == resolvedPotID && ownedPots.contains($0.id) }

            next.plantName = plant?.name.tr ?? "Chọn cây trên iPhone".tr
            next.plantLevel = selectedPlanted?.plantLevel
            let isHanging = (selectedPlanted?.isHanging ?? false)
                || (plant?.itemTypeAttribute.isHanging ?? false)
                || (pot?.itemTypeAttribute.isHanging ?? false)
            let key = "\(plant?.id ?? "")/\(pot?.id ?? "")/\(next.plantLevel ?? 0)/\(isHanging)"
            if key != artworkKey {
                artworkKey = key
                artwork = makeArtwork(plant: plant, pot: pot, plantLevel: next.plantLevel, isHanging: isHanging)
            }
            next.artwork = artwork
            next.clockStyle = GardenClockStyle(rawValue: defaults.string(forKey: "watch.clockStyle") ?? "") ?? .digital
            next.theme = GardenClockTheme(rawValue: defaults.string(forKey: "watch.theme") ?? "") ?? .schedule
            var appearance = GardenClockAppearance()
            appearance.layout = GardenClockLayout(rawValue: defaults.string(forKey: "watch.layout") ?? "") ?? .balanced
            appearance.font = GardenClockFont(rawValue: defaults.string(forKey: "watch.font") ?? "") ?? .rounded
            appearance.accent = GardenAccent(rawValue: defaults.string(forKey: "watch.accent") ?? "") ?? .mint
            appearance.plantScale = min(1.3, max(0.7, defaults.object(forKey: "watch.plantScale") as? Double ?? 1))
            appearance.showDate = defaults.object(forKey: "watch.showDate") as? Bool ?? true
            appearance.showPlantName = defaults.object(forKey: "watch.showPlantName") as? Bool ?? true
            appearance.showSeconds = defaults.bool(forKey: "watch.showSeconds")
            appearance.use24HourTime = defaults.object(forKey: "watch.use24HourTime") as? Bool ?? true
            appearance.animatePlant = defaults.object(forKey: "watch.animatePlant") as? Bool ?? true
            next.appearance = appearance
            next.scheduleEnabled = defaults.bool(forKey: "sleep.scheduleEnabled")
            next.bedMinutes = defaults.object(forKey: "sleep.bedMinutes") as? Int ?? 22 * 60
            next.wakeMinutes = defaults.object(forKey: "sleep.wakeMinutes") as? Int ?? 6 * 60
            next.sleepSeconds = sleepSeconds
            next.sleepMeasuredAt = sleepMeasuredAt
            if defaults.bool(forKey: "watch.weatherEnabled") {
                next.weather = WatchWeatherService.shared.weather
            }
        }
        // Ignore timestamps when deciding whether there is new display state to send.
        next.updatedAt = snapshot.updatedAt
        guard next != snapshot else { return }
        next.updatedAt = .now
        snapshot = next
        sendLatest()
        if next.enabled, defaults.bool(forKey: "watch.weatherEnabled") {
            WatchWeatherService.shared.refresh()
        }
    }

    func forceSyncNow() {
        publish()
        sendLatest()
    }

    private func sendLatest() {
        guard WCSession.isSupported() else {
            isWatchReachable = false
            status = "Thiết bị không hỗ trợ Apple Watch"
            return
        }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard session.isPaired else {
            isWatchReachable = false
            status = "Chưa ghép đôi Apple Watch"
            return
        }
        guard session.isWatchAppInstalled else {
            isWatchReachable = false
            status = "Cài Terrarium trên Apple Watch để đồng bộ"
            return
        }
        isWatchReachable = session.isReachable
        do {
            let data = try JSONEncoder().encode(snapshot)
            try session.updateApplicationContext([WatchGardenSnapshot.contextKey: data])
            if session.isReachable {
                session.sendMessage([WatchGardenSnapshot.contextKey: data], replyHandler: nil, errorHandler: nil)
                status = "Đã đồng bộ trực tiếp lên Apple Watch"
            } else {
                status = "Đã gửi trạng thái; Watch sẽ cập nhật khi hệ thống chuyển dữ liệu"
            }
        } catch {
            status = "Chưa gửi được; sẽ thử lại khi kết nối trở lại"
        }
    }

    func setSleepConnection(_ enabled: Bool) async {
        UserDefaults.standard.set(enabled, forKey: "watch.sleepConnected")
        clearSleep()
        healthMessage = nil
        publish()
        if enabled { await refreshSleep(requestPermission: true) }
    }

    private func refreshSleep(requestPermission: Bool) async {
        guard HKHealthStore.isHealthDataAvailable(), Auth.auth().currentUser != nil,
              UserDefaults.standard.bool(forKey: "watch.sleepConnected"),
              UserDefaults.standard.bool(forKey: "watch.enabled") else { return }
        healthGeneration += 1
        let generation = healthGeneration
        let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        do {
            if requestPermission {
                // Read-only permission. Does not change Apple's Sleep settings.
                try await healthStore.requestAuthorization(toShare: [], read: [type])
            }
            guard generation == healthGeneration else { return }
            let end = Date()
            let start = end.addingTimeInterval(-86400)
            let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
                let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
                healthStore.execute(HKSampleQuery(sampleType: type, predicate: predicate,
                    limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples as? [HKCategorySample] ?? []) }
                })
            }
            guard generation == healthGeneration else { return }
            let values = Set([HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                              HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                              HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                              HKCategoryValueSleepAnalysis.asleepREM.rawValue])
            let intervals = samples.filter { values.contains($0.value) }.compactMap { sample -> DateInterval? in
                let lower = max(start, sample.startDate), upper = min(end, sample.endDate)
                return upper > lower ? DateInterval(start: lower, end: upper) : nil
            }.sorted { $0.start < $1.start }
            var merged: [DateInterval] = []
            for interval in intervals {
                if let previous = merged.last, interval.start <= previous.end {
                    merged[merged.count - 1] = DateInterval(start: previous.start, end: max(previous.end, interval.end))
                } else { merged.append(interval) }
            }
            sleepSeconds = merged.isEmpty ? nil : merged.reduce(0) { $0 + $1.duration }
            sleepMeasuredAt = merged.isEmpty ? nil : end
            healthMessage = merged.isEmpty ? "Chưa có dữ liệu ngủ được chia sẻ. Cây vẫn phát triển bình thường." : nil
            publish()
        } catch {
            guard generation == healthGeneration else { return }
            clearSleep()
            healthMessage = "Chưa đọc được dữ liệu giấc ngủ. Bạn có thể thử kết nối lại."
            publish()
        }
    }

    private func resolvePlantImage(plant: ItemData, plantLevel: Int?) -> UIImage? {
        if plantLevel == 1, let seed = UIImage(named: "\(plant.id)_Asset-100@4.167x") {
            return seed
        }
        if plantLevel == 2, let sprout = UIImage(named: "\(plant.id)_Asset-200@4.167x") {
            return sprout
        }
        return UIImage(named: plant.image)
    }

    func renderThumbnail(plant: ItemData, pot: ItemData, plantLevel: Int?, isHanging: Bool, edge: CGFloat = 128) -> UIImage? {
        let effectiveHanging = isHanging || plant.itemTypeAttribute.isHanging || pot.itemTypeAttribute.isHanging
        let level = plantLevel ?? 3
        let cacheKey = "\(plant.id)/\(pot.id)/\(level)/\(effectiveHanging)/\(Int(edge))"
        if let cached = thumbnailCache[cacheKey] {
            return cached
        }

        // Render via the exact SpriteKit TerrariumSlotScene so standing & hanging pots,
        // plantMount sockets, Z-ordering, and growth stages match the main garden 1:1.
        let sceneSize = CGSize(width: edge, height: edge)
        let slotSize = CGSize(width: edge * 0.88, height: edge * 0.94)
        let scene = TerrariumSlotScene(size: sceneSize)
        scene.configure(
            potId: pot.id,
            plantId: plant.id,
            plantLevel: level,
            isHanging: effectiveHanging,
            slotSize: slotSize,
            widthFill: PotRegistry.defaultWidthFill(for: pot.id),
            itemTypeAttribute: plant.itemTypeAttribute
        )
        let skView = SKView(frame: CGRect(origin: .zero, size: sceneSize))
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        if let texture = skView.texture(from: scene, crop: CGRect(x: -edge / 2, y: 0, width: edge, height: edge)) {
            let rendered = UIImage(cgImage: texture.cgImage())
            thumbnailCache[cacheKey] = rendered
            return rendered
        }

        // Fallback to static image composition if SpriteKit texture capture is unavailable.
        guard let plantImage = resolvePlantImage(plant: plant, plantLevel: plantLevel),
              let potImage = UIImage(named: pot.image) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let fallback = UIGraphicsImageRenderer(size: sceneSize, format: format).image { _ in
            func draw(_ image: UIImage, in rect: CGRect, alignTop: Bool = false) {
                let scale = min(rect.width / image.size.width, rect.height / image.size.height)
                let width = image.size.width * scale, height = image.size.height * scale
                let y = alignTop ? rect.minY : (rect.maxY - height)
                image.draw(in: CGRect(x: rect.midX - width / 2, y: y, width: width, height: height))
            }
            if effectiveHanging {
                draw(potImage, in: CGRect(x: edge * 0.18, y: edge * 0.02, width: edge * 0.64, height: edge * 0.60), alignTop: true)
                draw(plantImage, in: CGRect(x: edge * 0.14, y: edge * 0.28, width: edge * 0.72, height: edge * 0.68), alignTop: true)
            } else {
                draw(plantImage, in: CGRect(x: edge * 0.08, y: edge * 0.04, width: edge * 0.84, height: edge * 0.68))
                draw(potImage, in: CGRect(x: edge * 0.24, y: edge * 0.65, width: edge * 0.52, height: edge * 0.31))
            }
        }
        thumbnailCache[cacheKey] = fallback
        return fallback
    }

    private func makeArtwork(plant: ItemData?, pot: ItemData?, plantLevel: Int?, isHanging: Bool) -> Data? {
        guard let plant, let pot else { return nil }
        // Static thumbnails only; never loads the full SpriteKit scene on Watch.
        for edge in [192, 160, 128, 96] {
            if let image = renderThumbnail(plant: plant, pot: pot, plantLevel: plantLevel, isHanging: isHanging, edge: CGFloat(edge)),
               let data = image.pngData(), data.count <= 40_000 {
                return data
            }
        }
        return nil
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.sendLatest() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.sendLatest() }
    }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.sendLatest() }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["requestSnapshot"] as? Bool == true {
            Task { @MainActor in self.sendLatest() }
        }
    }
}

struct WatchCompanionLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var phase
    func body(content: Content) -> some View {
        content.task(id: phase) {
            if phase == .active { await WatchCompanionService.shared.foreground() }
        }
    }
}

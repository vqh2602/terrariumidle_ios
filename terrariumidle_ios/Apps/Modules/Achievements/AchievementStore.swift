import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

@MainActor
final class AchievementStore: ObservableObject {
    static let shared = AchievementStore()
    @Published private(set) var progress = AchievementProgress()
    @Published private(set) var userID: String?
    @Published private(set) var cloudError: String?

    private let defaults: UserDefaults
    private let deviceID: String
    private var subscriptions = Set<AnyCancellable>()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var cloudTask: Task<Void, Never>?
    private var localTask: Task<Void, Never>?
    private var generation = UUID()
    private var dirty = false
    private var started = false

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let key = "terrarium.achievements.installation"
        deviceID = defaults.string(forKey: key) ?? UUID().uuidString
        defaults.set(deviceID, forKey: key)
    }

    var completedCount: Int { AchievementCatalog.all.filter { $0.percent(for: progress) >= 100 }.count }
    private func storageKey(_ uid: String) -> String { "terrarium.achievements.v1.\(uid)" }

    func start() {
        guard !started else { return }
        started = true
        FireStoreService.shared.$gradenModel.sink { [weak self] garden in
            Task { @MainActor in self?.observe(garden) }
        }.store(in: &subscriptions)
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task { @MainActor in self?.observe(FireStoreService.shared.gradenModel) }
        }
    }

    func observe(_ garden: GardenModel?) {
        guard let garden, garden.user.userID == Auth.auth().currentUser?.uid else {
            switchUser(nil)
            return
        }
        switchUser(garden.user.userID)
        var next = progress
        let items = ItemDataManager.shared
        let plantIDs = Set(items.getAllPlants().map(\.id))
        let potIDs = Set(items.getAllPots().map(\.id))
        let stickerIDs = Set(items.getAllDecorations().map(\.id))
        let animalIDs = Set(items.getAllAnimals().map(\.id))
        // Match visible sockets: duplicate records and standalone items never inflate counts.
        var sockets: [String: GardenModel.Plant] = [:]
        for plant in garden.plants { sockets[plant.position] = plant }
        let plants = sockets.values.filter { plantIDs.contains($0.idPlant) && potIDs.contains($0.idPot) }
        next.include(garden.cart.cartPlants.filter { plantIDs.contains($0) } + plants.map(\.idPlant), for: .plantsOwned)
        next.include(garden.cart.cartPots.filter { potIDs.contains($0) } + plants.map(\.idPot), for: .potsOwned)
        next.include(garden.cart.cartStickers.filter { stickerIDs.contains($0) }
                         + sockets.values.map(\.idPlant).filter { stickerIDs.contains($0) }, for: .stickersOwned)
        next.include(garden.cart.cartAnimals.filter { animalIDs.contains($0) }
                         + sockets.values.map(\.idPlant).filter { animalIDs.contains($0) }, for: .animalsOwned)
        next.include(plants.filter { $0.plantLevel >= 3 }.map(\.idPlant), for: .matureSpecies)
        next.observe(plants.map(\.plantLevel).max() ?? 0, for: .plantLevel)
        next.observe(plants.count, for: .plantedTogether)
        next.observe(garden.user.userLevel, for: .gardenerLevel)
        next.observe(garden.user.userFloor, for: .floors)
        next.observe(garden.user.userTotalLike, for: .likesReceived)
        if UIApplication.shared.applicationState == .active {
            next.include([AchievementProgress.dayID(Date())], for: .activeDays)
        }
        if next != progress { progress = next; changed() }
        GameCenterAchievementService.shared.resumeIfEnabled(userID: garden.user.userID)
    }

    private func switchUser(_ uid: String?) {
        guard userID != uid else { return }
        persistLocally()
        cloudTask?.cancel()
        localTask?.cancel()
        cloudTask = nil
        localTask = nil
        generation = UUID()
        userID = uid
        dirty = false
        cloudError = nil
        progress = uid.flatMap { defaults.data(forKey: storageKey($0)) }
            .flatMap { try? JSONDecoder().decode(AchievementProgress.self, from: $0) } ?? AchievementProgress()
        GameCenterAchievementService.shared.resetGardenSession()
        if uid != nil { scheduleCloudSync(delay: 0) }
    }

    /// Called only after the corresponding gameplay operation succeeds.
    func recordHarvest(oxygen: Int) {
        observe(FireStoreService.shared.gradenModel)
        guard userID != nil, oxygen > 0 else { return }
        var next = progress
        next.increment(.harvests, device: deviceID)
        next.increment(.oxygenCollected, device: deviceID, by: oxygen)
        progress = next
        changed()
    }

    func record(_ metric: AchievementMetric, amount: Int = 1) {
        observe(FireStoreService.shared.gradenModel)
        guard userID != nil, [.harvests, .oxygenCollected, .watering, .fertilizing, .weather, .plantings].contains(metric), amount > 0 else { return }
        progress.increment(metric, device: deviceID, by: amount)
        changed()
    }

    func recordGarden(_ gardenID: String, liked: Bool = false) {
        observe(FireStoreService.shared.gradenModel)
        guard let userID, gardenID != userID, !gardenID.isEmpty else { return }
        var next = progress
        next.include([gardenID], for: .gardensVisited)
        if liked { next.include([gardenID], for: .heartsGiven) }
        if next != progress { progress = next; changed() }
    }

    private func changed() {
        dirty = true
        if localTask == nil {
            localTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.persistLocally()
                self.localTask = nil
            }
        }
        // A fixed window, rather than restarting on every tap, also handles continuous auto-taps.
        scheduleCloudSync(delay: 15)
        GameCenterAchievementService.shared.scheduleReport()
    }

    func persistLocally() {
        guard let userID, let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: storageKey(userID))
    }

    func foreground() {
        observe(FireStoreService.shared.gradenModel)
        scheduleCloudSync(delay: 0)
        GameCenterAchievementService.shared.scheduleReport()
    }

    func background() {
        persistLocally()
        GameCenterAchievementService.shared.reportNow()
        // Preserve pending progress synchronously on disk; the cloud transaction may finish later.
        if cloudTask == nil { scheduleCloudSync(delay: 0) }
    }

    func retrySync() {
        scheduleCloudSync(delay: 0)
        GameCenterAchievementService.shared.reportNow()
    }

    private func scheduleCloudSync(delay: Double) {
        guard userID != nil, cloudTask == nil else { return }
        let token = generation
        cloudTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard let self, token == self.generation else { return }
            await self.syncCloud(token: token)
            guard token == self.generation else { return }
            self.cloudTask = nil
            if self.dirty && self.cloudError == nil { self.scheduleCloudSync(delay: 15) }
        }
    }

    private func syncCloud(token: UUID) async {
        guard let uid = userID, uid == Auth.auth().currentUser?.uid else { return }
        let local = progress
        dirty = false
        let reference = Firestore.firestore().collection("users").document(uid)
        do {
            let result = try await Firestore.firestore().runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(reference)
                    guard snapshot.exists else { throw NSError(domain: "Achievements", code: 1) }
                    var merged = AchievementProgress(dictionary: snapshot.data()?["achievementProgress"] as? [String: Any] ?? [:])
                    merged.merge(local)
                    transaction.updateData(["achievementProgress": merged.dictionary], forDocument: reference)
                    return merged.dictionary
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard token == generation, uid == userID, uid == Auth.auth().currentUser?.uid else { return }
            if let dictionary = result as? [String: Any] {
                progress.merge(AchievementProgress(dictionary: dictionary))
            }
            cloudError = nil
            persistLocally()
            GameCenterAchievementService.shared.scheduleReport()
        } catch {
            guard token == generation else { return }
            dirty = true
            cloudError = "Tiến độ đã lưu trên máy. Chưa đồng bộ được khu vườn.".tr
        }
    }
}

//
//  FireStoreService.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 6/2/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FireStoreService: ObservableObject {
    static let shared = FireStoreService()
    /// Thông tin user hiện tại
    private var currentUser: User?
    private var dataGraden: [String: Any]?
    
    @Published var gradenModel: GardenModel?

    // MARK: - Debounce & Background Persistence Properties
    private var debounceTask: Task<Void, Never>?
    private var pendingGardenModel: GardenModel?
    private var isClaimingHealthReward = false
    private let eventOxygenLock = NSLock()
    private var pendingEventOxygen: Int = 0
    private var locallyRemovedPestIds: Set<String> = []

    func recordEventOxygen(_ amount: Int) {
        guard amount > 0 else { return }
        eventOxygenLock.lock()
        pendingEventOxygen += amount
        eventOxygenLock.unlock()
    }

    func consumePendingEventOxygen() -> Int {
        eventOxygenLock.lock()
        let delta = pendingEventOxygen
        pendingEventOxygen = 0
        eventOxygenLock.unlock()
        return delta
    }

    /// Clears in-memory garden state and pending saves when signing out so nothing leaks across accounts.
    func resetSession() {
        debounceTask?.cancel()
        debounceTask = nil
        pendingGardenModel = nil
        gradenModel = nil
        dataGraden = nil
        currentUser = nil
        locallyRemovedPestIds.removeAll()
        _ = consumePendingEventOxygen()
        Task { @MainActor in
            HealthRewardStatusStore.shared.resetSession()
        }
    }

    // MARK: - Dependencies

    private let auth: AuthService = AuthService.shared
    private let db = Firestore.firestore()

    // MARK: - Init

    /// Private init để ngăn tạo instance mới từ bên ngoài (enforcing Singleton)
    private init() {
        // Lắng nghe khi app chuẩn bị vào background hoặc ngưng hoạt động để lưu ngay lập tức các thay đổi đang chờ
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushPendingUpdates()
        }
        #endif
    }
    
    var currentGradenModel: GardenModel? {
      return gradenModel
    }
    
    func realtimeChangeDataGraden(userId: String?) {
        guard let userId else { return }
        db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                // Nếu snapshot này sinh ra do local write của chính thiết bị (hasPendingWrites),
                // hoặc đang có thay đổi local đang chờ debounce, bỏ qua để tránh re-render giật lag
                if document.metadata.hasPendingWrites || self.pendingGardenModel != nil || self.isClaimingHealthReward {
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                self.dataGraden = data
                do {
                    let model = try GardenModel(dict: data)
                    let sanitized = self.sanitizeGardenModel(model)
                    DispatchQueue.main.async {
                        self.gradenModel = sanitized
                        print("User realtime:", sanitized.user.userName, "Plants:", sanitized.user.userFloor)
                    }
                } catch {
                    print("Failed to parse GardenModel: \(error)")
                }
            }
    }
    /// lấy dữ liệu khu vườn theo id user
    /// pb03Q3R93naRsjiAuyTGz0BPHI92 -> app flutter
    /// 0pMij25JsAV4lMkshYzAFLisdpz2 -> app ios
    func getDataById(userId: String) async -> GardenModel? {
        let docRef = db.collection("users").document(userId)
        print("userIdLoad: \(userId)")
        do {
            let snapshot = try await docRef.getDocument()
            let dict = snapshot.data() ?? [:]
            dataGraden = dict
            // Parse GardenModel from the dictionary if possible
            let model = try GardenModel(dict: dict)
            let sanitized = sanitizeGardenModel(model)
            await MainActor.run {
                self.gradenModel = sanitized
            }
            print("User:", sanitized.user.userName, "Plants:", sanitized.user.userFloor)
            return sanitized
        } catch {
            print("Error loading garden: \(error)")
            return nil
        }
    }

    /// Đồng bộ thủ công dữ liệu khu vườn trực tiếp từ máy chủ Firestore.
    func syncGardenData(userId: String) async throws -> GardenModel {
        flushPendingUpdates()
        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument(source: .server)
        let dict = snapshot.data() ?? [:]
        dataGraden = dict
        let model = try GardenModel(dict: dict)
        let sanitized = sanitizeGardenModel(model)
        await MainActor.run {
            self.gradenModel = sanitized
        }
        return sanitized
    }

    // MARK: - Create User Data

    /// Tạo dữ liệu mặc định cho tài khoản mới
    /// - Parameters:
    ///   - email: Email của user
    ///   - name: Tên của user (optional, sẽ tạo random nếu nil)
    ///   - id: User ID từ Firebase Auth
    func createDataUser(email: String?, name: String?, id: String) async throws {
        // Tạo username mặc định nếu không có tên
        let userName = name ?? "user\(Int.random(in: 0 ... 999_999_999))"

        // Tạo dữ liệu user mặc định
        let userData: [String: Any] = [
            "isBan": false,
            "isServerUpdate": false,
            "user": [
                "userAvatar": "https://i.imgur.com/pWzNAg8.jpeg",
                "userName": userName,
                "bag": [],
                "identifier": NSNull(),
                "latestPurchaseDate": NSNull(),
                "userEmail": email ?? "",
                "userID": id,
                "userTotalLike": 0,
                "userFloor": 2,
                "userLevel": 1,
                "userLevelEXP": 0,
                "userImageBackground": NSNull(),
            ],
            "cart": [
                "cartPlants": [],
                "cartPots": [],
                "cartStickers": [],
                "cartAnimals": [],
            ],
            "item": [
                "fertilizer": 40,
                "shovel": 5,
            ],
            "money": [
                "oxygen": 10000,
                "gemstone": 20,
                "ticket": 0,
            ],
            "plants": [],
        ]

        do {
            try await db.collection("users").document(id).setData(userData)
           _ = await getDataById(userId: id)
            print("✅ Tạo tài khoản thành công cho user: \(userName)")
        } catch {
            print("❌ Lỗi tạo tài khoản: \(error.localizedDescription)")
            // Đăng xuất nếu tạo tài khoản thất bại
            try? Auth.auth().signOut()
            throw error
        }
    }

    // MARK: - Garden Model Sanitization

    /// Khử trùng lặp cây cùng vị trí và đảm bảo tính nhất quán của dữ liệu
    public func sanitizeGardenModel(_ model: GardenModel) -> GardenModel {
        var uniquePlants: [String: GardenModel.Plant] = [:]
        for plant in model.plants {
            let key = plant.position
            if let existing = uniquePlants[key] {
                // Ưu tiên bản ghi có ID không rỗng và có plantLevel cao nhất
                if existing.idPlant.isEmpty && !plant.idPlant.isEmpty {
                    uniquePlants[key] = plant
                } else if !plant.idPlant.isEmpty && plant.plantLevel >= existing.plantLevel {
                    uniquePlants[key] = plant
                }
            } else {
                uniquePlants[key] = plant
            }
        }
        var cleaned = model
        cleaned.plants = Array(uniquePlants.values)
        return cleaned
    }

    // MARK: - Update User Data

    public struct PlantTapResult {
        public let oxygenGained: Int
        public let newPlantLevel: Int
        public let didPlantLevelUp: Bool
        public let newUserLevel: Int
        public let didUserLevelUp: Bool

        public init(
            oxygenGained: Int,
            newPlantLevel: Int,
            didPlantLevelUp: Bool,
            newUserLevel: Int,
            didUserLevelUp: Bool
        ) {
            self.oxygenGained = oxygenGained
            self.newPlantLevel = newPlantLevel
            self.didPlantLevelUp = didPlantLevelUp
            self.newUserLevel = newUserLevel
            self.didUserLevelUp = didUserLevelUp
        }
    }

    static let baseTapExpGain = 100

    static func tapExpGain(isVIP: Bool) -> Int {
        isVIP ? baseTapExpGain * 2 : baseTapExpGain
    }

    /// Xử lý tap cây một cách nguyên tử (atomic), ngăn chặn race condition khi tap nhiều cây cùng lúc,
    /// gom toàn bộ các lần tap đồng thời vào cùng một snapshot dữ liệu duy nhất và debounce Firestore.
    @MainActor
    @discardableResult
    func recordPlantTap(at position: String, plantId: String) -> PlantTapResult? {
        guard var garden = self.gradenModel else { return nil }

        let targetPos = position
        guard let plantIndex = garden.plants.lastIndex(where: {
            $0.position == targetPos && $0.idPlant == plantId
        }) ?? garden.plants.lastIndex(where: {
            $0.position == targetPos && !$0.idPlant.isEmpty
        }) ?? garden.plants.firstIndex(where: { $0.position == targetPos }) else {
            return nil
        }

        var plant = garden.plants[plantIndex]
        let currentLevel = plant.plantLevel

        // Lấy tỉ lệ drop và lượng oxy nhận được theo cấp độ
        let dropChance = ShareFunc.getDropRate(level: currentLevel).chance

        guard Double.random(in: 0...1) <= dropChance else {
            return nil
        }

        let baseOxygenDrop = ItemDataManager.shared.collectionOxygen(
            level: currentLevel, plantId: plant.idPlant, potId: plant.idPot
        )
        let isVIP = SubscriptionManager.isVIP(gardenModel: garden)
        let vipAdjustedOxygen = isVIP
            ? Int((Double(baseOxygenDrop) * 1.5).rounded())
            : baseOxygenDrop
        let baseExpGain = Self.tapExpGain(isVIP: isVIP)

        let isInfested = garden.isPlantInfested(at: targetPos)
        let oxygenDrop = isInfested
            ? max(1, Int((Double(vipAdjustedOxygen) * GardenModel.pestPenaltyMultiplier).rounded()))
            : vipAdjustedOxygen
        let expGain = isInfested
            ? max(1, Int((Double(baseExpGain) * GardenModel.pestPenaltyMultiplier).rounded()))
            : baseExpGain

        // 1. Tăng oxy
        garden.money.oxygen += oxygenDrop
        recordEventOxygen(oxygenDrop)

        // 2. Tăng EXP cho cây
        plant.platLevelExp += expGain
        var didPlantLevelUp = false
        if currentLevel < 3 {
            let maxExp = ShareFunc.calculatePlantMaxExp(level: currentLevel)
            if plant.platLevelExp >= maxExp {
                plant.plantLevel += 1
                plant.platLevelExp -= maxExp
                didPlantLevelUp = true
            }
        }

        // Cập nhật lại danh sách cây: loại bỏ trùng lặp tại toạ độ này và gán bản ghi mới
        garden.plants.removeAll { $0.position == targetPos }
        garden.plants.append(plant)

        // 3. Tăng EXP cho người dùng
        garden.user.userLevelEXP += expGain
        var didUserLevelUp = false
        let userMaxExp = ShareFunc.calculateUserMaxExp(level: garden.user.userLevel)
        if garden.user.userLevelEXP >= userMaxExp {
            garden.user.userLevel += 1
            garden.user.userLevelEXP -= userMaxExp
            didUserLevelUp = true
        }

        // Cập nhật model và debounce lưu Firestore
        saveGarden(gardenModel: garden, debounce: true)
        if ItemDataManager.shared.getPlant(byId: plant.idPlant) != nil {
            AchievementStore.shared.recordHarvest(oxygen: oxygenDrop)
        }

        return PlantTapResult(
            oxygenGained: oxygenDrop,
            newPlantLevel: plant.plantLevel,
            didPlantLevelUp: didPlantLevelUp,
            newUserLevel: garden.user.userLevel,
            didUserLevelUp: didUserLevelUp
        )
    }

    /// Cập nhật dữ liệu khu vườn:
    /// - Cập nhật ngay lập tức `gradenModel` trên MainActor để UI hiển thị mượt mà 60/120 FPS không độ trễ.
    /// - `debounce == true`: Dành cho thao tác lặp lại nhiều lần liên tục (như tap nhặt oxy).
    ///   Tự động gom toàn bộ các lần tap trong khoảng 1.2s thành 1 lần ghi Firestore duy nhất chạy ngầm ở background.
    /// - `debounce == false`: Ghi ngay lập tức lên Firestore ở background thread (không block Main UI).
    @MainActor
    func saveGarden(gardenModel: GardenModel, debounce: Bool = false) {
        let sanitized = sanitizeGardenModel(gardenModel)
        // Cập nhật ngay local model để UI phản hồi ngay lập tức
        self.gradenModel = sanitized
        self.pendingGardenModel = sanitized
        guard !isClaimingHealthReward else { return }

        if debounce {
            debounceTask?.cancel()
            debounceTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 giây sau lần tương tác cuối cùng
                    guard !Task.isCancelled else { return }
                    guard let self = self, let latestModel = self.pendingGardenModel else { return }
                    self.pendingGardenModel = nil
                    Task.detached(priority: .background) {
                        await self.performFirestoreUpdate(gardenModel: latestModel)
                    }
                } catch {
                    // Task bị huỷ khi người dùng tiếp tục tap - hoạt động bình thường
                }
            }
        } else {
            debounceTask?.cancel()
            debounceTask = nil
            pendingGardenModel = nil
            let modelToSave = sanitized
            Task.detached(priority: .background) { [weak self] in
                await self?.performFirestoreUpdate(gardenModel: modelToSave)
            }
        }
    }

    private enum HealthRewardKind {
        case sleep, steps

        var dailyField: String { self == .sleep ? "sleepRewardDays" : "stepsRewardDays" }
        var milestoneField: String { self == .sleep ? "sleepRewardMilestones" : "stepsRewardMilestones" }
        var weekDaysField: String { self == .sleep ? "sleepRewardWeekDays" : "stepsRewardWeekDays" }
        var oxygenField: String { self == .sleep ? "sleepRewardOxygen" : "stepsRewardOxygen" }
        var gemsField: String { self == .sleep ? "sleepRewardGems" : "stepsRewardGems" }
        var ticketsField: String { self == .sleep ? "sleepRewardTickets" : "stepsRewardTickets" }
    }

    /// The receipt and currency credit commit together. No sleep samples leave the device.
    @MainActor
    func claimSleepReward(grant: SleepRewardGrant, goal: Double) async throws -> Bool {
        guard SleepRewardRules.isValid(grant, goal: goal) else {
            throw EventReward.failure("Chưa thể nhận phần thưởng lúc này.".tr)
        }
        return try await claimHealthReward(
            kind: .sleep,
            id: grant.id,
            isDaily: grant.kind == .daily,
            isWeekly: grant.kind == .weekly,
            dayIds: grant.days.map(\.id),
            oxygen: grant.oxygen,
            gems: grant.gems,
            tickets: grant.tickets
        )
    }

    /// The receipt and currency credit commit together. No raw step samples leave the device.
    @MainActor
    func claimStepsReward(grant: StepsRewardGrant, goal: Int) async throws -> Bool {
        guard StepsRewardRules.isValid(grant, goal: goal) else {
            throw EventReward.failure("Chưa thể nhận phần thưởng lúc này.".tr)
        }
        return try await claimHealthReward(
            kind: .steps,
            id: grant.id,
            isDaily: grant.kind == .daily,
            isWeekly: grant.kind == .weekly,
            dayIds: grant.days.map(\.id),
            oxygen: grant.oxygen,
            gems: grant.gems,
            tickets: grant.tickets
        )
    }

    @MainActor
    private func claimHealthReward(
        kind: HealthRewardKind,
        id key: String,
        isDaily: Bool,
        isWeekly: Bool,
        dayIds: [String],
        oxygen grantOxygen: Int,
        gems grantGems: Int,
        tickets grantTickets: Int
    ) async throws -> Bool {
        guard !isClaimingHealthReward,
              let garden = gradenModel,
              Auth.auth().currentUser?.uid == garden.user.userID else {
            throw EventReward.failure("Chưa thể nhận phần thưởng lúc này.".tr)
        }
        let uid = garden.user.userID
        isClaimingHealthReward = true
        debounceTask?.cancel()
        debounceTask = nil
        pendingGardenModel = nil
        defer {
            isClaimingHealthReward = false
            flushPendingUpdates()
        }
        // Drain previously queued garden writes and persist the current local balance first.
        guard await performFirestoreUpdate(gardenModel: garden) != nil else {
            pendingGardenModel = gradenModel
            throw EventReward.failure("Chưa lưu được khu vườn. Hãy kiểm tra mạng và thử lại.".tr)
        }
        let target = db.collection("users").document(uid)
        do {
            let outcome: [String: Int] = try await GardenWriteQueue.shared.perform {
                let result = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(target)
                        guard let data = snapshot.data() else {
                            throw EventReward.failure("Không tìm thấy khu vườn.".tr)
                        }
                        let receiptField = isDaily ? kind.dailyField : kind.milestoneField
                        let receipts = data[receiptField] as? [String: Any] ?? [:]
                        let oxygen = (data[kind.oxygenField] as? NSNumber)?.intValue ?? 0
                        let gems = (data[kind.gemsField] as? NSNumber)?.intValue ?? 0
                        let tickets = (data[kind.ticketsField] as? NSNumber)?.intValue ?? 0
                        let covered = data[kind.weekDaysField] as? [String: Any] ?? [:]
                        let overlaps = isWeekly && dayIds.contains { covered[$0] != nil }
                        guard receipts[key] == nil, !overlaps else {
                            return ["credited": 0, "oxygen": oxygen, "gems": gems, "tickets": tickets]
                        }
                        var updates: [String: Any] = [
                            "\(receiptField).\(key)": FieldValue.serverTimestamp(),
                            "money.oxygen": FieldValue.increment(Int64(grantOxygen)),
                            "money.gemstone": FieldValue.increment(Int64(grantGems)),
                            "money.ticket": FieldValue.increment(Int64(grantTickets)),
                            kind.oxygenField: FieldValue.increment(Int64(grantOxygen)),
                            kind.gemsField: FieldValue.increment(Int64(grantGems)),
                            kind.ticketsField: FieldValue.increment(Int64(grantTickets))
                        ]
                        if isWeekly {
                            for dayId in dayIds { updates["\(kind.weekDaysField).\(dayId)"] = true }
                        }
                        transaction.updateData(updates, forDocument: target)
                        return ["credited": 1, "oxygen": oxygen + grantOxygen,
                                "gems": gems + grantGems, "tickets": tickets + grantTickets]
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }
                guard let outcome = result as? [String: Int] else {
                    throw EventReward.failure("Chưa nhận được phần thưởng. Hãy thử lại.".tr)
                }
                return outcome
            }
            // Retain taps/edits made while waiting, then persist them after crediting locally.
            if var latest = gradenModel, latest.user.userID == uid {
                switch kind {
                case .sleep:
                    let oxygen = outcome["oxygen"] ?? latest.sleepRewardOxygen
                    let gems = outcome["gems"] ?? latest.sleepRewardGems
                    let tickets = outcome["tickets"] ?? latest.sleepRewardTickets
                    let oxygenDelta = max(0, oxygen - latest.sleepRewardOxygen)
                    latest.money.oxygen += oxygenDelta
                    recordEventOxygen(oxygenDelta)
                    latest.money.gemstone += max(0, gems - latest.sleepRewardGems)
                    latest.money.ticket += max(0, tickets - latest.sleepRewardTickets)
                    latest.sleepRewardOxygen = max(latest.sleepRewardOxygen, oxygen)
                    latest.sleepRewardGems = max(latest.sleepRewardGems, gems)
                    latest.sleepRewardTickets = max(latest.sleepRewardTickets, tickets)
                case .steps:
                    let oxygen = outcome["oxygen"] ?? latest.stepsRewardOxygen
                    let gems = outcome["gems"] ?? latest.stepsRewardGems
                    let tickets = outcome["tickets"] ?? latest.stepsRewardTickets
                    let oxygenDelta = max(0, oxygen - latest.stepsRewardOxygen)
                    latest.money.oxygen += oxygenDelta
                    recordEventOxygen(oxygenDelta)
                    latest.money.gemstone += max(0, gems - latest.stepsRewardGems)
                    latest.money.ticket += max(0, tickets - latest.stepsRewardTickets)
                    latest.stepsRewardOxygen = max(latest.stepsRewardOxygen, oxygen)
                    latest.stepsRewardGems = max(latest.stepsRewardGems, gems)
                    latest.stepsRewardTickets = max(latest.stepsRewardTickets, tickets)
                }
                gradenModel = latest
                pendingGardenModel = latest
            }
            return outcome["credited"] == 1
        } catch {
            if gradenModel?.user.userID == uid { pendingGardenModel = gradenModel }
            throw EventReward.failure("Chưa nhận được phần thưởng. Hãy kiểm tra mạng và thử lại.".tr)
        }
    }

    /// Event pages wait for persistence before acknowledging the JS callback.
    @MainActor
    func saveEventReward(gardenModel: GardenModel) async -> Bool {
        guard !isClaimingHealthReward else { return false }
        debounceTask?.cancel()
        debounceTask = nil
        let previousPending = pendingGardenModel
        pendingGardenModel = gardenModel // Ignore realtime snapshots during this write.
        let saved = await performFirestoreUpdate(gardenModel: gardenModel) != nil
        pendingGardenModel = previousPending
        if saved {
            pendingGardenModel = nil
            gradenModel = gardenModel
        } else if previousPending != nil {
            flushPendingUpdates()
        }
        return saved
    }

    /// Lưu ngay lập tức các thay đổi đang chờ debounce (khi app chuẩn bị vào background hoặc thoát)
    func flushPendingUpdates() {
        guard !isClaimingHealthReward else { return }
        debounceTask?.cancel()
        debounceTask = nil
        guard let model = pendingGardenModel else { return }
        pendingGardenModel = nil
        Task.detached(priority: .background) { [weak self] in
            await self?.performFirestoreUpdate(gardenModel: model)
        }
    }

    /// Ghi dữ liệu lên Firestore ở background thread hoàn toàn bất đồng bộ, không block UI
    @discardableResult
    func performFirestoreUpdate(gardenModel: GardenModel) async -> GardenModel? {
        let userId = gardenModel.user.userID
        guard !userId.isEmpty else {
            print("❌ Lỗi: UserID rỗng")
            return nil
        }

        // Chuyển đổi model sang Dictionary trên background thread để tránh chiếm dụng Main Thread
        var updateData = await Task.detached(priority: .utility) {
            return gardenModel.toDictionary()
        }.value
        // Likes are changed independently by visitors. An older owner snapshot
        // must never overwrite them while saving plants, inventory or currency.
        if var profile = updateData["user"] as? [String: Any] {
            profile.removeValue(forKey: "userTotalLike")
            updateData["user"] = profile
        }

        do {
            let docRef = db.collection("users").document(userId)
            // Protect sleep credits from garden snapshots created before the reward transaction.
            let payload = updateData
            let removedIds = await MainActor.run { self.locallyRemovedPestIds }
            try await GardenWriteQueue.shared.perform {
                _ = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(docRef)
                        let remoteData = snapshot.data()
                        // Protect health reward credits from garden snapshots created before the reward transaction.
                        let remoteCredit = (remoteData?["sleepRewardOxygen"] as? NSNumber)?.intValue ?? 0
                        let remoteGems = (remoteData?["sleepRewardGems"] as? NSNumber)?.intValue ?? 0
                        let remoteTickets = (remoteData?["sleepRewardTickets"] as? NSNumber)?.intValue ?? 0
                        let remoteStepsOxygen = (remoteData?["stepsRewardOxygen"] as? NSNumber)?.intValue ?? 0
                        let remoteStepsGems = (remoteData?["stepsRewardGems"] as? NSNumber)?.intValue ?? 0
                        let remoteStepsTickets = (remoteData?["stepsRewardTickets"] as? NSNumber)?.intValue ?? 0
                        var protectedPayload = payload
                        if var money = protectedPayload["money"] as? [String: Any] {
                            // A delayed snapshot must not erase a reward credited since it was created.
                            money["oxygen"] = gardenModel.money.oxygen
                                + max(0, remoteCredit - gardenModel.sleepRewardOxygen)
                                + max(0, remoteStepsOxygen - gardenModel.stepsRewardOxygen)
                            money["gemstone"] = gardenModel.money.gemstone
                                + max(0, remoteGems - gardenModel.sleepRewardGems)
                                + max(0, remoteStepsGems - gardenModel.stepsRewardGems)
                            money["ticket"] = gardenModel.money.ticket
                                + max(0, remoteTickets - gardenModel.sleepRewardTickets)
                                + max(0, remoteStepsTickets - gardenModel.stepsRewardTickets)
                            protectedPayload["money"] = money
                        }

                        // Preserve remote visitor-dropped pests that arrived concurrently and were not removed locally.
                        let remotePests = (remoteData?["pests"] as? [[String: Any]] ?? []).compactMap { GardenPest(dict: $0) }
                        var mergedPests = gardenModel.pests
                        var seenPestIds = Set(mergedPests.map(\.id))
                        for remotePest in remotePests where remotePest.source == .visitor {
                            if !seenPestIds.contains(remotePest.id) && !removedIds.contains(remotePest.id) {
                                mergedPests.append(remotePest)
                                seenPestIds.insert(remotePest.id)
                            }
                        }
                        protectedPayload["pests"] = mergedPests.map { $0.toDictionary() }

                        transaction.setData(protectedPayload, forDocument: docRef, merge: true)
                        return nil
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }
            }
            await MainActor.run {
                self.locallyRemovedPestIds.subtract(removedIds)
            }
            print("✅ Update Firestore thành công cho user: \(gardenModel.user.userName)")
            let eventOxygenDelta = consumePendingEventOxygen()
            if eventOxygenDelta > 0 {
                try? await db.collection("user-event").document(userId).setData([
                    "userId": userId,
                    "oxygenCollected": FieldValue.increment(Int64(eventOxygenDelta))
                ], merge: true)
            }
            return gardenModel
        } catch {
            print("❌ Lỗi khi update Firestore: \(error.localizedDescription)")
            return nil
        }
    }

    /// Update dữ liệu user lên Firestore (hỗ trợ async gọi từ các ViewModel / caller cũ)
    @discardableResult
    func updateDataUser(gardenModel: GardenModel?) async -> GardenModel? {
        guard let gardenModel = gardenModel else {
            print("❌ Lỗi: Không tìm thấy thông tin tài khoản")
            return nil
        }

        await MainActor.run {
            self.debounceTask?.cancel()
            self.debounceTask = nil
            self.pendingGardenModel = nil
            self.gradenModel = gardenModel
        }

        return await performFirestoreUpdate(gardenModel: gardenModel)
    }

    /// Cập nhật đường dẫn ảnh đại diện của user lên Firestore và đồng bộ state cục bộ
    @MainActor
    func updateUserAvatar(_ avatarURL: String) async throws {
        guard let uid = auth.currentUser?.uid ?? gradenModel?.user.userID, !uid.isEmpty else {
            throw NSError(
                domain: "FireStoreService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy tài khoản để cập nhật ảnh đại diện.".tr]
            )
        }

        let docRef = db.collection("users").document(uid)
        try await GardenWriteQueue.shared.perform {
            try await docRef.updateData(["user.userAvatar": avatarURL])
        }

        if var garden = gradenModel, garden.user.userID == uid {
            garden.user.userAvatar = avatarURL
            gradenModel = garden
        }
        if var pending = pendingGardenModel, pending.user.userID == uid {
            pending.user.userAvatar = avatarURL
            pendingGardenModel = pending
        }
    }

    // MARK: - VIP Subscription Sync

    func isVIPTransactionOwnedByAnotherUser(originalTransactionId: String, currentUID: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("vip.originalTransactionId", isEqualTo: originalTransactionId)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.contains { $0.documentID != currentUID }
    }

    @MainActor
    func syncVIPStatus(
        isActive: Bool,
        productId: String?,
        expiresAt: TimeInterval,
        willAutoRenew: Bool,
        source: String,
        originalTransactionId: String? = nil
    ) async {
        guard let uid = auth.currentUser?.uid, !uid.isEmpty else { return }
        let docRef = db.collection("users").document(uid)
        let now = Date().timeIntervalSince1970

        do {
            let outcome = try await GardenWriteQueue.shared.perform {
                let result = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(docRef)
                        let data = snapshot.data() ?? [:]
                        let existingVIP = data["vip"] as? [String: Any] ?? [:]
                        let alreadyClaimedWelcome = (existingVIP["welcomeBonusClaimed"] as? Bool)
                            ?? ((existingVIP["welcomeBonusClaimed"] as? NSNumber)?.boolValue ?? false)
                        let grantWelcome = isActive && !alreadyClaimedWelcome

                        let vipPayload: [String: Any] = [
                            "isActive": isActive,
                            "productId": productId ?? NSNull(),
                            "expiresAt": expiresAt,
                            "willAutoRenew": willAutoRenew,
                            "welcomeBonusClaimed": alreadyClaimedWelcome || grantWelcome,
                            "source": source,
                            "originalTransactionId": originalTransactionId ?? existingVIP["originalTransactionId"] ?? NSNull(),
                            "updatedAt": now,
                        ]

                        var updates: [String: Any] = ["vip": vipPayload]
                        if grantWelcome {
                            updates["money.gemstone"] = FieldValue.increment(Int64(VIPWelcomeBonus.gemstone))
                            updates["money.ticket"] = FieldValue.increment(Int64(VIPWelcomeBonus.ticket))
                            updates["item.fertilizer"] = FieldValue.increment(Int64(VIPWelcomeBonus.fertilizer))
                            updates["item.shovel"] = FieldValue.increment(Int64(VIPWelcomeBonus.shovel))
                        }

                        if snapshot.exists {
                            transaction.updateData(updates, forDocument: docRef)
                        } else {
                            transaction.setData(["vip": vipPayload], forDocument: docRef, merge: true)
                        }

                        return [
                            "grantedWelcome": grantWelcome,
                            "welcomeBonusClaimed": alreadyClaimedWelcome || grantWelcome
                        ]
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }
                return result as? [String: Bool] ?? [:]
            }

            if var garden = self.gradenModel, garden.user.userID == uid {
                let grantedWelcome = outcome["grantedWelcome"] ?? false
                let claimed = outcome["welcomeBonusClaimed"] ?? garden.vipStatus.welcomeBonusClaimed
                garden.vipStatus = GardenModel.VIPStatus(
                    isActive: isActive,
                    productId: productId,
                    expiresAt: expiresAt,
                    willAutoRenew: willAutoRenew,
                    welcomeBonusClaimed: claimed,
                    source: source,
                    originalTransactionId: originalTransactionId ?? garden.vipStatus.originalTransactionId,
                    updatedAt: now
                )
                if grantedWelcome {
                    garden.money.gemstone += VIPWelcomeBonus.gemstone
                    garden.money.ticket += VIPWelcomeBonus.ticket
                    garden.item.fertilizer += VIPWelcomeBonus.fertilizer
                    garden.item.shovel += VIPWelcomeBonus.shovel
                }
                self.gradenModel = garden
            }
        } catch {
            print("❌ VIP sync error: \(error.localizedDescription)")
        }
    }

    /// Credits purchased consumable gemstones atomically and idempotently by StoreKit transaction ID.
    @MainActor
    func creditPurchasedGems(
        amount: Int,
        transactionId: String,
        productId: String
    ) async throws -> Bool {
        guard amount > 0, !transactionId.isEmpty else { return false }
        guard let uid = auth.currentUser?.uid, !uid.isEmpty else {
            throw NSError(
                domain: "GemStore",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Chưa đăng nhập tài khoản".tr]
            )
        }

        let docRef = db.collection("users").document(uid)
        let now = Date().timeIntervalSince1970

        let credited = try await GardenWriteQueue.shared.perform {
            let result = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(docRef)
                    let data = snapshot.data() ?? [:]
                    let receipts = data["gemPurchases"] as? [String: Any] ?? [:]
                    if receipts[transactionId] != nil {
                        return false
                    }

                    let receiptPayload: [String: Any] = [
                        "amount": amount,
                        "productId": productId,
                        "purchasedAt": now,
                    ]

                    if snapshot.exists {
                        transaction.updateData([
                            "gemPurchases.\(transactionId)": receiptPayload,
                            "money.gemstone": FieldValue.increment(Int64(amount)),
                        ], forDocument: docRef)
                    } else {
                        transaction.setData([
                            "gemPurchases": [transactionId: receiptPayload],
                            "money": ["gemstone": amount],
                        ], forDocument: docRef, merge: true)
                    }

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            return result as? Bool ?? false
        }

        if credited {
            if var garden = self.gradenModel, garden.user.userID == uid {
                garden.money.gemstone += amount
                self.gradenModel = garden
            }
            if var pending = self.pendingGardenModel, pending.user.userID == uid {
                pending.money.gemstone += amount
                self.pendingGardenModel = pending
            }
        }

        return credited
    }

    // MARK: - Pest & Bugsnet Management

    enum VisitorPestDropError: LocalizedError {
        case signInRequired
        case ownGarden
        case dailyLimitReached
        case noPlantsAvailable
        case allPlantsInfested
        case unavailable

        var errorDescription: String? {
            switch self {
            case .signInRequired:
                return "Vui lòng đăng nhập để thả sâu.".tr
            case .ownGarden:
                return "Bạn không thể thả sâu vào khu vườn của chính mình.".tr
            case .dailyLimitReached:
                return "Bạn đã thả tối đa 10 con sâu hôm nay. Hãy quay lại vào ngày mai nhé!".tr
            case .noPlantsAvailable:
                return "Khu vườn này chưa có cây để thả sâu.".tr
            case .allPlantsInfested:
                return "Tất cả cây trong khu vườn này đã có sâu bám rồi!".tr
            case .unavailable:
                return "Không thể thả sâu vào khu vườn này lúc này.".tr
            }
        }
    }

    @MainActor
    func markAllPestsRemovedLocally(_ pestIds: [String]) {
        locallyRemovedPestIds.formUnion(pestIds)
    }

    /// Tap tiêu diệt hoặc bắt sâu vào túi `Bugsnet` (nhận 300 oxygen/con).
    @MainActor
    func resolvePestTap(pestId: String) -> (caughtInBag: Bool, oxygenGained: Int, pest: GardenPest)? {
        guard var garden = self.gradenModel,
              let index = garden.pests.firstIndex(where: { $0.id == pestId }) else {
            return nil
        }

        let removed = garden.pests.remove(at: index)
        locallyRemovedPestIds.insert(removed.id)

        let reward = GardenModel.pestKillOxygenReward
        garden.money.oxygen += reward
        recordEventOxygen(reward)

        let caughtInBag: Bool
        if garden.hasBugsNet && garden.capturedPests.count < GardenModel.maxBagCapacity {
            garden.capturedPests.append(removed.kind)
            caughtInBag = true
        } else {
            caughtInBag = false
        }

        saveGarden(gardenModel: garden, debounce: false)
        return (caughtInBag, reward, removed)
    }

    /// Tự động sản sinh sâu/châu chấu khi có `Bugsnet` (`animal3`), có giới hạn tần suất và số lượng để tránh spam.
    @MainActor
    @discardableResult
    func spawnAutoPestIfNeeded(now: TimeInterval = Date().timeIntervalSince1970) -> GardenPest? {
        guard var garden = self.gradenModel,
              garden.hasBugsNet,
              garden.weatherUntil <= now || garden.weatherKind != .spray else {
            return nil
        }

        // Tránh spam: tôn trọng thời gian hồi và giới hạn tối đa sâu tự sinh đang bám trên vườn
        guard now - garden.lastAutoPestSpawnAt >= GardenModel.autoPestSpawnCooldown else {
            return nil
        }

        let activeAutoCount = garden.pests.filter { $0.source == .auto }.count
        guard activeAutoCount < GardenModel.maxActiveAutoPests else {
            return nil
        }

        let occupiedPositions = Set(garden.pests.map(\.position))
        let candidatePlants = garden.weatherPlants.filter { !occupiedPositions.contains($0.position) }
        guard let chosenPlant = candidatePlants.randomElement() else {
            return nil
        }

        // Xác suất vừa phải (40%) mỗi chu kỳ để tự nhiên, không bị dồn dập
        guard Double.random(in: 0...1) <= 0.40 else {
            garden.lastAutoPestSpawnAt = now - (GardenModel.autoPestSpawnCooldown * 0.5)
            saveGarden(gardenModel: garden, debounce: true)
            return nil
        }

        let species = PestSpecies.allCases.randomElement() ?? .bug1
        let newPest = GardenPest(
            kind: species,
            position: chosenPlant.position,
            plantId: chosenPlant.idPlant,
            source: .auto,
            createdAt: now
        )
        garden.pests.append(newPest)
        garden.lastAutoPestSpawnAt = now
        saveGarden(gardenModel: garden, debounce: false)
        return newPest
    }

    /// Xóa danh sách thông báo bị thả sâu sau khi người dùng đã xem khi đăng nhập.
    @MainActor
    func clearPestNotifications() {
        guard var garden = self.gradenModel, !garden.pestNotifications.isEmpty else { return }
        let uid = garden.user.userID
        garden.pestNotifications.removeAll()
        self.gradenModel = garden
        if var pending = self.pendingGardenModel {
            pending.pestNotifications.removeAll()
            self.pendingGardenModel = pending
        }
        guard !uid.isEmpty else { return }
        db.collection("users").document(uid).updateData(["pestNotifications": []])
    }

    /// Thả sâu vào vườn nhà người khác (tối đa 10 con/ngày, bám ngẫu nhiên vào 1 cây, nhận +350 oxygen/con).
    @MainActor
    func dropPestInVisitorGarden(
        targetGardenId: String,
        targetSlots: [VisitorGarden.Slot],
        existingTargetPests: [GardenPest]
    ) async throws -> (pest: GardenPest, oxygenReward: Int) {
        guard let senderId = auth.currentUser?.uid,
              var senderGarden = self.gradenModel else {
            throw VisitorPestDropError.signInRequired
        }
        guard senderId != targetGardenId else {
            throw VisitorPestDropError.ownGarden
        }
        guard senderGarden.remainingVisitorPestDrops() > 0 else {
            throw VisitorPestDropError.dailyLimitReached
        }

        let plantSlots = targetSlots.filter { !$0.isSticker && !$0.isAnimal && !$0.plantID.isEmpty && !$0.potID.isEmpty }
        guard !plantSlots.isEmpty else {
            throw VisitorPestDropError.noPlantsAvailable
        }

        // Lấy loài sâu từ túi Bugsnet nếu đang có sẵn (giải phóng chỗ trong túi), ngược lại chọn ngẫu nhiên
        let speciesToSend: PestSpecies = senderGarden.capturedPests.first ?? (PestSpecies.allCases.randomElement() ?? .bug1)
        let senderName = senderGarden.user.userName.isEmpty ? "Người chơi khác".tr : senderGarden.user.userName
        let now = Date().timeIntervalSince1970

        let targetRef = db.collection("users").document(targetGardenId)
        let createdPest: GardenPest = try await GardenWriteQueue.shared.perform {
            let result = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(targetRef)
                    guard let data = snapshot.data() else {
                        throw VisitorPestDropError.unavailable
                    }
                    let banned = (data["isBan"] as? NSNumber)?.boolValue == true
                        || ["true", "1"].contains(data["isBan"] as? String ?? "")
                    guard !banned else { throw VisitorPestDropError.unavailable }

                    var remotePests = (data["pests"] as? [[String: Any]] ?? []).compactMap { GardenPest(dict: $0) }
                    let occupied = Set(remotePests.map(\.position))
                    let available = plantSlots.filter { !occupied.contains($0.id) }
                    guard let chosenSlot = available.randomElement() else {
                        throw VisitorPestDropError.allPlantsInfested
                    }

                    let newPest = GardenPest(
                        kind: speciesToSend,
                        position: chosenSlot.id,
                        plantId: chosenSlot.plantID,
                        source: .visitor,
                        senderId: senderId,
                        senderName: senderName,
                        createdAt: now
                    )
                    remotePests.append(newPest)

                    var remoteNotifs = (data["pestNotifications"] as? [[String: Any]] ?? []).compactMap { GardenPestNotification(dict: $0) }
                    remoteNotifs.append(GardenPestNotification(
                        senderId: senderId,
                        senderName: senderName,
                        kind: speciesToSend,
                        position: chosenSlot.id,
                        createdAt: now
                    ))
                    if remoteNotifs.count > 25 {
                        remoteNotifs = Array(remoteNotifs.suffix(25))
                    }

                    transaction.updateData([
                        "pests": remotePests.map { $0.toDictionary() },
                        "pestNotifications": remoteNotifs.map { $0.toDictionary() }
                    ], forDocument: targetRef)

                    return newPest.toDictionary()
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            guard let dict = result as? [String: Any], let parsed = GardenPest(dict: dict) else {
                throw VisitorPestDropError.unavailable
            }
            return parsed
        }

        // Thưởng +350 oxygen, cập nhật giới hạn 10 con/ngày, và lấy 1 con ra khỏi túi nếu túi có sâu
        let today = GardenModel.todayDateKey()
        if senderGarden.pestDropDate != today {
            senderGarden.pestDropDate = today
            senderGarden.pestDropCount = 0
        }
        senderGarden.pestDropCount += 1
        if !senderGarden.capturedPests.isEmpty {
            senderGarden.capturedPests.removeFirst()
        }
        let reward = GardenModel.visitorDropOxygenReward
        senderGarden.money.oxygen += reward
        recordEventOxygen(reward)
        saveGarden(gardenModel: senderGarden, debounce: false)

        return (createdPest, reward)
    }
}


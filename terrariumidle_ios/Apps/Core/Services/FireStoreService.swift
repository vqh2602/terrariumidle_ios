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
    private var isClaimingSleepReward = false
    private let eventOxygenLock = NSLock()
    private var pendingEventOxygen: Int = 0

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
        _ = consumePendingEventOxygen()
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
                if document.metadata.hasPendingWrites || self.pendingGardenModel != nil || self.isClaimingSleepReward {
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
        let oxygenDrop = SubscriptionManager.isVIP(gardenModel: garden)
            ? Int((Double(baseOxygenDrop) * 1.5).rounded())
            : baseOxygenDrop

        // 1. Tăng oxy
        garden.money.oxygen += oxygenDrop
        recordEventOxygen(oxygenDrop)

        // 2. Tăng EXP cho cây
        plant.platLevelExp += 100
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
        garden.user.userLevelEXP += 100
        var didUserLevelUp = false
        let userMaxExp = ShareFunc.calculateUserMaxExp(level: garden.user.userLevel)
        if garden.user.userLevelEXP >= userMaxExp {
            garden.user.userLevel += 1
            garden.user.userLevelEXP -= userMaxExp
            didUserLevelUp = true
        }

        // Cập nhật model và debounce lưu Firestore
        saveGarden(gardenModel: garden, debounce: true)

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
        guard !isClaimingSleepReward else { return }

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

    /// The receipt and currency credit commit together. No sleep samples leave the device.
    @MainActor
    func claimSleepReward(grant: SleepRewardGrant, goal: Double) async throws -> Bool {
        guard !isClaimingSleepReward,
              SleepRewardRules.isValid(grant, goal: goal),
              let garden = gradenModel,
              Auth.auth().currentUser?.uid == garden.user.userID else {
            throw EventReward.failure("Chưa thể nhận phần thưởng lúc này.".tr)
        }
        let uid = garden.user.userID
        isClaimingSleepReward = true
        debounceTask?.cancel()
        debounceTask = nil
        pendingGardenModel = nil
        defer {
            isClaimingSleepReward = false
            flushPendingUpdates()
        }
        // Drain previously queued garden writes and persist the current local balance first.
        guard await performFirestoreUpdate(gardenModel: garden) != nil else {
            pendingGardenModel = gradenModel
            throw EventReward.failure("Chưa lưu được khu vườn. Hãy kiểm tra mạng và thử lại.".tr)
        }
        let target = db.collection("users").document(uid)
        let key = grant.id
        do {
            let outcome: [String: Int] = try await GardenWriteQueue.shared.perform {
                let result = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(target)
                        guard let data = snapshot.data() else {
                            throw EventReward.failure("Không tìm thấy khu vườn.".tr)
                        }
                        let receiptField = grant.kind == .daily ? "sleepRewardDays" : "sleepRewardMilestones"
                        let receipts = data[receiptField] as? [String: Any] ?? [:]
                        let oxygen = (data["sleepRewardOxygen"] as? NSNumber)?.intValue ?? 0
                        let gems = (data["sleepRewardGems"] as? NSNumber)?.intValue ?? 0
                        let tickets = (data["sleepRewardTickets"] as? NSNumber)?.intValue ?? 0
                        let covered = data["sleepRewardWeekDays"] as? [String: Any] ?? [:]
                        let overlaps = grant.kind == .weekly && grant.days.contains { covered[$0.id] != nil }
                        guard receipts[key] == nil, !overlaps else {
                            return ["credited": 0, "oxygen": oxygen, "gems": gems, "tickets": tickets]
                        }
                        var updates: [String: Any] = [
                            "\(receiptField).\(key)": FieldValue.serverTimestamp(),
                            "money.oxygen": FieldValue.increment(Int64(grant.oxygen)),
                            "money.gemstone": FieldValue.increment(Int64(grant.gems)),
                            "money.ticket": FieldValue.increment(Int64(grant.tickets)),
                            "sleepRewardOxygen": FieldValue.increment(Int64(grant.oxygen)),
                            "sleepRewardGems": FieldValue.increment(Int64(grant.gems)),
                            "sleepRewardTickets": FieldValue.increment(Int64(grant.tickets))
                        ]
                        if grant.kind == .weekly {
                            for day in grant.days { updates["sleepRewardWeekDays.\(day.id)"] = true }
                        }
                        transaction.updateData(updates, forDocument: target)
                        return ["credited": 1, "oxygen": oxygen + grant.oxygen,
                                "gems": gems + grant.gems, "tickets": tickets + grant.tickets]
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
        guard !isClaimingSleepReward else { return false }
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
        guard !isClaimingSleepReward else { return }
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
            try await GardenWriteQueue.shared.perform {
                _ = try await self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let snapshot = try transaction.getDocument(docRef)
                        let remoteCredit = (snapshot.data()?["sleepRewardOxygen"] as? NSNumber)?.intValue ?? 0
                        let remoteGems = (snapshot.data()?["sleepRewardGems"] as? NSNumber)?.intValue ?? 0
                        let remoteTickets = (snapshot.data()?["sleepRewardTickets"] as? NSNumber)?.intValue ?? 0
                        var protectedPayload = payload
                        if var money = protectedPayload["money"] as? [String: Any] {
                            // A delayed snapshot must not erase a reward credited since it was created.
                            money["oxygen"] = gardenModel.money.oxygen + max(0, remoteCredit - gardenModel.sleepRewardOxygen)
                            money["gemstone"] = gardenModel.money.gemstone + max(0, remoteGems - gardenModel.sleepRewardGems)
                            money["ticket"] = gardenModel.money.ticket + max(0, remoteTickets - gardenModel.sleepRewardTickets)
                            protectedPayload["money"] = money
                        }
                        transaction.setData(protectedPayload, forDocument: docRef, merge: true)
                        return nil
                    } catch {
                        errorPointer?.pointee = error as NSError
                        return nil
                    }
                }
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
}


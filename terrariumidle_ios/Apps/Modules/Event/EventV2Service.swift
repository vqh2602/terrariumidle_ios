import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

@MainActor
final class EventV2Service {
    static let shared = EventV2Service()

    private let db = Firestore.firestore()
    private let collectionName = "user-event"
    private let maxStoredReceipts = 15

    private struct RewardSpec {
        let id: String
        let quantity: Int

        init(_ id: String, quantity: Int = 1) {
            self.id = id
            self.quantity = max(1, quantity)
        }

        func toDictionary(milestone: Int? = nil) -> [String: Any] {
            var dict: [String: Any] = [
                "id": id,
                "quantity": quantity
            ]
            if let milestone {
                dict["milestone"] = milestone
            }
            return dict
        }
    }

    private struct EventSpec {
        let rewards: [RewardSpec]
        let milestones: [Int]?

        var rewardIds: [String] { rewards.map(\.id) }

        func toWebList() -> [[String: Any]] {
            rewards.enumerated().map { index, reward in
                let milestone = (milestones != nil && index < milestones!.count) ? milestones![index] : nil
                return reward.toDictionary(milestone: milestone)
            }
        }
    }

    private let specs: [String: EventSpec] = [
        "slot": EventSpec(
            rewards: [
                RewardSpec("plant30", quantity: 1),
                RewardSpec("pot30", quantity: 1),
                RewardSpec("oxygen", quantity: 5000)
            ],
            milestones: nil
        ),
        "match": EventSpec(
            rewards: [
                RewardSpec("plant11", quantity: 1),
                RewardSpec("pot11", quantity: 1),
                RewardSpec("fertilizer", quantity: 1),
                RewardSpec("oxygen", quantity: 3000)
            ],
            milestones: nil
        ),
        "oxygen": EventSpec(
            rewards: [
                RewardSpec("fertilizer", quantity: 1),
                RewardSpec("pot21", quantity: 1),
                RewardSpec("plant21", quantity: 1),
                RewardSpec("gemstone", quantity: 500)
            ],
            milestones: [10000, 50000, 100000, 500000]
        ),
        "level": EventSpec(
            rewards: [
                RewardSpec("oxygen", quantity: 3000),
                RewardSpec("pot20", quantity: 1),
                RewardSpec("plant20", quantity: 1)
            ],
            milestones: [5, 15, 50]
        ),
        "daily": EventSpec(
            rewards: [
                RewardSpec("oxygen", quantity: 300),
                RewardSpec("fertilizer", quantity: 1),
                RewardSpec("oxygen", quantity: 300),
                RewardSpec("pot8", quantity: 1),
                RewardSpec("oxygen", quantity: 300),
                RewardSpec("fertilizer", quantity: 1),
                RewardSpec("plant8", quantity: 1)
            ],
            milestones: nil
        ),
        "monthly": EventSpec(
            rewards: [
                RewardSpec("oxygen", quantity: 300),
                RewardSpec("fertilizer", quantity: 1),
                RewardSpec("shovel", quantity: 1),
                RewardSpec("gemstone", quantity: 10),
                RewardSpec("ticket", quantity: 1)
            ],
            milestones: nil
        ),
        "harvest": EventSpec(
            rewards: [
                RewardSpec("sticker3", quantity: 1),
                RewardSpec("gemstone", quantity: 50),
                RewardSpec("oxygen", quantity: 5000)
            ],
            milestones: nil
        )
    ]

    private struct HarvestRequirement {
        let plantId: String
        let required: Int
    }

    private let harvestRequirements: [HarvestRequirement] = [
        HarvestRequirement(plantId: "plant10", required: 3),
        HarvestRequirement(plantId: "plant2", required: 2),
        HarvestRequirement(plantId: "plant5", required: 2)
    ]

    private init() {}

    func handle(action: String, payload: [String: Any], expectedEventId: String) async throws -> Any {
        let eventId = (payload["eventId"] as? String) ?? expectedEventId
        guard eventId == expectedEventId, specs[eventId] != nil else {
            throw EventReward.failure("Sự kiện không hợp lệ.".tr)
        }

        if action == "resolveAssets" {
            let itemIds = payload["itemIds"] as? [String] ?? []
            return resolveAssets(itemIds: itemIds)
        }

        guard let uid = AuthService.shared.currentUser?.uid,
              let garden = FireStoreService.shared.gradenModel,
              garden.user.userID == uid else {
            throw EventReward.failure("Vui lòng đăng nhập lại".tr)
        }

        let requestId = payload["requestId"] as? String

        switch action {
        case "getContext":
            return try await runDocumentTransaction(uid: uid, level: garden.user.userLevel, requestId: nil) { _ in }

        case "spin":
            guard eventId == "slot" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            return try await runDocumentTransaction(uid: uid, level: garden.user.userLevel, requestId: requestId) { state in
                let spins = (state["spins"] as? NSNumber)?.intValue ?? 0
                guard spins > 0 else {
                    throw EventReward.failure("Bạn đã dùng hết lượt hôm nay.".tr)
                }
                let nextSpins = spins - 1
                state["spins"] = nextSpins
                let seq = ((state["spinSeq"] as? NSNumber)?.intValue ?? 0) + 1
                state["spinSeq"] = seq

                let pool = self.specs["slot"]!.rewardIds
                let symbols = (0..<3).map { _ in pool.randomElement()! }
                let wonId: String? = (symbols[0] == symbols[1] && symbols[1] == symbols[2]) ? symbols[0] : nil
                if let wonId,
                   let wonSpec = self.specs["slot"]!.rewards.first(where: { $0.id == wonId }) {
                    var pending = state["pending"] as? [[String: Any]] ?? []
                    pending.append([
                        "id": "spin-\(seq)",
                        "rewardId": wonSpec.id,
                        "quantity": wonSpec.quantity,
                        "eventId": "slot"
                    ])
                    state["pending"] = pending
                }
                state["lastSpin"] = [
                    "symbols": symbols,
                    "rewardId": (wonId as Any?) ?? NSNull()
                ]
            }

        case "startRound":
            guard eventId == "match" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            return try await runDocumentTransaction(uid: uid, level: garden.user.userLevel, requestId: requestId) { state in
                let available = state["matchAvailable"] as? Bool ?? false
                guard available else {
                    throw EventReward.failure("Bạn đã dùng lượt chơi hôm nay.".tr)
                }
                state["matchAvailable"] = false
                let rounds = ((state["rounds"] as? NSNumber)?.intValue ?? 0) + 1
                state["rounds"] = rounds

                let rewardIds = self.specs["match"]!.rewardIds
                var board = rewardIds + rewardIds + [""]
                board.shuffle()

                state["round"] = [
                    "id": "round-\(rounds)",
                    "board": board,
                    "open": [Int](),
                    "revealed": [String: Any](),
                    "attempts": 3,
                    "ended": false
                ]
            }

        case "revealTile":
            guard eventId == "match" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            let roundId = payload["roundId"] as? String ?? ""
            guard let index = (payload["index"] as? NSNumber)?.intValue else {
                throw EventReward.failure("Ô hoặc lượt chơi không hợp lệ.".tr)
            }
            return try await runDocumentTransaction(uid: uid, level: garden.user.userLevel, requestId: requestId) { state in
                guard var round = state["round"] as? [String: Any],
                      let currentId = round["id"] as? String, currentId == roundId,
                      !(round["ended"] as? Bool ?? true),
                      let board = round["board"] as? [String], board.count == 9,
                      (0..<9).contains(index) else {
                    throw EventReward.failure("Ô hoặc lượt chơi không hợp lệ.".tr)
                }

                var open = (round["open"] as? [NSNumber])?.map(\.intValue) ?? (round["open"] as? [Int] ?? [])
                guard !open.contains(index) else {
                    throw EventReward.failure("Ô hoặc lượt chơi không hợp lệ.".tr)
                }

                var revealed = round["revealed"] as? [String: Any] ?? [:]
                if open.count == 2 {
                    open = []
                    revealed = [:]
                }

                open.append(index)
                let tileValue = board[index]
                revealed[String(index)] = tileValue.isEmpty ? NSNull() : tileValue

                var attempts = (round["attempts"] as? NSNumber)?.intValue ?? 0
                var ended = false
                if open.count == 2 {
                    attempts = max(0, attempts - 1)
                    let first = board[open[0]]
                    let second = board[open[1]]
                    if !first.isEmpty && first == second {
                        ended = true
                        let matchedQty = self.specs["match"]!.rewards.first(where: { $0.id == first })?.quantity ?? 1
                        var pending = state["pending"] as? [[String: Any]] ?? []
                        pending.append([
                            "id": currentId,
                            "rewardId": first,
                            "quantity": matchedQty,
                            "eventId": "match"
                        ])
                        state["pending"] = pending
                    }
                    if attempts == 0 {
                        ended = true
                    }
                }

                round["open"] = open
                round["revealed"] = revealed
                round["attempts"] = attempts
                round["ended"] = ended
                state["round"] = round
            }

        case "claimReward":
            if eventId == "harvest" {
                return try await handleHarvestClaimReward(uid: uid, garden: garden, requestId: requestId)
            }
            return try await handleClaimReward(uid: uid, eventId: eventId, payload: payload, garden: garden, requestId: requestId)

        case "harvestPlant":
            guard eventId == "harvest" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            return try await handleHarvestPlant(uid: uid, payload: payload, garden: garden, requestId: requestId)

        case "checkIn":
            guard eventId == "daily" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            return try await handleCheckIn(uid: uid, garden: garden, requestId: requestId)

        case "monthlyCheckIn":
            guard eventId == "monthly" else { throw EventReward.failure("Sự kiện không hợp lệ.".tr) }
            return try await handleMonthlyCheckIn(uid: uid, garden: garden, requestId: requestId)

        default:
            throw EventReward.failure("Lệnh chưa hỗ trợ.".tr)
        }
    }

    // MARK: - Claim & Check-in (syncs GardenModel + user-event)

    private func handleClaimReward(uid: String, eventId: String, payload: [String: Any], garden: GardenModel, requestId: String?) async throws -> [String: Any] {
        // 1. Check receipt or validate claim precondition
        let preState = try await fetchOrInitState(uid: uid, level: garden.user.userLevel)
        if let requestId, let receipts = preState["receipts"] as? [String: Any], let cached = receipts[requestId] as? [String: Any] {
            return cached
        }

        let spec = specs[eventId]!
        let claims = preState["claims"] as? [String] ?? []

        let rewardIdToGrant: String
        let quantityToGrant: Int?
        let claimKey: String
        var pendingIdToRemove: String?

        if let milestones = spec.milestones {
            guard let milestone = (payload["milestone"] as? NSNumber)?.intValue,
                  let idx = milestones.firstIndex(of: milestone),
                  idx < spec.rewards.count else {
                throw EventReward.failure("Chưa đạt mốc.".tr)
            }
            let progress = eventId == "oxygen"
                ? ((preState["oxygenCollected"] as? NSNumber)?.intValue ?? 0)
                : garden.user.userLevel
            guard progress >= milestone else {
                throw EventReward.failure("Chưa đạt mốc.".tr)
            }
            claimKey = "\(eventId)-\(milestone)"
            guard !claims.contains(claimKey) else {
                throw EventReward.failure("Quà đã nhận.".tr)
            }
            let targetReward = spec.rewards[idx]
            rewardIdToGrant = targetReward.id
            quantityToGrant = targetReward.quantity
        } else {
            let pendingId = payload["rewardId"] as? String ?? ""
            let pending = preState["pending"] as? [[String: Any]] ?? []
            guard let match = pending.first(where: { ($0["id"] as? String) == pendingId && ($0["eventId"] as? String) == eventId }),
                  let actualRewardId = match["rewardId"] as? String else {
                throw EventReward.failure("Không tìm thấy quà.".tr)
            }
            claimKey = "\(eventId)-\(pendingId)"
            guard !claims.contains(claimKey) else {
                throw EventReward.failure("Quà đã nhận.".tr)
            }
            rewardIdToGrant = actualRewardId
            quantityToGrant = (match["quantity"] as? NSNumber)?.intValue
                ?? spec.rewards.first(where: { $0.id == actualRewardId })?.quantity
            pendingIdToRemove = pendingId
        }

        // 2. Apply to GardenModel and persist to users/{uid} first
        let (updatedGarden, qty) = try EventReward.applyV2Reward(
            rewardId: rewardIdToGrant,
            quantityOverride: quantityToGrant,
            to: garden
        )
        let saved = await FireStoreService.shared.saveEventReward(gardenModel: updatedGarden)
        guard saved else {
            throw EventReward.failure("Chưa lưu được phần thưởng. Vui lòng kiểm tra kết nối rồi thử lại.".tr)
        }

        // 3. Commit claim + wallet + receipt to user-event/{uid}
        return try await runDocumentTransaction(uid: uid, level: updatedGarden.user.userLevel, requestId: requestId) { state in
            var currentClaims = state["claims"] as? [String] ?? []
            guard !currentClaims.contains(claimKey) else {
                throw EventReward.failure("Quà đã nhận.".tr)
            }
            currentClaims.append(claimKey)
            state["claims"] = currentClaims

            if let pendingIdToRemove {
                var pending = state["pending"] as? [[String: Any]] ?? []
                pending.removeAll { ($0["id"] as? String) == pendingIdToRemove && ($0["eventId"] as? String) == eventId }
                state["pending"] = pending
            }

            var wallet = state["wallet"] as? [[String: Any]] ?? []
            wallet.append([
                "id": rewardIdToGrant,
                "name": self.displayName(for: rewardIdToGrant),
                "quantity": qty
            ])
            state["wallet"] = wallet
        }
    }

    private func handleCheckIn(uid: String, garden: GardenModel, requestId: String?) async throws -> [String: Any] {
        let preState = try await fetchOrInitState(uid: uid, level: garden.user.userLevel)
        if let requestId, let receipts = preState["receipts"] as? [String: Any], let cached = receipts[requestId] as? [String: Any] {
            return cached
        }

        let checkedToday = preState["checkedToday"] as? Bool ?? false
        let day = (preState["day"] as? NSNumber)?.intValue ?? 0
        guard !checkedToday, day < 7 else {
            throw EventReward.failure("Bạn đã điểm danh hôm nay hoặc hoàn thành chuỗi.".tr)
        }

        let dailyRewards = specs["daily"]!.rewards
        let rewardSpec = dailyRewards[day]
        let rewardId = rewardSpec.id
        let claimKey = "daily-\(day)"

        let (updatedGarden, qty) = try EventReward.applyV2Reward(
            rewardId: rewardId,
            quantityOverride: rewardSpec.quantity,
            to: garden
        )
        let saved = await FireStoreService.shared.saveEventReward(gardenModel: updatedGarden)
        guard saved else {
            throw EventReward.failure("Chưa lưu được phần thưởng. Vui lòng kiểm tra kết nối rồi thử lại.".tr)
        }

        return try await runDocumentTransaction(uid: uid, level: updatedGarden.user.userLevel, requestId: requestId) { state in
            let isChecked = state["checkedToday"] as? Bool ?? false
            let currentDay = (state["day"] as? NSNumber)?.intValue ?? 0
            guard !isChecked, currentDay < 7 else {
                throw EventReward.failure("Bạn đã điểm danh hôm nay hoặc hoàn thành chuỗi.".tr)
            }

            var currentClaims = state["claims"] as? [String] ?? []
            if !currentClaims.contains(claimKey) {
                currentClaims.append(claimKey)
                state["claims"] = currentClaims
            }
            state["day"] = currentDay + 1
            state["checkedToday"] = true

            var wallet = state["wallet"] as? [[String: Any]] ?? []
            wallet.append([
                "id": rewardId,
                "name": self.displayName(for: rewardId),
                "quantity": qty
            ])
            state["wallet"] = wallet
        }
    }

    private func handleMonthlyCheckIn(uid: String, garden: GardenModel, requestId: String?) async throws -> [String: Any] {
        let isVIP = SubscriptionManager.isVIP(gardenModel: garden)
        let preState = try await fetchOrInitState(uid: uid, level: garden.user.userLevel, isVIP: isVIP)
        if let requestId, let receipts = preState["receipts"] as? [String: Any], let cached = receipts[requestId] as? [String: Any] {
            return cached
        }

        let checkedToday = preState["monthlyCheckedToday"] as? Bool ?? false
        let dayIndex = (preState["monthlyDay"] as? NSNumber)?.intValue ?? 0
        let monthKey = (preState["monthlyMonthKey"] as? String) ?? currentVietnamMonthString()
        let rawRewards = preState["monthlyRewards"] as? [[String: Any]] ?? []
        let rewards = rawRewards.compactMap(MonthlyRewardItem.init(dict:))

        guard !checkedToday, dayIndex >= 0, dayIndex < min(30, rewards.count) else {
            throw EventReward.failure("Bạn đã điểm danh hôm nay hoặc đã hoàn thành đủ 30 ngày tháng này.".tr)
        }

        let targetReward = rewards[dayIndex]
        let multiplier = isVIP ? 2 : 1
        let expectedQty = targetReward.quantity * multiplier
        let claimKey = "monthly-\(monthKey)-\(dayIndex + 1)"

        let (updatedGarden, qty) = try EventReward.applyV2Reward(
            rewardId: targetReward.rewardId,
            quantityOverride: expectedQty,
            to: garden
        )
        let saved = await FireStoreService.shared.saveEventReward(gardenModel: updatedGarden)
        guard saved else {
            throw EventReward.failure("Chưa lưu được phần thưởng. Vui lòng kiểm tra kết nối rồi thử lại.".tr)
        }

        return try await runDocumentTransaction(uid: uid, level: updatedGarden.user.userLevel, isVIP: isVIP, requestId: requestId) { state in
            let isChecked = state["monthlyCheckedToday"] as? Bool ?? false
            let currentDay = (state["monthlyDay"] as? NSNumber)?.intValue ?? 0
            let currentMonth = (state["monthlyMonthKey"] as? String) ?? monthKey
            guard currentMonth == monthKey, !isChecked, currentDay == dayIndex, currentDay < 30 else {
                throw EventReward.failure("Bạn đã điểm danh hôm nay hoặc đã hoàn thành đủ 30 ngày tháng này.".tr)
            }

            var currentClaims = state["claims"] as? [String] ?? []
            if !currentClaims.contains(claimKey) {
                currentClaims.append(claimKey)
                state["claims"] = currentClaims
            }
            state["monthlyDay"] = currentDay + 1
            state["monthlyCheckedToday"] = true

            var wallet = state["wallet"] as? [[String: Any]] ?? []
            wallet.append([
                "id": targetReward.rewardId,
                "name": self.displayName(for: targetReward.rewardId),
                "quantity": qty
            ])
            state["wallet"] = wallet
        }
    }

    // MARK: - Harvest Event (cuts mature plant back to Lv.1 and places on shelf)

    private func handleHarvestPlant(uid: String, payload: [String: Any], garden: GardenModel, requestId: String?) async throws -> [String: Any] {
        let preState = try await fetchOrInitState(uid: uid, level: garden.user.userLevel)
        if let requestId, let receipts = preState["receipts"] as? [String: Any], let cached = receipts[requestId] as? [String: Any] {
            return cached
        }

        guard let plantId = payload["plantId"] as? String,
              let requirement = harvestRequirements.first(where: { $0.plantId == plantId }) else {
            throw EventReward.failure("Cây không nằm trong danh sách thu hoạch.".tr)
        }

        let progress = preState["harvestProgress"] as? [String: Any] ?? [:]
        let currentCollected = (progress[plantId] as? NSNumber)?.intValue ?? 0
        guard currentCollected < requirement.required else {
            throw EventReward.failure("Kệ vật phẩm cho cây này đã đủ số lượng.".tr)
        }

        let preferredPosition = payload["position"] as? String
        guard let targetIndex = activeMaturePlantIndex(for: plantId, preferredPosition: preferredPosition, in: garden) else {
            throw EventReward.failure("Bạn chưa có cây trưởng thành phù hợp trong khu vườn.".tr)
        }

        var updatedGarden = garden
        updatedGarden.plants[targetIndex].plantLevel = 1
        updatedGarden.plants[targetIndex].platLevelExp = 0

        let saved = await FireStoreService.shared.saveEventReward(gardenModel: updatedGarden)
        guard saved else {
            throw EventReward.failure("Chưa lưu được tiến trình thu hoạch. Vui lòng kiểm tra kết nối rồi thử lại.".tr)
        }

        return try await runDocumentTransaction(uid: uid, level: updatedGarden.user.userLevel, requestId: requestId) { state in
            var currentProgress = state["harvestProgress"] as? [String: Any] ?? [:]
            let latestCount = (currentProgress[plantId] as? NSNumber)?.intValue ?? 0
            guard latestCount < requirement.required else {
                throw EventReward.failure("Kệ vật phẩm cho cây này đã đủ số lượng.".tr)
            }
            currentProgress[plantId] = latestCount + 1
            state["harvestProgress"] = currentProgress
        }
    }

    private func handleHarvestClaimReward(uid: String, garden: GardenModel, requestId: String?) async throws -> [String: Any] {
        let preState = try await fetchOrInitState(uid: uid, level: garden.user.userLevel)
        if let requestId, let receipts = preState["receipts"] as? [String: Any], let cached = receipts[requestId] as? [String: Any] {
            return cached
        }

        let claims = preState["claims"] as? [String] ?? []
        let claimKey = "harvest-complete"
        guard !claims.contains(claimKey) else {
            throw EventReward.failure("Quà đã nhận.".tr)
        }

        let progress = preState["harvestProgress"] as? [String: Any] ?? [:]
        let isComplete = harvestRequirements.allSatisfy { req in
            ((progress[req.plantId] as? NSNumber)?.intValue ?? 0) >= req.required
        }
        guard isComplete else {
            throw EventReward.failure("Bạn chưa hoàn thiện đủ kệ vật phẩm.".tr)
        }

        let harvestRewards = specs["harvest"]!.rewards
        var updatedGarden = garden
        var grantedItems: [(id: String, qty: Int)] = []
        for reward in harvestRewards {
            let result = try EventReward.applyV2Reward(
                rewardId: reward.id,
                quantityOverride: reward.quantity,
                to: updatedGarden
            )
            updatedGarden = result.garden
            grantedItems.append((reward.id, result.quantity))
        }

        let saved = await FireStoreService.shared.saveEventReward(gardenModel: updatedGarden)
        guard saved else {
            throw EventReward.failure("Chưa lưu được phần thưởng. Vui lòng kiểm tra kết nối rồi thử lại.".tr)
        }

        return try await runDocumentTransaction(uid: uid, level: updatedGarden.user.userLevel, requestId: requestId) { state in
            var currentClaims = state["claims"] as? [String] ?? []
            guard !currentClaims.contains(claimKey) else {
                throw EventReward.failure("Quà đã nhận.".tr)
            }
            currentClaims.append(claimKey)
            state["claims"] = currentClaims

            var wallet = state["wallet"] as? [[String: Any]] ?? []
            for item in grantedItems {
                wallet.append([
                    "id": item.id,
                    "name": self.displayName(for: item.id),
                    "quantity": item.qty
                ])
            }
            state["wallet"] = wallet
        }
    }

    private func activeMaturePlantIndex(for plantId: String, preferredPosition: String?, in garden: GardenModel) -> Int? {
        // Only the last record at each socket position is active in the garden.
        var latestIndexByPosition: [String: Int] = [:]
        for (index, plant) in garden.plants.enumerated() {
            latestIndexByPosition[plant.position] = index
        }

        let activeIndices = latestIndexByPosition.values.sorted()
        if let preferredPosition,
           let preferredIdx = latestIndexByPosition[preferredPosition] {
            let plant = garden.plants[preferredIdx]
            if plant.idPlant == plantId && !plant.idPot.isEmpty && plant.plantLevel >= 3 {
                return preferredIdx
            }
        }

        return activeIndices.first { idx in
            let plant = garden.plants[idx]
            return plant.idPlant == plantId && !plant.idPot.isEmpty && plant.plantLevel >= 3
        }
    }

    private func harvestSnapshot(from state: [String: Any], garden: GardenModel?) -> [String: Any] {
        let progress = state["harvestProgress"] as? [String: Any] ?? [:]
        let claims = state["claims"] as? [String] ?? []

        var matureCounts: [String: Int] = [:]
        if let garden {
            for plant in garden.weatherPlants where plant.plantLevel >= 3 {
                matureCounts[plant.idPlant, default: 0] += 1
            }
        }

        let requirementsPayload: [[String: Any]] = harvestRequirements.map { req in
            let collected = min(req.required, (progress[req.plantId] as? NSNumber)?.intValue ?? 0)
            let remaining = max(0, req.required - collected)
            return [
                "plantId": req.plantId,
                "required": req.required,
                "collected": collected,
                "remaining": remaining,
                "matureInGarden": matureCounts[req.plantId] ?? 0
            ]
        }

        let isComplete = harvestRequirements.allSatisfy { req in
            ((progress[req.plantId] as? NSNumber)?.intValue ?? 0) >= req.required
        }

        return [
            "requirements": requirementsPayload,
            "maturePlants": matureCounts,
            "isComplete": isComplete,
            "claimed": claims.contains("harvest-complete"),
            "rewards": specs["harvest"]!.toWebList()
        ]
    }

    // MARK: - Firestore Transaction Core

    private func fetchOrInitState(uid: String, level: Int, isVIP: Bool = false) async throws -> [String: Any] {
        return try await runDocumentTransaction(uid: uid, level: level, isVIP: isVIP, requestId: nil, includeReceiptsInReturn: true) { _ in }
    }

    private func runDocumentTransaction(
        uid: String,
        level: Int,
        isVIP: Bool? = nil,
        requestId: String?,
        includeReceiptsInReturn: Bool = false,
        mutation: @escaping (inout [String: Any]) throws -> Void
    ) async throws -> [String: Any] {
        let docRef = db.collection(collectionName).document(uid)
        let today = currentVietnamDateString()
        let currentMonth = currentVietnamMonthString()
        let resolvedVIP = isVIP ?? SubscriptionManager.isVIP(gardenModel: FireStoreService.shared.gradenModel)
        let oxygenDelta = FireStoreService.shared.consumePendingEventOxygen()

        do {
            let result = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(docRef)
                    var state = snapshot.data() ?? self.defaultState(uid: uid, today: today, monthKey: currentMonth, isVIP: resolvedVIP)
                    let isNew = !snapshot.exists

                    if oxygenDelta > 0 {
                        let currentOxy = (state["oxygenCollected"] as? NSNumber)?.intValue ?? 0
                        state["oxygenCollected"] = currentOxy + oxygenDelta
                    }

                    var didMonthlyReset = false
                    let storedMonth = state["monthlyMonthKey"] as? String
                    let currentMonthlyDay = (state["monthlyDay"] as? NSNumber)?.intValue ?? 0
                    let existingRewards = (state["monthlyRewards"] as? [[String: Any]] ?? []).compactMap(MonthlyRewardItem.init(dict:))
                    let storedRewardsVIP = state["monthlyRewardsVIP"] as? Bool
                    let hasDisallowedUpcoming = !resolvedVIP && existingRewards.contains {
                        $0.day > currentMonthlyDay && !MonthlyRewardGenerator.isAllowed(rarity: $0.rarity, isVIP: false)
                    }

                    if storedMonth != currentMonth || existingRewards.count != 30 {
                        let generated = MonthlyRewardGenerator.generate(
                            monthKey: currentMonth,
                            seedSalt: "\(uid)-\(UUID().uuidString.prefix(8))",
                            isVIP: resolvedVIP
                        )
                        state["monthlyMonthKey"] = currentMonth
                        state["monthlyDay"] = 0
                        state["monthlyCheckedToday"] = false
                        state["monthlyRewards"] = generated.map { $0.toDictionary() }
                        state["monthlyRewardsVIP"] = resolvedVIP
                        didMonthlyReset = true
                    } else if hasDisallowedUpcoming || (storedRewardsVIP != resolvedVIP && currentMonthlyDay < 30) {
                        let reconciled = MonthlyRewardGenerator.reconcileRewards(
                            existingRewards,
                            monthKey: currentMonth,
                            seedSalt: "\(uid)-\(UUID().uuidString.prefix(8))",
                            currentDay: currentMonthlyDay,
                            isVIP: resolvedVIP
                        )
                        state["monthlyRewards"] = reconciled.map { $0.toDictionary() }
                        state["monthlyRewardsVIP"] = resolvedVIP
                        didMonthlyReset = true
                    }

                    var didDailyReset = false
                    if (state["lastResetDate"] as? String) != today {
                        state["spins"] = 3
                        state["matchAvailable"] = true
                        state["checkedToday"] = false
                        state["monthlyCheckedToday"] = false
                        state["lastResetDate"] = today
                        didDailyReset = true
                    }

                    state["userId"] = uid
                    state["level"] = level
                    state["isVIP"] = resolvedVIP

                    if let requestId,
                       let receipts = state["receipts"] as? [String: Any],
                       let existingReceipt = receipts[requestId] as? [String: Any] {
                        if isNew || didDailyReset || didMonthlyReset || oxygenDelta > 0 {
                            transaction.setData(state, forDocument: docRef, merge: true)
                        }
                        return includeReceiptsInReturn ? state : existingReceipt
                    }

                    try mutation(&state)

                    let sanitized = self.sanitizedSnapshot(from: state, level: level, isVIP: resolvedVIP)

                    if let requestId, !requestId.isEmpty {
                        var receipts = state["receipts"] as? [String: Any] ?? [:]
                        var order = state["receiptOrder"] as? [String] ?? []
                        receipts[requestId] = sanitized
                        order.append(requestId)
                        while order.count > self.maxStoredReceipts {
                            let oldest = order.removeFirst()
                            receipts.removeValue(forKey: oldest)
                        }
                        state["receipts"] = receipts
                        state["receiptOrder"] = order
                    }

                    transaction.setData(state, forDocument: docRef, merge: true)
                    return includeReceiptsInReturn ? state : sanitized
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            guard let dict = result as? [String: Any] else {
                if oxygenDelta > 0 { FireStoreService.shared.recordEventOxygen(oxygenDelta) }
                throw EventReward.failure("Không thể đồng bộ dữ liệu sự kiện.".tr)
            }
            return dict
        } catch {
            if oxygenDelta > 0 { FireStoreService.shared.recordEventOxygen(oxygenDelta) }
            throw error
        }
    }

    private func defaultState(uid: String, today: String, monthKey: String, isVIP: Bool) -> [String: Any] {
        let monthlyRewards = MonthlyRewardGenerator.generate(monthKey: monthKey, seedSalt: uid, isVIP: isVIP)
        return [
            "userId": uid,
            "oxygenCollected": 0,
            "spins": 3,
            "spinSeq": 0,
            "matchAvailable": true,
            "rounds": 0,
            "claims": [String](),
            "day": 0,
            "checkedToday": false,
            "monthlyMonthKey": monthKey,
            "monthlyDay": 0,
            "monthlyCheckedToday": false,
            "monthlyRewards": monthlyRewards.map { $0.toDictionary() },
            "monthlyRewardsVIP": isVIP,
            "pending": [[String: Any]](),
            "wallet": [[String: Any]](),
            "harvestProgress": [String: Int](),
            "lastResetDate": today,
            "receipts": [String: Any](),
            "receiptOrder": [String]()
        ]
    }

    private func sanitizedSnapshot(from state: [String: Any], level: Int, isVIP: Bool) -> [String: Any] {
        var result: [String: Any] = [
            "oxygenCollected": (state["oxygenCollected"] as? NSNumber)?.intValue ?? 0,
            "level": level,
            "isVIP": isVIP,
            "spins": (state["spins"] as? NSNumber)?.intValue ?? 0,
            "matchAvailable": state["matchAvailable"] as? Bool ?? false,
            "rounds": (state["rounds"] as? NSNumber)?.intValue ?? 0,
            "claims": state["claims"] as? [String] ?? [],
            "day": (state["day"] as? NSNumber)?.intValue ?? 0,
            "checkedToday": state["checkedToday"] as? Bool ?? false,
            "monthlyMonthKey": state["monthlyMonthKey"] as? String ?? currentVietnamMonthString(),
            "monthlyDay": (state["monthlyDay"] as? NSNumber)?.intValue ?? 0,
            "monthlyCheckedToday": state["monthlyCheckedToday"] as? Bool ?? false,
            "monthlyRewards": state["monthlyRewards"] as? [[String: Any]] ?? [],
            "pending": state["pending"] as? [[String: Any]] ?? [],
            "wallet": state["wallet"] as? [[String: Any]] ?? [],
            "eventSpecs": specs.mapValues { $0.toWebList() },
            "harvest": harvestSnapshot(from: state, garden: FireStoreService.shared.gradenModel)
        ]

        if let lastSpin = state["lastSpin"] as? [String: Any] {
            result["lastSpin"] = lastSpin
        }

        if var round = state["round"] as? [String: Any] {
            round.removeValue(forKey: "board")
            result["round"] = round
        } else {
            result["round"] = NSNull()
        }

        return result
    }

    private func currentVietnamDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func currentVietnamMonthString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    // MARK: - Asset Resolution

    private func resolveAssets(itemIds: [String]) -> [String: [String: Any]] {
        var result: [String: [String: Any]] = [:]
        for id in itemIds {
            let name = displayName(for: id)
            let dataURL = thumbnailDataURL(for: id)
            result[id] = [
                "name": name,
                "image": (dataURL as Any?) ?? NSNull()
            ]
        }
        return result
    }

    private func displayName(for id: String) -> String {
        if let item = ItemDataManager.shared.getItem(byId: id) {
            return item.name.tr
        }
        switch id {
        case "oxygen": return "Oxygen"
        case "gemstone": return "Đá quý".tr
        case "ticket": return "Vé thời tiết".tr
        case "fertilizer": return "Phân bón".tr
        case "shovel": return "Xẻng".tr
        default: return id
        }
    }

    private func thumbnailDataURL(for id: String) -> String? {
        let imageName: String? = ItemDataManager.shared.getItem(byId: id)?.image
            ?? (["oxygen", "gemstone", "ticket", "fertilizer", "shovel"].contains(id) ? id : nil)
        guard let imageName,
              let source = UIImage(named: imageName) else {
            return nil
        }
        let maxSide: CGFloat = 192
        let size = source.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1.0, maxSide / max(size.width, size.height))
        let targetSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let png = resized.pngData() else { return nil }
        return "data:image/png;base64,\(png.base64EncodedString())"
    }
}

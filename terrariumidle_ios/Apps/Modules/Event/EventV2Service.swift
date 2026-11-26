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

    private struct EventSpec {
        let rewardIds: [String]
        let milestones: [Int]?
    }

    private let specs: [String: EventSpec] = [
        "slot": EventSpec(rewardIds: ["plant20", "pot1", "oxygen"], milestones: nil),
        "match": EventSpec(rewardIds: ["plant2", "pot1", "fertilizer", "oxygen"], milestones: nil),
        "oxygen": EventSpec(rewardIds: ["fertilizer", "pot1", "plant20"], milestones: [1000, 5000, 10000]),
        "level": EventSpec(rewardIds: ["oxygen", "pot1", "plant20"], milestones: [5, 10, 20]),
        "daily": EventSpec(rewardIds: ["oxygen", "fertilizer", "oxygen", "pot1", "oxygen", "fertilizer", "plant20"], milestones: nil),
        "monthly": EventSpec(rewardIds: ["oxygen", "fertilizer", "shovel", "gemstone", "ticket"], milestones: nil)
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
                if let wonId {
                    var pending = state["pending"] as? [[String: Any]] ?? []
                    pending.append([
                        "id": "spin-\(seq)",
                        "rewardId": wonId,
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
                        var pending = state["pending"] as? [[String: Any]] ?? []
                        pending.append([
                            "id": currentId,
                            "rewardId": first,
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
            return try await handleClaimReward(uid: uid, eventId: eventId, payload: payload, garden: garden, requestId: requestId)

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
        let claimKey: String
        var pendingIdToRemove: String?

        if let milestones = spec.milestones {
            guard let milestone = (payload["milestone"] as? NSNumber)?.intValue,
                  let idx = milestones.firstIndex(of: milestone) else {
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
            rewardIdToGrant = spec.rewardIds[idx]
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
            pendingIdToRemove = pendingId
        }

        // 2. Apply to GardenModel and persist to users/{uid} first
        let (updatedGarden, qty) = try EventReward.applyV2Reward(rewardId: rewardIdToGrant, to: garden)
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

        let dailyRewards = specs["daily"]!.rewardIds
        let rewardId = dailyRewards[day]
        let claimKey = "daily-\(day)"

        let (updatedGarden, qty) = try EventReward.applyV2Reward(rewardId: rewardId, to: garden)
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
                    var state = snapshot.data() ?? self.defaultState(uid: uid, today: today, monthKey: currentMonth)
                    let isNew = !snapshot.exists

                    if oxygenDelta > 0 {
                        let currentOxy = (state["oxygenCollected"] as? NSNumber)?.intValue ?? 0
                        state["oxygenCollected"] = currentOxy + oxygenDelta
                    }

                    var didMonthlyReset = false
                    let storedMonth = state["monthlyMonthKey"] as? String
                    let existingRewards = (state["monthlyRewards"] as? [[String: Any]] ?? []).compactMap(MonthlyRewardItem.init(dict:))
                    if storedMonth != currentMonth || existingRewards.count != 30 {
                        let generated = MonthlyRewardGenerator.generate(
                            monthKey: currentMonth,
                            seedSalt: "\(uid)-\(UUID().uuidString.prefix(8))"
                        )
                        state["monthlyMonthKey"] = currentMonth
                        state["monthlyDay"] = 0
                        state["monthlyCheckedToday"] = false
                        state["monthlyRewards"] = generated.map { $0.toDictionary() }
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

    private func defaultState(uid: String, today: String, monthKey: String) -> [String: Any] {
        let monthlyRewards = MonthlyRewardGenerator.generate(monthKey: monthKey, seedSalt: uid)
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
            "pending": [[String: Any]](),
            "wallet": [[String: Any]](),
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
            "wallet": state["wallet"] as? [[String: Any]] ?? []
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

import Foundation

/// Quản lý số lượng phần thưởng ở tầng native; tuyệt đối không tin tưởng số lượng do JavaScript truyền lên.
enum EventReward {
    static func apply(handler: String, argument: Any, to garden: GardenModel) throws -> GardenModel {
        var updated = garden
        switch handler {
        case "event_get_bag_level", "event_get_bag_floor":
            guard (argument as? String) == "true" || (argument as? Bool) == true else { throw failure("Chưa đủ điều kiện nhận huy hiệu".tr) }
            let isLevel = handler == "event_get_bag_level"
            guard isLevel ? garden.user.userLevel >= 50 : garden.user.userFloor >= 20 else { throw failure("Chưa đủ điều kiện nhận huy hiệu".tr) }
            try addBadge(isLevel ? "bag1" : "bag3", to: &updated)
        case "clam-lavender-plant":
            guard let payload = argument as? [String: Any], let code = payload["code"] as? String else { throw failure("Phần thưởng không hợp lệ".tr) }
            guard garden.money.oxygen >= 100 else { throw failure("Cần ít nhất 100 oxygen để quay".tr) }
            switch code {
            case "oxygen": updated.money.oxygen += 50
            case "gemstone": updated.money.gemstone += 10
            case "ticket": updated.money.ticket += 5
            case "fertilizer": updated.item.fertilizer += 1
            case "shovel": updated.item.shovel += 1
            case "bag4": try addBadge(code, to: &updated)
            case "plant20", "plant24", "plant26":
                guard !garden.cart.cartPlants.contains(code) else { throw failure("Bạn đã sở hữu cây này".tr) }
                updated.cart = GardenModel.Cart(cartPlants: garden.cart.cartPlants + [code], cartPots: garden.cart.cartPots, cartStickers: garden.cart.cartStickers)
            default: throw failure("Mã phần thưởng chưa được hỗ trợ".tr)
            }
            updated.money.oxygen -= 100
        default: throw failure("Lệnh sự kiện chưa được hỗ trợ".tr)
        }
        return updated
    }

    static func applyV2Reward(rewardId: String, to garden: GardenModel) throws -> (garden: GardenModel, quantity: Int) {
        return try applyV2Reward(rewardId: rewardId, quantityOverride: nil, to: garden)
    }

    static func applyV2Reward(rewardId: String, quantityOverride: Int?, to garden: GardenModel) throws -> (garden: GardenModel, quantity: Int) {
        var updated = garden
        switch rewardId {
        case "oxygen":
            let qty = max(1, quantityOverride ?? 300)
            updated.money.oxygen += qty
            return (updated, qty)
        case "gemstone":
            let qty = max(1, quantityOverride ?? 10)
            updated.money.gemstone += qty
            return (updated, qty)
        case "ticket":
            let qty = max(1, quantityOverride ?? 1)
            updated.money.ticket += qty
            return (updated, qty)
        case "fertilizer":
            let qty = max(1, quantityOverride ?? 1)
            updated.item.fertilizer += qty
            return (updated, qty)
        case "shovel":
            let qty = max(1, quantityOverride ?? 1)
            updated.item.shovel += qty
            return (updated, qty)
        case let id where id.hasPrefix("plant"):
            if !garden.cart.cartPlants.contains(id) {
                updated.cart = GardenModel.Cart(
                    cartPlants: garden.cart.cartPlants + [id],
                    cartPots: garden.cart.cartPots,
                    cartStickers: garden.cart.cartStickers
                )
            } else {
                updated.money.oxygen += 300
            }
            return (updated, 1)
        case let id where id.hasPrefix("pot"):
            if !garden.cart.cartPots.contains(id) {
                updated.cart = GardenModel.Cart(
                    cartPlants: garden.cart.cartPlants,
                    cartPots: garden.cart.cartPots + [id],
                    cartStickers: garden.cart.cartStickers
                )
            } else {
                updated.money.oxygen += 300
            }
            return (updated, 1)
        default:
            throw failure("Mã phần thưởng chưa được hỗ trợ".tr)
        }
    }

    private static func addBadge(_ id: String, to garden: inout GardenModel) throws {
        guard !garden.user.bag.contains(where: { $0.idBag == id }) else { throw failure("Bạn đã nhận huy hiệu này".tr) }
        let badge: GardenModel.UserProfile.BagItem
        switch id {
        case "bag1": badge = .init(colorBag: 0xFF000000, idBag: id, nameBag: "Kinh nghiệm nhà vườn".tr)
        case "bag3": badge = .init(colorBag: 0xFF388E3C, idBag: id, nameBag: "Triệu phú giàu sang".tr)
        default: badge = .init(colorBag: 0xFF558B2F, idBag: id, nameBag: "Lá xanh trắng bay".tr)
        }
        var dictionary = garden.user.toDictionary()
        dictionary["bag"] = (garden.user.bag + [badge]).map { ["idBag": $0.idBag, "nameBag": $0.nameBag, "colorBag": $0.colorBag] as [String: Any] }
        garden.user = try GardenModel.UserProfile(dict: dictionary)
    }

    static func failure(_ message: String) -> NSError {
        NSError(domain: "TerrariumEvent", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

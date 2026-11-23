import Foundation

/// Quản lý số lượng phần thưởng ở tầng native; tuyệt đối không tin tưởng số lượng do JavaScript truyền lên.
enum EventReward {
    static func apply(handler: String, argument: Any, to garden: GardenModel) throws -> GardenModel {
        var updated = garden
        switch handler {
        case "event_get_bag_level", "event_get_bag_floor":
            guard (argument as? String) == "true" || (argument as? Bool) == true else { throw failure("Chưa đủ điều kiện nhận huy hiệu") }
            let isLevel = handler == "event_get_bag_level"
            guard isLevel ? garden.user.userLevel >= 50 : garden.user.userFloor >= 20 else { throw failure("Chưa đủ điều kiện nhận huy hiệu") }
            try addBadge(isLevel ? "bag1" : "bag3", to: &updated)
        case "clam-lavender-plant":
            guard let payload = argument as? [String: Any], let code = payload["code"] as? String else { throw failure("Phần thưởng không hợp lệ") }
            guard garden.money.oxygen >= 100 else { throw failure("Cần ít nhất 100 oxygen để quay") }
            switch code {
            case "oxygen": updated.money.oxygen += 50
            case "gemstone": updated.money.gemstone += 10
            case "ticket": updated.money.ticket += 5
            case "fertilizer": updated.item.fertilizer += 1
            case "shovel": updated.item.shovel += 1
            case "bag4": try addBadge(code, to: &updated)
            case "plant20", "plant24", "plant26":
                guard !garden.cart.cartPlants.contains(code) else { throw failure("Bạn đã sở hữu cây này") }
                updated.cart = GardenModel.Cart(cartPlants: garden.cart.cartPlants + [code], cartPots: garden.cart.cartPots, cartStickers: garden.cart.cartStickers)
            default: throw failure("Mã phần thưởng chưa được hỗ trợ")
            }
            updated.money.oxygen -= 100
        default: throw failure("Lệnh sự kiện chưa được hỗ trợ")
        }
        return updated
    }

    private static func addBadge(_ id: String, to garden: inout GardenModel) throws {
        guard !garden.user.bag.contains(where: { $0.idBag == id }) else { throw failure("Bạn đã nhận huy hiệu này") }
        let badge: GardenModel.UserProfile.BagItem
        switch id {
        case "bag1": badge = .init(colorBag: 0xFF000000, idBag: id, nameBag: "Kinh nghiệm nhà vườn")
        case "bag3": badge = .init(colorBag: 0xFF388E3C, idBag: id, nameBag: "Triệu phú giàu sang")
        default: badge = .init(colorBag: 0xFF558B2F, idBag: id, nameBag: "Lá xanh trắng bay")
        }
        var dictionary = garden.user.toDictionary()
        dictionary["bag"] = (garden.user.bag + [badge]).map { ["idBag": $0.idBag, "nameBag": $0.nameBag, "colorBag": $0.colorBag] as [String: Any] }
        garden.user = try GardenModel.UserProfile(dict: dictionary)
    }

    static func failure(_ message: String) -> NSError {
        NSError(domain: "TerrariumEvent", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

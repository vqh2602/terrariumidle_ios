import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct EventTests {
    private func event(link: String = "clam-level-up", start: String = "2024-05-05", end: String = "20100-12-30", version: String = "1.0.0") -> TerrariumEvent {
        TerrariumEvent(eventdata: [
            .init(local: "vi", description: "Mô tả", title: "Tiếng Việt", image: ""),
            .init(local: "en", description: "Description", title: "English", image: "")
        ], start: start, end: end, create: "2020-11-01", version: version, link: link)
    }

    private func garden(level: Int = 50, floors: Int = 20, oxygen: Int = 100) -> GardenModel {
        GardenModel(isBan: 0, isServerUpdate: 0,
                    item: .init(fertilizer: 0, shovel: 0),
                    cart: .init(cartPlants: [], cartPots: [], cartStickers: []),
                    money: .init(gemstone: 0, oxygen: oxygen, ticket: 0),
                    user: .init(bag: [], identifier: nil, latestPurchaseDate: nil, userAvatar: nil, userEmail: nil,
                                userFloor: floors, userID: "user +&?", userImageBackground: nil,
                                userLevel: level, userLevelEXP: 0, userName: "Test", userTotalLike: 0), plants: [])
    }

    private var today: Date { Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 12))! }

    @Test func feedDatesLocalizationAndAvailability() throws {
        #expect(event().content(language: "vi")?.title == "Tiếng Việt")
        #expect(event().content(language: "ja")?.title == "English")
        #expect(event().unavailableReason(now: today, appVersion: "1.0.0") == nil)
        #expect(event().unavailableReason(now: today, appVersion: "1.0") == nil)
        #expect(TerrariumEvent.dayValue("2025-1-31") == 20250131)
        #expect(TerrariumEvent.dayValue("invalid") == nil)
        #expect(event(end: "2026-11-23").unavailableReason(now: today, appVersion: "1.0.0") == nil)
        #expect(event(end: "2026-11-22").unavailableReason(now: today, appVersion: "1.0.0") == "Đã kết thúc")
        #expect(event(start: "2026-11-24").unavailableReason(now: today, appVersion: "1.0.0") == "Chưa bắt đầu")
        #expect(event(version: "1.0.10").unavailableReason(now: today, appVersion: "1.0.9") != nil)
        #expect(event(version: "1.0.9").unavailableReason(now: today, appVersion: "1.0.10") == nil)
    }

    @Test func legacyURLsEncodeUserContextAndRejectUnsupportedSchemes() throws {
        for (link, path) in [("clam-level-up", "event_level_terrarium"), ("clam-floor", "events_floors"), ("clam-lavender-plant", "lucky-wheel")] {
            let url = try #require(event(link: link).webURL(garden: garden()))
            #expect(url.path.contains(path))
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            #expect(query?.first { $0.name == "userId" }?.value == "user +&?")
            #expect(query?.first { $0.name == "oxygen" }?.value == "100")
            #expect(event(link: link).webURL(garden: nil) == nil)
        }
        #expect(event(link: "https://www.vqhapp.name.vn/p/event.html").webURL(garden: nil) != nil)
        #expect(event(link: "javascript:alert(1)").webURL(garden: garden()) == nil)
    }

    @Test func badgesRequireNativeEligibilityAndCannotBeClaimedTwice() throws {
        #expect(throws: Error.self) { try EventReward.apply(handler: "event_get_bag_level", argument: "true", to: garden(level: 49)) }
        #expect(throws: Error.self) { try EventReward.apply(handler: "event_get_bag_floor", argument: "true", to: garden(floors: 19)) }
        #expect(throws: Error.self) { try EventReward.apply(handler: "event_get_bag_level", argument: "false", to: garden()) }
        let awarded = try EventReward.apply(handler: "event_get_bag_level", argument: "true", to: garden())
        #expect(awarded.user.bag.map(\.idBag) == ["bag1"])
        #expect(awarded.money.oxygen == 100)
        #expect(throws: Error.self) { try EventReward.apply(handler: "event_get_bag_level", argument: "true", to: awarded) }
        let floor = try EventReward.apply(handler: "event_get_bag_floor", argument: "true", to: garden())
        #expect(floor.user.bag.map(\.idBag) == ["bag3"])
    }

    @Test func wheelUsesFixedAmountsAndChecksBalanceAndRewardCodes() throws {
        let reward = try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "oxygen", "quantity": 999999] as [String: Any], to: garden())
        #expect(reward.money.oxygen == 50)
        let ticket = try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "ticket"], to: garden())
        #expect(ticket.money.ticket == 5)
        #expect(ticket.money.oxygen == 0)
        #expect(throws: Error.self) { try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "ticket"], to: garden(oxygen: 99)) }
        #expect(throws: Error.self) { try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "plant9999"], to: garden()) }
        #expect(throws: Error.self) { try EventReward.apply(handler: "clam-lavender-plant", argument: "malformed", to: garden()) }
        let plant = try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "plant24"], to: garden(oxygen: 200))
        #expect(plant.cart.cartPlants == ["plant24"])
        #expect(plant.money.oxygen == 100)
        #expect(throws: Error.self) { try EventReward.apply(handler: "clam-lavender-plant", argument: ["code": "plant24"], to: plant) }
    }

    @Test func monthlyRewardsExcludeRareAndLegendaryForNonVIP() throws {
        let nonVIPRewards = MonthlyRewardGenerator.generate(monthKey: "2026-11", seedSalt: "user-1", isVIP: false)
        #expect(nonVIPRewards.count == 30)
        #expect(!nonVIPRewards.contains { $0.rarity == "rare" || $0.rarity == "legendary" })
        #expect(!nonVIPRewards.contains { $0.rewardId == "shovel" || $0.rewardId == "ticket" })
        #expect(nonVIPRewards.last?.rewardId == "gemstone")
        let nonVIPIds = Set(nonVIPRewards.map(\.rewardId))
        #expect(nonVIPIds == Set(["oxygen", "fertilizer", "gemstone"]))

        let vipRewards = MonthlyRewardGenerator.generate(monthKey: "2026-11", seedSalt: "user-1", isVIP: true)
        #expect(vipRewards.count == 30)
        let vipIds = Set(vipRewards.map(\.rewardId))
        #expect(vipIds == Set(["oxygen", "fertilizer", "shovel", "gemstone", "ticket"]))

        let reconciled = MonthlyRewardGenerator.reconcileRewards(
            vipRewards,
            monthKey: "2026-11",
            seedSalt: "user-2",
            currentDay: 5,
            isVIP: false
        )
        #expect(reconciled.count == 30)
        #expect(Array(reconciled.prefix(5)) == Array(vipRewards.prefix(5)))
        #expect(!reconciled.dropFirst(5).contains { $0.rarity == "rare" || $0.rarity == "legendary" })
    }
}

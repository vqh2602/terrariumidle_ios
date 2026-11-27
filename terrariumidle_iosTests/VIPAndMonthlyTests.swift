import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct VIPAndMonthlyTests {
    private func makeGarden(vipStatus: GardenModel.VIPStatus = .init()) -> GardenModel {
        GardenModel(
            isBan: 0,
            isServerUpdate: 0,
            item: .init(fertilizer: 0, shovel: 0),
            cart: .init(cartPlants: [], cartPots: [], cartStickers: []),
            money: .init(gemstone: 0, oxygen: 0, ticket: 0),
            user: .init(
                bag: [],
                identifier: nil,
                latestPurchaseDate: nil,
                userAvatar: nil,
                userEmail: nil,
                userFloor: 2,
                userID: "vip-test-user",
                userImageBackground: nil,
                userLevel: 1,
                userLevelEXP: 0,
                userName: "Tester",
                userTotalLike: 0
            ),
            plants: [],
            vipStatus: vipStatus
        )
    }

    @Test func vipUnlocksAllAudioAndVisualCatalogWithoutPlanting() {
        let nonVIPGarden = makeGarden(vipStatus: .init(isActive: false))
        let nonVIPUnlocked = MusicUnlockHelper.getUnlockedMusicIds(from: nonVIPGarden, isVIPOverride: false)
        #expect(nonVIPUnlocked.contains("music1"))
        #expect(nonVIPUnlocked.contains("m0"))
        #expect(!nonVIPUnlocked.contains("music12"))
        #expect(!nonVIPUnlocked.contains("sfx17"))
        #expect(!nonVIPUnlocked.contains("overlay4"))
        #expect(!nonVIPUnlocked.contains("Landscape7"))

        let future = Date().timeIntervalSince1970 + 86400
        let vipGarden = makeGarden(vipStatus: .init(
            isActive: true,
            productId: SubscriptionManager.yearlyProductId,
            expiresAt: future,
            willAutoRenew: true,
            welcomeBonusClaimed: true,
            source: "appstore",
            updatedAt: Date().timeIntervalSince1970
        ))
        let vipUnlocked = MusicUnlockHelper.getUnlockedMusicIds(from: vipGarden)

        for track in ItemDataManager.shared.getAllMusics() {
            #expect(vipUnlocked.contains(track.id), "Expected music \(track.id) unlocked for VIP")
        }
        for sfx in ItemDataManager.shared.getAllMusicsSFX() {
            #expect(vipUnlocked.contains(sfx.id), "Expected SFX \(sfx.id) unlocked for VIP")
        }
        for overlay in ItemDataManager.shared.getAllEffects() {
            #expect(vipUnlocked.contains(overlay.id), "Expected overlay \(overlay.id) unlocked for VIP")
        }
        for landscape in ItemDataManager.shared.getAllLandscapes() {
            #expect(vipUnlocked.contains(landscape.id), "Expected landscape \(landscape.id) unlocked for VIP")
        }
    }

    @Test func vipStatusRoundTripsThroughDictionaryAndChecksExpiry() throws {
        let future = Date().timeIntervalSince1970 + 3600
        let garden = makeGarden(vipStatus: .init(
            isActive: true,
            productId: SubscriptionManager.monthlyProductId,
            expiresAt: future,
            willAutoRenew: true,
            welcomeBonusClaimed: true,
            source: "appstore",
            updatedAt: 1_700_000_000
        ))
        let restored = try GardenModel(dict: garden.toDictionary())
        #expect(restored.vipStatus.isCurrentlyActive == true)
        #expect(restored.vipStatus.productId == SubscriptionManager.monthlyProductId)
        #expect(restored.vipStatus.welcomeBonusClaimed == true)

        let expired = GardenModel.VIPStatus(
            isActive: true,
            productId: SubscriptionManager.monthlyProductId,
            expiresAt: Date().timeIntervalSince1970 - 60
        )
        #expect(expired.isCurrentlyActive == false)
    }

    @Test func monthlyGeneratorCreates30RewardsWithAllFiveTypesAndRarityBounds() {
        let novRewards = MonthlyRewardGenerator.generate(monthKey: "2026-11", seedSalt: "userA", isVIP: true)
        let decRewards = MonthlyRewardGenerator.generate(monthKey: "2026-12", seedSalt: "userA", isVIP: true)

        #expect(novRewards.count == 30)
        #expect(decRewards.count == 30)
        #expect(novRewards != decRewards)
        #expect(novRewards.map(\.day) == Array(1 ... 30))

        let types = Set(novRewards.map(\.rewardId))
        for expected in ["oxygen", "gemstone", "ticket", "fertilizer", "shovel"] {
            #expect(types.contains(expected), "Missing \(expected) in monthly rewards")
        }

        for item in novRewards {
            switch item.rewardId {
            case "oxygen":
                #expect((250 ... 1200).contains(item.quantity))
                #expect(item.rarity == "common")
            case "fertilizer":
                #expect((2 ... 8).contains(item.quantity))
                #expect(item.rarity == "uncommon")
            case "shovel":
                #expect((1 ... 4).contains(item.quantity))
                #expect(item.rarity == "rare")
            case "gemstone":
                #expect((5 ... 25).contains(item.quantity))
                #expect(item.rarity == "epic")
            case "ticket":
                #expect((1 ... 3).contains(item.quantity))
                #expect(item.rarity == "legendary")
            default:
                Issue.record("Unexpected rewardId \(item.rewardId)")
            }
        }

        let day30 = novRewards.last!
        #expect(day30.rewardId == "gemstone" || day30.rewardId == "ticket")
    }

    @Test func v2RewardsCreditAllFiveMonthlyResourcesWithDynamicQuantities() throws {
        var garden = makeGarden()
        garden = try EventReward.applyV2Reward(rewardId: "oxygen", quantityOverride: 800, to: garden).garden
        garden = try EventReward.applyV2Reward(rewardId: "gemstone", quantityOverride: 20, to: garden).garden
        garden = try EventReward.applyV2Reward(rewardId: "ticket", quantityOverride: 4, to: garden).garden
        garden = try EventReward.applyV2Reward(rewardId: "fertilizer", quantityOverride: 6, to: garden).garden
        garden = try EventReward.applyV2Reward(rewardId: "shovel", quantityOverride: 2, to: garden).garden

        #expect(garden.money.oxygen == 800)
        #expect(garden.money.gemstone == 20)
        #expect(garden.money.ticket == 4)
        #expect(garden.item.fertilizer == 6)
        #expect(garden.item.shovel == 2)
    }

    @Test func monthlyEventURLMapsToV2MonthlyEventId() {
        let event = TerrariumEvent(
            eventdata: [.init(local: "vi", description: "30 ngày", title: "30 Ngày Xanh", image: "")],
            start: "2026-11-26",
            end: "2027-12-31",
            create: "2026-11-26",
            version: "1.0.0",
            link: "https://vqh2602.github.io/terrarium_data.github.io/terrarium-events-web/events/monthly.html"
        )
        #expect(event.v2EventId == "monthly")
    }
}

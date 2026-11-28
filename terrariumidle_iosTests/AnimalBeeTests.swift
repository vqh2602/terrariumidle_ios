import Foundation
import SpriteKit
import Testing
@testable import terrariumidle_ios

@MainActor
struct AnimalBeeTests {
    private func makeGarden(plants: [GardenModel.Plant] = [], cartAnimals: [String] = []) -> GardenModel {
        GardenModel(
            isBan: 0,
            isServerUpdate: 0,
            item: .init(fertilizer: 0, shovel: 1),
            cart: .init(cartPlants: [], cartPots: [], cartStickers: [], cartAnimals: cartAnimals),
            money: .init(gemstone: 0, oxygen: 500_000, ticket: 0),
            user: .init(
                bag: [],
                identifier: nil,
                latestPurchaseDate: nil,
                userAvatar: nil,
                userEmail: nil,
                userFloor: 2,
                userID: "test-user",
                userImageBackground: nil,
                userLevel: 20,
                userLevelEXP: 0,
                userName: "Tester",
                userTotalLike: 0
            ),
            plants: plants
        )
    }

    @Test func animalsDataLoadedAndDecoded() throws {
        let animals = ItemDataManager.shared.getAllAnimals()
        #expect(!animals.isEmpty)
        let beeHive = try #require(ItemDataManager.shared.getAnimal(byId: "animal1"))
        #expect(beeHive.type == "animal")
        #expect(beeHive.maximum == 1)
        #expect(beeHive.itemTypeAttribute.isHanging)
        #expect(beeHive.itemTypeAttribute.isInFront)
        #expect(beeHive.clickSound == "mixkit-clinking-coins-1993")
        #expect(beeHive.childClickSound(for: "bee") == "mixkit-clinking-coins-1993")
    }

    @Test func maximumLimitPreventsSecondHivePlacement() throws {
        let beeHive = try #require(ItemDataManager.shared.getAnimal(byId: "animal1"))
        let emptyGarden = makeGarden()
        #expect(emptyGarden.canPlantItem(beeHive, at: "1,1"))

        let planted = GardenModel.Plant(
            harvestTime: 1000,
            idPlant: "animal1",
            idPot: "animal1",
            isHanging: true,
            plantLevel: 1,
            platLevelExp: 0,
            position: "1,1"
        )
        let gardenWithHive = makeGarden(plants: [planted])
        #expect(gardenWithHive.plantedCount(forItemId: "animal1") == 1)
        #expect(!gardenWithHive.canPlantItem(beeHive, at: "1,2"))
        #expect(gardenWithHive.canPlantItem(beeHive, at: "1,1"))
    }

    @Test func cartAnimalsDictBackwardsCompatible() throws {
        let legacyDict: [String: Any] = [
            "cartPlants": ["plant1"],
            "cartPots": ["pot1"],
            "cartStickers": ["sticker1"]
        ]
        let cart = try GardenModel.Cart(dict: legacyDict)
        #expect(cart.cartAnimals.isEmpty)

        let withAnimalDict: [String: Any] = [
            "cartPlants": [],
            "cartPots": [],
            "cartStickers": [],
            "cartAnimals": ["animal1"]
        ]
        let cartWithAnimal = try GardenModel.Cart(dict: withAnimalDict)
        #expect(cartWithAnimal.cartAnimals == ["animal1"])
        #expect((cartWithAnimal.toDictionary()["cartAnimals"] as? [String]) == ["animal1"])
    }

    @Test func beeAgentsAssembleAllFourVariantsAndStates() {
        for variant in BeeVariant.allCases {
            let bee = BeeAgentNode(variant: variant, displayWidth: 40)
            #expect(bee.flightState == .idleInHive)
            bee.setState(.flyingToPlant)
            #expect(bee.flightState == .flyingToPlant)
            #expect(!bee.isHidden)
            bee.setState(.collecting)
            #expect(bee.flightState == .collecting)
            bee.setState(.returning)
            #expect(bee.flightState == .returning)
            bee.setState(.startled)
            #expect(bee.flightState == .startled)
            bee.setState(.idleInHive)
            #expect(bee.isHidden)
        }
    }

    @Test func animal1NodeBuildsAndLoadsSceneTemplate() {
        let hive = Animal1Node(containerSize: CGSize(width: 120, height: 220), isHanging: true)
        #expect(hive.isHanging)
        hive.playTapAnimation()
    }

    @Test func bugsNetAnimal3AndPestNodesAssembleCleanly() throws {
        let bugsNet = try #require(ItemDataManager.shared.getAnimal(byId: "animal3"))
        #expect(bugsNet.name == "Bugsnet")
        #expect(bugsNet.image == "greenmeshbag-1@4.167x")
        #expect(bugsNet.itemTypeAttribute.isHanging)
        #expect(bugsNet.itemTypeAttribute.isInFront)
        #expect(bugsNet.maximum == 1)

        let bagNode = Animal3Node(
            containerSize: CGSize(width: 120, height: 220),
            isHanging: true,
            capturedPests: [.bug1, .grasshopper, .bug1, .grasshopper, .bug1, .bug1]
        )
        #expect(bagNode.capturedPests.count == 5)
        bagNode.playTapAnimation()

        for species in PestSpecies.allCases {
            let pestNode = PestAgentNode(species: species, plantPositionKey: "1,1", displayWidth: 32)
            pestNode.position = CGPoint(x: 100, y: 100)
            #expect(!pestNode.isDisposed)
            #expect(pestNode.containsWorldPoint(CGPoint(x: 100, y: 100)))
            #expect(!pestNode.containsWorldPoint(CGPoint(x: 145, y: 100)))
            #expect(!pestNode.containsWorldPoint(CGPoint(x: 100, y: 140)))
        }
    }

    @Test func sprayWeatherRespectsFreeDailyQuotaAndClearsPestsWithoutBagCapture() {
        let now = Date().timeIntervalSince1970
        let samplePlant = GardenModel.Plant(
            harvestTime: 1000,
            idPlant: "plant1",
            idPot: "pot1",
            isHanging: false,
            plantLevel: 3,
            platLevelExp: 0,
            position: "1,1"
        )
        let pest = GardenPest(kind: .bug1, position: "1,1", plantId: "plant1", source: .auto, createdAt: now)

        var nonVIP = makeGarden(plants: [samplePlant])
        nonVIP.pests = [pest]
        nonVIP.money.ticket = 1

        #expect(nonVIP.remainingFreeSprays(isVIP: false) == 1)
        let first = nonVIP.startWeather(.spray, isVIP: false, now: now)
        #expect(first == .started)
        #expect(nonVIP.weatherKind == .spray)
        #expect(nonVIP.weatherUntil == now + 5)
        #expect(nonVIP.pests.isEmpty)
        #expect(nonVIP.capturedPests.isEmpty)
        #expect(nonVIP.money.ticket == 1)
        #expect(nonVIP.remainingFreeSprays(isVIP: false) == 0)

        let second = nonVIP.startWeather(.spray, isVIP: false, now: now + 10)
        #expect(second == .started)
        #expect(nonVIP.money.ticket == 0)

        let third = nonVIP.startWeather(.spray, isVIP: false, now: now + 20)
        #expect(third == .insufficientTickets)

        var vipGarden = makeGarden(plants: [samplePlant])
        #expect(vipGarden.remainingFreeSprays(isVIP: true) == 5)
        for step in 0..<5 {
            let res = vipGarden.startWeather(.spray, isVIP: true, now: now + Double(step * 10))
            #expect(res == .started)
        }
        #expect(vipGarden.remainingFreeSprays(isVIP: true) == 0)
        #expect(vipGarden.startWeather(.spray, isVIP: true, now: now + 60) == .insufficientTickets)
    }

    @Test func visitorPestDropRequiresCapturedPestsAndConsumesFromBag() {
        var garden = makeGarden(plants: [])
        let initialOxygen = garden.money.oxygen
        #expect(!garden.canDropPestToVisitor)
        #expect(garden.recordVisitorPestDrop() == nil)
        #expect(garden.money.oxygen == initialOxygen)

        garden.capturedPests = [.bug1, .grasshopper]
        #expect(garden.canDropPestToVisitor)

        let firstSent = garden.recordVisitorPestDrop()
        #expect(firstSent == .bug1)
        #expect(garden.capturedPests == [.grasshopper])
        #expect(garden.remainingVisitorPestDrops() == 9)
        #expect(garden.money.oxygen == initialOxygen + GardenModel.visitorDropOxygenReward)

        let secondSent = garden.recordVisitorPestDrop()
        #expect(secondSent == .grasshopper)
        #expect(garden.capturedPests.isEmpty)
        #expect(!garden.canDropPestToVisitor)
        #expect(garden.recordVisitorPestDrop() == nil)
        #expect(garden.money.oxygen == initialOxygen + GardenModel.visitorDropOxygenReward * 2)
    }

    @Test func visitorPestDailyLimitsRespectVIPAndDoNotConsumeExtraPests() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        for isVIP in [false, true] {
            var garden = makeGarden(plants: [])
            let initialOxygen = garden.money.oxygen
            let limit = isVIP ? 20 : 10
            #expect(garden.remainingVisitorPestDrops(isVIP: isVIP, now: date) == limit)
            for _ in 0..<limit {
                garden.capturedPests = [.bug1]
                #expect(garden.recordVisitorPestDrop(isVIP: isVIP, date: date) == .bug1)
            }
            garden.capturedPests = [.grasshopper]
            #expect(garden.remainingVisitorPestDrops(isVIP: isVIP, now: date) == 0)
            #expect(garden.recordVisitorPestDrop(isVIP: isVIP, date: date) == nil)
            #expect(garden.capturedPests == [.grasshopper])
            #expect(garden.pestDropCount == limit)
            #expect(garden.money.oxygen == initialOxygen + limit * GardenModel.visitorDropOxygenReward)
        }
    }

    @Test func visitorPestDropsKeepUsageWhenVIPChangesAndResetNextDay() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var garden = makeGarden(plants: [])
        garden.pestDropDate = GardenModel.todayDateKey(date: date)
        garden.pestDropCount = 10
        garden.capturedPests = [.bug1, .grasshopper]
        #expect(garden.remainingVisitorPestDrops(isVIP: false, now: date) == 0)
        #expect(garden.remainingVisitorPestDrops(isVIP: true, now: date) == 10)
        #expect(garden.recordVisitorPestDrop(isVIP: true, date: date) == .bug1)
        #expect(garden.remainingVisitorPestDrops(isVIP: false, now: date) == 0)
        #expect(garden.recordVisitorPestDrop(isVIP: false, date: date) == nil)
        #expect(garden.capturedPests == [.grasshopper])

        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        #expect(garden.remainingVisitorPestDrops(isVIP: true, now: nextDay) == 20)
        #expect(garden.remainingVisitorPestDrops(isVIP: false, now: nextDay) == 10)
        #expect(garden.recordVisitorPestDrop(isVIP: true, date: nextDay) == .grasshopper)
        #expect(garden.pestDropCount == 1)
        #expect(garden.pestDropDate == GardenModel.todayDateKey(date: nextDay))
    }

}

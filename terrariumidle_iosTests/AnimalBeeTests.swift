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
}

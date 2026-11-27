import XCTest
@testable import terrariumidle_ios

final class ChangePotTests: XCTestCase {
    private func makeGarden(oxygen: Int, plants: [GardenModel.Plant]) -> GardenModel {
        GardenModel(
            isBan: 0,
            isServerUpdate: 0,
            item: .init(fertilizer: 0, shovel: 1),
            cart: .init(cartPlants: ["plant1"], cartPots: ["pot1", "pot2"], cartStickers: [], cartAnimals: []),
            money: .init(gemstone: 100, oxygen: oxygen, ticket: 0),
            user: .init(
                bag: [],
                identifier: nil,
                latestPurchaseDate: nil,
                userAvatar: nil,
                userEmail: nil,
                userFloor: 2,
                userID: "u1",
                userImageBackground: nil,
                userLevel: 5,
                userLevelEXP: 0,
                userName: "Tester",
                userTotalLike: 0
            ),
            plants: plants
        )
    }

    func testChangePotSucceedsForVIPWithoutRefundingOldPot() {
        let original = GardenModel.Plant(
            harvestTime: 123456,
            idPlant: "plant1",
            idPot: "pot1",
            isHanging: false,
            plantLevel: 7,
            platLevelExp: 42,
            position: "0,1",
            wateringUntil: 9999
        )
        var garden = makeGarden(oxygen: 1200, plants: [original])

        let result = garden.changePot(at: "0,1", plantId: "plant1", to: "pot2", cost: 500, isVIP: true)

        XCTAssertEqual(result, .changed)
        XCTAssertEqual(garden.money.oxygen, 700)
        XCTAssertEqual(garden.plants.first?.idPot, "pot2")
        XCTAssertEqual(garden.plants.first?.plantLevel, 7)
        XCTAssertEqual(garden.plants.first?.platLevelExp, 42)
        XCTAssertEqual(garden.plants.first?.wateringUntil, 9999)
        XCTAssertEqual(garden.plants.first?.harvestTime, 123456)
    }

    func testChangePotRequiresVIP() {
        let original = GardenModel.Plant(
            harvestTime: 123456,
            idPlant: "plant1",
            idPot: "pot1",
            isHanging: false,
            plantLevel: 3,
            platLevelExp: 10,
            position: "0,1"
        )
        var garden = makeGarden(oxygen: 1200, plants: [original])

        let result = garden.changePot(at: "0,1", plantId: "plant1", to: "pot2", cost: 500, isVIP: false)

        XCTAssertEqual(result, .vipRequired)
        XCTAssertEqual(garden.money.oxygen, 1200)
        XCTAssertEqual(garden.plants.first?.idPot, "pot1")
    }

    func testChangePotRejectsInsufficientOxygenAndSamePot() {
        let original = GardenModel.Plant(
            harvestTime: 123456,
            idPlant: "plant1",
            idPot: "pot1",
            isHanging: false,
            plantLevel: 1,
            platLevelExp: 0,
            position: "0,1"
        )
        var garden = makeGarden(oxygen: 300, plants: [original])

        XCTAssertEqual(garden.changePot(at: "0,1", plantId: "plant1", to: "pot1", cost: 500, isVIP: true), .samePot)
        XCTAssertEqual(garden.changePot(at: "0,1", plantId: "plant1", to: "pot2", cost: 500, isVIP: true), .insufficientOxygen)
        XCTAssertEqual(garden.money.oxygen, 300)
        XCTAssertEqual(garden.plants.first?.idPot, "pot1")
    }
}

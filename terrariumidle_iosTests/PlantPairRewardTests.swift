import Testing
@testable import terrariumidle_ios

struct PlantPairRewardTests {
    @Test func recommendationsAndRewardsAgreeForEveryPair() throws {
        let items = ItemDataManager.shared
        let plants = items.getAllPlants()
        let pots = items.getAllPots()
        #expect(!plants.isEmpty)
        #expect(!pots.isEmpty)
        for plant in plants {
            for pot in pots {
                let expected = plant.id.dropFirst(5) == pot.id.dropFirst(3)
                    && plant.itemTypeAttribute.isHanging == pot.itemTypeAttribute.isHanging
                #expect(items.isRecommendedPair(plantId: plant.id, potId: pot.id) == expected)
                #expect((items.recommendedPlant(for: pot.id)?.id == plant.id) == expected)
                for level in [1, 2, 3, 10] {
                    let base = ShareFunc.getDropRate(level: level).oxygen
                    let reward = items.collectionOxygen(level: level, plantId: plant.id, potId: pot.id)
                    #expect(reward == (expected ? Int((Double(base) * 2.5).rounded()) : base))
                }
            }
        }
        #expect(items.collectionOxygen(level: 1, plantId: "plant1", potId: "pot1") == 8)
        #expect(items.collectionOxygen(level: 2, plantId: "plant1", potId: "pot1") == 13)
        #expect(items.collectionOxygen(level: 3, plantId: "plant1", potId: "pot1") == 25)
    }

    @Test func invalidOrDecorationPairsReceiveNoBonus() {
        let items = ItemDataManager.shared
        for (plant, pot) in [("", ""), ("plant999", "pot999"), ("sticker1", "sticker1"),
                             ("plant1", ""), ("plant1", "pot2"), ("plant1", "pot01")] {
            #expect(!items.isRecommendedPair(plantId: plant, potId: pot))
            #expect(items.collectionOxygen(level: 3, plantId: plant, potId: pot) == 10)
        }
    }
}

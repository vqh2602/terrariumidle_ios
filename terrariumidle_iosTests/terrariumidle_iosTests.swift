//
//  terrariumidle_iosTests.swift
//  terrariumidle_iosTests
//
//  Created by vương quang huy on 29/1/26.
//

import Testing
@testable import terrariumidle_ios

@MainActor
struct terrariumidle_iosTests {

    @Test func testPlantPositionParsing() async throws {
        let pos1 = PlantPosition(from: "1,2")
        #expect(pos1?.row == 1)
        #expect(pos1?.column == 2)

        let pos0 = PlantPosition(from: "0,3")
        #expect(pos0?.row == 0)
        #expect(pos0?.column == 3)

        let invalid = PlantPosition(from: "invalid")
        #expect(invalid == nil)
    }

    @Test func testPlantingReplacesExistingPosition() async throws {
        var plants: [GardenModel.Plant] = [
            GardenModel.Plant(
                harvestTime: 0,
                idPlant: "",
                idPot: "",
                isHanging: false,
                plantLevel: 1,
                platLevelExp: 0,
                position: "1,2"
            )
        ]

        let newPlant = GardenModel.Plant(
            harvestTime: 123456,
            idPlant: "plant1",
            idPot: "pot1",
            isHanging: false,
            plantLevel: 1,
            platLevelExp: 0,
            position: "1,2"
        )

        plants.removeAll { $0.position == "1,2" }
        plants.append(newPlant)

        #expect(plants.count == 1)
        #expect(plants.first?.idPlant == "plant1")
        #expect(plants.first?.idPot == "pot1")
    }

    @Test func testRemovingPlantRemovesFromArray() async throws {
        var plants: [GardenModel.Plant] = [
            GardenModel.Plant(
                harvestTime: 0,
                idPlant: "plant1",
                idPot: "pot1",
                isHanging: false,
                plantLevel: 1,
                platLevelExp: 0,
                position: "1,2"
            ),
            GardenModel.Plant(
                harvestTime: 0,
                idPlant: "plant2",
                idPot: "pot2",
                isHanging: false,
                plantLevel: 1,
                platLevelExp: 0,
                position: "1,3"
            )
        ]

        plants.removeAll { $0.position == "1,2" }

        #expect(plants.count == 1)
        #expect(plants.first?.position == "1,3")
    }
}

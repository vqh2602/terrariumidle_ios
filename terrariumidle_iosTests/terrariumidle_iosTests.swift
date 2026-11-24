//
//  terrariumidle_iosTests.swift
//  terrariumidle_iosTests
//
//  Created by vương quang huy on 29/1/26.
//

import Testing
import SpriteKit
@testable import terrariumidle_ios

@MainActor
struct terrariumidle_iosTests {

    @Test func oxygenStartsOnHangingLeafInsteadOfInsideRopeFrame() {
        let plant = SKNode()
        let root = SKNode()
        root.position = CGPoint(x: 7, y: -90)
        root.setScale(0.4)
        plant.addChild(root)
        let leaf = SKSpriteNode(color: .green, size: CGSize(width: 100, height: 160))
        leaf.anchorPoint = CGPoint(x: 0.9, y: 0.05)
        leaf.zRotation = 0.3
        root.addChild(leaf)

        OxygenBubblesEffect().trigger(on: plant, containerSize: CGSize(width: 120, height: 180),
                                     level: 3, leaves: [leaf])

        #expect((8...12).contains(plant.children.filter { $0.name == "oxygenBubble" }.count))
        for bubble in plant.children where bubble.name == "oxygenBubble" {
            let point = leaf.convert(bubble.position, from: plant)
            #expect((-65 ... -15).contains(point.x))
            #expect((40 ... 120).contains(point.y))
            #expect(bubble.position.y < 0)
            #expect(bubble.parent === plant)
        }
    }

    @Test func oxygenRisesInSceneCoordinatesWhileHangingRigSwings() {
        let scene = SKScene(size: CGSize(width: 300, height: 500))
        let rig = SKNode()
        rig.zRotation = 0.25
        rig.xScale = 0.8
        rig.yScale = 1.2
        scene.addChild(rig)
        let plant = SKNode()
        plant.position = CGPoint(x: 12, y: -150)
        rig.addChild(plant)
        let offset = OxygenBubblesEffect.riseOffset(on: plant, distance: 100, drift: -20)
        let start = plant.convert(CGPoint.zero, to: scene)
        let end = plant.convert(CGPoint(x: offset.dx, y: offset.dy), to: scene)
        #expect(abs(end.y - start.y - 100) < 0.001)
        #expect(abs(end.x - start.x + 20) < 0.001)
    }

    @Test(arguments: [false, true])
    func slotMountDoesNotMoveWhenParticleRenderPaddingChanges(isHanging: Bool) throws {
        let slotSize = CGSize(width: 120, height: 234)
        let scene = TerrariumSlotScene(size: CGSize(width: 140, height: 374))
        scene.configure(potId: isHanging ? "pot16" : "pot1", plantId: "none",
                        isHanging: isHanging, slotSize: slotSize)
        let pot = try #require(scene.children.compactMap { $0 as? PotInteractiveNode }.first)
        let mount = try #require(pot.plantMountNode)
        let originalMount = mount.convert(CGPoint.zero, to: scene)
        let expectedHook = CGPoint(x: 0, y: isHanging ? slotSize.height : 0)
        #expect(pot.asNode.position == expectedHook)

        // Render space may grow without changing the pot's shelf or plant socket.
        scene.size = CGSize(width: 140, height: 434)
        let resizedPot = try #require(scene.children.compactMap { $0 as? PotInteractiveNode }.first)
        let resizedMount = try #require(resizedPot.plantMountNode)
        let newMount = resizedMount.convert(CGPoint.zero, to: scene)
        #expect(resizedPot.asNode.position == expectedHook)
        #expect(abs(newMount.x - originalMount.x) < 0.001)
        #expect(abs(newMount.y - originalMount.y) < 0.001)
    }

    @Test func wateringFeedbackOnlyEmitsOxygenAndPreservesIdleMotion() {
        let plant = AutoTapFeedbackPlant()
        let otherEffect = NonOxygenEffectSpy()
        plant.tapEffects = [OxygenBubblesEffect(theme: .floralPink), otherEffect]
        plant.position = CGPoint(x: 5, y: 12)
        plant.zRotation = 0.12
        plant.run(.repeatForever(.wait(forDuration: 1)), withKey: "idleSway")

        plant.playOxygenBubbles(containerSize: CGSize(width: 120, height: 180), level: 3)

        #expect((8...12).contains(plant.children.count))
        #expect(plant.children.allSatisfy { $0 is SKShapeNode && $0.zPosition == 200 })
        #expect(otherEffect.triggerCount == 0)
        #expect(plant.tapCount == 0)
        #expect(plant.action(forKey: "idleSway") != nil)
        #expect(plant.position == CGPoint(x: 5, y: 12))
        #expect(plant.zRotation == 0.12)
    }

    private func wateringGarden(diamonds: Int) throws -> GardenModel {
        try GardenModel(dict: [
            "money": ["gemstone": diamonds], "user": [:] as [String: Any],
            "item": [:] as [String: Any], "cart": [:] as [String: Any],
            "plants": [
                ["idPlant": "plant1", "idPot": "pot1", "position": "0,0"],
                ["idPlant": "plant2", "idPot": "pot2", "position": "0,1"]
            ]
        ])
    }

    @Test func wateringChargesTenDiamondsForOnlySelectedPlant() throws {
        var garden = try wateringGarden(diamonds: 10)
        #expect(garden.waterPlant(at: "0,1", plantId: "plant2", now: 100) == .watered)
        #expect(garden.money.gemstone == 0)
        #expect(garden.plants[0].wateringUntil == 0)
        #expect(garden.plants[1].wateringUntil == 160)
        let restored = try GardenModel(dict: garden.toDictionary())
        #expect(restored.plants[1].wateringUntil == 160)
    }

    @Test func wateringRejectsInsufficientFundsAndInvalidTargets() throws {
        var garden = try wateringGarden(diamonds: 9)
        #expect(garden.waterPlant(at: "0,0", plantId: "plant1", now: 100) == .insufficientDiamonds)
        #expect(garden.money.gemstone == 9)
        #expect(garden.plants[0].wateringUntil == 0)
        garden.money.gemstone = 20
        #expect(garden.waterPlant(at: "0,0", plantId: "plant2", now: 100) == .invalidPlant)
        garden.plants[0].idPlant = "sticker1"
        #expect(garden.waterPlant(at: "0,0", plantId: "sticker1", now: 100) == .invalidPlant)
        #expect(garden.money.gemstone == 20)
    }

    @Test func wateringCannotChargeAgainUntilSixtySecondsExpire() throws {
        var garden = try wateringGarden(diamonds: 30)
        #expect(garden.waterPlant(at: "0,0", plantId: "plant1", now: 100) == .watered)
        #expect(garden.waterPlant(at: "0,0", plantId: "plant1", now: 159.99) == .alreadyWatering)
        #expect(garden.money.gemstone == 20)
        #expect(garden.plants[0].wateringUntil == 160)
        garden.plants[0].plantLevel += 1
        garden.plants[0].position = "1,2"
        #expect(garden.plants[0].wateringUntil == 160)
        #expect(garden.waterPlant(at: "1,2", plantId: "plant1", now: 160) == .watered)
        #expect(garden.money.gemstone == 10)
        #expect(garden.plants[0].wateringUntil == 220)
    }

    @Test func rainChargesOneTicketAndPersistsSixtySecondDeadline() throws {
        var garden = try wateringGarden(diamonds: 10)
        garden.money.ticket = 2
        #expect(garden.weatherUntil == 0)
        #expect(garden.startWeather(.rain, now: 100) == .started)
        #expect(garden.money.ticket == 1)
        #expect(garden.money.gemstone == 10)
        #expect(garden.weatherUntil == 160)
        let restored = try GardenModel(dict: garden.toDictionary())
        #expect(restored.weatherUntil == 160)
        #expect(restored.money.ticket == 1)
        #expect(garden.startWeather(.rain, now: 159.99) == .alreadyActive)
        #expect(garden.money.ticket == 1)
        #expect(garden.startWeather(.rain, now: 160) == .started)
        #expect(garden.money.ticket == 0)
        #expect(garden.weatherUntil == 220)
    }

    @Test func rainRejectsMissingTicketsAndEmptyGardensWithoutCharging() throws {
        var garden = try wateringGarden(diamonds: 10)
        #expect(garden.startWeather(.rain, now: 100) == .insufficientTickets)
        #expect(garden.weatherUntil == 0)
        garden.money.ticket = 1
        garden.plants.removeAll()
        #expect(garden.startWeather(.rain, now: 100) == .noPlants)
        #expect(garden.money.ticket == 1)
        #expect(garden.weatherUntil == 0)
    }

    @Test func rainIncludesAllFloorsButExcludesStickersEmptyAndDuplicateSockets() throws {
        var garden = try wateringGarden(diamonds: 10)
        var highFloor = garden.plants[0]
        highFloor.position = "20,1"
        garden.plants.append(highFloor)
        garden.plants.append(highFloor)
        var sticker = highFloor
        sticker.position = "2,2"
        sticker.idPlant = "sticker1"
        sticker.idPot = "sticker1"
        garden.plants.append(sticker)
        var empty = highFloor
        empty.position = "2,3"
        empty.idPot = ""
        garden.plants.append(empty)
        #expect(Set(garden.weatherPlants.map(\.position)) == ["0,0", "0,1", "20,1"])
        #expect(garden.weatherPlants.count == 3)
    }

    @Test func rainPreservesExistingWateringAndPreventsExtraDiamondCharge() throws {
        var garden = try wateringGarden(diamonds: 20)
        garden.money.ticket = 1
        #expect(garden.waterPlant(at: "0,0", plantId: "plant1", now: 90) == .watered)
        #expect(garden.startWeather(.rain, now: 100) == .started)
        #expect(garden.plants[0].wateringUntil == 150)
        #expect(garden.waterPlant(at: "0,1", plantId: "plant2", now: 120) == .alreadyWatering)
        #expect(garden.money.gemstone == 10)
        #expect(garden.waterPlant(at: "0,1", plantId: "plant2", now: 160) == .watered)
    }

    @Test func windUsesOneTicketAndSameSixtySecondWeatherSession() throws {
        var garden = try wateringGarden(diamonds: 20)
        garden.money.ticket = 2
        #expect(garden.startWeather(.wind, now: 100) == .started)
        #expect(garden.weatherKind == .wind)
        #expect(garden.weatherUntil == 160)
        #expect(garden.money.ticket == 1)
        #expect(garden.weatherPlants.count == 2)
        #expect(garden.startWeather(.rain, now: 120) == .alreadyActive)
        #expect(garden.startWeather(.wind, now: 120) == .alreadyActive)
        #expect(garden.money.ticket == 1)
        #expect(garden.waterPlant(at: "0,0", plantId: "plant1", now: 120) == .alreadyWatering)
        #expect(garden.money.gemstone == 20)
        let restored = try GardenModel(dict: garden.toDictionary())
        #expect(restored.weatherKind == .wind)
        #expect(restored.weatherUntil == 160)
        #expect(garden.startWeather(.rain, now: 160) == .started)
        #expect(garden.weatherKind == .rain)
        #expect(garden.weatherUntil == 220)
        #expect(garden.money.ticket == 0)
    }

    @Test func windRejectsInsufficientTicketsAndEmptyGarden() throws {
        var garden = try wateringGarden(diamonds: 20)
        #expect(garden.startWeather(.wind, now: 100) == .insufficientTickets)
        #expect(garden.weatherUntil == 0)
        garden.money.ticket = 1
        garden.plants.removeAll()
        #expect(garden.startWeather(.wind, now: 100) == .noPlants)
        #expect(garden.money.ticket == 1)
        #expect(garden.weatherUntil == 0)
    }

    @Test func weatherRestoresLegacyRainSession() throws {
        let garden = try wateringGarden(diamonds: 10)
        var data = garden.toDictionary()
        data.removeValue(forKey: "weatherUntil")
        data.removeValue(forKey: "weatherKind")
        data["rainUntil"] = 160.0
        let restored = try GardenModel(dict: data)
        #expect(restored.weatherKind == .rain)
        #expect(restored.weatherUntil == 160)
        data["weatherUntil"] = 220.0
        data["weatherKind"] = "wind"
        let updated = try GardenModel(dict: data)
        #expect(updated.weatherKind == .wind)
        #expect(updated.weatherUntil == 220)
    }

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

    @Test func testPots4To7Data() async throws {
        let pot4 = ItemDataManager.shared.getPot(byId: "pot4")
        #expect(pot4 != nil)
        #expect(pot4?.image == "Pot4@4.167x")
        #expect(pot4?.effect == "Trái tim nhịp đập")

        let pot5 = ItemDataManager.shared.getPot(byId: "pot5")
        #expect(pot5 != nil)
        #expect(pot5?.image == "pot5@4.167x")

        let pot6 = ItemDataManager.shared.getPot(byId: "pot6")
        #expect(pot6 != nil)
        #expect(pot6?.image == "Pot6@4.167x")
        #expect(pot6?.effect == "Tam thạch anh hồng")

        let pot7 = ItemDataManager.shared.getPot(byId: "pot7")
        #expect(pot7 != nil)
        #expect(pot7?.image == "Pot7@4.167x")
    }
}

private final class AutoTapFeedbackPlant: SKNode, PlantInteractiveNode {
    var motionEffect: PlantMotionEffect = StandardPlantBounceMotionEffect()
    var tapEffects: [PlantTapEffect] = []
    var tapCount = 0

    func playTapAnimation() { tapCount += 1 }
}

private final class NonOxygenEffectSpy: PlantTapEffect {
    let name = "NonOxygenEffectSpy"
    var triggerCount = 0

    func trigger(on plantNode: SKNode, containerSize: CGSize, level: Int, leaves: [SKNode]) {
        triggerCount += 1
    }
}

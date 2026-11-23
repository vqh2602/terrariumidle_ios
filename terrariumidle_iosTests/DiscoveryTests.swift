import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct DiscoveryTests {
    private func data(name: String = "Khách", floors: Any = 2, plants: [Any] = []) -> [String: Any] {
        ["user": ["userID": "untrusted-id", "userName": name, "userFloor": floors,
                  "userLevel": "50", "userTotalLike": "12", "userEmail": "private@example.com"],
         "money": ["oxygen": 999999], "cart": ["cartPlants": ["plant19"]], "plants": plants]
    }

    private func plant(_ position: String, id: String = "plant1", pot: String = "pot1", level: Any = 3) -> [String: Any] {
        ["position": position, "idPlant": id, "idPot": pot, "plantLevel": level, "isHanging": "true"]
    }

    @Test func visitorSnapshotUsesDocumentIdentityAndOnlyPublicData() throws {
        let original = data(plants: [plant("1,2")])
        let before = NSDictionary(dictionary: original)
        let garden = try VisitorGarden(documentID: "visitor", data: original)
        #expect(garden.profile.id == "visitor")
        #expect(garden.profile.level == 50)
        #expect(garden.profile.likes == 12)
        #expect(garden.slot(row: 1, column: 2)?.isHanging == true)
        #expect(NSDictionary(dictionary: original).isEqual(before))
        #expect(Set(Mirror(reflecting: garden).children.compactMap(\.label)) == ["profile", "topFloor", "slots"])
        var banned = original
        banned["isBan"] = true
        #expect(throws: DiscoveryError.self) { try VisitorGarden(documentID: "visitor", data: banned) }
        #expect(throws: DiscoveryError.self) { try VisitorGarden(documentID: "visitor", data: [:]) }
    }

    @Test func malformedSlotsAndFloorsCannotCrashOrDisplaceValidPlants() throws {
        let garden = try VisitorGarden(documentID: "visitor", data: data(floors: Int.max, plants: [
            plant("1,2", level: 5), plant("1,2", id: "", level: 10), plant("1,2", level: 3),
            plant("1,2,3"), plant("-1,2"), plant("1,4"), plant("999999,1"), plant("bad"),
            plant("0,1", id: "sticker1", pot: "sticker1", level: -5),
            plant("3,3", id: "plant26", level: 999999), "malformed"
        ]))
        #expect(garden.topFloor == VisitorGarden.maximumFloor)
        #expect(garden.slots.count == 3)
        #expect(garden.slot(row: 1, column: 2)?.level == 5)
        #expect(garden.slot(row: 0, column: 1)?.isSticker == true)
        #expect(garden.slot(row: 0, column: 1)?.level == 1)
        #expect(garden.slot(row: 3, column: 3)?.level == 10)
        let empty = try VisitorGarden(documentID: "empty", data: data(floors: -10))
        #expect(empty.topFloor == 0)
        #expect(empty.slots.isEmpty)
    }

    @Test func listingExcludesOwnerAndDeduplicatesAcrossPages() async throws {
        let repository = FakeDiscoveryRepository()
        let owner = try #require(DiscoveredProfile(documentID: "owner", data: data()))
        let other = try #require(DiscoveredProfile(documentID: "other", data: data()))
        let next = try #require(DiscoveredProfile(documentID: "next", data: data()))
        repository.pages = [DiscoveryPage(profiles: [owner, other, other], nextCursor: "cursor"),
                            DiscoveryPage(profiles: [other, next], nextCursor: nil)]
        let model = DiscoveryViewModel(repository: repository, ownID: "owner")
        await model.load()
        #expect(model.profiles.map(\.id) == ["other"])
        await model.load(more: true)
        #expect(model.profiles.map(\.id) == ["other", "next"])
        #expect(repository.cursors == [nil, "cursor"])
        #expect(model.nextCursor == nil)
        #expect(!model.isLoading)
    }

    @Test func searchAndFailuresStayLocalToDiscovery() async throws {
        let repository = FakeDiscoveryRepository()
        repository.snapshot = try VisitorGarden(documentID: "visitor", data: data())
        let model = DiscoveryViewModel(repository: repository, ownID: "owner")
        model.searchID = "  visitor  "
        model.search()
        await model.load()
        #expect(repository.requestedIDs == ["visitor"])
        #expect(model.profiles.map(\.id) == ["visitor"])
        repository.shouldFail = true
        model.resetSearch()
        await model.load()
        #expect(model.error != nil)
        #expect(!model.isLoading)
        #expect(model.profiles.isEmpty)
        let visitor = VisitorGardenViewModel(repository: repository)
        await visitor.load(id: "missing")
        #expect(visitor.garden == nil)
        #expect(visitor.error != nil)
    }

    @Test func lateVisitorResponseCannotReplaceNewerGarden() async throws {
        let repository = FakeDiscoveryRepository()
        repository.snapshot = try VisitorGarden(documentID: "new", data: data(name: "Mới"))
        repository.suspendOldRequest = true
        let model = VisitorGardenViewModel(repository: repository)
        let oldTask = Task { await model.load(id: "old") }
        while repository.pending == nil { await Task.yield() }
        await model.load(id: "new")
        repository.pending?.resume(returning: try VisitorGarden(documentID: "old", data: data(name: "Cũ")))
        await oldTask.value
        #expect(model.garden?.profile.id == "new")
        #expect(model.error == nil)
        #expect(!model.isLoading)
    }

    @Test func cancelledVisitDoesNotPublishSnapshot() async throws {
        let repository = FakeDiscoveryRepository()
        repository.suspendOldRequest = true
        let model = VisitorGardenViewModel(repository: repository)
        let task = Task { await model.load(id: "old") }
        while repository.pending == nil { await Task.yield() }
        task.cancel()
        repository.pending?.resume(returning: try VisitorGarden(documentID: "old", data: data()))
        await task.value
        #expect(model.garden == nil)
        #expect(model.error == nil)
        #expect(!model.isLoading)
    }
}

@MainActor
private final class FakeDiscoveryRepository: DiscoveryReading {
    var pages: [DiscoveryPage] = []
    var snapshot: VisitorGarden?
    var shouldFail = false
    var suspendOldRequest = false
    var pending: CheckedContinuation<VisitorGarden, Error>?
    var cursors: [String?] = []
    var requestedIDs: [String] = []

    func profiles(category: DiscoveryCategory, after cursor: String?) async throws -> DiscoveryPage {
        cursors.append(cursor)
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return pages.isEmpty ? DiscoveryPage(profiles: [], nextCursor: nil) : pages.removeFirst()
    }

    func garden(id: String) async throws -> VisitorGarden {
        requestedIDs.append(id)
        if suspendOldRequest && id == "old" {
            return try await withCheckedThrowingContinuation { pending = $0 }
        }
        if shouldFail { throw URLError(.notConnectedToInternet) }
        guard let snapshot else { throw DiscoveryError.unavailable }
        return snapshot
    }
}

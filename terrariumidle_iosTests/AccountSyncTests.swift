import Foundation
import Testing
@testable import terrariumidle_ios

@MainActor
struct AccountSyncTests {
    @Test func manualSyncSuccessSetsSuccessAlert() async {
        var syncedUserId: String?
        let vm = AccountViewModel(
            userIdProvider: { "user-123" },
            syncHandler: { userId in
                syncedUserId = userId
            }
        )

        await vm.performSyncData()

        #expect(syncedUserId == "user-123")
        #expect(!vm.isSyncingData)
        #expect(vm.syncAlertStatus == .success)
    }

    @Test func manualSyncFailureSetsFailureAlert() async {
        let vm = AccountViewModel(
            userIdProvider: { "user-123" },
            syncHandler: { _ in
                throw URLError(.notConnectedToInternet)
            }
        )

        await vm.performSyncData()

        #expect(!vm.isSyncingData)
        if case .failure(let message) = vm.syncAlertStatus {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected failure syncAlertStatus")
        }
    }

    @Test func manualSyncWithoutUserSetsFailureAlert() async {
        let vm = AccountViewModel(
            userIdProvider: { nil },
            syncHandler: { _ in
                Issue.record("syncHandler should not be called without a userId")
            }
        )

        await vm.performSyncData()

        #expect(!vm.isSyncingData)
        if case .failure = vm.syncAlertStatus {
            #expect(true)
        } else {
            Issue.record("Expected failure syncAlertStatus when user is missing")
        }
    }
}

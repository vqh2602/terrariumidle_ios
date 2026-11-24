import Foundation

/// Keep garden snapshot writes ordered with reward transactions on this device.
@MainActor
final class GardenWriteQueue {
    static let shared = GardenWriteQueue()
    private var tail: Task<Void, Never>?

    func perform<T>(_ operation: @escaping @MainActor () async throws -> T) async throws -> T {
        let previous = tail
        let work = Task {
            await previous?.value
            return try await operation()
        }
        tail = Task { _ = try? await work.value }
        return try await work.value
    }
}

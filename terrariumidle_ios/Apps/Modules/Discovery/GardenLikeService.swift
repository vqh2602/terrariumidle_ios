import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
protocol GardenLiking {
    var viewerID: String? { get }
    func hasLiked(gardenID: String) -> Bool
    func like(gardenID: String) async throws -> Int
}

enum GardenLikeError: LocalizedError {
    case signInRequired, ownGarden, alreadyLiked, unavailable, saveFailed
    var errorDescription: String? {
        switch self {
        case .signInRequired: return "Vui lòng đăng nhập để gửi lượt thích.".tr
        case .ownGarden: return "Bạn không thể thích khu vườn của chính mình.".tr
        case .alreadyLiked: return "Bạn đã gửi trái tim cho khu vườn này rồi.".tr
        case .unavailable: return "Khu vườn hiện không thể nhận lượt thích.".tr
        case .saveFailed: return "Chưa gửi được lượt thích. Vui lòng thử lại.".tr
        }
    }
}

/// The only visitor write: atomically update user.userTotalLike on the target.
/// Never publish a visitor snapshot into FireStoreService or save a full garden.
@MainActor
final class GardenLikeService: GardenLiking {
    static let shared = GardenLikeService()
    private let db = Firestore.firestore()
    private let defaults = UserDefaults.standard
    private var inFlight: Set<String> = []
    var viewerID: String? { AuthService.shared.currentUser?.uid }

    private init() { GardenLikeReporter.shared.retryPending() }

    func hasLiked(gardenID: String) -> Bool {
        guard let viewerID else { return false }
        GardenLikeReporter.shared.retryPending()
        return (defaults.stringArray(forKey: "garden.likes.\(viewerID)") ?? []).contains(gardenID)
    }

    func like(gardenID: String) async throws -> Int {
        guard let viewerID else { throw GardenLikeError.signInRequired }
        guard viewerID != gardenID else { throw GardenLikeError.ownGarden }
        guard !gardenID.isEmpty, !gardenID.contains("/"), gardenID != ".", gardenID != "..",
              gardenID.utf8.count <= 1500 else { throw GardenLikeError.unavailable }
        let key = "\(viewerID)/\(gardenID)"
        guard !hasLiked(gardenID: gardenID), inFlight.insert(key).inserted else { throw GardenLikeError.alreadyLiked }
        defer { inFlight.remove(key) }
        let target = db.collection("users").document(gardenID)
        let result: Any?
        do {
            result = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(target)
                    guard let data = snapshot.data(),
                          let user = data["user"] as? [String: Any] else { throw GardenLikeError.unavailable }
                    let banned = (data["isBan"] as? NSNumber)?.boolValue == true ||
                        ["true", "1"].contains(data["isBan"] as? String ?? "")
                    guard !banned else { throw GardenLikeError.unavailable }
                    // Support legacy numeric strings without resetting their accumulated likes.
                    let current = max(0, (user["userTotalLike"] as? NSNumber)?.intValue ??
                                      Int(user["userTotalLike"] as? String ?? "") ?? 0)
                    guard current < Int.max else { throw GardenLikeError.unavailable }
                    let total = current + 1
                    transaction.updateData(["user.userTotalLike": total], forDocument: target)
                    return NSNumber(value: total)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch {
            throw GardenLikeError.saveFailed
        }
        guard let total = (result as? NSNumber)?.intValue else { throw GardenLikeError.saveFailed }
        // Record and enqueue only after the transaction succeeds. Discord retries never add another like.
        let receiptKey = "garden.likes.\(viewerID)"
        var liked = Set(defaults.stringArray(forKey: receiptKey) ?? [])
        liked.insert(gardenID)
        defaults.set(Array(liked), forKey: receiptKey)
        GardenLikeReporter.shared.enqueue(viewerID: viewerID, gardenID: gardenID, total: total)
        return total
    }
}

import Combine
import FirebaseAuth
import Foundation
import StoreKit
import UIKit

enum VIPPlanKind: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { productId }

    var productId: String {
        switch self {
        case .monthly: return SubscriptionManager.monthlyProductId
        case .yearly: return SubscriptionManager.yearlyProductId
        }
    }

    var title: String {
        switch self {
        case .monthly: return "Gói Tháng".tr
        case .yearly: return "Gói Năm".tr
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Gia hạn mỗi tháng · Linh hoạt".tr
        case .yearly: return "Tiết kiệm 32% · Dùng thử 7 ngày".tr
        }
    }

    var fallbackPrice: String {
        switch self {
        case .monthly: return "49.000đ / tháng".tr
        case .yearly: return "399.000đ / năm".tr
        }
    }

    var badge: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "TIẾT KIỆM NHẤT".tr
        }
    }
}

enum VIPWelcomeBonus {
    static let gemstone = 50
    static let ticket = 3
    static let fertilizer = 10
    static let shovel = 5
}

extension Notification.Name {
    static let terrariumVIPDidChange = Notification.Name("terrariumVIPDidChange")
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    static let monthlyProductId = "vqhapp.terrariumidle_ios.vip.monthly"
    static let yearlyProductId = "vqhapp.terrariumidle_ios.vip.yearly"
    static let allProductIds: [String] = [monthlyProductId, yearlyProductId]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isVIP = false
    @Published private(set) var activeProductId: String?
    @Published private(set) var expirationDate: Date?
    @Published private(set) var willAutoRenew = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    private init() {}

    deinit {
        updatesTask?.cancel()
    }

    /// Checks whether the user currently has VIP access from either verified StoreKit entitlements
    /// or a valid persisted VIP status in Firestore.
    static func isVIP(gardenModel: GardenModel?) -> Bool {
        if shared.isVIP {
            return true
        }
        return gardenModel?.vipStatus.isCurrentlyActive == true
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        updatesTask = Task { [weak self] in
            for await verificationResult in Transaction.updates {
                guard let self else { break }
                await self.handleTransactionUpdate(verificationResult)
            }
        }

        Task { [weak self] in
            guard let self else { return }
            await self.loadProducts()
            await self.refreshEntitlements()
        }
    }

    func product(for plan: VIPPlanKind) -> Product? {
        products.first { $0.id == plan.productId }
    }

    func displayPrice(for plan: VIPPlanKind) -> String {
        guard let product = product(for: plan) else {
            return plan.fallbackPrice
        }
        switch plan {
        case .monthly:
            return "%@ / tháng".tr(product.displayPrice)
        case .yearly:
            return "%@ / năm".tr(product.displayPrice)
        }
    }

    func monthlyEquivalentText(for plan: VIPPlanKind) -> String? {
        guard plan == .yearly, let product = product(for: .yearly) else { return nil }
        let monthly = product.price / 12
        let formatted = monthly.formatted(product.priceFormatStyle)
        return "Chỉ khoảng %@ / tháng".tr(formatted)
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: Self.allProductIds)
            products = loaded.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
        } catch {
            print("⚠️ StoreKit loadProducts failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func purchase(_ plan: VIPPlanKind) async -> Bool {
        guard !isPurchasing else { return false }
        errorMessage = nil
        statusMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        if product(for: plan) == nil {
            await loadProducts()
        }

        guard let product = product(for: plan) else {
            errorMessage = "Chưa tải được gói từ App Store. Vui lòng kiểm tra cấu hình StoreKit hoặc thử lại sau.".tr
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
                statusMessage = "Chào mừng bạn gia nhập Terrarium VIP!".tr
                return true
            case .userCancelled:
                return false
            case .pending:
                statusMessage = "Giao dịch đang chờ xác nhận từ App Store.".tr
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Không thể hoàn tất đăng ký: %@".tr(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        guard !isPurchasing else { return false }
        errorMessage = nil
        statusMessage = nil
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if isVIP {
                statusMessage = "Đã khôi phục quyền lợi Terrarium VIP thành công!".tr
                return true
            } else {
                statusMessage = "Không tìm thấy gói VIP đang hoạt động trên Apple ID này.".tr
                return false
            }
        } catch {
            errorMessage = "Khôi phục giao dịch thất bại: %@".tr(error.localizedDescription)
            return false
        }
    }

    func manageSubscriptions() async {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            errorMessage = "Không mở được trang quản lý đăng ký App Store.".tr
        }
    }

    func refreshEntitlements() async {
        var latestTransaction: StoreKit.Transaction?

        for await verificationResult in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(verificationResult),
                  Self.allProductIds.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }
            if let exp = transaction.expirationDate, exp <= Date() {
                continue
            }
            if let current = latestTransaction {
                let currentExp = current.expirationDate ?? .distantFuture
                let newExp = transaction.expirationDate ?? .distantFuture
                if newExp > currentExp {
                    latestTransaction = transaction
                }
            } else {
                latestTransaction = transaction
            }
        }

        if let transaction = latestTransaction {
            let willRenew = await checkAutoRenewStatus(for: transaction.productID)
            applyEntitlement(
                isActive: true,
                productId: transaction.productID,
                expirationDate: transaction.expirationDate,
                willAutoRenew: willRenew
            )
            await syncToFirestore(
                isActive: true,
                productId: transaction.productID,
                expiresAt: transaction.expirationDate?.timeIntervalSince1970 ?? 0,
                willAutoRenew: willRenew
            )
        } else {
            let previousStoreKitVIP = isVIP
            applyEntitlement(isActive: false, productId: nil, expirationDate: nil, willAutoRenew: false)
            if previousStoreKitVIP || FireStoreService.shared.gradenModel?.vipStatus.source == "appstore" {
                await syncToFirestore(isActive: false, productId: nil, expiresAt: 0, willAutoRenew: false)
            }
        }
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<StoreKit.Transaction>) async {
        guard let transaction = try? checkVerified(verificationResult) else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func checkAutoRenewStatus(for productID: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productID }),
              let subscription = product.subscription else {
            return false
        }
        guard let statuses = try? await subscription.status else {
            return false
        }
        for status in statuses where status.state == .subscribed || status.state == .inGracePeriod {
            if case .verified(let renewalInfo) = status.renewalInfo {
                return renewalInfo.willAutoRenew
            }
        }
        return false
    }

    private func applyEntitlement(
        isActive: Bool,
        productId: String?,
        expirationDate: Date?,
        willAutoRenew: Bool
    ) {
        let changed = (self.isVIP != isActive) || (self.activeProductId != productId)
        self.isVIP = isActive
        self.activeProductId = productId
        self.expirationDate = expirationDate
        self.willAutoRenew = willAutoRenew
        if changed {
            NotificationCenter.default.post(name: .terrariumVIPDidChange, object: nil)
        }
    }

    private func syncToFirestore(
        isActive: Bool,
        productId: String?,
        expiresAt: TimeInterval,
        willAutoRenew: Bool
    ) async {
        guard AuthService.shared.currentUser?.uid != nil else { return }
        await FireStoreService.shared.syncVIPStatus(
            isActive: isActive,
            productId: productId,
            expiresAt: expiresAt,
            willAutoRenew: willAutoRenew,
            source: "appstore"
        )
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

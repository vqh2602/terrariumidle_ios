import Combine
import FirebaseAuth
import Foundation
import StoreKit

enum GemPackageKind: String, CaseIterable, Identifiable {
    case pack1000
    case pack5000
    case pack10000

    var id: String { productId }

    var productId: String {
        switch self {
        case .pack1000: return GemStoreManager.pack1000ProductId
        case .pack5000: return GemStoreManager.pack5000ProductId
        case .pack10000: return GemStoreManager.pack10000ProductId
        }
    }

    var gemAmount: Int {
        switch self {
        case .pack1000: return 1_000
        case .pack5000: return 5_000
        case .pack10000: return 10_000
        }
    }

    var title: String {
        switch self {
        case .pack1000: return "1.000 Đá quý".tr
        case .pack5000: return "5.000 Đá quý".tr
        case .pack10000: return "10.000 Đá quý".tr
        }
    }

    var subtitle: String {
        switch self {
        case .pack1000:
            return "Đủ mua cây hiếm, chậu đá hoặc 100× Xẻng".tr
        case .pack5000:
            return "Thoải mái sưu tầm cây, chậu & nâng cấp vườn".tr
        case .pack10000:
            return "Kho báu đá quý cho người chơi sưu tầm toàn diện".tr
        }
    }

    var fallbackPrice: String {
        switch self {
        case .pack1000: return "29.000đ".tr
        case .pack5000: return "119.000đ".tr
        case .pack10000: return "199.000đ".tr
        }
    }

    var fallbackOriginalPrice: String? {
        switch self {
        case .pack1000: return nil
        case .pack5000: return "145.000đ".tr
        case .pack10000: return "290.000đ".tr
        }
    }

    var fallbackDiscountPercent: Int {
        switch self {
        case .pack1000: return 0
        case .pack5000: return 18
        case .pack10000: return 31
        }
    }

    var fallbackUnitPriceText: String {
        switch self {
        case .pack1000: return "29.000đ / 1.000 đá quý".tr
        case .pack5000: return "23.800đ / 1.000 đá quý".tr
        case .pack10000: return "19.900đ / 1.000 đá quý".tr
        }
    }

    var fallbackSavingsText: String? {
        switch self {
        case .pack1000: return nil
        case .pack5000: return "Tiết kiệm 26.000đ".tr
        case .pack10000: return "Tiết kiệm 91.000đ".tr
        }
    }

    var isPopular: Bool { self == .pack5000 }
    var isBestValue: Bool { self == .pack10000 }
}

@MainActor
final class GemStoreManager: ObservableObject {
    static let shared = GemStoreManager()

    static let pack1000ProductId = "vqhapp.terrariumidle_ios.gem.1000"
    static let pack5000ProductId = "vqhapp.terrariumidle_ios.gem.5000"
    static let pack10000ProductId = "vqhapp.terrariumidle_ios.gem.10000"
    static let allProductIds: [String] = [
        pack1000ProductId,
        pack5000ProductId,
        pack10000ProductId,
    ]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchasingProductId: String?
    @Published var statusMessage: String?
    @Published var errorMessage: String?
    @Published var lastPurchasedGems: Int?

    var isPurchasing: Bool { purchasingProductId != nil }

    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false

    private init() {}

    deinit {
        updatesTask?.cancel()
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
            await self.processUnfinishedTransactions()
        }
    }

    func product(for package: GemPackageKind) -> Product? {
        products.first { $0.id == package.productId }
    }

    func package(for productId: String) -> GemPackageKind? {
        GemPackageKind.allCases.first { $0.productId == productId }
    }

    func displayPrice(for package: GemPackageKind) -> String {
        product(for: package)?.displayPrice ?? package.fallbackPrice
    }

    func discountPercent(for package: GemPackageKind) -> Int {
        guard package != .pack1000,
              let baseProduct = product(for: .pack1000),
              let targetProduct = product(for: package),
              baseProduct.price > 0 else {
            return package.fallbackDiscountPercent
        }
        let multiplier = Decimal(package.gemAmount) / Decimal(GemPackageKind.pack1000.gemAmount)
        let originalPrice = baseProduct.price * multiplier
        guard originalPrice > targetProduct.price, originalPrice > 0 else { return 0 }
        let ratio = ((originalPrice - targetProduct.price) / originalPrice) * 100
        return NSDecimalNumber(decimal: ratio).rounding(accordingToBehavior: nil).intValue
    }

    func originalDisplayPrice(for package: GemPackageKind) -> String? {
        guard package != .pack1000 else { return nil }
        guard let baseProduct = product(for: .pack1000),
              let targetProduct = product(for: package) else {
            return package.fallbackOriginalPrice
        }
        let multiplier = Decimal(package.gemAmount) / Decimal(GemPackageKind.pack1000.gemAmount)
        let originalPrice = baseProduct.price * multiplier
        guard originalPrice > targetProduct.price else { return nil }
        return originalPrice.formatted(targetProduct.priceFormatStyle)
    }

    func savingsText(for package: GemPackageKind) -> String? {
        guard package != .pack1000 else { return nil }
        guard let baseProduct = product(for: .pack1000),
              let targetProduct = product(for: package) else {
            return package.fallbackSavingsText
        }
        let multiplier = Decimal(package.gemAmount) / Decimal(GemPackageKind.pack1000.gemAmount)
        let originalPrice = baseProduct.price * multiplier
        let savings = originalPrice - targetProduct.price
        guard savings > 0 else { return nil }
        return "Tiết kiệm %@".tr(savings.formatted(targetProduct.priceFormatStyle))
    }

    func unitPriceText(for package: GemPackageKind) -> String {
        guard let targetProduct = product(for: package) else {
            return package.fallbackUnitPriceText
        }
        let perThousand = (targetProduct.price / Decimal(package.gemAmount)) * 1000
        return "%@ / 1.000 đá quý".tr(perThousand.formatted(targetProduct.priceFormatStyle))
    }

    func badgeText(for package: GemPackageKind) -> String? {
        let discount = discountPercent(for: package)
        if package.isBestValue {
            return discount > 0 ? "ƯU ĐÃI TỐT NHẤT · -%d%%".tr(discount) : "ƯU ĐÃI TỐT NHẤT".tr
        }
        if package.isPopular {
            return discount > 0 ? "PHỔ BIẾN · -%d%%".tr(discount) : "PHỔ BIẾN".tr
        }
        return nil
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
            print("⚠️ GemStore loadProducts failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func purchase(_ package: GemPackageKind) async -> Bool {
        guard !isPurchasing else { return false }
        errorMessage = nil
        statusMessage = nil
        lastPurchasedGems = nil

        guard let uid = AuthService.shared.currentUser?.uid, !uid.isEmpty else {
            errorMessage = "Vui lòng đăng nhập tài khoản trước khi mua Đá quý.".tr
            return false
        }

        purchasingProductId = package.productId
        defer { purchasingProductId = nil }

        if product(for: package) == nil {
            await loadProducts()
        }

        guard let product = product(for: package) else {
            errorMessage = "Chưa tải được gói Đá quý từ App Store. Vui lòng thử lại sau.".tr
            return false
        }

        do {
            let purchaseOptions: Set<Product.PurchaseOption> = [
                .appAccountToken(SubscriptionManager.appAccountToken(for: uid))
            ]
            let result = try await product.purchase(options: purchaseOptions)
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                let credited = await deliverTransaction(transaction)
                if credited {
                    lastPurchasedGems = package.gemAmount
                    statusMessage = "Đã cộng +%@ Đá quý vào khu vườn của bạn!".tr(package.gemAmount.formatted())
                }
                return credited
            case .userCancelled:
                return false
            case .pending:
                statusMessage = "Giao dịch đang chờ xác nhận từ App Store.".tr
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Không thể hoàn tất giao dịch: %@".tr(error.localizedDescription)
            return false
        }
    }

    func processUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            guard let transaction = try? checkVerified(verificationResult),
                  Self.allProductIds.contains(transaction.productID) else {
                continue
            }
            _ = await deliverTransaction(transaction)
        }
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<StoreKit.Transaction>) async {
        guard let transaction = try? checkVerified(verificationResult),
              Self.allProductIds.contains(transaction.productID) else {
            return
        }
        _ = await deliverTransaction(transaction)
    }

    @discardableResult
    private func deliverTransaction(_ transaction: StoreKit.Transaction) async -> Bool {
        guard let package = package(for: transaction.productID) else {
            return false
        }
        guard transaction.revocationDate == nil else {
            await transaction.finish()
            return false
        }
        guard let currentUID = AuthService.shared.currentUser?.uid, !currentUID.isEmpty else {
            return false
        }
        if let token = transaction.appAccountToken, token != SubscriptionManager.appAccountToken(for: currentUID) {
            return false
        }

        do {
            _ = try await FireStoreService.shared.creditPurchasedGems(
                amount: package.gemAmount,
                transactionId: String(transaction.id),
                productId: transaction.productID
            )
            await transaction.finish()
            return true
        } catch {
            errorMessage = "Thanh toán đã xác nhận nhưng chưa đồng bộ được Đá quý. Hệ thống sẽ tự thử lại.".tr
            return false
        }
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

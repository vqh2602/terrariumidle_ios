import SwiftUI

struct GemStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var gemStore = GemStoreManager.shared
    @ObservedObject private var fireStore = FireStoreService.shared

    var isSheet: Bool = false

    private var currentGems: Int {
        fireStore.gradenModel?.money.gemstone ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 18) {
                    heroCard
                    GemPackagesSection()
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            LinearGradient(
                colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .task {
            if gemStore.products.isEmpty {
                await gemStore.loadProducts()
            }
        }
    }

    private var topBar: some View {
        ZStack {
            VStack(spacing: 3) {
                Text("Cửa hàng Đá quý".tr)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("GEM STORE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(AccountStyle.green)
            }

            HStack {
                Button {
                    if isSheet {
                        dismiss()
                    } else {
                        router.pop()
                    }
                } label: {
                    Image(systemName: isSheet ? "xmark" : "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .frame(width: 44, height: 44)
                        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                        }
                        .compositingGroup()
                        .shadow(color: AccountStyle.border, radius: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quay lại".tr)

                Spacer()

                HStack(spacing: 6) {
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(FormatNumber.formatNumber(currentGems))
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(AccountStyle.ink)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(AccountStyle.cream, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(AccountStyle.border, lineWidth: 1.5)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Đá quý hiện có: %d".tr(currentGems))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var heroCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "DCEEF8"), Color(hex: "F3E7FF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image("gemstone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
            }
            .overlay {
                Circle().strokeBorder(Color(hex: "7BB8D9").opacity(0.45), lineWidth: 1.5)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Nạp Đá quý cho khu vườn".tr)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("Mở khóa cây hiếm, chậu cao cấp, phân bón & xẻng. Mua gói lớn tiết kiệm tới 31%!".tr)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .modifier(AccountPanel())
    }
}

struct GemPackagesSection: View {
    @ObservedObject private var gemStore = GemStoreManager.shared
    @State private var showSuccessAlert = false
    @State private var creditedAmount = 0

    var body: some View {
        VStack(spacing: 14) {
            if let errorMessage = gemStore.errorMessage {
                statusBanner(text: errorMessage, isError: true)
            } else if let statusMessage = gemStore.statusMessage {
                statusBanner(text: statusMessage, isError: false)
            }

            ForEach(GemPackageKind.allCases) { package in
                GemPackageCard(
                    package: package,
                    displayPrice: gemStore.displayPrice(for: package),
                    originalPrice: gemStore.originalDisplayPrice(for: package),
                    unitPriceText: gemStore.unitPriceText(for: package),
                    savingsText: gemStore.savingsText(for: package),
                    badgeText: gemStore.badgeText(for: package),
                    isPurchasing: gemStore.purchasingProductId == package.productId,
                    isDisabled: gemStore.isPurchasing
                ) {
                    Task {
                        let ok = await gemStore.purchase(package)
                        if ok {
                            creditedAmount = package.gemAmount
                            showSuccessAlert = true
                        }
                    }
                }
            }

            Text("Giao dịch được xử lý an toàn qua Apple App Store. Đá quý sẽ được cộng ngay vào tài khoản của bạn.".tr)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 8)
        }
        .task {
            if gemStore.products.isEmpty {
                await gemStore.loadProducts()
            }
        }
        .alert("Nạp Đá quý thành công!".tr, isPresented: $showSuccessAlert) {
            Button("Tuyệt vời!".tr, role: .cancel) {}
        } message: {
            Text("Bạn vừa nhận được +%@ Đá quý vào khu vườn.".tr(creditedAmount.formatted()))
        }
    }

    private func statusBanner(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? AccountStyle.danger : AccountStyle.green)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(isError ? AccountStyle.danger : AccountStyle.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            (isError ? AccountStyle.danger : AccountStyle.green).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder((isError ? AccountStyle.danger : AccountStyle.green).opacity(0.3), lineWidth: 1)
        }
    }
}

private struct GemPackageCard: View {
    let package: GemPackageKind
    let displayPrice: String
    let originalPrice: String?
    let unitPriceText: String
    let savingsText: String?
    let badgeText: String?
    let isPurchasing: Bool
    let isDisabled: Bool
    let onBuy: () -> Void

    private var accentColor: Color {
        if package.isBestValue { return Color(hex: "D79922") }
        if package.isPopular { return AccountStyle.green }
        return Color(hex: "5E99B5")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let badgeText {
                HStack(spacing: 6) {
                    Image(systemName: package.isBestValue ? "crown.fill" : "flame.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(badgeText)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.6)
                }
                .foregroundStyle(AccountStyle.cream)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accentColor, in: Capsule())
            }

            HStack(spacing: 14) {
                gemArtwork
                VStack(alignment: .leading, spacing: 5) {
                    Text(package.title)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.ink)
                    Text(package.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        Text(unitPriceText)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(AccountStyle.muted)
                        if let savingsText {
                            Text(savingsText)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AccountStyle.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AccountStyle.green.opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: onBuy) {
                HStack(spacing: 10) {
                    if isPurchasing {
                        ProgressView()
                            .tint(AccountStyle.cream)
                        Text("Đang xử lý…".tr)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                    } else {
                        Text("Mua ngay".tr)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Spacer()
                        if let originalPrice {
                            Text(originalPrice)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .strikethrough()
                                .foregroundStyle(AccountStyle.cream.opacity(0.75))
                        }
                        Text(displayPrice)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(AccountStyle.cream)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    package.isBestValue ? Color(hex: "C9831B") : AccountStyle.green,
                    in: RoundedRectangle(cornerRadius: 15)
                )
                .compositingGroup()
                .shadow(
                    color: package.isBestValue ? Color(hex: "8A570C") : Color(hex: "3F5B34"),
                    radius: 0,
                    y: 3
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled && !isPurchasing ? 0.6 : 1)
        }
        .padding(18)
        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    package.isBestValue ? Color(hex: "D79922") : AccountStyle.border,
                    lineWidth: package.isBestValue ? 2 : 1.5
                )
        }
        .compositingGroup()
        .shadow(color: AccountStyle.border.opacity(0.75), radius: 0, y: 4)
    }

    private var gemArtwork: some View {
        let count = package == .pack1000 ? 1 : (package == .pack5000 ? 2 : 3)
        return ZStack {
            LinearGradient(
                colors: [Color(hex: "E2F1F8"), Color(hex: "F5EDD4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if count == 1 {
                Image("gemstone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
            } else if count == 2 {
                HStack(spacing: -10) {
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-10))
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(8))
                }
            } else {
                ZStack {
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .offset(x: -14, y: 6)
                        .rotationEffect(.degrees(-14))
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .offset(x: 14, y: 6)
                        .rotationEffect(.degrees(14))
                    Image("gemstone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .offset(y: -4)
                }
            }
        }
        .frame(width: 78, height: 78)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(accentColor.opacity(0.35), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    GemStoreView()
        .environmentObject(AppRouter())
}

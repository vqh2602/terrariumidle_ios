import SwiftUI

struct StoreItemCard: View {
    let item: ItemData
    let isOwned: Bool
    let canAfford: Bool
    let meetsLevelRequirement: Bool
    let onPurchase: (ItemData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                itemArtwork
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.name.tr)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.description.tr)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .lineLimit(3)
                    if !meetsLevelRequirement {
                        Label("Mở khóa cấp %d".tr(item.levelUnlock), systemImage: "lock.fill")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.danger)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if item.displayEffect != "N.A" && !item.displayEffect.isEmpty {
                Label(item.displayEffect, systemImage: "sparkles")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AccountStyle.green)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AccountStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
            purchaseButton
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var itemArtwork: some View {
        CachedAsyncImage(named: item.image) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            Image(systemName: item.type == "plant" ? "leaf.fill" : "shippingbox.fill")
                .font(.system(size: 28))
                .foregroundStyle(AccountStyle.green.opacity(0.45))
        }
        .padding(10)
        .frame(width: 88, height: 100)
        .background {
            LinearGradient(colors: [Color(hex: "E6EBCF"), Color(hex: "F5EDD4")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(AccountStyle.border.opacity(0.65), lineWidth: 1) }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isOwned {
            statusLabel("Đã sở hữu".tr, icon: "checkmark.seal.fill")
        } else if !meetsLevelRequirement {
            statusLabel("Mở khóa ở cấp %d".tr(item.levelUnlock), icon: "lock.fill")
        } else {
            Button { onPurchase(item) } label: {
                HStack(spacing: 8) {
                    Text(canAfford ? "Mua vật phẩm".tr : "Chưa đủ tài nguyên".tr)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                    Spacer(minLength: 8)
                    currencyIcon
                    Text(item.priceStore.formatted())
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(canAfford ? AccountStyle.cream : AccountStyle.muted)
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(canAfford ? AccountStyle.green : AccountStyle.border.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 14))
                .compositingGroup()
                .shadow(color: canAfford ? Color(hex: "3F5B34") : .clear, radius: 0, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
            .accessibilityLabel("Mua %@, %d %@".tr(item.name.tr, item.priceStore, currencyName))
        }
    }

    private func statusLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(AccountStyle.muted)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(AccountStyle.border.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
    }

    private var currencyName: String {
        switch item.currencyUnit {
        case "oxygen": return "oxy"
        case "gemstone": return "đá quý".tr
        case "ticket": return "vé".tr
        default: return item.currencyUnit
        }
    }

    @ViewBuilder
    private var currencyIcon: some View {
        switch item.currencyUnit {
        case "oxygen", "gemstone", "ticket":
            Image(item.currencyUnit)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        default:
            Image(systemName: "questionmark.circle.fill")
        }
    }
}

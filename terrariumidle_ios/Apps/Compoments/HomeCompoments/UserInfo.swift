import SwiftUI

struct UserInfoCompoment: View {
    @State private var isExpanded: Bool = false
    @StateObject var fireStore: FireStoreService = .shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @EnvironmentObject var router: AppRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var userLevel: Int { fireStore.gradenModel?.user.userLevel ?? 1 }
    private var userExp: Int { fireStore.gradenModel?.user.userLevelEXP ?? 0 }
    private var maxExp: Int { max(1, ShareFunc.calculateUserMaxExp(level: userLevel)) }
    private var progress: Double { min(max(Double(userExp) / Double(maxExp), 0), 1) }
    private var isVIP: Bool { SubscriptionManager.isVIP(gardenModel: fireStore.gradenModel) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isExpanded {
                expandedBar
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.82, anchor: .topLeading).combined(with: .opacity))
            } else {
                levelButton
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.9, anchor: .topLeading).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: fireStore.gradenModel?.user.userLevel) { oldLevel, newLevel in
            guard let oldLevel, let newLevel, newLevel > oldLevel else { return }
            AudioPlayer.shared.playSFX(fileName: "level_up")
        }
    }

    private var levelButton: some View {
        Button { toggleExpanded() } label: {
            LevelCircularBadge(level: userLevel, progress: progress, isVIP: isVIP)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cấp %d, mở thanh tài nguyên".tr(userLevel))
        .accessibilityHint("Nhấn giữ để mở tài khoản".tr)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            router.push(.accountView)
        })
    }

    private var expandedBar: some View {
        GardenStatusBar(
            level: userLevel, experience: userExp, maxExperience: maxExp,
            oxygen: fireStore.gradenModel?.money.oxygen ?? 0,
            gemstones: fireStore.gradenModel?.money.gemstone ?? 0,
            fertilizer: fireStore.gradenModel?.item.fertilizer ?? 0,
            shovels: fireStore.gradenModel?.item.shovel ?? 0,
            tickets: fireStore.gradenModel?.money.ticket ?? 0,
            isVIP: isVIP,
            onCollapse: toggleExpanded,
            onAccount: { router.push(.accountView) }
        )
    }

    private func toggleExpanded() {
        AudioPlayer.shared.playSFX(fileName: "swoosh", ext: "wav")
        withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.86)) {
            isExpanded.toggle()
        }
    }
}

struct GardenStatusBar: View {
    let level: Int
    let experience: Int
    let maxExperience: Int
    let oxygen: Int
    let gemstones: Int
    let fertilizer: Int
    let shovels: Int
    let tickets: Int
    var isVIP: Bool = false
    let onCollapse: () -> Void
    let onAccount: () -> Void

    private var progress: Double {
        min(max(Double(experience) / Double(max(1, maxExperience)), 0), 1)
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                Button(action: onCollapse) {
                    LevelCircularBadge(level: level, progress: progress, size: 48, isVIP: isVIP)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cấp %d, thu gọn thanh tài nguyên".tr(level))
                .accessibilityHint("Nhấn giữ để mở tài khoản".tr)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onAccount() })

                HStack(spacing: 4) {
                    GardenResourceValue(name: "Oxy".tr, image: "oxygen", value: oxygen)
                    GardenResourceValue(name: "Đá quý".tr, image: "gemstone", value: gemstones)
                    GardenResourceValue(name: "Phân bón".tr, image: "fertilizer", value: fertilizer)
                    GardenResourceValue(name: "Xẻng".tr, image: "shovel", value: shovels)
                    GardenResourceValue(name: "Vé".tr, image: "ticket", value: tickets)
                }
                .frame(maxWidth: .infinity)
            }
            HStack(spacing: 8) {
                Text("Cấp %d".tr(level))
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AccountStyle.green)
                GeometryReader { geometry in
                    Capsule()
                        .fill(AccountStyle.green.opacity(0.15))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: "99B96B"), AccountStyle.green],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * progress)
                        }
                }
                .frame(height: 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Kinh nghiệm".tr)
                .accessibilityValue("%d trên %d".tr(experience, maxExperience))
                Text("\(experience.formatted()) / \(maxExperience.formatted()) XP")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(12)
        .modifier(AccountPanel())
    }
}

struct LevelCircularBadge: View {
    let level: Int
    let progress: Double
    var size: CGFloat = 50
    var isVIP: Bool = false

    var body: some View {
        ZStack {
            Circle().fill(AccountStyle.cream)
            Circle().strokeBorder(isVIP ? VIPPalette.gold : AccountStyle.border, lineWidth: 2)
            Circle()
                .inset(by: 4)
                .stroke(AccountStyle.green.opacity(0.15), lineWidth: 3)
            Circle()
                .inset(by: 4)
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AccountStyle.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Image(systemName: isVIP ? "crown.fill" : "leaf.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isVIP ? VIPPalette.gold : AccountStyle.green)
                Text("\(level)")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(AccountStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(9)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: AccountStyle.border.opacity(0.7), radius: 0, y: 3)
    }
}

private struct GardenResourceValue: View {
    let name: String
    let image: String
    let value: Int

    private var compactValue: String {
        FormatNumber.formatNumber(value)
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 23)
            Text(compactValue)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AccountStyle.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(AccountStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name): \(value.formatted())")
    }
}

#Preview("Thanh thông tin · 320pt".tr) {
    GardenStatusBar(level: 52, experience: 42_900, maxExperience: 104_000,
                    oxygen: 272_100_000, gemstones: 799_900_000, fertilizer: 11_800,
                    shovels: 32, tickets: 6_585_800_000, onCollapse: {}, onAccount: {})
        .padding(16)
        .frame(width: 320)
        .background(Color(hex: "E9EED9"))
}

import SwiftUI

private enum HealthFeatureDestination: String, Identifiable {
    case sleep
    case steps

    var id: String { rawValue }
}

struct HealthHubSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var sleepHealth = SleepHealthStore.shared
    @ObservedObject private var stepsHealth = StepsHealthStore.shared
    @ObservedObject private var rewardStatus = HealthRewardStatusStore.shared
    @AppStorage("sleep.goalHours") private var sleepGoal = 8.0
    @AppStorage(StepsSummary.goalStorageKey) private var rawStepsGoal = StepsSummary.defaultGoal
    @State private var activeDestination: HealthFeatureDestination?

    private var stepsGoal: Int {
        StepsSummary.clampedGoal(rawStepsGoal)
    }

    private var sleepSubtitle: String {
        if let today = sleepHealth.days.last, today.seconds > 0 {
            return "Hôm nay: %@ / %@ giờ".tr(SleepSummary.duration(today.seconds), sleepGoal.formatted())
        }
        return "Theo dõi giấc ngủ & nhận quà hằng ngày".tr
    }

    private var stepsSubtitle: String {
        if let today = stepsHealth.days.last, today.steps > 0 {
            return "Hôm nay: %@ / %@".tr(StepsSummary.formatted(today.steps), StepsSummary.countLabel(stepsGoal))
        }
        return "Đồng bộ Apple Health & đặt mục tiêu bước/ngày".tr
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    featureCard(
                        title: "Giấc ngủ".tr,
                        subtitle: sleepSubtitle,
                        icon: "moon.stars.fill",
                        tint: Color(hex: "8D9360"),
                        unclaimedCount: rewardStatus.sleepUnclaimedCount
                    ) {
                        AudioPlayer.shared.playTap()
                        activeDestination = .sleep
                    }

                    featureCard(
                        title: "Bước chân".tr,
                        subtitle: stepsSubtitle,
                        icon: "figure.walk",
                        tint: AccountStyle.green,
                        unclaimedCount: rewardStatus.stepsUnclaimedCount
                    ) {
                        AudioPlayer.shared.playTap()
                        activeDestination = .steps
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "EDF0DD").ignoresSafeArea())
            .foregroundStyle(AccountStyle.ink)
            .navigationTitle("Sức khỏe".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng".tr) { dismiss() }
                }
            }
            .tint(AccountStyle.green)
            .task {
                await rewardStatus.syncAndRefresh()
            }
            .sheet(item: $activeDestination) { destination in
                switch destination {
                case .sleep:
                    SleepGardenView()
                case .steps:
                    StepsGardenView()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color(hex: "E4E9D2")).frame(width: 68, height: 68)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color(hex: "C26A63"))
            }
            .accessibilityHidden(true)
            Text("Chăm sóc sức khỏe cùng khu vườn".tr)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Chọn tính năng bạn muốn xem thống kê và nhận thưởng.".tr)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private func featureCard(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        unclaimedCount: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 52, height: 52)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.ink)
                        if unclaimedCount > 0 {
                            Text("Có %d quà".tr(unclaimedCount))
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "D95D39"), in: Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AccountStyle.muted)
            }
            .padding(16)
            .modifier(AccountPanel())
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Sức khỏe · Góc vườn".tr) {
    HealthHubSheet()
}

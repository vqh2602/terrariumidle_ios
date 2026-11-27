import GameKit
import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var store = AchievementStore.shared
    @ObservedObject private var gameCenter = GameCenterAchievementService.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var filter = 0

    private var isVietnamese: Bool { localization.currentLanguage == .vi }
    private func percent(_ item: GardenAchievement) -> Double {
        gameCenter.displayPercent(for: item, progress: store.progress)
    }
    private var completed: Int { AchievementCatalog.all.filter { percent($0) >= 100 }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summary
                connection
                Picker("Lọc thành tích".tr, selection: $filter) {
                    Text("Tất cả".tr).tag(0)
                    Text("Đang tiến hành".tr).tag(1)
                    Text("Đã đạt".tr).tag(2)
                }
                .pickerStyle(.segmented)
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(AchievementMetric.allCases, id: \.self) { metric in
                        let items = AchievementCatalog.all.filter {
                            $0.metric == metric && (filter == 0 || (filter == 2 ? percent($0) >= 100 : percent($0) < 100))
                        }
                        if let first = items.first {
                            Section {
                                ForEach(items) { achievement in row(achievement) }
                            } header: {
                                Text(groupTitle(first))
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .padding(.top, 8)
                            }
                        }
                    }
                    if filter == 2 && completed == 0 {
                        ContentUnavailableView("Chưa có thành tích hoàn tất".tr,
                                               systemImage: "medal",
                                               description: Text("Mỗi bước chăm vườn đều đưa bạn gần hơn tới huy hiệu đầu tiên.".tr))
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(AccountStyle.cream.ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .tint(AccountStyle.green)
        .navigationTitle("Thành tích".tr)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { router.pop() } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Quay lại".tr)
            }
        }
        .onAppear { store.foreground() }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hành trình khu vườn".tr, systemImage: "trophy.fill")
                .font(.system(.title2, design: .rounded, weight: .heavy))
            Text("%d / %d thành tích".tr(completed, AchievementCatalog.all.count))
                .font(.headline)
            ProgressView(value: Double(completed), total: Double(AchievementCatalog.all.count))
            Text("Thành tích đã đạt luôn được giữ lại khi bạn thay đổi khu vườn.".tr)
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var connection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Game Center", systemImage: "gamecontroller.fill")
                .font(.headline)
            if gameCenter.isConnected {
                Text(gameCenter.playerName).font(.subheadline.bold())
                Button("Xem thành tích trên Game Center".tr) { gameCenter.showDashboard() }
                    .buttonStyle(.borderedProminent)
                HStack {
                    Button("Đồng bộ lại".tr) {
                        store.retrySync()
                        // Reload Apple metadata too: configuration may have changed since the last connection.
                        gameCenter.connect()
                    }
                    Spacer()
                    Button("Ngắt kết nối".tr) { gameCenter.disconnect() }
                }
                .font(.subheadline)
                .disabled(gameCenter.isReporting)
            } else {
                Text("Kết nối để lưu thành tích vào tài khoản Game Center và xem huy hiệu của Apple.".tr)
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
                Button { gameCenter.connect() } label: {
                    if gameCenter.isConnecting { ProgressView() }
                    else { Text("Kết nối Game Center".tr) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(gameCenter.isConnecting || store.userID == nil)
            }
            if let message = gameCenter.message {
                Text(message).font(.caption).foregroundStyle(AccountStyle.muted)
            }
            if let error = store.cloudError {
                Text(error).font(.caption).foregroundStyle(AccountStyle.muted)
                Button("Thử lại".tr) { store.retrySync() }.font(.caption.bold())
            }
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private func groupTitle(_ item: GardenAchievement) -> String {
        let title = isVietnamese ? item.titleVI : item.titleEN
        return title.split(separator: " ").dropLast().joined(separator: " ")
    }

    private func row(_ item: GardenAchievement) -> some View {
        let value = percent(item)
        let achieved = value >= 100
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: achieved ? "checkmark.seal.fill" : item.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(achieved ? Color(hex: "B18A45") : AccountStyle.green)
                .frame(width: 48, height: 48)
                .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text(isVietnamese ? item.titleVI : item.titleEN)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Text(isVietnamese ? item.descriptionVI : item.descriptionEN)
                    .font(.caption).foregroundStyle(AccountStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: value, total: 100)
                HStack {
                    Text(achieved ? "Đã đạt".tr : "\(Int(value))%")
                    Spacer()
                    Text("%d điểm Game Center".tr(item.points))
                }
                .font(.caption2)
                .foregroundStyle(AccountStyle.muted)
            }
        }
        .padding(16)
        .modifier(AccountPanel())
        .accessibilityElement(children: .combine)
    }
}

/// Present Apple's controllers from one stable root, including reconnects during gameplay.
struct AchievementLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var phase
    @ObservedObject private var gameCenter = GameCenterAchievementService.shared

    func body(content: Content) -> some View {
        content
            .task {
                AchievementStore.shared.start()
                AchievementStore.shared.foreground()
            }
            .onChange(of: phase) { _, value in
                if value == .active { AchievementStore.shared.foreground() }
                else { AchievementStore.shared.background() }
            }
            .fullScreenCover(item: $gameCenter.presentation) { presentation in
                GameCenterController(controller: presentation.controller) {
                    gameCenter.presentation = nil
                }
                .ignoresSafeArea()
            }
    }
}

private struct GameCenterController: UIViewControllerRepresentable {
    let controller: UIViewController
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }
    func makeUIViewController(context: Context) -> UIViewController {
        if let dashboard = controller as? GKGameCenterViewController {
            dashboard.gameCenterDelegate = context.coordinator
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) { onDismiss() }
    }
}

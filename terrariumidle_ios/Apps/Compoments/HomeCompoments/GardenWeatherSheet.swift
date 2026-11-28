import SwiftUI

struct GardenWeatherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fireStore = FireStoreService.shared
    @State private var message: String?

    private var isVIP: Bool {
        SubscriptionManager.isVIP(gardenModel: fireStore.gradenModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Chọn thời tiết cho khu vườn của bạn: mưa gió tự tap 60s hoặc xịt hóa chất tiêu diệt sâu bọ.".tr)
                        .foregroundStyle(.secondary)
                    Label("Bạn có %d ticket".tr(fireStore.gradenModel?.money.ticket ?? 0), systemImage: "ticket.fill")
                        .font(.subheadline.bold())
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let end = fireStore.gradenModel?.weatherUntil ?? 0
                        let seconds = max(0, Int(ceil(end - context.date.timeIntervalSince1970)))
                        VStack(spacing: 14) {
                            if seconds > 0 {
                                Label("%@ đang diễn ra · %ds".tr(fireStore.gradenModel?.weatherKind.title ?? "Mưa".tr, seconds),
                                      systemImage: fireStore.gradenModel?.weatherKind.icon ?? "cloud.rain.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AccountStyle.green)
                            }
                            ForEach(GardenModel.WeatherKind.allCases) { kind in
                                Button { startWeather(kind) } label: {
                                    HStack(spacing: 16) {
                                        Image(systemName: kind.icon)
                                            .font(.system(size: 28))
                                            .foregroundStyle(iconColor(for: kind))
                                            .frame(width: 44)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(titleText(for: kind))
                                                .font(.headline)
                                            Text(subtitleText(for: kind))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text(costText(for: kind))
                                                .font(.caption.bold())
                                                .foregroundStyle(kind == .spray && (fireStore.gradenModel?.remainingFreeSprays(isVIP: isVIP) ?? 0) > 0 ? AccountStyle.green : .primary)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(18)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
                                    .contentShape(RoundedRectangle(cornerRadius: 18))
                                }
                                .buttonStyle(.plain)
                                .disabled(seconds > 0 || fireStore.gradenModel == nil)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Thời tiết".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng".tr) { dismiss() }
                }
            }
            .alert("Thời tiết".tr, isPresented: Binding(
                get: { message != nil }, set: { if !$0 { message = nil } }
            )) {
                Button("Đã hiểu".tr, role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func iconColor(for kind: GardenModel.WeatherKind) -> Color {
        switch kind {
        case .rain: return Color(hex: "5E99B5")
        case .wind: return AccountStyle.green
        case .spray: return Color(hex: "4B9B7A")
        }
    }

    private func titleText(for kind: GardenModel.WeatherKind) -> String {
        switch kind {
        case .spray: return "Xịt hóa chất".tr
        case .rain, .wind: return "Tạo %@".tr(kind.title.lowercased())
        }
    }

    private func subtitleText(for kind: GardenModel.WeatherKind) -> String {
        switch kind {
        case .rain: return "Mưa rơi tưới mát toàn vườn".tr
        case .wind: return "Từng đợt gió lướt qua khu vườn".tr
        case .spray: return "Khói sương tiêu diệt toàn bộ sâu bọ (không vào túi)".tr
        }
    }

    private func costText(for kind: GardenModel.WeatherKind) -> String {
        guard kind == .spray else {
            return "1 ticket · Tự tap 60 giây".tr
        }
        let freeLeft = fireStore.gradenModel?.remainingFreeSprays(isVIP: isVIP) ?? 0
        let freeLimit = GardenModel.sprayFreeLimit(isVIP: isVIP)
        if freeLeft > 0 {
            if isVIP {
                return "VIP miễn phí (%d/%d hôm nay) · 5 giây".tr(freeLeft, freeLimit)
            } else {
                return "Miễn phí (%d/%d hôm nay) · 5 giây".tr(freeLeft, freeLimit)
            }
        }
        return "1 ticket (đã hết miễn phí) · 5 giây".tr
    }

    private func startWeather(_ kind: GardenModel.WeatherKind) {
        guard var garden = fireStore.gradenModel else { return }
        let removedPestIds = kind == .spray ? garden.pests.map(\.id) : []
        switch garden.startWeather(kind, isVIP: isVIP, now: Date().timeIntervalSince1970) {
        case .started:
            if kind == .spray && !removedPestIds.isEmpty {
                fireStore.markAllPestsRemovedLocally(removedPestIds)
            }
            fireStore.saveGarden(gardenModel: garden, debounce: false)
            AchievementStore.shared.record(.weather)
            dismiss()
        case .insufficientTickets:
            message = "Bạn cần 1 ticket để tạo %@.".tr(kind.title.lowercased())
        case .alreadyActive:
            message = "Hãy chờ thời tiết hiện tại kết thúc trước khi tạo đợt mới.".tr
        case .noPlants:
            message = "Hãy trồng cây trong vườn trước khi tạo thời tiết.".tr
        }
    }
}

import SwiftUI

struct GardenWeatherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fireStore = FireStoreService.shared
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Chọn thời tiết để toàn bộ cây tự tap mỗi giây trong 60 giây.".tr)
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
                                            .frame(width: 44)
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Tạo %@".tr(kind.title.lowercased()))
                                                .font(.headline)
                                            Text(kind == .rain ? "Mưa rơi tưới mát toàn vườn".tr : "Từng đợt gió lướt qua khu vườn".tr)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text("1 ticket · Tự tap 60 giây".tr)
                                                .font(.caption.bold())
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

    private func startWeather(_ kind: GardenModel.WeatherKind) {
        guard var garden = fireStore.gradenModel else { return }
        switch garden.startWeather(kind, now: Date().timeIntervalSince1970) {
        case .started:
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

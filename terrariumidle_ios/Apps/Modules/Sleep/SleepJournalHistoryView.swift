import SwiftUI

struct SleepActionButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .foregroundStyle(prominent ? AccountStyle.cream : AccountStyle.green)
            .background(prominent ? AccountStyle.green : AccountStyle.green.opacity(0.08), in: Capsule())
            .overlay { Capsule().strokeBorder(AccountStyle.green.opacity(prominent ? 0 : 0.2), lineWidth: 1) }
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
    }
}

struct SleepJournalEntryRow: View {
    let entry: ManualSleepEntry
    private let locale = Locale(identifier: "vi_VN")

    private var timeRange: String {
        let time = Date.FormatStyle.dateTime.hour().minute().locale(locale)
        if Calendar.current.isDate(entry.start, inSameDayAs: entry.end) {
            return "\(entry.start.formatted(time)) – \(entry.end.formatted(time))"
        }
        let dateTime = Date.FormatStyle.dateTime.day().month(.twoDigits).hour().minute().locale(locale)
        return "\(entry.start.formatted(dateTime)) → \(entry.end.formatted(dateTime))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(entry.end.formatted(.dateTime.day().month().year().locale(locale)))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Spacer(minLength: 0)
                Image(systemName: entry.exported ? "checkmark.icloud" : "iphone")
                    .font(.caption).foregroundStyle(AccountStyle.muted)
                    .accessibilityLabel(entry.exported ? "Đã ghi sang Apple Health" : "Chỉ trên thiết bị")
            }
            Text(timeRange).font(.subheadline).foregroundStyle(AccountStyle.muted)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    duration
                    if entry.feeling != "Chưa chọn" { Text("·"); Text(entry.feeling) }
                }
                VStack(alignment: .leading, spacing: 4) {
                    duration
                    if entry.feeling != "Chưa chọn" { Text(entry.feeling) }
                }
            }.font(.caption).foregroundStyle(AccountStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var duration: some View {
        Label(SleepSummary.duration(entry.interval.duration), systemImage: "moon.fill")
            .foregroundStyle(AccountStyle.green)
    }
}

struct SleepJournalHistoryView: View {
    @ObservedObject var health: SleepHealthStore
    @State private var showEntry = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if health.manualEntries.isEmpty {
                    ContentUnavailableView("Chưa có nhật ký", systemImage: "book.closed",
                                           description: Text("Ghi lại giấc ngủ đầu tiên của bạn."))
                }
                ForEach(health.manualEntries.sorted { $0.end > $1.end }) { entry in
                    SleepJournalEntryRow(entry: entry).padding(18).modifier(AccountPanel())
                }
            }.padding(20)
        }
        .background(Color(hex: "EDF0DD").ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .navigationTitle("Nhật ký giấc ngủ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEntry = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Ghi giấc ngủ")
            }
        }
        .sheet(isPresented: $showEntry) { ManualSleepSheet(health: health) }
        .tint(AccountStyle.green)
    }
}

struct SleepHealthSettingsView: View {
    @ObservedObject var health: SleepHealthStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Kết nối giấc ngủ", systemImage: "heart.fill")
                        .font(.system(.headline, design: .rounded))
                    Text("Đọc dữ liệu từ Apple Health và chọn ghi nhật ký thủ công của bạn sang Health.")
                        .font(.subheadline).foregroundStyle(AccountStyle.muted)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { healthButtons }
                        VStack(alignment: .leading, spacing: 12) { healthButtons }
                    }
                    if health.isSyncing || health.isSaving { ProgressView("Đang xử lý…").font(.caption) }
                    if let message = health.message {
                        Text(message).font(.caption).foregroundStyle(AccountStyle.muted)
                    }
                    if !health.isAvailable {
                        Text("Apple Health chưa khả dụng trên thiết bị này.").font(.subheadline)
                    }
                }.padding(20).modifier(AccountPanel())
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cách đồng bộ").font(.headline)
                    Text("“Đồng bộ” sẽ ghi tất cả bản ghi thủ công còn trên thiết bị sang Apple Health nếu bạn đã cấp quyền ghi.")
                    Text("Khi thêm bản ghi mới, bạn vẫn có thể chọn chỉ lưu trên thiết bị. Các khoảng ngủ trùng nhau chỉ được tính một lần trong biểu đồ.")
                    Text("Nhật ký được giữ trên thiết bị nếu chưa đồng bộ được. Bạn có thể thử lại sau.")
                }
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
                .padding(20).modifier(AccountPanel())
            }.padding(20)
        }
        .background(Color(hex: "EDF0DD").ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AccountStyle.green)
    }

    @ViewBuilder private var healthButtons: some View {
        Button { Task { await health.connect() } } label: {
            Label("Cấp quyền", systemImage: "heart.text.clipboard")
        }
        .buttonStyle(SleepActionButtonStyle(prominent: false))
        .disabled(health.isSyncing || health.isSaving || !health.isAvailable)
        Button { Task { await health.syncManualJournal() } } label: {
            Label("Đồng bộ", systemImage: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(SleepActionButtonStyle())
        .disabled(!health.hasRequestedAccess || health.isSyncing || health.isSaving || !health.isAvailable
                  || !health.manualEntries.contains(where: { !$0.exported }))
    }
}

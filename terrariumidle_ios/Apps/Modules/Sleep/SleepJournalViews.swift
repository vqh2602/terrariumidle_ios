import SwiftUI
import UserNotifications

struct SleepScheduleCard: View {
    @AppStorage("sleep.scheduleEnabled") private var enabled = false
    @AppStorage("sleep.bedMinutes") private var bedMinutes = 22 * 60
    @AppStorage("sleep.wakeMinutes") private var wakeMinutes = 6 * 60
    @AppStorage("sleep.reminders") private var reminders = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $enabled) {
                Label("Lịch trình ngủ".tr, systemImage: "bed.double.fill").font(.headline)
            }
            if enabled {
                DatePicker("Giờ đi ngủ".tr, selection: timeBinding($bedMinutes), displayedComponents: .hourAndMinute)
                DatePicker("Giờ thức dậy".tr, selection: timeBinding($wakeMinutes), displayedComponents: .hourAndMinute)
                Text("Thời gian dự kiến: %@ giờ mỗi đêm".tr(SleepJournal.scheduledHours(bedMinutes: bedMinutes, wakeMinutes: wakeMinutes).formatted()))
                    .font(.subheadline)
                Toggle("Nhắc giờ ngủ và thức dậy".tr, isOn: $reminders)
                Text("Lịch trong Terrarium áp dụng mỗi ngày, không thay đổi lịch Apple Health hoặc chế độ Tập trung. Lịch không tự tạo bản ghi giấc ngủ. Nhắc nhở là thông báo, không phải báo thức.".tr)
                    .font(.caption).foregroundStyle(AccountStyle.muted)
                if let message { Text(message).font(.caption).foregroundStyle(AccountStyle.muted) }
            }
        }
        .padding(20).modifier(AccountPanel())
        .task(id: "\(enabled)-\(reminders)-\(bedMinutes)-\(wakeMinutes)") { await updateReminders() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await updateReminders() } }
        }
    }

    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(get: {
            Calendar.current.date(bySettingHour: minutes.wrappedValue / 60,
                                  minute: minutes.wrappedValue % 60, second: 0, of: .now)!
        }, set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = parts.hour! * 60 + parts.minute!
        })
    }

    @MainActor private func updateReminders() async {
        message = await SleepReminderScheduler.shared.update(enabled: enabled && reminders,
                                                             minutes: [bedMinutes, wakeMinutes])
    }
}

/// Serialize replacements so an older notification request cannot overwrite newer settings.
@MainActor
private final class SleepReminderScheduler {
    static let shared = SleepReminderScheduler()
    private var pending: Task<String?, Never>?

    func update(enabled: Bool, minutes: [Int]) async -> String? {
        let previous = pending
        previous?.cancel()
        let next = Task<String?, Never> {
            _ = await previous?.value
            guard !Task.isCancelled else { return nil }
            let center = UNUserNotificationCenter.current()
            let ids = ["terrarium.sleep.bed", "terrarium.sleep.wake"]
            center.removePendingNotificationRequests(withIdentifiers: ids)
            guard enabled else { return nil }
            do {
                let allowed = try await center.requestAuthorization(options: [.alert, .sound])
                guard !Task.isCancelled else { return nil }
                guard allowed else {
                    return "Thông báo chưa được cho phép. Bạn có thể bật trong Cài đặt → Thông báo → Terrarium.".tr
                }
                for (index, time) in minutes.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = index == 0 ? "Đến giờ nghỉ ngơi".tr : "Chào buổi sáng".tr
                    content.body = index == 0 ? "Khép lại hôm nay, dành thời gian nghỉ ngơi cùng khu vườn.".tr : "Khi sẵn sàng, hãy ghi lại giấc ngủ đêm qua.".tr
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: time / 60, minute: time % 60), repeats: true)
                    try await center.add(UNNotificationRequest(identifier: ids[index], content: content, trigger: trigger))
                    if Task.isCancelled {
                        center.removePendingNotificationRequests(withIdentifiers: ids)
                        return nil
                    }
                }
                return nil
            } catch {
                center.removePendingNotificationRequests(withIdentifiers: ids)
                return Task.isCancelled ? nil : "Chưa đặt được nhắc nhở. Hãy thử tắt rồi bật lại.".tr
            }
        }
        pending = next
        return await next.value
    }
}

struct ManualSleepSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var health: SleepHealthStore
    @State private var start = Calendar.current.date(byAdding: .hour, value: -8, to: .now)!
    @State private var end = Date()
    @State private var feeling = "Chưa chọn".tr
    @State private var export = false
    private let feelings = ["Chưa chọn".tr, "Mệt mỏi".tr, "Bình thường".tr, "Sảng khoái".tr]

    var body: some View {
        NavigationStack {
            Form {
                Section("Giấc ngủ thực tế".tr) {
                    DatePicker("Bắt đầu ngủ".tr, selection: $start, in: ...Date())
                    DatePicker("Thức dậy".tr, selection: $end, in: ...Date())
                    if SleepJournal.isValid(start: start, end: end) {
                        Text(SleepSummary.duration(end.timeIntervalSince(start)))
                    } else {
                        Text("Giờ thức dậy phải sau giờ ngủ, không ở tương lai và khoảng ngủ tối đa 24 giờ.".tr)
                            .foregroundStyle(.red).font(.caption)
                    }
                    Picker("Cảm nhận khi thức dậy".tr, selection: $feeling) {
                        ForEach(feelings, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    Toggle("Ghi bản này sang Apple Health".tr, isOn: $export)
                        .disabled(!health.isAvailable)
                    Text("Luôn lưu nhật ký trên thiết bị. Bản ghi thủ công chỉ ghi nhận thời gian ngủ, không suy đoán các giai đoạn REM hay ngủ sâu. Cần cấp quyền ghi để xuất sang Apple Health.".tr)
                        .font(.caption)
                    if let message = health.message { Text(message).font(.caption) }
                }
            }
            .navigationTitle("Ghi giấc ngủ".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy".tr) { dismiss() }.disabled(health.isSaving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(health.isSaving ? "Đang lưu…".tr : "Lưu".tr) {
                        Task {
                            if await health.addManual(start: start, end: end, feeling: feeling, export: export) { dismiss() }
                        }
                    }.disabled(!SleepJournal.isValid(start: start, end: end) || health.isSaving || health.isSyncing)
                }
            }
            .interactiveDismissDisabled(health.isSaving)
        }
    }
}

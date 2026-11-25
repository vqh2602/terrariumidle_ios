import SwiftUI
import UIKit
import UserNotifications

/// Daily reminders are device preferences, independent of the signed-in garden.
struct AccountReminderCard: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @AppStorage("account.reminders.enabled") private var enabled = true
    @AppStorage("account.reminders.morningEnabled") private var morningEnabled = true
    @AppStorage("account.reminders.eveningEnabled") private var eveningEnabled = true
    @AppStorage("account.reminders.morningMinutes") private var morningMinutes = 7 * 60
    @AppStorage("account.reminders.eveningMinutes") private var eveningMinutes = 21 * 60
    @State private var status: String?
    @State private var permissionDenied = false

    private var configuration: GardenReminderConfiguration {
        GardenReminderConfiguration(enabled: enabled, morningEnabled: morningEnabled,
                                    eveningEnabled: eveningEnabled, morningMinutes: morningMinutes,
                                    eveningMinutes: eveningMinutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Hẹn lịch thông báo", systemImage: "bell.badge.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.green)
                .padding(.leading, 8)
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Nhắc chăm vườn và nghỉ ngơi", isOn: $enabled)
                    .font(.system(.headline, design: .rounded))
                Text("Một lời nhắc nhỏ mỗi ngày để chăm cây và dành thời gian cho mình.")
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
                if enabled {
                    Divider()
                    reminder(title: "Tưới cây buổi sáng", icon: "sun.max.fill", active: $morningEnabled,
                             minutes: $morningMinutes, text: GardenReminderConfiguration.morningBody)
                    Divider()
                    reminder(title: "Chuẩn bị ngủ", icon: "moon.stars.fill", active: $eveningEnabled,
                             minutes: $eveningMinutes, text: GardenReminderConfiguration.eveningBody)
                    Text("Lặp lại hằng ngày theo giờ trên thiết bị. Bạn có thể tắt riêng từng lời nhắc.")
                        .font(.caption).foregroundStyle(AccountStyle.muted)
                    if let status {
                        Text(status).font(.caption).foregroundStyle(AccountStyle.muted)
                            .accessibilityLabel(status)
                    }
                    if permissionDenied {
                        Button("Mở cài đặt thông báo") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }.font(.subheadline.bold())
                    }
                }
            }
            .padding(20)
            .modifier(AccountPanel())
        }
        .foregroundStyle(AccountStyle.ink)
        .tint(AccountStyle.green)
        .task(id: configuration) { await updateSchedule() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await updateSchedule() } }
        }
    }

    private func reminder(title: String, icon: String, active: Binding<Bool>,
                          minutes: Binding<Int>, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: active) {
                Label(title, systemImage: icon).font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            if active.wrappedValue {
                DatePicker("Giờ nhắc", selection: timeBinding(minutes), displayedComponents: .hourAndMinute)
                    .accessibilityLabel("Giờ nhắc \(title.lowercased())")
                Text(text).font(.subheadline).foregroundStyle(AccountStyle.muted)
            }
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

    @MainActor private func updateSchedule() async {
        let requested = configuration
        let result = await GardenReminderScheduler.shared.update(requested)
        guard requested == configuration, !Task.isCancelled else { return }
        status = result.message
        permissionDenied = result.permissionDenied
    }
}

struct GardenReminderConfiguration: Equatable, Hashable, Sendable {
    let enabled: Bool
    let morningEnabled: Bool
    let eveningEnabled: Bool
    let morningMinutes: Int
    let eveningMinutes: Int

    // Missing preferences default to on; an explicitly saved false remains off.
    static func saved(in defaults: UserDefaults = .standard) -> GardenReminderConfiguration {
        GardenReminderConfiguration(
            enabled: defaults.object(forKey: "account.reminders.enabled") as? Bool ?? true,
            morningEnabled: defaults.object(forKey: "account.reminders.morningEnabled") as? Bool ?? true,
            eveningEnabled: defaults.object(forKey: "account.reminders.eveningEnabled") as? Bool ?? true,
            morningMinutes: defaults.object(forKey: "account.reminders.morningMinutes") as? Int ?? 7 * 60,
            eveningMinutes: defaults.object(forKey: "account.reminders.eveningMinutes") as? Int ?? 21 * 60)
    }

    static let morningBody = "Chào buổi sáng! Ghé vườn tưới cây, đón một ngày mới xanh tươi nhé."
    static let eveningBody = "Đến lúc thư giãn rồi. Mở Terrarium, bật một bản nhạc dịu nhẹ và ghé mục Giấc ngủ để theo dõi, ghi lại giấc ngủ của bạn nhé."
}

@MainActor
final class GardenReminderScheduler {
    struct Result {
        var message: String?
        var permissionDenied = false
    }
    static let shared = GardenReminderScheduler()
    private var pending: Task<Result, Never>?
    private let identifiers = ["terrarium.account.morning", "terrarium.account.evening"]

    /// Serialize changes so a slow authorization/add request cannot restore a disabled reminder.
    func update(_ configuration: GardenReminderConfiguration) async -> Result {
        let previous = pending
        previous?.cancel()
        let ids = identifiers
        let next = Task<Result, Never> {
            _ = await previous?.value
            guard !Task.isCancelled else { return Result() }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ids)
            center.removeDeliveredNotifications(withIdentifiers: ids)
            guard configuration.enabled else { return Result() }
            guard configuration.morningEnabled || configuration.eveningEnabled else {
                return Result(message: "Cả hai lời nhắc đang tắt.")
            }
            do {
                let allowed = try await center.requestAuthorization(options: [.alert, .sound])
                guard !Task.isCancelled else { return Result() }
                guard allowed else {
                    return Result(message: "Thông báo chưa được cho phép. Bật quyền trong Cài đặt để nhận lời nhắc.",
                                  permissionDenied: true)
                }
                let reminders = [
                    (configuration.morningEnabled, configuration.morningMinutes, "Vườn nhỏ chờ bạn", GardenReminderConfiguration.morningBody),
                    (configuration.eveningEnabled, configuration.eveningMinutes, "Một chút bình yên trước giờ ngủ", GardenReminderConfiguration.eveningBody)
                ]
                for (index, reminder) in reminders.enumerated() where reminder.0 {
                    let content = UNMutableNotificationContent()
                    content.title = reminder.2
                    content.body = reminder.3
                    content.sound = .default
                    let minute = min(max(reminder.1, 0), 1439)
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: DateComponents(hour: minute / 60, minute: minute % 60), repeats: true)
                    try await center.add(UNNotificationRequest(identifier: ids[index], content: content, trigger: trigger))
                    if Task.isCancelled {
                        center.removePendingNotificationRequests(withIdentifiers: ids)
                        return Result()
                    }
                }
                return Result(message: "Đã đặt lời nhắc hằng ngày.")
            } catch {
                center.removePendingNotificationRequests(withIdentifiers: ids)
                return Result(message: Task.isCancelled ? nil : "Chưa đặt được lời nhắc. Hãy thử tắt rồi bật lại.")
            }
        }
        pending = next
        return await next.value
    }
}

#Preview {
    AccountReminderCard().padding(20).background(AccountStyle.cream)
}

import Charts
import SwiftUI

private enum SleepPeriod: String, CaseIterable {
    case day = "Ngày", week = "Tuần", month = "Tháng"
    var component: Calendar.Component {
        switch self { case .day: return .day; case .week: return .weekOfYear; case .month: return .month }
    }
}

struct SleepGardenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var health = SleepHealthStore.shared
    @ObservedObject private var garden = FireStoreService.shared
    @StateObject private var rewards = SleepRewards()
    @AppStorage("sleep.goalHours") private var goal = 8.0
    @State private var period: SleepPeriod = .week
    @State private var selectedDate = Date()
    @State private var showHelp = false
    @State private var showManualEntry = false

    private var interval: DateInterval {
        Calendar.current.dateInterval(of: period.component, for: selectedDate)!
    }
    private var visibleDays: [SleepDay] {
        health.days.filter { $0.date >= interval.start && $0.date < interval.end }
    }
    private var recordedDays: [SleepDay] { visibleDays.filter { $0.seconds > 0 } }
    private var average: TimeInterval {
        recordedDays.isEmpty ? 0 : recordedDays.reduce(0) { $0 + $1.seconds } / Double(recordedDays.count)
    }
    private var today: SleepDay? { health.days.last }
    private var eligibleRewards: [SleepRewardGrant] {
        SleepRewardRules.available(days: health.days, goal: goal, claimed: rewards.claimed,
                                   weeklyDays: rewards.weeklyDays)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SleepGardenHeader()
                    SleepScheduleCard()
                    if !health.isAvailable {
                        notice("Thiết bị này chưa hỗ trợ Apple Health. Bạn vẫn có thể ghi nhật ký thủ công.".tr, icon: "heart.slash")
                    } else if !health.hasRequestedAccess {
                        connectionCard
                    }
                    tonightCard
                    actionButton("Ghi giấc ngủ".tr, icon: "square.and.pencil") { showManualEntry = true }
                    if let message = health.message { notice(message, icon: "exclamationmark.circle") }
                    if health.days.allSatisfy({ $0.seconds == 0 }) && !health.isSyncing { emptyCard }
                    statisticsCard
                    manualJournalCard
                    journeyCard
                    rewardCard
                    privacyNote
                }
                .padding(20)
            }
            .background(Color(hex: "EDF0DD").ignoresSafeArea())
            .foregroundStyle(AccountStyle.ink)
            .navigationTitle("Giấc ngủ".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                        .accessibilityLabel("Hướng dẫn kết nối Apple Health".tr)
                }
                ToolbarItem(placement: .confirmationAction) { Button("Đóng".tr) { dismiss() } }
            }
            .tint(AccountStyle.green)
            .refreshable { await health.sync() }
            .task { await health.sync() }
            .task(id: garden.gradenModel?.user.userID) {
                await rewards.load(userID: garden.gradenModel?.user.userID)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await health.sync() } }
            }
            .alert("Quà từ giấc ngủ".tr, isPresented: Binding(
                get: { rewards.message != nil }, set: { if !$0 { rewards.message = nil } }
            )) { Button("Đã hiểu".tr) { rewards.message = nil } }
            message: { Text(rewards.message ?? "") }
            .sheet(isPresented: $showHelp) { helpSheet }
            .sheet(isPresented: $showManualEntry) { ManualSleepSheet(health: health) }
        }
        .presentationDragIndicator(.visible)
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nghỉ ngơi cùng khu vườn".tr, systemImage: "heart.text.clipboard.fill")
                .font(.system(.headline, design: .rounded))
            Text("Cho phép đọc giấc ngủ từ Apple Health. Mỗi lần mở Terrarium, nhật ký sẽ tự cập nhật để bạn nhận quà cho vườn.".tr)
            Text("Đọc giấc ngủ • Chỉ ghi nhật ký thủ công khi bạn chọn đồng bộ".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
            actionButton(health.isSyncing ? "Đang kết nối…".tr : "Kết nối Health".tr, icon: "heart.fill") {
                Task { await health.connect() }
            }.disabled(health.isSyncing)
            if let message = health.message { Text(message).font(.caption) }
        }.padding(20).modifier(AccountPanel())
    }

    private var tonightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Giấc ngủ hôm nay".tr, systemImage: "moon.zzz.fill")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if health.isSyncing { ProgressView().accessibilityLabel("Đang đồng bộ giấc ngủ".tr) }
            }
            if let today, today.seconds > 0 {
                Text(SleepSummary.duration(today.seconds))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                ProgressView(value: min(today.hours / goal, 1)).tint(AccountStyle.green)
                Text(today.hours >= goal ? "Một đêm nghỉ ngơi, thêm sức sống cho vườn.".tr : "Cảm ơn bạn đã dành thời gian nghỉ ngơi.".tr)
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
                if rewards.claimed.contains(today.id) {
                    Label("Đã nhận quà hôm nay".tr, systemImage: "checkmark.seal.fill").foregroundStyle(AccountStyle.green)
                }
            } else {
                Text("Đang chờ giấc ngủ mới".tr)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Ghi lại đêm qua bằng tay hoặc đồng bộ dữ liệu từ Apple Health.".tr)
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
            }
            if let lastSync = health.lastSync {
                Text("Đồng bộ gần nhất: %@".tr(lastSync.formatted(date: .abbreviated, time: .shortened)))
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
        }.padding(20).modifier(AccountPanel())
    }

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nhật ký nghỉ ngơi".tr, systemImage: "chart.bar.xaxis")
                .font(.system(.headline, design: .rounded))
            Picker("Thống kê theo".tr, selection: $period) {
                ForEach(SleepPeriod.allCases, id: \.self) { Text($0.rawValue.tr).tag($0) }
            }.pickerStyle(.segmented)
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").padding(8) }
                    .accessibilityLabel("Xem kỳ trước".tr)
                    .disabled(interval.start <= (health.days.first?.date ?? .now))
                Spacer(minLength: 0)
                Text(periodTitle).font(.system(.subheadline, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                Button { move(1) } label: { Image(systemName: "chevron.right").padding(8) }
                    .accessibilityLabel("Xem kỳ tiếp theo".tr)
                    .disabled(interval.contains(Date()))
            }
            if recordedDays.isEmpty {
                notice("Chưa có dữ liệu trong khoảng thời gian này.".tr, icon: "moon")
            } else {
                Text(period == .day ? SleepSummary.duration(average) : "Trung bình %@ / ngày có dữ liệu".tr(SleepSummary.duration(average)))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Chart {
                    ForEach(visibleDays) { day in
                        BarMark(x: .value("Ngày".tr, day.date, unit: .day), y: .value("Giờ ngủ".tr, day.hours))
                            .foregroundStyle(day.hours >= goal ? AccountStyle.green : Color(hex: "A9B88D"))
                            .cornerRadius(4)
                            .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue(day.seconds > 0 ? SleepSummary.duration(day.seconds) : "Chưa có dữ liệu".tr)
                    }
                    RuleMark(y: .value("Mục tiêu".tr, goal))
                        .foregroundStyle(Color(hex: "B18A45"))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: 0...max(goal + 2, (visibleDays.map(\.hours).max() ?? 0) + 1))
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: period == .month ? 7 : 1)) {
                    AxisValueLabel(format: .dateTime.day())
                } }
                .frame(height: 165)
                Text("Nét đứt: mục tiêu %@ giờ • Ngày trống không tính vào trung bình.".tr(goal.formatted()))
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
            comparisonSummary
            Stepper(value: $goal, in: 6...10, step: 0.5) {
                Text("Mục tiêu của bạn: %@ giờ".tr(goal.formatted()))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            Text("Mục tiêu dùng cho phần thưởng trong game, không phải đánh giá sức khỏe.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }.padding(20).modifier(AccountPanel())
    }

    private var previousDays: [SleepDay] {
        let previousDate = Calendar.current.date(byAdding: period.component, value: -1, to: selectedDate)!
        let previous = Calendar.current.dateInterval(of: period.component, for: previousDate)!
        // Compare the same elapsed portion when the selected period is still in progress.
        let cutoff: Date
        if interval.contains(Date()) {
            let elapsed = Calendar.current.dateComponents([.day], from: interval.start,
                                                          to: Calendar.current.startOfDay(for: Date())).day! + 1
            cutoff = min(previous.end, Calendar.current.date(byAdding: .day, value: elapsed, to: previous.start)!)
        } else { cutoff = previous.end }
        return health.days.filter { $0.date >= previous.start && $0.date < cutoff }
    }

    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("So sánh & đánh giá".tr, systemImage: "chart.line.uptrend.xyaxis").font(.headline)
            if let current = SleepJournal.average(visibleDays) {
                if let previous = SleepJournal.average(previousDays) {
                    let delta = current - previous
                    Text(abs(delta) < 60 ? "Trung bình tương đương kỳ trước.".tr : (delta >= 0 ? "Trung bình tăng %@ so với kỳ trước.".tr(SleepSummary.duration(abs(delta))) : "Trung bình giảm %@ so với kỳ trước.".tr(SleepSummary.duration(abs(delta)))))
                } else { Text("Chưa đủ dữ liệu kỳ trước để so sánh.".tr) }
                Text("%d/%d ngày có dữ liệu đạt mục tiêu %@ giờ.".tr(recordedDays.filter { $0.hours >= goal }.count, recordedDays.count, goal.formatted()))
                Text(current >= goal * 3600 ? "Thời lượng trung bình đạt mục tiêu bạn đặt.".tr : "Thời lượng trung bình còn thiếu %@ so với mục tiêu bạn đặt.".tr(SleepSummary.duration(goal * 3600 - current)))
            } else { Text("Ghi thêm giấc ngủ để xem đánh giá theo mục tiêu cá nhân.".tr) }
            Text("So sánh trung bình các ngày có dữ liệu; kỳ hiện tại chỉ so với cùng số ngày đã qua ở kỳ trước. Thời lượng không phản ánh đầy đủ chất lượng giấc ngủ.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }.font(.subheadline)
    }

    private var manualJournalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Nhật ký".tr, systemImage: "book.closed").font(.headline)
                Spacer()
                NavigationLink {
                    SleepJournalHistoryView(health: health)
                } label: {
                    Label("Tất cả".tr, systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                }
                .accessibilityLabel("Xem tất cả nhật ký giấc ngủ".tr)
            }
            if health.manualEntries.isEmpty {
                Text("Chưa có bản ghi thủ công.".tr)
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
            }
            ForEach(Array(health.manualEntries.sorted { $0.end > $1.end }.prefix(2))) { entry in
                SleepJournalEntryRow(entry: entry)
                Divider().overlay(AccountStyle.border.opacity(0.4))
            }
            NavigationLink {
                SleepHealthSettingsView(health: health)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill").foregroundStyle(AccountStyle.green)
                    Text("Apple Health").font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold))
                }
                .padding(.vertical, 12).padding(.horizontal, 14)
                .background(AccountStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }.padding(20).modifier(AccountPanel())
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Khu vườn nghỉ ngơi".tr, systemImage: "leaf.fill")
                .font(.system(.headline, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(visibleDays) { day in
                    VStack(spacing: 4) {
                        Image(systemName: day.hours >= goal ? "leaf.fill" : day.seconds > 0 ? "moon.fill" : "circle.dotted")
                            .foregroundStyle(day.hours >= goal ? AccountStyle.green : AccountStyle.muted.opacity(0.7))
                        Text(day.date.formatted(.dateTime.day())).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(AccountStyle.green.opacity(day.hours >= goal ? 0.12 : 0.03), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.seconds > 0 ? SleepSummary.duration(day.seconds) : "chưa có dữ liệu".tr)")
                }
            }
            Text("%d ngày đạt mục tiêu trong kỳ. Mỗi chiếc lá là một ngày bạn dành thời gian cho mình.".tr(visibleDays.filter { $0.hours >= goal }.count))
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Text("Không mất cây hay phần thưởng khi bạn có một đêm ngủ ít.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }.padding(20).modifier(AccountPanel())
    }

    private var rewardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Quà cho khu vườn".tr, systemImage: "gift.fill")
                .font(.system(.headline, design: .rounded))
            Text("Mỗi ngày đạt mục tiêu: 1.000 Oxy. Mỗi 7 ngày liên tiếp: 10 gem. Trọn một tháng dương lịch: 20 gem + 1 ticket. Các phần thưởng được cộng dồn.".tr)
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            if garden.gradenModel == nil {
                Text("Hãy đăng nhập và tải khu vườn để nhận quà.".tr).font(.subheadline)
            } else if eligibleRewards.isEmpty {
                Label("Quà mới sẽ chờ khi có giấc ngủ đạt mục tiêu.".tr, systemImage: "sparkles")
                    .font(.subheadline)
            } else {
                ForEach(eligibleRewards) { grant in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(grant.title).font(.system(.subheadline, design: .rounded, weight: .bold))
                            Text(grant.prize).font(.caption)
                        }
                        Spacer()
                        Button {
                            Task { await rewards.claim(grant, goal: goal) }
                        } label: {
                            Label("Nhận quà".tr, systemImage: grant.kind == .daily ? "leaf.fill" : "gift.fill")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .padding(12)
                                .foregroundStyle(AccountStyle.cream)
                                .background(AccountStyle.green, in: Capsule())
                        }
                        .disabled(rewards.isClaiming || rewards.isLoading || health.isSyncing)
                    }
                }
            }
            Text("Nhận bù trong 7 ngày kể từ ngày hoàn thành mốc. Một ngày chỉ tính cho một mốc tuần; mốc tháng vẫn được cộng thêm.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
            if rewards.isClaiming { ProgressView("Đang gửi quà vào vườn…".tr).font(.caption) }
        }.padding(20).modifier(AccountPanel())
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            notice("Chưa có dữ liệu giấc ngủ".tr, icon: "moon.zzz")
            Text("Bạn có thể ghi thủ công ngay cả khi không có Apple Watch, hoặc kết nối Apple Health để đọc dữ liệu được chia sẻ.".tr)
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Button("Hướng dẫn kết nối".tr) { showHelp = true }.font(.subheadline.bold())
        }.padding(20).modifier(AccountPanel())
    }

    private var privacyNote: some View {
        Text("Giấc ngủ từ Apple Health và nhật ký thủ công chỉ được xử lý trên thiết bị. Nhật ký được lưu cục bộ; bản ghi bạn chọn đồng bộ sẽ được ghi sang Apple Health. Tài khoản game lưu dấu ngày đã nhận quà, không lưu thời lượng hay các giai đoạn ngủ. Một ngày thống kê tính từ 12h trưa hôm trước đến 12h trưa ngày đó.".tr)
            .font(.caption).foregroundStyle(AccountStyle.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("1. Mở Sức khỏe (Apple Health), tìm Giấc ngủ và kiểm tra đã có dữ liệu từ Apple Watch hoặc ứng dụng ghi giấc ngủ.".tr)
                    Text("2. Trong Sức khỏe, mở hồ sơ → Ứng dụng / quyền truy cập dữ liệu → Terrarium, cho phép đọc và, nếu muốn đồng bộ nhật ký thủ công, cho phép ghi Giấc ngủ. Tên mục có thể khác theo phiên bản iOS.".tr)
                    Text("3. Quay lại Terrarium. App tự đồng bộ khi hoạt động; bạn cũng có thể kéo xuống để thử lại.".tr)
                    Text("Bạn có thể dùng Lịch trình ngủ để đặt giờ nghỉ ngơi và Ghi giấc ngủ thủ công để bổ sung nhật ký. Terrarium không tự đo giấc ngủ. Đánh giá chỉ dựa trên mục tiêu cá nhân và cảm nhận tự ghi.".tr)
                    actionButton("Cấp quyền Health".tr, icon: "heart.fill") {
                        Task { await health.connect() }
                    }.disabled(health.isSyncing || !health.isAvailable)
                }.padding(24)
            }
            .background(AccountStyle.cream)
            .navigationTitle("Kết nối giấc ngủ".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong".tr) { showHelp = false } } }
        }.presentationDetents([.medium, .large])
    }

    private var periodTitle: String {
        if period == .month { return selectedDate.formatted(.dateTime.month(.wide).year()) }
        if period == .day { return selectedDate.formatted(date: .abbreviated, time: .omitted) }
        let end = Calendar.current.date(byAdding: .day, value: -1, to: interval.end)!
        return "\(interval.start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month().year()))"
    }

    private func move(_ value: Int) {
        selectedDate = Calendar.current.date(byAdding: period.component, value: value, to: selectedDate)!
    }

    private func notice(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon).font(.system(.subheadline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon) }
            .buttonStyle(SleepActionButtonStyle())
    }

}

private struct SleepGardenHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "E5E8CD")).frame(width: 100, height: 100)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 48)).foregroundStyle(Color(hex: "8D9360"))
                Image(systemName: "leaf.fill")
                    .font(.system(size: 27)).foregroundStyle(AccountStyle.green).offset(x: 32, y: 29)
            }.accessibilityHidden(true)
            Text("Bạn nghỉ ngơi, vườn thêm xanh".tr)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Một chút bình yên cho bạn và những chiếc lá.".tr)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 8)
    }
}

#Preview("Giấc ngủ · Góc vườn".tr) {
    SleepGardenHeader().padding(24).background(AccountStyle.cream)
}

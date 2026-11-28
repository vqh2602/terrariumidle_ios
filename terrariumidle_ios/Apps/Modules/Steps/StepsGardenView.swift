import Charts
import SwiftUI

private enum StepsPeriod: String, CaseIterable {
    case day = "Ngày", week = "Tuần", month = "Tháng"
    var component: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

struct StepsGardenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var health = StepsHealthStore.shared
    @ObservedObject private var garden = FireStoreService.shared
    @StateObject private var rewards = StepsRewards()
    @AppStorage(StepsSummary.goalStorageKey) private var rawGoal = StepsSummary.defaultGoal
    @State private var period: StepsPeriod = .week
    @State private var selectedDate = Date()
    @State private var showHelp = false

    private var goal: Int {
        StepsSummary.clampedGoal(rawGoal)
    }

    private var goalBinding: Binding<Int> {
        Binding(
            get: { goal },
            set: { rawGoal = StepsSummary.clampedGoal($0) }
        )
    }

    private var interval: DateInterval {
        Calendar.current.dateInterval(of: period.component, for: selectedDate)!
    }

    private var visibleDays: [StepsDay] {
        health.days.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private var recordedDays: [StepsDay] {
        visibleDays.filter { $0.steps > 0 }
    }

    private var average: Int {
        StepsSummary.average(visibleDays) ?? 0
    }

    private var today: StepsDay? { health.days.last }

    private var eligibleRewards: [StepsRewardGrant] {
        StepsRewardRules.available(
            days: health.days,
            goal: goal,
            claimed: rewards.claimed,
            weeklyDays: rewards.weeklyDays
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StepsGardenHeader()
                    if !health.isAvailable {
                        notice("Thiết bị này chưa hỗ trợ Apple Health để đọc số bước chân.".tr, icon: "heart.slash")
                    } else if !health.hasRequestedAccess {
                        connectionCard
                    }
                    todayCard
                    goalConfigCard
                    if let message = health.message { notice(message, icon: "exclamationmark.circle") }
                    if health.days.allSatisfy({ $0.steps == 0 }) && !health.isSyncing { emptyCard }
                    statisticsCard
                    appleHealthCard
                    journeyCard
                    rewardCard
                    privacyNote
                }
                .padding(20)
            }
            .background(Color(hex: "EDF0DD").ignoresSafeArea())
            .foregroundStyle(AccountStyle.ink)
            .navigationTitle("Bước chân".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                        .accessibilityLabel("Hướng dẫn kết nối Apple Health".tr)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Đóng".tr) { dismiss() }
                }
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
            .onChange(of: rawGoal) { _, _ in
                HealthRewardStatusStore.shared.recalculate(notifyIfNeeded: true)
            }
            .alert("Quà từ bước chân".tr, isPresented: Binding(
                get: { rewards.message != nil },
                set: { if !$0 { rewards.message = nil } }
            )) {
                Button("Đã hiểu".tr) { rewards.message = nil }
            } message: {
                Text(rewards.message ?? "")
            }
            .sheet(isPresented: $showHelp) { helpSheet }
        }
        .presentationDragIndicator(.visible)
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Vận động cùng khu vườn".tr, systemImage: "heart.text.clipboard.fill")
                .font(.system(.headline, design: .rounded))
            Text("Cho phép đọc số bước chân từ Apple Health. Mỗi lần mở Terrarium, thống kê bước chân sẽ tự cập nhật để bạn nhận quà cho vườn.".tr)
            Text("Chỉ đọc số bước chân • Không ghi dữ liệu vào Apple Health".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
            actionButton(health.isSyncing ? "Đang kết nối…".tr : "Kết nối Health".tr, icon: "heart.fill") {
                Task { await health.connect() }
            }
            .disabled(health.isSyncing)
            if let message = health.message { Text(message).font(.caption) }
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Bước chân hôm nay".tr, systemImage: "figure.walk")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if health.isSyncing {
                    ProgressView().accessibilityLabel("Đang đồng bộ bước chân".tr)
                }
            }
            if let today, today.steps > 0 {
                Text(StepsSummary.countLabel(today.steps))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                ProgressView(value: min(Double(today.steps) / Double(goal), 1))
                    .tint(AccountStyle.green)
                if today.steps >= goal {
                    Text("Bạn đã đạt mục tiêu hôm nay, khu vườn thêm sức sống.".tr)
                        .font(.subheadline).foregroundStyle(AccountStyle.muted)
                } else {
                    Text("Còn thiếu %@ nữa để đạt mục tiêu hôm nay.".tr(StepsSummary.countLabel(goal - today.steps)))
                        .font(.subheadline).foregroundStyle(AccountStyle.muted)
                }
                if rewards.claimed.contains(today.id) {
                    Label("Đã nhận quà hôm nay".tr, systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AccountStyle.green)
                }
            } else {
                Text("Đang chờ dữ liệu bước chân".tr)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Kết nối và đồng bộ từ Apple Health để cập nhật số bước chân hôm nay.".tr)
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
            }
            if let lastSync = health.lastSync {
                Text("Đồng bộ gần nhất: %@".tr(lastSync.formatted(date: .abbreviated, time: .shortened)))
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
            if health.isAvailable && health.hasRequestedAccess {
                actionButton(health.isSyncing ? "Đang đồng bộ…".tr : "Đồng bộ từ Apple Health".tr,
                             icon: "arrow.triangle.2.circlepath") {
                    Task { await health.sync() }
                }
                .disabled(health.isSyncing)
            }
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var goalConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Mục tiêu mỗi ngày".tr, systemImage: "target")
                .font(.system(.headline, design: .rounded))
            Stepper(value: goalBinding, in: StepsSummary.minGoal...StepsSummary.maxGoal, step: StepsSummary.goalStep) {
                Text("Đạt mục tiêu: %@ / ngày".tr(StepsSummary.countLabel(goal)))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StepsSummary.presetGoals, id: \.self) { preset in
                        Button {
                            rawGoal = preset
                        } label: {
                            Text(StepsSummary.formatted(preset))
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(goal == preset ? AccountStyle.cream : AccountStyle.green)
                                .background(
                                    goal == preset ? AccountStyle.green : AccountStyle.green.opacity(0.08),
                                    in: Capsule()
                                )
                                .overlay {
                                    Capsule().strokeBorder(AccountStyle.green.opacity(goal == preset ? 0 : 0.2), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Text("Mục tiêu dùng cho phần thưởng trong game, không phải đánh giá sức khỏe.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nhật ký bước chân".tr, systemImage: "chart.bar.xaxis")
                .font(.system(.headline, design: .rounded))
            Picker("Thống kê theo".tr, selection: $period) {
                ForEach(StepsPeriod.allCases, id: \.self) { Text($0.rawValue.tr).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").padding(8) }
                    .accessibilityLabel("Xem kỳ trước".tr)
                    .disabled(interval.start <= (health.days.first?.date ?? .now))
                Spacer(minLength: 0)
                Text(periodTitle)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                Button { move(1) } label: { Image(systemName: "chevron.right").padding(8) }
                    .accessibilityLabel("Xem kỳ tiếp theo".tr)
                    .disabled(interval.contains(Date()))
            }
            if recordedDays.isEmpty {
                notice("Chưa có dữ liệu trong khoảng thời gian này.".tr, icon: "figure.walk")
            } else {
                Text(period == .day
                     ? StepsSummary.countLabel(average)
                     : "Trung bình %@ / ngày có dữ liệu".tr(StepsSummary.countLabel(average)))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Chart {
                    ForEach(visibleDays) { day in
                        BarMark(x: .value("Ngày".tr, day.date, unit: .day), y: .value("Bước chân".tr, day.steps))
                            .foregroundStyle(day.steps >= goal ? AccountStyle.green : Color(hex: "A9B88D"))
                            .cornerRadius(4)
                            .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue(day.steps > 0 ? StepsSummary.countLabel(day.steps) : "Chưa có dữ liệu".tr)
                    }
                    RuleMark(y: .value("Mục tiêu".tr, goal))
                        .foregroundStyle(Color(hex: "B18A45"))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: 0...max(goal + 2_000, (visibleDays.map(\.steps).max() ?? 0) + 1_000))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: period == .month ? 7 : 1)) {
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
                .frame(height: 165)
                Text("Nét đứt: mục tiêu %@ • Ngày trống không tính vào trung bình.".tr(StepsSummary.countLabel(goal)))
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
            comparisonSummary
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var previousDays: [StepsDay] {
        let previousDate = Calendar.current.date(byAdding: period.component, value: -1, to: selectedDate)!
        let previous = Calendar.current.dateInterval(of: period.component, for: previousDate)!
        // Compare the same elapsed portion when the selected period is still in progress.
        let cutoff: Date
        if interval.contains(Date()) {
            let elapsed = Calendar.current.dateComponents([.day], from: interval.start,
                                                          to: Calendar.current.startOfDay(for: Date())).day! + 1
            cutoff = min(previous.end, Calendar.current.date(byAdding: .day, value: elapsed, to: previous.start)!)
        } else {
            cutoff = previous.end
        }
        return health.days.filter { $0.date >= previous.start && $0.date < cutoff }
    }

    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("So sánh & đánh giá".tr, systemImage: "chart.line.uptrend.xyaxis").font(.headline)
            if let current = StepsSummary.average(visibleDays) {
                if let previous = StepsSummary.average(previousDays) {
                    let delta = current - previous
                    if abs(delta) < 50 {
                        Text("Trung bình tương đương kỳ trước.".tr)
                    } else if delta >= 0 {
                        Text("Trung bình tăng %@ so với kỳ trước.".tr(StepsSummary.countLabel(abs(delta))))
                    } else {
                        Text("Trung bình giảm %@ so với kỳ trước.".tr(StepsSummary.countLabel(abs(delta))))
                    }
                } else {
                    Text("Chưa đủ dữ liệu kỳ trước để so sánh.".tr)
                }
                Text("%d/%d ngày có dữ liệu đạt mục tiêu %@.".tr(
                    recordedDays.filter { $0.steps >= goal }.count,
                    recordedDays.count,
                    StepsSummary.countLabel(goal)
                ))
                if current >= goal {
                    Text("Số bước trung bình đạt mục tiêu bạn đặt.".tr)
                } else {
                    Text("Số bước trung bình còn thiếu %@ so với mục tiêu bạn đặt.".tr(StepsSummary.countLabel(goal - current)))
                }
            } else {
                Text("Đồng bộ bước chân để xem đánh giá theo mục tiêu cá nhân.".tr)
            }
            Text("So sánh trung bình các ngày có dữ liệu; kỳ hiện tại chỉ so với cùng số ngày đã qua ở kỳ trước.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }
        .font(.subheadline)
    }

    private var appleHealthCard: some View {
        NavigationLink {
            StepsHealthSettingsView(health: health)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill").foregroundStyle(AccountStyle.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.subheadline.weight(.semibold))
                    Text("Cấp quyền & đồng bộ số bước chân".tr)
                        .font(.caption)
                        .foregroundStyle(AccountStyle.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.bold))
            }
            .padding(18)
            .modifier(AccountPanel())
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Khu vườn bước chân".tr, systemImage: "leaf.fill")
                .font(.system(.headline, design: .rounded))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(visibleDays) { day in
                    VStack(spacing: 4) {
                        Image(systemName: day.steps >= goal ? "leaf.fill" : day.steps > 0 ? "figure.walk" : "circle.dotted")
                            .foregroundStyle(day.steps >= goal ? AccountStyle.green : AccountStyle.muted.opacity(0.7))
                        Text(day.date.formatted(.dateTime.day())).font(.caption2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(AccountStyle.green.opacity(day.steps >= goal ? 0.12 : 0.03),
                                in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.steps > 0 ? StepsSummary.countLabel(day.steps) : "chưa có dữ liệu".tr)")
                }
            }
            Text("%d ngày đạt mục tiêu trong kỳ. Mỗi chiếc lá là một ngày bạn vận động cho mình.".tr(visibleDays.filter { $0.steps >= goal }.count))
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Text("Không mất cây hay phần thưởng khi bạn đi ít bước hơn.".tr)
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }
        .padding(20)
        .modifier(AccountPanel())
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
                Label("Quà mới sẽ chờ khi số bước chân đạt mục tiêu.".tr, systemImage: "sparkles")
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
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            notice("Chưa có dữ liệu bước chân".tr, icon: "figure.walk")
            Text("Hãy kết nối Apple Health để Terrarium đồng bộ số bước chân từ iPhone hoặc Apple Watch của bạn.".tr)
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Button("Hướng dẫn kết nối".tr) { showHelp = true }.font(.subheadline.bold())
        }
        .padding(20)
        .modifier(AccountPanel())
    }

    private var privacyNote: some View {
        Text("Số bước chân từ Apple Health chỉ được xử lý trên thiết bị. Tài khoản game lưu dấu ngày đã nhận quà, không lưu số bước chân chi tiết của bạn. Một ngày thống kê tính từ 00:00 đến 24:00 theo giờ thiết bị.".tr)
            .font(.caption).foregroundStyle(AccountStyle.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("1. Mở Sức khỏe (Apple Health), kiểm tra mục Số bước đã có dữ liệu từ iPhone hoặc Apple Watch.".tr)
                    Text("2. Trong Sức khỏe, mở hồ sơ → Ứng dụng / quyền truy cập dữ liệu → Terrarium và cho phép đọc Số bước. Tên mục có thể khác theo phiên bản iOS.".tr)
                    Text("3. Quay lại Terrarium. App tự đồng bộ khi hoạt động; bạn cũng có thể bấm Đồng bộ hoặc kéo xuống để làm mới.".tr)
                    actionButton("Cấp quyền Health".tr, icon: "heart.fill") {
                        Task { await health.connect() }
                    }
                    .disabled(health.isSyncing || !health.isAvailable)
                }
                .padding(24)
            }
            .background(AccountStyle.cream)
            .navigationTitle("Kết nối bước chân".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong".tr) { showHelp = false } } }
        }
        .presentationDetents([.medium, .large])
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
        Label(text, systemImage: icon)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon) }
            .buttonStyle(SleepActionButtonStyle())
    }
}

struct StepsHealthSettingsView: View {
    @ObservedObject var health: StepsHealthStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Kết nối bước chân".tr, systemImage: "heart.fill")
                        .font(.system(.headline, design: .rounded))
                    Text("Đọc dữ liệu số bước chân hằng ngày từ Apple Health.".tr)
                        .font(.subheadline).foregroundStyle(AccountStyle.muted)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 12) { healthButtons }
                        VStack(alignment: .leading, spacing: 12) { healthButtons }
                    }
                    if health.isSyncing { ProgressView("Đang đồng bộ…".tr).font(.caption) }
                    if let message = health.message {
                        Text(message).font(.caption).foregroundStyle(AccountStyle.muted)
                    }
                    if !health.isAvailable {
                        Text("Apple Health chưa khả dụng trên thiết bị này.".tr).font(.subheadline)
                    }
                }
                .padding(20)
                .modifier(AccountPanel())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Cách đồng bộ".tr).font(.headline)
                    Text("Terrarium dùng tổng số bước theo từng ngày từ Apple Health (tự gộp iPhone và Apple Watch để không bị tính trùng).".tr)
                    Text("Mỗi lần bạn mở app hoặc kéo làm mới trong màn hình Bước chân, dữ liệu sẽ được cập nhật tự động.".tr)
                }
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
                .padding(20)
                .modifier(AccountPanel())
            }
            .padding(20)
        }
        .background(Color(hex: "EDF0DD").ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AccountStyle.green)
    }

    @ViewBuilder private var healthButtons: some View {
        Button { Task { await health.connect() } } label: {
            Label("Cấp quyền".tr, systemImage: "heart.text.clipboard")
        }
        .buttonStyle(SleepActionButtonStyle(prominent: false))
        .disabled(health.isSyncing || !health.isAvailable)

        Button { Task { await health.sync() } } label: {
            Label("Đồng bộ".tr, systemImage: "arrow.triangle.2.circlepath")
        }
        .buttonStyle(SleepActionButtonStyle())
        .disabled(!health.hasRequestedAccess || health.isSyncing || !health.isAvailable)
    }
}

private struct StepsGardenHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: "DCE8D4")).frame(width: 100, height: 100)
                Image(systemName: "figure.walk")
                    .font(.system(size: 46, weight: .semibold)).foregroundStyle(AccountStyle.green)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 27)).foregroundStyle(Color(hex: "8D9360")).offset(x: 32, y: 29)
            }
            .accessibilityHidden(true)
            Text("Mỗi bước chân, vườn thêm xanh".tr)
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Từng bước nhỏ mỗi ngày mang sức sống về khu vườn.".tr)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview("Bước chân · Góc vườn".tr) {
    StepsGardenView()
}

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
                    if !health.isAvailable {
                        notice("Thiết bị này chưa hỗ trợ Apple Health.", icon: "heart.slash")
                    } else if !health.hasRequestedAccess {
                        connectionCard
                    } else {
                        tonightCard
                        if let message = health.message {
                            notice(message, icon: "exclamationmark.circle")
                        }
                        if health.days.allSatisfy({ $0.seconds == 0 }) && !health.isSyncing {
                            emptyCard
                        }
                        statisticsCard
                        journeyCard
                        rewardCard
                    }
                    privacyNote
                }
                .padding(20)
            }
            .background(Color(hex: "EDF0DD").ignoresSafeArea())
            .foregroundStyle(AccountStyle.ink)
            .navigationTitle("Giấc ngủ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHelp = true } label: { Image(systemName: "questionmark.circle") }
                        .accessibilityLabel("Hướng dẫn kết nối Apple Health")
                }
                ToolbarItem(placement: .confirmationAction) { Button("Đóng") { dismiss() } }
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
            .alert("Quà từ giấc ngủ", isPresented: Binding(
                get: { rewards.message != nil }, set: { if !$0 { rewards.message = nil } }
            )) { Button("Đã hiểu") { rewards.message = nil } }
            message: { Text(rewards.message ?? "") }
            .sheet(isPresented: $showHelp) { helpSheet }
        }
        .presentationDragIndicator(.visible)
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nghỉ ngơi cùng khu vườn", systemImage: "heart.text.clipboard.fill")
                .font(.system(.headline, design: .rounded))
            Text("Cho phép đọc giấc ngủ từ Apple Health. Mỗi lần mở Terrarium, nhật ký sẽ tự cập nhật để bạn nhận quà cho vườn.")
            Text("Chỉ đọc giấc ngủ • Không ghi dữ liệu sức khỏe")
                .font(.caption).foregroundStyle(AccountStyle.muted)
            actionButton(health.isSyncing ? "Đang kết nối…" : "Kết nối Apple Health", icon: "heart.fill") {
                Task { await health.connect() }
            }.disabled(health.isSyncing)
            if let message = health.message { Text(message).font(.caption) }
        }.padding(20).modifier(AccountPanel())
    }

    private var tonightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Giấc ngủ hôm nay", systemImage: "moon.zzz.fill")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if health.isSyncing { ProgressView().accessibilityLabel("Đang đồng bộ giấc ngủ") }
            }
            if let today, today.seconds > 0 {
                Text(SleepSummary.duration(today.seconds))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                ProgressView(value: min(today.hours / goal, 1)).tint(AccountStyle.green)
                Text(today.hours >= goal ? "Một đêm nghỉ ngơi, thêm sức sống cho vườn." : "Cảm ơn bạn đã dành thời gian nghỉ ngơi.")
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
                if rewards.claimed.contains(today.id) {
                    Label("Đã nhận quà hôm nay", systemImage: "checkmark.seal.fill").foregroundStyle(AccountStyle.green)
                }
            } else {
                Text("Đang chờ giấc ngủ mới")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Dữ liệu sẽ xuất hiện khi nguồn ghi giấc ngủ cập nhật vào Apple Health.")
                    .font(.subheadline).foregroundStyle(AccountStyle.muted)
            }
            if let lastSync = health.lastSync {
                Text("Đồng bộ gần nhất: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
        }.padding(20).modifier(AccountPanel())
    }

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Nhật ký nghỉ ngơi", systemImage: "chart.bar.xaxis")
                .font(.system(.headline, design: .rounded))
            Picker("Thống kê theo", selection: $period) {
                ForEach(SleepPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            HStack {
                Button { move(-1) } label: { Image(systemName: "chevron.left").padding(8) }
                    .accessibilityLabel("Xem kỳ trước")
                    .disabled(interval.start <= (health.days.first?.date ?? .now))
                Spacer(minLength: 0)
                Text(periodTitle).font(.system(.subheadline, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer(minLength: 0)
                Button { move(1) } label: { Image(systemName: "chevron.right").padding(8) }
                    .accessibilityLabel("Xem kỳ tiếp theo")
                    .disabled(interval.contains(Date()))
            }
            if recordedDays.isEmpty {
                notice("Chưa có dữ liệu trong khoảng thời gian này.", icon: "moon")
            } else {
                Text(period == .day ? SleepSummary.duration(average) : "Trung bình \(SleepSummary.duration(average)) / ngày có dữ liệu")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Chart {
                    ForEach(visibleDays) { day in
                        BarMark(x: .value("Ngày", day.date, unit: .day), y: .value("Giờ ngủ", day.hours))
                            .foregroundStyle(day.hours >= goal ? AccountStyle.green : Color(hex: "A9B88D"))
                            .cornerRadius(4)
                            .accessibilityLabel(day.date.formatted(date: .abbreviated, time: .omitted))
                            .accessibilityValue(day.seconds > 0 ? SleepSummary.duration(day.seconds) : "Chưa có dữ liệu")
                    }
                    RuleMark(y: .value("Mục tiêu", goal))
                        .foregroundStyle(Color(hex: "B18A45"))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: 0...max(goal + 2, (visibleDays.map(\.hours).max() ?? 0) + 1))
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: period == .month ? 7 : 1)) {
                    AxisValueLabel(format: .dateTime.day())
                } }
                .frame(height: 165)
                Text("Nét đứt: mục tiêu \(goal.formatted()) giờ • Ngày trống không tính vào trung bình.")
                    .font(.caption).foregroundStyle(AccountStyle.muted)
            }
            Stepper(value: $goal, in: 6...10, step: 0.5) {
                Text("Mục tiêu của bạn: \(goal.formatted()) giờ")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            Text("Mục tiêu dùng cho phần thưởng trong game, không phải đánh giá sức khỏe.")
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }.padding(20).modifier(AccountPanel())
    }

    private var journeyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Khu vườn nghỉ ngơi", systemImage: "leaf.fill")
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
                    .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.seconds > 0 ? SleepSummary.duration(day.seconds) : "chưa có dữ liệu")")
                }
            }
            Text("\(visibleDays.filter { $0.hours >= goal }.count) ngày đạt mục tiêu trong kỳ. Mỗi chiếc lá là một ngày bạn dành thời gian cho mình.")
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Text("Không mất cây hay phần thưởng khi bạn có một đêm ngủ ít.")
                .font(.caption).foregroundStyle(AccountStyle.muted)
        }.padding(20).modifier(AccountPanel())
    }

    private var rewardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Quà cho khu vườn", systemImage: "gift.fill")
                .font(.system(.headline, design: .rounded))
            Text("Mỗi ngày đạt mục tiêu: 1.000 Oxy. Mỗi 7 ngày liên tiếp: 10 gem. Trọn một tháng dương lịch: 20 gem + 1 ticket. Các phần thưởng được cộng dồn.")
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            if garden.gradenModel == nil {
                Text("Hãy đăng nhập và tải khu vườn để nhận quà.").font(.subheadline)
            } else if eligibleRewards.isEmpty {
                Label("Quà mới sẽ chờ khi có giấc ngủ đạt mục tiêu.", systemImage: "sparkles")
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
                            Label("Nhận quà", systemImage: grant.kind == .daily ? "leaf.fill" : "gift.fill")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .padding(12)
                                .foregroundStyle(AccountStyle.cream)
                                .background(AccountStyle.green, in: Capsule())
                        }
                        .disabled(rewards.isClaiming || rewards.isLoading || health.isSyncing)
                    }
                }
            }
            Text("Nhận bù trong 7 ngày kể từ ngày hoàn thành mốc. Một ngày chỉ tính cho một mốc tuần; mốc tháng vẫn được cộng thêm.")
                .font(.caption).foregroundStyle(AccountStyle.muted)
            if rewards.isClaiming { ProgressView("Đang gửi quà vào vườn…").font(.caption) }
        }.padding(20).modifier(AccountPanel())
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            notice("Chưa có dữ liệu giấc ngủ", icon: "moon.zzz")
            Text("Hãy kiểm tra Apple Health đã có bản ghi giấc ngủ và Terrarium được phép đọc. Nếu bạn chưa cấp quyền, app cũng sẽ chưa thấy dữ liệu.")
                .font(.subheadline).foregroundStyle(AccountStyle.muted)
            Button("Hướng dẫn kết nối") { showHelp = true }.font(.subheadline.bold())
        }.padding(20).modifier(AccountPanel())
    }

    private var privacyNote: some View {
        Text("Giấc ngủ được đọc từ Apple Health và chỉ xử lý trên thiết bị. Tài khoản game lưu dấu ngày đã nhận quà, không lưu thời lượng hay các giai đoạn ngủ. Một ngày thống kê tính từ 12h trưa hôm trước đến 12h trưa ngày đó.")
            .font(.caption).foregroundStyle(AccountStyle.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("1. Mở Sức khỏe (Apple Health), tìm Giấc ngủ và kiểm tra đã có dữ liệu từ Apple Watch hoặc ứng dụng ghi giấc ngủ.")
                    Text("2. Trong Sức khỏe, mở hồ sơ → Ứng dụng / quyền truy cập dữ liệu → Terrarium, cho phép đọc Giấc ngủ. Tên mục có thể khác theo phiên bản iOS.")
                    Text("3. Quay lại Terrarium. App tự đồng bộ khi hoạt động; bạn cũng có thể kéo xuống để thử lại.")
                    Text("Terrarium chỉ thống kê dữ liệu được chia sẻ, không tự đo giấc ngủ hay chẩn đoán sức khỏe.")
                    actionButton("Kiểm tra quyền Apple Health", icon: "heart.fill") {
                        Task { await health.connect() }
                    }.disabled(health.isSyncing || !health.isAvailable)
                }.padding(24)
            }
            .background(AccountStyle.cream)
            .navigationTitle("Kết nối giấc ngủ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { showHelp = false } } }
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
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity).padding(15)
                .foregroundStyle(AccountStyle.cream)
                .background(AccountStyle.green, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
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
            Text("Bạn nghỉ ngơi, vườn thêm xanh")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
            Text("Một chút bình yên cho bạn và những chiếc lá.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AccountStyle.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 8)
    }
}

#Preview("Giấc ngủ · Góc vườn") {
    SleepGardenHeader().padding(24).background(AccountStyle.cream)
}

import Combine
import SwiftUI

@MainActor
final class EventViewModel: ObservableObject {
    @Published var events: [TerrariumEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            var request = URLRequest(url: TerrariumEvent.feedURL)
            request.timeoutInterval = 30
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
            events = try JSONDecoder().decode(TerrariumEvent.Feed.self, from: data).data.reversed()
        } catch is CancellationError {
        } catch {
            self.error = "Không tải được sự kiện. Vui lòng thử lại.".tr
        }
    }
}

struct EventView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var model = EventViewModel()
    @StateObject private var store = FireStoreService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedEvent: TerrariumEvent?
    @State private var message: String?
    @State private var showVIPSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }.accessibilityLabel("Quay lại".tr)
                Spacer()
                Text("Sự kiện".tr).font(.system(.title2, design: .rounded, weight: .bold))
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }.padding(.horizontal)
            if model.isLoading && model.events.isEmpty {
                Spacer()
                ProgressView("Đang tải sự kiện…".tr)
                Spacer()
            } else if let error = model.error, model.events.isEmpty {
                Spacer()
                Text(error).multilineTextAlignment(.center).padding()
                Button("Thử lại".tr) { Task { await model.load() } }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 18) {
                        if !SubscriptionManager.isVIP(gardenModel: store.gradenModel) {
                            VIPPromoBanner(
                                title: "Terrarium VIP · ×2 quà Điểm danh 30 ngày".tr,
                                subtitle: "Nhận gấp đôi Oxygen, Đá quý, Vé, Phân bón, Xẻng & mở khóa toàn bộ âm thanh, hiệu ứng →".tr
                            ) {
                                showVIPSheet = true
                            }
                        }
                        if let error = model.error { Text(error).foregroundStyle(.secondary) }
                        if model.events.isEmpty { Text("Chưa có sự kiện mới".tr).padding(40) }
                        ForEach(model.events) { event in
                            eventCard(event)
                        }
                    }.frame(maxWidth: 600).padding(20).frame(maxWidth: .infinity)
                }.refreshable { await model.load() }
            }
        }
        .foregroundStyle(AccountStyle.ink)
        .background(AccountStyle.cream.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await model.load() }
        .sheet(item: $selectedEvent) { event in
            if let url = event.webURL(garden: store.gradenModel) {
                EventWebScreen(event: event, url: url)
            }
        }
        .sheet(isPresented: $showVIPSheet) {
            SubscriptionView(isSheet: true, highlightContext: "Nâng cấp VIP để nhân đôi phần thưởng điểm danh 30 ngày hàng tháng!".tr)
        }
        .alert("Sự kiện".tr, isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("Đóng".tr, role: .cancel) { message = nil }
        } message: { Text(message ?? "") }
    }

    private func eventCard(_ event: TerrariumEvent) -> some View {
        let content = event.content()
        let reason = event.unavailableReason()
        return Button {
            if let reason { message = reason }
            else if event.webURL(garden: store.gradenModel) == nil { message = "Không mở được sự kiện. Vui lòng kiểm tra thông tin tài khoản.".tr }
            else { selectedEvent = event }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                AsyncImage(url: URL(string: content?.image ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "gift.fill").font(.largeTitle)
                        .frame(maxWidth: .infinity).frame(height: 140)
                        .background(AccountStyle.green.opacity(0.08))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(content?.title ?? "Sự kiện".tr).font(.headline)
                    Text(content?.description ?? "").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(event.start) – \(event.end)").font(.caption).foregroundStyle(.secondary)
                    Text(reason ?? "Tham gia sự kiện →".tr).font(.subheadline.bold())
                        .foregroundStyle(reason == nil ? AccountStyle.green : AccountStyle.muted)
                }.padding([.horizontal, .bottom], 16)
            }
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(reason == nil ? 1 : 0.65)
        }.buttonStyle(.plain)
    }
}

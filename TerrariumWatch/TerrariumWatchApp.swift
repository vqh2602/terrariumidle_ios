import Combine
import SwiftUI
import WatchConnectivity
import WidgetKit

@main
struct TerrariumWatchApp: App {
    @StateObject private var receiver = WatchGardenReceiver()
    @Environment(\.scenePhase) private var phase
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                GardenClockView(snapshot: receiver.snapshot, showClock: false)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .tag(0)
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(receiver.snapshot.display.accent.color.opacity(0.18))
                            .frame(width: 48, height: 48)
                        Image(systemName: "moon.stars.fill")
                            .font(.title2)
                            .foregroundStyle(receiver.snapshot.display.accent.color)
                    }
                    if receiver.snapshot.enabled,
                       let seconds = receiver.snapshot.sleepSeconds,
                       let measured = receiver.snapshot.sleepMeasuredAt,
                       Date().timeIntervalSince(measured) < 24 * 3600 {
                        Text(WatchText.value("Ngủ trong 24 giờ", language: receiver.snapshot.languageCode))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(WatchText.format("%d giờ %d phút", language: receiver.snapshot.languageCode, Int(seconds / 3600), Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        Text(WatchText.format("Cập nhật %@", language: receiver.snapshot.languageCode, measured.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(Locale(identifier: WatchText.language(receiver.snapshot.languageCode))))))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(WatchText.value("Chưa có dữ liệu ngủ được chia sẻ", language: receiver.snapshot.languageCode))
                            .font(.caption.weight(.semibold))
                        Text(WatchText.value("Bật kết nối trong Terrarium trên iPhone. Cây vẫn phát triển bình thường khi không có dữ liệu.", language: receiver.snapshot.languageCode))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .multilineTextAlignment(.center)
                .tag(1)
                WatchWeatherDetailView(snapshot: receiver.snapshot).tag(2)
            }
            .tabViewStyle(.verticalPage)
            .environment(\.locale, Locale(identifier: WatchText.language(receiver.snapshot.languageCode)))
            .task(id: phase) { if phase == .active { receiver.activate() } }
            .onOpenURL { url in selectedTab = url.host == "weather" ? 2 : 0 }
        }
        .backgroundTask(.watchConnectivity) { await receiver.finishBackgroundTransfer() }
    }
}

@MainActor
final class WatchGardenReceiver: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snapshot = WatchGardenCache.read()

    override init() {
        super.init()
        activate()
    }

    func finishBackgroundTransfer() async {
        activate()
        // Keep the SwiftUI background task alive until WCSession has delivered
        // its pending context. Cancellation releases the system's time budget.
        while !Task.isCancelled {
            let session = WCSession.default
            if session.activationState == .activated && !session.hasContentPending {
                receive(session.receivedApplicationContext)
                return
            }
            do { try await Task.sleep(for: .milliseconds(100)) }
            catch { return }
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        receive(session.receivedApplicationContext)
        if session.activationState == .activated && session.isReachable {
            session.sendMessage(["requestSnapshot": true], replyHandler: nil, errorHandler: nil)
        }
    }

    private func receive(_ context: [String: Any]) {
        guard let data = context[WatchGardenSnapshot.contextKey] as? Data,
              let next = try? JSONDecoder().decode(WatchGardenSnapshot.self, from: data),
              next.isValid else { return }
        snapshot = next
        WatchGardenCache.write(next)
        WidgetCenter.shared.reloadAllTimelines()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        if activationState == .activated && session.isReachable {
            session.sendMessage(["requestSnapshot": true], replyHandler: nil, errorHandler: nil)
        }
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.receive(applicationContext) }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.receive(message) }
    }
}

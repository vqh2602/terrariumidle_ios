import SwiftUI

struct SpeedDial: View {
    @State private var isOpen = false
    @State private var isIdle = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMusicSheet = false
    @State private var showEffectsSheet = false
    @State private var showWeatherSheet = false
    @State private var showSleepSheet = false
    @Binding var isEditing: Bool
    @Binding var backgroundRive: String
    @Binding var overlayRive: String?
    @EnvironmentObject var router: AppRouter
    @ObservedObject private var mailboxStore = MailboxStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                if isOpen {
                    Button(action: close) {
                        Color(hex: "263C2B").opacity(0.30)
                            .ignoresSafeArea()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Đóng menu khu vườn".tr)
                    .transition(.opacity)
                }

                VStack(alignment: .trailing, spacing: 14) {
                    if isOpen {
                        GardenMenuPanel(onSelect: select)
                        .frame(height: min(max(geometry.size.height - 100, 0), 390))
                        .padding(.bottom, 5)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    }
                    launcher
                }
                .frame(width: min(max(geometry.size.width - 32, 0), 340), alignment: .trailing)
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .task {
            await mailboxStore.loadIfNeeded()
        }
        .task(id: idleTimerKey) {
            isIdle = false
            guard !isOpen, !showMusicSheet, !showEffectsSheet, !showWeatherSheet, !showSleepSheet, scenePhase == .active else { return }
            do {
                try await Task.sleep(for: .seconds(4))
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: 0.6)) { isIdle = true }
            } catch { /* View disappearance or interaction cancels the idle delay. */ }
        }
        .sheet(isPresented: $showSleepSheet) {
            SleepGardenView()
        }
        .sheet(isPresented: $showWeatherSheet) {
            GardenWeatherSheet()
        }
        .sheet(isPresented: $showMusicSheet) {
            MusicSheetView()
        }
        .sheet(isPresented: $showEffectsSheet) {
            EffectsSheetView(backgroundRive: $backgroundRive, overlayRive: $overlayRive)
        }
    }

    private var idleTimerKey: String {
        "\(isOpen)-\(showMusicSheet)-\(showEffectsSheet)-\(showWeatherSheet)-\(showSleepSheet)-\(scenePhase)"
    }

    private var launcher: some View {
        Button {
            AudioPlayer.shared.playTap()
            isIdle = false
            withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.85)) {
                isOpen.toggle()
            }
        } label: {
            Image(systemName: isOpen ? "xmark" : "square.grid.2x2.fill")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(AccountStyle.cream)
                .frame(width: 56, height: 56)
                .background {
                    Circle().fill(LinearGradient(colors: [Color(hex: "77995C"), AccountStyle.green],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay { Circle().strokeBorder(AccountStyle.cream.opacity(0.8), lineWidth: 2) }
                .overlay { Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1).padding(5) }
                .compositingGroup()
                .shadow(color: Color(hex: "354D2C").opacity(0.75), radius: 0, y: 4)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 5)
                // Fade the artwork, keeping the Button's hit region fully active.
                .opacity(isIdle && !isOpen ? 0.35 : 1)
                .overlay(alignment: .topTrailing) {
                    if !isOpen && mailboxStore.unreadCount > 0 {
                        Circle()
                            .fill(Color(hex: "D95D39"))
                            .frame(width: 13, height: 13)
                            .overlay { Circle().strokeBorder(AccountStyle.cream, lineWidth: 2) }
                            .offset(x: 1, y: -1)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(true)
        .accessibilityLabel(isOpen ? "Đóng menu khu vườn".tr : "Mở menu khu vườn".tr)
    }

    private func select(_ destination: GardenMenuDestination) {
        close()
        switch destination {
        case .weather: showWeatherSheet = true
        case .sleep: showSleepSheet = true
        case .landscape: showEffectsSheet = true
        case .music: showMusicSheet = true
        case .store: router.push(.storeView)
        case .account: router.push(.accountView)
        case .achievements: router.push(.achievementsView)
        case .layout: isEditing = true
        case .events: router.push(.eventView)
        case .mailbox: router.push(.mailboxView)
        case .discovery: router.push(.discoveryView)
        case .vip: router.push(.subscriptionView)
        }
    }

    private func close() {
        AudioPlayer.shared.playTap()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { isOpen = false }
    }
}

enum GardenMenuDestination: String, CaseIterable, Identifiable {
    case weather = "Thời tiết"
    case sleep = "Giấc ngủ"
    case landscape = "Phong cảnh"
    case music = "Âm nhạc"
    case store = "Cửa hàng"
    case events = "Sự kiện"
    case achievements = "Thành tích"
    case mailbox = "Hòm thư"
    case discovery = "Khám phá"
    case layout = "Bố cục"
    case vip = "Gói VIP"
    case account = "Tài khoản"

    var id: Self { self }
    var icon: String {
        switch self {
        case .weather: return "cloud.sun.fill"
        case .sleep: return "moon.stars.fill"
        case .landscape: return "sun.horizon.fill"
        case .music: return "music.note"
        case .store: return "basket.fill"
        case .events: return "gift.fill"
        case .achievements: return "trophy.fill"
        case .mailbox: return "envelope.fill"
        case .discovery: return "globe.asia.australia.fill"
        case .vip: return "crown.fill"
        case .account: return "person.crop.circle.fill"
        case .layout: return "square.grid.3x3.fill"
        }
    }
    var tint: Color {
        switch self {
        case .weather: return Color(hex: "5E99B5")
        case .sleep: return Color(hex: "8D9360")
        case .landscape: return Color(hex: "B18A45")
        case .music: return Color(hex: "AC7862")
        case .store, .layout: return AccountStyle.green
        case .events: return Color(hex: "9A8A71")
        case .achievements: return Color(hex: "B18A45")
        case .mailbox: return Color(hex: "C07A53")
        case .discovery: return Color(hex: "648C86")
        case .vip: return Color(hex: "D79922")
        case .account: return Color(hex: "648C86")
        }
    }
}

struct GardenMenuPanel: View {
    let onSelect: (GardenMenuDestination) -> Void
    @ObservedObject private var mailboxStore = MailboxStore.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var canScrollDown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(AccountStyle.green)
                Text("Góc vườn".tr)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Spacer()
                Image(systemName: "sparkle")
                    .foregroundStyle(AccountStyle.border)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10),
                                         count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                    ForEach(GardenMenuDestination.allCases) { destination in
                        tile(destination)
                    }
                }
            }
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let bottom = geometry.contentSize.height + geometry.contentInsets.bottom
                let visibleBottom = geometry.contentOffset.y + geometry.containerSize.height
                return bottom - visibleBottom > 1
            } action: { _, hasMore in
                canScrollDown = hasMore
            }

            HStack(spacing: 6) {
                Text("Vuốt lên để xem thêm".tr)
                Image(systemName: "chevron.down")
                    .accessibilityHidden(true)
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(AccountStyle.green)
            .frame(maxWidth: .infinity)
            // Keep the footer's space stable so hiding it cannot change the scroll range.
            .opacity(canScrollDown ? 1 : 0)
            .accessibilityHidden(!canScrollDown)
        }
        .padding(18)
        .modifier(AccountPanel())
        .accessibilityElement(children: .contain)
    }

    private func tile(_ destination: GardenMenuDestination) -> some View {
        Button { onSelect(destination) } label: {
            VStack(spacing: 8) {
                Image(systemName: destination.icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(destination.tint)
                    .frame(width: 40, height: 36)
                    .background(destination.tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        if destination == .mailbox && mailboxStore.unreadCount > 0 {
                            Text(mailboxStore.unreadCount > 9 ? "9+" : "\(mailboxStore.unreadCount)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color(hex: "D95D39"), in: Capsule())
                                .offset(x: 6, y: -5)
                        }
                    }
                Text(destination.rawValue.tr)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if destination == .weather {
                    Text("1 ticket · 60 giây".tr)
                        .font(.caption2)
                        .foregroundStyle(AccountStyle.ink.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(destination.tint.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AccountStyle.border.opacity(0.7), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(destination.rawValue.tr)
    }
}

#Preview("Menu · 320pt") {
    GardenMenuPanel(onSelect: { _ in })
        .padding(16)
        .frame(width: 320, height: 422)
        .background(Color(hex: "E9EED9"))
}

#Preview("Menu · Chữ lớn".tr) {
    GardenMenuPanel(onSelect: { _ in })
        .padding(16)
        .frame(width: 320, height: 422)
        .environment(\.dynamicTypeSize, .accessibility1)
        .background(Color(hex: "E9EED9"))
}

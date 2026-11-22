import SwiftUI

struct SpeedDial: View {
    @State private var isOpen = false
    @State private var isIdle = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var showMusicSheet = false
    @State private var showEffectsSheet = false
    @Binding var isEditing: Bool
    @Binding var backgroundRive: String
    @Binding var overlayRive: String?
    @EnvironmentObject var router: AppRouter
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
                    .accessibilityLabel("Đóng menu khu vườn")
                    .transition(.opacity)
                }

                VStack(alignment: .trailing, spacing: 14) {
                    if isOpen {
                        ScrollView {
                            GardenMenuPanel(onSelect: select)
                                .padding(.bottom, 5)
                        }
                        .scrollIndicators(.hidden)
                        .defaultScrollAnchor(.bottom, for: .alignment)
                        .frame(height: min(max(geometry.size.height - 100, 0), 390))
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    }
                    launcher
                }
                .frame(width: min(max(geometry.size.width - 32, 0), 340), alignment: .trailing)
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .task(id: idleTimerKey) {
            isIdle = false
            guard !isOpen, !showMusicSheet, !showEffectsSheet, scenePhase == .active else { return }
            do {
                try await Task.sleep(for: .seconds(4))
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: 0.6)) { isIdle = true }
            } catch { /* View disappearance or interaction cancels the idle delay. */ }
        }
        .sheet(isPresented: $showMusicSheet) {
            MusicSheetView()
        }
        .sheet(isPresented: $showEffectsSheet) {
            EffectsSheetView(backgroundRive: $backgroundRive, overlayRive: $overlayRive)
        }
    }

    private var idleTimerKey: String {
        "\(isOpen)-\(showMusicSheet)-\(showEffectsSheet)-\(scenePhase)"
    }

    private var launcher: some View {
        Button {
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
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(true)
        .accessibilityLabel(isOpen ? "Đóng menu khu vườn" : "Mở menu khu vườn")
    }

    private func select(_ destination: GardenMenuDestination) {
        close()
        switch destination {
        case .landscape: showEffectsSheet = true
        case .music: showMusicSheet = true
        case .store: router.push(.storeView)
        case .account: router.push(.accountView)
        case .layout: isEditing = true
        case .events: break // No event destination is available yet.
        }
    }

    private func close() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) { isOpen = false }
    }
}

enum GardenMenuDestination: String, CaseIterable, Identifiable {
    case landscape = "Phong cảnh"
    case music = "Âm nhạc"
    case store = "Cửa hàng"
    case events = "Sự kiện"
    case account = "Tài khoản"
    case layout = "Bố cục"

    var id: Self { self }
    var icon: String {
        switch self {
        case .landscape: return "sun.horizon.fill"
        case .music: return "music.note"
        case .store: return "basket.fill"
        case .events: return "gift.fill"
        case .account: return "person.crop.circle.fill"
        case .layout: return "square.grid.3x3.fill"
        }
    }
    var tint: Color {
        switch self {
        case .landscape: return Color(hex: "B18A45")
        case .music: return Color(hex: "AC7862")
        case .store, .layout: return AccountStyle.green
        case .events: return Color(hex: "9A8A71")
        case .account: return Color(hex: "648C86")
        }
    }
}

struct GardenMenuPanel: View {
    let onSelect: (GardenMenuDestination) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(AccountStyle.green)
                Text("Góc vườn")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Spacer()
                Image(systemName: "sparkle")
                    .foregroundStyle(AccountStyle.border)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10),
                                     count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                ForEach(GardenMenuDestination.allCases) { destination in
                    tile(destination)
                }
            }
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
                Text(destination.rawValue)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(destination == .events ? AccountStyle.muted : AccountStyle.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(destination.tint.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AccountStyle.border.opacity(0.7), lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if destination == .events {
                    Text("Sắp có")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(AccountStyle.cream, in: Capsule())
                        .padding(5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(destination == .events)
        .accessibilityLabel(destination == .events ? "Sự kiện, sắp có" : destination.rawValue)
    }
}

#Preview("Menu · 320pt") {
    GardenMenuPanel(onSelect: { _ in })
        .padding(16)
        .frame(width: 320)
        .background(Color(hex: "E9EED9"))
}

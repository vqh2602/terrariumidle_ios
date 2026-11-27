import FirebaseAuth
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var isReplay: Bool = false
    var onFinish: (() -> Void)? = nil

    @State private var currentStepIndex: Int = 0
    private let steps = OnboardingStep.allCases

    private var activeStep: OnboardingStep {
        steps[min(max(currentStepIndex, 0), steps.count - 1)]
    }

    private var isLastStep: Bool {
        currentStepIndex >= steps.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $currentStepIndex) {
                ForEach(steps) { step in
                    stepPage(step)
                        .tag(step.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.88), value: currentStepIndex)

            bottomControls
        }
        .background {
            LinearGradient(
                colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                Image.bundle("leaf_emerald_1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-28))
                    .opacity(0.10)
                    .offset(x: 42, y: 36)
                    .accessibilityHidden(true)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar (Quick Skip + Step Counter)

    private var topBar: some View {
        HStack(spacing: 12) {
            if currentStepIndex > 0 {
                Button {
                    AudioPlayer.shared.playTap()
                    withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86)) {
                        currentStepIndex = max(0, currentStepIndex - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .frame(width: 44, height: 44)
                        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                        }
                        .shadow(color: AccountStyle.border.opacity(0.65), radius: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bước trước".tr)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AccountStyle.green)
                    Text("Hướng dẫn".tr)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.ink)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(AccountStyle.cream.opacity(0.85), in: Capsule())
                .overlay {
                    Capsule().strokeBorder(AccountStyle.border, lineWidth: 1.5)
                }
            }

            Spacer(minLength: 8)

            Text("\(currentStepIndex + 1) / \(steps.count)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(AccountStyle.muted)
                .accessibilityHidden(true)

            Button {
                completeOnboarding()
            } label: {
                HStack(spacing: 6) {
                    Text(isReplay ? "Đóng".tr : "Bỏ qua".tr)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                    Image(systemName: isReplay ? "xmark" : "forward.end.fill")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(AccountStyle.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(AccountStyle.cream, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                }
                .shadow(color: AccountStyle.border.opacity(0.65), radius: 0, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isReplay ? "Đóng hướng dẫn".tr : "Bỏ qua hướng dẫn".tr)
            .accessibilityHint("Chuyển nhanh vào ứng dụng".tr)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Step Page

    private func stepPage(_ step: OnboardingStep) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                illustrationPanel(for: step)

                VStack(spacing: 8) {
                    Text(step.eyebrow)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(AccountStyle.green)

                    Text(step.title)
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(step.summary)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AccountStyle.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 6)

                VStack(spacing: 12) {
                    ForEach(step.highlights) { item in
                        highlightRow(item)
                    }
                }
                .padding(16)
                .modifier(AccountPanel())
            }
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func highlightRow(_ item: OnboardingStep.Highlight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let assetImage = item.assetImage {
                    Image(assetImage)
                        .resizable()
                        .scaledToFit()
                        .padding(7)
                } else {
                    Image(systemName: item.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AccountStyle.green)
                }
            }
            .frame(width: 40, height: 40)
            .background(AccountStyle.green.opacity(0.11), in: RoundedRectangle(cornerRadius: 13))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.detail)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(AccountStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Step Visual Illustrations

    @ViewBuilder
    private func illustrationPanel(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            welcomeIllustration
        case .care:
            careIllustration
        case .gardenMenu:
            gardenMenuIllustration
        case .relax:
            relaxIllustration
        }
    }

    private var welcomeIllustration: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E5EBCF"))
                    .frame(width: 132, height: 132)
                    .overlay {
                        Circle().strokeBorder(AccountStyle.border, lineWidth: 2)
                    }

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 102, height: 102)
                    .clipShape(Circle())
            }
            .overlay(alignment: .topTrailing) {
                miniResourcePill(image: "oxygen", text: "+Oxy")
                    .offset(x: 24, y: -4)
            }
            .overlay(alignment: .bottomLeading) {
                miniBadgePill(icon: "music.note", text: "Chill BGM")
                    .offset(x: -20, y: 4)
            }

            Text("Terrarium Idle")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .modifier(AccountPanel())
    }

    private var careIllustration: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                gestureCard(
                    icon: "hand.tap.fill",
                    title: "Chạm nhanh".tr,
                    subtitle: "Nhặt Oxy & EXP".tr,
                    asset: "oxygen"
                )
                gestureCard(
                    icon: "hand.point.up.left.fill",
                    title: "Nhấn giữ".tr,
                    subtitle: "Mở menu chăm cây".tr,
                    asset: "water-can"
                )
            }

            HStack(spacing: 8) {
                careToolPill(asset: "water-can", label: "Tưới cây".tr)
                careToolPill(asset: "fertilizer", label: "Bón phân".tr)
                careToolPill(asset: "shovel", label: "Loại bỏ".tr)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .modifier(AccountPanel())
    }

    private var gardenMenuIllustration: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    LevelCircularBadge(level: 1, progress: 0.55, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Huy hiệu Cấp".tr)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(AccountStyle.ink)
                        Text("Chạm để mở ví".tr)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(AccountStyle.muted)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AccountStyle.green)
                    Text("Ô thêm cây".tr)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AccountStyle.green.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .background(AccountStyle.green.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                )
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Nút Góc vườn".tr)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                    Text("Cửa hàng · Bố cục · Phong cảnh · Âm nhạc".tr)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(AccountStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AccountStyle.cream)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(
                            LinearGradient(
                                colors: [Color(hex: "77995C"), AccountStyle.green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .overlay {
                        Circle().strokeBorder(AccountStyle.cream.opacity(0.85), lineWidth: 2)
                    }
                    .shadow(color: Color(hex: "354D2C").opacity(0.6), radius: 0, y: 3)
            }
            .padding(12)
            .background(AccountStyle.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .modifier(AccountPanel())
    }

    private var relaxIllustration: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                featurePreviewTile(
                    icon: "moon.stars.fill",
                    tint: Color(hex: "8D9360"),
                    title: "Giấc ngủ".tr,
                    subtitle: "Quà mỗi ngày".tr
                )
                featurePreviewTile(
                    icon: "cloud.rain.fill",
                    tint: Color(hex: "5E99B5"),
                    title: "Thời tiết".tr,
                    subtitle: "Tự tap 60s".tr
                )
                featurePreviewTile(
                    icon: "globe.asia.australia.fill",
                    tint: Color(hex: "648C86"),
                    title: "Khám phá".tr,
                    subtitle: "Thăm & thả tim".tr
                )
            }

            HStack(spacing: 10) {
                miniResourcePill(image: "oxygen", text: "Oxy")
                miniResourcePill(image: "gemstone", text: "Đá quý".tr)
                miniResourcePill(image: "ticket", text: "Vé thời tiết".tr)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .modifier(AccountPanel())
    }

    // MARK: - Illustration Subcomponents

    private func miniResourcePill(image: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AccountStyle.cream, in: Capsule())
        .overlay {
            Capsule().strokeBorder(AccountStyle.border, lineWidth: 1.5)
        }
        .shadow(color: AccountStyle.border.opacity(0.5), radius: 0, y: 2)
    }

    private func miniBadgePill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AccountStyle.green)
            Text(text)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.ink)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AccountStyle.cream, in: Capsule())
        .overlay {
            Capsule().strokeBorder(AccountStyle.border, lineWidth: 1.5)
        }
        .shadow(color: AccountStyle.border.opacity(0.5), radius: 0, y: 2)
    }

    private func gestureCard(icon: String, title: String, subtitle: String, asset: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.ink)
            Text(subtitle)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AccountStyle.border.opacity(0.65), lineWidth: 1)
        }
    }

    private func careToolPill(asset: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.ink)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(AccountStyle.cream, in: Capsule())
        .overlay {
            Capsule().strokeBorder(AccountStyle.border.opacity(0.8), lineWidth: 1)
        }
    }

    private func featurePreviewTile(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 36)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            Text(title)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.ink)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(tint.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AccountStyle.border.opacity(0.7), lineWidth: 1)
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(steps) { step in
                    let isSelected = step.rawValue == currentStepIndex
                    Button {
                        AudioPlayer.shared.playTap()
                        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.85)) {
                            currentStepIndex = step.rawValue
                        }
                    } label: {
                        Capsule()
                            .fill(isSelected ? AccountStyle.green : AccountStyle.border)
                            .frame(width: isSelected ? 26 : 8, height: 8)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Bước %d: %@".tr(step.rawValue + 1, step.eyebrow))
                }
            }

            Button {
                handlePrimaryAction()
            } label: {
                HStack(spacing: 8) {
                    Text(primaryButtonTitle)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    Image(systemName: isLastStep ? "leaf.fill" : "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(AccountStyle.cream)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "6E9153"), AccountStyle.green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule().strokeBorder(AccountStyle.cream.opacity(0.65), lineWidth: 1.5)
                }
                .shadow(color: Color(hex: "354D2C").opacity(0.75), radius: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryButtonTitle)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var primaryButtonTitle: String {
        if isLastStep {
            return isReplay ? "Hoàn tất".tr : "Bắt đầu trồng cây".tr
        }
        return "Tiếp theo".tr
    }

    // MARK: - Actions

    private func handlePrimaryAction() {
        if isLastStep {
            completeOnboarding()
        } else {
            AudioPlayer.shared.playTap()
            withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.86)) {
                currentStepIndex = min(steps.count - 1, currentStepIndex + 1)
            }
        }
    }

    private func completeOnboarding() {
        AudioPlayer.shared.playTap()
        OnboardingStorage.markCompleted()
        if let onFinish {
            onFinish()
        } else {
            let route = OnboardingStorage.postOnboardingRoute(
                isAuthenticated: AuthService.shared.currentUser?.uid != nil
            )
            router.replaceRoot(route)
        }
    }
}

#Preview("Hướng dẫn · Lần đầu".tr) {
    OnboardingView()
        .environmentObject(AppRouter())
}

#Preview("Hướng dẫn · Màn hình nhỏ".tr) {
    OnboardingView()
        .environmentObject(AppRouter())
        .frame(width: 320, height: 568)
}

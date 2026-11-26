import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var fireStore = FireStoreService.shared

    var isSheet: Bool = false
    var highlightContext: String? = nil

    @State private var selectedPlan: VIPPlanKind = .yearly
    @State private var previewAudioItem: ItemData?
    @State private var previewAudioTimer: Task<Void, Never>?
    @State private var previousAudioSnapshot: BackgroundAudioManager.AudioSnapshot?
    @State private var previewEffectIndex = 0
    @State private var showSuccessAlert = false

    private var isVIPActive: Bool {
        SubscriptionManager.isVIP(gardenModel: fireStore.gradenModel)
    }

    private var allMusics: [ItemData] { ItemDataManager.shared.getAllMusics() }
    private var allSFX: [ItemData] { ItemDataManager.shared.getAllMusicsSFX() }
    private var allLandscapes: [ItemData] { ItemDataManager.shared.getAllLandscapes() }
    private var allEffects: [ItemData] { ItemDataManager.shared.getAllEffects() }

    private var previewEffects: [ItemData] {
        allEffects.isEmpty ? [] : allEffects
    }

    private var lockedSampleTracks: [ItemData] {
        let unlocked = MusicUnlockHelper.getUnlockedMusicIds(from: fireStore.gradenModel, isVIPOverride: false)
        let locked = allMusics.filter { !unlocked.contains($0.id) }
        return locked.isEmpty ? Array(allMusics.prefix(3)) : Array(locked.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 20) {
                    heroCard

                    if isVIPActive {
                        activeMemberCard
                    } else {
                        if let highlightContext, !highlightContext.isEmpty {
                            contextCallout(highlightContext)
                        }
                        planSelectionSection
                        purchaseCTASection
                    }

                    interactivePreviewSection
                    perksSection
                    welcomeGiftSection
                    footerSection
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            LinearGradient(
                colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
            await subscriptionManager.refreshEntitlements()
        }
        .onDisappear {
            stopAudioPreviewIfNeeded()
        }
        .alert("Terrarium VIP", isPresented: $showSuccessAlert) {
            Button("Tuyệt vời!".tr, role: .cancel) {
                if isSheet { dismiss() }
            }
        } message: {
            Text("Chúc mừng! Toàn bộ âm nhạc, hiệu ứng hình ảnh và đặc quyền VIP ×2 đã được mở khóa cho khu vườn của bạn.".tr)
        }
    }

    // MARK: - Header

    private var topBar: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("Terrarium VIP".tr)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("ĐẶC QUYỀN KHU VƯỜN".tr)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(AccountStyle.green)
            }
            HStack {
                Button {
                    stopAudioPreviewIfNeeded()
                    if isSheet {
                        dismiss()
                    } else {
                        router.pop()
                    }
                } label: {
                    Image(systemName: isSheet ? "xmark" : "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)
                        .frame(width: 42, height: 42)
                        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Đóng".tr)
                Spacer()
                if isVIPActive {
                    VIPCrownBadge()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFE08A"), VIPPalette.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(VIPPalette.emeraldDark)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isVIPActive ? "Bạn đang là Hội viên VIP".tr : "Mở khóa trọn vẹn khu vườn bình yên".tr)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.cream)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tận hưởng ngay %d bản nhạc, %d âm thanh thiên nhiên & %d hiệu ứng không cần trồng cây.".tr(
                        allMusics.count,
                        allSFX.count,
                        allLandscapes.count + allEffects.count
                    ))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(AccountStyle.cream.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 6) {
                heroStatChip(icon: "music.note.list", text: "%d Nhạc & SFX".tr(allMusics.count + allSFX.count))
                heroStatChip(icon: "sparkles", text: "%d Hiệu ứng".tr(allLandscapes.count + allEffects.count))
                heroStatChip(icon: "gift.fill", text: "×2 Quà tháng".tr)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [VIPPalette.emeraldDark, VIPPalette.emeraldMid],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(VIPPalette.gold.opacity(0.65), lineWidth: 1.5)
        }
        .shadow(color: VIPPalette.emeraldDark.opacity(0.28), radius: 10, y: 5)
    }

    private func heroStatChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(VIPPalette.gold)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(AccountStyle.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.11), in: Capsule())
    }

    private func contextCallout(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(VIPPalette.emeraldDark)
            Text(message)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(VIPPalette.emeraldDark)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(VIPPalette.goldSoft, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(VIPPalette.goldBorder, lineWidth: 1)
        }
    }

    // MARK: - Active VIP Status

    private var activeMemberCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Gói VIP đang hoạt động".tr, systemImage: "checkmark.seal.fill")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.green)
                Spacer()
                VIPCrownBadge()
            }

            if let planName = activePlanTitle {
                HStack {
                    Text("Gói hiện tại".tr)
                        .foregroundStyle(AccountStyle.muted)
                    Spacer()
                    Text(planName)
                        .fontWeight(.bold)
                        .foregroundStyle(AccountStyle.ink)
                }
                .font(.system(.subheadline, design: .rounded))
            }

            if let expiry = subscriptionManager.expirationDate ?? fallbackExpirationDate {
                HStack {
                    Text(subscriptionManager.willAutoRenew ? "Gia hạn vào".tr : "Hết hạn vào".tr)
                        .foregroundStyle(AccountStyle.muted)
                    Spacer()
                    Text(expiry.formatted(date: .abbreviated, time: .omitted))
                        .fontWeight(.bold)
                        .foregroundStyle(AccountStyle.ink)
                }
                .font(.system(.subheadline, design: .rounded))
            }

            Button {
                Task { await subscriptionManager.manageSubscriptions() }
            } label: {
                Label("Quản lý gói đăng ký App Store".tr, systemImage: "gearshape.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(AccountStyle.green.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .modifier(AccountPanel())
    }

    private var activePlanTitle: String? {
        let id = subscriptionManager.activeProductId ?? fireStore.gradenModel?.vipStatus.productId
        if id == SubscriptionManager.yearlyProductId { return "Terrarium VIP Năm".tr }
        if id == SubscriptionManager.monthlyProductId { return "Terrarium VIP Tháng".tr }
        return isVIPActive ? "Terrarium VIP".tr : nil
    }

    private var fallbackExpirationDate: Date? {
        let ts = fireStore.gradenModel?.vipStatus.expiresAt ?? 0
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    // MARK: - Plan Selector

    private var planSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chọn gói thành viên".tr)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.ink)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach([VIPPlanKind.yearly, VIPPlanKind.monthly]) { plan in
                    planCard(plan)
                }
            }
        }
    }

    private func planCard(_ plan: VIPPlanKind) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            AudioPlayer.shared.playTap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(plan.title)
                                .font(.system(.headline, design: .rounded, weight: .heavy))
                                .foregroundStyle(AccountStyle.ink)
                            if let badge = plan.badge {
                                Text(badge)
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(VIPPalette.emeraldDark)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(VIPPalette.gold, in: Capsule())
                            }
                        }
                        Text(plan.subtitle)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AccountStyle.muted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(subscriptionManager.displayPrice(for: plan))
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(AccountStyle.green)
                        if let eq = subscriptionManager.monthlyEquivalentText(for: plan) {
                            Text(eq)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AccountStyle.muted)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color(hex: "F3F6E2") : AccountStyle.cream,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        isSelected ? AccountStyle.green : AccountStyle.border,
                        lineWidth: isSelected ? 2.5 : 1.2
                    )
            }
            .shadow(color: isSelected ? AccountStyle.green.opacity(0.18) : .clear, radius: 6, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase CTA

    private var purchaseCTASection: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    let ok = await subscriptionManager.purchase(selectedPlan)
                    if ok {
                        stopAudioPreviewIfNeeded()
                        showSuccessAlert = true
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .tint(VIPPalette.emeraldDark)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 17, weight: .bold))
                    }
                    Text(
                        subscriptionManager.isPurchasing
                            ? "Đang xử lý giao dịch…".tr
                            : "Đăng ký %@ · %@".tr(selectedPlan.title, subscriptionManager.displayPrice(for: selectedPlan))
                    )
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                }
                .foregroundStyle(VIPPalette.emeraldDark)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFE394"), VIPPalette.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1.5)
                }
                .shadow(color: VIPPalette.goldBorder.opacity(0.55), radius: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isPurchasing)

            if let error = subscriptionManager.errorMessage {
                Text(error)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AccountStyle.danger)
                    .multilineTextAlignment(.center)
            } else if let status = subscriptionManager.statusMessage {
                Text(status)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AccountStyle.green)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    let ok = await subscriptionManager.restorePurchases()
                    if ok { showSuccessAlert = true }
                }
            } label: {
                Text("Khôi phục giao dịch đã mua".tr)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                    .padding(.vertical, 6)
            }
            .disabled(subscriptionManager.isPurchasing)
        }
    }

    // MARK: - Interactive Preview (Enticement)

    private var interactivePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Nghe thử & Xem trước VIP".tr, systemImage: "wand.and.stars")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                Spacer()
                Text("Miễn phí dùng thử 12s".tr)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
            }
            .padding(.leading, 4)

            VStack(spacing: 12) {
                ForEach(lockedSampleTracks) { track in
                    let isPreviewing = previewAudioItem?.id == track.id
                    Button {
                        toggleTrackPreview(track)
                    } label: {
                        HStack(spacing: 12) {
                            Image(track.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.name.tr)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(AccountStyle.ink)
                                Text(isPreviewing ? "Đang nghe thử nhạc VIP…".tr : "Chạm để nghe thử 12 giây".tr)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(isPreviewing ? AccountStyle.green : AccountStyle.muted)
                            }
                            Spacer()
                            Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(isPreviewing ? AccountStyle.danger : AccountStyle.green)
                        }
                        .padding(10)
                        .background(AccountStyle.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                if !previewEffects.isEmpty {
                    let current = previewEffects[previewEffectIndex % previewEffects.count]
                    HStack(spacing: 12) {
                        Group {
                            if let thumbName = resolvedThumbnailName(for: current) {
                                Image(thumbName)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                ZStack {
                                    AccountStyle.green.opacity(0.15)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(AccountStyle.green)
                                }
                            }
                        }
                        .frame(width: 56, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hiệu ứng: %@".tr(current.name.tr))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(AccountStyle.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(current.description.tr)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(AccountStyle.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button {
                            AudioPlayer.shared.playTap()
                            previewEffectIndex = (previewEffectIndex + 1) % previewEffects.count
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AccountStyle.green)
                                .frame(width: 34, height: 34)
                                .background(AccountStyle.green.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(VIPPalette.goldSoft.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
            .modifier(AccountPanel())
        }
    }

    // MARK: - Perks & Welcome Gift

    private var perksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quyền lợi hội viên Terrarium VIP".tr, systemImage: "sparkles")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.green)
                .padding(.leading, 4)

            VStack(spacing: 12) {
                perkRow(
                    icon: "music.note.house.fill",
                    tint: Color(hex: "AC7862"),
                    title: "Mở khóa 100% Âm nhạc & SFX".tr,
                    detail: "Truy cập ngay %d bản nhạc và %d hiệu ứng âm thanh phối đa lớp mà không cần trồng cây.".tr(allMusics.count, allSFX.count)
                )
                Divider()
                perkRow(
                    icon: "sun.horizon.fill",
                    tint: Color(hex: "B18A45"),
                    title: "Mở khóa 100% Phong cảnh & Hiệu ứng".tr,
                    detail: "Thay đổi tự do %d bầu trời phong cảnh và %d hiệu ứng đom đóm, hoa đào, lá rơi.".tr(allLandscapes.count, allEffects.count)
                )
                Divider()
                perkRow(
                    icon: "calendar.badge.plus",
                    tint: AccountStyle.green,
                    title: "Nhân đôi (×2) quà Điểm danh 30 ngày".tr,
                    detail: "Mỗi ngày nhận quà ngẫu nhiên tháng (Oxygen, Đá quý, Vé, Phân bón, Xẻng) đều được nhân đôi số lượng.".tr
                )
                Divider()
                perkRow(
                    icon: "bolt.heart.fill",
                    tint: Color(hex: "5E99B5"),
                    title: "+50% Oxygen khi chăm vườn".tr,
                    detail: "Mỗi lần chạm chăm cây thu hoạch thêm 50% Oxygen và nổi bật với huy hiệu Hoàng gia VIP.".tr
                )
            }
            .padding(18)
            .modifier(AccountPanel())
        }
    }

    private func perkRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.ink)
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AccountStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var welcomeGiftSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quà chào mừng khi kích hoạt VIP".tr, systemImage: "gift.fill")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.green)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                welcomeGiftChip(image: "gemstone", label: "×\(VIPWelcomeBonus.gemstone)")
                welcomeGiftChip(image: "ticket", label: "×\(VIPWelcomeBonus.ticket)")
                welcomeGiftChip(image: "fertilizer", label: "×\(VIPWelcomeBonus.fertilizer)")
                welcomeGiftChip(image: "shovel", label: "×\(VIPWelcomeBonus.shovel)")
            }
            .padding(14)
            .modifier(AccountPanel())
        }
    }

    private func welcomeGiftChip(image: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AccountStyle.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Gói đăng ký tự động gia hạn trừ khi được hủy ít nhất 24 giờ trước khi kết thúc chu kỳ hiện tại. Bạn có thể quản lý hoặc hủy bất kỳ lúc nào trong Cài đặt Apple ID.".tr)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Button("Điều khoản sử dụng".tr) {
                    if let url = URL(string: "https://terrarium.com/terms") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Chính sách bảo mật".tr) {
                    if let url = URL(string: "https://terrarium.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(AccountStyle.green)
        }
        .padding(.top, 4)
    }

    // MARK: - Thumbnail Resolution

    private func resolvedThumbnailName(for item: ItemData) -> String? {
        if UIImage(named: item.image) != nil {
            return item.image
        }
        let prefixed = item.image.hasPrefix("i_") ? item.image : "i_\(item.image)"
        if UIImage(named: prefixed) != nil {
            return prefixed
        }
        if item.image.hasPrefix("i_") {
            let stripped = String(item.image.dropFirst(2))
            if UIImage(named: stripped) != nil {
                return stripped
            }
        }
        if let firstImage = item.images?.first, UIImage(named: firstImage) != nil {
            return firstImage
        }
        return nil
    }

    // MARK: - Audio Preview Logic

    private func toggleTrackPreview(_ track: ItemData) {
        if previewAudioItem?.id == track.id {
            stopAudioPreviewIfNeeded()
            return
        }

        if previousAudioSnapshot == nil {
            previousAudioSnapshot = BackgroundAudioManager.shared.captureAudioSnapshot()
        }

        previewAudioTimer?.cancel()
        previewAudioItem = track
        BackgroundAudioManager.shared.switchBGM(
            id: track.id,
            fileName: track.sound ?? track.id,
            title: track.name.tr,
            image: track.image
        )

        previewAudioTimer = Task { @MainActor in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled else { return }
            stopAudioPreviewIfNeeded()
        }
    }

    private func stopAudioPreviewIfNeeded() {
        previewAudioTimer?.cancel()
        previewAudioTimer = nil
        guard previewAudioItem != nil else { return }
        previewAudioItem = nil

        guard let prev = previousAudioSnapshot else { return }
        previousAudioSnapshot = nil
        if !isVIPActive {
            BackgroundAudioManager.shared.restoreAudioSnapshot(prev)
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(AppRouter())
}

import SwiftUI

/// Visitor snapshots and interactions stay independent of the owner's garden.
struct VisitorGardenView: View {
    let profile: DiscoveredProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: VisitorGardenViewModel
    @State private var reloadID = 0
    @State private var showLikeNotice = false

    init(profile: DiscoveredProfile, repository: any DiscoveryReading,
         onLike: ((String, Int) -> Void)? = nil) {
        self.profile = profile
        _model = StateObject(wrappedValue: VisitorGardenViewModel(repository: repository,
                                                                liking: GardenLikeService.shared,
                                                                onLike: onLike))
    }

    var body: some View {
        ZStack {
            if let garden = model.garden {
                VisitorShelvesView(garden: garden)
                    .id(garden.profile.id)
                    .ignoresSafeArea()
            } else if model.isLoading {
                ProgressView("Đang ghé thăm khu vườn…".tr)
            } else {
                VStack(spacing: 16) {
                    Text(model.error ?? "Không tải được khu vườn.".tr)
                        .multilineTextAlignment(.center)
                    Button("Thử lại".tr) { reloadID += 1 }
                }.padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AccountStyle.cream.ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .overlay(alignment: .top) {
            visitorToolbar
                .padding(.horizontal, 12)
                .padding(.top, 6)
        }
        .overlay(alignment: .bottom) {
            if showLikeNotice, let message = model.likeMessage {
                Text(message)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .modifier(VisitorGlassSurface())
                    .padding(.horizontal, 24).padding(.bottom, 12)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .task(id: reloadID) { await model.load(id: profile.id) }
        .task(id: model.likeMessage) {
            showLikeNotice = model.likeMessage != nil
            guard showLikeNotice else { return }
            do {
                try await Task.sleep(for: .seconds(3))
                try Task.checkCancellation()
                showLikeNotice = false
            } catch { }
        }
    }

    private var visitorToolbar: some View {
        HStack(spacing: 6) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44).contentShape(Circle())
            }
            .accessibilityLabel("Rời khu vườn".tr)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.garden?.profile.name ?? profile.name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                Text("Đang ghé thăm".tr)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AccountStyle.ink.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button { Task { await model.like() } } label: {
                HStack(spacing: 5) {
                    if model.isLiking {
                        ProgressView().tint(Color(hex: "BC796C"))
                    } else {
                        Image(systemName: model.hasLiked ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    Text(displayedLikes.formatted(.number.notation(.compactName)))
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundStyle(Color(hex: "AE6259"))
                .padding(.horizontal, 10).frame(minWidth: 54, minHeight: 44)
                .background(model.hasLiked ? Color(hex: "DBA397").opacity(0.18) : .clear, in: Capsule())
                .contentShape(Capsule())
            }
            .disabled(!model.canLike)
            .accessibilityLabel(model.hasLiked ? "Đã thích khu vườn này".tr : "Thích khu vườn này".tr)
            .accessibilityValue("%d lượt yêu thích".tr(displayedLikes))

            Button { reloadID += 1 } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44).contentShape(Circle())
            }
            .accessibilityLabel("Tải lại khu vườn".tr)
            .disabled(model.isLiking)
        }
        .buttonStyle(DiscoveryPressStyle())
        .padding(5)
        .modifier(VisitorGlassSurface())
    }

    private var displayedLikes: Int { model.garden == nil ? profile.likes : model.likeCount }
}

private struct VisitorGlassSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(AccountStyle.cream, in: Capsule())
                .overlay { Capsule().strokeBorder(AccountStyle.border, lineWidth: 1) }
        } else if #available(iOS 26.0, *) {
            content.glassEffect(.regular.tint(AccountStyle.cream.opacity(0.25)), in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().strokeBorder(.white.opacity(0.65), lineWidth: 1) }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
    }
}

private struct VisitorShelvesView: View {
    let garden: VisitorGarden

    private var backgroundID: String {
        let unlocked = Set(garden.slots.values.flatMap { slot in
            [slot.plantID, slot.potID].flatMap { ItemDataManager.shared.getItem(byId: $0)?.unlockedLandscapeIds ?? [] }
        })
        return ItemDataManager.shared.getAllLandscapes().first { unlocked.contains($0.id) }?.image ?? "i_sky_sun_day"
    }

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, (geometry.size.width - 40) / 3)
            ZStack {
                SpriteKitBackgroundView(backgroundId: backgroundID)
                HStack(spacing: 0) {
                    Image("r1").resizable().frame(width: 16)
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array((0...garden.topFloor).reversed()), id: \.self) { row in
                                VStack(spacing: 0) {
                                    HStack(spacing: 4) {
                                        ForEach(1...3, id: \.self) { column in
                                            VisitorSlotView(slot: garden.slot(row: row, column: column), width: width)
                                        }
                                    }
                                    Image("r2").resizable().frame(height: 16)
                                }
                            }
                        }
                    }
                    .contentMargins(.top, 76, for: .scrollContent)
                    .contentMargins(.bottom, 24, for: .scrollContent)
                    .defaultScrollAnchor(.bottom)
                    Image("r1").resizable().frame(width: 16).scaleEffect(x: -1, y: 1)
                }
            }
        }
    }
}

private struct VisitorSlotView: View {
    let slot: VisitorGarden.Slot?
    let width: CGFloat
    private var height: CGFloat { width * 1.95 }

    var body: some View {
        Group {
            if let slot {
                if slot.isSticker && StickerAvailability.isAvailable(stickerId: slot.plantID) {
                    SpriteKitStickerView(stickerId: slot.plantID, isHanging: slot.isHanging, width: width, height: height)
                } else if !slot.isSticker && supported(slot) {
                    // Không gắn onTap: scene chỉ phát hiệu ứng thị giác và không thể thu thập oxy.
                    TerrariumSlotView(potId: slot.potID, plantId: slot.plantID, plantLevel: slot.level,
                                      isHanging: slot.isHanging, width: width, height: height)
                } else {
                    fallback(slot)
                }
            } else {
                Color.clear
            }
        }.frame(width: width, height: height)
    }

    private func supported(_ slot: VisitorGarden.Slot) -> Bool {
        let plantSupported = slot.plantID.isEmpty || PlantAvailability.isAvailable(plantId: slot.plantID)
        // PotFactory hiện tại hỗ trợ pot1...pot30. Tránh việc tự động fallback về pot1 đối với các ID legacy chưa rõ.
        let potSupported = slot.potID.isEmpty || (slot.potID.hasPrefix("pot") && (1...30).contains(Int(slot.potID.dropFirst(3)) ?? 0))
        return plantSupported && potSupported
    }

    private func fallback(_ slot: VisitorGarden.Slot) -> some View {
        let item = ItemDataManager.shared.getItem(byId: slot.plantID.isEmpty ? slot.potID : slot.plantID)
        return CachedAsyncImage(named: item?.image) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            VStack(spacing: 5) {
                Image(systemName: "leaf.circle").font(.title)
                Text(item?.name.tr ?? "Vật phẩm chưa hỗ trợ".tr).font(.caption2).multilineTextAlignment(.center)
            }.foregroundStyle(AccountStyle.muted)
        }
        .frame(width: width * 0.88, height: height * 0.86)
        .frame(width: width, height: height, alignment: slot.isHanging ? .top : .bottom)
    }
}

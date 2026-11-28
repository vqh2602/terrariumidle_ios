import SwiftUI

/// Visitor snapshots and interactions stay independent of the owner's garden.
struct VisitorGardenView: View {
    let profile: DiscoveredProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: VisitorGardenViewModel
    @State private var reloadID = 0
    @State private var showLikeNotice = false
    @State private var showPestNotice = false
    @State private var atmosphere: VisitorAtmosphere?
    @State private var savedAudioSnapshot: BackgroundAudioManager.AudioSnapshot?
    @ObservedObject private var fireStore = FireStoreService.shared

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
                VisitorShelvesView(garden: garden, atmosphere: atmosphere)
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
            VStack(spacing: 10) {
                if showPestNotice, let pestMsg = model.pestDropMessage {
                    Text(pestMsg)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .modifier(VisitorGlassSurface())
                        .accessibilityAddTraits(.updatesFrequently)
                } else if showLikeNotice, let message = model.likeMessage {
                    Text(message)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .modifier(VisitorGlassSurface())
                        .accessibilityAddTraits(.updatesFrequently)
                }

                if model.garden != nil && !model.isOwnGarden && model.hasPlantTargets {
                    dropPestBar
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 12)
        }
        .task(id: reloadID) { await model.load(id: profile.id) }
        .task(id: "\(model.garden?.profile.id ?? "")-\(reloadID)") {
            guard let garden = model.garden else { return }
            applyVisitorAtmosphere(for: garden)
        }
        .onDisappear {
            if let snapshot = savedAudioSnapshot {
                BackgroundAudioManager.shared.restoreAudioSnapshot(snapshot)
                savedAudioSnapshot = nil
            }
        }
        .task(id: model.likeMessage) {
            showLikeNotice = model.likeMessage != nil
            guard showLikeNotice else { return }
            do {
                try await Task.sleep(for: .seconds(3))
                try Task.checkCancellation()
                showLikeNotice = false
            } catch { }
        }
        .task(id: model.pestDropMessage) {
            showPestNotice = model.pestDropMessage != nil
            guard showPestNotice else { return }
            do {
                try await Task.sleep(for: .seconds(3))
                try Task.checkCancellation()
                showPestNotice = false
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
                HStack(spacing: 4) {
                    if model.garden?.profile.isVIP ?? profile.isVIP {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(VIPPalette.gold)
                    }
                    Text(model.garden?.profile.name ?? profile.name)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                }
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

    private var dropPestBar: some View {
        let remaining = fireStore.gradenModel?.remainingVisitorPestDrops() ?? 0
        let bagCount = fireStore.gradenModel?.capturedPests.count ?? 0
        let hasBagPests = bagCount > 0
        return Button {
            Task { await model.dropPest() }
        } label: {
            HStack(spacing: 8) {
                if model.isDroppingPest {
                    ProgressView()
                        .tint(Color(hex: "4E823C"))
                } else {
                    Image(systemName: hasBagPests ? "ladybug.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(hasBagPests ? Color(hex: "4E823C") : Color(hex: "C07A53"))
                }
                Text(hasBagPests ? "Thả sâu".tr : "Hết sâu · Bắt mới".tr)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text("Túi %d/%d".tr(bagCount, GardenModel.maxBagCapacity))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(hasBagPests ? AccountStyle.green : Color(hex: "C07A53"))
                Text("(\(remaining)/10)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(AccountStyle.muted)
                if hasBagPests {
                    Text("+350 💨")
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AccountStyle.green.opacity(0.14), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .modifier(VisitorGlassSurface())
            .contentShape(Capsule())
        }
        .buttonStyle(DiscoveryPressStyle())
        .disabled(model.isDroppingPest || remaining <= 0)
        .opacity(remaining > 0 ? (hasBagPests ? 1.0 : 0.85) : 0.65)
    }

    private func applyVisitorAtmosphere(for garden: VisitorGarden) {
        let audio = BackgroundAudioManager.shared
        if savedAudioSnapshot == nil {
            savedAudioSnapshot = audio.captureAudioSnapshot()
        }

        let itemIds = garden.slots.values.flatMap { [$0.plantID, $0.potID] }
        let selected = MusicUnlockHelper.randomAtmosphere(
            itemIds: itemIds,
            isVIP: garden.profile.isVIP,
            hasAudioFile: { audio.hasAudioResource(fileName: $0) }
        )
        atmosphere = selected

        guard savedAudioSnapshot?.wasPlaying == true else { return }
        if let music = selected.music {
            audio.switchBGM(
                id: music.id,
                fileName: music.sound ?? music.id,
                title: music.name.tr,
                image: music.image
            )
        }
        audio.stopAllSFX()
        if let sfx = selected.sfx {
            audio.startSFX(id: sfx.id, fileName: sfx.sound ?? sfx.id)
        }
    }
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
    let atmosphere: VisitorAtmosphere?
    @StateObject private var beeCoordinator = GardenBeeSwarmCoordinator()

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, (geometry.size.width - 40) / 3)
            let slotHeight = width * 1.95
            let _ = {
                beeCoordinator.layout.viewportSize = geometry.size
                beeCoordinator.layout.slotSize = CGSize(width: width, height: slotHeight)
                beeCoordinator.layout.userFloors = garden.topFloor
            }()

            ZStack {
                SpriteKitBackgroundView(backgroundId: atmosphere?.backgroundId ?? "i_sky_sun_day")
                HStack(spacing: 0) {
                    Image("r1").resizable().frame(width: 16)
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array((0...garden.topFloor).reversed()), id: \.self) { row in
                                VStack(spacing: 0) {
                                    HStack(spacing: 4) {
                                        ForEach(1...3, id: \.self) { column in
                                            let slot = garden.slot(row: row, column: column)
                                            let isInfested = slot.map { s in garden.pests.contains { $0.position == s.id } } ?? false
                                            VisitorSlotView(
                                                slot: slot,
                                                width: width,
                                                isInfested: isInfested,
                                                capturedPests: garden.capturedPests,
                                                onAnimalTap: {
                                                    beeCoordinator.notifyAnimalTapped(animalId: slot?.plantID ?? "animal1")
                                                }
                                            )
                                        }
                                    }
                                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("visitorViewport")) } action: { rect in
                                        guard beeCoordinator.hivePositionKey != nil
                                            || beeCoordinator.ladybugHomePositionKey != nil
                                            || beeCoordinator.bugsNetPositionKey != nil
                                            || !beeCoordinator.activePests.isEmpty else { return }
                                        beeCoordinator.layout.calibrate(row: row, viewportMinY: rect.minY)
                                    }
                                    Image("r2").resizable().frame(height: 16)
                                }
                            }
                        }
                    }
                    .contentMargins(.top, 76, for: .scrollContent)
                    .contentMargins(.bottom, 24, for: .scrollContent)
                    .defaultScrollAnchor(.bottom)
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, newOffset in
                        beeCoordinator.layout.shelfOffset = newOffset
                    }
                    Image("r1").resizable().frame(width: 16).scaleEffect(x: -1, y: 1)
                }

                GardenAnimalOverlayView(coordinator: beeCoordinator, viewportSize: geometry.size)

                OverlayEffectView(overlayId: atmosphere?.overlayId)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)
            }
            .coordinateSpace(name: "visitorViewport")
            .onAppear {
                syncVisitorSwarm()
            }
            .onChange(of: garden.pests) { _, _ in
                syncVisitorSwarm()
            }
        }
    }

    private func syncVisitorSwarm() {
        let hive = garden.slots.values.first(where: { $0.isAnimal && $0.plantID == "animal1" && AnimalAvailability.isAvailable(animalId: $0.plantID) })
        let ladybugHome = garden.slots.values.first(where: { $0.isAnimal && $0.plantID == "animal2" && AnimalAvailability.isAvailable(animalId: $0.plantID) })
        let bugsNet = garden.slots.values.first(where: { $0.isAnimal && $0.plantID == "animal3" && AnimalAvailability.isAvailable(animalId: $0.plantID) })
        let targets = garden.slots.values
            .filter { !$0.isSticker && !$0.isAnimal && !$0.plantID.isEmpty && !$0.potID.isEmpty }
            .map { BeePlantTarget(positionKey: $0.id, row: $0.row, column: $0.column, isHanging: $0.isHanging) }
        beeCoordinator.syncGarden(
            hivePosition: hive?.id,
            ladybugHomePosition: ladybugHome?.id,
            bugsNetPosition: bugsNet?.id,
            plantTargets: targets,
            pests: garden.pests,
            userFloors: garden.topFloor,
            animalId: hive?.plantID ?? ladybugHome?.plantID ?? bugsNet?.plantID ?? "animal1"
        )
    }
}

private struct VisitorSlotView: View {
    let slot: VisitorGarden.Slot?
    let width: CGFloat
    var isInfested: Bool = false
    var capturedPests: [PestSpecies] = []
    var onAnimalTap: (() -> Void)? = nil
    private var height: CGFloat { width * 1.95 }

    var body: some View {
        Group {
            if let slot {
                if slot.isSticker && StickerAvailability.isAvailable(stickerId: slot.plantID) {
                    SpriteKitStickerView(stickerId: slot.plantID, isHanging: slot.isHanging, width: width, height: height)
                } else if slot.isAnimal && AnimalAvailability.isAvailable(animalId: slot.plantID) {
                    SpriteKitAnimalView(
                        animalId: slot.plantID,
                        isHanging: slot.isHanging,
                        width: width,
                        height: height,
                        capturedPests: slot.plantID == "animal3" ? capturedPests : [],
                        onTap: onAnimalTap
                    )
                } else if !slot.isSticker && !slot.isAnimal && supported(slot) {
                    // Không gắn onTap: scene chỉ phát hiệu ứng thị giác và không thể thu thập oxy.
                    TerrariumSlotView(potId: slot.potID, plantId: slot.plantID, plantLevel: slot.level,
                                      isHanging: slot.isHanging, width: width, height: height, isInfested: isInfested)
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

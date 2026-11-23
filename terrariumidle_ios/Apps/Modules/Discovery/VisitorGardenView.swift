import SwiftUI

/// Màn hình này không có store của chủ vườn, không có binding chỉnh sửa, không callback kinh tế và không thay đổi âm nhạc.
struct VisitorGardenView: View {
    let profile: DiscoveredProfile
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: VisitorGardenViewModel
    @State private var reloadID = 0

    init(profile: DiscoveredProfile, repository: any DiscoveryReading) {
        self.profile = profile
        _model = StateObject(wrappedValue: VisitorGardenViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Rời khu vườn")
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.garden?.profile.name ?? profile.name).font(.headline).lineLimit(1)
                    Text("Đang ghé thăm · Chỉ xem").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { reloadID += 1 } label: { Image(systemName: "arrow.clockwise").frame(width: 44, height: 44) }
                    .accessibilityLabel("Tải lại khu vườn")
            }.padding(.horizontal, 8).background(AccountStyle.cream)
            if let garden = model.garden {
                VisitorShelvesView(garden: garden).id(garden.profile.id)
            } else if model.isLoading {
                Spacer()
                ProgressView("Đang ghé thăm khu vườn…")
                Spacer()
            } else {
                Spacer()
                Text(model.error ?? "Không tải được khu vườn.").multilineTextAlignment(.center).padding()
                Button("Thử lại") { reloadID += 1 }
                Spacer()
            }
        }
        .background(AccountStyle.cream.ignoresSafeArea())
        .foregroundStyle(AccountStyle.ink)
        .task(id: reloadID) { await model.load(id: profile.id) }
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
                    }.defaultScrollAnchor(.bottom)
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
        // PotFactory hiện tại hỗ trợ pot1...pot19. Tránh việc tự động fallback về pot1 đối với các ID legacy chưa rõ.
        let potSupported = slot.potID.isEmpty || (slot.potID.hasPrefix("pot") && (1...19).contains(Int(slot.potID.dropFirst(3)) ?? 0))
        return plantSupported && potSupported
    }

    private func fallback(_ slot: VisitorGarden.Slot) -> some View {
        let item = ItemDataManager.shared.getItem(byId: slot.plantID.isEmpty ? slot.potID : slot.plantID)
        return CachedAsyncImage(named: item?.image) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            VStack(spacing: 5) {
                Image(systemName: "leaf.circle").font(.title)
                Text(item?.name ?? "Vật phẩm chưa hỗ trợ").font(.caption2).multilineTextAlignment(.center)
            }.foregroundStyle(AccountStyle.muted)
        }
        .frame(width: width * 0.88, height: height * 0.86)
        .frame(width: width, height: height, alignment: slot.isHanging ? .top : .bottom)
    }
}

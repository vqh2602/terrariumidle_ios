import SwiftUI
import UIKit

private struct WatchFacePreset: Identifiable {
    let id: String
    let title: String
    let style: GardenClockStyle
    let layout: GardenClockLayout
    let font: GardenClockFont
    let accent: GardenAccent
    let theme: GardenClockTheme
}

private struct PlantedWatchItem: Identifiable {
    let planted: GardenModel.Plant
    let plant: ItemData
    let pot: ItemData
    var id: String { "\(planted.position)-\(planted.idPlant)-\(planted.idPot)" }
}

struct WatchCompanionSettingsView: View {
    @ObservedObject private var service = WatchCompanionService.shared
    @ObservedObject private var garden = FireStoreService.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var weather = WatchWeatherService.shared
    @Environment(\.dismiss) private var dismiss

    @AppStorage("watch.enabled") private var enabled = false
    @AppStorage("watch.plantedPosition") private var plantedPosition = ""
    @AppStorage("watch.plantID") private var plantID = ""
    @AppStorage("watch.potID") private var potID = ""
    @AppStorage("watch.clockStyle") private var style = GardenClockStyle.digital.rawValue
    @AppStorage("watch.theme") private var theme = GardenClockTheme.schedule.rawValue
    @AppStorage("watch.sleepConnected") private var sleepConnected = false
    @AppStorage("watch.layout") private var layout = GardenClockLayout.balanced.rawValue
    @AppStorage("watch.font") private var font = GardenClockFont.rounded.rawValue
    @AppStorage("watch.accent") private var accent = GardenAccent.mint.rawValue
    @AppStorage("watch.plantScale") private var plantScale = 1.0
    @AppStorage("watch.showDate") private var showDate = true
    @AppStorage("watch.showPlantName") private var showPlantName = true
    @AppStorage("watch.showSeconds") private var showSeconds = false
    @AppStorage("watch.use24HourTime") private var use24HourTime = true
    @AppStorage("watch.animatePlant") private var animatePlant = true
    @AppStorage("watch.weatherEnabled") private var weatherEnabled = false
    @State private var requestingSleep = false
    @State private var showInventoryFallback = false
    @State private var watchFaceImageToShare: UIImage?

    private var currentAccent: GardenAccent {
        GardenAccent(rawValue: accent) ?? .mint
    }

    private var plantedItems: [PlantedWatchItem] {
        guard let plantedList = garden.gradenModel?.plants else { return [] }
        let allPlants = ItemDataManager.shared.getAllPlants()
        let allPots = ItemDataManager.shared.getAllPots()
        return plantedList.compactMap { item in
            guard item.idPlant.hasPrefix("plant"), !item.idPot.isEmpty,
                  let plant = allPlants.first(where: { $0.id == item.idPlant }),
                  let pot = allPots.first(where: { $0.id == item.idPot }) else {
                return nil
            }
            return PlantedWatchItem(planted: item, plant: plant, pot: pot)
        }
    }

    private var plants: [ItemData] {
        let ids = Set((garden.gradenModel?.cart.cartPlants ?? []) + (garden.gradenModel?.plants.map(\.idPlant) ?? []))
        return ItemDataManager.shared.getAllPlants().filter { ids.contains($0.id) }
    }

    private var pots: [ItemData] {
        let ids = Set((garden.gradenModel?.cart.cartPots ?? []) + (garden.gradenModel?.plants.map(\.idPot) ?? []))
        return ItemDataManager.shared.getAllPots().filter { ids.contains($0.id) }
    }

    private var presets: [WatchFacePreset] {
        [
            WatchFacePreset(id: "fresh", title: "Vườn Sáng", style: .digital, layout: .balanced, font: .rounded, accent: .mint, theme: .schedule),
            WatchFacePreset(id: "classic", title: "Cổ Điển", style: .analog, layout: .plantFocus, font: .classic, accent: .amber, theme: .schedule),
            WatchFacePreset(id: "minimal", title: "Tối Giản", style: .digital, layout: .sideBySide, font: .monospaced, accent: .ocean, theme: .dark),
            WatchFacePreset(id: "sakura", title: "Anh Đào", style: .digital, layout: .plantFocus, font: .rounded, accent: .rose, theme: .light)
        ]
    }

    var body: some View {
        NavigationStack {
            Form {
                previewSection

                if enabled {
                    plantedPlantsSection
                    presetsSection
                    customizationSection
                    sleepSection
                    weatherSection
                    healthSection
                    tipsSection
                }
            }
            .navigationTitle("Apple Watch")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong".tr) { dismiss() }
                }
            }
            .task {
                service.start()
                service.publish()
            }
            .sheet(isPresented: Binding(
                get: { watchFaceImageToShare != nil },
                set: { if !$0 { watchFaceImageToShare = nil } }
            )) {
                if let image = watchFaceImageToShare {
                    WatchFaceShareSheet(items: [image])
                }
            }
        }
        .environment(\.locale, localization.currentLanguage.locale)
    }

    // MARK: - Live Apple Watch Bezel Preview

    private var previewSection: some View {
        Section {
            VStack(spacing: 14) {
                watchHardwareFrame
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                Toggle("Đồng hành trên Apple Watch".tr, isOn: $enabled)
                    .tint(currentAccent.color)

                HStack(spacing: 8) {
                    Circle()
                        .fill(service.isWatchReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(service.status.tr)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if enabled {
                        Button("Đồng bộ ngay".tr) {
                            service.forceSyncNow()
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.bordered)
                        .tint(currentAccent.color)
                    }
                }

                if enabled {
                    Button {
                        exportWatchFaceImage()
                    } label: {
                        Label("Thêm mặt đồng hồ vào Apple Watch".tr, systemImage: "applewatch.watchface")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(currentAccent.color)

                    Text("Chọn 'Tạo mặt đồng hồ' trong bảng chia sẻ để đặt làm màn hình khóa Apple Watch.".tr)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @MainActor
    private func exportWatchFaceImage() {
        var faceSnapshot = service.snapshot
        var faceAppearance = faceSnapshot.display
        faceAppearance.showDate = false
        faceAppearance.showPlantName = false
        faceAppearance.animatePlant = false
        faceSnapshot.appearance = faceAppearance

        let view = GardenClockView(snapshot: faceSnapshot, showClock: false)
            .frame(width: 396, height: 484)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        watchFaceImageToShare = renderer.uiImage
    }

    private var watchHardwareFrame: some View {
        ZStack(alignment: .trailing) {
            // Digital Crown & Side Button
            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.45), Color(white: 0.25), Color(white: 0.40)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 7, height: 34)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.30))
                    .frame(width: 5, height: 22)
            }
            .offset(x: 6, y: -16)

            // Watch Case
            ZStack {
                RoundedRectangle(cornerRadius: 46, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.20), Color(white: 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 46, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 14, y: 8)

                // Watch Display
                GardenClockView(snapshot: service.snapshot)
                    .frame(width: 186, height: 226)
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 38, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.6), lineWidth: 2)
                    )
            }
            .frame(width: 210, height: 250)
        }
    }

    // MARK: - Currently Growing Plants

    private var plantedPlantsSection: some View {
        Section("Cây đang trồng".tr) {
            if plantedItems.isEmpty {
                Text("Bạn chưa trồng cây nào trong vườn.".tr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(plantedItems) { item in
                            let isSelected = (plantedPosition == item.planted.position && plantID == item.plant.id)
                                || (plantedPosition.isEmpty && plantID == item.plant.id && potID == item.pot.id)
                            plantedCard(item, isSelected: isSelected)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            DisclosureGroup("Chọn tự do từ kho".tr, isExpanded: $showInventoryFallback) {
                Picker("Cây".tr, selection: Binding(
                    get: { plantID },
                    set: { newValue in
                        plantedPosition = ""
                        plantID = newValue
                        service.forceSyncNow()
                    }
                )) {
                    Text("Chọn cây".tr).tag("")
                    ForEach(plants) { Text($0.name.tr).tag($0.id) }
                }
                Picker("Chậu".tr, selection: Binding(
                    get: { potID },
                    set: { newValue in
                        plantedPosition = ""
                        potID = newValue
                        service.forceSyncNow()
                    }
                )) {
                    Text("Chọn chậu".tr).tag("")
                    ForEach(pots) { Text($0.name.tr).tag($0.id) }
                }
                if plants.isEmpty || pots.isEmpty {
                    Text("Cây và chậu bạn sở hữu sẽ xuất hiện ở đây.".tr).font(.caption)
                }
            }
            .font(.subheadline)
        }
    }

    private func plantedCard(_ item: PlantedWatchItem, isSelected: Bool) -> some View {
        Button {
            plantedPosition = item.planted.position
            plantID = item.plant.id
            potID = item.pot.id
            service.forceSyncNow()
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? currentAccent.color.opacity(0.16) : Color(.secondarySystemGroupedBackground))
                        .frame(width: 84, height: 84)

                    if let thumb = service.renderThumbnail(
                        plant: item.plant,
                        pot: item.pot,
                        plantLevel: item.planted.plantLevel,
                        isHanging: item.planted.isHanging,
                        edge: 128
                    ) {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .frame(width: 84, height: 84)
                    }

                    Text("Lv.\(item.planted.plantLevel)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(5)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isSelected ? currentAccent.color : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
                )

                Text(item.plant.name.tr)
                    .font(.caption2.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? currentAccent.color : .primary)
                    .lineLimit(1)
                    .frame(width: 84)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Presets

    private var presetsSection: some View {
        Section("Mẫu mặt đồng hồ".tr) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets) { preset in
                        let isActive = style == preset.style.rawValue
                            && layout == preset.layout.rawValue
                            && font == preset.font.rawValue
                            && accent == preset.accent.rawValue
                            && theme == preset.theme.rawValue
                        Button {
                            style = preset.style.rawValue
                            layout = preset.layout.rawValue
                            font = preset.font.rawValue
                            accent = preset.accent.rawValue
                            theme = preset.theme.rawValue
                            service.forceSyncNow()
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(preset.accent.color)
                                    .frame(width: 12, height: 12)
                                Text(preset.title.tr)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isActive ? preset.accent.color.opacity(0.20) : Color(.secondarySystemGroupedBackground),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(isActive ? preset.accent.color : Color.primary.opacity(0.08), lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Customization Controls

    private var customizationSection: some View {
        Section("Tùy chỉnh mặt đồng hồ".tr) {
            Picker("Kiểu đồng hồ".tr, selection: $style) {
                Text("Đồng hồ số".tr).tag(GardenClockStyle.digital.rawValue)
                Text("Đồng hồ kim".tr).tag(GardenClockStyle.analog.rawValue)
            }
            .pickerStyle(.segmented)

            Picker("Bố cục".tr, selection: $layout) {
                Text("Cân đối".tr).tag(GardenClockLayout.balanced.rawValue)
                Text("Nổi bật cây".tr).tag(GardenClockLayout.plantFocus.rawValue)
                Text("Cạnh nhau".tr).tag(GardenClockLayout.sideBySide.rawValue)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("Màu chủ đạo".tr)
                    .font(.subheadline)
                HStack(spacing: 14) {
                    ForEach(GardenAccent.allCases, id: \.self) { option in
                        let selected = accent == option.rawValue
                        Button {
                            accent = option.rawValue
                            service.forceSyncNow()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 30, height: 30)
                                if selected {
                                    Circle()
                                        .strokeBorder(Color.primary, lineWidth: 2.5)
                                        .frame(width: 36, height: 36)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accentTitle(option).tr)
                    }
                }
                .padding(.vertical, 2)
            }

            Picker("Phông chữ".tr, selection: $font) {
                Text("Bo tròn".tr).tag(GardenClockFont.rounded.rawValue)
                Text("Cổ điển".tr).tag(GardenClockFont.classic.rawValue)
                Text("Đơn cách".tr).tag(GardenClockFont.monospaced.rawValue)
            }

            Picker("Bầu trời".tr, selection: $theme) {
                Text("Theo lịch ngủ/thức".tr).tag(GardenClockTheme.schedule.rawValue)
                Text("Ban ngày".tr).tag(GardenClockTheme.light.rawValue)
                Text("Ban đêm".tr).tag(GardenClockTheme.dark.rawValue)
            }

            VStack(alignment: .leading) {
                Text("Kích thước cây".tr)
                Slider(value: $plantScale, in: 0.7...1.3, step: 0.05)
                    .tint(currentAccent.color)
                    .accessibilityLabel("Kích thước cây".tr)
            }

            Toggle("Hiển thị ngày".tr, isOn: $showDate)
            Toggle("Hiển thị tên cây".tr, isOn: $showPlantName)
            Toggle("Hiển thị giây".tr, isOn: $showSeconds)
            Toggle("Định dạng 24 giờ".tr, isOn: $use24HourTime)
            Toggle("Chuyển động nhẹ".tr, isOn: $animatePlant)
            Text("Giây và chuyển động tự tắt khi màn hình giảm sáng hoặc bật Giảm chuyển động.".tr)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func accentTitle(_ option: GardenAccent) -> String {
        switch option {
        case .mint: return "Xanh bạc hà"
        case .amber: return "Hổ phách"
        case .lavender: return "Oải hương"
        case .ocean: return "Đại dương"
        case .rose: return "Hồng đào"
        }
    }

    // MARK: - Sleep, Weather, Health, Tips

    private var sleepSection: some View {
        Section("Đồng hồ Terrarium".tr) {
            Text("Bình minh bắt đầu vào giờ thức dậy; hoàng hôn bắt đầu vào giờ đi ngủ rồi chuyển sang đêm. Mỗi chuyển cảnh kéo dài tối đa 30 phút. Khi mở Watch, bầu trời hiện đúng thời điểm hiện tại.".tr)
                .font(.caption)
            SleepScheduleCard()
        }
    }

    private var weatherSection: some View {
        Section("Thời tiết và UV".tr) {
            Toggle("Đồng bộ thời tiết".tr, isOn: Binding(
                get: { weatherEnabled }, set: { weather.setEnabled($0) }))
            Text(weather.message.tr).font(.caption)
            if weatherEnabled {
                if weather.isLoading { ProgressView() }
                Button("Cập nhật thời tiết".tr) { weather.refresh(force: true, promptForLocation: true) }
                    .disabled(weather.isLoading)
                if let reading = weather.weather, reading.isFresh(at: .now) {
                    ForEach(GardenWeatherMetric.allCases, id: \.self) { metric in
                        LabeledContent(metric.titleKey.tr,
                            value: metric.value(in: reading, fahrenheit: false, language: localization.currentLanguage.rawValue))
                    }
                    Link(destination: reading.legalURL) {
                        HStack {
                            if let data = reading.attributionMark, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().scaledToFit().frame(width: 90, height: 20)
                                    .padding(6).background(.black, in: RoundedRectangle(cornerRadius: 5))
                            } else { Text("Apple Weather") }
                            Text("Nguồn dữ liệu thời tiết".tr).font(.caption)
                        }
                    }
                }
                Text("Vị trí chỉ dùng trên iPhone để lấy thời tiết. Watch nhận số liệu, không nhận tọa độ. Có thể chọn độ C hoặc độ F trong cấu hình widget.".tr)
                    .font(.caption)
            }
        }
    }

    private var healthSection: some View {
        Section("Kết nối giấc ngủ với cây".tr) {
            Toggle("Đọc giấc ngủ từ Apple Health".tr, isOn: Binding(
                get: { sleepConnected },
                set: { value in
                    requestingSleep = true
                    Task {
                        await service.setSleepConnection(value)
                        requestingSleep = false
                    }
                }))
                .disabled(requestingSleep)
            if requestingSleep { ProgressView() }
            if let message = service.healthMessage { Text(message.tr).font(.caption) }
            Text("Tùy chọn này chỉ đọc thời lượng ngủ để hiển thị. Không thay đổi theo dõi giấc ngủ của Apple Watch. Tắt kết nối sẽ ngừng đọc và gửi yêu cầu xóa số liệu trên Watch khi đồng bộ tới nơi. Hiệu ứng bầu trời vẫn theo lịch, không cần Apple Health.".tr)
                .font(.caption)
        }
    }

    private var tipsSection: some View {
        Section {
            Text("Mỗi widget có thể chọn nội dung riêng: cây yêu thích, lịch ngủ/thức hoặc ngày giờ. Thêm Terrarium vào Smart Stack hoặc vùng tiện ích trên mặt đồng hồ, rồi chọn cấu hình phù hợp.".tr)
                .font(.caption)
            Text("Thêm tiện ích Terrarium khi chỉnh sửa mặt đồng hồ Apple. Chạm vào tiện ích để mở đồng hồ Terrarium với cây lớn. Màn hình trong app không thay thế mặt đồng hồ hệ thống.".tr)
                .font(.caption)
        }
    }
}

private struct WatchFaceShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

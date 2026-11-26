import SwiftUI
import UIKit
#if os(watchOS)
import WatchKit
#endif

extension GardenAccent {
    var color: Color {
        switch self {
        case .mint: return Color(red: 0.32, green: 0.85, blue: 0.65)
        case .amber: return Color(red: 1.0, green: 0.72, blue: 0.28)
        case .lavender: return Color(red: 0.73, green: 0.59, blue: 0.95)
        case .ocean: return Color(red: 0.25, green: 0.69, blue: 0.96)
        case .rose: return Color(red: 0.96, green: 0.54, blue: 0.68)
        }
    }
}

private struct WatchOxygenBubble: Identifiable {
    let id = UUID()
    let xOffset: CGFloat
    let yOffset: CGFloat
    let size: CGFloat
    let driftX: CGFloat
    let rise: CGFloat
    let duration: Double
}

struct GardenClockView: View {
    let snapshot: WatchGardenSnapshot
    var showClock: Bool = true
    @Environment(\.isLuminanceReduced) private var dimmed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubbles: [WatchOxygenBubble] = []
    @State private var tapScale: CGFloat = 1.0
    @State private var tapTilt: Double = 0.0

    private var design: Font.Design {
        switch snapshot.display.font {
        case .rounded: return .rounded
        case .classic: return .serif
        case .monospaced: return .monospaced
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: dimmed || reduceMotion ? 60 : 1)) { context in
            GeometryReader { geometry in
                let sky = GardenSkyState.resolve(at: context.date, snapshot: snapshot)
                let isLightSky = sky.phase == .day || (sky.phase == .dawn && sky.progress > 0.6)
                let ink: Color = isLightSky ? Color(red: 0.08, green: 0.16, blue: 0.14) : .white

                ZStack {
                    GardenSkyView(state: sky, accent: snapshot.display.accent.color)

                    VStack(spacing: 2) {
                        topBar(at: context.date, isLightSky: isLightSky)
                            .padding(.top, 4)

                        if !showClock {
                            Spacer(minLength: 4)
                            plantView(at: context.date, size: geometry.size, isLightSky: isLightSky)
                                .frame(height: geometry.size.height * 0.62)
                            Spacer(minLength: 2)
                        } else if snapshot.display.layout == .plantFocus {
                            Spacer(minLength: 2)
                            plantView(at: context.date, size: geometry.size, isLightSky: isLightSky)
                                .frame(height: geometry.size.height * 0.50)
                            clockView(at: context.date, compact: true, isLightSky: isLightSky)
                                .frame(height: geometry.size.height * 0.20)
                        } else if snapshot.display.layout == .sideBySide {
                            Spacer(minLength: 2)
                            HStack(spacing: 4) {
                                clockView(at: context.date, compact: true, isLightSky: isLightSky)
                                    .frame(maxWidth: .infinity)
                                plantView(at: context.date, size: geometry.size, isLightSky: isLightSky)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(height: geometry.size.height * 0.60)
                            Spacer(minLength: 2)
                        } else {
                            clockView(at: context.date, compact: false, isLightSky: isLightSky)
                                .frame(height: geometry.size.height * 0.26)
                            Spacer(minLength: 0)
                            plantView(at: context.date, size: geometry.size, isLightSky: isLightSky)
                                .frame(height: geometry.size.height * 0.46)
                        }

                        bottomBar(isLightSky: isLightSky)
                            .padding(.bottom, 4)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(ink)
                }
                .opacity(dimmed ? 0.62 : 1)
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerTapEffect()
                }
            }
        }
        .environment(\.locale, Locale(identifier: WatchText.language(snapshot.languageCode)))
        .task(id: "\(snapshot.enabled)-\(dimmed)-\(reduceMotion)") {
            guard snapshot.enabled, !dimmed, !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 4.0...7.0)))
                guard !Task.isCancelled, !dimmed, !reduceMotion else { break }
                spawnOxygenBurst(count: Int.random(in: 2...3), bounce: false)
            }
        }
    }

    private func triggerTapEffect() {
        guard !dimmed else { return }
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        spawnOxygenBurst(count: Int.random(in: 4...6), bounce: true)
    }

    private func spawnOxygenBurst(count: Int, bounce: Bool) {
        if bounce && !reduceMotion {
            withAnimation(.easeOut(duration: 0.09)) {
                tapScale = 0.90
                tapTilt = Bool.random() ? -4.5 : 4.5
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(.spring(response: 0.34, dampingFraction: 0.45)) {
                    tapScale = 1.0
                    tapTilt = 0.0
                }
            }
        }
        guard !reduceMotion else { return }
        let newBubbles = (0..<count).map { _ in
            WatchOxygenBubble(
                xOffset: CGFloat.random(in: -38...38),
                yOffset: CGFloat.random(in: -22...14),
                size: CGFloat.random(in: 6...11),
                driftX: CGFloat.random(in: -14...14),
                rise: CGFloat.random(in: 55...95),
                duration: Double.random(in: 1.3...1.9)
            )
        }
        bubbles.append(contentsOf: newBubbles)
        let ids = Set(newBubbles.map(\.id))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.1))
            bubbles.removeAll { ids.contains($0.id) }
        }
    }

    @ViewBuilder
    private func topBar(at date: Date, isLightSky: Bool) -> some View {
        let showDate = snapshot.display.showDate && !dimmed
        let freshWeather = (snapshot.enabled && !dimmed)
            ? snapshot.weather.flatMap { $0.isFresh(at: date) ? $0 : nil }
            : nil

        if showDate || freshWeather != nil {
            HStack(spacing: 6) {
                if showDate {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)
                        .locale(Locale(identifier: WatchText.language(snapshot.languageCode)))))
                        .font(.system(size: 11, weight: .semibold, design: design))
                        .lineLimit(1)
                        .opacity(0.88)
                }
                if let weather = freshWeather {
                    HStack(spacing: 2) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 10, weight: .semibold))
                            .symbolRenderingMode(.multicolor)
                        Text(GardenWeatherMetric.temperature.value(
                            in: weather, fahrenheit: false, language: snapshot.languageCode
                        ))
                        .font(.system(size: 10, weight: .semibold, design: design))
                        .monospacedDigit()
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        (isLightSky ? Color.white.opacity(0.45) : Color.black.opacity(0.30)),
                        in: Capsule()
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func bottomBar(isLightSky: Bool) -> some View {
        if !snapshot.enabled {
            Text(WatchText.value("Mở Terrarium trên iPhone để chọn cây", language: snapshot.languageCode))
                .font(.system(size: 10, weight: .medium, design: design))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (isLightSky ? Color.white.opacity(0.55) : Color.black.opacity(0.35)),
                    in: Capsule()
                )
        } else if snapshot.display.showPlantName && !dimmed {
            HStack(spacing: 4) {
                Circle()
                    .fill(snapshot.display.accent.color)
                    .frame(width: 5, height: 5)
                Text(snapshot.plantName)
                    .font(.system(size: 11, weight: .semibold, design: design))
                    .lineLimit(1)
                if let level = snapshot.plantLevel, level > 0 {
                    Text("Lv.\(level)")
                        .font(.system(size: 9, weight: .bold, design: design))
                        .foregroundStyle(snapshot.display.accent.color)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                (isLightSky ? Color.white.opacity(0.50) : Color.black.opacity(0.36)),
                in: Capsule()
            )
        }
    }

    @ViewBuilder
    private func plantView(at date: Date, size: CGSize, isLightSky: Bool) -> some View {
        let shouldAnimate = !dimmed && !reduceMotion && snapshot.display.animatePlant
        let t = date.timeIntervalSinceReferenceDate
        let bob = shouldAnimate ? sin(t / 2.6) * 2.0 : 0.0
        let sway = shouldAnimate ? sin(t / 3.4) * 1.1 : 0.0

        ZStack(alignment: .bottom) {
            // Soft contact shadow on the terrarium moss hill
            Ellipse()
                .fill(Color.black.opacity(isLightSky ? 0.16 : 0.32))
                .frame(width: size.width * 0.34 * snapshot.display.plantScale, height: 7)
                .blur(radius: 2.5)
                .offset(y: 1)

            Group {
                if snapshot.enabled, let data = snapshot.artwork, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(snapshot.plantName)
                } else {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(snapshot.display.accent.color)
                        .padding(14)
                }
            }
            .scaleEffect(snapshot.display.plantScale * tapScale, anchor: .bottom)
            .rotationEffect(.degrees(sway + tapTilt), anchor: .bottom)
            .offset(y: bob)
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

            // Purely visual oxygen bubbles (tap & periodic auto-emit)
            ForEach(bubbles) { bubble in
                WatchOxygenBubbleView(bubble: bubble, accent: snapshot.display.accent.color)
            }
        }
    }

    @ViewBuilder
    private func clockView(at date: Date, compact: Bool, isLightSky: Bool) -> some View {
        if snapshot.clockStyle == .analog {
            analogClock(at: date, isLightSky: isLightSky)
        } else {
            digitalClock(at: date, compact: compact, isLightSky: isLightSky)
        }
    }

    @ViewBuilder
    private func digitalClock(at date: Date, compact: Bool, isLightSky: Bool) -> some View {
        let mainSize: CGFloat = compact ? 25 : 36
        let showSec = snapshot.display.showSeconds && !dimmed && !reduceMotion

        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(mainTimeString(at: date))
                .font(.system(size: mainSize, weight: .bold, design: design))
                .monospacedDigit()
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            if showSec {
                Text(secondsString(at: date))
                    .font(.system(size: mainSize * 0.44, weight: .bold, design: design))
                    .monospacedDigit()
                    .foregroundStyle(snapshot.display.accent.color)
            }
        }
        .shadow(color: isLightSky ? .white.opacity(0.35) : .black.opacity(0.35), radius: 3, y: 1)
    }

    private func mainTimeString(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: WatchText.language(snapshot.languageCode))
        formatter.dateFormat = snapshot.display.use24HourTime ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    private func secondsString(at date: Date) -> String {
        let sec = Calendar.current.component(.second, from: date)
        return String(format: "%02d", sec)
    }

    private func fullTimeString(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: WatchText.language(snapshot.languageCode))
        let seconds = snapshot.display.showSeconds && !dimmed && !reduceMotion
        formatter.dateFormat = snapshot.display.use24HourTime
            ? (seconds ? "HH:mm:ss" : "HH:mm") : (seconds ? "h:mm:ss a" : "h:mm a")
        return formatter.string(from: date)
    }

    private func analogClock(at date: Date, isLightSky: Bool) -> some View {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let minute = Double(parts.minute ?? 0)
        let hour = Double((parts.hour ?? 0) % 12) + minute / 60
        let accent = snapshot.display.accent.color

        return GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(isLightSky ? Color.white.opacity(0.28) : Color.black.opacity(0.28))
                Circle()
                    .strokeBorder(accent.opacity(0.65), lineWidth: 1.5)

                ForEach(0..<12) { tick in
                    let isCardinal = tick % 3 == 0
                    Capsule()
                        .fill(isCardinal ? accent : Color.primary.opacity(0.55))
                        .frame(width: isCardinal ? 2 : 1, height: isCardinal ? 5 : 3)
                        .offset(y: -size * 0.41)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                // Hour hand
                Capsule()
                    .frame(width: 2.8, height: size * 0.25)
                    .offset(y: -size * 0.125)
                    .rotationEffect(.degrees(hour * 30))
                    .shadow(color: .black.opacity(0.2), radius: 1)

                // Minute hand
                Capsule()
                    .frame(width: 2, height: size * 0.36)
                    .offset(y: -size * 0.18)
                    .rotationEffect(.degrees(minute * 6))
                    .shadow(color: .black.opacity(0.2), radius: 1)

                if snapshot.display.showSeconds && !dimmed && !reduceMotion {
                    Capsule()
                        .fill(accent)
                        .frame(width: 1.2, height: size * 0.41)
                        .offset(y: -size * 0.17)
                        .rotationEffect(.degrees(Double(parts.second ?? 0) * 6))
                }

                Circle()
                    .fill(accent)
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(isLightSky ? .white : .black)
                    .frame(width: 2, height: 2)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fullTimeString(at: date))
    }
}

private struct GardenSkyView: View {
    let state: GardenSkyState
    let accent: Color

    private var daylight: Double {
        switch state.phase {
        case .day: return 1
        case .night: return 0
        case .dawn: return state.progress
        case .dusk: return 1 - state.progress
        }
    }

    private var twilightIntensity: Double {
        (state.phase == .dawn || state.phase == .dusk) ? sin(state.progress * .pi) : 0
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Night sky base
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.05, blue: 0.14),
                        Color(red: 0.06, green: 0.11, blue: 0.24),
                        Color(red: 0.05, green: 0.15, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Day sky overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.31, green: 0.67, blue: 0.86),
                        Color(red: 0.62, green: 0.85, blue: 0.90),
                        Color(red: 0.92, green: 0.95, blue: 0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(daylight)

                // Dawn / Dusk warm atmospheric glow
                LinearGradient(
                    colors: [
                        Color(red: 0.25, green: 0.22, blue: 0.48).opacity(0.6),
                        Color(red: 0.91, green: 0.52, blue: 0.42).opacity(0.75),
                        Color(red: 0.98, green: 0.78, blue: 0.52).opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(twilightIntensity)

                // Stars at night
                ForEach(0..<14, id: \.self) { index in
                    let x = Double((index * 47 + 19) % 94 + 3) / 100.0
                    let y = Double((index * 23 + 11) % 52 + 4) / 100.0
                    let starSize: CGFloat = (index % 3 == 0) ? 2.2 : 1.3
                    Circle()
                        .fill(Color.white.opacity(index % 2 == 0 ? 0.85 : 0.45))
                        .frame(width: starSize, height: starSize)
                        .position(x: w * x, y: h * y)
                }
                .opacity(max(0, 1 - daylight * 1.4))

                // Glowing Sun
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.55),
                                    Color(red: 1.0, green: 0.78, blue: 0.35).opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 6,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.86, blue: 0.48))
                        .frame(width: 22, height: 22)
                }
                .position(x: w * 0.80, y: h * (0.78 - daylight * 0.54))
                .opacity(min(1, daylight * 2.2))

                // Glowing Moon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.22), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Color(red: 0.95, green: 0.96, blue: 1.0).opacity(0.9))
                }
                .position(x: w * 0.80, y: h * 0.22)
                .opacity(max(0, 1 - daylight * 1.3))

                // Distant soft mist hill
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                (daylight > 0.5
                                    ? Color(red: 0.24, green: 0.52, blue: 0.40)
                                    : Color(red: 0.08, green: 0.22, blue: 0.20)).opacity(0.65),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 1.5, height: h * 0.34)
                    .position(x: w * 0.35, y: h * 0.94)

                // Foreground Terrarium Moss Ground
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                daylight > 0.5
                                    ? Color(red: 0.20, green: 0.48, blue: 0.34)
                                    : Color(red: 0.08, green: 0.24, blue: 0.19),
                                daylight > 0.5
                                    ? Color(red: 0.11, green: 0.30, blue: 0.22)
                                    : Color(red: 0.04, green: 0.13, blue: 0.11)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 1.65, height: h * 0.32)
                    .position(x: w * 0.52, y: h * 0.98)

                // Subtle accent rim glow along top
                RadialGradient(
                    colors: [accent.opacity(0.14), .clear],
                    center: .top,
                    startRadius: 5,
                    endRadius: h * 0.65
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct WatchWeatherDetailView: View {
    let snapshot: WatchGardenSnapshot
    private func text(_ key: String) -> String { WatchText.value(key, language: snapshot.languageCode) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: snapshot.weather?.symbolName ?? "cloud.sun.fill")
                            .symbolRenderingMode(.multicolor)
                        Text(text("Thời tiết và UV"))
                            .font(.headline)
                    }
                    .padding(.bottom, 2)

                    if snapshot.enabled, let weather = snapshot.weather, weather.isFresh(at: context.date) {
                        ForEach(GardenWeatherMetric.allCases, id: \.self) { metric in
                            HStack {
                                Label(
                                    text(metric.titleKey),
                                    systemImage: metric == .weather ? weather.symbolName : metric.icon
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                Spacer(minLength: 4)
                                Text(metric.value(in: weather, fahrenheit: false, language: snapshot.languageCode))
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        }

                        Text(WatchText.format("Cập nhật %@", language: snapshot.languageCode,
                            weather.measuredAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: WatchText.language(snapshot.languageCode))))))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    } else {
                        Text(text("Mở iPhone để cập nhật"))
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Text(text("Thời tiết được cập nhật khi mở app iPhone; widget không cập nhật liên tục."))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let weather = snapshot.weather {
                        Link(destination: weather.legalURL) {
                            VStack(alignment: .leading, spacing: 3) {
                                if let data = weather.attributionMark, let image = UIImage(data: data) {
                                    Image(uiImage: image).resizable().scaledToFit().frame(width: 90, height: 18)
                                } else {
                                    Text("Apple Weather").font(.caption)
                                }
                                Text(text("Nguồn dữ liệu thời tiết")).font(.caption2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }
}

private struct WatchOxygenBubbleView: View {
    let bubble: WatchOxygenBubble
    let accent: Color
    @State private var risen = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.65), accent.opacity(0.45)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: bubble.size * 0.7
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.75), lineWidth: 0.75)
                )

            // 30% specular highlight dot for 3D glossy bubble look
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: bubble.size * 0.30, height: bubble.size * 0.30)
                .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.18)
        }
        .frame(width: bubble.size, height: bubble.size)
        .scaleEffect(risen ? 1.25 : 0.75)
        .opacity(risen ? 0.0 : 0.92)
        .offset(
            x: bubble.xOffset + (risen ? bubble.driftX : 0),
            y: bubble.yOffset - (risen ? bubble.rise : 0)
        )
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: bubble.duration)) {
                risen = true
            }
        }
    }
}

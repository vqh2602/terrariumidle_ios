import SwiftUI

/// Hiệu ứng thời tiết toàn cảnh khu vườn (Mưa tự nhiên & Gió lốc sinh động)
/// - Mưa: 3 tầng chiều sâu 3D (mưa bụi xa, mưa rào chính, vệt lướt gần), góc nghiêng gió tự nhiên,
///         gợn sóng phản chiếu (ripples) & giọt bắn tung tóe (splashes) tại các mặt kệ và đáy.
/// - Gió: Dải khí uốn lượn mềm mại kèm xoáy gió Ghibli (swirls), lá non xanh & cánh hoa rơi
///        chao liệng 3D trong gió, hạt bồ công anh và bụi phấn hoa lấp lánh.
struct GardenWeatherOverlay: View {
    let weatherUntil: TimeInterval
    let kind: GardenModel.WeatherKind
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isActive = false

    var body: some View {
        ZStack(alignment: .top) {
            if isActive {
                // Lớp phủ môi trường khí quyển tự nhiên
                weatherAtmosphere
                    .ignoresSafeArea()

                // Hoạt ảnh hạt & khí quyển thời tiết
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
                        Canvas { canvas, size in
                            let time = context.date.timeIntervalSince1970
                            if kind == .wind {
                                drawWind(in: &canvas, size: size, time: time)
                            } else {
                                drawRain(in: &canvas, size: size, time: time)
                            }
                        }
                    }
                    .ignoresSafeArea()
                }

                // Banner đếm ngược thời gian hiệu lực
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = max(0, Int(ceil(weatherUntil - context.date.timeIntervalSince1970)))
                    HStack(spacing: 8) {
                        Image(systemName: kind.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(kind == .rain ? Color(red: 0.35, green: 0.75, blue: 1.0) : Color(red: 0.40, green: 0.85, blue: 0.55))
                        Text("%@ · Tự tap toàn vườn · %ds".tr(kind.title, seconds))
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                    .padding(.top, 130)
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: "\(weatherUntil)-\(scenePhase)") {
            let remaining = weatherUntil - Date().timeIntervalSince1970
            isActive = remaining > 0 && scenePhase == .active
            guard isActive else { return }
            do {
                try await Task.sleep(for: .seconds(remaining))
                isActive = false
            } catch { }
        }
        .onChange(of: isActive) { _, active in
            syncWeatherAudio(active: active)
        }
        .onChange(of: kind) { _, _ in
            syncWeatherAudio(active: isActive)
        }
        .onDisappear {
            BackgroundAudioManager.shared.stopWeatherSound()
        }
    }

    private func syncWeatherAudio(active: Bool) {
        if active {
            BackgroundAudioManager.shared.startWeatherSound(fileName: kind.soundFileName, ext: "wav")
        } else {
            BackgroundAudioManager.shared.stopWeatherSound()
        }
    }

    // MARK: - Ambient Atmospheres

    @ViewBuilder
    private var weatherAtmosphere: some View {
        if kind == .rain {
            // Màn trời mưa ẩm ướt mát mẻ, sương mờ dịu mắt
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.20, blue: 0.32).opacity(0.14),
                    Color(red: 0.16, green: 0.26, blue: 0.36).opacity(0.06),
                    Color(red: 0.20, green: 0.30, blue: 0.40).opacity(0.02),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Ngày lộng gió tươi sáng, ánh nắng dịu nhẹ hòa cùng không khí trong lành
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 0.88).opacity(0.06),
                    Color(red: 1.0, green: 0.98, blue: 0.90).opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Rain Simulation

    private func drawRain(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        guard size.width > 0, size.height > 0 else { return }

        // Độ nghiêng gió tự nhiên: rơi thoai thoải sang trái kèm dao động vi mô
        let windSway = sin(time * 0.75) * 0.035
        let slant: CGFloat = -0.16 + windSway // dx/dy

        // 1. Tầng mưa bụi sương xa (Background Drizzle - 90 hạt mờ mảnh)
        for i in 0..<90 {
            let seed = Double(i)
            let speed = 400.0 + seed.truncatingRemainder(dividingBy: 11) * 28.0
            let loopH = size.height + 60.0
            let y = (time * speed + seed * 73.0).truncatingRemainder(dividingBy: loopH) - 30.0
            let x = ((seed * 149.3) + y * slant).truncatingRemainder(dividingBy: size.width + 100.0) - 50.0
            let len = 15.0 + seed.truncatingRemainder(dividingBy: 7) * 3.0
            let alpha = 0.13 + seed.truncatingRemainder(dividingBy: 5) * 0.03

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + slant * len, y: y + len))
            canvas.stroke(
                path,
                with: .color(Color(white: 0.94).opacity(alpha)),
                style: StrokeStyle(lineWidth: 0.75, lineCap: .round)
            )
        }

        // 2. Tầng mưa chính trung cảnh (Midground Rain - 75 hạt rõ nét, ánh nước)
        for i in 0..<75 {
            let seed = Double(i + 100)
            let speed = 720.0 + seed.truncatingRemainder(dividingBy: 9) * 45.0
            let loopH = size.height + 120.0
            let y = (time * speed + seed * 107.0).truncatingRemainder(dividingBy: loopH) - 60.0
            let x = ((seed * 197.7) + y * slant).truncatingRemainder(dividingBy: size.width + 120.0) - 60.0
            let len = 38.0 + seed.truncatingRemainder(dividingBy: 8) * 4.0
            let alpha = 0.28 + seed.truncatingRemainder(dividingBy: 5) * 0.04

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + slant * len, y: y + len))
            canvas.stroke(
                path,
                with: .color(Color(red: 0.88, green: 0.94, blue: 1.0).opacity(alpha)),
                style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
            )
        }

        // 3. Vệt mưa lướt nhanh tiền cảnh (Foreground Speed Streaks - 16 hạt dài)
        for i in 0..<16 {
            let seed = Double(i + 200)
            let speed = 1200.0 + seed.truncatingRemainder(dividingBy: 5) * 80.0
            let loopH = size.height + 180.0
            let y = (time * speed + seed * 139.0).truncatingRemainder(dividingBy: loopH) - 90.0
            let x = ((seed * 223.1) + y * slant).truncatingRemainder(dividingBy: size.width + 160.0) - 80.0
            let len = 72.0 + seed.truncatingRemainder(dividingBy: 5) * 15.0
            let alpha = 0.22 + seed.truncatingRemainder(dividingBy: 4) * 0.04

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + slant * len, y: y + len))
            canvas.stroke(
                path,
                with: .color(Color.white.opacity(alpha)),
                style: StrokeStyle(lineWidth: 1.85, lineCap: .round)
            )
        }

        // 4. Giọt bắn & Gợn sóng chạm kệ (Splashes & Surface Ripples - 26 điểm)
        for i in 0..<26 {
            let seed = Double(i + 300)
            let shelfTier = (seed.truncatingRemainder(dividingBy: 5)) / 4.0 // Trải đều các tầng kệ
            let impactY = size.height * (0.36 + shelfTier * 0.58) + (seed.truncatingRemainder(dividingBy: 7) - 3.0) * 8.0
            let impactX = (seed * 167.3).truncatingRemainder(dividingBy: max(size.width - 40.0, 1.0)) + 20.0

            let period = 0.55 + (seed.truncatingRemainder(dividingBy: 4)) * 0.12
            let phase = (time + seed * 0.31).truncatingRemainder(dividingBy: period)
            let progress = phase / period

            if progress < 0.65 {
                let p = progress / 0.65
                let fade = 1.0 - p

                // Gợn sóng elip lan tỏa theo góc nhìn kệ
                let rx = 1.8 + p * 8.5
                let ry = rx * 0.32
                let rippleRect = CGRect(x: impactX - rx, y: impactY - ry, width: rx * 2.0, height: ry * 2.0)
                canvas.stroke(
                    Path(ellipseIn: rippleRect),
                    with: .color(Color(red: 0.85, green: 0.94, blue: 1.0).opacity(fade * 0.42)),
                    lineWidth: 0.85
                )

                // 2 giọt nước bắn tung tóe theo đường parabol
                let bounceH = sin(p * .pi) * (5.5 + seed.truncatingRemainder(dividingBy: 3) * 3.0)
                let spread1 = p * 6.5
                let spread2 = p * 7.5
                let d1 = CGPoint(x: impactX - spread1, y: impactY - bounceH)
                let d2 = CGPoint(x: impactX + spread2, y: impactY - bounceH * 0.82)

                canvas.fill(
                    Path(ellipseIn: CGRect(x: d1.x - 0.7, y: d1.y - 0.7, width: 1.4, height: 1.4)),
                    with: .color(Color.white.opacity(fade * 0.55))
                )
                canvas.fill(
                    Path(ellipseIn: CGRect(x: d2.x - 0.7, y: d2.y - 0.7, width: 1.4, height: 1.4)),
                    with: .color(Color.white.opacity(fade * 0.55))
                )
            }
        }
    }

    // MARK: - Wind Simulation

    private func drawWind(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        guard size.width > 0, size.height > 0 else { return }

        // 1. Dòng khí gió uốn lượn mượt mà (Flowing Wind Ribbons - 14 luồng)
        for i in 0..<14 {
            let seed = Double(i)
            let speed = 210.0 + seed.truncatingRemainder(dividingBy: 5) * 45.0
            let length = 130.0 + seed.truncatingRemainder(dividingBy: 4) * 35.0
            let loopW = size.width + length * 2.2
            let headX = (time * speed + seed * 163.0).truncatingRemainder(dividingBy: loopW) - length
            let baseY = size.height * (0.12 + seed.truncatingRemainder(dividingBy: 8) * 0.105)

            let progress = (headX + length) / (size.width + length * 1.8)
            let screenAlpha = sin(min(max(progress, 0.0), 1.0) * .pi) * 0.40
            guard screenAlpha > 0.01 else { continue }

            var path = Path()
            let steps = 22
            for s in 0...steps {
                let t = CGFloat(s) / CGFloat(steps)
                let px = headX - (1.0 - t) * length
                let wave1 = sin(px * 0.012 + time * 2.8 + seed) * 13.0
                let wave2 = cos(px * 0.024 + seed * 1.6) * 5.0
                let py = baseY + wave1 + wave2
                if s == 0 {
                    path.move(to: CGPoint(x: px, y: py))
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }

            // Xoáy gió cuộn tròn (Ghibli Wind Swirl) ở đầu luồng
            if Int(seed) % 4 == 0 {
                let headWave = sin(headX * 0.012 + time * 2.8 + seed) * 13.0 + cos(headX * 0.024 + seed * 1.6) * 5.0
                let swirlCenter = CGPoint(x: headX + 7.0, y: baseY + headWave - 2.0)
                let swirlRadius: CGFloat = 8.0
                let swirlStart = Angle(radians: -Double.pi * 0.5)
                let swirlEnd = Angle(radians: Double.pi * 1.3)
                path.addRelativeArc(
                    center: swirlCenter,
                    radius: swirlRadius,
                    startAngle: swirlStart,
                    delta: swirlEnd - swirlStart
                )
            }

            canvas.stroke(
                path,
                with: .color(Color.white.opacity(screenAlpha)),
                style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)
            )
        }

        // 2. Lá non xanh chao liệng xoay 3D trong gió (Dancing Fresh Leaves - 12 lá)
        for i in 0..<12 {
            let seed = Double(i + 100)
            let speed = 190.0 + seed.truncatingRemainder(dividingBy: 4) * 35.0
            let loopW = size.width + 60.0
            let leafX = (time * speed + seed * 137.0).truncatingRemainder(dividingBy: loopW) - 30.0
            let baseY = size.height * (0.16 + seed.truncatingRemainder(dividingBy: 7) * 0.11)
            let waveY = sin(time * 3.4 + seed * 2.0) * 18.0 + cos(leafX * 0.016 + seed) * 9.0
            let leafY = baseY + waveY
            let rot = time * 4.0 + seed * 2.1
            let scaleX = cos(rot * 0.85) // Hiệu ứng lật lọng 3D khi lá bay trong không gian

            canvas.drawLayer { ctx in
                ctx.translateBy(x: leafX, y: leafY)
                ctx.rotate(by: Angle(radians: rot))
                ctx.scaleBy(x: scaleX, y: 1.0)

                // Phiến lá non nhọn 2 đầu
                var leafPath = Path()
                leafPath.move(to: CGPoint(x: -6, y: 0))
                leafPath.addQuadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 0, y: -4.5))
                leafPath.addQuadCurve(to: CGPoint(x: -6, y: 0), control: CGPoint(x: 0, y: 4.5))

                // Màu xanh non tươi tắn pha sắc mạ
                ctx.fill(
                    leafPath,
                    with: .color(Color(red: 0.38, green: 0.82, blue: 0.40).opacity(0.85))
                )
                // Gân lá mờ
                var stem = Path()
                stem.move(to: CGPoint(x: -5, y: 0))
                stem.addLine(to: CGPoint(x: 5, y: 0))
                ctx.stroke(stem, with: .color(Color(red: 0.22, green: 0.58, blue: 0.26).opacity(0.65)), lineWidth: 0.6)
            }
        }

        // 3. Cánh hoa đào hồng phấn dịu dàng rơi bay lượn (Fluttering Petals - 8 cánh)
        for i in 0..<8 {
            let seed = Double(i + 200)
            let speed = 160.0 + seed.truncatingRemainder(dividingBy: 3) * 30.0
            let loopW = size.width + 60.0
            let petalX = (time * speed + seed * 151.0).truncatingRemainder(dividingBy: loopW) - 30.0
            let baseY = size.height * (0.22 + seed.truncatingRemainder(dividingBy: 6) * 0.11)
            let waveY = sin(time * 2.6 + seed * 1.8) * 15.0
            let petalY = baseY + waveY
            let rot = time * 3.0 + seed * 1.7

            canvas.drawLayer { ctx in
                ctx.translateBy(x: petalX, y: petalY)
                ctx.rotate(by: Angle(radians: rot))
                ctx.scaleBy(x: cos(rot * 0.7), y: 1.0)

                var petalPath = Path()
                petalPath.move(to: CGPoint(x: 0, y: -4.5))
                petalPath.addQuadCurve(to: CGPoint(x: 3.5, y: 2), control: CGPoint(x: 4, y: -2))
                petalPath.addQuadCurve(to: CGPoint(x: 0, y: 4.5), control: CGPoint(x: 2, y: 4))
                petalPath.addQuadCurve(to: CGPoint(x: -3.5, y: 2), control: CGPoint(x: -2, y: 4))
                petalPath.addQuadCurve(to: CGPoint(x: 0, y: -4.5), control: CGPoint(x: -4, y: -2))

                ctx.fill(
                    petalPath,
                    with: .color(Color(red: 1.0, green: 0.76, blue: 0.84).opacity(0.85))
                )
            }
        }

        // 4. Hạt bồ công anh trôi lơ lửng theo gió (Dandelion Fluffs - 6 hạt)
        for i in 0..<6 {
            let seed = Double(i + 300)
            let speed = 135.0 + seed.truncatingRemainder(dividingBy: 4) * 25.0
            let loopW = size.width + 50.0
            let fluffX = (time * speed + seed * 179.0).truncatingRemainder(dividingBy: loopW) - 25.0
            let baseY = size.height * (0.18 + seed.truncatingRemainder(dividingBy: 5) * 0.13)
            let fluffY = baseY + sin(time * 2.2 + seed) * 12.0

            // Hạt nhụy nhỏ
            canvas.fill(
                Path(ellipseIn: CGRect(x: fluffX - 1.0, y: fluffY - 1.0, width: 2.0, height: 2.0)),
                with: .color(Color.white.opacity(0.85))
            )
            // Sợi tơ xòe nhẹ xuôi theo gió
            var fluffTuft = Path()
            fluffTuft.move(to: CGPoint(x: fluffX, y: fluffY))
            fluffTuft.addLine(to: CGPoint(x: fluffX - 5.5, y: fluffY - 2.5))
            fluffTuft.move(to: CGPoint(x: fluffX, y: fluffY))
            fluffTuft.addLine(to: CGPoint(x: fluffX - 6.0, y: fluffY))
            fluffTuft.move(to: CGPoint(x: fluffX, y: fluffY))
            fluffTuft.addLine(to: CGPoint(x: fluffX - 5.5, y: fluffY + 2.5))
            canvas.stroke(
                fluffTuft,
                with: .color(Color.white.opacity(0.55)),
                lineWidth: 0.65
            )
        }

        // 5. Bụi phấn hoa & Đốm sáng lấp lánh trong gió (Breeze Shimmer / Pollen - 32 hạt)
        for i in 0..<32 {
            let seed = Double(i + 400)
            let speed = 280.0 + seed.truncatingRemainder(dividingBy: 6) * 45.0
            let loopW = size.width + 40.0
            let px = (time * speed + seed * 113.0).truncatingRemainder(dividingBy: loopW) - 20.0
            let py = size.height * (0.10 + seed.truncatingRemainder(dividingBy: 9) * 0.095) + sin(time * 4.0 + seed) * 10.0
            let shimmer = sin(time * 5.0 + seed) * 0.3 + 0.5
            let r: CGFloat = 1.0 + CGFloat(Int(seed) % 3) * 0.5

            canvas.fill(
                Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2.0, height: r * 2.0)),
                with: .color(Color(red: 1.0, green: 0.95, blue: 0.72).opacity(shimmer * 0.70))
            )
        }
    }
}

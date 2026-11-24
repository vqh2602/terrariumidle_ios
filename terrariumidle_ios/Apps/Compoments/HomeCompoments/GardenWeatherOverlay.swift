import SwiftUI

/// Shared weather lifetime and countdown with bounded, texture-free artwork.
struct GardenWeatherOverlay: View {
    let weatherUntil: TimeInterval
    let kind: GardenModel.WeatherKind
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isActive = false

    var body: some View {
        ZStack(alignment: .top) {
            if isActive {
                Color.blue.opacity(kind == .rain ? 0.045 : 0.015)
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        Canvas { canvas, size in
                            let time = context.date.timeIntervalSince1970
                            if kind == .wind {
                                drawWind(in: &canvas, size: size, time: time)
                            } else {
                                drawRain(in: &canvas, size: size, time: time)
                            }
                        }
                    }
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = max(0, Int(ceil(weatherUntil - context.date.timeIntervalSince1970)))
                    Label("\(kind.title) · Tự tap toàn vườn · \(seconds)s", systemImage: kind.icon)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
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
    }

    private func drawRain(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<90 {
            let seed = Double(index)
            let speed = 360 + seed.truncatingRemainder(dividingBy: 7) * 36
            let height = size.height + 40
            let y = (time * speed + seed * 79).truncatingRemainder(dividingBy: height) - 20
            let x = (seed * 137.5).truncatingRemainder(dividingBy: max(size.width + 40, 1)) - 20
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 4, y: y + 12 + seed.truncatingRemainder(dividingBy: 9)))
            canvas.stroke(path, with: .color(.cyan.opacity(0.22 + seed.truncatingRemainder(dividingBy: 4) * 0.08)),
                          style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }

    private func drawWind(in canvas: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        // Three staggered gusts cross the screen, then leave a quiet interval.
        let elapsed = time - (weatherUntil - 60)
        for index in 0..<15 {
            let seed = Double(index)
            let phase = (elapsed + floor(seed / 5) * 1.4).truncatingRemainder(dividingBy: 6)
            guard phase >= 0, phase < 3.2 else { continue }
            let progress = phase / 3.2
            let length = 55 + seed.truncatingRemainder(dividingBy: 4) * 15
            let x = -length + progress * (size.width + length * 2)
            let y = size.height * (0.12 + seed.truncatingRemainder(dividingBy: 5) * 0.18)
                + sin(elapsed * 2 + seed) * 12
            var path = Path()
            path.move(to: CGPoint(x: x - length, y: y))
            path.addCurve(to: CGPoint(x: x, y: y - 5),
                          control1: CGPoint(x: x - length * 0.65, y: y - 14),
                          control2: CGPoint(x: x - length * 0.25, y: y + 10))
            let opacity = sin(progress * .pi) * 0.65
            canvas.stroke(path, with: .color(.white.opacity(opacity)),
                          style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        }
    }

}

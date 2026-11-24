import SwiftUI

/// A bounded, texture-free rain layer that leaves garden interactions available.
struct GardenRainOverlay: View {
    let rainUntil: TimeInterval
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRaining = false

    var body: some View {
        ZStack(alignment: .top) {
            if isRaining {
                Color.blue.opacity(0.045)
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                        Canvas { canvas, size in
                            let time = context.date.timeIntervalSince1970
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
                    }
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let seconds = max(0, Int(ceil(rainUntil - context.date.timeIntervalSince1970)))
                    Label("Mưa · Tự tap toàn vườn · \(seconds)s", systemImage: "cloud.rain.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.top, 130)
                }
            }
        }
        .allowsHitTesting(false)
        .task(id: "\(rainUntil)-\(scenePhase)") {
            let remaining = rainUntil - Date().timeIntervalSince1970
            isRaining = remaining > 0 && scenePhase == .active
            guard isRaining else { return }
            do {
                try await Task.sleep(for: .seconds(remaining))
                isRaining = false
            } catch { }
        }
    }
}

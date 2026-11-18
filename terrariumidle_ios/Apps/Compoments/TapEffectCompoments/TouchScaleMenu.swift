import SwiftUI

struct TouchScaleMenu<Content: View>: View {
    let content: Content
    let onTap: () -> Void

    @State private var isPressed = false

    init(onTap: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        content
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.94 : 1.0, anchor: .center)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                // Trigger zoom effect
                isPressed = true

                // Call onTap
                onTap()

                // Reset zoom after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }.onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity) {
                // Long press completed - play sound and call onTap
                AudioPlayer.shared.playTap(fileName: "longpress", ext: "mp3")
                onTap()
            } onPressingChanged: { pressing in
                // Track press state for zoom effect while pressing
                isPressed = pressing
            }
            
    }
}

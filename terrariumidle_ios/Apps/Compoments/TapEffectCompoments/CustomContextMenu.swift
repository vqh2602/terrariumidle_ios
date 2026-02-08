import SwiftUI

// MARK: - Menu Item Model

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String?
    let role: ButtonRole?
    let action: () -> Void

    init(title: String, icon: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

// MARK: - Custom Context Menu Modifier

struct CustomContextMenu: ViewModifier {
    let menuItems: [MenuItem]

    @State private var showMenu = false

    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                // Chỉ hiển thị menu khi có items
                if !menuItems.isEmpty {
                    AudioPlayer.shared.playTap(fileName: "longpress", ext: "mp3")
                    showMenu = true
                }
            }
            .confirmationDialog("Chọn hành động", isPresented: $showMenu, titleVisibility: .hidden) {
                ForEach(menuItems) { item in
                    Button(role: item.role) {
                        item.action()
                    } label: {
                        if let icon = item.icon {
                            Label(item.title, systemImage: icon)
                        } else {
                            Text(item.title)
                        }
                    }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func customContextMenu(menuItems: [MenuItem]) -> some View {
        modifier(CustomContextMenu(menuItems: menuItems))
    }
}

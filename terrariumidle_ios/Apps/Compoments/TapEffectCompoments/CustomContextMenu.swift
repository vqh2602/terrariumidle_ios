import SwiftUI

struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String?
    let assetIcon: String?
    let subtitle: String?
    let role: ButtonRole?
    let action: () -> Void

    init(title: String, icon: String? = nil, assetIcon: String? = nil,
         subtitle: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.assetIcon = assetIcon
        self.subtitle = subtitle
        self.role = role
        self.action = action
    }
}

struct CustomContextMenu: ViewModifier {
    let menuItems: [MenuItem]
    @State private var showMenu = false
    @State private var selectedAction: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                guard !menuItems.isEmpty else { return }
                AudioPlayer.shared.playTap(fileName: "longpress", ext: "mp3")
                showMenu = true
            }
            .sheet(isPresented: $showMenu, onDismiss: {
                let action = selectedAction
                selectedAction = nil
                action?()
            }) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Chọn hành động".tr)
                            .font(.title3.bold())
                        Spacer()
                        Button {
                            showMenu = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Đóng menu".tr)
                    }
                    .padding(.bottom, 6)

                    ForEach(menuItems) { item in
                        Button(role: item.role) {
                            selectedAction = item.action
                            showMenu = false
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill((item.role == .destructive ? Color.orange : Color.green).opacity(0.1))
                                    if let asset = item.assetIcon {
                                        Image(asset)
                                            .resizable()
                                            .scaledToFit()
                                            .padding(7)
                                    } else if let icon = item.icon {
                                        Image(systemName: icon)
                                            .font(.title2)
                                    }
                                }
                                .frame(width: 54, height: 54)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(item.role == .destructive ? Color.red : Color.primary)
                                    if let subtitle = item.subtitle {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .presentationDetents([.height(CGFloat(132 + menuItems.count * 84))])
                .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func customContextMenu(menuItems: [MenuItem]) -> some View {
        modifier(CustomContextMenu(menuItems: menuItems))
    }
}

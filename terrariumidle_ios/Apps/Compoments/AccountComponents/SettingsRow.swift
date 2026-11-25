import SwiftUI

/// Warm, outlined surfaces shared by the account screen.
enum AccountStyle {
    static let ink = Color(hex: "57432E")
    static let muted = Color(hex: "88765C")
    static let green = Color(hex: "567747")
    static let cream = Color(hex: "FFFAEA")
    static let border = Color(hex: "DDCBA6")
    static let danger = Color(hex: "B45549")
}

struct AccountPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AccountStyle.cream)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                    .padding(4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.8), lineWidth: 1.5)
            }
            .compositingGroup()
            .shadow(color: AccountStyle.border.opacity(0.65), radius: 0, y: 4)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String?
    let isDestructive: Bool
    let trailingContent: TrailingContent
    let action: () -> Void

    enum TrailingContent {
        case chevron
        case value(String)
        case toggle(Binding<Bool>)
        case none
    }

    init(
        title: String,
        icon: String? = nil,
        isDestructive: Bool = false,
        trailingContent: TrailingContent = .chevron,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.trailingContent = trailingContent
        self.action = action
    }

    var body: some View {
        // A toggle owns its interaction; nesting it inside a Button can toggle twice.
        switch trailingContent {
        case let .toggle(binding):
            Toggle(isOn: binding) {
                rowLabel
            }
            .tint(AccountStyle.green)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        default:
            Button(action: action) {
                HStack(spacing: 12) {
                    rowLabel
                    Spacer(minLength: 4)
                    if case .chevron = trailingContent {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AccountStyle.muted)
                            .frame(width: 26, height: 26)
                            .background(AccountStyle.border.opacity(0.28), in: Circle())
                    } else if case let .value(text) = trailingContent {
                        HStack(spacing: 6) {
                            Text(text)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(AccountStyle.muted)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AccountStyle.muted)
                                .frame(width: 26, height: 26)
                                .background(AccountStyle.border.opacity(0.28), in: Circle())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var rowLabel: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isDestructive ? AccountStyle.danger : AccountStyle.green)
                    .frame(width: 36, height: 36)
                    .background(
                        isDestructive ? AccountStyle.danger.opacity(0.09) : AccountStyle.green.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(isDestructive ? AccountStyle.danger : AccountStyle.ink)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .frame(minHeight: 36)
    }
}

#Preview {
    VStack(spacing: 0) {
        SettingsRow(title: "Đồng bộ dữ liệu".tr, icon: "arrow.triangle.2.circlepath")
        SettingsRow(title: "Hiệu suất cao".tr, icon: "bolt.fill", trailingContent: .toggle(.constant(true)))
    }
    .modifier(AccountPanel())
    .padding()
}

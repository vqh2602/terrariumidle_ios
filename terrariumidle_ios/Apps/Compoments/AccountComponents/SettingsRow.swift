//
//  SettingsRow.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import SwiftUI

struct SettingsRow: View {
    let title: String
    let icon: String?
    let isDestructive: Bool
    let trailingContent: TrailingContent
    let action: () -> Void

    enum TrailingContent {
        case chevron
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
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon (optional)
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isDestructive ? .red : .gray)
                        .frame(width: 24)
                }

                // Title
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .red : .primary)

                Spacer()

                // Trailing content
                switch trailingContent {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                case let .toggle(binding):
                    Toggle("", isOn: binding)
                        .labelsHidden()

                case .none:
                    EmptyView()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 1) {
        SettingsRow(
            title: "Đồng bộ dữ liệu",
            icon: "arrow.triangle.2.circlepath",
            trailingContent: .chevron
        ) {
            print("Sync tapped")
        }

        SettingsRow(
            title: "Chế độ hiệu suất cao",
            trailingContent: .toggle(.constant(true))
        )

        SettingsRow(
            title: "Xóa tài khoản",
            icon: "trash",
            isDestructive: true,
            trailingContent: .none
        ) {
            print("Delete tapped")
        }
    }
    .background(Color.gray.opacity(0.2))
}

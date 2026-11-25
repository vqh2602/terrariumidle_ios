import SwiftUI

/// Kept outside the shelf's rotated scroll view so the controls stay upright.
struct LayoutEditingPanel: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                Text("Chỉnh bố cục".tr)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.ink)
                Spacer(minLength: 0)
                Button(action: onFinish) {
                    Label("Xong".tr, systemImage: "checkmark")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.cream)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(AccountStyle.green, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Xong, thoát chế độ bố cục".tr)
            }
            tip("plus.circle.fill", "Chạm ô + để thêm cây, chậu hoặc đồ trang trí.".tr)
            tip("hand.draw.fill", "Nhấn giữ rồi kéo sang ô khác để di chuyển hoặc đổi chỗ.".tr)
            tip("arrow.up.arrow.down", "Cuộn kệ để sắp xếp các tầng khác.".tr)
        }
        .padding(16)
        .modifier(AccountPanel())
        .accessibilityElement(children: .contain)
    }

    private func tip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(AccountStyle.green)
                .frame(width: 16)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(AccountStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(.caption, design: .rounded, weight: .medium))
    }
}

#Preview("Bố cục · 320pt".tr) {
    LayoutEditingPanel(onFinish: {})
        .padding(12)
        .frame(width: 320)
        .background(Color(hex: "E9EED9"))
}

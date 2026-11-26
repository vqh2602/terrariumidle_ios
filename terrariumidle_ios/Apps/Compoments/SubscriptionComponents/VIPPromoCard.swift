import SwiftUI

enum VIPPalette {
    static let emeraldDark = Color(hex: "1C3D2B")
    static let emeraldMid = Color(hex: "2E5B40")
    static let gold = Color(hex: "E9B44C")
    static let goldSoft = Color(hex: "FFF2CC")
    static let goldBorder = Color(hex: "D7A442")
}

struct VIPCrownBadge: View {
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: compact ? 9 : 11, weight: .bold))
            Text("VIP")
                .font(.system(size: compact ? 9 : 11, weight: .black, design: .rounded))
                .tracking(0.6)
        }
        .foregroundStyle(VIPPalette.emeraldDark)
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFE08A"), VIPPalette.gold],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.65), lineWidth: 1)
        }
    }
}

struct VIPPromoBanner: View {
    let title: String
    let subtitle: String
    var darkTheme: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFE08A"), VIPPalette.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(VIPPalette.emeraldDark)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(.subheadline, design: .rounded, weight: .heavy))
                            .foregroundStyle(darkTheme ? Color(hex: "FFE69D") : AccountStyle.cream)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(darkTheme ? .white.opacity(0.78) : AccountStyle.cream.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VIPPalette.gold)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: darkTheme
                                ? [Color(hex: "1E2D3D"), Color(hex: "223D34")]
                                : [VIPPalette.emeraldDark, VIPPalette.emeraldMid],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(VIPPalette.gold.opacity(0.55), lineWidth: 1.5)
            }
            .shadow(color: VIPPalette.emeraldDark.opacity(0.25), radius: 6, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

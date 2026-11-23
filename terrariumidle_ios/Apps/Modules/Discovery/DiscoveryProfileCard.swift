import SwiftUI

struct DiscoveryProfileCard: View {
    let profile: DiscoveredProfile
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                avatar
                VStack(alignment: .leading, spacing: 9) {
                    Text(profile.name)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.ink)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 7) { statistics }
                        VStack(alignment: .leading, spacing: 5) { statistics }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize { visitBadge }
            }
            if let oxygen = profile.oxygenCollected {
                Label("\(oxygen.formatted()) oxygen đã thu thập", systemImage: "wind")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(hex: "527F89"))
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(Color(hex: "E6EEEA"), in: RoundedRectangle(cornerRadius: 10))
            }
            if dynamicTypeSize.isAccessibilitySize { visitBadge.frame(maxWidth: .infinity, alignment: .trailing) }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Color(hex: "FFFDF3"), Color(hex: "F8F2DF")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24).strokeBorder(AccountStyle.border, lineWidth: 1.5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.8), lineWidth: 1).padding(4)
        }
        .compositingGroup()
        .shadow(color: Color(hex: "C5B58F").opacity(0.65), radius: 0, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        CachedAsyncImage(named: profile.avatar) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Color(hex: "E4EBCF")
                Image(systemName: "leaf.fill").font(.system(size: 26)).foregroundStyle(AccountStyle.green)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 19))
        .padding(4)
        .background(Color(hex: "E7D8B5"), in: RoundedRectangle(cornerRadius: 23))
        .overlay { RoundedRectangle(cornerRadius: 23).strokeBorder(Color(hex: "CFB98A"), lineWidth: 1.5) }
        .overlay(alignment: .bottom) {
            HStack(spacing: 3) {
                Image(systemName: "star.fill").font(.system(size: 8, weight: .bold))
                Text("Lv.\(profile.level)").font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(hex: "6E5229"))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color(hex: "F3D88C"), in: Capsule())
            .overlay { Capsule().strokeBorder(Color(hex: "C5A366"), lineWidth: 1) }
            .offset(y: 6)
        }
        .padding(.bottom, 6)
        .accessibilityLabel("Cấp \(profile.level)")
    }

    @ViewBuilder
    private var statistics: some View {
        stat("square.stack.3d.up.fill", value: "\(profile.floors) tầng", tint: AccountStyle.green)
        stat("heart.fill", value: profile.likes.formatted(), tint: Color(hex: "BC796C"))
    }

    private func stat(_ icon: String, value: String, tint: Color) -> some View {
        Label(value, systemImage: icon)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(tint.opacity(0.09), in: Capsule())
            .fixedSize()
    }

    private var visitBadge: some View {
        VStack(spacing: 5) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(AccountStyle.cream)
                .frame(width: 38, height: 38)
                .background {
                    Circle().fill(LinearGradient(colors: [Color(hex: "8BA669"), AccountStyle.green],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .overlay { Circle().strokeBorder(Color(hex: "486637"), lineWidth: 1.5) }
                .overlay { Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1).padding(4) }
                .shadow(color: Color(hex: "486637"), radius: 0, y: 2)
            Text("Ghé thăm")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(AccountStyle.green)
        }
        .accessibilityHidden(true)
    }
}

struct DiscoveryPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

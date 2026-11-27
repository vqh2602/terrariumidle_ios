import SwiftUI

struct ProfileCard: View {
    let userName: String
    let userEmail: String?
    let userID: String
    let userLevel: Int
    let userLikes: Int
    let userAvatar: String?
    var isVIP: Bool = false
    var isUploadingAvatar: Bool = false
    var onEditAvatar: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                Text("NGƯỜI LÀM VƯỜN".tr)
                    .tracking(2)
                if isVIP {
                    VIPCrownBadge(compact: true)
                }
            }
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(AccountStyle.green)

            avatarView

            VStack(spacing: 6) {
                Text(userName)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                    .multilineTextAlignment(.center)
                if let userEmail, !userEmail.isEmpty {
                    Text(userEmail)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }
                Text("ID: \(userID)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(AccountStyle.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AccountStyle.border.opacity(0.20), in: Capsule())
            }

            HStack(spacing: 12) {
                stat(icon: "star.fill", title: "Cấp độ".tr, value: userLevel, tint: AccountStyle.green)
                stat(icon: "heart.fill", title: "Lượt thích".tr, value: userLikes, tint: Color(hex: "C4776B"))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .modifier(AccountPanel())
    }

    @ViewBuilder
    private var avatarView: some View {
        let baseAvatar = avatar
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay {
                if isUploadingAvatar {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(.black.opacity(0.42))
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(5)
            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 31))
            .overlay {
                RoundedRectangle(cornerRadius: 31)
                    .strokeBorder(AccountStyle.border, lineWidth: 2)
            }
            .shadow(color: AccountStyle.border.opacity(0.6), radius: 0, y: 4)
            .overlay(alignment: .bottomTrailing) {
                if onEditAvatar != nil && !isUploadingAvatar {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AccountStyle.green, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(AccountStyle.cream, lineWidth: 2)
                        }
                        .offset(x: 4, y: 4)
                }
            }

        if let onEditAvatar {
            Button(action: onEditAvatar) {
                baseAvatar
            }
            .buttonStyle(.plain)
            .disabled(isUploadingAvatar)
            .accessibilityLabel("Đổi ảnh đại diện".tr)
        } else {
            baseAvatar
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let userAvatar, !userAvatar.isEmpty {
            CachedAsyncImage(named: userAvatar) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                defaultAvatar
            }
        } else {
            defaultAvatar
        }
    }

    private var defaultAvatar: some View {
        ZStack {
            Color(hex: "E5EBCF")
            Image(systemName: "leaf.fill")
                .font(.system(size: 38))
                .foregroundStyle(AccountStyle.green)
        }
    }

    private func stat(icon: String, title: String, value: Int, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(value.formatted())
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
                Text(title)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(AccountStyle.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProfileCard(userName: "huy quang", userEmail: "huykojo@gmail.com",
                userID: "0tW4PU3U2aMyGEPh8LYFSm0kSp33", userLevel: 52, userLikes: 59, userAvatar: nil)
        .padding()
}

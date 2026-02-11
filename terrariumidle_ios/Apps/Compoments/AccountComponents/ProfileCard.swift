//
//  ProfileCard.swift
//  terrariumidle_ios
//
//  Created by AI on 11/2/26.
//

import SwiftUI

struct ProfileCard: View {
    let userName: String
    let userEmail: String?
    let userID: String
    let userLevel: Int
    let userLikes: Int
    let userAvatar: String?

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            if let avatarURL = userAvatar, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultAvatar
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                defaultAvatar
            }

            // User Info
            VStack(spacing: 8) {
                Text(userName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "envelope")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(userEmail ?? "N.A")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(userID)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Stats
            HStack(spacing: 24) {
                // Level
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                    Text("Level: \(userLevel)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }

                // Likes
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Like: \(userLikes)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundColor(.gray.opacity(0.3))
    }
}

#Preview {
    ProfileCard(
        userName: "Terrarium",
        userEmail: "N.A",
        userID: "pb03Q3R93naRsjjAuyTGzOBPH19",
        userLevel: 129,
        userLikes: 5008,
        userAvatar: nil
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

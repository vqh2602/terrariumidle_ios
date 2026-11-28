import SwiftUI

struct PestAttackSummary: Identifiable, Equatable {
    let id: String
    let senderName: String
    let bug1Count: Int
    let grasshopperCount: Int
}

struct PestAttackModalView: View {
    let summaries: [PestAttackSummary]
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "263C2B").opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture {
                    AudioPlayer.shared.playTap()
                    onDismiss()
                }

            VStack(spacing: 16) {
                headerEmblem

                VStack(spacing: 6) {
                    Text("Khu vườn bị thả sâu!".tr)
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.ink)
                        .multilineTextAlignment(.center)

                    Text("Trong lúc bạn vắng mặt, khu vườn đã bị thả sâu:".tr)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AccountStyle.muted)
                        .multilineTextAlignment(.center)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(summaries) { item in
                            senderRow(item)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: 170)

                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AccountStyle.green)
                    Text("Chạm vào sâu trên cây để bắt (+50 Oxy) hoặc dùng Xịt hóa chất!".tr)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AccountStyle.ink.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AccountStyle.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AccountStyle.green.opacity(0.22), lineWidth: 1)
                }

                Button {
                    AudioPlayer.shared.playTap()
                    onDismiss()
                } label: {
                    Text("Đã hiểu".tr)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(AccountStyle.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "77995C"), AccountStyle.green],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1)
                        }
                        .shadow(color: Color(hex: "354D2C").opacity(0.85), radius: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(AccountStyle.border, lineWidth: 2)
            }
            .shadow(color: Color(hex: "263C2B").opacity(0.28), radius: 20, y: 10)
            .padding(.horizontal, 24)
        }
    }

    private var headerEmblem: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FBE7E1"))
                    .frame(width: 78, height: 78)
                    .overlay {
                        Circle().strokeBorder(Color(hex: "D95D39").opacity(0.35), lineWidth: 2)
                    }
                HStack(spacing: -4) {
                    Image.bundle("bug1@2.083x")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 22)
                        .rotationEffect(.degrees(-10))
                    Image.bundle("grasshopper@2.083x")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 22)
                        .rotationEffect(.degrees(8))
                }
            }

            HStack(spacing: 2) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 8, weight: .bold))
                Text("-70%")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: "B83B2E"), in: Capsule())
            .overlay { Capsule().strokeBorder(AccountStyle.cream, lineWidth: 1.5) }
            .offset(x: 8, y: 2)
        }
    }

    private func senderRow(_ item: PestAttackSummary) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "C07A53"))

            Text(item.senderName)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(AccountStyle.ink)
                .lineLimit(1)

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                if item.bug1Count > 0 {
                    pestCountPill(imageName: "bug1@2.083x", count: item.bug1Count)
                }
                if item.grasshopperCount > 0 {
                    pestCountPill(imageName: "grasshopper@2.083x", count: item.grasshopperCount)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color(hex: "F3F1E2"), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AccountStyle.border.opacity(0.65), lineWidth: 1)
        }
    }

    private func pestCountPill(imageName: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image.bundle(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 14)
            Text("×\(count)")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(AccountStyle.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(AccountStyle.cream, in: Capsule())
        .overlay {
            Capsule().strokeBorder(AccountStyle.border.opacity(0.75), lineWidth: 1)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "8EB5D1").ignoresSafeArea()
        PestAttackModalView(
            summaries: [
                PestAttackSummary(id: "1", senderName: "huy quang", bug1Count: 1, grasshopperCount: 2),
                PestAttackSummary(id: "2", senderName: "Minh Anh", bug1Count: 3, grasshopperCount: 0)
            ],
            onDismiss: {}
        )
    }
}

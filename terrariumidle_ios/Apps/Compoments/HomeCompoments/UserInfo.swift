//
//  UserInfo.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 8/2/26.
//

import SwiftUI

struct UserInfoCompoment: View {
    @State private var isExpanded: Bool = false
    @StateObject var fireStore: FireStoreService = .shared
    @EnvironmentObject var router: AppRouter

    // MARK: - EXP & Level Data
    private var userLevel: Int {
        fireStore.gradenModel?.user.userLevel ?? 1
    }

    private var userExp: Int {
        fireStore.gradenModel?.user.userLevelEXP ?? 0
    }

    private var maxExp: Int {
        max(1, ShareFunc.calculateUserMaxExp(level: userLevel))
    }

    private var expProgress: Double {
        min(max(Double(userExp) / Double(maxExp), 0.0), 1.0)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if isExpanded {
                expandedBarView
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.82, anchor: .topLeading).combined(with: .opacity),
                            removal: .scale(scale: 0.82, anchor: .topLeading).combined(with: .opacity)
                        )
                    )
            } else {
                collapsedCircleView
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.82, anchor: .center).combined(with: .opacity),
                            removal: .scale(scale: 0.82, anchor: .center).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Collapsed View (Mặc định: chỉ có hình tròn với thanh tiến trình % và số level)
    private var collapsedCircleView: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.8)) {
                isExpanded = true
            }
        } label: {
            LevelCircularBadge(level: userLevel, progress: expProgress)
        }
        .buttonStyle(ScaleTouchButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                router.push(.accountView)
            }
        )
    }

    // MARK: - Expanded View (Xổ ra đầy đủ như hình)
    private var expandedBarView: some View {
        HStack(spacing: 8) {
            // Level Card (Tap để thu gọn lại, Long press để xem trang Account)
            Button {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Level: \(userLevel)")
                            .m3TextStyle(.bodyMedium)
                            .fontWeight(.bold)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray.opacity(0.75))
                    }
                    Text("\(formatNumberWithSeparator(userExp)) / \(formatNumberWithSeparator(maxExp))")
                        .font(.system(size: 8, weight: .light, design: .default))
                }
                .foregroundColor(.black)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                .shadow(radius: 6)
            }
            .buttonStyle(ScaleTouchButtonStyle())
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    router.push(.accountView)
                }
            )

            // Resource Bar (Các đơn vị tiền tệ / vật phẩm)
            HStack {
                Button {} label: {
                    HStack(spacing: 0) {
                        Spacer()
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.oxygen ?? 0), image: "oxygen")
                        Spacer()
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.gemstone ?? 0), image: "gemstone")
                        Spacer()
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.item.fertilizer ?? 0), image: "fertilizer")
                        Spacer()
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.item.shovel ?? 0), image: "shovel")
                        Spacer()
                        UserItemData(title: FormatNumber.formatNumber(fireStore.gradenModel?.money.ticket ?? 0), image: "ticket")
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                }
            }
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
            .padding(4)
            .shadow(radius: 6)
        }
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.width < -15 || value.translation.height < -15 {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
                }
        )
    }

    // MARK: - Format helper (dấu chấm ngăn cách phần nghìn: 42.700)
    private func formatNumberWithSeparator(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Circular Level Badge (Hình tròn với thanh tiến trình % level và số level trong cùng)
struct LevelCircularBadge: View {
    let level: Int
    let progress: Double
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            // Nền hình tròn màu trắng có đổ bóng
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)

            // Vòng tròn nền (Track)
            Circle()
                .stroke(Color.gray.opacity(0.18), lineWidth: 3.5)
                .padding(3)

            // Thanh tiến trình (%) level hình tròn
            Circle()
                .trim(from: 0.0, to: CGFloat(max(0.005, min(progress, 1.0))))
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "34D399"), // Mint / emerald
                            Color(hex: "059669")  // Dark emerald
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(3)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: progress)

            // Trong cùng là số level
            Text("\(level)")
                .font(.system(size: level >= 1000 ? 11 : (level >= 100 ? 13 : 15), weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "1F2937"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(6)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
    }
}

// MARK: - Touch Feedback Style
private struct ScaleTouchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Resource Item Display
private struct UserItemData: View {
    let title: String
    let image: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(image)
                .resizable()
                .frame(width: 25, height: 25)
                .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))

            Text(title)
                .textStyle(.caption1)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundColor(.black)
        .padding(0)
    }
}

#Preview("Collapsed (Default)") {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        VStack {
            UserInfoCompoment()
                .padding(.horizontal, 16)
                .padding(.top, 40)
            Spacer()
        }
    }
}

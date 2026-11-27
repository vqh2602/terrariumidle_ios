//
//  AppIconPickerSheet.swift
//  terrariumidle_ios
//

import SwiftUI

struct AppIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var iconManager = AppIconManager.shared

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerBanner

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AppIconOption.allCases) { option in
                            iconCard(for: option)
                        }
                    }

                    Text("Biểu tượng ứng dụng và màn hình khởi động sẽ được đồng bộ theo lựa chọn của bạn.".tr)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(AccountStyle.muted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .background(
                LinearGradient(
                    colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Đổi biểu tượng".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong".tr) {
                        dismiss()
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AccountStyle.green)
                }
            }
            .alert(
                "Không thể đổi biểu tượng".tr,
                isPresented: Binding(
                    get: { iconManager.errorMessage != nil },
                    set: { if !$0 { iconManager.errorMessage = nil } }
                )
            ) {
                Button("Đóng".tr, role: .cancel) {}
            } message: {
                Text(iconManager.errorMessage ?? "")
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 12) {
            Image(iconManager.currentSplashImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AccountStyle.border, lineWidth: 1.5)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Biểu tượng hiện tại".tr)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.muted)
                    VIPCrownBadge(compact: true)
                }
                Text(iconManager.currentIcon.title)
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AccountStyle.ink)
            }

            Spacer()
        }
        .padding(14)
        .modifier(AccountPanel())
    }

    private func iconCard(for option: AppIconOption) -> some View {
        let isSelected = iconManager.currentIcon == option

        return Button {
            Task {
                await iconManager.selectIcon(option)
            }
        } label: {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(option.splashImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    isSelected ? option.accentColor : AccountStyle.border,
                                    lineWidth: isSelected ? 2.5 : 1.5
                                )
                        }
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(option.accentColor)
                            .background(Circle().fill(AccountStyle.cream).padding(2))
                            .offset(x: 6, y: -6)
                    }
                }

                VStack(spacing: 2) {
                    Text(option.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AccountStyle.ink)

                    Text(option.badgeText)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? option.accentColor : AccountStyle.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (isSelected ? option.accentColor : AccountStyle.border).opacity(0.16),
                            in: Capsule()
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(AccountStyle.cream)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        isSelected ? option.accentColor : AccountStyle.border,
                        lineWidth: isSelected ? 2 : 1.5
                    )
            }
            .shadow(color: AccountStyle.border.opacity(0.55), radius: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(iconManager.isUpdating)
    }
}

#Preview {
    AppIconPickerSheet()
}

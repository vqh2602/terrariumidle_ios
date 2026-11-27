//
//  ChangePotSheet.swift
//  terrariumidle_ios
//

import SwiftUI

/// VIP-only sheet allowing the user to replace a planted tree's pot by purchasing a new pot with oxygen.
struct ChangePotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fireStore = FireStoreService.shared

    let plantId: String
    let currentPotId: String
    let isHanging: Bool
    let cartPots: [String]
    let rowIndex: Int
    let columnIndex: Int
    var onPotChanged: (() -> Void)? = nil

    @State private var selectedPotId: String? = nil

    private var isVIP: Bool {
        SubscriptionManager.isVIP(gardenModel: fireStore.gradenModel)
    }

    private var plantIsHanging: Bool {
        ItemDataManager.shared.getPlant(byId: plantId)?.itemTypeAttribute.isHanging ?? isHanging
    }

    private var compatibleOwnedPots: [ItemData] {
        ItemDataManager.shared.getAllPots().filter { pot in
            cartPots.contains(pot.id) && pot.itemTypeAttribute.isHanging == plantIsHanging
        }
    }

    private var recommendedPot: ItemData? {
        ItemDataManager.shared.recommendedPot(for: plantId)
    }

    private var selectedPot: ItemData? {
        guard let selectedPotId else { return nil }
        return ItemDataManager.shared.getPot(byId: selectedPotId)
    }

    private var hasRecommendedPair: Bool {
        guard let selectedPotId else { return false }
        return ItemDataManager.shared.isRecommendedPair(plantId: plantId, potId: selectedPotId)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                infoBanner
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                GardenItemPicker(
                    items: compatibleOwnedPots,
                    placeholder: "Tìm chậu trong kho…".tr,
                    selection: $selectedPotId,
                    onSelect: { _ in },
                    recommendedItemId: recommendedPot?.id,
                    disabledMessages: [currentPotId: "Đang sử dụng".tr]
                )

                if let pot = selectedPot {
                    Divider()
                    confirmButton(for: pot)
                        .padding()
                }
            }
            .background {
                LinearGradient(colors: [Color(hex: "E9EED9"), Color(hex: "F7EEDB")],
                               startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
            .tint(AccountStyle.green)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(AccountStyle.cream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Đổi chậu".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng".tr) {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var infoBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(
                hasRecommendedPair ? "Đã kích hoạt oxygen ×2.5".tr : "Chọn chậu mới cho cây".tr,
                systemImage: hasRecommendedPair ? "checkmark.seal.fill" : "crown.fill"
            )
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(AccountStyle.green)

            Text("Chậu mới sẽ thay thế chậu hiện tại bằng giá mua oxygen. Chậu cũ không được hoàn lại.".tr)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(AccountStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AccountStyle.cream, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AccountStyle.border, lineWidth: 1)
        }
    }

    private func confirmButton(for pot: ItemData) -> some View {
        let cost = pot.priceOxygen
        let currentOxygen = fireStore.gradenModel?.money.oxygen ?? 0
        let hasEnoughOxygen = currentOxygen >= cost

        return Button {
            if hasEnoughOxygen {
                confirmChangePot(to: pot)
            } else {
                dismiss()
            }
        } label: {
            HStack {
                if hasEnoughOxygen {
                    Image("oxygen")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("\(cost)")
                        .fontWeight(.bold)
                    Spacer()
                    Text("Đổi chậu".tr)
                        .fontWeight(.semibold)
                } else {
                    Text("Không đủ oxygen".tr)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(AccountStyle.cream)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(hasEnoughOxygen ? AccountStyle.green : AccountStyle.danger)
            .cornerRadius(12)
        }
    }

    private func confirmChangePot(to pot: ItemData) {
        guard var updatedModel = fireStore.gradenModel else {
            dismiss()
            return
        }
        let position = "\(rowIndex),\(columnIndex)"
        let result = updatedModel.changePot(
            at: position,
            plantId: plantId,
            to: pot.id,
            cost: pot.priceOxygen,
            isVIP: isVIP
        )
        guard result == .changed else {
            dismiss()
            return
        }

        AudioPlayer.shared.playSFX(fileName: "mixkit-silly-pop-cluster-2359", ext: "wav")
        fireStore.saveGarden(gardenModel: updatedModel, debounce: false)
        onPotChanged?()
        dismiss()
    }
}

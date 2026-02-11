import SwiftUI

/// Button for unlocking new floors in edit mode
struct UnlockFloorButton: View {
    let currentFloor: Int
    let cost: Int
    let maxFloors: Int
    let onUnlock: () -> Void

    @State var fireStoreService: FireStoreService = .shared

    var hasEnoughOxygen: Bool {
        (fireStoreService.gradenModel?.money.oxygen ?? 0) >= cost
    }

    var canUnlock: Bool {
        currentFloor < maxFloors
    }

    var requiredLevel: Int {
        (currentFloor + 1) * 5
    }

    var body: some View {
        Button(action: {
            if canUnlock, hasEnoughOxygen {
                onUnlock()
            }
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: canUnlock ? "lock.open.fill" : "lock.fill")
                        .textStyle(.title2)
                    Text("Mở khóa tầng \(currentFloor + 1)")
                        .textStyle(.title2)
                }
                .foregroundColor(canUnlock && hasEnoughOxygen ? .green : canUnlock ? .orange : .gray)

                if canUnlock {
                    HStack(spacing: 4) {
                        Text("\(cost)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("💨")
                            .font(.title3)
                    }
                    .foregroundColor(hasEnoughOxygen ? .green : .red)

                    if !hasEnoughOxygen {
                        let deficit = cost - (fireStoreService.gradenModel?.money.oxygen ?? 0)
                        Text("(Thiếu \(deficit) oxygen)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Yêu cầu level \(requiredLevel)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        canUnlock && hasEnoughOxygen ? Color.green :
                            canUnlock ? Color.orange : Color.gray,
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
            )
        }
        .disabled(!canUnlock || !hasEnoughOxygen)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

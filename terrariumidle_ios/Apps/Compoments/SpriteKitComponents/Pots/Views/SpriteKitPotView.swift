//
//  SpriteKitPotView.swift
//  terrariumidle_ios
//
//  Created by AI on 18/11/26.
//

import SpriteKit
import SwiftUI

/// Typealias ngắn gọn để tái sử dụng thuận tiện ở các nơi
public typealias PotView = SpriteKitPotView

// MARK: - Pot Default Dimensions & Presets
public enum PotDefaults {
    /// Độ giãn nở chiều rộng mặc định cho các chậu có dáng dọc cao (tall / upright pots)
    public static func defaultWidthFill(for potId: String) -> CGFloat {
        let cleanId = potId.lowercased().trimmingCharacters(in: .whitespaces)
        switch cleanId {
        case "pot13":
            return 0.67
        case "pot11":
            return 0.30
        case "pot8":
            return 0.25
        case "pot12":
            return 0.25
        case "pot10":
            return 0.20
        default:
            return 0.0
        }
    }
}

/// SwiftUI Component hiển thị chậu cây bằng SpriteKit
/// - Đổ bóng tự nhiên dưới đáy
/// - Phản hồi nảy đàn hồi (spring bounce) khi chạm vào
/// - Hỗ trợ cả chậu đứng trên kệ và chậu treo móc
public struct SpriteKitPotView: View {
    public var potId: String = "pot1"
    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    /// Độ giãn phủ chiều rộng (0.0 = giữ aspect ratio tự nhiên, 1.0 = fill tối đa chiều rộng container)
    public var widthFill: CGFloat? = nil
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill ?? effectiveWidthFill }
        set { widthFill = newValue }
    }

    /// Tính toán widthFill hiệu dụng: ưu tiên caller truyền vào > cấu hình trong pots_data.json > PotDefaults
    public var effectiveWidthFill: CGFloat {
        if let explicit = widthFill {
            return min(max(explicit, 0.0), 1.0)
        }
        if let dataFill = ItemDataManager.shared.getPot(byId: potId)?.widthFill {
            return CGFloat(min(max(dataFill, 0.0), 1.0))
        }
        return PotDefaults.defaultWidthFill(for: potId)
    }

    @State private var scene: SpriteKitPotScene

    public init(
        potId: String = "pot1",
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 80,
        widthFill: CGFloat? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.widthFill = widthFill
        self.onTap = onTap

        let cleanFill: CGFloat
        if let explicit = widthFill {
            cleanFill = min(max(explicit, 0.0), 1.0)
        } else if let df = ItemDataManager.shared.getPot(byId: potId)?.widthFill {
            cleanFill = CGFloat(min(max(df, 0.0), 1.0))
        } else {
            cleanFill = PotDefaults.defaultWidthFill(for: potId)
        }

        let initialScene = Self.makeScene(potId: potId, isHanging: isHanging, width: width, height: height, widthFill: cleanFill)
        _scene = State(initialValue: initialScene)
    }

    public var body: some View {
        let activeFill = effectiveWidthFill
        let currentScene = scene
        currentScene.configure(potId: potId, isHanging: isHanging, widthFill: activeFill)

        return SpriteView(scene: currentScene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .background(Color.clear)
            .contentShape(Rectangle())
            .id("\(potId)-\(isHanging)-\(activeFill)-\(width)-\(height)")
            .onAppear {
                currentScene.configure(potId: potId, isHanging: isHanging, widthFill: activeFill)
            }
            .onTapGesture {
                currentScene.playTapAnimation()
                let soundName = ItemDataManager.shared.getPot(byId: potId)?.clickSound ?? "tap"
                AudioPlayer.shared.playClickSound(named: soundName)
                onTap?()
            }
            .onChange(of: potId) { newId in
                currentScene.configure(potId: newId, isHanging: isHanging, widthFill: activeFill)
            }
            .onChange(of: isHanging) { newHanging in
                currentScene.configure(potId: potId, isHanging: newHanging, widthFill: activeFill)
            }
            .onChange(of: activeFill) { newFill in
                currentScene.configure(potId: potId, isHanging: isHanging, widthFill: newFill)
            }
    }

    private static func makeScene(potId: String, isHanging: Bool, width: CGFloat, height: CGFloat, widthFill: CGFloat = 0.0) -> SpriteKitPotScene {
        let newScene = SpriteKitPotScene(size: CGSize(width: width, height: height))
        newScene.configure(potId: potId, isHanging: isHanging, widthFill: widthFill)
        return newScene
    }
}

// MARK: - Preview Chậu cây SpriteKit
private struct SpriteKitPotInteractiveDemoView: View {
    @State private var selectedPotId: String = "pot10"
    @State private var isHanging: Bool = false
    @State private var widthFill: CGFloat = 0.0
    @State private var tapCount: Int = 0

    private let potIds = ["pot1", "pot2", "pot3", "pot4", "pot5", "pot6", "pot7", "pot8", "pot9", "pot10", "pot11", "pot12", "pot13", "pot14"]

    var body: some View {
        VStack(spacing: 20) {
            Text("🪴 SpriteKit Pot View Demo")
                .font(.headline)

            Picker("Chọn chậu", selection: $selectedPotId) {
                ForEach(potIds, id: \.self) { id in
                    Text(id.uppercased()).tag(id)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ZStack(alignment: isHanging ? .top : .bottom) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                PotView(
                    potId: selectedPotId,
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 110,
                    widthFill: widthFill,
                    onTap: {
                        tapCount += 1
                    }
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
                .id("\(selectedPotId)-\(isHanging)-\(widthFill)")
            }

            VStack(spacing: 6) {
                HStack {
                    Text("Độ rộng (widthFill):")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(widthFill * 100))%")
                        .font(.caption).bold()
                }
                Slider(value: $widthFill, in: 0.0...1.0, step: 0.05)
            }
            .padding(.horizontal, 30)

            Text("Số lần chạm: \(tapCount)")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle("Chậu treo (isHanging)", isOn: $isHanging)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    SpriteKitPotInteractiveDemoView()
}

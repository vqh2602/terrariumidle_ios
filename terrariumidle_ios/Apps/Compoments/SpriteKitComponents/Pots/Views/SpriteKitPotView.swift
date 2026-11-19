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
    public var widthFill: CGFloat = 0.0
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {
        get { widthFill }
        set { widthFill = newValue }
    }

    @State private var scene: SpriteKitPotScene

    public init(
        potId: String = "pot1",
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 80,
        widthFill: CGFloat = 0.0,
        onTap: (() -> Void)? = nil
    ) {
        self.potId = potId
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        self.onTap = onTap

        let initialScene = Self.makeScene(potId: potId, isHanging: isHanging, width: width, height: height, widthFill: widthFill)
        _scene = State(initialValue: initialScene)
    }

    public var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: width, height: height)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onAppear {
                scene.configure(potId: potId, isHanging: isHanging, widthFill: widthFill)
            }
            .onTapGesture {
                scene.playTapAnimation()
                let soundName = ItemDataManager.shared.getPot(byId: potId)?.clickSound ?? "tap"
                AudioPlayer.shared.playClickSound(named: soundName)
                onTap?()
            }
            .onChange(of: potId) { newId in
                scene.configure(potId: newId, isHanging: isHanging, widthFill: widthFill)
            }
            .onChange(of: isHanging) { newHanging in
                scene.configure(potId: potId, isHanging: newHanging, widthFill: widthFill)
            }
            .onChange(of: widthFill) { newFill in
                scene.configure(potId: potId, isHanging: isHanging, widthFill: newFill)
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

#!/usr/bin/env python3
import os

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
POTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots")

POTS_CONFIG = [
    {
        "id": 20,
        "name": "Chậu gỗ xoan",
        "tagline": "Chậu gỗ xoan vân nâu ấm áp 🪵",
        "w": 242.0,
        "h": 233.0,
        "mount_y": 192.0,
        "bottom_ratio": 0.44,
        "width_fill": 0.0,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[WoodPollenEffect()]",
        "primary_texture": "Pot20-1@4.167x",
        "candidates": ["Pot20-1@4.167x", "pot20-1@4.167x", "pot20_Asset-1@4.167x", "pot20"],
    },
    {
        "id": 21,
        "name": "Chậu đá hoa cương Safe",
        "tagline": "Chậu đá hoa cương vân xám vững chãi 🪨",
        "w": 277.0,
        "h": 267.0,
        "mount_y": 224.0,
        "bottom_ratio": 0.47,
        "width_fill": 0.0,
        "motion": "FirmBounceMotionEffect()",
        "tap_effects": "[StoneDustEffect()]",
        "primary_texture": "Pot21-1@4.167x",
        "candidates": ["Pot21-1@4.167x", "pot21-1@4.167x", "pot21_Asset-1@4.167x", "pot21"],
    },
    {
        "id": 22,
        "name": "Chậu đất nung có đế",
        "tagline": "Chậu đất nung truyền thống kèm chân đế 🏺",
        "w": 335.0,
        "h": 290.0,
        "mount_y": 230.0,
        "bottom_ratio": 0.79,
        "width_fill": 0.0,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[ClayGlintEffect()]",
        "primary_texture": "Pot22-1@4.167x",
        "candidates": ["Pot22-1@4.167x", "pot22-1@4.167x", "pot22_Asset-1@4.167x", "pot22"],
    },
    {
        "id": 23,
        "name": "Chậu sa thạch be sữa",
        "tagline": "Chậu sa thạch màu be sữa thanh lịch 🌾",
        "w": 321.0,
        "h": 325.0,
        "mount_y": 264.0,
        "bottom_ratio": 0.40,
        "width_fill": 0.0,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[EarthenParticlesEffect()]",
        "primary_texture": "Pot23-1@4.167x",
        "candidates": ["Pot23-1@4.167x", "pot23-1@4.167x", "pot23_Asset-1@4.167x", "pot23"],
    },
    {
        "id": 24,
        "name": "Chậu gốm nâu đỏ Salix",
        "tagline": "Chậu gốm đất nung màu nâu đỏ trầm ấm 🍂",
        "w": 403.0,
        "h": 354.0,
        "mount_y": 318.0,
        "bottom_ratio": 0.48,
        "width_fill": 0.0,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[ClayGlintEffect()]",
        "primary_texture": "Pot24-2@4.167x",
        "candidates": ["Pot24-2@4.167x", "pot24-2@4.167x", "pot24_Asset-1@4.167x", "pot24"],
    },
    {
        "id": 25,
        "name": "Chậu vẽ tay họa tiết vàng",
        "tagline": "Chậu vẽ tay thủ công hoàng kim tinh xảo ✨",
        "w": 439.0,
        "h": 537.0,
        "mount_y": 483.0,
        "bottom_ratio": 0.29,
        "width_fill": 0.15,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[GoldGlintEffect()]",
        "primary_texture": "Pot25-13@4.167x",
        "candidates": ["Pot25-13@4.167x", "pot25-13@4.167x", "pot25_Asset-1@4.167x", "pot25"],
    },
    {
        "id": 26,
        "name": "Chậu đá đa giác phấn hồng",
        "tagline": "Chậu đá cắt vát đa giác bệ đá đen hiện đại 💎",
        "w": 304.0,
        "h": 327.0,
        "mount_y": 294.0,
        "bottom_ratio": 0.86,
        "width_fill": 0.0,
        "motion": "FirmBounceMotionEffect()",
        "tap_effects": "[QuartzBurstEffect()]",
        "primary_texture": "Pot26-1@4.167x",
        "candidates": ["Pot26-1@4.167x", "pot26-1@4.167x", "pot26_Asset-1@4.167x", "pot26"],
    },
    {
        "id": 27,
        "name": "Chậu sứ trắng ngà dáng cao",
        "tagline": "Chậu sứ trắng ngà dáng cao thanh thoát 🤍",
        "w": 226.0,
        "h": 306.0,
        "mount_y": 259.0,
        "bottom_ratio": 0.53,
        "width_fill": 0.20,
        "motion": "FirmBounceMotionEffect()",
        "tap_effects": "[SparkleBurstEffect()]",
        "primary_texture": "Pot27-1@4.167x",
        "candidates": ["Pot27-1@4.167x", "pot27-1@4.167x", "pot27_Asset-1@4.167x", "pot27"],
    },
    {
        "id": 28,
        "name": "Chậu ngọc bích băng tuyết",
        "tagline": "Chậu ngọc bích băng tuyết thuần khiết mát lạnh ❄️",
        "w": 1600.0,
        "h": 1509.0,
        "mount_y": 1358.0,
        "bottom_ratio": 0.45,
        "width_fill": 0.0,
        "motion": "FirmBounceMotionEffect()",
        "tap_effects": "[EmeraldJadeEffect()]",
        "primary_texture": "Pot28-1@4.167x",
        "candidates": ["Pot28-1@4.167x", "pot28-1@4.167x", "pot28_Asset-1@4.167x", "pot28"],
    },
    {
        "id": 29,
        "name": "Bình gốm san hô cổ cao",
        "tagline": "Bình gốm cổ thon cao màu hồng san hô dịu dàng 🪸",
        "w": 498.0,
        "h": 724.0,
        "mount_y": 651.0,
        "bottom_ratio": 0.35,
        "width_fill": 0.25,
        "motion": "StandardBounceMotionEffect()",
        "tap_effects": "[CoralBubbleEffect()]",
        "primary_texture": "Pot29@4.167x",
        "candidates": ["Pot29@4.167x", "pot29@4.167x", "pot29_Asset-1@4.167x", "pot29"],
    },
    {
        "id": 30,
        "name": "Chậu ống tre mộc nâu sẫm",
        "tagline": "Chậu ống trụ thon dài tối giản thiền tịnh 🎋",
        "w": 153.0,
        "h": 360.0,
        "mount_y": 324.0,
        "bottom_ratio": 0.59,
        "width_fill": 0.35,
        "motion": "FirmBounceMotionEffect()",
        "tap_effects": "[BambooMistEffect()]",
        "primary_texture": "Pot30-1@4.167x",
        "candidates": ["Pot30-1@4.167x", "pot30-1@4.167x", "pot30_Asset-1@4.167x", "pot30"],
    },
]

def generate_node(cfg):
    pid = cfg["id"]
    name = cfg["name"]
    w = cfg["w"]
    h = cfg["h"]
    bottom_ratio = cfg["bottom_ratio"]
    motion = cfg["motion"]
    tap_effects = cfg["tap_effects"]
    cand_str = ",\n            ".join([f'"{c}"' for c in cfg["candidates"]])

    return f"""//
//  Pot{pid}Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

/// Node SpriteKit chuyên biệt cho Chậu {pid}: "{name}" (pot{pid})
/// - Hỗ trợ Kiến trúc Lai (Hybrid Visual Architecture): Nạp từ `Pot{pid}Scene.sks` nếu có
/// - Kích thước chuẩn: ({w} x {h})
/// - Đổ bóng mềm mại phía dưới đáy chậu (tỉ lệ tiếp xúc đáy ~{int(bottom_ratio * 100)}%)
public final class Pot{pid}Node: SKNode, PotInteractiveNode {{

    // MARK: - Properties

    private var containerSize: CGSize = .zero
    private var isHanging: Bool = false
    private var widthFill: CGFloat = Pot{pid}View.defaultWidthFill

    /// Gốc rễ chậu và hiệu ứng
    private let potRootNode = SKNode()
    /// Sprite hiển thị chậu cây
    private var potNode: SKSpriteNode?
    /// Bóng đổ dưới đáy chậu
    private var shadowNode: SKNode?
    /// Socket cắm cây
    public private(set) var plantMountNode: SKNode?

    /// Toạ độ ban đầu của chậu (chống trôi toạ độ khi tap liên tục)
    private var initialPotPosition: CGPoint = .zero
    /// Tỉ lệ scale cơ sở
    private var baseScale: CGFloat = 1.0

    /// Hiệu ứng chuyển động rung / nảy / đu đưa khi tap vào chậu
    public var motionEffect: PotMotionEffect = {motion}

    /// Danh sách hiệu ứng thị giác khi tap vào chậu
    public var tapEffects: [PotTapEffect] = {tap_effects}

    // MARK: - Initializer

    public init(containerSize: CGSize = CGSize(width: 120, height: 95), isHanging: Bool = false, widthFill: CGFloat = Pot{pid}View.defaultWidthFill) {{
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        super.init()

        addChild(potRootNode)
        build()
    }}

    public required init?(coder aDecoder: NSCoder) {{
        super.init(coder: aDecoder)
        addChild(potRootNode)
    }}

    // MARK: - Configuration

    public func configure(containerSize: CGSize, isHanging: Bool = false, widthFill: CGFloat = Pot{pid}View.defaultWidthFill) {{
        self.containerSize = containerSize
        self.isHanging = isHanging
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        build()
    }}

    // MARK: - Build Scene

    public func build() {{
        potRootNode.removeAllChildren()
        potRootNode.removeAllActions()
        potNode = nil
        shadowNode = nil
        plantMountNode = nil

        self.isPaused = false
        self.speed = 1.0
        potRootNode.isPaused = false
        potRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else {{ return }}

        let aspect: CGFloat = {h} / {w}
        let targetH = containerSize.height * 0.98
        let naturalW = targetH / aspect
        let maxW = max(naturalW, containerSize.width * 0.96)
        let targetW = naturalW + (maxW - naturalW) * widthFill

        // 1. Bóng đổ dưới đáy chậu (nếu không phải chậu treo)
        if !isHanging {{
            let baseContactW = targetW * {bottom_ratio}
            let shadowW = max(28.0, baseContactW * 1.12)
            let shadowH = max(5.0, min(10.0, shadowW * 0.16))
            let shadowTex = SpriteKitPotScene.createSoftShadowTexture(width: shadowW, height: shadowH)
            let shadow = SKSpriteNode(texture: shadowTex, size: CGSize(width: shadowW, height: shadowH))
            shadow.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            shadow.position = CGPoint(x: 0, y: shadowH * 0.35)
            shadow.zPosition = 1
            potRootNode.addChild(shadow)
            self.shadowNode = shadow
        }}

        // 2. ƯU TIÊN KIẾN TRÚC LAI: Nạp node từ file trực quan Pot{pid}Scene.sks nếu có
        if let scene = loadSceneTemplate(),
           let templatePot = scene.childNode(withName: "potNode") as? SKSpriteNode,
           templatePot.texture != nil {{
            templatePot.removeFromParent()
            templatePot.isHidden = false
            templatePot.isPaused = false
            templatePot.speed = 1.0
            templatePot.size = CGSize(width: targetW, height: targetH)
            templatePot.anchorPoint = CGPoint(x: 0.5, y: isHanging ? 1.0 : 0.0)
            templatePot.position = CGPoint(x: 0, y: 0)
            templatePot.zPosition = 50
            potRootNode.addChild(templatePot)
            self.potNode = templatePot
            self.initialPotPosition = templatePot.position

            // Nạp socket cắm cây từ scene Pot{pid}Scene.sks
            if let mount = scene.childNode(withName: "plantMount") {{
                mount.removeFromParent()
                mount.isHidden = false
                mount.isPaused = false
                let scaleX = targetW / {w}
                let scaleY = targetH / {h}
                mount.position = CGPoint(x: mount.position.x * scaleX, y: mount.position.y * scaleY)
                mount.zPosition = 10
                potRootNode.addChild(mount)
                self.plantMountNode = mount
            }}
            return
        }}

        // 3. Fallback nạp texture ảnh pot{pid}
        guard let texture = loadPot{pid}Texture() else {{ return }}

        let node = SKSpriteNode(texture: texture)
        node.name = "potNode"
        node.size = CGSize(width: targetW, height: targetH)
        node.zPosition = 50
        node.isPaused = false
        node.speed = 1.0

        if isHanging {{
            node.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            node.position = CGPoint(x: 0, y: 0)
        }} else {{
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: 0, y: 0)
        }}

        potRootNode.addChild(node)
        self.potNode = node
        self.initialPotPosition = node.position

        // Socket cắm cây mặc định nếu chưa nạp được scene
        let mount = SKNode()
        mount.name = "plantMount"
        mount.position = CGPoint(x: 0, y: isHanging ? -targetH * 0.65 : targetH * 0.88)
        mount.zPosition = 10
        potRootNode.addChild(mount)
        self.plantMountNode = mount
    }}

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {{
        if let scene = SKScene(fileNamed: "Pot{pid}Scene") {{
            return scene
        }}
        return nil
    }}

    // MARK: - Texture Loader

    private func loadPot{pid}Texture() -> SKTexture? {{
        let candidates = [
            {cand_str}
        ]

        for name in candidates {{
            if let img = UIImage(named: name) {{
                return SKTexture(image: img)
            }}
        }}

        return SpriteKitPotScene.generateProceduralPotTexture(potId: "pot{pid}", isHanging: isHanging).texture
    }}

    // MARK: - Phản hồi tương tác Tap (Motion & Visual Tap Animation)

    public func playTapAnimation() {{
        guard let node = potNode else {{ return }}

        // 1. Kích hoạt hiệu ứng chuyển động rung/nảy
        motionEffect.apply(
            targetNode: node,
            potNode: node,
            shadowNode: shadowNode,
            initialPosition: initialPotPosition,
            isHanging: isHanging
        )

        // 2. Kích hoạt toàn bộ danh sách hiệu ứng tap đã khai báo
        for effect in tapEffects {{
            effect.trigger(on: node, in: potRootNode, isHanging: isHanging)
        }}
    }}
}}
"""

def generate_view(cfg):
    pid = cfg["id"]
    name = cfg["name"]
    tagline = cfg["tagline"]
    width_fill = cfg["width_fill"]

    return f"""//
//  Pot{pid}View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho Chậu {pid}: "{name}" (pot{pid})
public struct Pot{pid}View: View {{
    /// Độ giãn phủ chiều rộng mặc định của Chậu {pid} (0.0 -> 1.0)
    public static var defaultWidthFill: CGFloat = {width_fill}

    public var isHanging: Bool = false
    public var width: CGFloat
    public var height: CGFloat
    public var widthFill: CGFloat = Pot{pid}View.defaultWidthFill
    public var onTap: (() -> Void)? = nil

    /// Bí danh (alias) tương thích cho thuộc tính widthFill
    public var fillWidth: CGFloat {{
        get {{ widthFill }}
        set {{ widthFill = newValue }}
    }}

    public init(
        isHanging: Bool = false,
        width: CGFloat = 120,
        height: CGFloat = 95,
        widthFill: CGFloat = Pot{pid}View.defaultWidthFill,
        onTap: (() -> Void)? = nil
    ) {{
        self.isHanging = isHanging
        self.width = width
        self.height = height
        self.widthFill = min(max(widthFill, 0.0), 1.0)
        self.onTap = onTap
    }}

    public var body: some View {{
        PotView(
            potId: "pot{pid}",
            isHanging: isHanging,
            width: width,
            height: height,
            widthFill: widthFill,
            onTap: onTap
        )
        .id("pot{pid}-\\(isHanging)-\\(widthFill)-\\(width)-\\(height)")
    }}
}}

// MARK: - Interactive Preview Struct
private struct Pot{pid}InteractiveDemoView: View {{
    @State private var isHanging: Bool = false
    @State private var widthFill: CGFloat = Pot{pid}View.defaultWidthFill
    @State private var tapCount: Int = 0

    var body: some View {{
        VStack(spacing: 24) {{
            Text("🪴 Demo Pot {pid} SpriteKit")
                .font(.title2).bold()

            Text("{tagline}")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ZStack(alignment: isHanging ? .top : .bottom) {{
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 180)

                Pot{pid}View(
                    isHanging: isHanging,
                    width: isHanging ? 150 : 160,
                    height: isHanging ? 150 : 120,
                    widthFill: widthFill,
                    onTap: {{
                        tapCount += 1
                    }}
                )
                .padding(.top, isHanging ? 16 : 0)
                .padding(.bottom, isHanging ? 0 : 20)
                .id("\\(isHanging)-\\(widthFill)")
            }}

            VStack(spacing: 6) {{
                HStack {{
                    Text("Độ rộng (widthFill):")
                        .font(.caption)
                    Spacer()
                    Text("\\(Int(widthFill * 100))%")
                        .font(.caption).bold()
                }}
                Slider(value: $widthFill, in: 0.0...1.0, step: 0.05)
            }}
            .padding(.horizontal, 30)

            Text("Đã chạm: \\(tapCount) lần")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {{
                widthFill = Pot{pid}View.defaultWidthFill
            }}) {{
                Text("Đặt lại độ rộng mặc định")
                    .font(.caption)
            }}
            .buttonStyle(.bordered)
        }}
        .padding()
    }}
}}

#Preview {{
    Pot{pid}InteractiveDemoView()
}}
"""

def main():
    print("🚀 Generating Pot20..Pot30 Node & View Swift files...")
    for cfg in POTS_CONFIG:
        pid = cfg["id"]
        out_dir = os.path.join(POTS_DIR, f"Pot{pid}")
        os.makedirs(out_dir, exist_ok=True)

        node_path = os.path.join(out_dir, f"Pot{pid}Node.swift")
        view_path = os.path.join(out_dir, f"Pot{pid}View.swift")

        with open(node_path, "w", encoding="utf-8") as f:
            f.write(generate_node(cfg))
        with open(view_path, "w", encoding="utf-8") as f:
            f.write(generate_view(cfg))

        print(f"✅ Generated Pot{pid}Node.swift & Pot{pid}View.swift")
    print("🎉 All Swift files generated successfully!")

if __name__ == "__main__":
    main()

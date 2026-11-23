#!/usr/bin/env python3
"""
Script tự động sinh trọn bộ SpriteKit Visual Scene (.sks), Code Logic Node (.swift),
và SwiftUI Preview View (.swift) cho Plant20 -> Plant30 trong Terrarium Idle iOS
dựa trên dữ liệu bóc tách từ file SVG và assets xcassets.
"""

import os
import re
import glob
import copy
import struct
import plistlib
import xml.etree.ElementTree as ET

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant14/Plant14Scene.sks")
COMPONENTS_PLANTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants")
ASSETS_PLANTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Assets.xcassets/Plants")
RESOURCES_SVG_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Resources/SVGPlants")

def get_png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
        if head.startswith(b"\x89PNG\r\n\x1a\n"):
            return struct.unpack(">II", head[16:24])
    return None

def get_child_bbox_and_anchor(elem):
    paths = elem.findall(".//{http://www.w3.org/2000/svg}path") + ([elem] if elem.tag.endswith("path") else [])
    polys = elem.findall(".//{http://www.w3.org/2000/svg}polygon") + ([elem] if elem.tag.endswith("polygon") else [])
    all_x, all_y = [], []
    for p in paths:
        d = p.attrib.get("d", "")
        coords = [float(x) for x in re.findall(r"[-+]?[0-9]*\.?[0-9]+", d)]
        for i in range(0, len(coords)-1, 2):
            all_x.append(coords[i])
            all_y.append(coords[i+1])
    for p in polys:
        pts = [float(x) for x in re.findall(r"[-+]?[0-9]*\.?[0-9]+", p.attrib.get("points", ""))]
        for i in range(0, len(pts)-1, 2):
            all_x.append(pts[i])
            all_y.append(pts[i+1])
    if not all_x:
        return None
    min_x, max_x = min(all_x), max(all_x)
    min_y, max_y = min(all_y), max(all_y)
    w = max_x - min_x
    h = max_y - min_y
    # Bottom points
    bottom_pts = [x for x, y in zip(all_x, all_y) if y >= max_y - max(2.0, h * 0.08)]
    if bottom_pts and w > 0:
        avg_bx = sum(bottom_pts) / len(bottom_pts)
        ax = (avg_bx - min_x) / w
    else:
        ax = 0.5
    ax = max(0.05, min(0.95, ax))
    return {
        "min_x": min_x, "min_y": min_y,
        "max_x": max_x, "max_y": max_y,
        "w": w, "h": h,
        "ax": ax, "ay": 0.0
    }

PLANTS_CONFIG = {
    20: {
        "name_vn": "Xương rồng nhím",
        "botanical": "Echinocactus",
        "svg": "plant20-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "ElasticPulseMotionEffect(pulseScale: 1.05, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .emerald)]",
        "idle_style": "breathe", # pulse scale
    },
    21: {
        "name_vn": "Sen bạch liên",
        "botanical": "Nelumbo nucifera",
        "svg": "plant21-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "WindSwayMotionEffect(swayAngle: 0.040, leafBendAngle: 0.08, durationMultiplier: 1.0)",
        "tap_effects": "[FloatingPetalsEffect(), OxygenBubblesEffect(theme: .deepOcean)]",
        "idle_style": "wind",
    },
    22: {
        "name_vn": "Thất mạt hương",
        "botanical": "Plectranthus hadiensis",
        "svg": "plant22-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "WindSwayMotionEffect(swayAngle: 0.035, leafBendAngle: 0.075, durationMultiplier: 0.95)",
        "tap_effects": "[SparklePollenEffect(), OxygenBubblesEffect(theme: .emerald)]",
        "idle_style": "wind",
    },
    23: {
        "name_vn": "Sen đá đinh",
        "botanical": "Sedum clavatum",
        "svg": "plant23-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": True,
        "motion_effect": "CascadingVineMotionEffect(waveAngle: 0.08, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .emerald)]",
        "idle_style": "cascade",
    },
    24: {
        "name_vn": "Hoa đào",
        "botanical": "Prunus persica",
        "svg": "plant24-3.svg",
        "start_aid": 4,
        "composite_aid": 3,
        "hanging": False,
        "motion_effect": "WindSwayMotionEffect(swayAngle: 0.045, leafBendAngle: 0.09, durationMultiplier: 1.1)",
        "tap_effects": "[FloatingPetalsEffect(), OxygenBubblesEffect(theme: .floralPink)]",
        "idle_style": "wind",
    },
    25: {
        "name_vn": "Xương rồng thùng hồng",
        "botanical": "Echinocactus grusonii",
        "svg": "plant25-1.svg",
        "start_aid": 2,
        "composite_aid": 1,
        "hanging": False,
        "motion_effect": "ElasticPulseMotionEffect(pulseScale: 1.06, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .floralPink)]",
        "idle_style": "breathe",
    },
    26: {
        "name_vn": "Trúc tiểu cảnh",
        "botanical": "Phyllostachys aurea",
        "svg": "plant26-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "WindSwayMotionEffect(swayAngle: 0.038, leafBendAngle: 0.07, durationMultiplier: 1.0)",
        "tap_effects": "[SparklePollenEffect(), OxygenBubblesEffect(theme: .emerald)]",
        "idle_style": "wind",
    },
    27: {
        "name_vn": "Xương rồng cột Andes",
        "botanical": "Oreocereus celsianus",
        "svg": "plant27-2.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "StandardPlantBounceMotionEffect(bounceIntensity: 0.7, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .goldenSun)]",
        "idle_style": "standard",
    },
    28: {
        "name_vn": "Xương rồng myrtle xanh",
        "botanical": "Myrtillocactus geometrizans",
        "svg": "plant28.svg",
        "start_aid": 2,
        "composite_aid": 1, # plant28-1@4.167x contains plant28-32@4.167x.png
        "hanging": False,
        "motion_effect": "StandardPlantBounceMotionEffect(bounceIntensity: 0.6, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .deepOcean)]",
        "idle_style": "standard",
    },
    29: {
        "name_vn": "Xương rồng trụ xoắn",
        "botanical": "Cereus forbesii spiralis",
        "svg": "plant29-1.svg",
        "start_aid": 2,
        "composite_aid": 1,
        "hanging": False,
        "motion_effect": "ElasticPulseMotionEffect(pulseScale: 1.04, durationMultiplier: 1.0)",
        "tap_effects": "[OxygenBubblesEffect(theme: .goldenSun)]",
        "idle_style": "breathe",
    },
    30: {
        "name_vn": "Hoa lan chuông trắng",
        "botanical": "Convallaria majalis",
        "svg": "plant30.svg",
        "start_aid": 3,
        "composite_aid": 2,
        "hanging": False,
        "motion_effect": "CascadingVineMotionEffect(waveAngle: 0.09, durationMultiplier: 1.0)",
        "tap_effects": "[SparklePollenEffect(), OxygenBubblesEffect(theme: .deepOcean)]",
        "idle_style": "cascade",
    },
}

def parse_plant(pid):
    cfg = PLANTS_CONFIG[pid]
    sname = cfg["svg"]
    spath = os.path.join(RESOURCES_SVG_DIR, sname)
    tree = ET.parse(spath)
    root = tree.getroot()

    vb = root.get("viewBox")
    vb_parts = [float(x) for x in vb.split()] if vb else [0, 0, float(root.get("width")), float(root.get("height"))]
    svg_w, svg_h = vb_parts[2], vb_parts[3]

    obj = root.find(".//{http://www.w3.org/2000/svg}g[@id=\"OBJECTS\"]") or \
          root.find(".//{http://www.w3.org/2000/svg}g[@id=\"Layer_1\"]") or \
          root.find(".//{http://www.w3.org/2000/svg}g[@id=\"DESIGNED_BY_FREEPIK\"]") or root
    curr = obj
    while curr is not None and len(curr) == 1 and curr[0].tag.endswith("g"):
        curr = curr[0]

    png_dir = os.path.join(ASSETS_PLANTS_DIR, f"plant{pid}")
    comp_aid = cfg["composite_aid"]
    comp_png = glob.glob(f"{png_dir}/*plant{pid}-{comp_aid}@*/*.png")
    if not comp_png:
        comp_png = glob.glob(f"{png_dir}/plant{pid}-1@*/*.png")
    comp_w, comp_h = get_png_size(comp_png[0])
    scale = comp_w / svg_w

    leaves = []
    start_aid = cfg["start_aid"]
    for i, c in enumerate(curr):
        bb = get_child_bbox_and_anchor(c)
        if not bb:
            continue
        aid = start_aid + i
        png_p = glob.glob(f"{png_dir}/plant{pid}-{aid}@*/*.png")
        if png_p:
            pw, ph = get_png_size(png_p[0])
        else:
            pw, ph = round(bb["w"] * scale), round(bb["h"] * scale)

        ix = bb["min_x"] * scale
        iy = bb["min_y"] * scale
        ax = bb["ax"]
        ay = bb["ay"]

        # SpriteKit Bottom-Center coordinates
        sk_x = round((ix + ax * pw) - (comp_w / 2.0), 1)
        sk_y = round(comp_h - iy - (1.0 - ay) * ph - 10.0, 1)

        is_left = (ix + pw / 2.0) < (comp_w / 2.0)
        z_pos = 11 + i

        # Calculate bend angle & duration
        bend = 0.035 if is_left else -0.035
        dur = 3.0 + (i % 4) * 0.35

        leaves.append({
            "asset_id": aid,
            "img_name": f"plant{pid}-{aid}@4.167x",
            "w": float(pw),
            "h": float(ph),
            "ax": round(ax, 2),
            "ay": round(ay, 2),
            "sk_x": sk_x,
            "sk_y": sk_y,
            "z_pos": float(z_pos),
            "is_left": is_left,
            "bend": round(bend, 3),
            "dur": round(dur, 2),
            "should_sway": True,
        })

    return {
        "pid": pid,
        "canvas_w": float(comp_w),
        "canvas_h": float(comp_h),
        "leaves": leaves,
        "cfg": cfg,
    }

def generate_sks(plant_data):
    pid = plant_data["pid"]
    canvas_w = plant_data["canvas_w"]
    canvas_h = plant_data["canvas_h"]
    leaves = plant_data["leaves"]

    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]

    # Update root bounds & visible rect
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-0.0}}}, {{{canvas_w}, {canvas_h}}}}}"

    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0}"

    root_children_uid = root["_children"].data
    root_children = objs[root_children_uid]["NS.objects"]
    array_class_uid = objs[root_children_uid]["$class"]

    mature_node = None
    for c_uid in root_children:
        node = objs[c_uid.data]
        name = objs[node["_name"].data]
        if name == "matureNode":
            mature_node = node
            break

    # Sample leaf
    sample_leaf_uid = objs[mature_node["_children"].data]["NS.objects"][0]
    sample_leaf = copy.deepcopy(objs[sample_leaf_uid.data])
    nsvalue_class_uid = objs[sample_leaf["_position"].data]["$class"]

    new_leaf_uids = []
    for leaf in leaves:
        lf = copy.deepcopy(sample_leaf)
        lf["_name"] = add_obj(f"leaf_{leaf['asset_id']}")

        pos_val = add_obj(f"{{{leaf['sk_x']:.1f}, {leaf['sk_y']:.1f}}}")
        lf["_position"] = add_obj({"NS.pointval": pos_val, "$class": nsvalue_class_uid, "NS.special": 1})

        anchor_val = add_obj(f"{{{leaf['ax']:.2f}, {leaf['ay']:.2f}}}")
        lf["_anchorPoint"] = add_obj({"NS.pointval": anchor_val, "$class": nsvalue_class_uid, "NS.special": 1})

        w, h, ax, ay = leaf["w"], leaf["h"], leaf["ax"], leaf["ay"]
        bounds_val = add_obj(f"{{{{{-ax*w:.1f}, {-ay*h:.1f}}}, {{{w:.0f}, {h:.0f}}}}}")
        lf["_bounds"] = add_obj({"NS.rectval": bounds_val, "$class": nsvalue_class_uid, "NS.special": 3})

        lf["_zPosition"] = add_obj(float(leaf["z_pos"]))

        tex = copy.deepcopy(objs[lf["_texture"].data])
        tex["_imgName"] = add_obj(leaf["img_name"])
        size_val = add_obj(f"{{{w:.0f}, {h:.0f}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": nsvalue_class_uid, "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        lf["_texture"] = add_obj(tex)

        # Ensure empty children array with valid class
        lf["_children"] = add_obj({"NS.objects": [], "$class": array_class_uid})

        new_leaf_uids.append(add_obj(lf))

    # Mutate existing matureNode children array in-place to preserve valid class
    objs[mature_node["_children"].data]["NS.objects"] = new_leaf_uids

    out_dir = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{pid}")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"Plant{pid}Scene.sks")
    with open(out_file, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)
    print(f"  ✅ Saved: {out_file}")

print("Python generator module ready!")

def generate_swift_node(plant_data):
    pid = plant_data["pid"]
    cfg = plant_data["cfg"]
    canvas_w = plant_data["canvas_w"]
    canvas_h = plant_data["canvas_h"]
    leaves = plant_data["leaves"]
    name_vn = cfg["name_vn"]
    botanical = cfg["botanical"]
    motion_eff = cfg["motion_effect"]
    tap_eff = cfg["tap_effects"]
    is_hanging_str = "true" if cfg["hanging"] else "false"
    idle_style = cfg["idle_style"]

    leaves_code = []
    for lf in leaves:
        is_left_str = "true" if lf["is_left"] else "false"
        leaves_code.append(
            f"        LeafData(assetId: {lf['asset_id']}, imgX: {lf['sk_x']:7.1f}, imgY: {lf['sk_y']:7.1f}, "
            f"width: {lf['w']:6.1f}, height: {lf['h']:6.1f}, "
            f"anchorX: {lf['ax']:4.2f}, anchorY: {lf['ay']:4.2f}, "
            f"isLeft: {is_left_str:5}, zPos: {int(lf['z_pos'])}, "
            f"bendAngle: {lf['bend']:6.3f}, duration: {lf['dur']:4.2f}, shouldSway: true)"
        )
    leaves_block = ",\n".join(leaves_code)

    swift_content = f"""//
//  Plant{pid}Node.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SpriteKit
import UIKit

// MARK: - Trạng thái sinh trưởng {name_vn} (Plant{pid} - {botanical})

public enum Plant{pid}GrowthState: Equatable {{
    case seed
    case sprout
    case mature(level: Int)

    public init(level: Int) {{
        switch level {{
        case 1, 100:
            self = .seed
        case 2, 200:
            self = .sprout
        default:
            self = .mature(level: max(3, level))
        }}
    }}

    public var rawLevel: Int {{
        switch self {{
        case .seed: return 1
        case .sprout: return 2
        case .mature(let lvl): return lvl
        }}
    }}

    public var title: String {{
        switch self {{
        case .seed: return "Gieo hạt (Lv.1)"
        case .sprout: return "Cây con (Lv.2)"
        case .mature(let lvl): return "Trưởng thành (Lv.\\(lvl))"
        }}
    }}
}}

// MARK: - Node SpriteKit điều khiển toàn bộ cấu trúc & animation Plant{pid}

public final class Plant{pid}Node: SKNode {{

    // MARK: - Metadata cấu trúc các bộ phận {name_vn} (Canvas {canvas_w:.0f} x {canvas_h:.0f})

    private struct LeafData {{
        let assetId: Int
        let imgX: CGFloat
        let imgY: CGFloat
        let width: CGFloat
        let height: CGFloat
        let anchorX: CGFloat
        let anchorY: CGFloat
        let isLeft: Bool
        let zPos: CGFloat
        let bendAngle: CGFloat
        let duration: TimeInterval
        let shouldSway: Bool
    }}

    private static let leavesMetadata: [LeafData] = [
{leaves_block}
    ]

    // MARK: - Properties

    public private(set) var growthState: Plant{pid}GrowthState = .mature(level: 1)
    private var containerSize: CGSize = .zero
    private var isHanging: Bool = {is_hanging_str}

    public var motionEffect: PlantMotionEffect = {motion_eff}
    public var tapEffects: [PlantTapEffect] = {tap_eff}

    private let plantRootNode = SKNode()
    private var leafNodes: [SKSpriteNode] = []
    private var seedNode: SKSpriteNode?
    private var sproutNode: SKSpriteNode?
    private var initialSeedPosition: CGPoint = .zero
    private var initialSproutPosition: CGPoint = .zero
    private var baseScale: CGFloat = 1.0

    // MARK: - Initializer

    public init(growthState: Plant{pid}GrowthState = .mature(level: 1), containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = {is_hanging_str}) {{
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        super.init()

        addChild(plantRootNode)
        build()
    }}

    public convenience init(level: Int, containerSize: CGSize = CGSize(width: 140, height: 180), isHanging: Bool = {is_hanging_str}) {{
        self.init(growthState: Plant{pid}GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }}

    public required init?(coder aDecoder: NSCoder) {{
        super.init(coder: aDecoder)
        addChild(plantRootNode)
    }}

    // MARK: - Configuration

    public func configure(growthState: Plant{pid}GrowthState, containerSize: CGSize, isHanging: Bool = {is_hanging_str}) {{
        self.growthState = growthState
        self.containerSize = containerSize
        self.isHanging = isHanging
        build()
    }}

    public func configure(level: Int, containerSize: CGSize, isHanging: Bool = {is_hanging_str}) {{
        configure(growthState: Plant{pid}GrowthState(level: level), containerSize: containerSize, isHanging: isHanging)
    }}

    // MARK: - Build Scene theo trạng thái

    public func build() {{
        plantRootNode.removeAllChildren()
        plantRootNode.removeAllActions()
        leafNodes.removeAll()
        seedNode = nil
        sproutNode = nil

        self.isPaused = false
        self.speed = 1.0
        plantRootNode.isPaused = false
        plantRootNode.speed = 1.0

        guard containerSize.width > 0, containerSize.height > 0 else {{ return }}

        switch growthState {{
        case .seed:
            buildSeedState()
        case .sprout:
            buildSproutState()
        case .mature:
            buildMatureState()
        }}
    }}

    // MARK: - State 100: Hạt giống (Seed)

    private func buildSeedState() {{
        let baseCanvasW: CGFloat = {canvas_w:.1f}
        let baseCanvasH: CGFloat = {canvas_h:.1f}
        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.90
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        if let scene = loadSceneTemplate(),
           let seedGroup = scene.childNode(withName: "seedNode") {{
            seedGroup.removeFromParent()
            seedGroup.isHidden = false
            seedGroup.isPaused = false
            seedGroup.speed = 1.0
            plantRootNode.addChild(seedGroup)

            if let sprite = seedGroup.childNode(withName: "seedSprite") as? SKSpriteNode {{
                if sprite.texture == nil {{
                    sprite.texture = loadSeedTexture()
                }}
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0.05)
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.seedNode = sprite
                self.initialSeedPosition = sprite.position
            }}
            return
        }}

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "seedNode"
        fallbackGroup.position = CGPoint(x: 0, y: 0)

        let node = SKSpriteNode(texture: loadSeedTexture())
        node.name = "seedSprite"
        node.size = CGSize(width: 80, height: 60)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0, y: -18.5)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.seedNode = node
        self.initialSeedPosition = node.position
    }}

    // MARK: - State 200: Cây con (Sprout)

    private func buildSproutState() {{
        let baseCanvasW: CGFloat = {canvas_w:.1f}
        let baseCanvasH: CGFloat = {canvas_h:.1f}
        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.90
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        if let scene = loadSceneTemplate(),
           let sproutGroup = scene.childNode(withName: "sproutNode") {{
            sproutGroup.removeFromParent()
            sproutGroup.isHidden = false
            sproutGroup.isPaused = false
            sproutGroup.speed = 1.0
            plantRootNode.addChild(sproutGroup)

            if let sprite = sproutGroup.childNode(withName: "sproutSprite") as? SKSpriteNode {{
                if sprite.texture == nil {{
                    sprite.texture = loadSproutTexture()
                }}
                sprite.anchorPoint = CGPoint(x: 0.5, y: 0.05)
                sprite.isHidden = false
                sprite.isPaused = false
                sprite.speed = 1.0
                self.sproutNode = sprite
                self.initialSproutPosition = sprite.position
            }}
            return
        }}

        // Fallback procedural
        let fallbackGroup = SKNode()
        fallbackGroup.name = "sproutNode"
        fallbackGroup.position = CGPoint(x: 0, y: 0)

        let node = SKSpriteNode(texture: loadSproutTexture())
        node.name = "sproutSprite"
        node.size = CGSize(width: 140, height: 160)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.05)
        node.position = CGPoint(x: 0, y: -18.5)
        node.zPosition = 10
        fallbackGroup.addChild(node)
        plantRootNode.addChild(fallbackGroup)
        self.sproutNode = node
        self.initialSproutPosition = node.position
    }}

    // MARK: - State 3+: Trưởng thành (Mature {name_vn})

    private func buildMatureState() {{
        let baseCanvasW: CGFloat = {canvas_w:.1f}
        let baseCanvasH: CGFloat = {canvas_h:.1f}

        let scaleX = containerSize.width / baseCanvasW
        let scaleY = containerSize.height / baseCanvasH
        self.baseScale = min(scaleX, scaleY) * 0.95
        plantRootNode.setScale(baseScale)
        plantRootNode.position = .zero

        // 1. ƯU TIÊN KIẾN TRÚC LAI: Nạp trực tiếp matureNode từ Plant{pid}Scene.sks
        if let scene = loadSceneTemplate(),
           let templateMature = scene.childNode(withName: "matureNode") {{
            templateMature.removeFromParent()
            templateMature.isHidden = false
            templateMature.isPaused = false
            templateMature.speed = 1.0
            plantRootNode.addChild(templateMature)

            let sortedLeaves = templateMature.children.compactMap {{ $0 as? SKSpriteNode }}.sorted {{
                let id1 = Int($0.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let id2 = Int($1.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                return id1 < id2
            }}

            for (idx, leaf) in sortedLeaves.enumerated() {{
                leaf.isHidden = false
                leaf.isPaused = false
                leaf.speed = 1.0
                leaf.restZRotation = leaf.zRotation
                leafNodes.append(leaf)

                let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
                let meta = Self.leavesMetadata.first(where: {{ $0.assetId == assetId }})

                if leaf.texture == nil {{
                    leaf.texture = loadPlantTexture(assetId: assetId)
                }}

                if meta?.shouldSway ?? true {{
                    let bend = meta?.bendAngle ?? 0.035
                    let dur = meta?.duration ?? 3.2
                    startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur, phaseDelay: Double(idx) * 0.18)
                }}
            }}
            return
        }}

        // 2. Procedural Fallback nếu chưa tải được .sks
        let fallbackGroup = SKNode()
        fallbackGroup.name = "matureNode"
        fallbackGroup.position = CGPoint(x: 0, y: -10)
        plantRootNode.addChild(fallbackGroup)

        for (idx, leafData) in Self.leavesMetadata.enumerated() {{
            guard let texture = loadPlantTexture(assetId: leafData.assetId) else {{ continue }}

            let leaf = SKSpriteNode(texture: texture)
            leaf.name = "leaf_\\(leafData.assetId)"
            leaf.size = CGSize(width: leafData.width, height: leafData.height)
            leaf.anchorPoint = CGPoint(x: leafData.anchorX, y: leafData.anchorY)
            leaf.position = CGPoint(x: leafData.imgX, y: leafData.imgY)
            leaf.zPosition = leafData.zPos

            fallbackGroup.addChild(leaf)
            leaf.restZRotation = leaf.zRotation
            leafNodes.append(leaf)

            if leafData.shouldSway {{
                startLeafIdleAnimation(leaf: leaf, bendAngle: leafData.bendAngle, duration: leafData.duration, phaseDelay: Double(idx) * 0.18)
            }}
        }}
    }}

    // MARK: - Hoạt ảnh nhàn rỗi (Idle Animation)

    private func startLeafIdleAnimation(leaf: SKSpriteNode, bendAngle: CGFloat, duration: TimeInterval, phaseDelay: TimeInterval) {{
        leaf.removeAction(forKey: "plantIdleAction")
        let rest = leaf.restZRotation
        leaf.zRotation = rest

        let rotateRight = SKAction.rotate(toAngle: rest + bendAngle, duration: duration * 0.5)
        rotateRight.timingMode = .easeInEaseOut
        let rotateLeft = SKAction.rotate(toAngle: rest - bendAngle, duration: duration)
        rotateLeft.timingMode = .easeInEaseOut
        let rotateBack = SKAction.rotate(toAngle: rest, duration: duration * 0.5)
        rotateBack.timingMode = .easeInEaseOut

        let swaySeq = SKAction.sequence([rotateRight, rotateLeft, rotateBack])

        let fullAction: SKAction
        if "{idle_style}" == "breathe" {{
            let breatheUp = SKAction.scaleY(to: 1.025, duration: duration * 0.5)
            breatheUp.timingMode = .easeInEaseOut
            let breatheDown = SKAction.scaleY(to: 0.985, duration: duration * 0.5)
            breatheDown.timingMode = .easeInEaseOut
            let breatheCycle = SKAction.sequence([breatheUp, breatheDown])
            fullAction = SKAction.group([swaySeq, breatheCycle])
        }} else {{
            fullAction = swaySeq
        }}

        if phaseDelay > 0 {{
            leaf.run(SKAction.sequence([
                SKAction.wait(forDuration: phaseDelay),
                SKAction.repeatForever(fullAction)
            ]), withKey: "plantIdleAction")
        }} else {{
            leaf.run(SKAction.repeatForever(fullAction), withKey: "plantIdleAction")
        }}
    }}

    // MARK: - Khôi phục chuyển động nhàn rỗi sau Tap

    public func resumeIdleAnimation() {{
        for (idx, leaf) in leafNodes.enumerated() {{
            let assetId = Int(leaf.name?.replacingOccurrences(of: "leaf_", with: "") ?? "") ?? 0
            let meta = Self.leavesMetadata.first(where: {{ $0.assetId == assetId }})
            if meta?.shouldSway ?? true {{
                let bend = meta?.bendAngle ?? 0.035
                let dur = meta?.duration ?? 3.2
                startLeafIdleAnimation(leaf: leaf, bendAngle: bend, duration: dur, phaseDelay: Double(idx) * 0.18)
            }}
        }}
    }}

    // MARK: - Phản hồi tương tác Tap

    public func playTapAnimation() {{
        motionEffect.apply(
            plantNode: self,
            plantRootNode: plantRootNode,
            seedNode: seedNode,
            sproutNode: sproutNode,
            leafNodes: leafNodes,
            baseScale: baseScale,
            level: growthState.rawLevel,
            initialSeedPosition: initialSeedPosition,
            initialSproutPosition: initialSproutPosition,
            containerSize: containerSize,
            onComplete: {{ [weak self] in
                self?.resumeIdleAnimation()
            }}
        )

        let lvl = growthState.rawLevel
        for effect in tapEffects {{
            effect.trigger(on: self, containerSize: containerSize, level: lvl, leaves: leafNodes)
        }}
    }}

    // MARK: - Scene Template Loader

    private func loadSceneTemplate() -> SKScene? {{
        return SKScene(fileNamed: "Plant{pid}Scene")
    }}

    // MARK: - Texture Loaders

    private func loadPlantTexture(assetId: Int) -> SKTexture? {{
        let name = "plant{pid}-\\(assetId)@4.167x"
        let tex = SKTexture(imageNamed: name)
        if tex.size().width > 0 {{ return tex }}
        return nil
    }}

    private func loadSeedTexture() -> SKTexture {{
        let candidates = [
            "plant1_Asset-100@4.167x",
            "plant1_Asset-100",
            "plant{pid}_Asset-100@4.167x",
            "plant{pid}_Asset-100"
        ]
        for name in candidates {{
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 {{ return tex }}
        }}
        return SKTexture()
    }}

    private func loadSproutTexture() -> SKTexture {{
        let candidates = [
            "plant1_Asset-200@4.167x",
            "plant1_Asset-200",
            "plant{pid}_Asset-200@4.167x",
            "plant{pid}_Asset-200"
        ]
        for name in candidates {{
            let tex = SKTexture(imageNamed: name)
            if tex.size().width > 0 {{ return tex }}
        }}
        return SKTexture()
    }}
}}
"""
    out_dir = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{pid}")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"Plant{pid}Node.swift")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(swift_content)
    print(f"  ✅ Saved: {out_file}")

def generate_swift_view(plant_data):
    pid = plant_data["pid"]
    cfg = plant_data["cfg"]
    name_vn = cfg["name_vn"]
    botanical = cfg["botanical"]
    is_hanging_str = "true" if cfg["hanging"] else "false"

    view_content = f"""//
//  Plant{pid}View.swift
//  terrariumidle_ios
//
//  Created by AI on 23/11/26.
//

import SwiftUI

/// SwiftUI Component chuyên biệt cho {name_vn} (Plant{pid} - {botanical})
public struct Plant{pid}View: View {{
    public var growthState: Plant{pid}GrowthState = .mature(level: 3)
    public var width: CGFloat
    public var height: CGFloat
    public var isHanging: Bool = {is_hanging_str}
    public var onTap: (() -> Void)? = nil

    public init(
        growthState: Plant{pid}GrowthState = .mature(level: 3),
        width: CGFloat = 120,
        height: CGFloat = 160,
        isHanging: Bool = {is_hanging_str},
        onTap: (() -> Void)? = nil
    ) {{
        self.growthState = growthState
        self.width = width
        self.height = height
        self.isHanging = isHanging
        self.onTap = onTap
    }}

    public init(
        level: Int = 3,
        width: CGFloat = 120,
        height: CGFloat = 160,
        isHanging: Bool = {is_hanging_str},
        onTap: (() -> Void)? = nil
    ) {{
        self.init(growthState: Plant{pid}GrowthState(level: level), width: width, height: height, isHanging: isHanging, onTap: onTap)
    }}

    public var body: some View {{
        PlantView(
            plantId: "plant{pid}",
            plantLevel: growthState.rawLevel,
            isHanging: isHanging,
            width: width,
            height: height,
            onTap: onTap
        )
        .id("plant{pid}-\\(growthState.rawLevel)")
    }}
}}

// MARK: - Interactive Preview Struct
private struct Plant{pid}InteractiveDemoView: View {{
    @State private var selectedLevel: Int = 3

    var body: some View {{
        VStack(spacing: 20) {{
            Text("🌱 Demo Plant{pid}: {name_vn} ({botanical})")
                .font(.headline)

            ZStack(alignment: .bottom) {{
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(width: 220, height: 260)

                Plant{pid}View(
                    level: selectedLevel,
                    width: 170,
                    height: 220,
                    isHanging: {is_hanging_str}
                )
                .padding(.bottom, 15)
            }}

            Picker("Trạng thái", selection: $selectedLevel) {{
                Text("Gieo hạt (Lv.1)").tag(1)
                Text("Cây con (Lv.2)").tag(2)
                Text("Trưởng thành (Lv.3)").tag(3)
                Text("Cực đại (Lv.10)").tag(10)
            }}
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
        }}
        .padding()
    }}
}}

#Preview {{
    Plant{pid}InteractiveDemoView()
}}
"""
    out_dir = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{pid}")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"Plant{pid}View.swift")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(view_content)
    print(f"  ✅ Saved: {out_file}")

def main():
    print("🚀 Bắt đầu quá trình trích xuất SVG & sinh Plant20 -> Plant30...")
    for pid in range(20, 31):
        print(f"\\nProcessing Plant{pid} ({PLANTS_CONFIG[pid]['name_vn']})...")
        pdata = parse_plant(pid)
        generate_sks(pdata)
        generate_swift_node(pdata)
        generate_swift_view(pdata)
    print("\\n🎉 Hoàn tất sinh toàn bộ 11 loài cây (Plant20 -> Plant30)!")

if __name__ == "__main__":
    main()

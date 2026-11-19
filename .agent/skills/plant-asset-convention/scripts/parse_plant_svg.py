#!/usr/bin/env python3
"""
Script bóc tách toạ độ và kích thước các bộ phận cây từ file SVG
chuyển đổi sang hệ toạ độ SpriteKit của Terrarium Idle iOS.

Hỗ trợ:
1. Đọc file SVG (cả dạng thẻ <image> hoặc vector <g>/<path> như plant3.svg).
2. Tự động tìm tỉ lệ scale với ảnh tham chiếu trong xcassets (ví dụ @4.167x).
3. Tự động tính toán điểm neo cuống lá và toạ độ SpriteKit (skX, skY).
4. Tự động cập nhật trực tiếp vào PlantXScene.sks và PlantXNode.swift khi truyền flag --update hoặc --plant <ID>.

Sử dụng:
    python3 parse_plant_svg.py --plant 3
    python3 parse_plant_svg.py <duong_dan_file_svg> [--plant ID] [--update] [--offset-y OFFSET]
"""

import sys
import os
import re
import argparse
import plistlib
import subprocess
import xml.etree.ElementTree as ET

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
RESOURCES_SVG_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Resources/SVGPlants")
COMPONENTS_PLANTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants")
ASSETS_PLANTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Assets.xcassets/Plants")

def get_asset_pixel_size(file_path):
    if not os.path.exists(file_path):
        return None
    try:
        out = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", file_path]).decode()
        w = int([line.split(":")[1].strip() for line in out.splitlines() if "pixelWidth" in line][0])
        h = int([line.split(":")[1].strip() for line in out.splitlines() if "pixelHeight" in line][0])
        return (w, h)
    except Exception:
        return None

def find_reference_canvas_size(plant_num):
    # 1. Ưu tiên đọc baseCanvasWidth / baseCanvasHeight từ PlantXNode.swift
    swift_path = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{plant_num}/Plant{plant_num}Node.swift")
    if os.path.exists(swift_path):
        with open(swift_path, "r", encoding="utf-8") as f:
            content = f.read()
            w_m = re.search(r"let baseCanvasWidth:\s*CGFloat\s*=\s*([\d.]+)", content)
            h_m = re.search(r"let baseCanvasHeight:\s*CGFloat\s*=\s*([\d.]+)", content)
            if w_m and h_m:
                return (float(w_m.group(1)), float(h_m.group(1)))

    # 2. Fallback: tìm ảnh avatar lớn nhất trong xcassets
    plant_asset_dir = os.path.join(ASSETS_PLANTS_DIR, f"plant{plant_num}")
    if not os.path.exists(plant_asset_dir):
        return None
    for entry in os.listdir(plant_asset_dir):
        if entry.endswith(".imageset"):
            img_file = os.path.join(plant_asset_dir, entry, entry.replace(".imageset", ".png"))
            if any(name in entry for name in ["aloe-vera", "begonia-rex", "Asset-1@"]):
                size = get_asset_pixel_size(img_file)
                if size and size[0] > 300:
                    return (float(size[0]), float(size[1]))
    return None

def extract_svg_elements(svg_path):
    tree = ET.parse(svg_path)
    root = tree.getroot()

    def clean_tag(tag):
        return tag.split('}')[-1] if '}' in tag else tag

    view_box = root.attrib.get('viewBox', '')
    width_attr = root.attrib.get('width', '')
    height_attr = root.attrib.get('height', '')

    svg_w, svg_h = 0.0, 0.0
    if view_box:
        parts = [float(p) for p in re.split(r'[\s,]+', view_box.strip()) if p]
        if len(parts) >= 4:
            svg_w = parts[2]
            svg_h = parts[3]
    if svg_w == 0.0 and width_attr:
        svg_w = float(re.sub(r'[^\d.]', '', width_attr))
    if svg_h == 0.0 and height_attr:
        svg_h = float(re.sub(r'[^\d.]', '', height_attr))

    container = None
    for elem in root.iter():
        elem_id = elem.attrib.get('id', '')
        if any(k in elem_id.lower() for k in ['rex', 'plant', 'leaves', 'object', 'body']):
            container = elem

    items = []
    for elem in root.iter():
        if clean_tag(elem.tag) == 'image':
            elem_id = elem.attrib.get('id', '')
            num_match = re.search(r'\d+', elem_id)
            aid = int(num_match.group()) if num_match else len(items) + 1
            x = float(elem.attrib.get('x', 0))
            y = float(elem.attrib.get('y', 0))
            w = float(elem.attrib.get('width', 0))
            h = float(elem.attrib.get('height', 0))
            if w > 0 and h > 0:
                items.append({'id': aid, 'x': x, 'y': y, 'w': w, 'h': h})

    if not items and container is not None:
        for idx, child in enumerate(container):
            tag = clean_tag(child.tag)
            paths = [child] if tag == "path" else child.findall(".//{*}path")
            all_x, all_y = [], []
            for p in paths:
                d = p.attrib.get("d", "")
                coords = re.findall(r"[-+]?[0-9]*\.?[0-9]+", d)
                for i in range(0, len(coords)-1, 2):
                    all_x.append(float(coords[i]))
                    all_y.append(float(coords[i+1]))
            if all_x and all_y:
                min_x, max_x = min(all_x), max(all_x)
                min_y, max_y = min(all_y), max(all_y)
                w = max_x - min_x
                h = max_y - min_y
                aid = idx + 1
                items.append({'id': aid, 'x': min_x, 'y': min_y, 'w': w, 'h': h})

    return svg_w, svg_h, items

def update_plant_sks(plant_num, leaf_coords):
    sks_path = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{plant_num}/Plant{plant_num}Scene.sks")
    if not os.path.exists(sks_path):
        print(f"⚠️  Không tìm thấy file: {sks_path}")
        return False

    with open(sks_path, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]
    def resolve(v):
        if hasattr(v, "data"):
            return objs[v.data]
        return v

    updated = 0
    for obj in objs:
        if isinstance(obj, dict) and "_name" in obj:
            name = resolve(obj["_name"])
            if isinstance(name, str) and name in leaf_coords:
                sk_x, sk_y, ax, ay = leaf_coords[name]
                pos_dict = resolve(obj.get("_position"))
                if isinstance(pos_dict, dict) and "NS.pointval" in pos_dict:
                    val_idx = pos_dict["NS.pointval"].data if hasattr(pos_dict["NS.pointval"], "data") else None
                    if val_idx is not None:
                        objs[val_idx] = f"{{{sk_x:.1f}, {sk_y:.1f}}}"
                anchor_dict = resolve(obj.get("_anchorPoint"))
                if isinstance(anchor_dict, dict) and "NS.pointval" in anchor_dict:
                    val_idx = anchor_dict["NS.pointval"].data if hasattr(anchor_dict["NS.pointval"], "data") else None
                    if val_idx is not None:
                        objs[val_idx] = f"{{{ax:.2f}, {ay:.2f}}}"
                updated += 1

    with open(sks_path, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã cập nhật {updated} lá trong {os.path.basename(sks_path)}")
    return True

def process_plant(plant_num, svg_path=None, do_update=False, offset_y=10.0):
    if not svg_path:
        svg_path = os.path.join(RESOURCES_SVG_DIR, f"plant{plant_num}.svg")

    if not os.path.exists(svg_path):
        print(f"❌ Lỗi: Không tìm thấy file SVG tại {svg_path}")
        return

    print(f"🌿 Bóc tách toạ độ Plant {plant_num} từ: {svg_path}")
    svg_w, svg_h, raw_items = extract_svg_elements(svg_path)
    if not raw_items:
        print("❌ Không tìm thấy phần tử nào trong file SVG!")
        return

    ref_size = find_reference_canvas_size(plant_num)
    if ref_size:
        canvas_w, canvas_h = float(ref_size[0]), float(ref_size[1])
    else:
        canvas_w, canvas_h = svg_w, svg_h

    scale_x = canvas_w / svg_w if svg_w > 0 else 1.0
    scale_y = canvas_h / svg_h if svg_h > 0 else 1.0

    print(f"📏 Canvas: {canvas_w:.1f} x {canvas_h:.1f} (Scale: {scale_x:.3f}x)")

    swift_path = os.path.join(COMPONENTS_PLANTS_DIR, f"Plant{plant_num}/Plant{plant_num}Node.swift")
    existing_meta = {}
    if os.path.exists(swift_path):
        with open(swift_path, "r", encoding="utf-8") as f:
            content = f.read()
            for m in re.finditer(r'LeafData\(assetId:\s*(\d+).*?anchorX:\s*([\d.]+),\s*anchorY:\s*([\d.]+),\s*isLeft:\s*(true|false)\s*,\s*zPos:\s*(\d+),\s*bendAngle:\s*([\d.]+),\s*duration:\s*([\d.]+)', content):
                aid = int(m.group(1))
                existing_meta[aid] = {
                    'anchorX': float(m.group(2)),
                    'anchorY': float(m.group(3)),
                    'isLeft': m.group(4) == 'true',
                    'zPos': int(m.group(5)),
                    'bendAngle': float(m.group(6)),
                    'duration': float(m.group(7))
                }

    leaf_coords = {}
    swift_lines = []

    for idx, it in enumerate(raw_items):
        aid = it['id']
        ix = it['x'] * scale_x
        iy = it['y'] * scale_y
        w = it['w'] * scale_x
        h = it['h'] * scale_y

        meta = existing_meta.get(aid)
        if meta:
            ax = meta['anchorX']
            ay = meta['anchorY']
            is_left = meta['isLeft']
            z_pos = meta['zPos']
            bend = meta['bendAngle']
            dur = meta['duration']
        else:
            center_x = ix + w / 2.0
            is_left = center_x < (canvas_w / 2.0)
            ax = 0.85 if is_left else 0.15
            ay = 0.00
            z_pos = 11 + idx
            bend = 0.040
            dur = 3.0

        sk_x = (ix + ax * w) - (canvas_w / 2.0)
        sk_y = canvas_h - iy - (1.0 - ay) * h - offset_y

        leaf_coords[f"leaf_{aid}"] = (sk_x, sk_y, ax, ay)
        swift_lines.append(
            f"        LeafData(assetId: {aid:2d}, imgX: {ix:4.0f}, imgY: {iy:4.0f}, width: {w:4.0f}, height: {h:4.0f}, "
            f"anchorX: {ax:.2f}, anchorY: {ay:.2f}, isLeft: {str(is_left).lower():5s}, "
            f"zPos: {z_pos:2d}, bendAngle: {bend:.3f}, duration: {dur:.1f}),"
        )

    print("\n📝 Mảng Swift leavesMetadata đề xuất:")
    print("    private static let leavesMetadata: [LeafData] = [")
    for line in swift_lines:
        print(line)
    print("    ]\n")

    if do_update:
        update_plant_sks(plant_num, leaf_coords)

        if os.path.exists(swift_path):
            with open(swift_path, "r", encoding="utf-8") as f:
                content = f.read()

            new_meta_block = "    private static let leavesMetadata: [LeafData] = [\n" + "\n".join(swift_lines) + "\n    ]"
            pattern = r"    private static let leavesMetadata: \[LeafData\] = \[[\s\S]*?    \]"
            if re.search(pattern, content):
                content = re.sub(pattern, new_meta_block, content)
                with open(swift_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"✅ Đã cập nhật metadata trong {os.path.basename(swift_path)}")
            else:
                print(f"⚠️  Không tìm thấy block leavesMetadata trong {swift_path}")

def main():
    parser = argparse.ArgumentParser(description="Tự động bóc tách SVG và cập nhật SpriteKit Scene")
    parser.add_argument("svg", nargs="?", default=None, help="Đường dẫn file SVG (tuỳ chọn)")
    parser.add_argument("--plant", type=int, default=None, help="Mã số Plant (ví dụ: 3 cho Plant3)")
    parser.add_argument("--update", action="store_true", help="Tự động cập nhật trực tiếp vào file .sks và .swift")
    parser.add_argument("--offset-y", type=float, default=10.0, help="Offset cuống lá cắm vào miệng chậu (mặc định: 10.0)")
    args = parser.parse_args()

    plant_num = args.plant
    svg_path = args.svg

    if plant_num is None and svg_path:
        match = re.search(r'plant(\d+)', svg_path.lower())
        if match:
            plant_num = int(match.group(1))

    if plant_num is not None:
        process_plant(plant_num, svg_path=svg_path, do_update=args.update or True, offset_y=args.offset_y)
    else:
        print("Vui lòng chỉ định --plant <ID> hoặc truyền đường dẫn file SVG dạng plantX.svg")

if __name__ == "__main__":
    main()

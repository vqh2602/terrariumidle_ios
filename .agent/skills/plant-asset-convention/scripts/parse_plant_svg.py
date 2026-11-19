#!/usr/bin/env python3
"""
Script bóc tách toạ độ và kích thước các bộ phận cây từ file SVG
chuyển đổi sang hệ toạ độ SpriteKit của Terrarium Idle iOS.

Sử dụng:
    python3 parse_plant_svg.py <duong_dan_file_svg> [--plant-id ID] [--offset-y OFFSET]
"""

import sys
import os
import re
import argparse
import xml.etree.ElementTree as ET

def parse_svg(svg_path, plant_id=None, offset_y=10.0):
    if not os.path.exists(svg_path):
        print(f"Lỗi: Không tìm thấy file {svg_path}")
        return

    tree = ET.parse(svg_path)
    root = tree.getroot()

    # Bỏ qua XML namespace prefix khi tìm tag
    def clean_tag(tag):
        return tag.split('}')[-1] if '}' in tag else tag

    # 1. Đọc kích thước Canvas (ViewBox hoặc Width/Height)
    view_box = root.attrib.get('viewBox', '')
    width_attr = root.attrib.get('width', '')
    height_attr = root.attrib.get('height', '')

    canvas_w = 0.0
    canvas_h = 0.0

    if view_box:
        parts = [float(p) for p in re.split(r'[\s,]+', view_box.strip()) if p]
        if len(parts) >= 4:
            canvas_w = parts[2]
            canvas_h = parts[3]
    
    if canvas_w == 0.0 and width_attr:
        canvas_w = float(re.sub(r'[^\d.]', '', width_attr))
    if canvas_h == 0.0 and height_attr:
        canvas_h = float(re.sub(r'[^\d.]', '', height_attr))

    if canvas_w == 0.0 or canvas_h == 0.0:
        canvas_w, canvas_h = 500.0, 700.0
        print(f"// Cảnh báo: Không tìm thấy kích thước viewBox, dùng mặc định: {canvas_w} x {canvas_h}")

    items = []

    # 2. Quét tất cả phần tử có id hoặc thẻ image/g/path
    for elem in root.iter():
        tag = clean_tag(elem.tag)
        elem_id = elem.attrib.get('id') or elem.attrib.get('data-name') or ''
        
        # Nhận diện phần tử là lá/bộ phận cây
        is_relevant = (
            tag == 'image' or
            any(k in elem_id.lower() for k in ['leaf', 'asset', 'part', 'branch', 'stem', 'plant'])
        )

        if not is_relevant and not ('x' in elem.attrib and 'y' in elem.attrib):
            continue

        x_val = elem.attrib.get('x')
        y_val = elem.attrib.get('y')
        w_val = elem.attrib.get('width')
        h_val = elem.attrib.get('height')

        # Thử lấy từ transform nếu không có x, y trực tiếp
        transform = elem.attrib.get('transform', '')
        if (x_val is None or y_val is None) and 'translate' in transform:
            tr_match = re.search(r'translate\(([-0-9.]+)[,\s]+([-0-9.]+)\)', transform)
            if tr_match:
                x_val = tr_match.group(1)
                y_val = tr_match.group(2)

        if x_val is None or y_val is None or w_val is None or h_val is None:
            continue

        try:
            x = float(re.sub(r'[^\d.-]', '', str(x_val)))
            y = float(re.sub(r'[^\d.-]', '', str(y_val)))
            w = float(re.sub(r'[^\d.-]', '', str(w_val)))
            h = float(re.sub(r'[^\d.-]', '', str(h_val)))
        except ValueError:
            continue

        if w <= 0 or h <= 0:
            continue

        # Trích xuất số Asset ID từ tên (vd: leaf_2 -> 2, Plant2-5 -> 5)
        num_match = re.search(r'\d+', elem_id)
        asset_id = int(num_match.group()) if num_match else len(items) + 1

        items.append({
            'id': elem_id or f"leaf_{asset_id}",
            'asset_id': asset_id,
            'x': x,
            'y': y,
            'width': w,
            'height': h
        })

    # Sắp xếp theo thứ tự assetId
    items.sort(key=lambda item: item['asset_id'])

    # 3. Sinh mã Swift
    print(f"// ================================================================")
    print(f"// Metadata tự động trích xuất từ SVG: {os.path.basename(svg_path)}")
    print(f"// Kích thước Canvas: {canvas_w:.1f} x {canvas_h:.1f}")
    print(f"// ================================================================\n")

    print(f"    // Canvas tham chiếu")
    print(f"    private let baseCanvasWidth: CGFloat = {canvas_w:.1f}")
    print(f"    private let baseCanvasHeight: CGFloat = {canvas_h:.1f}\n")

    print(f"    /// Tọa độ pixel và điểm neo cuống lá trích xuất từ SVG")
    print(f"    private static let leavesMetadata: [LeafData] = [")

    z_start = 11
    for i, it in enumerate(items):
        aid = it['asset_id']
        ix = it['x']
        iy = it['y']
        w = it['width']
        h = it['height']

        # Quy ước: lá ở nửa trái canvas thì nghiêng trái, cuống lá lệch phải (anchorX ~ 0.85)
        # lá ở nửa phải canvas thì nghiêng phải, cuống lá lệch trái (anchorX ~ 0.15)
        center_x = ix + w / 2.0
        is_left = center_x < (canvas_w / 2.0)
        anchor_x = 0.85 if is_left else 0.15
        anchor_y = 0.00
        z_pos = z_start + i

        # Tính toạ độ SpriteKit tham chiếu
        sk_x = (ix + anchor_x * w) - (canvas_w / 2.0)
        sk_y = canvas_h - iy - (1.0 - anchor_y) * h - offset_y

        print(f"        LeafData(assetId: {aid:2d}, imgX: {ix:4.0f}, imgY: {iy:4.0f}, width: {w:4.0f}, height: {h:4.0f}, "
              f"anchorX: {anchor_x:.2f}, anchorY: {anchor_y:.2f}, isLeft: {str(is_left).lower():5s}, "
              f"zPos: {z_pos:2d}, bendAngle: 0.040, duration: 3.0), // skPos: ({sk_x:5.1f}, {sk_y:5.1f})")

    print(f"    ]\n")

def main():
    parser = argparse.ArgumentParser(description="Parse SVG to Swift SpriteKit LeafData")
    parser.add_argument("svg", help="Đường dẫn file SVG")
    parser.add_argument("--offset-y", type=float, default=10.0, help="Offset cắm vào miệng chậu (mặc định: 10.0)")
    args = parser.parse_args()

    parse_svg(args.svg, offset_y=args.offset_y)

if __name__ == "__main__":
    main()

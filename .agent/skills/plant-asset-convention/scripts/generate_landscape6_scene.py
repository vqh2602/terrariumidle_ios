#!/usr/bin/env python3
"""
Script tạo file Landscape6Scene.sks trực quan cho Minamoto no Yuuhi (Landscape6)
Thiết kế dọc: canvas 1700 x 1943.233, anchorPoint = (0.5, 0.5) tại tâm.
Bao gồm các layer:
1. bgNode: nền trời hoàng hôn vàng ấm (landscape6-bg-3@4.167x, pos: (0, 0), size: 1700x2400, z: 0)
2. sunNode: vầng thái dương hoàng hôn (landscape6-sun-2@4.167x, pos: (0, 616.4385), size: 710.356x710.356, z: 5)
3. 11 Tầng núi (từ xa nhất Layer 11 đến gần nhất Layer 1):
   - mountain_11 (landscape6-11@4.167x, anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x1310.444, z: 10)
   - mountain_10 (landscape6-10@4.167x, anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x1180.411, z: 11)
   - mountain_9  (landscape6-9@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x1113.356, z: 12)
   - mountain_8  (landscape6-8@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x1052.683, z: 13)
   - mountain_7  (landscape6-7@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x943.730,  z: 14)
   - mountain_6  (landscape6-6@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x813.835,  z: 15)
   - mountain_5  (landscape6-5@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x734.039,  z: 16)
   - mountain_4  (landscape6-4@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x764.875,  z: 17)
   - mountain_3  (landscape6-3@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x859.211,  z: 18)
   - mountain_2  (landscape6-2@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x651.727,  z: 19)
   - mountain_1  (landscape6-1@4.167x,  anchor: (0.5, 0.0), pos: (0, -971.6165), size: 1700x789.317,  z: 20)
"""

import os
import plistlib
import copy

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Landscapes/Landscape6")
OUT_FILE = os.path.join(OUT_DIR, "Landscape6Scene.sks")

def generate_landscape6_scene():
    os.makedirs(OUT_DIR, exist_ok=True)

    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 1700.0
    canvas_h = 1943.233

    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h/2.0}}}, {{{canvas_w}, {canvas_h}}}}}"

    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0.5}"

    def make_sprite(name, img_name, x, y, w, h, z_pos, anchor_x=0.5, anchor_y=0.5, alpha=1.0, scale_x=1.0, scale_y=1.0):
        sp = copy.deepcopy(objs[19])
        sp["_name"] = add_obj(name)

        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        sp["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        anchor_val_uid = add_obj(f"{{{anchor_x}, {anchor_y}}}")
        sp["_anchorPoint"] = add_obj({"NS.pointval": anchor_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        min_bx = -anchor_x * w
        min_by = -anchor_y * h
        bounds_val_uid = add_obj(f"{{{{{min_bx}, {min_by}}}, {{{w}, {h}}}}}")
        sp["_bounds"] = add_obj({"NS.rectval": bounds_val_uid, "$class": plistlib.UID(5), "NS.special": 3})

        sp["_zPosition"] = add_obj(float(z_pos))
        sp["_opacity"] = add_obj(float(alpha))
        sp["_xScale"] = add_obj(float(scale_x))
        sp["_yScale"] = add_obj(float(scale_y))

        tex = copy.deepcopy(objs[sp["_texture"].data])
        tex["_imgName"] = add_obj(img_name)
        size_val = add_obj(f"{{{w}, {h}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        sp["_texture"] = add_obj(tex)

        return add_obj(sp)

    children_uids = []

    # 1. Nền bầu trời (z = 0.0)
    # Background texture size: 1700 x 2400 pt
    bg_uid = make_sprite("bgNode", "landscape6-bg-3@4.167x", 0.0, 0.0, 1700.0, 2400.0, 0.0, 0.5, 0.5)
    children_uids.append(bg_uid)

    # 2. Mặt trời hoàng hôn (z = 5.0)
    # Center SVG: (850, 355.178) -> in centered coord: x = 0, y = 1943.233/2 - 355.178 = 971.6165 - 355.178 = 616.4385
    sun_uid = make_sprite("sunNode", "landscape6-sun-2@4.167x", 0.0, 616.4385, 710.356, 710.356, 5.0, 0.5, 0.5)
    children_uids.append(sun_uid)

    # 3. 11 Tầng núi (từ xa nhất Layer 11 đến gần nhất Layer 1)
    # Tọa độ đáy của mọi layer núi là đáy canvas: y = -canvas_h / 2.0 = -971.6165
    bottom_y = -canvas_h / 2.0

    mountain_configs = [
        ("mountain_11", "landscape6-11@4.167x", 1310.444, 10.0),
        ("mountain_10", "landscape6-10@4.167x", 1180.411, 11.0),
        ("mountain_9",  "landscape6-9@4.167x",  1113.356, 12.0),
        ("mountain_8",  "landscape6-8@4.167x",  1052.683, 13.0),
        ("mountain_7",  "landscape6-7@4.167x",   943.730, 14.0),
        ("mountain_6",  "landscape6-6@4.167x",   813.835, 15.0),
        ("mountain_5",  "landscape6-5@4.167x",   734.039, 16.0),
        ("mountain_4",  "landscape6-4@4.167x",   764.875, 17.0),
        ("mountain_3",  "landscape6-3@4.167x",   859.211, 18.0),
        ("mountain_2",  "landscape6-2@4.167x",   651.727, 19.0),
        ("mountain_1",  "landscape6-1@4.167x",   789.317, 20.0),
    ]

    for name, img_name, h, z_pos in mountain_configs:
        m_uid = make_sprite(name, img_name, 0.0, bottom_y, 1700.0, h, z_pos, 0.5, 0.0)
        children_uids.append(m_uid)

    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = children_uids

    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print("Successfully generated:", OUT_FILE)

if __name__ == "__main__":
    generate_landscape6_scene()

#!/usr/bin/env python3
"""
Script tạo file Landscape1Scene.sks trực quan cho Ban công quang đãng (Landscape1)
Thiết kế dọc: canvas 750 x 1334, anchorPoint = (0.5, 0.5) tại tâm.
Bao gồm các layer:
1. bgNode: nền sky (bg1-1@4.167x, pos: (0, 0), size: 1334x1334, z: 0)
2. sunGroup: nhóm mặt trời (pos: (140, 380), z: 10)
   - sunAura4 (sunbg1-6@4.167x, z: 11, hào quang 4 / tia nắng)
   - sunAura3 (sunbg1-5@4.167x, z: 12, hào quang 3)
   - sunAura2 (sunbg1-4@4.167x, z: 13, hào quang 2)
   - sunAura1 (sunbg1-3@4.167x, z: 14, hào quang 1)
   - sunCore  (sunbg1-2@4.167x, z: 15, mặt trời chính)
3. cloudsGroup: nhóm mây trôi (pos: (0, 0), z: 20)
   - cloud_1 -> cloud_8 (Cloudbg1-1 -> Cloudbg1-8)
"""

import os
import plistlib
import copy

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Landscapes/Landscape1")
OUT_FILE = os.path.join(OUT_DIR, "Landscape1Scene.sks")

def generate_landscape1_scene():
    os.makedirs(OUT_DIR, exist_ok=True)

    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 750.0
    canvas_h = 1334.0

    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h/2.0}}}, {{{canvas_w}, {canvas_h}}}}}"

    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0.5}"

    def make_sprite(name, img_name, x, y, w, h, z_pos, alpha=1.0, scale_x=1.0, scale_y=1.0):
        sp = copy.deepcopy(objs[19])
        sp["_name"] = add_obj(name)

        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        sp["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        anchor_val_uid = add_obj("{0.5, 0.5}")
        sp["_anchorPoint"] = add_obj({"NS.pointval": anchor_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        bounds_val_uid = add_obj(f"{{{{{-w/2.0}, {-h/2.0}}}, {{{w}, {h}}}}}")
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

    def make_group_node(name, x, y, z_pos, children_uids):
        node = copy.deepcopy(objs[15])
        node["_name"] = add_obj(name)
        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        node["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
        node["_zPosition"] = add_obj(float(z_pos))
        node["_hidden"] = plistlib.UID(26)  # False
        node["_children"] = add_obj({"NS.objects": children_uids, "$class": plistlib.UID(25)})
        return add_obj(node)

    # 1. Nền phong cảnh
    bg_sprite_uid = make_sprite("bgNode", "bg1-1@4.167x", 0.0, 0.0, 1334.0, 1334.0, 0.0)

    # 2. Mặt trời và các lớp hào quang (Toạ độ chuẩn sau khi tinh chỉnh)
    sun_aura4 = make_sprite("sunAura4", "sunbg1-6@4.167x",  31.5727,  22.0004, 680.0, 530.0, 11.0, 0.55)
    sun_aura3 = make_sprite("sunAura3", "sunbg1-5@4.167x",  10.0001,  67.0005, 500.0, 440.0, 12.0, 0.70)
    sun_aura2 = make_sprite("sunAura2", "sunbg1-4@4.167x",  -4.9997,  99.9996, 340.0, 340.0, 13.0, 0.82)
    sun_aura1 = make_sprite("sunAura1", "sunbg1-3@4.167x", -18.8816, 151.7301, 200.0, 200.0, 14.0, 0.90)
    sun_core  = make_sprite("sunCore",  "sunbg1-2@4.167x", -14.4003, 136.9997, 120.0, 120.0, 15.0, 1.0, 2.0, 2.0)

    sun_group_uid = make_group_node("sunGroup", 140.0, 380.0, 10.0, [
        sun_aura4, sun_aura3, sun_aura2, sun_aura1, sun_core
    ])

    # 3. Các đám mây
    cloud1 = make_sprite("cloud_1", "Cloudbg1-1@4.167x", -180.0, 480.0, 320.0, 185.0, 21.0, 0.85)
    cloud2 = make_sprite("cloud_2", "Cloudbg1-2@4.167x",  190.0, 240.0, 280.0, 160.0, 22.0, 0.90)
    cloud3 = make_sprite("cloud_3", "Cloudbg1-3@4.167x", -120.0, 120.0, 340.0, 140.0, 20.0, 0.75)
    cloud4 = make_sprite("cloud_4", "Cloudbg1-4@4.167x",  160.0, 420.0, 310.0, 190.0, 23.0, 0.80)
    cloud5 = make_sprite("cloud_5", "Cloudbg1-5@4.167x", -230.0, 290.0, 180.0, 130.0, 19.0, 0.70)
    cloud6 = make_sprite("cloud_6", "Cloudbg1-6@4.167x",   40.0, 520.0, 150.0, 135.0, 18.0, 0.65)
    cloud7 = make_sprite("cloud_7", "Cloudbg1-7@4.167x",  -60.0,  -20.0, 360.0, 160.0, 24.0, 0.85)
    cloud8 = make_sprite("cloud_8", "Cloudbg1-8@4.167x",  210.0,  50.0, 220.0, 150.0, 21.0, 0.80)

    clouds_group_uid = make_group_node("cloudsGroup", 0.0, 0.0, 20.0, [
        cloud1, cloud2, cloud3, cloud4, cloud5, cloud6, cloud7, cloud8
    ])

    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [
        bg_sprite_uid,
        sun_group_uid,
        clouds_group_uid
    ]

    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print("Successfully generated:", OUT_FILE)

if __name__ == "__main__":
    generate_landscape1_scene()

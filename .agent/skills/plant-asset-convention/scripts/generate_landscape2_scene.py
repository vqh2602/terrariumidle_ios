#!/usr/bin/env python3
"""
Script tạo file Landscape2Scene.sks trực quan cho Ban công chiều tà (Landscape2)
Thiết kế dọc: canvas 1150 x 2071, anchorPoint = (0.5, 0.5) tại tâm.
Bao gồm các layer:
1. bgNode: nền sky hoàng hôn (landscape2-bg@4.167x, pos: (0, 0), size: 1150x2071, z: 0)
2. sunGroup: nhóm mặt trời hoàng hôn (pos: (255.0, 861.5), z: 10)
   - sunCore (landscape2-sun@4.167x, pos: (0, 0), size: 302x309, z: 12)
3. layer5Node: lớp phủ ánh sáng/mù sương chiều tà trên nền, nằm trước mặt trời (landscape2-5@4.167x, pos: (0, 196.0), size: 1150x1679, z: 20)
4. cloudsGroup: nhóm mây trôi trên cùng (pos: (0, 0), z: 30)
   - cloud_1 -> cloud_13 (landscape2-cloud-1 -> landscape2-cloud-13)
"""

import os
import plistlib
import copy

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Landscapes/Landscape2")
OUT_FILE = os.path.join(OUT_DIR, "Landscape2Scene.sks")

def generate_landscape2_scene():
    os.makedirs(OUT_DIR, exist_ok=True)

    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 1150.0
    canvas_h = 2071.0

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

    # 1. Nền phong cảnh (z: 0.0)
    bg_sprite_uid = make_sprite("bgNode", "landscape2-bg@4.167x", 0.0, 0.0, 1150.0, 2071.0, 0.0)

    # 2. Mặt trời hoàng hôn (z: 10.0 - nằm SAU layer 5)
    sun_core = make_sprite("sunCore", "landscape2-sun@4.167x", 0.0, 0.0, 302.0, 309.0, 12.0)
    sun_group_uid = make_group_node("sunGroup", 255.0, 861.5, 10.0, [sun_core])

    # 3. Lớp phủ trên nền và mặt trời nằm sau lớp này (z: 20.0)
    layer5_sprite_uid = make_sprite("layer5Node", "landscape2-5@4.167x", 0.0, 196.0, 1150.0, 1679.0, 20.0, 1.0)

    # 4. Các đám mây trên cùng (z: 30.0)
    cloud_configs = [
        ("cloud_1",  "landscape2-cloud-1@4.167x",   209.5,  -34.0, 394.0, 222.0, 31.0, 0.95),
        ("cloud_2",  "landscape2-cloud-2@4.167x",  -260.5,  359.5, 310.0, 175.0, 32.0, 0.95),
        ("cloud_3",  "landscape2-cloud-3@4.167x",    48.5,  251.0, 116.0,  72.0, 33.0, 0.90),
        ("cloud_4",  "landscape2-cloud-4@4.167x",   317.0,  471.5, 177.0,  65.0, 34.0, 0.90),
        ("cloud_5",  "landscape2-cloud-5@4.167x",  -157.0,  493.5,  89.0,  43.0, 35.0, 0.88),
        ("cloud_6",  "landscape2-cloud-6@4.167x",  -335.0,  799.0, 221.0, 144.0, 36.0, 0.92),
        ("cloud_7",  "landscape2-cloud-7@4.167x",  -508.0, -328.5, 101.0,  39.0, 31.0, 0.85),
        ("cloud_8",  "landscape2-cloud-8@4.167x",    10.5, -606.0,  70.0,  38.0, 32.0, 0.85),
        ("cloud_9",  "landscape2-cloud-9@4.167x",   451.5,  157.0,  70.0,  38.0, 33.0, 0.85),
        ("cloud_10", "landscape2-cloud-10@4.167x",  364.0,  -96.0, 105.0,  82.0, 34.0, 0.90),
        ("cloud_11", "landscape2-cloud-11@4.167x",  -55.0,  693.0, 139.0,  72.0, 35.0, 0.90),
        ("cloud_12", "landscape2-cloud-12@4.167x",  513.0, -230.5, 124.0, 147.0, 36.0, 0.92),
        ("cloud_13", "landscape2-cloud-13@4.167x", -225.5, -223.5, 198.0, 103.0, 37.0, 0.92),
    ]

    cloud_uids = []
    for cfg in cloud_configs:
        uid = make_sprite(cfg[0], cfg[1], cfg[2], cfg[3], cfg[4], cfg[5], cfg[6], cfg[7])
        cloud_uids.append(uid)

    clouds_group_uid = make_group_node("cloudsGroup", 0.0, 0.0, 30.0, cloud_uids)

    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [
        bg_sprite_uid,
        sun_group_uid,
        layer5_sprite_uid,
        clouds_group_uid
    ]

    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print("Successfully generated:", OUT_FILE)

if __name__ == "__main__":
    generate_landscape2_scene()

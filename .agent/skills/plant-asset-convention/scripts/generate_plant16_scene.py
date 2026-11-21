#!/usr/bin/env python3
"""
Script tạo file Plant16Scene.sks trực quan cho Chlorophytum comosum (Plant16)
- Canvas: 721 x 552, anchorPoint = (0.5, 0.0)
- seedNode (SKNode) -> seedSprite (SKSpriteNode, plant1_Asset-100@4.167x, 80x60, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- sproutNode (SKNode) -> sproutSprite (SKSpriteNode, plant1_Asset-200@4.167x, 140x160, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- matureNode (SKNode, pos: (0, -10)) -> 22 nhánh lá leaf_2..23 với texture plant16-X@4.167x
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant14/Plant14Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant16")
OUT_FILE = os.path.join(OUT_DIR, "Plant16Scene.sks")

# (assetId, imgName, w, h, ax, ay, posX, posY, zPos)
LEAVES_CONFIG = [
    ( 2, "plant16-2@4.167x",  163.0, 322.0, 0.07, 0.01, -107.7,  145.5, 11.0),
    ( 3, "plant16-3@4.167x",  247.0, 203.0, 0.01, 0.54,   53.9,  352.1, 12.0),
    ( 4, "plant16-4@4.167x",   75.0, 221.0, 0.83, 0.01,  114.1,  119.6, 13.0),
    ( 5, "plant16-5@4.167x",  321.0, 280.0, 0.01, 0.45,   42.8,  357.6, 14.0),
    ( 6, "plant16-6@4.167x",   69.0, 158.0, 0.86, 0.01,   96.9,  179.6, 15.0),
    ( 7, "plant16-7@4.167x",  144.0, 246.0, 0.48, 0.01,  106.7,  122.7, 16.0),
    ( 8, "plant16-8@4.167x",  216.0, 250.0, 0.72, 0.01,  206.1,  152.5, 17.0),
    ( 9, "plant16-9@4.167x",  100.0, 202.0, 0.03, 0.01,   46.8,  341.3, 18.0),
    (10, "plant16-10@4.167x",  55.0, 194.0, 0.34, 0.01,    4.5,  166.4, 19.0),
    (11, "plant16-11@4.167x", 200.0, 105.0, 0.99, 0.01,   36.0,  360.4, 20.0),
    (12, "plant16-12@4.167x", 149.0, 284.0, 0.52, 0.14,  -37.5,  110.9, 21.0),
    (13, "plant16-13@4.167x",  72.0, 164.0, 0.58, 0.01,   79.7,  185.5, 22.0),
    (14, "plant16-14@4.167x", 209.0,  82.0, 0.01, 0.01,   42.5,  336.3, 23.0),
    (15, "plant16-15@4.167x", 234.0, 151.0, 0.01, 0.01,   52.5,  365.9, 24.0),
    (16, "plant16-16@4.167x", 236.0, 191.0, 0.89, 0.01,   24.9,  348.5, 25.0),
    (17, "plant16-17@4.167x", 140.0,  66.0, 0.98, 0.01,   43.4,  368.4, 26.0),
    (18, "plant16-18@4.167x", 255.0, 194.0, 0.89, 0.55,   14.9,  328.4, 27.0),
    (19, "plant16-19@4.167x", 265.0, 268.0, 0.36, 0.11, -131.6,  143.4, 28.0),
    (20, "plant16-20@4.167x", 105.0, 338.0, 0.23, 0.32,   40.6,  112.5, 29.0),
    (21, "plant16-21@4.167x", 299.0, 293.0, 0.01, 0.66,   38.3,  327.1, 30.0),
    (22, "plant16-22@4.167x", 157.0, 357.0, 0.50, 0.15,  136.2,   91.2, 31.0),
    (23, "plant16-23@4.167x", 399.0, 267.0, 0.99, 0.57,   33.4,  358.4, 32.0),
]

def generate_plant16_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 721.0
    canvas_h = 552.0

    # 1. Update Scene bounds
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    # anchorPoint = (0.5, 0.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0}"

    # Tìm matureNode trong children của root
    root_children_uid = root["_children"].data
    root_children_list = objs[root_children_uid]["NS.objects"]

    mature_node = None
    sample_leaf_sprite = None

    for c_uid in root_children_list:
        c = objs[c_uid.data]
        name = objs[c["_name"].data]
        if name == "matureNode":
            mature_node = c
            # Lấy 1 leaf mẫu
            first_leaf_uid = objs[mature_node["_children"].data]["NS.objects"][0]
            sample_leaf_sprite = copy.deepcopy(objs[first_leaf_uid.data])

    if not mature_node or not sample_leaf_sprite:
        print("Lỗi: Không tìm thấy matureNode hoặc leaf sprite mẫu")
        return

    # Tạo các leaf sprite cho Plant16
    new_leaf_uids = []
    for assetId, imgName, w, h, ax, ay, posX, posY, zPos in LEAVES_CONFIG:
        leaf = copy.deepcopy(sample_leaf_sprite)
        leaf["_name"] = add_obj(f"leaf_{assetId}")

        # position
        pos_val = add_obj(f"{{{posX:.1f}, {posY:.1f}}}")
        leaf["_position"] = add_obj({"NS.pointval": pos_val, "$class": plistlib.UID(5), "NS.special": 1})

        # anchorPoint
        anchor_val = add_obj(f"{{{ax:.2f}, {ay:.2f}}}")
        leaf["_anchorPoint"] = add_obj({"NS.pointval": anchor_val, "$class": plistlib.UID(5), "NS.special": 1})

        # bounds {{-ax*w, -ay*h}, {w, h}}
        bounds_val = add_obj(f"{{{{{-ax*w:.2f}, {-ay*h:.2f}}}, {{{w:.0f}, {h:.0f}}}}}")
        leaf["_bounds"] = add_obj({"NS.rectval": bounds_val, "$class": plistlib.UID(5), "NS.special": 3})

        # zPosition
        leaf["_zPosition"] = add_obj(float(zPos))

        # texture
        tex = copy.deepcopy(objs[leaf["_texture"].data])
        tex["_imgName"] = add_obj(imgName)
        size_val = add_obj(f"{{{w:.0f}, {h:.0f}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        leaf["_texture"] = add_obj(tex)

        new_leaf_uids.append(add_obj(leaf))

    # Gán danh sách leaf con mới cho matureNode
    mature_children_uid = mature_node["_children"].data
    objs[mature_children_uid]["NS.objects"] = new_leaf_uids

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE}!")

if __name__ == "__main__":
    generate_plant16_scene()

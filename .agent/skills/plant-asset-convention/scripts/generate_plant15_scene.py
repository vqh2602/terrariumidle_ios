#!/usr/bin/env python3
"""
Script tạo file Plant15Scene.sks trực quan cho Ceropegia woodii (Plant15)
- Canvas: 657 x 763, anchorPoint = (0.5, 0.0)
- seedNode (SKNode) -> seedSprite (SKSpriteNode, plant1_Asset-100@4.167x, 80x60, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- sproutNode (SKNode) -> sproutSprite (SKSpriteNode, plant1_Asset-200@4.167x, 140x160, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- matureNode (SKNode, pos: (0, -10)) -> 6 nhánh lá leaf_2..7 với texture Plant15-X@4.167x
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant14/Plant14Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant15")
OUT_FILE = os.path.join(OUT_DIR, "Plant15Scene.sks")

LEAVES_CONFIG = [
    # assetId, imgName, w, h, ax, ay, posX, posY, zPos
    (2, "Plant15-2@4.167x", 263.0, 260.0, 0.85, 0.01, -11.0, 327.5, 13.0),
    (3, "Plant15-3@4.167x", 204.0, 436.0, 0.75, 0.01, -6.5, 331.5, 11.0),
    (4, "Plant15-4@4.167x", 197.0, 134.0, 0.15, 0.01, 88.0, 326.5, 14.0),
    (5, "Plant15-5@4.167x", 194.0, 326.0, 0.15, 0.01, 67.5, 330.5, 12.0),
    (6, "Plant15-6@4.167x", 322.0, 371.0, 0.12, 0.01, 45.0, 4.0, 16.0),
    (7, "Plant15-7@4.167x", 322.0, 230.0, 0.88, 0.01, -45.0, 199.5, 15.0),
]

def generate_plant15_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 657.0
    canvas_h = 763.0

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

    # Tạo các leaf sprite cho Plant15
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
    generate_plant15_scene()

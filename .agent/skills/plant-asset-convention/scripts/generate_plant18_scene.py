#!/usr/bin/env python3
"""
Script tạo file Plant18Scene.sks trực quan cho Curio rowleyanus (Plant18 - Chuỗi ngọc bi / String of pearls)
- Canvas: 654 x 1174, anchorPoint = (0.5, 0.0)
- seedNode (SKNode) -> seedSprite (SKSpriteNode, plant1_Asset-100@4.167x, 80x60, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- sproutNode (SKNode) -> sproutSprite (SKSpriteNode, plant1_Asset-200@4.167x, 140x160, pos: (0, -18.5), anchor: (0.5, 0.05), zPos: 10)
- matureNode (SKNode, pos: (0, -10)) ->
  - leaf_2 (Crown): SKSpriteNode, plant18-2@4.167x, 509x293, pos: (-7.0, 865.0), anchor: (0.5, 0.0), zPos: 11.0
  - leaf_3 (Vines): SKSpriteNode, plant18-3@4.167x, 654x1174, pos: (0.0, 1164.0), anchor: (0.5, 1.0), zPos: 12.0
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant14/Plant14Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant18")
OUT_FILE = os.path.join(OUT_DIR, "Plant18Scene.sks")

# (assetId, imgName, w, h, ax, ay, posX, posY, zPos)
# leaf_2: Crown (Cụm hạt ngọc trên miệng chậu) - bám miệng chậu, không đung đưa theo gió
# leaf_3: Vines (Các chuỗi hạt ngọc buông rủ dài) - neo tại cuống rủ, đung đưa mềm mại con lắc gió
LEAVES_CONFIG = [
    ( 2, "plant18-2@4.167x", 509.0, 293.0, 0.50, 0.00, -7.0,  865.0, 11.0 ),
    ( 3, "plant18-3@4.167x", 654.0, 1174.0, 0.50, 1.00,  0.0, 1164.0, 12.0 ),
]

def generate_plant18_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 654.0
    canvas_h = 1174.0

    # 1. Update Scene bounds
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-0.0}}}, {{{canvas_w}, {canvas_h}}}}}"

    # anchorPoint = (0.5, 0.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0}"

    root_children_uid = root["_children"].data
    root_children = objs[root_children_uid]["NS.objects"]
    array_class_uid = objs[root_children_uid]["$class"]

    # Locate seedNode, sproutNode, matureNode
    seed_node = None
    sprout_node = None
    mature_node = None

    for c_uid in root_children:
        node = objs[c_uid.data]
        name = objs[node["_name"].data]
        if name == "seedNode":
            seed_node = node
        elif name == "sproutNode":
            sprout_node = node
        elif name == "matureNode":
            mature_node = node

    # Sample leaf sprite
    sample_leaf_uid = objs[mature_node["_children"].data]["NS.objects"][0]
    sample_leaf = copy.deepcopy(objs[sample_leaf_uid.data])

    # Build new leaves for matureNode
    new_leaf_uids = []
    for (asset_id, img_name, w, h, ax, ay, px, py, z) in LEAVES_CONFIG:
        leaf = copy.deepcopy(sample_leaf)
        leaf["_name"] = add_obj(f"leaf_{asset_id}")

        pos_val = add_obj(f"{{{px:.1f}, {py:.1f}}}")
        leaf["_position"] = add_obj({"NS.pointval": pos_val, "$class": plistlib.UID(5), "NS.special": 1})

        anchor_val = add_obj(f"{{{ax:.2f}, {ay:.2f}}}")
        leaf["_anchorPoint"] = add_obj({"NS.pointval": anchor_val, "$class": plistlib.UID(5), "NS.special": 1})

        bounds_val = add_obj(f"{{{{{-ax*w:.1f}, {-ay*h:.1f}}}, {{{w:.0f}, {h:.0f}}}}}")
        leaf["_bounds"] = add_obj({"NS.rectval": bounds_val, "$class": plistlib.UID(5), "NS.special": 3})

        leaf["_zPosition"] = add_obj(float(z))

        tex = copy.deepcopy(objs[leaf["_texture"].data])
        tex["_imgName"] = add_obj(img_name)
        size_val = add_obj(f"{{{w:.0f}, {h:.0f}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        leaf["_texture"] = add_obj(tex)

        leaf["_children"] = add_obj({"NS.objects": [], "$class": array_class_uid})

        new_leaf_uids.append(add_obj(leaf))

    objs[mature_node["_children"].data]["NS.objects"] = new_leaf_uids

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE}!")

if __name__ == "__main__":
    generate_plant18_scene()

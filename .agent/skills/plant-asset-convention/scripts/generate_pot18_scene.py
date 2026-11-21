#!/usr/bin/env python3
"""
Script tạo file Pot18Scene.sks trực quan cho Chậu đất kiềng (Pot18 - Hanging Pot)
- Kích thước canvas: 497 x 821, anchorPoint = (0.5, 1.0) tại đỉnh móc treo
- potNode (SKSpriteNode, Pot18@4.167x, pos: (0, 0), anchor: (0.5, 1.0), size: 497 x 821, z: 50.0)
- plantMount (SKNode, pos: (0, -485.0), z: 10.0)
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot1/Pot1Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot18")
OUT_FILE = os.path.join(OUT_DIR, "Pot18Scene.sks")

def generate_pot18_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 497.0
    canvas_h = 821.0
    mount_y = -485.0

    # 1. Update Scene bounds for hanging pot: anchor (0.5, 1.0)
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h}}}, {{{canvas_w}, {canvas_h}}}}}"

    # Anchor point = (0.5, 1.0) tại đỉnh móc treo
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 1}"

    root_children_uid = root["_children"].data
    root_children = objs[root_children_uid]["NS.objects"]

    # Locate plantMount and potNode
    mount_node = None
    pot_node = None

    for c_uid in root_children:
        node = objs[c_uid.data]
        name = objs[node["_name"].data]
        if name == "plantMount":
            mount_node = node
        elif name == "potNode":
            pot_node = node

    # Update plantMount: pos (0, -485.0) tại miệng chậu
    if mount_node:
        pos_val = add_obj(f"{{0, {mount_y:.1f}}}")
        mount_node["_position"] = add_obj({"NS.pointval": pos_val, "$class": plistlib.UID(5), "NS.special": 1})
        mount_node["_zPosition"] = add_obj(10.0)

    # Update potNode: anchor (0.5, 1.0), pos (0, 0), buông thõng xuống dưới
    if pot_node:
        pos_val = add_obj("{0, 0}")
        pot_node["_position"] = add_obj({"NS.pointval": pos_val, "$class": plistlib.UID(5), "NS.special": 1})

        anchor_val = add_obj("{0.5, 1}")
        pot_node["_anchorPoint"] = add_obj({"NS.pointval": anchor_val, "$class": plistlib.UID(5), "NS.special": 1})

        bounds_val = add_obj(f"{{{{{-canvas_w/2.0:.1f}, {-canvas_h:.1f}}}, {{{canvas_w:.0f}, {canvas_h:.0f}}}}}")
        pot_node["_bounds"] = add_obj({"NS.rectval": bounds_val, "$class": plistlib.UID(5), "NS.special": 3})

        pot_node["_zPosition"] = add_obj(50.0)

        tex = copy.deepcopy(objs[pot_node["_texture"].data])
        tex["_imgName"] = add_obj("Pot18@4.167x")
        size_val = add_obj(f"{{{canvas_w:.0f}, {canvas_h:.0f}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        pot_node["_texture"] = add_obj(tex)

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE} (Hanging Pot, anchor=(0.5, 1.0))!")

if __name__ == "__main__":
    generate_pot18_scene()

#!/usr/bin/env python3
"""
Script tạo file Sticker1Scene.sks trực quan cho Búp bê cầu nắng (Sticker1 - Sunshine doll)
Hệ toạ độ sticker treo: anchorPoint = (0.5, 1.0) tại đỉnh dây treo, canvas 122 x 375.
Bao gồm các layer phân tầng ghép lại (Multi-component assembled structure):
- ropeNode (SKSpriteNode, sticker1-2@4.167x, pos: (0.0, -53.64), size: (7.68, 107.27), z: 5.0)
- dollNode (SKSpriteNode, sticker1-3@4.167x, pos: (0.0, -235.54), size: (121.91, 278.14), z: 10.0)
- ribbonLeftNode (SKSpriteNode, sticker1-4@4.167x, pos: (-29.16, -206.14), size: (38.16, 62.87), z: 20.0)
- ribbonRightNode (SKSpriteNode, sticker1-5@4.167x, pos: (8.28, -205.06), size: (34.80, 60.71), z: 20.0)
"""

import os
import copy
import plistlib
from pathlib import Path
from optimize_plant_assets import Scene
from optimize_sticker_assets import optimize_sticker

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
OUT_FILE = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Stickers/Sticker1/Sticker1Scene.sks")

def create_sticker1_scene():
    template = Scene(Path(BASE_SKS))
    pl = template.data
    objs = template.objects
    prototype = next(node for node in template.nodes()
                     if template.get(node.get("_name")) == "seedSprite")
    nsvalue_class = template.get(prototype["_position"])["$class"]
    array_class = template.get(template.root["_children"])["$class"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = template.root
    canvas_w = 122.0
    canvas_h = 375.0

    # 1. Update Scene bounds: anchor (0.5, 1.0), visibleRect {{-61.0, -375.0}, {122.0, 375.0}}
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h}}}, {{{canvas_w}, {canvas_h}}}}}"

    # Anchor point = (0.5, 1.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 1}"

    # Resolve the prototype and archive classes dynamically; templates may be compacted.
    def make_sprite(name, img_name, x, y, w, h, z_pos):
        sp = copy.deepcopy(prototype)
        sp["_children"] = add_obj({"NS.objects": [], "$class": array_class})
        sp["_name"] = add_obj(name)

        # pos
        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        sp["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": nsvalue_class, "NS.special": 1})

        # anchor (0.5, 0.5) vì đã tính toạ độ tâm sprite
        anchor_val_uid = add_obj("{0.5, 0.5}")
        sp["_anchorPoint"] = add_obj({"NS.pointval": anchor_val_uid, "$class": nsvalue_class, "NS.special": 1})

        # bounds {{-w/2, -h/2}, {w, h}}
        bounds_val_uid = add_obj(f"{{{{{-w/2.0}, {-h/2.0}}}, {{{w}, {h}}}}}")
        sp["_bounds"] = add_obj({"NS.rectval": bounds_val_uid, "$class": nsvalue_class, "NS.special": 3})

        # zPos
        sp["_zPosition"] = add_obj(float(z_pos))

        # texture
        tex = copy.deepcopy(objs[sp["_texture"].data])
        tex["_imgName"] = add_obj(img_name)
        size_val = add_obj(f"{{{w}, {h}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": nsvalue_class, "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        sp["_texture"] = add_obj(tex)

        return add_obj(sp)

    # 1. ropeNode (Dây treo trên đỉnh): z = 5.0
    rope_uid = make_sprite("ropeNode", "sticker1-2@4.167x", 0.0, -53.64, 7.68, 107.27, 5.0)

    # 2. dollNode (Thân búp bê cầu nắng): z = 10.0
    doll_uid = make_sprite("dollNode", "sticker1-3@4.167x", 0.0, -235.54, 121.91, 278.14, 10.0)

    # 3. ribbonLeftNode (Ruy băng nơ trước ngực bên trái): z = 20.0
    ribbon_left_uid = make_sprite("ribbonLeftNode", "sticker1-4@4.167x", -29.16, -206.14, 38.16, 62.87, 20.0)

    # 4. ribbonRightNode (Ruy băng nơ trước ngực bên phải): z = 20.0
    ribbon_right_uid = make_sprite("ribbonRightNode", "sticker1-5@4.167x", 8.28, -205.06, 34.80, 60.71, 20.0)

    # Đưa vào danh sách children của Scene theo thứ tự hiển thị z-index
    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [
        rope_uid,
        doll_uid,
        ribbon_left_uid,
        ribbon_right_uid
    ]

    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    optimize_sticker(1, apply=True, scene_path=OUT_FILE)
    print(f"✅ Đã tạo và kiểm tra ngân sách texture: {OUT_FILE}")

if __name__ == "__main__":
    create_sticker1_scene()

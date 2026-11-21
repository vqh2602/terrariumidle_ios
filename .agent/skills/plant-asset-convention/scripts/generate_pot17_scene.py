#!/usr/bin/env python3
"""
Script tạo file Pot17Scene.sks trực quan cho Chậu đất treo (Pot17)
Hệ toạ độ chậu treo: anchorPoint = (0.5, 1.0) tại đỉnh móc treo, canvas 357 x 883.
Bao gồm các layer phân tầng (Z-Layering):
- backRope (SKSpriteNode, pot17-2@4.167x, pos: (0.0, -277.0), size: 356 x 554, z: 5.0)
- plantMount (SKNode, pos: (0.0, -475.0), z: 10.0, _hidden: false)
- potBody (SKSpriteNode, pot17-3@4.167x, pos: (0.0, -678.0), size: 355 x 410, z: 50.0)
- frontRope (SKSpriteNode, pot17-4@4.167x, pos: (13.0, -250.0), size: 212 x 462, z: 100.0)
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot15/Pot15Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot17")
OUT_FILE = os.path.join(OUT_DIR, "Pot17Scene.sks")

def create_pot17_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 357.0
    canvas_h = 883.0

    # 1. Update Scene bounds: anchor (0.5, 1.0), visibleRect {{-178.5, -883.0}, {357.0, 883.0}}
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h}}}, {{{canvas_w}, {canvas_h}}}}}"

    # Anchor point = (0.5, 1.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 1}"

    # Tìm sprite mẫu từ scene gốc
    root_children_uid = root["_children"].data
    root_children_list = objs[root_children_uid]["NS.objects"]
    array_class_uid = objs[root_children_uid]["$class"]
    
    sample_sprite = None
    sample_mount = None
    for c_uid in root_children_list:
        c = objs[c_uid.data]
        c_name = objs[c["_name"].data]
        if c_name == "plantMount":
            sample_mount = copy.deepcopy(c)
        elif sample_sprite is None and "_texture" in c:
            sample_sprite = copy.deepcopy(c)

    def make_sprite(name, img_name, x, y, w, h, z_pos):
        sp = copy.deepcopy(sample_sprite)
        sp["_name"] = add_obj(name)

        # pos
        pos_val_uid = add_obj(f"{{{x:.1f}, {y:.1f}}}")
        sp["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        # anchor (0.5, 0.5)
        anchor_val_uid = add_obj("{0.5, 0.5}")
        sp["_anchorPoint"] = add_obj({"NS.pointval": anchor_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        # bounds {{-w/2, -h/2}, {w, h}}
        bounds_val_uid = add_obj(f"{{{{{-w/2.0:.1f}, {-h/2.0:.1f}}}, {{{w:.0f}, {h:.0f}}}}}")
        sp["_bounds"] = add_obj({"NS.rectval": bounds_val_uid, "$class": plistlib.UID(5), "NS.special": 3})

        # zPos
        sp["_zPosition"] = add_obj(float(z_pos))

        # texture
        tex = copy.deepcopy(objs[sp["_texture"].data])
        tex["_imgName"] = add_obj(img_name)
        size_val = add_obj(f"{{{w:.0f}, {h:.0f}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        sp["_texture"] = add_obj(tex)

        # empty children array với đúng NSMutableArray class
        sp["_children"] = add_obj({"NS.objects": [], "$class": array_class_uid})

        return add_obj(sp)

    def make_mount(name, x, y, z_pos):
        node = copy.deepcopy(sample_mount)
        node["_name"] = add_obj(name)
        pos_val_uid = add_obj(f"{{{x:.1f}, {y:.1f}}}")
        node["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
        node["_zPosition"] = add_obj(float(z_pos))
        node["_hidden"] = plistlib.UID(24)  # False
        node["_children"] = add_obj({"NS.objects": [], "$class": array_class_uid})
        return add_obj(node)

    # 1. backRope (Dây treo sau): z = 5.0
    back_rope_uid = make_sprite("backRope", "pot17-2@4.167x", 0.0, -277.0, 356.0, 554.0, 5.0)

    # 2. plantMount (Socket cắm cây): z = 10.0, miệng chậu tại y = -475.0pt
    plant_mount_uid = make_mount("plantMount", 0.0, -475.0, 10.0)

    # 3. potBody (Bầu chậu đất nung): z = 50.0
    pot_body_uid = make_sprite("potBody", "pot17-3@4.167x", 0.0, -678.0, 355.0, 410.0, 50.0)

    # 4. frontRope (Dây treo trước): z = 100.0
    front_rope_uid = make_sprite("frontRope", "pot17-4@4.167x", 13.0, -250.0, 212.0, 462.0, 100.0)

    # Gán children theo thứ tự z-order
    objs[root_children_uid]["NS.objects"] = [
        back_rope_uid,
        plant_mount_uid,
        pot_body_uid,
        front_rope_uid
    ]

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE}!")

if __name__ == "__main__":
    create_pot17_scene()

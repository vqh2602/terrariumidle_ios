#!/usr/bin/env python3
"""
Script tạo file Pot16Scene.sks trực quan cho Chậu sứ mạ vàng (Pot16)
Hệ toạ độ chậu treo: anchorPoint = (0.5, 1.0) tại đỉnh móc treo, canvas 155 x 494.
Bao gồm các layer phân tầng (Z-Layering):
- plantMount (SKNode, pos: (0.0, -353.0), z: 10.0, _hidden: false)
- potBody (SKSpriteNode, pot16-4@4.167x, pos: (0.0, -417.8), size: 155 x 154, z: 50.0)
- potRim (SKSpriteNode, pot16-5@4.167x, pos: (-1.0, -353.3), size: 133 x 19, z: 52.0)
- frontLeftRope (SKSpriteNode, pot16-2@4.167x, pos: (-26.3, -185.3), size: 96 x 369, z: 100.0)
- frontRightRope (SKSpriteNode, pot16-3@4.167x, pos: (-0.6, -184.9), size: 147 x 366, z: 100.0)
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot15/Pot15Scene.sks")
OUT_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot16")
OUT_FILE = os.path.join(OUT_DIR, "Pot16Scene.sks")

def create_pot16_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 155.0
    canvas_h = 494.0

    # 1. Update Scene bounds: anchor (0.5, 1.0), visibleRect {{-77.5, -494.0}, {155.0, 494.0}}
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h}}}, {{{canvas_w}, {canvas_h}}}}}"

    # Anchor point = (0.5, 1.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 1}"

    # Tìm sprite mẫu từ scene gốc (ví dụ backRope hoặc potBody)
    root_children_uid = root["_children"].data
    root_children_list = objs[root_children_uid]["NS.objects"]
    
    sample_sprite = None
    sample_mount = None
    for c_uid in root_children_list:
        c = objs[c_uid.data]
        c_name = objs[c["_name"].data]
        if c_name == "plantMount":
            sample_mount = copy.deepcopy(c)
        elif sample_sprite is None and "_texture" in c:
            sample_sprite = copy.deepcopy(c)

    # Lấy class UID của NSMutableArray từ sample_mount hoặc root_children
    array_class_uid = objs[root_children_uid]["$class"]

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

    # 1. plantMount (Socket cắm cây): z = 10.0
    plant_mount_uid = make_mount("plantMount", 0.0, -353.0, 10.0)

    # 2. potBody (Bầu chậu sứ vàng): z = 50.0
    pot_body_uid = make_sprite("potBody", "pot16-4@4.167x", 0.0, -417.8, 155.0, 154.0, 50.0)

    # 3. potRim (Miệng chậu): z = 52.0
    pot_rim_uid = make_sprite("potRim", "pot16-5@4.167x", -1.0, -353.3, 133.0, 19.0, 52.0)

    # 4. frontLeftRope (Dây treo trái): z = 100.0
    front_left_uid = make_sprite("frontLeftRope", "pot16-2@4.167x", -26.3, -185.3, 96.0, 369.0, 100.0)

    # 5. frontRightRope (Dây treo phải): z = 100.0
    front_right_uid = make_sprite("frontRightRope", "pot16-3@4.167x", -0.6, -184.9, 147.0, 366.0, 100.0)

    # Gán children theo thứ tự z-order
    objs[root_children_uid]["NS.objects"] = [
        plant_mount_uid,
        pot_body_uid,
        pot_rim_uid,
        front_left_uid,
        front_right_uid
    ]

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE}!")

if __name__ == "__main__":
    create_pot16_scene()

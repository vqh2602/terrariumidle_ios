#!/usr/bin/env python3
"""
Script tạo file Pot15Scene.sks trực quan cho Chậu sứ Msuit (Pot15)
Hệ toạ độ chậu treo: anchorPoint = (0.5, 1.0) tại đỉnh móc treo, canvas 363 x 724.
Bao gồm các layer phân tầng (Z-Layering):
- backRope (SKSpriteNode, Pot15-4@4.167x, pos: (10.5, -286.0), z: 5.0)
- plantMount (SKNode, pos: (0.0, -506.0), z: 10.0, _hidden: false)
- potBody (SKSpriteNode, Pot15-5@4.167x, pos: (0.0, -603.0), z: 50.0)
- frontLeftRope (SKSpriteNode, Pot15-2@4.167x, pos: (-74.0, -254.0), z: 100.0)
- frontRightRope (SKSpriteNode, Pot15-3@4.167x, pos: (84.5, -240.5), z: 100.0)
"""

import os
import copy
import plistlib

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
OUT_FILE = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots/Pot15/Pot15Scene.sks")

def create_pot15_scene():
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    canvas_w = 363.0
    canvas_h = 724.0

    # 1. Update Scene bounds: anchor (0.5, 1.0), visibleRect {{-181.5, -724.0}, {363.0, 724.0}}
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{canvas_w}, {canvas_h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-canvas_w/2.0}, {-canvas_h}}}, {{{canvas_w}, {canvas_h}}}}}"

    # Anchor point = (0.5, 1.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 1}"

    # Helper tạo SKSpriteNode từ prototype objs[19] (seedSprite)
    def make_sprite(name, img_name, x, y, w, h, z_pos):
        sp = copy.deepcopy(objs[19])
        sp["_name"] = add_obj(name)

        # pos
        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        sp["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        # anchor (0.5, 0.5) vì đã tính toạ độ tâm sprite
        anchor_val_uid = add_obj("{0.5, 0.5}")
        sp["_anchorPoint"] = add_obj({"NS.pointval": anchor_val_uid, "$class": plistlib.UID(5), "NS.special": 1})

        # bounds {{-w/2, -h/2}, {w, h}}
        bounds_val_uid = add_obj(f"{{{{{-w/2.0}, {-h/2.0}}}, {{{w}, {h}}}}}")
        sp["_bounds"] = add_obj({"NS.rectval": bounds_val_uid, "$class": plistlib.UID(5), "NS.special": 3})

        # zPos
        sp["_zPosition"] = add_obj(float(z_pos))

        # texture
        tex = copy.deepcopy(objs[sp["_texture"].data])
        tex["_imgName"] = add_obj(img_name)
        size_val = add_obj(f"{{{w}, {h}}}")
        size_uid = add_obj({"NS.sizeval": size_val, "$class": plistlib.UID(5), "NS.special": 2})
        tex["_size"] = size_uid
        tex["_pixelSize"] = size_uid
        sp["_texture"] = add_obj(tex)

        return add_obj(sp)

    # Helper tạo SKNode mount từ objs[15] (seedNode)
    def make_mount(name, x, y, z_pos):
        node = copy.deepcopy(objs[15])
        node["_name"] = add_obj(name)
        pos_val_uid = add_obj(f"{{{x}, {y}}}")
        node["_position"] = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
        node["_zPosition"] = add_obj(float(z_pos))
        node["_hidden"] = plistlib.UID(26)  # False (hiển thị để không ẩn node con gắn vào)
        node["_children"] = add_obj({"NS.objects": [], "$class": plistlib.UID(25)})
        return add_obj(node)

    # 1. backRope (Dây giữa sau): z = 5.0
    back_rope_uid = make_sprite("backRope", "Pot15-4@4.167x", 10.5, -286.0, 10.0, 516.0, 5.0)

    # 2. plantMount (Socket cắm cây): z = 10.0
    plant_mount_uid = make_mount("plantMount", 0.0, -506.0, 10.0)

    # 3. potBody (Bầu chậu sứ): z = 50.0
    pot_body_uid = make_sprite("potBody", "Pot15-5@4.167x", 0.0, -603.0, 363.0, 242.0, 50.0)

    # 4. frontLeftRope (Dây trước trái + móc): z = 100.0
    front_left_uid = make_sprite("frontLeftRope", "Pot15-2@4.167x", -74.0, -254.0, 215.0, 506.0, 100.0)

    # 5. frontRightRope (Dây trước phải): z = 100.0
    front_right_uid = make_sprite("frontRightRope", "Pot15-3@4.167x", 84.5, -240.5, 168.0, 479.0, 100.0)

    # Đưa vào danh sách children của Scene theo thứ tự hiển thị z-index
    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [
        back_rope_uid,
        plant_mount_uid,
        pot_body_uid,
        front_left_uid,
        front_right_uid
    ]

    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo thành công {OUT_FILE}!")

if __name__ == "__main__":
    create_pot15_scene()

#!/usr/bin/env python3
"""
Script tự động sinh các file Scene trực quan PotXScene.sks cho 14 loài chậu
trong Terrarium Idle iOS.
Mỗi file .sks chứa:
1. potNode (SKSpriteNode): Thân chậu gán texture thật từ Assets.xcassets, zPos = 20
2. plantMount (SKNode): Socket điểm cắm cây, zPos = 10 (có thể kéo thả bằng chuột trong Xcode)
"""

import os
import copy
import plistlib
import subprocess

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
POTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots")

POTS_METADATA = {
    1:  {"image": "pot1-Asset-1@4.167x", "w": 276.0, "h": 195.0, "mount_y": 168.0, "hanging": False},
    2:  {"image": "Pot2-1@4.167x",        "w": 294.0, "h": 255.0, "mount_y": 222.0, "hanging": False},
    3:  {"image": "Pot3-1@4.167x",        "w": 308.0, "h": 260.0, "mount_y": 228.0, "hanging": False},
    4:  {"image": "Pot4@4.167x",          "w": 302.0, "h": 263.0, "mount_y": 230.0, "hanging": False},
    5:  {"image": "pot5@4.167x",          "w": 285.0, "h": 235.0, "mount_y": 204.0, "hanging": False},
    6:  {"image": "Pot6@4.167x",          "w": 361.0, "h": 207.0, "mount_y": 178.0, "hanging": False},
    7:  {"image": "Pot7@4.167x",          "w": 266.0, "h": 211.0, "mount_y": 184.0, "hanging": False},
    8:  {"image": "pot8@4.167x",          "w": 216.0, "h": 225.0, "mount_y": 208.0, "hanging": False},
    9:  {"image": "pot9@4.167x",          "w": 339.0, "h": 272.0, "mount_y": 240.0, "hanging": False},
    10: {"image": "Pot10-1@4.167x",       "w": 336.0, "h": 340.0, "mount_y": 298.0, "hanging": False},
    11: {"image": "pot11@4.167x",         "w": 226.0, "h": 244.0, "mount_y": 212.0, "hanging": True},
    12: {"image": "Pot12@4.167x",         "w": 213.0, "h": 216.0, "mount_y": 188.0, "hanging": False},
    13: {"image": "Pot13@4.167x",         "w": 214.0, "h": 276.0, "mount_y": 205.0, "hanging": False},
    14: {"image": "Pot14@4.167x",         "w": 203.0, "h": 179.0, "mount_y": 156.0, "hanging": False},
}

def generate_pot_scene(pot_id, meta):
    with open(BASE_SKS, "rb") as f:
        pl = plistlib.load(f)

    objs = pl["$objects"]

    def add_obj(val):
        objs.append(val)
        return plistlib.UID(len(objs) - 1)

    root = objs[1]
    w = meta["w"]
    h = meta["h"]
    mount_y = meta["mount_y"]
    is_hanging = meta["hanging"]

    # 1. Update Scene bounds
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{w}, {h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-w/2}, 0}}, {{{w}, {h}}}}}"

    # Anchor point = (0.5, 0.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0}"

    # 2. Clone seedSprite to make potNode (SKSpriteNode)
    # Trong Plant1Scene.sks: index 19 là seedSprite
    pot_node = copy.deepcopy(objs[19])
    pot_name_uid = add_obj("potNode")
    pot_node["_name"] = pot_name_uid

    # Position = (0, 0)
    pos_val_uid = add_obj("{0, 0}")
    pos_obj_uid = add_obj({"NS.pointval": pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
    pot_node["_position"] = pos_obj_uid

    # Anchor = (0.5, 0.0)
    anchor_val_uid = add_obj("{0.5, 0}")
    anchor_obj_uid = add_obj({"NS.pointval": anchor_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
    pot_node["_anchorPoint"] = anchor_obj_uid

    # Bounds = {{-w/2, 0}, {w, h}}
    bounds_val_uid = add_obj(f"{{{{{-w/2}, 0}}, {{{w}, {h}}}}}")
    bounds_obj_uid = add_obj({"NS.rectval": bounds_val_uid, "$class": plistlib.UID(5), "NS.special": 3})
    pot_node["_bounds"] = bounds_obj_uid

    # zPosition = 50.0 (Mặt trước chậu)
    zpos_uid = add_obj(50.0)
    pot_node["_zPosition"] = zpos_uid

    # Texture
    tex_obj = copy.deepcopy(objs[pot_node["_texture"].data])
    img_name_uid = add_obj(meta["image"])
    tex_obj["_imgName"] = img_name_uid
    tex_size_val_uid = add_obj(f"{{{w}, {h}}}")
    tex_size_uid = add_obj({"NS.sizeval": tex_size_val_uid, "$class": plistlib.UID(5), "NS.special": 2})
    tex_obj["_size"] = tex_size_uid
    tex_obj["_pixelSize"] = tex_size_uid
    tex_uid = add_obj(tex_obj)
    pot_node["_texture"] = tex_uid
    pot_node_uid = add_obj(pot_node)

    # 3. Clone seedNode to make plantMount (SKNode)
    # Trong Plant1Scene.sks: index 15 là seedNode
    mount_node = copy.deepcopy(objs[15])
    mount_name_uid = add_obj("plantMount")
    mount_node["_name"] = mount_name_uid
    mount_pos_val_uid = add_obj(f"{{0, {mount_y}}}")
    mount_pos_obj_uid = add_obj({"NS.pointval": mount_pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
    mount_node["_position"] = mount_pos_obj_uid
    mount_zpos_uid = add_obj(10.0)
    mount_node["_zPosition"] = mount_zpos_uid
    mount_children_uid = add_obj({"NS.objects": [], "$class": plistlib.UID(25)})
    mount_node["_children"] = mount_children_uid
    mount_node_uid = add_obj(mount_node)

    # 4. Gắn vào root children: plantMount xếp trước (z=10), potNode xếp sau (z=50) để plantMount nằm SAU chậu
    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [mount_node_uid, pot_node_uid]

    out_dir = os.path.join(POTS_DIR, f"Pot{pot_id}")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, f"Pot{pot_id}Scene.sks")

    with open(out_file, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    print(f"✅ Đã tạo Pot{pot_id}Scene.sks ({w}x{h}, mountY={mount_y}) -> {out_file}")

if __name__ == "__main__":
    for i in range(1, 15):
        generate_pot_scene(i, POTS_METADATA[i])

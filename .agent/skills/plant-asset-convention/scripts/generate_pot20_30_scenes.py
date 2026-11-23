#!/usr/bin/env python3
"""
Script tự động sinh các file Scene trực quan PotXScene.sks cho Pot20 -> Pot30
trong Terrarium Idle iOS.
Mỗi file .sks chứa:
1. potNode (SKSpriteNode): Thân chậu gán texture thật từ Assets.xcassets, zPos = 50
2. plantMount (SKNode): Socket điểm cắm cây, zPos = 10
"""

import os
import copy
import plistlib
import subprocess

WORKSPACE_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
BASE_SKS = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants/Plant1/Plant1Scene.sks")
POTS_DIR = os.path.join(WORKSPACE_ROOT, "terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Pots")

POTS_METADATA = {
    20: {"image": "Pot20-1@4.167x",  "w": 242.0,  "h": 233.0,  "mount_y": 192.0, "hanging": False},
    21: {"image": "Pot21-1@4.167x",  "w": 277.0,  "h": 267.0,  "mount_y": 224.0, "hanging": False},
    22: {"image": "Pot22-1@4.167x",  "w": 335.0,  "h": 290.0,  "mount_y": 230.0, "hanging": False},
    23: {"image": "Pot23-1@4.167x",  "w": 321.0,  "h": 325.0,  "mount_y": 264.0, "hanging": False},
    24: {"image": "Pot24-2@4.167x",  "w": 403.0,  "h": 354.0,  "mount_y": 318.0, "hanging": False},
    25: {"image": "Pot25-13@4.167x", "w": 439.0,  "h": 537.0,  "mount_y": 483.0, "hanging": False},
    26: {"image": "Pot26-1@4.167x",  "w": 304.0,  "h": 327.0,  "mount_y": 294.0, "hanging": False},
    27: {"image": "Pot27-1@4.167x",  "w": 226.0,  "h": 306.0,  "mount_y": 259.0, "hanging": False},
    28: {"image": "Pot28-1@4.167x",  "w": 1600.0, "h": 1509.0, "mount_y": 1358.0,"hanging": False},
    29: {"image": "Pot29@4.167x",    "w": 498.0,  "h": 724.0,  "mount_y": 651.0, "hanging": False},
    30: {"image": "Pot30-1@4.167x",  "w": 153.0,  "h": 360.0,  "mount_y": 324.0, "hanging": False},
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

    # 1. Update Scene bounds
    root_bounds_uid = root["Scene_bounds"].data
    objs[objs[root_bounds_uid]["NS.rectval"].data] = f"{{{{0, 0}}, {{{w}, {h}}}}}"

    root_vis_uid = root["_visibleRect"].data
    objs[objs[root_vis_uid]["NS.rectval"].data] = f"{{{{{-w/2}, 0}}, {{{w}, {h}}}}}"

    # Anchor point = (0.5, 0.0)
    anchor_uid = root["_anchorPoint"].data
    objs[objs[anchor_uid]["NS.pointval"].data] = "{0.5, 0}"

    # 2. Clone seedSprite to make potNode (SKSpriteNode)
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
    mount_node = copy.deepcopy(objs[15])
    mount_name_uid = add_obj("plantMount")
    mount_node["_name"] = mount_name_uid
    mount_pos_val_uid = add_obj(f"{{0, {mount_y}}}")
    mount_pos_obj_uid = add_obj({"NS.pointval": mount_pos_val_uid, "$class": plistlib.UID(5), "NS.special": 1})
    mount_node["_position"] = mount_pos_obj_uid
    mount_zpos_uid = add_obj(10.0)
    mount_node["_zPosition"] = mount_zpos_uid
    mount_node["_hidden"] = plistlib.UID(26)
    mount_children_uid = add_obj({"NS.objects": [], "$class": plistlib.UID(25)})
    mount_node["_children"] = mount_children_uid
    mount_node_uid = add_obj(mount_node)

    # 4. Gắn vào root children
    root_children_uid = root["_children"].data
    objs[root_children_uid]["NS.objects"] = [mount_node_uid, pot_node_uid]

    out_dir = os.path.join(POTS_DIR, f"Pot{pot_id}")
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"Pot{pot_id}Scene.sks")

    with open(out_path, "wb") as f:
        plistlib.dump(pl, f, fmt=plistlib.FMT_BINARY)

    # Lint check
    res = subprocess.run(["plutil", "-lint", out_path], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"✅ Generated Pot{pot_id}Scene.sks ({w}x{h}, mount_y={mount_y}, tex={meta['image']})")
    else:
        print(f"❌ Error linting Pot{pot_id}Scene.sks: {res.stderr}")

def main():
    print("🌿 Generating Pot20..Pot30 Scenes...")
    for pot_id, meta in sorted(POTS_METADATA.items()):
        generate_pot_scene(pot_id, meta)
    print("🎉 All Pot scenes generated successfully!")

if __name__ == "__main__":
    main()

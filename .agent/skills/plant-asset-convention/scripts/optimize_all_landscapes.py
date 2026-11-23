#!/usr/bin/env python3
"""
Script tối ưu hoá bộ nhớ VRAM toàn diện cho tất cả các Landscape (1, 2, 3, 4, 5, 7)
Nguyên tắc:
- Giữ nguyên tỉ lệ khung hình (aspect ratio) 100% không biến dạng.
- Giới hạn kích thước tối đa về ngưỡng chuẩn Retina di động (750 - 1000px).
- Giảm VRAM từ ~515MB xuống dưới ~85MB.
"""

import os
import subprocess

WORKSPACE = "/Users/vuongquanghuy/code/prj_ios/terrariumidle_ios"
LANDSCAPES_DIR = os.path.join(WORKSPACE, "terrariumidle_ios/Assets.xcassets/Landscapes")

CONFIGS = {
    "landscape1": {"max_w": 750, "max_h": 1334},
    "landscape2": {"max_w": 750, "max_h": 1334},
    "landscape3": {"max_w": 750, "max_h": 1334},
    "landscape4": {"max_w": 750, "max_h": 1334},
    "landscape5": {"max_w": 1000, "max_h": 1334},
    "landscape7": {"max_w": 1000, "max_h": 1500},
}

def optimize_landscapes():
    total_saved_vram = 0

    for land, bounds in CONFIGS.items():
        folder = os.path.join(LANDSCAPES_DIR, land)
        if not os.path.isdir(folder):
            continue

        max_w = bounds["max_w"]
        max_h = bounds["max_h"]

        print(f"\n==========================================")
        print(f"Đang tối ưu: {land} (Ngưỡng max: {max_w}x{max_h})")
        print(f"==========================================")

        for root, dirs, files in sorted(os.walk(folder)):
            for f in sorted(files):
                if f.endswith(".png"):
                    path = os.path.join(root, f)
                    out = subprocess.check_output(["sips", "-g", "pixelWidth", "-g", "pixelHeight", path]).decode()
                    w = int(out.split("pixelWidth: ")[1].split("\n")[0])
                    h = int(out.split("pixelHeight: ")[1].split("\n")[0])

                    if w > max_w or h > max_h:
                        scale = min(max_w / w, max_h / h)
                        new_w = round(w * scale)
                        new_h = round(h * scale)
                        orig_vram = (w * h * 4) / (1024 * 1024)
                        new_vram = (new_w * new_h * 4) / (1024 * 1024)
                        saved = orig_vram - new_vram
                        total_saved_vram += saved

                        print(f"  -> {f}: {w}x{h} ({orig_vram:.1f}MB) => {new_w}x{new_h} ({new_vram:.1f}MB, tiết kiệm {saved:.1f}MB)")
                        if w / max_w >= h / max_h:
                            subprocess.check_call(["sips", "--resampleWidth", str(new_w), path], stdout=subprocess.DEVNULL)
                        else:
                            subprocess.check_call(["sips", "--resampleHeight", str(new_h), path], stdout=subprocess.DEVNULL)

    print(f"\n>>> HOÀN TẤT TỐI ƯU HÓA! Tổng VRAM tiết kiệm được: ~{total_saved_vram:.1f} MB <<<")

if __name__ == "__main__":
    optimize_landscapes()

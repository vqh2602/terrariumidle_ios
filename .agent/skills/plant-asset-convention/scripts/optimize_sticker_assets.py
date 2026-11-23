#!/usr/bin/env python3
"""Audit sticker texture budgets; --apply resizes PNGs and normalizes SKS metadata.

Sticker scenes use small logical design coordinates, independent of export pixels.
Keep their geometry and Swift fallback unchanged when only reducing texture pixels.
"""
import argparse
import math
from pathlib import Path
import subprocess

from optimize_plant_assets import ROOT, Scene, numbers, png_size

STICKERS = ROOT / 'terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Stickers'
ASSETS = ROOT / 'terrariumidle_ios/Assets.xcassets/Stickers'
MAX_TEXTURE_EDGE = 768
MAX_SCENE_MIB = 4.0
TARGET_SCENE_MIB = 3.75
MAX_CANVAS_EDGE = 512


def asset_index():
    return {p.parent.stem: p for p in ASSETS.rglob('*.png')}


def optimize_sticker(sid, apply=False, scene_path=None, assets=None):
    assets = asset_index() if assets is None else assets
    path = Path(scene_path) if scene_path else STICKERS / f'Sticker{sid}/Sticker{sid}Scene.sks'
    scene = Scene(path)
    textures = scene.textures()
    if not textures:
        raise ValueError(f'Sticker{sid}: no real textures in scene')
    missing = textures.keys() - assets.keys()
    if missing:
        raise ValueError(f'Sticker{sid}: missing assets {sorted(missing)}')
    names = set(textures)
    sizes = [png_size(assets[name]) for name in names]
    before = sum(w*h*4 for w,h in sizes) / 1048576
    scale = min(1.0, MAX_TEXTURE_EDGE / max(max(s) for s in sizes))
    if before > MAX_SCENE_MIB:
        scale = min(scale, math.sqrt(TARGET_SCENE_MIB / before))
    if scale > 1 - 1e-7:
        scale = 1.0
    folder = ASSETS / f'sticker{sid}'
    images = sorted(folder.rglob('*.png'))
    if not images:
        raise ValueError(f'Sticker{sid}: no PNGs in {folder}')
    if any(not assets[name].is_relative_to(folder) for name in names):
        raise ValueError(f'Sticker{sid}: copy shared layers to its own assets before optimizing')
    oversized = [p for p in images if max(png_size(p)) > MAX_TEXTURE_EDGE]
    stale = sum(tuple(numbers(scene.value(texture, key, 'NS.sizeval'))) != png_size(assets[name])
                for name, texture in textures.items() for key in ('_size','_pixelSize'))
    canvas = scene.canvas()
    too_large_canvas = max(canvas) > MAX_CANVAS_EDGE
    preview_mismatch = scene.preview() != canvas
    disk_before = sum(p.stat().st_size for p in images)
    if apply:
        if too_large_canvas:
            raise ValueError(f'Sticker{sid}: logical canvas exceeds {MAX_CANVAS_EDGE}; normalize scene and Swift geometry together first')
        # Keep aliases/thumbnail names compatible. Resize all layers with one common factor;
        # cap unused full-size thumbnails separately, preserving alpha and aspect ratio.
        for image in images:
            w,h = png_size(image)
            factor = min(scale, MAX_TEXTURE_EDGE / max(w,h))
            if factor < 1:
                nw,nh = max(1,round(w*factor)),max(1,round(h*factor))
                subprocess.run(['sips','--resampleHeightWidth',str(nh),str(nw),str(image)],
                               check=True,stdout=subprocess.DEVNULL)
        scene.normalize(1.0, assets)
        encoded = scene.encoded()
        if encoded != path.read_bytes():
            path.write_bytes(encoded)
    after = sum(png_size(assets[n])[0]*png_size(assets[n])[1]*4 for n in names)/1048576
    if apply and (after > MAX_SCENE_MIB or any(max(png_size(p)) > MAX_TEXTURE_EDGE for p in images)):
        raise ValueError(f'Sticker{sid}: limits exceeded after normalization')
    return dict(sticker=sid,before_mib=before,after_mib=after,scale=scale,
                disk_before=disk_before,disk_after=sum(p.stat().st_size for p in images),
                needs_fix=bool(scale<1 or oversized or stale or too_large_canvas or preview_mismatch))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sticker',type=int,action='append',help='Repeat to select IDs; default all')
    parser.add_argument('--apply',action='store_true')
    parser.add_argument('--check',action='store_true')
    args = parser.parse_args()
    ids = args.sticker or sorted(int(p.parent.name.removeprefix('Sticker'))
                                 for p in STICKERS.glob('Sticker*/Sticker*Scene.sks'))
    failed = False
    for sid in ids:
        report = optimize_sticker(sid,apply=args.apply)
        print(f"Sticker{sid}: {report['before_mib']:.2f} -> {report['after_mib']:.2f} MiB; texture scale={report['scale']:.6f}")
        failed |= optimize_sticker(sid)['needs_fix'] if args.apply else report['needs_fix']
    if args.check and failed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()

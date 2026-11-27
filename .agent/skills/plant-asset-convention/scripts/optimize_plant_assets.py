#!/usr/bin/env python3
"""Audit or normalize plant PNGs, keyed scenes and Swift geometry without building.

Default: read-only audit. Use --apply to resize, or --check for a CI-friendly gate.
Only rescale a plant when its geometry/texture budget exceeds the limits.
"""
import argparse
import json
import math
from pathlib import Path
import plistlib
import re
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[4]
PLANTS = ROOT / 'terrariumidle_ios/Apps/Compoments/SpriteKitComponents/Plants'
ASSETS = ROOT / 'terrariumidle_ios/Assets.xcassets/Plants'
MAX_CANVAS_EDGE = 1024
MAX_TEXTURE_EDGE = 768
MAX_MATURE_MIB = 4.0
TARGET_MATURE_MIB = 3.75  # Leave room for integer pixel rounding.
NUMBER = r'-?\d+(?:\.\d+)?'


def png_size(path):
    with Path(path).open('rb') as stream:
        header = stream.read(24)
    if header[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError(f'Not a PNG: {path}')
    return struct.unpack('>II', header[16:24])


def numbers(text):
    return [float(x) for x in re.findall(NUMBER, text)]


class Scene:
    def __init__(self, path):
        self.path = path
        self.data = plistlib.loads(path.read_bytes())
        self.objects = self.data['$objects']
        self.root = self.get(self.data['$top']['root'])

    def get(self, value):
        return self.objects[value.data] if isinstance(value, plistlib.UID) else value

    def add(self, value):
        self.objects.append(value)
        return plistlib.UID(len(self.objects) - 1)

    def value(self, node, key, field):
        return self.get(self.get(node[key])[field])

    def set_value(self, node, key, field, value):
        if self.value(node, key, field) == value:
            return
        entry = dict(self.get(node[key]))
        entry[field] = self.add(value)
        node[key] = self.add(entry)

    def children(self, node):
        array = self.get(node.get('_children'))
        return array.get('NS.objects', []) if isinstance(array, dict) else []

    def nodes(self, start=None):
        start = self.root if start is None else start
        yield start
        for uid in self.children(start):
            yield from self.nodes(self.get(uid))

    def textures(self, start=None):
        result = {}
        for node in self.nodes(start):
            texture = self.get(node.get('_texture'))
            if isinstance(texture, dict) and '_imgName' in texture:
                result[self.get(texture['_imgName'])] = texture
        return result

    def canvas(self):
        return numbers(self.value(self.root, 'Scene_bounds', 'NS.rectval'))[-2:]

    def mature_textures(self):
        mature = next((n for n in self.nodes() if self.get(n.get('_name')) == 'matureNode'), None)
        if mature is None:
            raise ValueError(f'Missing matureNode: {self.path}')
        return self.textures(mature)

    def preview(self):
        info = self.get(self.root.get('_info'))
        if not isinstance(info, dict):
            return None
        entries = {self.get(k): self.get(v) for k, v in zip(info['NS.keys'], info['NS.objects'])}
        return [entries.get('_PB_previewSKEditorSceneSizeWidth'), entries.get('_PB_previewSKEditorSceneSizeHeight')]

    def normalize(self, scale, assets):
        for node in list(self.nodes()):
            if scale < 1:
                for key, field in (('_position', 'NS.pointval'), ('_bounds', 'NS.rectval'),
                                   ('Scene_bounds', 'NS.rectval'), ('_visibleRect', 'NS.rectval')):
                    if key in node:
                        old = self.value(node, key, field)
                        new = re.sub(NUMBER, lambda m: f'{float(m[0]) * scale:.9f}', old)
                        self.set_value(node, key, field, new)
            texture = self.get(node.get('_texture'))
            if isinstance(texture, dict) and '_imgName' in texture:
                name = self.get(texture['_imgName'])
                if name not in assets:
                    raise ValueError(f'Missing texture {name} in {self.path}')
                w, h = png_size(assets[name])
                for key in ('_size', '_pixelSize'):
                    self.set_value(texture, key, 'NS.sizeval', f'{{{w}, {h}}}')
        width, height = self.canvas()
        info = self.get(self.root.get('_info'))
        if not isinstance(info, dict):
            # Scene templates expect _info to be an NSMutableDictionary for Xcode Scene Editor.
            mutable_cls = next(
                (plistlib.UID(i)
                 for i, x in enumerate(self.objects)
                 if isinstance(x, dict) and x.get('$classname') == 'NSMutableDictionary'),
                None,
            )
            if mutable_cls is None:
                mutable_cls = self.add({
                    '$classname': 'NSMutableDictionary',
                    '$classes': ['NSMutableDictionary', 'NSDictionary', 'NSObject'],
                })
            info = {'$class': mutable_cls, 'NS.keys': [], 'NS.objects': []}
            self.root['_info'] = self.add(info)
        for name, value in (('_PB_previewSKEditorSceneSizeWidth', width),
                            ('_PB_previewSKEditorSceneSizeHeight', height)):
            keys = [self.get(x) for x in info['NS.keys']]
            if name in keys:
                index = keys.index(name)
                if self.get(info['NS.objects'][index]) != value:
                    info['NS.objects'][index] = self.add(value)
            else:
                info['NS.keys'].append(self.add(name))
                info['NS.objects'].append(self.add(value))

    def encoded(self):
        # Keep the entire root-reachable object graph, including classes and physics objects.
        seen = set()
        def mark(value):
            if isinstance(value, plistlib.UID):
                if value.data not in seen:
                    seen.add(value.data)
                    mark(self.get(value))
            elif isinstance(value, dict):
                for v in value.values(): mark(v)
            elif isinstance(value, list):
                for v in value: mark(v)
        mark(self.data['$top'])
        indices = sorted(seen)
        mapping = {old: new for new, old in enumerate(indices)}
        def remap(value):
            if isinstance(value, plistlib.UID): return plistlib.UID(mapping[value.data])
            if isinstance(value, dict): return {k: remap(v) for k, v in value.items()}
            if isinstance(value, list): return [remap(v) for v in value]
            return value
        result = {k: remap(v) for k, v in self.data.items() if k != '$objects'}
        result['$objects'] = [remap(self.objects[i]) for i in indices]
        return plistlib.dumps(result, fmt=plistlib.FMT_BINARY, sort_keys=False)


def asset_index():
    return {p.parent.stem: p for p in ASSETS.rglob('*.png')}


def swift_scaled(text, scale):
    # Preserve all animation choices/manual edits; change design-space lengths only.
    text = re.sub(r'(Canvas\s+)(' + NUMBER + r')(\s*x\s*)(' + NUMBER + ')',
                  lambda m: m[1] + f'{float(m[2]) * scale:.3f}' + m[3] + f'{float(m[4]) * scale:.3f}', text)
    count = 0
    def canvas(match):
        nonlocal count
        count += 1
        return match[1] + f'{float(match[2]) * scale:.9f}'
    text = re.sub(r'(let baseCanvas(?:W|H|Width|Height):\s*CGFloat\s*=\s*)(' + NUMBER + ')', canvas, text)
    if count != 6:
        raise ValueError(f'Expected canvas dimensions for all 3 states; found {count}')
    a = text.index('private static let leavesMetadata:')
    b = text.index('\n    ]', a)
    metadata = re.sub(r'((?:imgX|imgY|width|height):\s*)(' + NUMBER + ')',
                      lambda m: m[1] + f'{float(m[2]) * scale:.9f}', text[a:b])
    text = text[:a] + metadata + text[b:]
    a = text.index('private func buildSeedState()')
    # Only literal position/size assignments in state code are design-space lengths.
    tail = text[a:]
    lines = []
    for line in tail.splitlines(keepends=True):
        if re.search(r'\.position\s*=\s*CGPoint\(|\.size\s*=\s*CGSize\(', line):
            line = re.sub(r'((?:x|y|width|height):\s*)(' + NUMBER + r')(?=\s*[,\)])',
                          lambda m: m[1] + f'{float(m[2]) * scale:.9f}', line)
        lines.append(line)
    return text[:a] + ''.join(lines)


def optimize_plant(pid, apply=False, assets=None):
    assets = asset_index() if assets is None else assets
    path = PLANTS / f'Plant{pid}/Plant{pid}Scene.sks'
    scene = Scene(path)
    names = scene.mature_textures()
    missing = set(scene.textures()) - assets.keys()
    if missing: raise ValueError(f'Plant{pid}: missing assets {sorted(missing)}')
    sizes = [png_size(assets[name]) for name in names]
    before = sum(w*h*4 for w,h in sizes) / 1048576
    edge = max(max(s) for s in sizes)
    canvas = scene.canvas()
    scale = min(1.0, MAX_CANVAS_EDGE / max(canvas), MAX_TEXTURE_EDGE / edge)
    if before > MAX_MATURE_MIB:
        scale = min(scale, math.sqrt(TARGET_MATURE_MIB / before))
    # Avoid repeated resampling from insignificant binary floating-point roundoff.
    if scale > 1 - 1e-7: scale = 1.0
    mismatch = scene.preview() != canvas
    folder = ASSETS / f'plant{pid}'
    local_images = list(folder.rglob('*.png'))
    oversized = [str(p) for p in local_images if max(png_size(p)) > MAX_CANVAS_EDGE]
    stale = 0
    for name, texture in scene.textures().items():
        for key in ('_size', '_pixelSize'):
            stale += tuple(numbers(scene.value(texture, key, 'NS.sizeval'))) != png_size(assets[name])
    report = {'plant': pid, 'before_mib': before, 'scale': scale,
              'preview_repaired': mismatch, 'oversized_images': oversized,
              'stale_texture_sizes': stale}
    if apply:
        swift_path = path.with_name(f'Plant{pid}Node.swift')
        source = swift_path.read_text() if scale < 1 else None
        if source is not None:
            heights = re.findall(r'let baseCanvas(?:H|Height):\s*CGFloat\s*=\s*(' + NUMBER + ')', source)
            if len(heights) != 3 or any(abs(float(h) - canvas[1]) > 0.01 for h in heights):
                raise ValueError(f'Plant{pid}: scene/Swift canvas mismatch; regenerate both from the same source before scaling')
        swift = swift_scaled(source, scale) if source is not None else None
        if scale < 1 and any(not assets[name].is_relative_to(folder) for name in names):
            raise ValueError(f'Plant{pid}: copy shared mature textures into its own assets before scaling')
        for image in local_images:
            w,h = png_size(image)
            image_scale = min(scale, MAX_CANVAS_EDGE / max(w,h))
            if image_scale < 1:
                nw,nh = max(1,round(w*image_scale)),max(1,round(h*image_scale))
                subprocess.run(['sips','--resampleHeightWidth',str(nh),str(nw),str(image)],
                               check=True, stdout=subprocess.DEVNULL)
        scene.normalize(scale, assets)
        encoded = scene.encoded()
        if encoded != path.read_bytes(): path.write_bytes(encoded)
        if swift is not None: swift_path.write_text(swift)
    report['after_mib'] = sum(png_size(assets[n])[0]*png_size(assets[n])[1]*4 for n in names) / 1048576
    if apply and (report['after_mib'] > MAX_MATURE_MIB or
                  max(max(png_size(assets[n])) for n in names) > MAX_TEXTURE_EDGE):
        raise ValueError(f'Plant{pid} still exceeds texture limits after normalization')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plant', type=int, action='append', help='Repeat to select plant IDs; default all')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    assets = asset_index()
    ids = args.plant or sorted(int(re.search(r'Plant(\d+)',p.name)[1]) for p in PLANTS.glob('Plant*/Plant*Scene.sks'))
    failed = False
    for pid in ids:
        r = optimize_plant(pid, apply=args.apply, assets=assets)
        print(f"Plant{pid}: {r['before_mib']:.2f} -> {r['after_mib']:.2f} MiB; scale={r['scale']:.6f}; preview repair={r['preview_repaired']}")
        failed |= (r['scale'] < 1 or r['preview_repaired'] or
                   bool(r['oversized_images']) or bool(r['stale_texture_sizes']))
    if args.check and failed: raise SystemExit(1)


if __name__ == '__main__': main()

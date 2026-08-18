#!/usr/bin/env python3
"""
Export a .jm world to PNGs you can paint over in a pixel art tool.

The engine is tile based: the world is a grid of 8x8 pixel ground tiles taken
from an atlas (see Ground.xml -> <File>/<Index> and AssetLoader.addImageSet).
This script renders that grid out at 8px per tile, so one image pixel is one
map pixel and you can simply paint on it. map_import.py turns it back into a
.jm plus a generated tile atlas.

Outputs (next to the .jm, into --out):
  <name>_ground.png    the paintable layer - current ground, 8px per tile
  <name>_objects.png   objects/walls drawn on top, as a reference overlay
  <name>_guide.png     ground + objects + tile grid, for orientation only

Only <name>_ground.png is used on import. The other two are references.

  python dev/map_export.py source/Shared/resources/worlds/nexus.jm
"""

import argparse
import base64
import glob
import io
import json
import os
import re
import struct
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("Pillow missing.  python -m pip install Pillow")

TILE = 8
CLIENT = os.path.join("client", "src")
XMLS = os.path.join(CLIENT, "kabam", "rotmg", "assets", "prod", "xmls")
ASSETS = os.path.join(CLIENT, "kabam", "rotmg", "assets")


# ------------------------------------------------------------------ assets


def load_image_sets(root):
    """name -> (PIL image, cellW, cellH), mirroring AssetLoader.addImageSet."""
    al = io.open(os.path.join(root, CLIENT, "com", "company", "assembleegameclient",
                              "util", "AssetLoader.as"), encoding="utf-8-sig").read()
    ea = io.open(os.path.join(root, ASSETS, "EmbeddedAssets.as"), encoding="utf-8-sig").read()

    embed_path = {}
    for src, var in re.findall(r'\[Embed\(source="([^"]+)"\)\]\s*public static (?:var|const)\s+(\w+)\s*:', ea):
        embed_path[var] = src
    # custom images are plain classes: `public static var x:Class = Foo;`
    for var, cls in re.findall(r'public static var (\w+)\s*:\s*Class\s*=\s*(\w+)\s*;', ea):
        cls_file = os.path.join(root, ASSETS, "custom", "images", cls + ".as")
        if os.path.exists(cls_file):
            m = re.search(r'\[Embed\(source="([^"]+)"\)\]',
                          io.open(cls_file, encoding="utf-8-sig").read())
            if m:
                embed_path[var] = os.path.join("custom", "images", m.group(1))

    sets = {}
    for m in re.finditer(r'addImageSet\("([^"]+)",\s*new EmbeddedAssets\.(\w+)\(\)\.bitmapData,\s*(\d+),\s*(\d+)\)', al):
        name, var, cw, ch = m.group(1), m.group(2), int(m.group(3)), int(m.group(4))
        rel = embed_path.get(var)
        if not rel:
            continue
        path = os.path.join(root, ASSETS, rel.replace("/", os.sep))
        if os.path.exists(path):
            sets[name] = (Image.open(path).convert("RGBA"), cw, ch)
    return sets


def load_ground_textures(root):
    """ground id -> (type, file, index)"""
    out = {}
    for p in glob.glob(os.path.join(root, XMLS, "*round*.xml")):
        s = io.open(p, encoding="latin-1").read()
        for m in re.finditer(r'<Ground type="(0x[0-9a-fA-F]+)" id="([^"]+)">(.*?)</Ground>', s, re.S):
            t, gid, body = m.group(1), m.group(2), m.group(3)
            f = re.search(r"<File>([^<]+)</File>", body)
            i = re.search(r"<Index>([^<]+)</Index>", body)
            if f and i:
                out[gid] = (int(t, 16), f.group(1).strip(), int(i.group(1).strip(), 16))
    return out


def tile_image(sets, file_name, index):
    entry = sets.get(file_name)
    if entry is None:
        return None
    sheet, cw, ch = entry
    cols = sheet.width // cw
    if cols == 0:
        return None
    x, y = (index % cols) * cw, (index // cols) * ch
    if y + ch > sheet.height:
        return None
    img = sheet.crop((x, y, x + cw, y + ch))
    return img if (cw, ch) == (TILE, TILE) else img.resize((TILE, TILE), Image.BOX)


# --------------------------------------------------------------------- jm


def read_jm(path):
    d = json.load(io.open(path, encoding="utf-8"))
    w, h = d["width"], d["height"]
    raw = zlib_decompress(base64.b64decode(d["data"]))
    idx = struct.unpack(">%dH" % (w * h), raw)
    return d, w, h, idx


def zlib_decompress(b):
    import zlib
    return zlib.decompress(b)


# ------------------------------------------------------------------ export


def export(root, jm_path, out_dir):
    sets = load_image_sets(root)
    ground_tex = load_ground_textures(root)
    d, w, h, idx = read_jm(jm_path)
    name = os.path.splitext(os.path.basename(jm_path))[0]

    ground = Image.new("RGBA", (w * TILE, h * TILE), (0, 0, 0, 255))
    objects = Image.new("RGBA", (w * TILE, h * TILE), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(objects)

    cache, missing, obj_count = {}, set(), 0
    for i, entry_idx in enumerate(idx):
        entry = d["dict"][entry_idx]
        tx, ty = (i % w) * TILE, (i // w) * TILE
        gid = entry.get("ground")
        if gid:
            if gid not in cache:
                info = ground_tex.get(gid)
                img = tile_image(sets, info[1], info[2]) if info else None
                if img is None:
                    missing.add(gid)
                cache[gid] = img
            img = cache[gid]
            if img is not None:
                ground.paste(img, (tx, ty))
        if entry.get("objs"):
            obj_count += 1
            odraw.rectangle([tx, ty, tx + TILE - 1, ty + TILE - 1],
                            fill=(255, 0, 255, 90), outline=(255, 0, 255, 220))

    os.makedirs(out_dir, exist_ok=True)
    gpath = os.path.join(out_dir, name + "_ground.png")
    opath = os.path.join(out_dir, name + "_objects.png")
    kpath = os.path.join(out_dir, name + "_guide.png")
    ground.convert("RGB").save(gpath)
    objects.save(opath)

    guide = ground.copy()
    guide.alpha_composite(objects)
    gd = ImageDraw.Draw(guide)
    for gx in range(0, w * TILE, TILE * 10):
        gd.line([(gx, 0), (gx, h * TILE)], fill=(255, 255, 255, 40))
    for gy in range(0, h * TILE, TILE * 10):
        gd.line([(0, gy), (w * TILE, gy)], fill=(255, 255, 255, 40))
    guide.convert("RGB").save(kpath)

    print(f"map        : {name}  {w}x{h} tiles  ->  {w*TILE}x{h*TILE} px")
    print(f"palette    : {len(d['dict'])} entries, {len(cache)} distinct grounds")
    print(f"object tiles: {obj_count}")
    if missing:
        print(f"WARNING: no texture for {len(missing)} ground id(s): {sorted(missing)[:8]}")
    print("wrote:")
    for p in (gpath, opath, kpath):
        print("   ", p)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("jm")
    ap.add_argument("--root", default=".")
    ap.add_argument("--out", default=os.path.join("dev", "mapart"))
    a = ap.parse_args()
    export(a.root, a.jm, a.out)


if __name__ == "__main__":
    main()

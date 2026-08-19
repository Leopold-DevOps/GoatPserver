#!/usr/bin/env python3
"""
Build a .jm world by painting flat colour regions, one pixel per tile.

This is the sibling of map_import.py, and the difference matters:

  map_import.py  paints *pixel art* and generates brand new ground tiles from
                 it. Fast, but the generated tiles are flat scenery - always
                 walkable, no animation, no edge blending.

  map_paint.py   paints *regions*, where each colour names a ground tile that
                 already exists in Ground.xml. You get the real tile, so water
                 animates, edges blend, and NoWalk tiles block movement.

That last point is easy to get wrong. Ground collision is real in this engine:
World.CalculateTilePosition and Entity check TileDesc.NoWalk, and tiles like
"Tropical Water Deep" are NoWalk. So deep water painted with this tool stops
players walking out to sea - a bridge becomes the only crossing - whereas a
generated tile of the same colour would not.

One image pixel is one map tile, so a 120x80 map is a 120x80 PNG. Paint it in
any pixel art tool with the bucket and pencil.

Usage:

  # 1. write a starter palette and a swatch image to pick colours from
  python dev/map_paint.py palette --out dev/mapart/beach

  # 2. paint dev/mapart/beach_map.png  (1px = 1 tile)

  # 3. build the world
  python dev/map_paint.py build dev/mapart/beach_map.png \\
        --palette dev/mapart/beach_palette.json \\
        --out "source/Shared/resources/worlds/Beach.jm"

  # keep objects from an existing world (walls, portals, NPCs)
  python dev/map_paint.py build painted.png --palette p.json \\
        --base source/Shared/resources/worlds/nexus.jm --out out.jm
"""

import argparse
import base64
import io
import json
import os
import re
import struct
import sys
import zlib

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow missing.  python -m pip install Pillow")

GROUND_XML = os.path.join("client", "src", "kabam", "rotmg", "assets",
                          "prod", "xmls", "Ground.xml")

# A reasonable beach/tavern starting palette. Every name here must exist in
# Ground.xml - "build" verifies that and refuses to write a broken world.
DEFAULT_PALETTE = {
    "#e8d8a0": "Sand Tile",
    "#d8c48c": "Sand Covered Tile",
    "#7fc9e8": "Shallow Water",
    "#2f6fb0": "Water",
    "#123a63": "Tropical Water Deep",
    "#8b5a2b": "Bridge",
    "#a06a33": "Wood Plank Floor",
    "#6b4423": "Wood Panel Floor",
    "#4a4a4a": "Dark Cobblestone",
    "#3f7d3f": "Grass",
}


# ----------------------------------------------------------------- helpers


def load_ground_names(root):
    """Every <Ground id="..."> in Ground.xml, and which of them are NoWalk."""
    path = os.path.join(root, GROUND_XML)
    if not os.path.isfile(path):
        sys.exit("Ground.xml not found at %s (run from the repo root, or pass --root)" % path)

    text = io.open(path, encoding="utf-8", errors="replace").read()
    names, nowalk = set(), set()
    for block in re.findall(r"<Ground\b.*?</Ground>", text, re.S):
        m = re.search(r'id="([^"]+)"', block)
        if not m:
            continue
        names.add(m.group(1))
        if "<NoWalk" in block:
            nowalk.add(m.group(1))
    return names, nowalk


def load_object_names(root):
    """Every object id the server can resolve, across prod and custom XMLs."""
    names = set()
    for sub in (os.path.join("client", "src", "kabam", "rotmg", "assets", "prod", "xmls"),
                os.path.join("client", "src", "kabam", "rotmg", "assets", "custom", "xmls")):
        folder = os.path.join(root, sub)
        if not os.path.isdir(folder):
            continue
        for name in os.listdir(folder):
            if not name.endswith(".xml"):
                continue
            text = io.open(os.path.join(folder, name), encoding="utf-8",
                           errors="replace").read()
            names.update(re.findall(r'<Object[^>]*\bid="([^"]+)"', text))
    return names


def norm_hex(value):
    value = value.strip().lower()
    if not value.startswith("#"):
        value = "#" + value
    return value


def hex_to_rgb(value):
    value = norm_hex(value).lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def write_jm(path, doc, w, h, idx):
    """Byte-identical framing to map_import.py: big-endian u16, zlib, base64."""
    doc["width"], doc["height"] = w, h
    doc["data"] = base64.b64encode(
        zlib.compress(struct.pack(">%dH" % (w * h), *idx), 9)).decode("ascii")
    io.open(path, "w", encoding="utf-8", newline="").write(
        json.dumps(doc, separators=(",", ":")))


def read_jm(path):
    doc = json.load(io.open(path, encoding="utf-8"))
    w, h = doc["width"], doc["height"]
    idx = struct.unpack(">%dH" % (w * h),
                        zlib.decompress(base64.b64decode(doc["data"])))
    return doc, w, h, list(idx)


# ---------------------------------------------------------------- palette


def cmd_palette(args):
    names, nowalk = load_ground_names(args.root)

    missing = [n for n in DEFAULT_PALETTE.values() if n not in names]
    if missing:
        print("warning: not in Ground.xml, dropping: %s" % ", ".join(missing))

    palette = {k: v for k, v in DEFAULT_PALETTE.items() if v in names}

    out_dir = os.path.dirname(args.out) or "."
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)

    json_path = args.out + "_palette.json"
    io.open(json_path, "w", encoding="utf-8").write(
        json.dumps(palette, indent=2, ensure_ascii=False))

    # A swatch strip: one 16x16 block per entry, to eyedrop from.
    swatch = Image.new("RGB", (16 * len(palette), 16), (0, 0, 0))
    for i, colour in enumerate(palette):
        for y in range(16):
            for x in range(16):
                swatch.putpixel((i * 16 + x, y), hex_to_rgb(colour))
    swatch_path = args.out + "_swatch.png"
    swatch.save(swatch_path)

    print("wrote %s" % json_path)
    print("wrote %s  (%d colours, eyedrop from this)" % (swatch_path, len(palette)))
    print()
    for colour, name in palette.items():
        print("  %s  %-24s %s" % (colour, name, "[NoWalk - blocks movement]"
                                  if name in nowalk else ""))
    print()
    print("Paint at 1 pixel per tile, then: map_paint.py build <png> --palette %s"
          % json_path)


# ------------------------------------------------------------------ build


def cmd_build(args):
    names, nowalk = load_ground_names(args.root)

    palette_raw = json.load(io.open(args.palette, encoding="utf-8"))
    palette = {}
    for colour, tile in palette_raw.items():
        if tile not in names:
            sys.exit("palette uses '%s', which is not a <Ground> in Ground.xml" % tile)
        palette[hex_to_rgb(colour)] = tile

    img = Image.open(args.png).convert("RGB")
    w, h = img.size
    pixels = img.load()

    # Optional second layer: objects (walls, portals, scenery) and regions
    # (notably Spawn, which is where players appear - a world without it
    # drops everyone at 0,0).
    obj_pixels, obj_palette = None, {}
    if args.objects:
        if not args.objpalette:
            sys.exit("--objects needs --objpalette")
        known_objects = load_object_names(args.root)
        for colour, name in json.load(io.open(args.objpalette, encoding="utf-8")).items():
            # A misspelled object id would otherwise sail through and only show
            # up as a missing prop in game, so fail loudly here instead.
            if not name.startswith("region:") and name not in known_objects:
                sys.exit("object palette uses '%s', which is not an <Object> "
                         "in any prod/custom XML" % name)
            obj_palette[hex_to_rgb(colour)] = name
        obj_img = Image.open(args.objects).convert("RGB")
        if obj_img.size != (w, h):
            sys.exit("--objects is %dx%d but the ground image is %dx%d"
                     % (obj_img.size[0], obj_img.size[1], w, h))
        obj_pixels = obj_img.load()

    # Start from an existing world to keep its objects, or a bare document.
    if args.base:
        base_doc, bw, bh, base_idx = read_jm(args.base)
        if (bw, bh) != (w, h):
            sys.exit("--base is %dx%d but the image is %dx%d; they must match"
                     % (bw, bh, w, h))
        base_dict = base_doc.get("dict", [])
    else:
        base_doc, base_idx, base_dict = {}, None, []

    # Build the dict lazily: one entry per (ground, carried-over objs/regions).
    entries, lookup, idx = [], {}, []
    unknown = {}

    for y in range(h):
        for x in range(w):
            rgb = pixels[x, y]
            tile = palette.get(rgb)
            if tile is None:
                unknown[rgb] = unknown.get(rgb, 0) + 1
                tile = args.fallback

            # carry objects/regions sitting on this cell in the base world
            extra = {}
            if base_idx is not None:
                src = base_dict[base_idx[y * w + x]] if base_idx[y * w + x] < len(base_dict) else {}
                for key in ("objs", "regions"):
                    if key in src:
                        extra[key] = src[key]

            # painted objects/regions win over anything carried from --base
            if obj_pixels is not None:
                name = obj_palette.get(obj_pixels[x, y])
                if name:
                    if name.startswith("region:"):
                        extra["regions"] = [{"id": name.split(":", 1)[1]}]
                    else:
                        extra["objs"] = [{"id": name}]

            key = (tile, json.dumps(extra, sort_keys=True))
            if key not in lookup:
                entry = {"ground": tile}
                entry.update(extra)
                lookup[key] = len(entries)
                entries.append(entry)
            idx.append(lookup[key])

    if unknown:
        print("unmapped colours (used %s):" % args.fallback)
        for rgb, count in sorted(unknown.items(), key=lambda kv: -kv[1])[:10]:
            print("  #%02x%02x%02x  %d tiles" % (rgb[0], rgb[1], rgb[2], count))
        if args.strict:
            sys.exit("refusing to write with unmapped colours (--strict)")

    doc = {"dict": entries}
    write_jm(args.out, doc, w, h, idx)

    used = sorted({e["ground"] for e in entries})
    blocking = [n for n in used if n in nowalk]
    carried = sum(1 for e in entries if "objs" in e or "regions" in e) if args.base else 0

    # Count cells, not dict entries: many cells share one entry, so entry
    # counts would report a 40-tile wall as "x1".
    placed, spawn_cells = {}, 0
    for cell in idx:
        entry = entries[cell]
        for obj in entry.get("objs", []):
            placed[obj["id"]] = placed.get(obj["id"], 0) + 1
        if any(r.get("id") == "Spawn" for r in entry.get("regions", [])):
            spawn_cells += 1

    print("wrote %s  %dx%d, %d dict entries" % (args.out, w, h, len(entries)))
    print("tiles used: %s" % ", ".join(used))
    if placed:
        print("objects: %s" % ", ".join("%s x%d" % kv for kv in sorted(placed.items())))
    print("spawn region: %s" % ("%d tiles" % spawn_cells if spawn_cells else
                                "MISSING - players will spawn at 0,0"))
    if blocking:
        print("blocking (NoWalk): %s" % ", ".join(blocking))
    else:
        print("note: no NoWalk tiles used - every tile is walkable")
    if carried:
        print("carried %d cells of objects/regions from --base" % carried)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="repo root")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("palette", help="write a starter palette + swatch")
    p.add_argument("--out", default=os.path.join("dev", "mapart", "map"))
    p.set_defaults(func=cmd_palette)

    b = sub.add_parser("build", help="painted png -> .jm")
    b.add_argument("png")
    b.add_argument("--palette", required=True)
    b.add_argument("--out", required=True)
    b.add_argument("--objects", help="second PNG: colours -> objects/regions")
    b.add_argument("--objpalette",
                   help="JSON colour -> object id, or 'region:Spawn'")
    b.add_argument("--base", help="existing .jm to carry objects/regions from")
    b.add_argument("--fallback", default="Grass",
                   help="tile for colours not in the palette")
    b.add_argument("--strict", action="store_true",
                   help="fail instead of falling back on unmapped colours")
    b.set_defaults(func=cmd_build)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

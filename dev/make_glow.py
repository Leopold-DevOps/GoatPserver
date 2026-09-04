#!/usr/bin/env python3
"""
Build a pulsing-glow animation sheet for an item, from its cell in
CustomUV128x128.png.

The glow is NOT a soft fade. It is a bounded halo whose RADIUS pulses while
its alpha stays fairly flat, because the icon pipeline is hostile to wide
soft gradients: TextureRedrawer runs every icon through GlowRedrawer's
outline pass, and a gradual alpha ramp picks up a dark fringe along its whole
falloff. A halo with a short edge behaves like an ordinary sprite instead.

Usage:

  python dev/make_glow.py 0x03 AdventurerSwordGlow
  python dev/make_glow.py 0x04 AdventurerHelmGlow --peak 6 --alpha 170

Tuning knobs, in the order you will actually want them:

  --peak   how far the halo reaches at its widest, in source px (default 6).
           This is what "too much glow" almost always means.
  --alpha  ceiling on halo opacity, 0-255 (default 170).
  --base   how far it reaches at its narrowest (default 2).
  --edge   softness of the halo's outer edge (default 2). Keep this small;
           see the note above about wide gradients.
"""

import argparse
import os

import numpy as np
from PIL import Image, ImageFilter

SHEET = "client/src/kabam/rotmg/assets/custom/images/CustomUV128x128.png"
OUT_DIR = "client/src/kabam/rotmg/assets/custom/images"
CELL = 128
CANVAS = 156
FRAMES = 12


def dilate(mask, radius):
    if radius <= 0:
        return mask
    return mask.filter(ImageFilter.MaxFilter(2 * int(round(radius)) + 1))


def build(cell_index, name, base_r, peak_r, edge, alpha_max):
    sheet = Image.open(SHEET).convert("RGBA")
    cx, cy = (cell_index % 16) * CELL, (cell_index // 16) * CELL
    art = sheet.crop((cx, cy, cx + CELL, cy + CELL))
    mask = Image.fromarray((np.asarray(art)[..., 3] > 10).astype(np.uint8) * 255, "L")

    off = (CANVAS - CELL) // 2
    out = Image.new("RGBA", (CANVAS * FRAMES, CANVAS), (0, 0, 0, 0))

    for i in range(FRAMES):
        t = 0.5 + 0.5 * np.sin(2 * np.pi * i / FRAMES)
        radius = base_r + (peak_r - base_r) * t

        grown = dilate(mask, radius)
        soft = grown.filter(ImageFilter.GaussianBlur(edge))
        halo_a = np.clip(np.asarray(soft).astype(float), 0, alpha_max)

        # brighter nearer the item, deeper blue toward the rim
        rim = np.asarray(dilate(mask, radius * 0.35)).astype(float) / 255.0
        halo = np.dstack([90 + 70 * rim, 150 + 60 * rim,
                          np.full_like(rim, 255.0), halo_a]).astype(np.uint8)

        frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        frame.alpha_composite(Image.fromarray(halo, "RGBA"), (off, off))
        frame.alpha_composite(art, (off, off))
        out.paste(frame, (i * CANVAS, 0))

    path = os.path.join(OUT_DIR, name + ".png")
    out.save(path)
    print(f"  {name}.png  cell 0x{cell_index:02x}  radius {base_r}-{peak_r}px  alpha<={alpha_max}")
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cell", help="cell index in CustomUV128x128, e.g. 0x03")
    ap.add_argument("name", help="output name, e.g. AdventurerSwordGlow")
    ap.add_argument("--base", type=float, default=2)
    ap.add_argument("--peak", type=float, default=6)
    ap.add_argument("--edge", type=float, default=2)
    ap.add_argument("--alpha", type=int, default=170)
    a = ap.parse_args()
    build(int(a.cell, 0), a.name, a.base, a.peak, a.edge, a.alpha)


if __name__ == "__main__":
    main()

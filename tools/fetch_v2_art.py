#!/usr/bin/env python3
"""Import Higgsfield-generated production art as real offline Godot PNG assets.

Downloads the original images only if the generated files are not already in
the repository. Converts chroma-green subjects and sprite atlases into
separate transparent, cropped character sprites. No generated art is fetched
at runtime by the Android application.
"""
import json
import time
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

BASE = Path(__file__).resolve().parents[1]
ASSETS = BASE / "assets"
MANIFEST = json.loads((ASSETS / "v2_art_manifest.json").read_text())
MAX_BYTES = 22_000_000

def fetch(url: str, name: str) -> Path:
    path = ASSETS / ("source_" + name + ".png")
    if path.is_file() and path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n":
        return path
    for trial in range(3):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (EchoesOfAether-art-build)"})
            with urllib.request.urlopen(req, timeout=90) as resp:
                blob = resp.read(MAX_BYTES + 1)
            if len(blob) > MAX_BYTES or not blob.startswith(b"\x89PNG\r\n\x1a\n"):
                raise ValueError("Art download is not a valid size-limited PNG")
            path.write_bytes(blob)
            return path
        except Exception:
            if trial == 2:
                raise
            time.sleep(3 * (trial + 1))
    raise RuntimeError(f"Could not download {name}")

def make_sprite(image: Image.Image) -> Image.Image:
    rgba = np.array(image.convert("RGBA"), dtype=np.uint8)
    rgb = rgba[:, :, :3].astype(np.int16)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    # Chroma green only: dark moss creature details are preserved.
    key = (g >= 140) & (g >= r * 1.38) & (g >= b * 1.38) & (r <= 120)
    # Don't retain a pale green fringe at the edges of the atlas.
    rgba[:, :, 3][key] = 0
    rgba[:, :, 0:3][key] = 0
    sprite = Image.fromarray(rgba, "RGBA")
    alpha = sprite.getchannel("A")
    bounds = alpha.getbbox()
    if not bounds:
        raise ValueError("Generated sprite is fully transparent; atlas crop invalid")
    sprite = sprite.crop(bounds)
    sprite.thumbnail((512, 512), Image.Resampling.LANCZOS)
    final = Image.new("RGBA", (sprite.width + 16, sprite.height + 16), (0, 0, 0, 0))
    final.alpha_composite(sprite, (8, 8))
    return final

def save_sprite(img: Image.Image, id: str) -> None:
    path = ASSETS / f"v2_{id}.png"
    if path.is_file():
        return
    sprite = make_sprite(img)
    sprite.save(path, optimize=True)
    print(f"PASS: {id} distinct transparent sprite = {sprite.width}x{sprite.height}", flush=True)

for item in MANIFEST["backgrounds"]:
    target = ASSETS / f"v2_{item['id']}.png"
    if not target.exists():
        source = fetch(item["url"], item["id"])
        bg = Image.open(source).convert("RGB")
        bg.thumbnail((1600, 900), Image.Resampling.LANCZOS)
        bg.save(target, optimize=True)
    print(f"PASS: {item['id']} environment integrated", flush=True)

for item in MANIFEST["individuals"]:
    if not (ASSETS / f"v2_{item['id']}.png").is_file():
        source = fetch(item["url"], item["id"])
        save_sprite(Image.open(source), item["id"])

for atlas in MANIFEST["sheets"]:
    if all((ASSETS / f"v2_{t}.png").is_file() for t in atlas["types"]):
        continue
    source = fetch(atlas["url"], atlas["file"].removesuffix(".png"))
    sheet = Image.open(source).convert("RGBA")
    columns, rows = atlas["columns"], atlas["rows"]
    assert len(atlas["types"]) == columns * rows, "Atlas labels must match grid"
    for index, kind in enumerate(atlas["types"]):
        x0 = round((index % columns) * sheet.width / columns)
        x1 = round(((index % columns) + 1) * sheet.width / columns)
        y0 = round((index // columns) * sheet.height / rows)
        y1 = round(((index // columns) + 1) * sheet.height / rows)
        save_sprite(sheet.crop((x0, y0, x1, y1)), kind)

# One original sprite atlas cell was a Star Wisp; the Crystal Wisp was
# previously reusing it. Produce a visually distinct aqua, jagged crystal
# variant from that Higgsfield-painted source (no extra generation credits).
crystal_path = ASSETS / "v2_crystal_wisp.png"
if not crystal_path.is_file():
    wisp = Image.open(ASSETS / "v2_wisp.png").convert("RGBA")
    pixels = np.array(wisp, dtype=np.uint8)
    mask = pixels[:, :, 3] > 0
    r = pixels[:, :, 0].astype(np.float32)
    g = pixels[:, :, 1].astype(np.float32)
    b = pixels[:, :, 2].astype(np.float32)
    pixels[:, :, 0][mask] = np.clip(r[mask] * 0.23 + 32, 0, 255).astype(np.uint8)
    pixels[:, :, 1][mask] = np.clip(g[mask] * 0.72 + 62, 0, 255).astype(np.uint8)
    pixels[:, :, 2][mask] = np.clip(b[mask] * 0.82 + 91, 0, 255).astype(np.uint8)
    crystal = Image.fromarray(pixels, "RGBA")
    draw = ImageDraw.Draw(crystal, "RGBA")
    width, height = crystal.size
    cx, cy = width * 0.5, height * 0.48
    draw.polygon([(cx - 19, cy - 18), (cx - 4, cy - height * 0.35),
                  (cx + 6, cy - 18)], fill=(66, 236, 253, 205))
    draw.polygon([(cx + 17, cy + 3), (cx + width * 0.3, cy - 25),
                  (cx + 23, cy + 34)], fill=(51, 170, 251, 215))
    draw.polygon([(cx - 18, cy + 11), (cx - width * 0.3, cy - 7),
                  (cx - 29, cy + 35)], fill=(130, 249, 244, 205))
    draw.line([(cx - 4, cy - height * 0.35), (cx + 2, cy - 16)], fill=(226, 255, 255, 240), width=3)
    crystal.save(crystal_path, optimize=True)
    print("PASS: crystal_wisp has a unique recolored and faceted sprite", flush=True)

required = [f"v2_{x['id']}.png" for x in MANIFEST["backgrounds"] + MANIFEST["individuals"]]
required += [f"v2_{name}.png" for sheet in MANIFEST["sheets"] for name in sheet["types"]]
required.append("v2_crystal_wisp.png")
for name in required:
    path = ASSETS / name
    assert path.is_file(), f"Missing game sprite: {name}"
    with Image.open(path) as im:
        im.verify()
print(f"PASS: all {len(required)} v2 art assets packaged for offline Godot import", flush=True)

#!/usr/bin/env python3
"""Download original v1.0 fantasy realm backgrounds into the offline Godot project.

CI runs this once before Godot import. It retains previously committed art;
the CI may commit the fetched PNG files so future builds do not depend on CDN links.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import json
import time

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT / "assets" / "v1_art_manifest.json").read_text())
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
MAX_IMAGE_BYTES = 20_000_000

for entry in CONFIG["sources"]:
    dest = ROOT / entry["path"]
    if dest.exists() and dest.read_bytes()[:8] == PNG_MAGIC:
        print(f"Art ready: {dest.relative_to(ROOT)} ({dest.stat().st_size} bytes)")
        continue
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading original realm background: {entry['name']}", flush=True)
    for attempt in range(3):
        try:
            request = Request(entry["url"], headers={"User-Agent": "Mozilla/5.0 (EchoesOfAetherCI)"})
            with urlopen(request, timeout=65) as response:
                image = response.read(MAX_IMAGE_BYTES + 1)
            if len(image) > MAX_IMAGE_BYTES or not image.startswith(PNG_MAGIC):
                raise ValueError(f"Invalid PNG or oversized art: {entry['name']}")
            dest.write_bytes(image)
            print(f"Downloaded {len(image)} bytes to {dest.relative_to(ROOT)}", flush=True)
            break
        except Exception:
            if attempt == 2:
                raise
            time.sleep(3 * (attempt + 1))

assert all((ROOT / e["path"]).is_file() for e in CONFIG["sources"])
print("PASS: all three original Higgsfield world backgrounds are available for offline APK packaging")

#!/usr/bin/env python3
"""Twelve differentiated, offline enemy/boss silhouettes for Echoes of Aether v7.

Derivative transformations of the game's previously imported original pixel-art
creatures: significantly distinct palettes, outlines, ornaments, claws, spines,
fins and horns. No external image download or generative-service credits.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import hashlib

ASSETS = Path(__file__).resolve().parents[1] / "assets"
N = 288
SPECS = {
    "tide_stalker": ("fire_imp", "#063a56", "#74f3ed", "fins"),
    "coral_wisp": ("crystal_wisp", "#612a67", "#ff9dce", "coral"),
    "thorn_knight": ("ash_knight", "#233e25", "#b5ff73", "thorns"),
    "petal_moth": ("cloud_moth", "#7e305b", "#ffcf9a", "petals"),
    "root_colossus": ("marsh_guardian", "#4d2a24", "#d8aa73", "roots"),
    "mirror_keeper": ("crystal_titan", "#17487d", "#f7fbfa", "mirrors"),
    "gale_wyrm": ("sky_herald", "#304a8e", "#ffdf93", "lightning"),
    "mire_reaver": ("marsh_guardian", "#2d3043", "#b8fe88", "spores"),
    "echo_archon": ("boss", "#3c2674", "#f0c5ff", "stars"),
    "abyss_leviathan": ("crystal_titan", "#072747", "#3df1e9", "leviathan"),
    "thornheart": ("marsh_guardian", "#522a30", "#ffab91", "flowers"),
    "nexus_echo": ("boss", "#1c3159", "#a7f1ff", "halo"),
}

def overlay(draw, kind, main, edge):
    # Spikes, fins and equipment are large enough to change the silhouette.
    if kind in ("fins", "leviathan"):
        for side in [-1, 1]:
            draw.polygon([(144+side*54,135),(144+side*125,64),
                          (144+side*104,158),(144+side*122,201),(144+side*45,171)],
                         fill=edge+(215,),outline=main+(255,))
        draw.polygon([(102,104),(144,16),(186,104),(145,91)],fill=edge+(180,))
    elif kind=="coral":
        for side in [-1,1]:
            for j in range(4):
                x=144+side*(66+j*12)
                y=182-j*25
                draw.line([(144+side*42,209),(x,y),(x+side*13,y-28)],
                          fill=edge+(220,),width=7)
                draw.ellipse((x-8,y-8,x+8,y+8),fill=main+(230,))
    elif kind in ("thorns","roots"):
        for side in [-1,1]:
            for j in range(5):
                y=72+j*34
                draw.polygon([(144+side*67,y+15),(144+side*(107+j%2*7),y-24),
                              (144+side*75,y-5)],fill=edge+(215,))
        if kind=="roots":
            draw.line([(97,220),(67,257),(43,265)],fill=main+(255,),width=19)
            draw.line([(187,220),(222,259),(254,266)],fill=main+(255,),width=19)
    elif kind == "petals":
        for i in range(8):
            from math import cos,sin,pi
            a=2*pi*i/8
            x=144+int(110*cos(a));y=139+int(106*sin(a))
            draw.ellipse((x-25,y-16,x+25,y+16),fill=edge+(175,),outline=main+(245,),width=3)
    elif kind=="mirrors":
        for side in [-1,1]:
            draw.polygon([(144+side*68,71),(144+side*128,127),
                          (144+side*108,202),(144+side*64,181)],
                         fill=edge+(175,),outline=(255,255,255,223))
        draw.line([(144,30),(144,80)],fill=edge+(255,),width=13)
    elif kind=="lightning":
        for side in [-1,1]:
            draw.line([(144+side*72,54),(144+side*110,109),(144+side*88,146),
                       (144+side*125,174)],fill=edge+(232,),width=12,joint="curve")
    elif kind=="spores":
        for i in range(14):
            x=38+(i*43)%211;y=29+(i*63)%201
            r=7+(i%3)*4
            draw.ellipse((x-r,y-r,x+r,y+r),fill=edge+(105+i%4*23,))
    elif kind=="stars":
        for x,y in [(60,52),(226,77),(56,190),(236,219)]:
            draw.polygon([(x,y-17),(x+6,y-6),(x+18,y),(x+6,y+6),
                          (x,y+18),(x-6,y+6),(x-18,y),(x-6,y-6)], fill=edge+(185,))
    elif kind=="flowers":
        for x,y in [(65,61),(220,120),(77,229)]:
            for d in [(-13,0),(13,0),(0,-13),(0,13)]:
                draw.ellipse((x+d[0]-8,y+d[1]-8,x+d[0]+8,y+d[1]+8),fill=edge+(210,))
            draw.ellipse((x-7,y-7,x+7,y+7),fill=(255,222,116,255))
    elif kind=="halo":
        draw.arc((44,18,244,232),205,515,fill=edge+(225,),width=12)
        draw.arc((27,31,261,247),25,170,fill=main+(200,),width=8)
        draw.polygon([(144,1),(159,31),(144,46),(129,31)],fill=edge+(235,))

def rgb(v):
    v=v.lstrip("#")
    return tuple(bytes.fromhex(v))

def main():
    signatures=set()
    for kind,(parent,shadow,light,ornament) in SPECS.items():
        target=ASSETS/f"v7_{kind}.png"
        if not target.exists():
            source=ASSETS/f"v2_{parent}.png"
            if not source.is_file():
                raise FileNotFoundError(f"Missing source sprite {source}")
            orig=Image.open(source).convert("RGBA")
            color=ImageOps.colorize(ImageOps.grayscale(orig.convert("RGB")),shadow,light).convert("RGBA")
            color.putalpha(orig.getchannel("A"))
            color.thumbnail((190,202),Image.Resampling.LANCZOS)
            stage=Image.new("RGBA",(N,N),(0,0,0,0))
            back=Image.new("RGBA",(N,N),(0,0,0,0))
            overlay(ImageDraw.Draw(back,"RGBA"),ornament,rgb(shadow),rgb(light))
            stage.alpha_composite(back)
            stage.alpha_composite(color,((N-color.width)//2, (N-color.height)//2+16))
            stage.save(target,optimize=True)
        with Image.open(target) as img:
            assert img.size==(N,N) and img.mode=="RGBA",kind
            assert img.getchannel("A").getbbox() is not None,kind
        sig=hashlib.sha256(target.read_bytes()).hexdigest()
        assert sig not in signatures, "Every mob has an independent actual image"
        signatures.add(sig)
        print("PASS: original v7 distinct sprite",kind,target.stat().st_size,flush=True)
    print("PASS: twelve distinct v7 enemy and boss sprite identities imported",flush=True)

if __name__=="__main__":
    main()

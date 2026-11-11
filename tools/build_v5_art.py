#!/usr/bin/env python3
"""Create original, offline fantasy realm backdrops without external image services.

This deterministic Pillow art pipeline is intentionally self-contained:
GitHub Actions can rebuild the PNGs even when all image-generation services
are unavailable. Unique scene art is not a substitute for collisions or NPCs.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, math, hashlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets"
OUT.mkdir(exist_ok=True)
W, H = 1600, 720

THEMES = {
    "abyss": ("ocean", "#021528", "#12658d", "#0a5369", "#0b4054", "#092c48", "#35e6fa"),
    "tide_temple": ("ocean", "#020f22", "#14527d", "#07455b", "#163c51", "#102a43", "#7feaff"),
    "garden": ("garden", "#16395a", "#99cbb4", "#3d9072", "#24624b", "#1c483b", "#f5cc7b"),
    "verdant_vault": ("garden", "#071c1e", "#397c59", "#256547", "#124734", "#0d302b", "#c7fa6d"),
    "nexus": ("cosmos", "#0c0b37", "#5753b8", "#383a7e", "#262766", "#1b214a", "#b8bcff"),
    "nexus_core": ("cosmos", "#070b22", "#4e2786", "#492d83", "#251954", "#14162e", "#ffdc9c"),
    "rootcrypt": ("crypt", "#071b1a", "#28614c", "#194f3c", "#143c34", "#102a26", "#84ffb0"),
}

def rgb(code):
    return tuple(int(code[i:i+2], 16) for i in (1, 3, 5))

def mix(a, b, weight):
    return tuple(int(a[i] * (1-weight) + b[i] * weight) for i in range(3))

def render(name, theme):
    mood, top, bottom, hills, mid, near, accent = theme
    top, bottom, hills, mid, near, accent = map(rgb, (top, bottom, hills, mid, near, accent))
    seed = {"abyss": 53, "tide_temple": 54, "garden": 91,
            "verdant_vault": 92, "nexus": 141, "nexus_core": 142, "rootcrypt": 182}[name]
    rng = random.Random(seed)
    canvas = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(canvas)
    # Atmospheric layered backdrop without a tile boundary.
    for y in range(H):
        t = (y / H) ** 0.77
        drift = 0.05 * math.sin(y * .013 + seed)
        color = mix(top, bottom, min(1.0, max(0.0, t + drift)))
        dr.line((0, y, W, y), fill=color)
    for layer, base, amplitude, tone in [
        (0, 430, 92, mix(hills, top, .36)),
        (1, 520, 116, mid),
        (2, 648, 82, near),
    ]:
        points = [(0, H)]
        for x in range(0, W + 32, 32):
            y = base + math.sin(x * .009 + layer * 2.8 + seed) * amplitude * .42
            y += math.sin(x * .021 + seed * .3 + layer) * amplitude * .26
            y += rng.randrange(-12, 13)
            points.append((x, int(y)))
        points += [(W, H)]
        dr.polygon(points, fill=tone)

    effects = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    e = ImageDraw.Draw(effects)
    highlight = accent + (95,)
    if mood in ("ocean", "cosmos"):
        # Shafts of moonlight or underwater sunbeams.
        for i in range(9):
            x = rng.randrange(100, 1600)
            spread = 65 + i * 11
            e.polygon([(x-9, 0), (x+9, 0), (x+spread, 630), (x-spread, 630)],
                      fill=accent + (12 if mood == "cosmos" else 17,))
    elif mood == "garden":
        for i in range(8):
            x = rng.randrange(40, 1600)
            e.polygon([(x, 0), (x+20, 0), (x+260, 650), (x+95, 650)], fill=(255, 247, 162, 13))
    for i in range(84 if mood == "cosmos" else 43):
        x, y = rng.randrange(W), rng.randrange(20, 630)
        r = rng.choice([1, 1, 2, 3, 4])
        e.ellipse((x-r*3, y-r*3, x+r*3, y+r*3), fill=accent + (18,))
        e.ellipse((x-r, y-r, x+r, y+r), fill=accent + (155,))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), effects.filter(ImageFilter.GaussianBlur(2)))
    draw = ImageDraw.Draw(canvas, "RGBA")

    def column(x, top_y, height, col=None):
        stone = col or mix(near, accent, .20)
        draw.rectangle((x-24, top_y, x+24, top_y+height), fill=stone + (255,))
        draw.rectangle((x-34, top_y-14, x+34, top_y+2), fill=mix(stone, accent, .38)+(255,))
        draw.rectangle((x-30, top_y+height-17, x+30, top_y+height), fill=mix(stone, top, .33)+(255,))
        draw.line((x-8, top_y+15, x-8, top_y+height-24), fill=accent+(56,), width=4)

    def arch(cx, y, radius):
        stone = mix(mid, bottom, .23)
        draw.arc((cx-radius, y-radius, cx+radius, y+radius), 180, 360, fill=stone+(255,), width=34)
        draw.arc((cx-radius+9, y-radius+9, cx+radius-9, y+radius-9), 182, 355,
                 fill=accent+(100,), width=5)
        column(cx-radius, y, 320, stone)
        column(cx+radius, y, 320, stone)

    def crystal(x, y, size):
        tone = mix(accent, (243, 253, 255), .28)
        draw.polygon([(x,y-size), (x+size//2,y-size//3), (x+size//3,y+size),
                      (x-size//2,y+size//2), (x-size//3,y-size//3)], fill=tone+(200,))
        draw.line((x,y-size,x,y+size//2),fill=(240,255,255,164),width=3)

    if mood == "ocean":
        for cx, y, radius in [(340, 415, 180), (840, 365, 212), (1310, 420, 165)]:
            arch(cx, y, radius)
        # Drowned observatory and the shattered tide mechanism.
        draw.ellipse((635,125,963,452), outline=accent+(155,),width=15)
        draw.ellipse((685,175,915,402), outline=(162,236,255,140),width=7)
        draw.polygon([(801,196),(864,282),(800,368),(736,282)], fill=accent+(166,))
        draw.line((790,215,790,354),fill=(234,255,255,190),width=7)
        # Coral forests, kelp and bubble streams.
        for i in range(62):
            x = rng.randrange(30, W-30)
            y = rng.randrange(605, 715)
            height = rng.randrange(38, 130)
            col = rng.choice([(30,190,202,220),(138,99,225,220),(241,114,164,220)])
            draw.line((x,y,x+rng.randrange(-18,19),y-height), fill=col,width=rng.randrange(5,11))
            for dy in range(3):
                bend = rng.randrange(-30,30)
                draw.line((x,y-height//2,x+bend,y-height+dy*22),fill=col,width=4)
        for i in range(47):
            x,y = rng.randrange(W),rng.randrange(85,590)
            radius=rng.randrange(4,11)
            draw.ellipse((x-radius,y-radius,x+radius,y+radius),outline=(184,244,255,110),width=2)
        for x in (140,590,1095,1465): crystal(x,635,rng.randrange(28,61))
    elif mood == "garden":
        for cx,y,radius in [(410,440,146),(1170,430,180)]:
            arch(cx,y,radius)
        for i in range(19):
            x=50+i*84+rng.randrange(-30,31)
            y=rng.randrange(470,650)
            canopy = rng.randrange(58,120)
            draw.line((x,y+100,x,y-canopy),fill=(67,73,48,255),width=rng.randrange(15,26))
            for j in range(7):
                off=rng.randrange(-canopy,canopy)
                rr=rng.randrange(34,71)
                cy=y-canopy+off//4
                draw.ellipse((x+off-rr,cy-rr,x+off+rr,cy+rr),
                             fill=rng.choice([(35,126,85,221),(42,161,112,230),(143,186,107,215)]))
        for i in range(81):
            x,y =rng.randrange(W),rng.randrange(550,720)
            size=rng.randrange(8,20)
            flower=rng.choice([(237,138,191,237),(249,226,127,240),(200,170,245,238)])
            draw.line((x,y+18,x,y-9),fill=(50,162,77,220),width=3)
            for k in range(5):
                angle=k*math.tau/5
                dx,dy=int(math.cos(angle)*size),int(math.sin(angle)*size)
                draw.ellipse((x+dx-8,y+dy-8,x+dx+8,y+dy+8),fill=flower)
            draw.ellipse((x-5,y-5,x+5,y+5),fill=(250,249,190,255))
        for x in [250,780,1290]: crystal(x,590,29)
    elif mood == "cosmos":
        # Floating islands, crystal spires and the luminous Aether core.
        for i in range(10):
            x = 100+i*162+rng.randrange(-45,46)
            y = 360+rng.randrange(-160,115)
            width = rng.randrange(72,146)
            draw.ellipse((x-width,y-21,x+width,y+25),fill=mix(mid,accent,.23)+(240,))
            draw.polygon([(x-width,y),(x+width,y),(x+40,y+92),(x,y+137),(x-41,y+76)],
                         fill=mix(near,top,.22)+(235,))
            if i % 2 == 0:
                column(x,y-125,127)
        for r, alpha in [(235,44),(195,78),(153,110)]:
            draw.ellipse((800-r,306-r,800+r,306+r),outline=accent+(alpha,),width=11)
        for r in range(3):
            spin=r*2.09
            draw.arc((565,76,1035,546),int(math.degrees(spin)),int(math.degrees(spin)+150),
                     fill=(250,213,130,155),width=17)
        draw.polygon([(800,111),(908,285),(803,482),(682,281)],fill=accent+(202,))
        draw.polygon([(800,117),(796,403),(720,283)],fill=(230,242,255,140))
        draw.line((800,110,803,460),fill=(255,253,223,216),width=11)
        for x in (110,345,1390,1540): crystal(x,610,rng.randrange(29,70))
    elif mood == "crypt":
        for cx,y,radius in [(270,435,140),(855,450,188),(1400,420,150)]:
            arch(cx,y,radius)
        draw.polygon([(1160,450),(1300,390),(1450,450),(1450,660),(1160,660)],fill=(15,43,39,255))
        crystal(1320,500,58)
        for i in range(14):
            x=60+i*116+rng.randrange(-25,25)
            y=rng.randrange(550,710)
            draw.rounded_rectangle((x-23,y-54,x+30,y+36),radius=12,
                                    fill=(55,76,65,235),outline=(95,138,105,232),width=4)
            draw.line((x+4,y-43,x+4,y-3),fill=(92,140,104,185),width=3)
        # Giant root arches with lantern fungi.
        for i in range(13):
            x=rng.randrange(W)
            y=-30+rng.randrange(0,70)
            end=rng.randrange(290,600)
            draw.line((x,y,x+rng.randrange(-115,115),end),
                      fill=(59,53,31,255),width=rng.randrange(18,39),joint="curve")
        for i in range(45):
            x,y=rng.randrange(W),rng.randrange(380,710)
            r=rng.randrange(7,24)
            draw.ellipse((x-r,y-r//2,x+r,y+r//2),
                         fill=rng.choice([(90,241,164,190),(172,230,123,185)]))
    # Architectural walkable horizon. Ground collision stays in Godot, not image.
    for i in range(22):
        x=i*74
        y=657+int(13*math.sin(i*1.8+seed))
        draw.rectangle((x,y,x+78,H),fill=mix(near,top,.25)+(255,))
        draw.line((x,y,x+74,y), fill=accent+(90,),width=3)
    # One-off soft glow above energy sources.
    glow=Image.new("RGBA",(W,H),(0,0,0,0))
    gd=ImageDraw.Draw(glow)
    for i in range(23):
        x=rng.randrange(W)
        y=rng.randrange(140,600)
        r=rng.randrange(9,25)
        gd.ellipse((x-r,y-r,x+r,y+r),fill=accent+(rng.randrange(25,65),))
    glow=glow.filter(ImageFilter.GaussianBlur(23))
    canvas=Image.alpha_composite(canvas,glow).convert("RGB")
    return canvas

def main():
    hashes = []
    for name, theme in THEMES.items():
        path=OUT / ("v5_generated_"+name+".png")
        if not path.exists():
            render(name,theme).save(path,optimize=True)
        with Image.open(path) as check:
            check.verify()
        signature=hashlib.sha256(path.read_bytes()).hexdigest()
        hashes.append(signature)
        print("PASS: generated game-art background",path.name,path.stat().st_size,"SHA256",signature[:12],flush=True)
    assert len(set(hashes)) == len(THEMES), "Different realms must not reuse identical art"
    print("PASS: seven distinct original offline v5 scenery textures imported",flush=True)

if __name__ == "__main__":
    main()

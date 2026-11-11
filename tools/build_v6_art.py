#!/usr/bin/env python3
"""Produce eight unique original illustrated dungeon annex backdrops.

Runs in GitHub Actions before Godot import; requires no paid image service.
Each canvas is a complete original still with a distinctive monumental puzzle
mechanism. The new chamber interactions/obstacles are built in Godot, not faked
into this image. A user's optional premium-art replacement may be loaded from
the same exact asset path later without changing scene logic.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random, hashlib
import build_v5_art as art

ROOT=Path(__file__).resolve().parents[1]
ASSETS=ROOT/"assets"
W,H=1600,720
CHAMBERS={
    "rootgallery":("rootcrypt",(128,232,146),"mural"),
    "prismannex":("tide_temple",(107,237,255),"prism"),
    "windobservatory":("nexus",(215,216,252),"clock"),
    "boglanterns":("rootcrypt",(154,250,170),"lantern"),
    "forgeengine":("nexus_core",(255,145,74),"forge"),
    "tidecontrol":("abyss",(88,230,255),"valves"),
    "seedarbor":("garden",(255,204,119),"mural"),
    "nexusmemory":("nexus_core",(209,153,255),"stars"),
}

def polygon(draw,points,fill,outline=None,width=3):
    draw.polygon(points,fill=fill)
    if outline: draw.line(points+[points[0]],fill=outline,width=width,joint="curve")

def arch(draw,x,y,w,h,col,glow):
    # Prominent stone arch with a dark open portal cutout.
    draw.rounded_rectangle((x-w//2,y-h,x+w//2,y),radius=45,fill=col,outline=glow,width=9)
    draw.rounded_rectangle((x-w//2+29,y-h+40,x+w//2-29,y+10),radius=38,fill=(11,26,39,248))
    draw.arc((x-w//2+18,y-h+30,x+w//2-18,y-10),185,357,fill=glow,width=11)

def star(draw,x,y,r,col):
    polygon(draw,[(x,y-r),(x+r//4,y-r//4),(x+r,y),(x+r//4,y+r//4),
                  (x,y+r),(x-r//4,y+r//4),(x-r,y),(x-r//4,y-r//4)],col)

def chamber(name,src_theme,accent,variant):
    base=art.render(src_theme,art.THEMES[src_theme]).convert("RGBA")
    shade=Image.new("RGBA",(W,H),(0,0,0,0))
    sd=ImageDraw.Draw(shade,"RGBA")
    # Recessed side walls create a real underground-room framing.
    for x in (0,W-110):
        sd.rectangle((x,0,x+110,H),fill=(13,17,27,110))
    sd.rectangle((0,0,W,72),fill=(6,11,25,132))
    sd.rectangle((0,656,W,H),fill=(17,23,34,125))
    for i in range(7):
        x=55+i*245
        sd.rectangle((x,0,x+20,270),fill=(23,28,42,145))
        sd.ellipse((x-10,245,x+30,290),fill=accent+(110,))
    base=Image.alpha_composite(base,shade)
    shadow=Image.new("RGBA",(W,H),(0,0,0,0))
    sh=ImageDraw.Draw(shadow,"RGBA")
    sh.ellipse((410,105,1190,660),fill=accent+(53,))
    base=Image.alpha_composite(base,shadow.filter(ImageFilter.GaussianBlur(100)))
    layer=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(layer,"RGBA")
    rng=random.Random(sum(ord(c) for c in name))
    stone=(39,46,69,244)
    line=accent+(220,)
    arch(d,800,560,690,520,stone,line)
    # Two sight-line platforms in back of the active foreground, never blocking players.
    for k in range(5):
        x=290+k*240
        y=564+int(math.sin(k+len(name))*18)
        d.rounded_rectangle((x,y,x+155,y+23),radius=6,fill=(66,70,90,230),outline=line,width=3)
        d.rectangle((x+32,y+22,x+118,y+30),fill=(28,41,51,216))
    if variant=="mural":
        # Assembled treasure-map mosaic pieces and ancient route glyph.
        for row in range(3):
            for col in range(3):
                x,y=600+col*137,153+row*123
                d.rectangle((x,y,x+125,y+110),fill=(41+row*6,62+col*10,67+row*7,255),outline=accent+(255,),width=6)
                if row*3+col<8:
                    pts=[(x+22,y+74),(x+46,y+33),(x+81,y+55),(x+103,y+18)]
                    d.line(pts,fill=(230,228,179,215),width=5,joint="curve")
                    star(d,x+91,y+78,17,line)
        for i in range(12):
            x=270+i*104
            d.line((x,0,x+30,180+random.Random(i).randint(0,70)),fill=(55,132,87,180),width=13)
    elif variant=="prism":
        # Distinct three-row optical routing with reflective lenses.
        for y in [172,305,438]:
            d.line((380,y,1235,y),fill=accent+(115,),width=12)
        for x,y in [(455,306),(810,172),(1120,435),(810,438),(1120,172)]:
            polygon(d,[(x,y-63),(x+52,y),(x,y+63),(x-52,y)],(117,211,247,180),outline=(231,255,255,255),width=7)
            d.arc((x-77,y-77,x+77,y+77),0,350,fill=(255,225,158,240),width=6)
        star(d,805,312,55,line)
    elif variant=="clock":
        # Three spatial logic dials, no glyph sprites reused.
        for k,x in enumerate([485,800,1115]):
            y=319
            d.ellipse((x-96,y-96,x+96,y+96),fill=(29,42,82,244),outline=accent+(240,),width=12)
            for j in range(8):
                t=j*math.tau/8
                ox=int(math.cos(t)*77);oy=int(math.sin(t)*77)
                d.ellipse((x+ox-8,y+oy-8,x+ox+8,y+oy+8),fill=(252,215,135,245))
            d.line((x,y,x+int(math.sin(k+1)*50),y-int(math.cos(k+1)*62)),fill=(244,232,185,255),width=13)
            d.ellipse((x-16,y-16,x+16,y+16),fill=accent+(255,))
    elif variant=="lantern":
        for i in range(8):
            x=260+i*157
            yy=170+(i%3)*55
            d.line((x,0,x,yy),fill=(150,130,99,205),width=6)
            d.polygon([(x-36,yy),(x+36,yy),(x+53,yy+41),(x+26,yy+81),(x-26,yy+81),(x-53,yy+41)],
                      fill=(99,53,126,220),outline=accent+(255,),width=5)
            star(d,x,yy+47,23,(236,253,195,255))
    elif variant=="forge":
        # Molten routing: huge gears, chimneys and fiery ring.
        for x,y,r in [(520,291,113),(1060,280,140),(800,360,183)]:
            d.ellipse((x-r,y-r,x+r,y+r),outline=accent+(255,),width=24)
            d.ellipse((x-r+34,y-r+34,x+r-34,y+r-34),outline=(252,215,122,224),width=8)
            for k in range(12):
                t=k*math.tau/12
                u,v=int(math.cos(t)*r),int(math.sin(t)*r)
                d.line((x+u*.87,y+v*.87,x+u*1.08,y+v*1.08),fill=(246,176,111,235),width=11)
        for i in range(13):
            x=180+i*112
            d.polygon([(x,650),(x-42,648),(x,480-rng.randint(0,85)),(x+45,649)],fill=(255,111,52,132))
    elif variant=="valves":
        # Water gates: three flood-control wheels with transparent pipes.
        for x in [490,810,1130]:
            y=295
            d.ellipse((x-108,y-108,x+108,y+108),fill=(32,88,112,210),outline=accent+(243,),width=13)
            for j in range(8):
                t=j*math.tau/8
                d.line((x,y,x+int(math.cos(t)*90),y+int(math.sin(t)*90)),fill=(186,242,243,206),width=8)
            d.ellipse((x-23,y-23,x+23,y+23),fill=(251,217,137,246))
            d.line((x,y+121,x,645),fill=(46,204,255,160),width=28)
        for row in range(5):
            yy=542+row*23
            d.arc((200,yy,1400,yy+95),4,176,fill=accent+(70,),width=4)
    elif variant=="stars":
        coords=[(420,218),(635,158),(852,258),(1088,150),(1200,408),(775,479),(450,412)]
        for i,(x,y) in enumerate(coords):
            star(d,x,y,24+i%2*8,line)
            nxt=coords[(i+1)%len(coords)]
            d.line((x,y,*nxt),fill=accent+(172,),width=7)
        for r in [160,220,275]:
            d.ellipse((800-r,340-r,800+r,340+r),outline=accent+(78,),width=9)
        star(d,800,340,86,(253,232,167,235))
    # Gold trim and magical plant growth.
    for i in range(8):
        x=rng.randint(80,1510);y=rng.randint(545,670)
        d.line((x,y,x+rng.randrange(-22,23),y-60),fill=(62,172,101,190),width=5)
        d.ellipse((x-14,y-75,x+14,y-50),fill=accent+(200,))
    base=Image.alpha_composite(base,layer)
    vignette=Image.new("RGBA",(W,H),(0,0,0,0))
    vd=ImageDraw.Draw(vignette,"RGBA")
    vd.rectangle((0,0,W,9),fill=accent+(200,))
    vd.rectangle((0,H-11,W,H),fill=accent+(115,))
    return Image.alpha_composite(base,vignette).convert("RGB")

def main():
    hashes=[]
    for name,(theme,accent,variant) in CHAMBERS.items():
        target=ASSETS/f"v6_generated_{name}.png"
        if not target.is_file():
            chamber(name,theme,accent,variant).save(target,optimize=True)
        with Image.open(target) as im:
            im.verify()
        hashes.append(hashlib.sha256(target.read_bytes()).hexdigest())
        print("PASS: illustrated v6 annex scene",name,target.stat().st_size,flush=True)
    assert len(set(hashes))==len(CHAMBERS), "All eight playable trials must have distinct art"
    print("PASS: eight distinct original v6 dungeon artworks embedded for offline Godot",flush=True)

if __name__=="__main__":
    main()

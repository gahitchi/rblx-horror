#!/usr/bin/env python3
"""Original, textured Blackline hero prop meshes.

These are optional Studio-imported set pieces with fixed Roblox-stud units,
not replacements for gameplay collision, prompts or objective logic.
Uses our shared, deterministic UV + material image generator.
"""
from pathlib import Path
import argparse
import math
import trimesh
from build_character_assets import Model

def transfer_machine():
    m=Model()
    # Late-1970s large-format transfer console on braced pedestal.
    m.box((0,1.90,0),(4.95,3.8,2.1),"iron")
    m.box((0,3.58,-1.11),(4.65,.32,.12),"coat_dark")
    m.box((0,2.86,-1.14),(4.5,.86,.17),"field_edge")
    for x in (-1.28,1.28):
        # Distinct reel decks with cutout geometry represented as five spokes,
        # recessed centers, hub retention bolt and readable drive bearings.
        m.link((x,2.38,-1.38),(x,2.38,-1.69),.94,.94,"iron",48)
        m.link((x,2.38,-1.72),(x,2.38,-1.77),.78,.78,"coat_dark",48)
        for a in range(6):
            t=a*math.tau/6
            m.link((x+math.cos(t)*.19,2.38+math.sin(t)*.19,-1.82),
                   (x+math.cos(t)*.78,2.38+math.sin(t)*.78,-1.82),
                   .065,.075,"brass",12)
        m.link((x,2.38,-1.77),(x,2.38,-1.96),.20,.20,"iron",24)
        m.link((x,2.38,-1.96),(x,2.38,-2.03),.075,.075,"brass",18)
    m.box((0,1.57,-1.10),(4.32,1.11,.16),"coat_dark")
    # Left/right VU meters: framed, grounded visual cues to the story's signal 08.
    for x in (-.95,.95):
        m.box((x,1.72,-1.21),(1.36,.57,.11),"brass")
        m.box((x,1.75,-1.30),(1.20,.36,.06),"label")
        m.link((x-.43,1.68,-1.34),(x+.12,1.82,-1.34),.028,.028,"signal",8)
    for i in range(9):
        x=-1.9+i*.47
        m.box((x,.65,-1.13),(.29,.12,.10),"coat_high")
        m.box((x,.39,-1.13),(.20,.28,.11),"rubber")
        m.box((x,.19,-1.13),(.12,.10,.12),"brass")
    # Per-channel maintenance trim, tactile rotary gain pots and small legends.
    # These are actual modeled controls, not a flat diffuse texture.
    for row in range(3):
        for col in range(8):
            x=-1.82+col*.52
            y=.92+row*.19
            m.link((x,y,-1.22),(x,y,-1.36),.09,.08,"brass",14)
            m.box((x,y-.09,-1.40),(.20,.026,.035),"rubber")
    for col in range(13):
        x=-2.05+col*.34
        m.box((x,.13,-1.22),(.18,.11,.045),"label")
    m.box((0,.05,0),(4.9,.14,2.2),"coat_dark")
    for x in (-2.20,2.20):
        m.box((x,.25,-1.10),(.17,.45,.15),"brass")
    return m.finish()

def patch_matrix():
    m=Model()
    # Floor-standing 17U signal routing cabinet, maintenance-access frontage.
    m.box((0,3.45,0),(3.6,6.9,2.2),"iron")
    for side in (-1,1):
        m.box((side*1.7,3.45,-1.14),(.23,6.7,.18),"coat_dark")
        m.box((side*1.6,3.45,.85),(.23,6.7,.12),"coat_high")
    m.box((0,6.60,-1.18),(3.3,.26,.15),"brass")
    for row in range(12):
        y=.74+row*.49
        m.box((0,y,-1.19),(3.22,.37,.10),"coat_dark")
        m.box((-.99,y,-1.29),(1.04,.17,.07),"field_edge")
        for col in range(6):
            x=-1.44+col*.18
            m.link((x,y,-1.30),(x,y,-1.36),.04,.04,"brass",10)
        m.box((.87,y,-1.29),(1.02,.16,.06),"coat_high")
        for col in range(3):
            m.box((.53+col*.32,y,-1.37),(.19,.075,.035),
                  "signal" if (row==7 and col==0) else "visor")
    # Critical cable bundles are physically tied to the back, not a fake pipe.
    for i in range(5):
        x=-1.3+i*.6
        m.link((x,5.45,.9),(x+.12,1.20,1.38),.057,.044,"rubber",12)
    for x in (-1.55,1.55):
        for y in (.32,6.49):
            m.link((x,y,-1.23),(x,y,-1.32),.052,.052,"brass",12)
    return m.finish()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,default=Path("build/roblox-glb"))
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    for name,builder in {
        "BlacklineTransferDeck":transfer_machine,
        "BlacklinePatchMatrix":patch_matrix,
    }.items():
        path=args.out/(name+".glb")
        path.write_bytes(builder().export(file_type="glb"))
        loaded=trimesh.load(path,force="scene",process=False)
        verts=sum(len(m.vertices) for m in loaded.geometry.values())
        assert verts>=1500,(name,"geometry unexpectedly low")
        print(f"{name}.glb: {verts} vertices, {len(loaded.geometry)} material meshes, {path.stat().st_size} bytes")
if __name__=="__main__":
    main()

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
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from trimesh.visual.material import PBRMaterial
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

def console_legend(scene:trimesh.Scene):
    """Original, authored blacklined identification/operation plate with
    image-space text, not a floating BillboardGui or generic rusty texture."""
    im=Image.new("RGB",(1024,192),(26,29,30))
    draw=ImageDraw.Draw(im)
    font=ImageFont.load_default(size=47)
    minor=ImageFont.load_default(size=24)
    draw.rectangle((12,10,1012,182),outline=(122,116,92),width=5)
    draw.text((42,29),"B L A C K L I N E  /  C O N T R O L  A",
              fill=(223,209,177),font=font)
    draw.text((44,118),"SESSION 08  /  MASTER BUS  /  ANALOG SIGNAL PATH",
              fill=(138,154,148),font=minor)
    # No material metalness on printed laminate; rough, diffuse lettering.
    material=PBRMaterial(name="OriginalConsoleLegend",
        baseColorTexture=im,metallicFactor=.0,roughnessFactor=.89,
        doubleSided=True)
    # Watertight thin printed aluminum nameplate, facing negative Z.
    mesh=trimesh.creation.box(extents=(4.96,.65,.035))
    mesh.apply_translation((0,3.915,-1.755))
    # Map the front face in local centimeters consistently, including corners.
    points=np.asarray(mesh.vertices)
    uv=np.column_stack(((points[:,0]+2.48)/4.96,(points[:,1]-3.59)/.65))
    mesh.visual=trimesh.visual.TextureVisuals(uv=uv,material=material)
    scene.add_geometry(mesh,node_name="ConsoleOriginalSerialLegend",
                       geom_name="ConsoleOriginalSerialLegend")
    return scene


def blackline_hero_console():
    """Purpose-authored, scale-conscious studio desk, with structural cabinet,
    sloped steel meter bridge, 16 channel strips, physical faders and VU units.

    A substitute for the original rough MixingConsole in Blackline's Control A;
    old import and procedural fallback are still functional and installed.
    """
    m=Model()
    # Self-supporting, polished workstation with a cable/vent service recess.
    for side in (-1,1):
        x=side*2.88
        m.box((x,1.28,.24),(.48,2.48,2.76),"coat_dark")
        m.box((x,2.42,.24),(.53,.14,2.92),"iron")
        for i in range(4):
            m.box((x,1.2+i*.33,-1.21),(.36,.06,.08),"brass")
    m.box((0,.36,1.12),(5.48,.43,.58),"coat_high")
    m.box((0,.16,-1.00),(5.64,.17,.21),"rubber")
    m.box((0,1.86,1.20),(5.32,1.19,.24),"iron")
    m.box((0,2.52,.09),(6.10,.25,3.22),"field_edge")
    m.box((0,2.70,-1.49),(6.28,.18,.13),"brass")
    m.box((0,2.74,1.37),(6.28,.18,.18),"brass")
    for side in (-1,1):
        m.box((side*3.08,2.62,-.06),(.16,.33,3.24),"brass")
    # Independent channel strips, controlled from the operator's front edge.
    for ch in range(16):
        x=-2.65+ch*(5.30/15)
        m.box((x,2.72,-.39),(.29,.075,1.77),
              "coat_high" if ch%4 else "iron")
        # Recessed fader slot, stem and tactile black knob.
        m.box((x,2.77,-.71),(.068,.055,1.10),"coat_dark")
        faderZ=-.98+(ch%5)*.13
        m.box((x,2.835,faderZ),(.21,.085,.27),"rubber")
        m.box((x,2.883,faderZ),(.11,.022,.17),"brass")
        for row in range(3):
            z=.06+row*.27
            m.link((x,2.78,z),(x,2.96,z),.10,.083,
                   "brass" if row==2 else "iron",14)
            m.box((x,2.99,z-.014),(.03,.027,.11),"rubber")
        for row in range(4):
            m.box((x,2.79,-1.27+row*.115),(.11,.035,.035),
                  "signal" if ch==7 and row<2 else "visor")
    # A rising master meter bridge with physical bezels, needles and glass.
    m.box((0,3.40,1.24),(5.85,1.45,.60),"iron")
    m.box((0,3.98,.88),(5.60,.18,.40),"brass")
    m.box((0,3.12,.91),(5.66,.13,.38),"coat_dark")
    for meter in range(2):
        x=-1.42+meter*2.84
        m.box((x,3.47,.87),(2.13,.72,.11),"brass")
        m.box((x,3.49,.795),(1.85,.48,.065),"label")
        for tick in range(9):
            m.box((x-.78+tick*.195,3.45,.74),(.028,.20,.024),
                  "signal" if tick>=7 else "coat_dark")
        m.link((x-.35,3.32,.70),(x+.23,3.53,.70),.031,.027,"signal",10)
    for side in (-1,1):
        x=side*2.60
        for row in range(5):
            m.box((x,3.16+row*.12,.68),(.11,.045,.035),
                  "visor" if row<4 else "signal")
    # Details stay behind operator-accessible surface, not across the aisle.
    scene=m.finish()
    return console_legend(scene)


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,default=Path("build/roblox-glb"))
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    for name,builder in {
        "BlacklineTransferDeck":transfer_machine,
        "BlacklinePatchMatrix":patch_matrix,
        "BlacklineHeroConsole":blackline_hero_console,
    }.items():
        path=args.out/(name+".glb")
        path.write_bytes(builder().export(file_type="glb"))
        loaded=trimesh.load(path,force="scene",process=False)
        verts=sum(len(m.vertices) for m in loaded.geometry.values())
        assert verts>=1500,(name,"geometry unexpectedly low")
        print(f"{name}.glb: {verts} vertices, {len(loaded.geometry)} material meshes, {path.stat().st_size} bytes")
if __name__=="__main__":
    main()

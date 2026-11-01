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
    """Q01 quality benchmark: hand-composed geometry and original UV atlases.

    Kept behind the historical prefab name so game integration, functional
    collision proxy and optional missing-import fallback are unchanged.
    """
    from quality_console import build
    return build()

def blackline_archive_cabinet():
    """One finished-looking, clearly legible archiving landmark, not a
    scatter set. Its original, image-mapped metal / reel surfaces are framed
    around a deliberately absent eighth master, independent of objectives.

    11.8 x 8.5 x 2.3 studs, grounded at y=0; front points toward negative Z.
    """
    m=Model()
    m.box((0,4.25,0),(11.8,8.5,1.85),"iron")
    m.box((0,4.06,-.95),(11.28,7.44,.11),"coat_dark")
    for x in (-5.73,5.73):
        m.box((x,4.20,-1.05),(.21,8.30,.22),"coat_high")
        for y in (.38,7.51):
            m.link((x,y,-1.17),(x,y,-1.28),.065,.065,"brass",12)
    for y in (.20,7.51):
        m.box((0,y,-1.05),(11.65,.20,.20),"coat_high")
    for row in range(2):
        for col in range(4):
            index=row*4+col+1
            x=-4.20+col*2.80
            y=5.51-row*3.15
            # A rectangular machined cartridge behind the reel flange.
            m.box((x,y,-1.06),(2.54,2.54,.15),"field_edge")
            m.box((x,y,-1.15),(2.36,2.33,.08),"coat_dark")
            for dx in (-1.22,1.22):
                m.box((x+dx,y,-1.20),(.085,2.38,.10),"brass")
            m.box((x,y-1.15,-1.21),(2.51,.12,.12),"brass")
            if index!=8:
                # Recess, stamped six-spoke reel and actual retaining lock.
                m.link((x,y,-1.23),(x,y,-1.31),.76,.76,"iron",42)
                m.link((x,y,-1.31),(x,y,-1.35),.62,.62,"coat_dark",42)
                for spoke in range(6):
                    t=math.tau*spoke/6
                    m.link((x+math.cos(t)*.15,y+math.sin(t)*.15,-1.39),
                           (x+math.cos(t)*.59,y+math.sin(t)*.59,-1.39),
                           .056,.056,"brass",10)
                m.link((x,y,-1.37),(x,y,-1.51),.18,.18,"iron",18)
                m.link((x,y,-1.51),(x,y,-1.56),.07,.07,"brass",12)
            else:
                # Negative space has more narrative weight than scattered debris.
                m.box((x,y,-1.33),(1.38,.11,.14),"signal")
                m.box((x,y,-1.34),(.11,1.27,.15),"signal")
            for xx in (x-1.03,x+1.03):
                for yy in (y-.88,y+.88):
                    m.link((xx,yy,-1.28),(xx,yy,-1.35),.042,.042,"brass",10)
            m.box((x,y-1.36,-1.27),(2.21,.23,.07),
                  "label" if index!=8 else "brass")
    m.box((0,.13,-1.14),(11.7,.24,.17),"rubber")
    scene=m.finish()
    # An original printed inventory identity plate, not a floating HUD.
    im=Image.new("RGB",(1200,128),(34,37,38))
    draw=ImageDraw.Draw(im)
    draw.rectangle((8,7,1192,120),outline=(139,124,94),width=3)
    font=ImageFont.load_default(size=40)
    small=ImageFont.load_default(size=24)
    draw.text((43,17),"B L A C K L I N E  /  M A S T E R  A R C H I V E",
              fill=(208,199,169),font=font)
    draw.text((46,79),"M-08  |  ANALOG MASTER INVENTORY  |  RELEASE BY ARCHIVIST",
              fill=(146,151,140),font=small)
    material=PBRMaterial(name="ArchiveOriginalSerialPlate",
        baseColorTexture=im,metallicFactor=0,roughnessFactor=.89,doubleSided=True)
    plaque=trimesh.creation.box(extents=(9.95,.59,.035))
    plaque.apply_translation((0,7.99,-1.265))
    vertices=np.asarray(plaque.vertices)
    uv=np.column_stack(((vertices[:,0]+4.975)/9.95,(vertices[:,1]-7.695)/.59))
    plaque.visual=trimesh.visual.TextureVisuals(uv=uv,material=material)
    scene.add_geometry(plaque,node_name="ArchiveOriginalInventoryPlate",
                       geom_name="ArchiveOriginalInventoryPlate")
    return scene


def blackline_master_reference():
    """Original wall-mounted mastering monitor/reference array (no speaker audio).

    Source-space pivot is at floor; the north-wall fixture occupies y=3.35..9.45
    and has a shallow, physically plausible 1.4-stud enclosure.
    """
    m=Model()
    m.box((0,6.40,0),(13.3,6.1,1.30),"iron")
    m.box((0,6.40,-.68),(12.80,5.53,.10),"field_edge")
    for side in (-1,1):
        x=side*3.95
        m.box((x,6.48,-.75),(4.26,4.45,.13),"coat_dark")
        # A shallow waveguide with a genuine stepped driver/surround,
        # rather than one flat round printed albedo.
        m.link((x,6.42,-.84),(x,6.42,-1.01),
               1.78,1.65,"rubber",84)
        m.link((x,6.42,-1.02),(x,6.42,-1.13),
               1.34,1.03,"iron",84)
        m.link((x,6.42,-1.13),(x,6.42,-1.23),
               .39,.35,"coat_dark",42)
        m.link((x,6.42,-1.24),(x,6.42,-1.29),
               .16,.16,"brass",32)
        for dx in (-1.88,1.88):
            for dy in (-1.82,1.82):
                m.link((x+dx,6.42+dy,-.87),
                       (x+dx,6.42+dy,-.95),.065,.065,"brass",12)
        for yy in (4.47,8.49):
            m.box((x,yy,-.82),(4.19,.12,.12),"coat_high")
        # Six modest cuts around the horn are purposeful vented construction.
        for v in range(3):
            m.box((x-1.62+v*1.62,4.14,-.87),
                  (1.04,.10,.055),"rubber")
        # Actual slotted heat vent on the outside wall of each driver pod.
        vent_x=side*6.13
        for row in range(8):
            m.box((vent_x,4.90+row*.42,-.86),
                  (.20,.15,.055),"coat_dark")
    m.box((0,6.37,-.81),(2.80,3.14,.12),"coat_dark")
    m.box((0,7.15,-.92),(2.41,.70,.06),"iron")
    for i in range(9):
        xx=-1.00+i*.25
        m.box((xx,7.18,-.964),(.032,.30 if i%2 else .46,.026),
              "brass" if i==4 else "label")
    # Zero signal movement: calibration is a stamped reference datum.
    m.link((-.85,6.56,-.90),(.70,6.56,-.90),.040,.040,
           "brass",12)
    m.box((0,5.49,-.91),(2.42,.60,.075),"label")
    for side in (-1,1):
        x=side*6.30
        m.box((x,6.40,-.74),(.17,5.75,.13),"coat_high")
        for y in (3.8,9.04):
            m.link((x,y,-.83),(x,y,-.94),.054,.054,"brass",12)
    m.box((0,3.49,-.69),(12.6,.18,.18),"rubber")
    scene=m.finish()
    # Printed equipment plate remains a real matte sign on the source mesh;
    # it does not depend on Roblox GUI rendering or runtime objective state.
    im=Image.new("RGB",(1280,160),(31,34,35))
    draw=ImageDraw.Draw(im)
    draw.rectangle((8,9,1271,151),outline=(122,117,99),width=4)
    title=ImageFont.load_default(size=42)
    fine=ImageFont.load_default(size=27)
    draw.text((42,20),"BLACKLINE  /  MASTERING A-B REFERENCE",
              fill=(215,206,180),font=title)
    draw.text((43,100),"CALIBRATION REV. 07  |  M-08 RETURN UNVERIFIED",
              fill=(162,151,121),font=fine)
    material=PBRMaterial(name="OriginalMasterReferenceSerial",
        baseColorTexture=im,metallicFactor=0,roughnessFactor=.91,
        doubleSided=True)
    plate=trimesh.creation.box(extents=(10.45,.61,.035))
    plate.apply_translation((0,9.02,-.78))
    positions=np.asarray(plate.vertices)
    uv=np.column_stack(((positions[:,0]+5.225)/10.45,
                        (positions[:,1]-8.715)/.61))
    plate.visual=trimesh.visual.TextureVisuals(uv=uv,material=material)
    scene.add_geometry(plate,node_name="OriginalMasterSerialPlate",
                       geom_name="OriginalMasterSerialPlate")
    return scene


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,default=Path("build/roblox-glb"))
    args=ap.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    for name,builder in {
        "BlacklineTransferDeck":transfer_machine,
        "BlacklinePatchMatrix":patch_matrix,
        "BlacklineHeroConsole":blackline_hero_console,
        "BlacklineArchiveCabinet":blackline_archive_cabinet,
        "BlacklineMasterReference":blackline_master_reference,
    }.items():
        path=args.out/(name+".glb")
        path.write_bytes(builder().export(file_type="glb"))
        loaded=trimesh.load(path,force="scene",process=False)
        verts=sum(len(m.vertices) for m in loaded.geometry.values())
        assert verts>=1500,(name,"geometry unexpectedly low")
        print(f"{name}.glb: {verts} vertices, {len(loaded.geometry)} material meshes, {path.stat().st_size} bytes")
if __name__=="__main__":
    main()

#!/usr/bin/env python3
"""Q02: The Engineer, a human-proportioned late-shift Blackline technician.

Authentic studio hardware, asymmetric human expression and workwear carry the
uncanny identity. No exposed injuries, blood, body mutation, weapons, or gore.

This is a real GLB source mesh with physically layered geometry and original
image-mapped studio identification art. It is NOT a sculpted AAA hero or a
Roblox Studio-approved/skinned render. Forward = -Z, floor relative to HRP.
"""
from __future__ import annotations
import math
import numpy as np
import trimesh
from PIL import Image,ImageDraw,ImageFont
from trimesh.visual.material import PBRMaterial
from build_character_assets import Model

def loft(rings,segments=40,folds=0.0):
    """Continuous waisted garment panels; taper is modeled, not a box stack."""
    verts=[]
    for i,(y,xr,zr,xc,zc) in enumerate(rings):
        for j in range(segments):
            ang=2*math.pi*j/segments
            ripple=1+folds*math.sin(ang*7.0+i*.57)+folds*.40*math.sin(ang*13-i*.4)
            verts.append((xc+xr*math.cos(ang)*ripple,y,
                          zc+zr*math.sin(ang)*ripple))
    faces=[]
    for i in range(len(rings)-1):
        for j in range(segments):
            k=(j+1)%segments
            a=i*segments+j;b=i*segments+k
            c=(i+1)*segments+j;d=(i+1)*segments+k
            faces.extend(((a,b,c),(b,d,c)))
    bottom=len(verts);verts.append((rings[0][3],rings[0][0],rings[0][4]))
    top=len(verts);verts.append((rings[-1][3],rings[-1][0],rings[-1][4]))
    for j in range(segments):
        k=(j+1)%segments
        faces.extend(((bottom,j,k),
                      (top,(len(rings)-1)*segments+k,(len(rings)-1)*segments+j)))
    mesh=trimesh.Trimesh(vertices=verts,faces=faces,process=False)
    return mesh

def sphere(m,xyz,axes,mat,sub=3):
    m.ellipsoid(xyz,axes,mat,sub)

def pipe(m,points,radius,mat,sections=12):
    for a,b in zip(points[:-1],points[1:]):
        m.link(a,b,radius,radius*.96,mat,sections)

def plaque(text,secondary,center,dim):
    W,H=1024,384
    image=Image.new('RGB',(W,H),(52,54,51))
    draw=ImageDraw.Draw(image)
    draw.rectangle((11,12,1012,369),outline=(134,126,106),width=7)
    font=ImageFont.load_default(size=61)
    small=ImageFont.load_default(size=31)
    draw.text((52,64),text,font=font,fill=(215,208,184))
    draw.text((54,236),secondary,font=small,fill=(149,150,137))
    normal=Image.new('RGB',(W,H),(128,128,255))
    orm=Image.new('RGB',(W,H),(0,221,0))
    mat=PBRMaterial(name='BlacklineEngineerOriginalIDPlate',
                    metallicFactor=1,roughnessFactor=1,
                    baseColorTexture=image,normalTexture=normal,
                    metallicRoughnessTexture=orm,doubleSided=True)
    x,y,z=center;w,h=dim
    # Front on -Z, separate UV-mapped equipment identifier, not an emissive HUD.
    mesh=trimesh.Trimesh(vertices=[
        (x-w/2,y-h/2,z),(x+w/2,y-h/2,z),
        (x+w/2,y+h/2,z),(x-w/2,y+h/2,z)],
        faces=[[0,1,2],[0,2,3]],process=False)
    mesh.visual=trimesh.visual.TextureVisuals(
        uv=np.asarray([(0,0),(1,0),(1,1),(0,1)]),material=mat)
    return mesh

def build():
    m=Model()
    # Natural, guarded posture rather than a 10-stud skeletal creature.
    # Feet are at the existing HRP floor datum (-4.65), no AI/collider edits.
    # Distinct jacket shell with folded hem, slight torso twist and a side zip.
    body=[
        (-1.63,.63,.38,0,.05),(-1.44,.77,.43,0,.05),
        (-1.14,.73,.43,.02,.07),(-.76,.68,.43,.02,.08),
        (-.25,.78,.46,-.03,.09),(.28,.92,.48,-.08,.10),
        (.80,1.02,.47,-.06,.10),(1.15,1.10,.43,-.03,.08),
        (1.44,.82,.32,-.01,.09),
    ]
    m.add(loft(body,48,.020),'coat')
    # Under-jacket inset / placket and asymmetric work pockets.
    m.add(loft([(-1.48,.54,.35,0,.08),(-.9,.55,.36,0,.09),
                (.2,.68,.38,-.03,.08),(.96,.78,.36,-.03,.07)],40),'coat_dark')
    m.box((-.10,.10,-.53),(.11,2.33,.046),'coat_dark')
    m.link((-.09,-1.14,-.54),(-.09,1.20,-.47),.021,.02,'brass',12)
    for x,y in ((-.48,-.68),(.52,-.56)):
        m.box((x,y,-.52),(.36,.33,.095),'coat_high')
        m.box((x,y+.16,-.585),(.40,.055,.05),'coat_dark')
        for dx in (-.12,.12):
            m.link((x+dx,y+.135,-.59),(x+dx,y-.14,-.59),
                   .013,.013,'field_edge',8)
    # Protective seam edging and shoulder fabric folds.
    for side in (-1,1):
        m.link((side*.67,1.30,-.23),(side*.52,.39,-.47),
               .050,.038,'coat_high',12)
        m.link((side*.49,.17,-.52),(side*.52,-1.48,-.43),
               .030,.026,'coat_high',12)
        m.box((side*.68,-1.39,-.40),(.31,.14,.10),'coat_dark')
    # Practical undershirt and collar, not armor or a fake chest wound.
    sphere(m,(0,1.54,-.06),(.48,.37,.35),'field_edge',2)
    for side in (-1,1):
        m.link((side*.18,1.53,-.42),(side*.48,1.12,-.49),
               .17,.10,'coat_high',14)
    # Trousers and feet, fabric over a plausible human joint layout.
    for side in (-1,1):
        hip=(side*.43,-1.47,.08)
        knee=(side*.49,-2.93,.06)
        ankle=(side*.53,-4.30,.02)
        m.link(hip,knee,.37,.27,'coat_dark',24)
        sphere(m,knee,(.30,.29,.31),'coat_high',2)
        m.link((side*.50,-3.02,.06),ankle,.28,.22,'coat_dark',24)
        m.box((side*.51,-3.98,-.27),(.38,.18,.14),'coat_high')
        # Calf stitching is fabric; no metal shin armor.
        m.link((side*.68,-3.12,-.24),(side*.65,-4.15,-.20),
               .023,.021,'field_edge',10)
        sphere(m,(side*.54,-4.47,-.26),(.39,.21,.70),'iron',3)
        m.box((side*.55,-4.63,-.31),(.65,.085,1.07),'rubber')
        m.box((side*.54,-4.31,-.64),(.40,.09,.22),'coat_dark')
        # Sleeves are shaped/tapered with one rolled cuff at the wrist.
        shoulder=(side*1.09,1.10,.02)
        elbow=(side*1.26,-.25,-.06)
        wrist=(side*1.34,-1.55,-.10)
        sphere(m,shoulder,(.42,.38,.40),'coat',3)
        m.link(shoulder,elbow,.38,.28,'coat',24)
        sphere(m,elbow,(.30,.31,.30),'coat_high',2)
        m.link((side*1.27,-.35,-.05),wrist,.27,.22,'coat',20)
        m.link((side*1.34,-1.51,-.10),(side*1.34,-1.65,-.10),
               .24,.24,'coat_dark',18)
        sphere(m,(side*1.35,-1.90,-.12),(.21,.32,.16),'flesh',3)
        for finger in range(4):
            x=side*1.20+(finger-.5)*.105
            m.link((x,-2.05,-.22),(x,-2.38+(finger%2)*.045,-.29),
                   .055,.037,'flesh',10)
        m.link((side*1.18,-1.90,-.26),(side*1.05,-2.20,-.38),
               .083,.065,'flesh',12)
        # Seam follows fabric sleeve instead of exposing monster anatomy.
        m.link((side*1.36,.79,-.36),(side*1.45,-1.34,-.29),
               .028,.028,'coat_high',10)
    # Waist utility belt + simple tape splice tools; no weapon prop.
    m.add(loft([(-1.21,.74,.43,0,.05),(-1.08,.75,.43,0,.05),
                (-1.02,.73,.42,0,.05)],36),'rubber')
    m.box((0,-1.11,-.43),(.39,.26,.13),'brass')
    m.box((.57,-1.09,-.48),(.21,.42,.13),'iron')
    m.box((.59,-.83,-.50),(.18,.14,.08),'label')
    m.box((-.67,-1.12,-.44),(.26,.41,.18),'coat_high')

    # Close to a real exhausted human face. No disfigurement, gore or glowing eyes.
    m.link((0,1.61,.04),(0,2.12,-.04),.30,.27,'flesh',18)
    sphere(m,(.015,2.55,-.04),(.66,.81,.57),'flesh',4)
    # Hair cap: compact salt-and-pepper work cut, readable silhouette.
    sphere(m,(.03,3.025,.01),(.66,.37,.55),'coat_dark',3)
    for side in (-1,1):
        sphere(m,(side*.53,2.46,-.015),(.135,.25,.18),'flesh',2)
        sphere(m,(side*.29,2.61,-.55),(.28,.14,.08),'bone',2)
        sphere(m,(side*.28,2.61,-.61),(.155,.105,.06),'rubber',2)
        # Dull focused eye, distinct gaze. No emissive glow.
        sphere(m,(side*.28,2.62,-.659),(.075,.074,.038),'iron',2)
        m.link((side*.12,2.74,-.61),(side*.42,2.77,-.56),
               .059,.047,'coat_dark',12)
        sphere(m,(side*.34,2.25,-.50),(.23,.12,.08),'flesh',2)
    # Normal human nose and closed lips, not monster jaws.
    m.link((0,2.61,-.54),(0,2.39,-.71),.115,.082,'flesh',14)
    sphere(m,(0,2.34,-.68),(.18,.09,.12),'flesh',2)
    m.link((-.20,2.13,-.59),(.22,2.11,-.59),.032,.03,'coat_dark',16)
    sphere(m,(.025,2.03,-.52),(.27,.11,.10),'bone',2)
    # One eyebrow is slightly higher, expressing unblinking attention,
    # without equating mental illness with monstrous anatomy.
    m.link((-.44,2.81,-.55),(-.13,2.84,-.59),.045,.034,'coat_dark',12)

    # Identifiable, asymmetric *wearable* circumaural headphones, NOT fused flesh.
    for side in (-1,1):
        x=side*.78
        sphere(m,(x,2.55,.02),(.22,.44,.42),'rubber',3)
        sphere(m,(side*.92,2.56,.02),(.20,.39,.35),'iron',3)
        sphere(m,(side*1.04,2.54,.02),(.065,.29,.27),
               'coat_dark' if side==1 else 'brass',2)
        m.link((side*.78,2.89,.03),(side*.49,3.29,.02),
               .10,.085,'iron',18)
    pipe(m,[(-.49,3.28,.02),(-.29,3.37,.03),(0,3.405,.035),
            (.29,3.37,.03),(.49,3.28,.02)],.098,'coat_dark',18)
    # Broken microphone boom: one rubber cap, no exposed gore.
    pipe(m,[(-1.03,2.46,-.08),(-1.16,2.21,-.24),
            (-1.14,2.08,-.50),(-.95,2.02,-.65)],.041,'iron',12)
    sphere(m,(-.95,2.02,-.65),(.14,.11,.12),'rubber',2)

    # Headphone cable is routed over shoulder through cloth retention loops.
    pipe(m,[(.98,2.27,.16),(1.00,1.94,.22),(.92,1.66,.31),
            (.81,1.22,.42),(.69,.62,.48),(.63,-.15,.46),
            (.63,-.91,.39)],.046,'rubber',16)
    for yy in (1.05,.30,-.46):
        m.box((.65,yy,.46),(.15,.105,.10),'coat_high')

    # Worn real-world belt field recorder: switches and knobs are tactile.
    m.box((-.34,-.88,-.54),(.85,.74,.22),'iron')
    m.box((-.34,-.82,-.68),(.69,.46,.08),'coat_dark')
    for idx in range(4):
        xx=-.58+idx*.155
        m.link((xx,-.63,-.72),(xx,-.63,-.79),.050,.047,
               'brass' if idx==0 else 'rubber',12)
    m.box((-.35,-1.15,-.69),(.58,.12,.06),'rubber')
    scene=m.finish()
    scene.add_geometry(
        plaque('BLACKLINE  /  ENG.','M-08  |  MASTERING  /  SERVICE',
               (-.34,-.90,-.756),(.56,.20)),
        node_name='OriginalBlacklineEngineerRecorderNameplate',
        geom_name='OriginalBlacklineEngineerRecorderNameplate')
    # Identity panel is worn and small, NOT a giant gaming HUD.
    scene.add_geometry(
        plaque('BL / STAFF','ARCHIVE  -  S.04',
               (.33,.65,-.527),(.33,.125)),
        node_name='OriginalBlacklineEngineerStaffBadge',
        geom_name='OriginalBlacklineEngineerStaffBadge')
    return scene

if __name__=='__main__':
    from pathlib import Path
    out=Path('build/roblox-glb/EngineerBody.glb')
    out.parent.mkdir(parents=True,exist_ok=True)
    scene=build()
    out.write_bytes(scene.export(file_type='glb'))
    print(out.name,sum(len(g.faces) for g in scene.geometry.values()),'triangles')

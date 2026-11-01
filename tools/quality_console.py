#!/usr/bin/env python3
"""Blackline's first quality-benchmark asset: a purpose-built analog console.

Real geometry and original UV-mapped images, not a runtime Roblox Part scatter.
The exported GLB remains visual-only; Kit owns its original invisible collider.
This is a modeled asset source, not a claim of AAA/TTK visual sign-off.

Coordinates are Roblox studs, floor y=0. The operator FRONT faces +Z
(Control A's occupied south approach); the raised meter bridge is at -Z.
"""
from __future__ import annotations

import math
from collections import defaultdict
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import trimesh
from trimesh.visual.material import PBRMaterial

TWO_PI=2.0*math.pi
TILT=math.atan(.21)

def rounded_outline(width:float,depth:float,radius:float,steps:int=6):
    radius=min(radius,width*.48,depth*.48)
    out=[]
    for cx,cz,start in (
        (width/2-radius,depth/2-radius,0),
        (-width/2+radius,depth/2-radius,90),
        (-width/2+radius,-depth/2+radius,180),
        (width/2-radius,-depth/2+radius,270),
    ):
        for j in range(steps+1):
            theta=math.radians(start+90*j/steps)
            out.append((cx+radius*math.cos(theta),cz+radius*math.sin(theta)))
    return out

def soft_case(width:float,height:float,depth:float,radius:float=.16,bevel:float=.065):
    """Rounded, beveled toolcase; actual curved perimeter, not a flat cube."""
    profile=[
        (0, width-2*bevel,depth-2*bevel,max(radius-bevel,.012)),
        (bevel,width,depth,radius),
        (height-bevel,width,depth,radius),
        (height,width-2*bevel,depth-2*bevel,max(radius-bevel,.012)),
    ]
    vertices=[]
    for y,w,d,r in profile:
        vertices.extend((x,y,z) for x,z in rounded_outline(w,d,r))
    n=len(rounded_outline(width,depth,radius))
    faces=[]
    for ring in range(len(profile)-1):
        for k in range(n):
            a=ring*n+k;b=ring*n+(k+1)%n
            c=(ring+1)*n+k;d=(ring+1)*n+(k+1)%n
            faces.extend(((a,c,b),(b,c,d)))
    # Fan caps are confined to planar section ends; no implicit Boolean operations.
    bottom=len(vertices);vertices.append((0,0,0))
    top=len(vertices);vertices.append((0,height,0))
    for k in range(n):
        faces.append((bottom,k,(k+1)%n))
        hi=(len(profile)-1)*n
        faces.append((top,hi+(k+1)%n,hi+k))
    mesh=trimesh.Trimesh(vertices=vertices,faces=faces,process=False)
    trimesh.repair.fix_normals(mesh,multibody=True)
    return mesh

def polygon_case():
    """Continuous sloping desk mass with a distinct operator edge and rear heel."""
    yz=[
        (-1.65,2.17),(-1.65,3.09),(-1.52,3.29),
        (-1.28,3.33),(1.29,2.79),(1.53,2.70),
        (1.63,2.51),(1.63,2.23),(1.43,2.15),(-1.43,2.15),
    ]
    # Beveled, inset end sections keep the cross-section from reading as a box.
    rings=[(-3.06,.94),(-2.98,1),(2.98,1),(3.06,.94)]
    vertices=[(x,y*scale+2.65*(1-scale),z*scale)
              for x,scale in rings for z,y in yz]
    faces=[];n=len(yz)
    for k in range(len(rings)-1):
        for j in range(n):
            a=k*n+j;b=k*n+(j+1)%n
            c=(k+1)*n+j;d=(k+1)*n+(j+1)%n
            faces.extend(((a,b,c),(b,d,c)))
    for i in range(1,n-1):
        faces.append((0,i+1,i))
        q=(len(rings)-1)*n
        faces.append((q,q+i,q+i+1))
    mesh=trimesh.Trimesh(vertices=vertices,faces=faces,process=False)
    trimesh.repair.fix_normals(mesh,multibody=True)
    return mesh

def transform(mesh,position,tilt:float=0.):
    mesh=mesh.copy()
    if tilt:
        mesh.apply_transform(trimesh.transformations.rotation_matrix(tilt,[1,0,0]))
    mesh.apply_translation(position)
    return mesh

def color_maps(rgb,metal,rough,seed,size=256):
    rng=np.random.default_rng(seed)
    noise=rng.normal(0,1,(size,size))
    # Restrained powder-coat texture: normal detail belongs to surfaces,
    # NOT alternating black-and-white noise used to mask rough modeling.
    variation=np.clip(noise*1.5,-4,4).astype(np.float32)
    col=np.clip(np.array(rgb)[None,None,:]+variation[:,:,None],0,255).astype('uint8')
    n=np.zeros((size,size,3),dtype=np.uint8)
    n[:,:,0]=128;n[:,:,1]=128;n[:,:,2]=255
    packed=np.zeros_like(n)
    packed[:,:,1]=np.clip(rough*255+variation*.9,0,255).astype(np.uint8)
    packed[:,:,2]=round(metal*255)
    return Image.fromarray(col,'RGB'),Image.fromarray(n,'RGB'),Image.fromarray(packed,'RGB')

PALETTE={
    'enamel':((55,60,61),.05,.69),
    'frame':((90,95,91),.62,.48),
    'rail':((44,48,49),.18,.78),
    'rubber':((25,28,29),.0,.91),
    'aluminum':((154,149,132),.71,.41),
    'dials':((201,192,167),.0,.85),
    'olive':((70,74,67),.10,.71),
    'meter':((155,132,88),.2,.66),
}
def material(name,rgb,metal,rough,seed):
    col,n,orm=color_maps(rgb,metal,rough,seed)
    return PBRMaterial(name=name,baseColorFactor=np.array([255,255,255,255],dtype=np.uint8),
                       metallicFactor=1.,roughnessFactor=1.,
                       baseColorTexture=col,normalTexture=n,
                       metallicRoughnessTexture=orm,doubleSided=False)

def print_atlas():
    """A single original 2048px control legend sheet, scaled to a real desk."""
    W,H=2048,1024
    im=Image.new('RGB',(W,H),(53,58,59))
    d=ImageDraw.Draw(im)
    font=ImageFont.load_default(size=23)
    small=ImageFont.load_default(size=17)
    faint=(143,151,140)
    high=(197,192,164)
    for ch in range(12):
        cx=int((ch+.5)*W/12)
        xlo=int(ch*W/12)
        d.line((xlo,22,xlo,H-24),fill=(28,32,33),width=3)
        d.text((cx-16,34),f'{ch+1:02d}',font=font,fill=high)
        d.text((cx-24,85),'TRIM',font=small,fill=faint)
        for y in range(180,405,42):
            d.line((cx-35,y,cx+35,y),fill=(83,87,82),width=2)
        d.text((cx-15,468),'EQ',font=small,fill=faint)
        for y in range(525,725,27):
            tick=34 if (y-525)%81==0 else 20
            d.line((cx-tick,y,cx-tick//3,y),fill=(137,140,131),width=3)
            d.line((cx+tick//3,y,cx+tick,y),fill=(137,140,131),width=3)
        d.text((cx-28,765),'FADER',font=small,fill=faint)
        d.text((cx-12,884),'0',font=small,fill=high)
        d.line((cx-52,958,cx+52,958),fill=(93,100,96),width=4)
    d.rectangle((6,7,W-7,H-7),outline=(103,106,97),width=8)
    n=Image.new('RGB',(W,H),(128,128,255))
    orm=Image.new('RGB',(W,H),(0,186,15))
    return im,n,orm

def bridge_atlas():
    W,H=1536,512
    im=Image.new('RGB',(W,H),(38,42,43))
    d=ImageDraw.Draw(im)
    wide=ImageFont.load_default(size=49)
    mid=ImageFont.load_default(size=34)
    small=ImageFont.load_default(size=23)
    d.rectangle((16,16,W-17,H-17),outline=(129,125,105),width=6)
    d.text((48,31),'B L A C K L I N E  /  M-08',font=wide,fill=(213,202,170))
    d.text((57,109),'ANALOG MIX SECTION   /   12 CH   /   30 IPS MASTER',font=mid,fill=(144,153,144))
    for k,channel in enumerate(('A  /  LEFT','B  /  RIGHT')):
        x=64+k*705
        d.rounded_rectangle((x,180,x+675,447),radius=22,fill=(169,153,120),outline=(93,80,63),width=5)
        d.rounded_rectangle((x+15,195,x+659,429),radius=15,fill=(198,189,159))
        d.text((x+34,211),channel,font=mid,fill=(61,63,56))
        for tick in range(13):
            xx=x+70+tick*46
            h=65 if tick%3==0 else 35
            d.line((xx,350,xx,350-h),fill=(85,84,74),width=3)
        d.line((x+80,354,x+481,275),fill=(115,52,44),width=6)
        d.ellipse((x+65,343,x+91,369),fill=(58,60,57))
    n=Image.new('RGB',(W,H),(128,128,255))
    orm=Image.new('RGB',(W,H),(0,215,0))
    return im,n,orm

def mapped_surface(vertices,uv,name,maps):
    mesh=trimesh.Trimesh(vertices=np.asarray(vertices,dtype=float),
                        faces=np.array(((0,1,2),(0,2,3))),process=False)
    color,n,orm=maps
    mat=PBRMaterial(name=name,baseColorFactor=np.array([255,255,255,255],dtype=np.uint8),
                    metallicFactor=1.,roughnessFactor=1.,
                    baseColorTexture=color,normalTexture=n,
                    metallicRoughnessTexture=orm,doubleSided=True)
    mesh.visual=trimesh.visual.TextureVisuals(uv=np.asarray(uv,dtype=float),material=mat)
    return mesh

def deck_y(z):
    return 3.02-.21*z

def build():
    geometries=defaultdict(list)
    def add(mesh,group):
        geometries[group].append(mesh)
    def block(group,center,extent,r=.075,tilt=0.):
        mesh=soft_case(extent[0],extent[1],extent[2],radius=r,bevel=min(.045,extent[1]/5))
        add(transform(mesh,(center[0],center[1]-extent[1]/2,center[2]),tilt),group)
    def knob(x,z,metal=False):
        y=deck_y(z)+.075
        stem=trimesh.creation.cylinder(radius=.047,height=.13,sections=16)
        # trimesh cylinders point up Z by default.
        stem.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
        add(transform(stem,(x,y+.07,z)),'frame')
        ring=trimesh.creation.cylinder(radius=.109,height=.16,sections=24)
        ring.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
        add(transform(ring,(x,y+.18,z)),'aluminum' if metal else 'rail')
        # Minuscule channel index is printed on the common UV deck atlas.
    # Left and right support columns are recessed behind the operator knee well.
    for side in (-1,1):
        x=side*2.79
        block('enamel',(x,1.30,.30),(.44,2.49,2.62),.20)
        block('frame',(x,2.40,.30),(.58,.15,2.75),.12)
        block('rubber',(x,.15,.90),(.50,.23,1.33),.09)
        block('rail',(x,1.22,-1.05),(.35,1.56,.21),.08)
    block('enamel',(0,.30,1.05),(5.12,.50,.52),.18)
    block('frame',(0,1.86,-1.38),(5.51,.66,.22),.11)
    add(polygon_case(),'enamel')
    # Separately built precision lip and inset operator rim.
    block('frame',(0,2.55,1.57),(5.86,.14,.16),.07)
    block('rubber',(0,2.53,1.665),(5.37,.06,.045),.025)
    for side in (-1,1):
        block('frame',(side*3.02,2.84,.08),(.12,.14,3.02),.05,tilt=TILT)
    # Meter bridge stands behind the operator's channel surface.
    block('frame',(0,3.49,-1.41),(5.86,1.12,.44),.18)
    block('enamel',(0,4.01,-1.29),(5.53,.19,.52),.085)
    block('rubber',(0,3.08,-1.15),(5.38,.105,.43),.055)

    # Unique, original 2k-resolution deck screen print mapped in local space.
    # UV in ascending X, ascending Z; the image exporter owns V orientation.
    top=[
        (-2.72,deck_y(1.23)+.028,1.23),
        (2.72,deck_y(1.23)+.028,1.23),
        (2.72,deck_y(-1.12)+.028,-1.12),
        (-2.72,deck_y(-1.12)+.028,-1.12),
    ]
    deck=mapped_surface(top,[(0,0),(1,0),(1,1),(0,1)],
                        'Blackline12ChannelScreenprint',print_atlas())
    add(deck,'_deck')
    # A true physical fader well for each of the 12 channels, with parked
    # thumbs at slightly different positions (nothing animates or flickers).
    for ch in range(12):
        x=-2.45+ch*(4.90/11)
        for z in (-.91,-.42,.08):
            knob(x,z,metal=(z==-.91))
        block('rubber',(x,deck_y(.72)+.031,.72),(.061,.04,.92),.028,tilt=TILT)
        fz=.38+(ch%5)*.125
        block('frame',(x,deck_y(fz)+.095,fz),(.24,.16,.28),.078,tilt=TILT)
        block('rubber',(x,deck_y(fz)+.184,fz),(.135,.024,.17),.04,tilt=TILT)
        block('aluminum',(x,deck_y(-1.1)+.08,-1.1),(.17,.06,.12),.045,tilt=TILT)
    # Important: real planar VU/serial artwork faces +Z toward the player.
    frontZ=-1.172
    panel=[
        (-2.57,3.20,frontZ), (2.57,3.20,frontZ),
        (2.57,4.04,frontZ),(-2.57,4.04,frontZ)
    ]
    add(mapped_surface(panel,[(0,0),(1,0),(1,1),(0,1)],
                       'Blackline12ChannelMeterBridge',bridge_atlas()),'_meter')
    for x in (-2.72,2.72):
        for y in (3.24,3.97):
            bolt=trimesh.creation.icosphere(subdivisions=1,radius=.045)
            add(transform(bolt,(x,y,frontZ+.045)),'aluminum')

    scene=trimesh.Scene()
    for group,meshes in geometries.items():
        if group=='_deck' or group=='_meter':
            for i,m in enumerate(meshes):
                scene.add_geometry(m,node_name=group+str(i),geom_name=group+str(i))
            continue
        merged=trimesh.util.concatenate(meshes)
        xyz=np.asarray(merged.vertices)
        # Fixed world-scale UV avoids per-part UV mismatch and atlas repetition.
        uv=np.column_stack((xyz[:,0]/3.8,xyz[:,2]/3.8))
        rgb,metal,rough=PALETTE[group]
        merged.visual=trimesh.visual.TextureVisuals(
            uv=uv,material=material('BlacklineConsole_'+group,rgb,metal,rough,
                                   8627+sum(ord(c) for c in group)))
        scene.add_geometry(merged,node_name='Machined_'+group,geom_name='Machined_'+group)
    return scene

if __name__=='__main__':
    from pathlib import Path
    out=Path('build/roblox-glb/BlacklineHeroConsole.glb')
    out.parent.mkdir(parents=True,exist_ok=True)
    scene=build()
    out.write_bytes(scene.export(file_type='glb'))
    print('Wrote',out,'triangles',sum(len(g.faces) for g in scene.geometry.values()))

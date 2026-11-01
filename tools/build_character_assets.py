#!/usr/bin/env python3
"""Original cosmetic character assets. Not Roblox humanoid rigs.

Builds the Engineer's replaceable rigid prototype body and modular R15 uniform
accessories. Animation-ready skinning, anatomy sculpting and texture baking are
separate art gates; a valid GLB does NOT constitute a TTK-class finished model.
Coordinate convention: Roblox-compatible units, local pivot at HRP (Engineer),
UpperTorso/Head attachment (player cosmetics), forward is negative Z.
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path
from PIL import Image
import hashlib
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

COLORS={
 "coat":((0.115,0.133,0.139,1),0.03,0.93),
 "coat_high":((0.17,0.19,0.19,1),0.02,0.82),
 "coat_dark":((0.062,0.068,0.07,1),0.01,0.97),
 "bone":((0.30,0.27,0.225,1),0.0,0.89),
 "flesh":((0.20,0.17,0.15,1),0.01,0.91),
 "iron":((0.20,0.23,0.24,1),0.78,0.68),
 "brass":((0.39,0.27,0.15,1),0.76,0.47),
 "rubber":((0.055,0.06,0.06,1),0.0,0.97),
 "signal":((0.33,0.06,0.038,1),0.16,0.57),
 "visor":((0.085,0.16,0.16,1),0.27,0.36),
 "label":((0.55,0.52,0.43,1),0.0,0.83),
 "field_cloth":((0.18,0.21,0.20,1),0.01,0.93),
 "field_edge":((0.105,0.12,0.12,1),0.01,0.95),
}
# Deterministic original microscopic material pattern, baked into the four
# character GLBs. Packed glTF metal/rough texture: G=roughness, B=metalness.
# This is a technically correct image-mapped first pass; a physically sampled
# and hand-painted high/low-poly bake is still required for final visual approval.
MATERIAL_PIXELS=384

def image_material(name):
 color,metal,rough=COLORS[name]
 seed=int.from_bytes(hashlib.sha256(name.encode("utf-8")).digest()[:8],"big")
 rng=np.random.default_rng(seed)
 n=MATERIAL_PIXELS
 coarse=rng.normal(0,1,(24,24))
 coarse=np.asarray(Image.fromarray(coarse.astype("float32"),"F").resize(
     (n,n),Image.Resampling.BILINEAR),dtype=np.float32)
 fine=rng.normal(0,1,(n,n)).astype(np.float32)
 yy,xx=np.mgrid[0:n,0:n]
 is_fabric=name in {"coat","coat_high","coat_dark","field_cloth","field_edge"}
 is_metal=name in {"iron","brass","signal"}
 weave=(np.sin(xx*math.pi*.55)*np.sin(yy*math.pi*.55)) if is_fabric else 0
 scratch=(np.sin(xx*.21+coarse*.4)**20)*.3 if is_metal else 0
 height=coarse*.3+fine*.11+weave*.16+scratch*.16
 variability=height*(.048 if is_fabric else .072 if is_metal else .037)
 base=np.array(color[:3],dtype=float)[None,None,:]
 color_map=np.clip((base+variability[:,:,None])*255,0,255).astype(np.uint8)
 gx=np.gradient(height,axis=1); gy=np.gradient(height,axis=0)
 # Low-amplitude normals avoid high-frequency sparkle under a moving torch.
 power=.085 if is_fabric else .13 if is_metal else .075
 nx=-gx*power;ny=-gy*power;nz=np.ones_like(nx)
 mag=np.sqrt(nx**2+ny**2+nz**2)
 normal=np.stack(((nx/mag*.5+.5)*255,(ny/mag*.5+.5)*255,
                  (nz/mag*.5+.5)*255),axis=-1).clip(0,255).astype(np.uint8)
 rr=np.clip((rough+height*.026)*255,0,255).astype(np.uint8)
 mm=np.clip((metal+height*.008)*255,0,255).astype(np.uint8)
 packed=np.zeros((n,n,3),dtype=np.uint8)
 packed[:,:,1]=rr;packed[:,:,2]=mm
 return PBRMaterial(
     name=name,baseColorFactor=np.array([255,255,255,255],dtype=np.uint8),
     metallicFactor=1.0,roughnessFactor=1.0,
     baseColorTexture=Image.fromarray(color_map,"RGB"),
     normalTexture=Image.fromarray(normal,"RGB"),
     metallicRoughnessTexture=Image.fromarray(packed,"RGB"),doubleSided=False,
 )

class Model:
 def __init__(self):
  self.meshes={name:[] for name in COLORS}
 def add(self,mesh,material):
  assert material in self.meshes
  mesh.remove_unreferenced_vertices()
  self.meshes[material].append(mesh)
 def ellipsoid(self,point,radii,mat,subdivision=2):
  mesh=trimesh.creation.icosphere(subdivisions=subdivision,radius=1)
  mesh.apply_scale(radii)
  mesh.apply_translation(point)
  self.add(mesh,mat)
 def box(self,point,dims,mat):
  mesh=trimesh.creation.box(extents=dims)
  mesh.apply_translation(point)
  self.add(mesh,mat)
 def link(self,a,b,r0,r1,mat,sections=14):
  a,b=np.asarray(a,dtype=float),np.asarray(b,dtype=float)
  delta=b-a
  length=np.linalg.norm(delta)
  assert length>1e-4
  mesh=trimesh.creation.conical_frustum(
   radius_top=r1,radius_base=r0,height=length,sections=sections) if hasattr(
       trimesh.creation,"conical_frustum") else None
  if mesh is None:
   # Side surface from two rings, explicitly capped. Prevents hard cuboid limbs.
   ang=np.linspace(0,2*math.pi,sections,endpoint=False)
   xy=np.stack((np.cos(ang),np.sin(ang)),axis=1)
   vertices=np.concatenate((np.column_stack((xy*r0,np.zeros(sections))),
                            np.column_stack((xy*r1,np.full(sections,length))),
                            np.array([[0,0,0],[0,0,length]])),axis=0)
   triangles=[]
   for i in range(sections):
    j=(i+1)%sections
    triangles.extend([[i,j,sections+j],[i,sections+j,sections+i],
                      [2*sections,j,i],[2*sections+1,sections+i,sections+j]])
   mesh=trimesh.Trimesh(vertices=vertices,faces=triangles,process=False)
  matrix=trimesh.geometry.align_vectors([0,0,1],delta)
  mesh.apply_transform(matrix)
  mesh.apply_translation(a)
  self.add(mesh,mat)
 def finish(self):
  scene=trimesh.Scene()
  for name,meshes in self.meshes.items():
   if not meshes:continue
   mesh=trimesh.util.concatenate(meshes)
   # Two dominant dimensions preserve stable texel density; UV tiling is
   # mapped in physical model units, rather than normalized separately per part.
   coords=np.asarray(mesh.vertices,dtype=np.float64)
   scales=np.ptp(coords,axis=0)
   axes=np.argsort(scales)[-2:]
   uv=np.asarray(coords[:,axes]/1.7,dtype=np.float64)
   mesh.visual=trimesh.visual.TextureVisuals(
       uv=uv,material=image_material(name))
   scene.add_geometry(mesh,node_name="PBR_"+name,geom_name="PBR_"+name)
  return scene

def engineer_body():
 m=Model()
 # Gaunt late-shift repair worker, anatomy intentionally incompatible with a
 # normal player: concave rib cage, overlong forearms, torsion and bad posture.
 m.ellipsoid((0,0.84,0.09),(1.00,1.59,.56),"coat",3)
 m.ellipsoid((0,-1.05,.10),(.71,.86,.45),"coat_dark",2)
 m.ellipsoid((0,1.95,.12),(1.48,.31,.53),"coat_high",2)
 m.ellipsoid((-.17,0.60,-.40),(.61,1.12,.17),"coat",2)
 m.ellipsoid((.56,0.55,-.39),(.49,1.09,.16),"coat_high",2)
 # Uneven coat hem / open split, reinforced binding and tool-harness silhouette.
 for side in (-1,1):
  m.link((side*.45,-1.14,.0),(side*.57,-2.65,-.05),.39,.27,"coat_high",12)
  m.box((side*.53,-1.23,-.53),(.27,1.40,.12),"coat_dark")
  m.link((side*1.30,1.64,.02),(side*1.70,.35,-.13),.37,.25,"coat",16)
  m.ellipsoid((side*1.68,.38,-.13),(.28,.39,.27),"coat_high",2)
  m.link((side*1.73,.31,-.14),(side*1.97,-1.72,-.17),.23,.13,"flesh",14)
  m.ellipsoid((side*2.01,-2.02,-.22),(.23,.43,.17),"flesh",2)
  for i in (-1,0,1):
   m.link((side*2.01+i*.075,-2.21,-.28),
          (side*2.02+i*.08,-2.73,-.31),.07,.043,"bone",10)
  m.link((side*.46,-1.53,.05),(side*.58,-3.05,-.05),.40,.29,"coat",16)
  m.ellipsoid((side*.59,-3.07,-.03),(.35,.29,.33),"iron",2)
  m.link((side*.60,-3.14,-.04),(side*.65,-4.37,-.04),.29,.20,"coat_dark",14)
  m.ellipsoid((side*.66,-4.57,-.27),(.32,.21,.68),"iron",2)
  m.box((side*.65,-4.58,-.48),(.5,.15,.52),"rubber")
  m.link((side*.80,1.22,-.28),(side*.28,-1.23,-.50),.072,.045,"iron",10)
  m.box((side*.69,.60,-.55),(.19,.65,.13),"brass")
 # A service harness with field-repaired analog hearing hardware.
 m.box((.12,.45,-.66),(.85,1.03,.23),"iron")
 m.box((.15,.65,-.81),(.62,.52,.07),"visor")
 m.link((.1,.69,-.85),(.37,.44,-.86),.03,.02,"signal",8)
 m.box((-.4,-.78,-.57),(.75,.31,.18),"brass")
 # The technician was incorporated into the studio equipment. A damaged
 # insulating harness/analog record counter reads in silhouette, not HUD text.
 m.box((-.54,.91,-.69),(.26,.62,.17),"rubber")
 m.link((-.57,1.11,-.76),(-.51,.61,-.76),.039,.03,"iron",12)
 m.box((.70,.17,-.59),(.21,.75,.14),"coat_high")
 m.box((.70,-.23,-.65),(.32,.13,.10),"brass")
 for x in (-.53,-.33,-.13,.07):
  m.box((x,-.75,-.70),(.09,.11,.055),"rubber")
 # Upright neck, destroyed face with apertures, no stereotypical skull mask.
 m.link((0,2.2,0),(.02,3.14,-.02),.30,.25,"flesh",18)
 m.ellipsoid((.04,3.73,-.08),(.71,.99,.65),"flesh",3)
 m.ellipsoid((0,3.28,-.31),(.44,.32,.50),"bone",2)
 for side in (-1,1):
  m.ellipsoid((side*.29,3.96,-.67),(.22,.14,.11),"rubber",2)
  m.link((side*.34,3.50,-.65),(side*.55,4.07,-.45),.055,.04,"iron",10)
 m.box((0,3.46,-.69),(.61,.10,.08),"rubber")
 m.box((0,4.41,-.38),(1.04,.23,.16),"iron")
 for offset in (-.45,.45):
  m.box((offset,1.53,-.47),(.26,.38,.18),"brass")
 return m.finish()

def operator_vest():
 # Root is R15 UpperTorso center. Vest does not obscure the rig's limb joints.
 m=Model()
 m.ellipsoid((0,-.02,.02),(1.04,.90,.56),"field_cloth",3)
 for side in (-1,1):
  m.box((side*.68,0,-.54),(.21,1.49,.14),"field_edge")
  m.box((side*.74,-.21,-.63),(.55,.51,.14),"field_cloth")
  m.box((side*.74,-.17,-.73),(.42,.13,.05),"iron")
 m.box((0,-.50,-.59),(1.65,.18,.14),"field_edge")
 m.box((0,.37,-.57),(1.37,.27,.12),"iron")
 for i in range(5):
  m.box((-.49+i*.245,.21,-.67),(.08,.09,.09),"brass")
 m.box((-.02,-.38,-.68),(.58,.30,.10),"label")
 # Durable stitched strap lines, integrated service loops and seams, not
 # glowing armor. Backing remains the existing Roblox R15 UpperTorso.
 for side in (-1,1):
  m.link((side*.65,.72,-.38),(side*.51,-.67,-.52),.074,.052,"field_edge",10)
  m.box((side*.75,.53,-.50),(.15,.22,.10),"iron")
  m.link((side*.45,.61,-.566),(side*.45,-.70,-.566),
         .022,.022,"field_edge",8)
  m.box((side*.47,-.61,-.64),(.27,.19,.095),"field_cloth")
 # Left-breast crew identity; no false emissive patch or live player marker.
 m.box((-.39,.035,-.654),(.42,.19,.043),"label")
 m.box((-.39,.036,-.691),(.31,.035,.026),"coat_dark")
 m.box((.12,-.39,-.733),(.22,.10,.06),"rubber")
 return m.finish()

def operator_mask():
 # Root at R15 Head. Built as low-profile breathing/dust PPE, not full replacement.
 m=Model()
 m.ellipsoid((0,-.28,-.58),(.58,.36,.24),"field_edge",2)
 m.ellipsoid((0,-.25,-.77),(.37,.22,.11),"iron",2)
 for side in (-1,1):
  m.link((side*.42,-.15,-.69),(side*.74,-.07,-.16),.066,.05,"rubber",12)
  m.ellipsoid((side*.28,-.23,-.89),(.15,.12,.07),"rubber",2)
  m.ellipsoid((side*.27,-.245,-.943),(.125,.10,.035),"iron",2)
  for i in range(3):
   m.box((side*.27,-.315+i*.052,-.973),(.17,.018,.014),"rubber")
 m.box((0,-.275,-.896),(.22,.055,.03),"field_cloth")
 return m.finish()

def operator_pack():
 # Root at UpperTorso, behind the shoulder plane. Keep height under head.
 m=Model()
 m.ellipsoid((0,-.09,.70),(.69,.80,.36),"field_edge",3)
 m.box((0,-.15,1.04),(1.12,.62,.16),"field_cloth")
 m.box((0,.44,.96),(.87,.22,.17),"iron")
 m.box((0,-.53,1.0),(.71,.15,.16),"brass")
 for side in (-1,1):
  m.link((side*.54,.63,.45),(side*.61,-.56,.56),.08,.055,"rubber",12)
 m.box((.2,-.16,1.15),(.25,.18,.08),"label")
 # Service-routed cable is sheathed against the pack, with a modest buckle
 # and one visible stitched seam; no radio signal or gear is simulated.
 m.link((-.48,.50,1.02),(-.47,-.33,1.10),.038,.033,"rubber",12)
 m.box((-.47,-.20,1.14),(.18,.11,.08),"iron")
 m.box((0,-.68,.94),(.86,.068,.074),"field_edge")
 m.box((.21,-.16,1.195),(.16,.036,.027),"coat_dark")
 return m.finish()

# Articulated, correctly-pivoted *rigid* body sections. These are not smooth
# skin-weighted meshes yet. They let Motor6D joints provide an expressive,
# readable gait with no dependence on Roblox default avatar animations.
def engineer_rig_torso():
 m=Model()
 m.ellipsoid((0,.71,.05),(1.02,1.53,.54),"coat",3)
 m.ellipsoid((0,-.97,.09),(.70,.84,.43),"coat_dark",2)
 m.ellipsoid((0,1.80,.09),(1.35,.30,.53),"coat_high",2)
 for side in (-1,1):
  m.link((side*.52,1.45,-.13),(side*.36,-1.30,-.45),.14,.09,"field_edge",14)
  m.box((side*.41,-1.35,-.34),(.38,1.34,.20),"coat_high")
  m.box((side*.59,.65,-.54),(.25,.69,.14),"brass")
 for row in range(4):
  m.box((0,1.26-row*.39,-.56),(1.10-row*.10,.065,.09),"bone")
 m.box((.14,.55,-.64),(.88,.94,.20),"iron")
 m.box((.14,.72,-.78),(.62,.40,.06),"visor")
 m.box((-.25,-.67,-.61),(.59,.22,.11),"brass")
 return m.finish()

def engineer_rig_head():
 m=Model()
 # Pivot: face centre is 3.68 studs above HRP.
 m.ellipsoid((.03,.08,-.06),(.72,.98,.65),"flesh",3)
 m.ellipsoid((0,-.42,-.29),(.43,.33,.46),"bone",2)
 for side in (-1,1):
  m.ellipsoid((side*.30,.29,-.68),(.24,.16,.10),"rubber",2)
  m.link((side*.37,-.08,-.61),(side*.55,.51,-.49),.065,.05,"iron",12)
  # Headphone cans, wing plates and restrained signal window.
  m.ellipsoid((side*.91,.03,-.01),(.25,.52,.45),"iron",2)
  m.box((side*1.14,.05,-.01),(.12,.47,.52),"rubber")
  m.box((side*1.22,.10,-.02),(.05,.20,.24),"signal")
  m.link((side*.91,.43,0),(side*.50,1.14,-.03),.11,.085,"brass",12)
 m.link((-.52,1.19,0),(.52,1.19,0),.13,.11,"iron",18)
 m.box((0,-.28,-.71),(.67,.08,.12),"rubber")
 # Small faceplate retention bolts and an asymmetrical service lead;
 # deliberately no additional eye glow or attack feedback mechanism.
 for side in (-1,1):
  m.ellipsoid((side*.51,.48,-.59),(.08,.08,.045),"brass",1)
 m.link((-.63,.65,-.48),(-.86,.28,-.31),.048,.031,"rubber",12)
 m.link((-1.14,-.22,-.09),(-1.36,-.52,-.87),.055,.04,"iron",12)
 m.ellipsoid((-1.37,-.55,-.91),(.16,.14,.18),"rubber",2)
 return m.finish()

def engineer_rig_arm(side):
 m=Model()
 # Origin: shoulder centre. Forearm and hooked fingers form one articulated
 # group in this baseline; future elbow/hand bones can split it further.
 m.ellipsoid((0,0,0),(.39,.43,.37),"coat_high",2)
 m.link((0,-.16,-.03),(side*.15,-1.54,-.13),.36,.24,"coat",16)
 m.ellipsoid((side*.15,-1.58,-.13),(.27,.31,.27),"iron",2)
 m.link((side*.16,-1.72,-.15),(side*.29,-3.57,-.20),.23,.15,"flesh",16)
 m.ellipsoid((side*.32,-3.81,-.25),(.24,.39,.20),"flesh",2)
 m.box((side*.25,-3.54,-.26),(.39,.17,.35),"brass")
 for i in (-1,0,1):
  m.link((side*.32+i*.10,-4.06,-.33),
         (side*.32+i*.11,-4.58,-.42),.064,.036,"bone",10)
 m.link((side*.10,-.16,-.35),(side*.37,-2.98,-.41),.066,.044,"iron",10)
 return m.finish()

def engineer_rig_leg(side):
 m=Model()
 # Origin: pelvis. Y=-3.3 sits at the floor with HRP height ~4.0.
 m.ellipsoid((0,-.34,0),(.43,.59,.43),"coat_high",2)
 m.link((0,-.18,0),(side*.08,-1.54,-.06),.40,.28,"coat",16)
 m.ellipsoid((side*.08,-1.61,-.07),(.34,.27,.34),"iron",2)
 m.link((side*.08,-1.70,-.07),(side*.16,-2.99,-.03),.28,.21,"coat_dark",16)
 m.ellipsoid((side*.16,-3.23,-.31),(.34,.22,.71),"iron",2)
 m.box((side*.16,-3.29,-.51),(.49,.14,.60),"rubber")
 m.box((side*.15,-2.62,-.29),(.35,.17,.12),"brass")
 return m.finish()

def main():
 parser=argparse.ArgumentParser()
 parser.add_argument("--out",type=Path,default=Path("build/roblox-glb"))
 args=parser.parse_args()
 args.out.mkdir(parents=True,exist_ok=True)
 for name,builder in {
     "EngineerBody":engineer_body,
     "FieldOperatorVest":operator_vest,
     "FieldOperatorMask":operator_mask,
     "FieldOperatorPack":operator_pack,
     "EngineerRigTorso":engineer_rig_torso,
     "EngineerRigHead":engineer_rig_head,
     "EngineerRigArmLeft":lambda:engineer_rig_arm(-1),
     "EngineerRigArmRight":lambda:engineer_rig_arm(1),
     "EngineerRigLegLeft":lambda:engineer_rig_leg(-1),
     "EngineerRigLegRight":lambda:engineer_rig_leg(1),
 }.items():
  path=args.out/(name+".glb")
  path.write_bytes(builder().export(file_type="glb"))
  src=trimesh.load(path,force="scene",process=False)
  verts=sum(len(m.vertices) for m in src.geometry.values())
  assert verts>300,(name,"unexpectedly simplified mesh")
  print(f"{name}.glb: {verts} vertices, {len(src.geometry)} material meshes, {path.stat().st_size} bytes")
if __name__=="__main__":main()

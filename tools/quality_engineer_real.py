#!/usr/bin/env python3
"""Realistic Blackline Engineer from a CC0 anatomically modeled, textured adult.

Source: Innerscene 'Daniel', CC0, MakeHuman-derived realistic male/clothing.
https://www.innerscene.com/tools/library/3d-parts/daniel-3d-person-standing-casual-f788af5a
Source GLB is downloaded in GitHub Actions and SHA-256 checked; assets are not
copy/pasted from commercial games. Additional headphone/field-monitor geometry,
original ID artwork and wardrobe retint are made for Dead Air.

Forward: -Z. Floor is y=-4 Roblox studs; root center is y=0. Model is STATIC
and needs glTF weighted skin export, which build_skinned_engineer.py provides.
"""
from __future__ import annotations
from pathlib import Path
import math
import numpy as np
import trimesh
import vtk
from vtk.util.numpy_support import numpy_to_vtk, vtk_to_numpy, numpy_to_vtkIdTypeArray
from PIL import Image,ImageDraw,ImageFont
from trimesh.visual.material import PBRMaterial

SCALE=3.62
OFFSET=-4.00

# Every element of the original anatomical sculpt retains UVs after decimation.
def reduce_uv(mesh:trimesh.Trimesh,reduction:float)->trimesh.Trimesh:
    if reduction<=0 or len(mesh.faces)<400:return mesh.copy()
    pts=vtk.vtkPoints()
    pts.SetData(numpy_to_vtk(np.ascontiguousarray(mesh.vertices,dtype=np.float32),deep=True))
    faces=np.column_stack((np.full(len(mesh.faces),3,dtype=np.int64),mesh.faces.astype(np.int64)))
    polygons=vtk.vtkCellArray()
    polygons.SetCells(len(mesh.faces),numpy_to_vtkIdTypeArray(faces.ravel(),deep=True))
    poly=vtk.vtkPolyData();poly.SetPoints(pts);poly.SetPolys(polygons)
    coords=numpy_to_vtk(np.ascontiguousarray(mesh.visual.uv,dtype=np.float32),deep=True)
    coords.SetNumberOfComponents(2);coords.SetName('TCoords')
    poly.GetPointData().SetTCoords(coords)
    simplify=vtk.vtkDecimatePro();simplify.SetInputData(poly)
    simplify.SetTargetReduction(reduction);simplify.PreserveTopologyOn()
    simplify.SplittingOff();simplify.BoundaryVertexDeletionOff()
    simplify.Update();out=simplify.GetOutput()
    tris=vtk_to_numpy(out.GetPolys().GetConnectivityArray()).reshape(-1,3)
    verts=vtk_to_numpy(out.GetPoints().GetData()).astype(np.float64)
    uvs=vtk_to_numpy(out.GetPointData().GetTCoords()).astype(np.float64)
    result=trimesh.Trimesh(vertices=verts,faces=tris,process=False)
    result.visual=trimesh.visual.TextureVisuals(uv=uvs,material=mesh.visual.material)
    return result


def recolor(image:Image.Image,name:str)->Image.Image:
    img=image.convert('RGBA')
    img.thumbnail((1024,1024),Image.Resampling.LANCZOS)
    p=np.asarray(img,dtype=np.float32).copy()
    if name=='male_casualsuit05':
        rgb=p[:,:,:3]
        # Preserve photographic weave / wrinkles while replacing the denim and
        # burgundy stripes with worn coal-grey technician garments.
        lum=.21*rgb[:,:,0]+.72*rgb[:,:,1]+.07*rgb[:,:,2]
        blue=(rgb[:,:,2]>rgb[:,:,0]*1.17)&(rgb[:,:,2]>rgb[:,:,1]*1.06)&(lum>35)
        red=(rgb[:,:,0]>rgb[:,:,1]*1.25)&(rgb[:,:,0]>rgb[:,:,2]*1.24)&(lum>32)
        shade=np.clip(36+lum*.72,29,182)
        for c,offset in enumerate((-3,0,2)):
            rgb[:,:,c]=np.where(blue,np.clip(shade+offset,0,255),rgb[:,:,c])
        for c,offset in enumerate((3,0,-4)):
            rgb[:,:,c]=np.where(red,np.clip(shade*.85+offset,0,255),rgb[:,:,c])
        rgb[:,:,:]=np.where((lum>15)[:,:,None],rgb*.92,rgb)
    elif name=='shoes01':
        p[:,:,:3]*=.73
    elif name=='short01':
        p[:,:,:3]*=.74
    return Image.fromarray(np.clip(p,0,255).astype(np.uint8),'RGBA')


def pbr_from_old(old,name):
    im=getattr(old,'baseColorTexture',None)
    if im is not None:im=recolor(im,name)
    normal=getattr(old,'normalTexture',None)
    if normal is not None:
        normal=normal.convert('RGB');normal.thumbnail((1024,1024),Image.Resampling.LANCZOS)
    # Retain original anatomical skin and fabric map, as opposed to noise maps.
    return PBRMaterial(name='LastListener_'+name,
        baseColorTexture=im,normalTexture=normal,
        baseColorFactor=np.array([255,255,255,255],dtype=np.uint8),
        metallicFactor=.02,roughnessFactor=.81,
        alphaMode=getattr(old,'alphaMode','OPAQUE') or 'OPAQUE',
        doubleSided=bool(getattr(old,'doubleSided',False)))


def rod(points,radius,material,segments=16):
    points=np.asarray(points,dtype=float)
    vertices=[]
    for i,c in enumerate(points):
        tangent=(points[min(i+1,len(points)-1)]-points[max(0,i-1)])
        tangent=tangent/max(np.linalg.norm(tangent),1e-9)
        ref=np.array([0,0,1.]) if abs(tangent[2])<.85 else np.array([0,1.,0])
        n=np.cross(tangent,ref);n/=np.linalg.norm(n)
        binormal=np.cross(tangent,n)
        for j in range(segments):
            a=2*math.pi*j/segments
            vertices.append(c+radius*(math.cos(a)*n+math.sin(a)*binormal))
    faces=[]
    for i in range(len(points)-1):
        for j in range(segments):
            a=i*segments+j;b=i*segments+(j+1)%segments
            c=(i+1)*segments+j;d=(i+1)*segments+(j+1)%segments
            faces.extend(((a,c,b),(b,c,d)))
    faces.extend([(0,j+1,j) for j in range(1,segments-1)])
    top=(len(points)-1)*segments
    faces.extend([(top,top+j,top+j+1) for j in range(1,segments-1)])
    m=trimesh.Trimesh(vertices=vertices,faces=faces,process=False)
    m.visual.material=material
    return m


def earcup(center,side,radius,depth,material):
    # Lathed nested ear cushions and brushed metal enclosure in actual 3D.
    y,z=center[1],center[2];x=center[0]
    sections=48
    profile=[(0,radius*.62),(.008,radius),(.024,radius),
             (.034,radius*.90),(.044,radius*.78),(.047,radius*.44)]
    vv=[]
    for dx,r in profile:
        for j in range(sections):
            angle=math.tau*j/sections
            vv.append((x+side*dx,y+math.cos(angle)*r,z+math.sin(angle)*r))
    ff=[]
    for i in range(len(profile)-1):
        for j in range(sections):
            a=i*sections+j;b=i*sections+(j+1)%sections
            c=(i+1)*sections+j;d=(i+1)*sections+(j+1)%sections
            ff.extend(((a,b,c),(b,d,c)))
    mesh=trimesh.Trimesh(vertices=vv,faces=ff,process=False)
    mesh.visual.material=material
    return mesh


def label_plate(title,subtitle,size,center):
    W,H=768,256
    im=Image.new('RGB',(W,H),(47,48,46));draw=ImageDraw.Draw(im)
    draw.rounded_rectangle((8,8,W-9,H-9),radius=16,outline=(156,151,129),width=6)
    f=ImageFont.load_default(size=36);sm=ImageFont.load_default(size=24)
    draw.text((38,43),title,font=f,fill=(212,207,185))
    draw.text((39,159),subtitle,font=sm,fill=(167,168,154))
    pbr=PBRMaterial(name='LastListenerOriginalBadging_'+title,
                    baseColorTexture=im,
                    metallicFactor=.1,roughnessFactor=.68,doubleSided=True)
    x,y,z=center;w,h=size
    positions=np.array([(x-w/2,y-h/2,z),(x+w/2,y-h/2,z),
                        (x+w/2,y+h/2,z),(x-w/2,y+h/2,z)],dtype=float)
    mesh=trimesh.Trimesh(vertices=positions,faces=[[0,1,2],[0,2,3]],process=False)
    mesh.visual=trimesh.visual.TextureVisuals(
        uv=np.array([(0,0),(1,0),(1,1),(0,1)],dtype=float),material=pbr)
    return mesh


def cushion_ring(center,r_major,tube,material):
    """Actual open annular ear cushion, rather than three flat face-covering discs."""
    x,y,z=center
    around=36;roundness=10
    vv=[];ff=[]
    for a in range(around):
        t=math.tau*a/around
        for b in range(roundness):
            u=math.tau*b/roundness
            rr=r_major+tube*math.cos(u)
            vv.append((x+tube*.66*math.sin(u),
                       y+rr*math.cos(t),z+rr*math.sin(t)))
    for a in range(around):
        an=(a+1)%around
        for b in range(roundness):
            bn=(b+1)%roundness
            i=a*roundness+b; j=an*roundness+b
            k=a*roundness+bn; l=an*roundness+bn
            ff.extend(((i,j,k),(j,l,k)))
    mesh=trimesh.Trimesh(vertices=vv,faces=ff,process=False)
    mesh.visual.material=material
    return mesh


def head_landmarks(source:trimesh.Scene):
    """Derive actual human ear positions from the immutable CC0 base sculpt.

    This fixes a major previous bug: the left ear is at x≈-.107 while the
    right is x≈+.055. A headphone rig symmetrical about x=0 cannot fit them.
    """
    skin=source.geometry['base'].vertices
    ear_band=skin[(skin[:,1]>1.62)&(skin[:,1]<1.68)&
                  (skin[:,2]>.0)&(skin[:,2]<.075)]
    assert len(ear_band)>200
    left=float(np.quantile(ear_band[:,0],.012))
    right=float(np.quantile(ear_band[:,0],.988))
    assert -.115<left<-.095 and .04<right<.067,(left,right)
    hair=source.geometry['short01'].vertices
    scalp_roof=float(np.quantile(hair[:,1],.995))
    assert 1.77<scalp_roof<1.805
    return left,right,scalp_roof


def hardware(fit:tuple[float,float,float]):
    brushed=PBRMaterial(name='Blackline_HeadphoneBrushedAluminum',
        baseColorFactor=np.array([90,94,93,255],dtype=np.uint8),
        metallicFactor=.78,roughnessFactor=.48)
    dark=PBRMaterial(name='Blackline_AgedHardRubber',
        baseColorFactor=np.array([34,37,38,255],dtype=np.uint8),
        metallicFactor=.06,roughnessFactor=.89)
    leather=PBRMaterial(name='Blackline_EarLeather',
        baseColorFactor=np.array([52,48,44,255],dtype=np.uint8),
        metallicFactor=0,roughnessFactor=.85)
    metal=PBRMaterial(name='Blackline_RecordHousingPaint',
        baseColorFactor=np.array([72,75,71,255],dtype=np.uint8),
        metallicFactor=.31,roughnessFactor=.57)
    items=[]
    def add(mesh,name):
        mesh.metadata['name']=name
        items.append((name,mesh))

    ear_left,ear_right,roof=fit
    ear_y=1.650;ear_z=.047
    # Inward annular leather pads rest against the *actual ears*; the hard
    # shells sit outboard, leaving the face/temples clear. Each side is fitted
    # to a different anatomical x-coordinate, NOT a guessed mirrored origin.
    for side,ear_x in ((-1,ear_left),(1,ear_right)):
        pad_x=ear_x+side*.0035
        shell_x=ear_x+side*.013
        outer_x=shell_x+side*.019
        add(cushion_ring((pad_x,ear_y,ear_z),.0295,.0098,leather),
            'HeadphoneSeal'+str(side))
        add(earcup((shell_x,ear_y,ear_z),side,.039,.030,dark),
            'HeadphoneHousing'+str(side))
        add(earcup((outer_x,ear_y,ear_z),side,.034,.010,brushed),
            'HeadphoneRing'+str(side))
        # Actual closed-back studio headset: cover the center of the outer
        # lathed cup. The former open tube revealed the ear through a hole.
        cap=trimesh.creation.cylinder(radius=.022,height=.008,sections=40)
        cap.apply_transform(trimesh.transformations.rotation_matrix(
            math.pi/2,[0,1,0]))
        cap.apply_translation((outer_x+side*.043,ear_y,ear_z))
        cap.visual.material=dark
        add(cap,'HeadphoneDriverBack'+str(side))
        boss=trimesh.creation.cylinder(radius=.008,height=.008,sections=28)
        boss.apply_transform(trimesh.transformations.rotation_matrix(
            math.pi/2,[0,1,0]))
        boss.apply_translation((outer_x+side*.048,ear_y,ear_z))
        boss.visual.material=brushed
        add(boss,'HeadphoneCalibrationBadge'+str(side))
        # The yoke starts INSIDE the rim, reaches the same crown arc end.
        fork=[(outer_x+side*.010,ear_y+.029,ear_z),
              (outer_x+side*.012,ear_y+.047,ear_z),
              (ear_x+side*.012,1.746,ear_z-.006),
              (ear_x+side*.006,roof-.003,ear_z-.009)]
        add(rod(fork,.0038,brushed),'HeadphoneFork'+str(side))
        add(rod([fork[0],(outer_x+side*.003,ear_y+.033,ear_z)],.0032,brushed),
            'HeadphonePivot'+str(side))
    # Curved steel spring + padded band follow the actual asymmetrical scalp.
    # Its underside contacts hair within a few millimeters, not hovering.
    crown_top=roof+.007
    arch=[(ear_left+(ear_right-ear_left)*i/36,
           (roof-.003)+(crown_top-(roof-.003))*math.sin(math.pi*i/36),
           ear_z-.009) for i in range(37)]
    add(rod(arch,.0085,leather),'HeadbandPadding')
    add(rod([(x,y+.0082,z) for x,y,z in arch],.0028,brushed),
        'HeadbandSpring')

    # Boom is physically anchored on the LEFT cup and stops beside the lip.
    left_outer=ear_left-.013-.019
    boom=[(left_outer-.01,ear_y-.008,ear_z),
          (left_outer-.023,1.611,.079),
          (left_outer-.020,1.579,.119),
          (-.107,1.567,.141),(-.072,1.562,.154)]
    add(rod(boom,.0032,brushed),'MicBoom')
    tip=trimesh.creation.icosphere(subdivisions=2,radius=.0085)
    tip.apply_translation(boom[-1]);tip.visual.material=dark
    add(tip,'MicCapsule')

    # A two-part, physically anchored cable: the short flexible section
    # follows the head in the skinned rig; the jacket portion follows Spine.
    # A grounded transition clip is attached to the upper lapel.
    right_outer=ear_right+.013+.019
    head_lead=[(right_outer+.008,ear_y-.027,ear_z),
               (right_outer+.018,1.585,.058),
               (.125,1.531,.077)]
    add(rod(head_lead,.0036,dark),'HeadphoneHeadLead')
    lapel_lead=[(.125,1.531,.077),(.158,1.456,.089),
                (.171,1.385,.123),(.157,1.285,.163),
                (.139,1.187,.187),(.139,1.075,.192),
                (.136,.999,.192)]
    add(rod(lapel_lead,.0036,dark),'StudioHeadsetCable')
    clip=trimesh.creation.box(extents=(.016,.028,.008))
    clip.apply_translation((.158,1.386,.127));clip.visual.material=metal
    add(clip,'CableLapelClip')

    # Existing small waist field recorder, backed into jacket construction.
    case=trimesh.creation.box(extents=(.138,.113,.036))
    case.apply_translation((.136,.974,.192));case.visual.material=metal
    add(case,'PortableAnalogMonitorBody')
    rim=trimesh.creation.box(extents=(.125,.061,.004))
    rim.apply_translation((.136,.991,.215));rim.visual.material=brushed
    add(rim,'PortableMonitorVURim')
    plate=label_plate('M-08','MONITOR  /  BLACKLINE',(.110,.044),(.136,.990,.220))
    add(plate,'OriginalFieldMonitorVUMarkings')
    for i in range(3):
        knob=trimesh.creation.cylinder(radius=.007,height=.008,sections=24)
        knob.apply_transform(trimesh.transformations.rotation_matrix(math.pi/2,[1,0,0]))
        knob.apply_translation((.09+i*.038,.942,.220))
        knob.visual.material=brushed
        add(knob,'MonitorPot'+str(i))
    add(label_plate('BLACKLINE','MASTERING  /  TECHNICIAN',
        (.081,.038),(-.092,1.314,.189)),'EmployeeBadge')
    return items


def build(source:Path):
    original=trimesh.load(str(source),force='scene',process=False)
    scene=trimesh.Scene()
    count0=count1=0
    headset_fit=head_landmarks(original)
    for name,m in original.geometry.items():
        if name in ('teeth_base','base_2'):continue
        components=[(name,m.copy())]
        if name=='base':
            center=m.vertices[m.faces].mean(axis=1)
            head=center[:,1]>=1.35
            arm=(center[:,1]>=.78)&(center[:,1]<1.35)&(np.abs(center[:,0])>.20)
            masks=[('Face',head&(center[:,2]>=.12)),
                   ('Scalp',head&(center[:,2]<.12)),
                   ('LeftHand',arm&(center[:,0]<0)),
                   ('RightHand',arm&(center[:,0]>=0))]
            components=[]
            for suffix,mask in masks:
                a=m.copy();a.update_faces(mask);a.remove_unreferenced_vertices()
                if len(a.faces):components.append((name+suffix,a))
        elif name=='male_casualsuit05':
            center=m.vertices[m.faces].mean(axis=1)
            components=[]
            for suffix,mask in [('Jacket',center[:,1]>=.96),('Trousers',center[:,1]<.96)]:
                a=m.copy();a.update_faces(mask);a.remove_unreferenced_vertices()
                components.append((name+suffix,a))
        for component,a in components:
            count0+=len(a.faces)
            if component.endswith('Hand'):
                a=reduce_uv(a,.55)
            count1+=len(a.faces)
            xyz=a.vertices.copy()
            xyz[:,0]*=-SCALE
            xyz[:,1]=xyz[:,1]*SCALE+OFFSET
            xyz[:,2]*=-SCALE
            a.vertices=xyz
            a.visual.material=pbr_from_old(m.visual.material,name)
            scene.add_geometry(a,node_name='Anatomical_'+component,
                               geom_name='Anatomical_'+component)
    for name,mesh in hardware(headset_fit):
        xyz=mesh.vertices.copy();xyz[:,0]*=-SCALE;xyz[:,1]=xyz[:,1]*SCALE+OFFSET;xyz[:,2]*=-SCALE
        mesh.vertices=xyz
        scene.add_geometry(mesh,node_name='StudioKit_'+name,geom_name='StudioKit_'+name)
    bounds=scene.bounds
    dims=bounds[1]-bounds[0]
    print('Q02 realistic source:',count0,'tri source,',count1,'reduced anatomical tri;',
          'whole',sum(len(x.faces) for x in scene.geometry.values()),'tri /',
          len(scene.geometry),'geometry; bounds',np.round(bounds,3),'extents',np.round(dims,3))
    assert 40_000<sum(len(x.faces) for x in scene.geometry.values())<95_000
    assert 5.8<dims[1]<7.0 and dims[0]<3.4 and dims[2]<2.7
    return scene

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=Path('build/cc0/daniel_cc0.glb'))
    p.add_argument('--out',type=Path,default=Path('build/roblox-glb/EngineerBody.glb'))
    a=p.parse_args();a.out.parent.mkdir(parents=True,exist_ok=True)
    scene=build(a.source);a.out.write_bytes(scene.export(file_type='glb'))
    print('OUTPUT',a.out,a.out.stat().st_size)
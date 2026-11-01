#!/usr/bin/env python3
"""Q02 headset fit/rig contract: exact CC0 ear anatomy and rigid Head binding.

A positive geometry + skin regression test, NOT a claim that Roblox Studio
has imported or rendered the model successfully.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
import trimesh
from build_skinned_engineer import WEIGHTED_BONES, unpack
from validate_skinned_engineer import get_buffer

SCALE=3.62
OFFSET=-4.


def validate(source:Path,body:Path,skinned:Path)->dict:
    reference=trimesh.load(source,force="scene",process=False)
    base=np.asarray(reference.geometry["base"].vertices)
    band=base[(base[:,1]>1.62)&(base[:,1]<1.68)&
              (base[:,2]>.0)&(base[:,2]<.075)]
    assert len(band)>200
    ear_landmarks={-1:float(np.quantile(band[:,0],.012)),
                   1:float(np.quantile(band[:,0],.988))}
    assert -.115<ear_landmarks[-1]<-.095
    assert .04<ear_landmarks[1]<.067
    scalp=float(np.quantile(
        np.asarray(reference.geometry["short01"].vertices)[:,1],.995))
    model=trimesh.load(body,force="scene",process=False)
    expected={"StudioKit_HeadphoneSeal-1","StudioKit_HeadphoneSeal1",
              "StudioKit_HeadphoneDriverBack-1",
              "StudioKit_HeadphoneDriverBack1",
              "StudioKit_HeadbandPadding","StudioKit_HeadbandSpring",
              "StudioKit_MicBoom","StudioKit_MicCapsule",
              "StudioKit_HeadphoneHeadLead",
              "StudioKit_StudioHeadsetCable"}
    assert expected.issubset(model.geometry.keys()),(
        "Missing closed earcups and physically joined headband",expected-set(model.geometry))
    measurements={}
    for side,ear_x in ear_landmarks.items():
        mesh=model.geometry["StudioKit_HeadphoneSeal"+str(side)]
        center=np.mean(mesh.vertices,axis=0)
        target_x=-(ear_x+side*.0035)*SCALE
        err=abs(float(center[0])-target_x)
        assert err<.025,("Pad is floating or not fitted to real ear",side,err)
        target_y=1.650*SCALE+OFFSET
        assert abs(center[1]-target_y)<.02
        target_z=-.047*SCALE
        assert abs(center[2]-target_z)<.02
        shell=model.geometry["StudioKit_HeadphoneHousing"+str(side)]
        assert abs(float(np.mean(shell.vertices[:,1]))-target_y)<.03
        measurements[str(side)]={"earXStud":round(-ear_x*SCALE,4),
                                 "padXStud":round(float(center[0]),4),
                                 "padFitErrorStud":round(err,5)}
    band_mesh=model.geometry["StudioKit_HeadbandPadding"]
    y_top=float(np.max(band_mesh.vertices[:,1]))
    roof=scalp*SCALE+OFFSET
    assert 0<y_top-roof<.085,(
        "Headband must rest on scalp, not float above hair",y_top,roof)
    # Visual headset is closed-back, the old open tubing exposed both ears.
    for side in (-1,1):
        m=model.geometry["StudioKit_HeadphoneDriverBack"+str(side)]
        assert len(m.faces)>=60
    assert skinned.is_file()
    gltf,buf=unpack(skinned.read_bytes())
    head_index=WEIGHTED_BONES.index("Head")
    fixed=0
    for node in gltf["nodes"]:
        name=node.get("name","")
        if "mesh" not in node:
            continue
        if not name.startswith(("StudioKit_Headphone","StudioKit_Headband",
                                "StudioKit_Mic")):
            continue
        if name.startswith("StudioKit_HeadphoneHeadLead"):
            continue # flexible cable has intentional Neck transition
        for primitive in gltf["meshes"][node["mesh"]]["primitives"]:
            attrib=primitive["attributes"]
            joints=get_buffer(gltf,buf,attrib["JOINTS_0"])
            weights=get_buffer(gltf,buf,attrib["WEIGHTS_0"])
            assert np.all(joints[:,0]==head_index),(name,"not Head-bound")
            assert np.allclose(weights[:,0],1,atol=1e-5),(name,"headset splits at neck")
            assert np.max(weights[:,1:])<1e-5,(name,"non-head influence")
            fixed+=1
    assert fixed>=17,("Too few rigidly head-bound components",fixed)
    print("PASS Q02 fitted headset: anatomical ears matched, closed-back "+
          "drivers, scalp contact, %d rigid Head-skinned sections"%fixed)
    return {"earFit":measurements,"headBandClearanceStud":
            round(y_top-roof,5),"rigidHeadSections":fixed,
            "studioImportAndAnimation":"PENDING"}


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--source",type=Path,
                   default=Path("build/cc0/daniel_cc0.glb"))
    p.add_argument("--body",type=Path,
                   default=Path("build/roblox-glb/EngineerBody.glb"))
    p.add_argument("--skinned",type=Path,
                   default=Path("build/roblox-glb/EngineerSkinned.glb"))
    a=p.parse_args()
    validate(a.source,a.body,a.skinned)

if __name__=="__main__":
    main()

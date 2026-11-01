#!/usr/bin/env python3
"""Check a genuine glTF skin: every vertex, every bone and every bind transform.

This is source validation, not Roblox 3D Importer acceptance or final rig quality.
"""
from __future__ import annotations
import argparse
import json
import math
import struct
from pathlib import Path
import numpy as np
from build_skinned_engineer import BONES, WEIGHTED_BONES, WORLD, unpack

def get_buffer(gltf:dict,buf:bytes,index:int):
    a=gltf["accessors"][index]
    view=gltf["bufferViews"][a["bufferView"]]
    types={"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}
    dtypes={5126:"<f4",5123:"<u2"}
    dtype=np.dtype(dtypes[a["componentType"]])
    width=types[a["type"]]
    offset=view.get("byteOffset",0)+a.get("byteOffset",0)
    stride=view.get("byteStride",width*dtype.itemsize)
    data=np.empty((a["count"],width),dtype=dtype)
    for i in range(a["count"]):
        data[i]=np.frombuffer(buf,dtype=dtype,count=width,offset=offset+i*stride)
    return data

def validate(path:Path)->dict:
    gltf,buf=unpack(path.read_bytes())
    assert gltf.get("skins") and len(gltf["skins"])==1
    skin=gltf["skins"][0]
    assert len(skin["joints"])==len(WEIGHTED_BONES)==15
    nodes=gltf["nodes"]
    named={n["name"]:i for i,n in enumerate(nodes) if "name" in n}
    for name,parent,xyz in BONES:
        assert name in named,("missing skeleton Bone",name)
        if parent:
            assert named[name] in nodes[named[parent]].get("children",[]),(
                "broken skeleton hierarchy",name,parent)
    assert "EngineerRoot" not in {nodes[j]["name"] for j in skin["joints"]}
    assert nodes[skin["skeleton"]]["name"]=="EngineerRoot"
    assert [nodes[i]["name"] for i in skin["joints"]]==WEIGHTED_BONES
    bind=get_buffer(gltf,buf,skin["inverseBindMatrices"])
    assert bind.shape==(15,16)
    for row,name in zip(bind,WEIGHTED_BONES):
        ibm=np.reshape(row,(4,4),order="F")
        expected=np.eye(4,dtype=float)
        expected[:3,3]=-WORLD[name]
        assert np.allclose(ibm,expected,atol=1e-5),(name,"inverse bind mismatch")
    all_used=set()
    vertex_count=0
    mesh_count=0
    max_weight_error=0.0
    bent_influence_count=0
    for node in nodes:
        if "mesh" not in node:
            continue
        mesh_count+=1
        assert node.get("skin")==0,("unskinned mesh node",node.get("name"))
        for primitive in gltf["meshes"][node["mesh"]]["primitives"]:
            attrs=primitive["attributes"]
            assert "JOINTS_0" in attrs and "WEIGHTS_0" in attrs
            j=get_buffer(gltf,buf,attrs["JOINTS_0"])
            w=get_buffer(gltf,buf,attrs["WEIGHTS_0"])
            p=get_buffer(gltf,buf,attrs["POSITION"])
            assert j.shape==w.shape==(len(p),4)
            assert w.dtype==np.float32 and j.dtype==np.uint16
            assert np.all(np.isfinite(w)) and np.min(w)>=0
            assert j.max()<len(WEIGHTED_BONES)
            error=np.abs(w.sum(axis=1)-1)
            max_weight_error=max(max_weight_error,float(error.max()))
            assert float(error.max())<1e-5,("skin vertex weight not normalized",float(error.max()))
            all_used.update(int(v) for v in j[w>1e-4])
            bent_influence_count+=int(np.count_nonzero((w>1e-3).sum(axis=1)>1))
            vertex_count+=len(p)
    assert mesh_count>=6 and vertex_count>=2000
    assert len(all_used)>=12,("insufficient articulated joints actually deform geometry",all_used)
    assert bent_influence_count>=100,(
        "skin does not have enough multi-bone vertices to allow smooth bends")
    assert path.stat().st_size<18_000_000
    result={"file":path.name,"status":"GLTF_WEIGHTED_SKIN_VALIDATED_STUDIO_IMPORT_PENDING",
            "skinnedMeshNodes":mesh_count,"vertices":vertex_count,
            "jointCount":len(WEIGHTED_BONES),"influencedJoints":len(all_used),
            "multiboneVertices":bent_influence_count,"maxWeightNormalizationError":max_weight_error}
    print("PASS SKINNED ENGINEER "+json.dumps(result,sort_keys=True))
    return result

def main():
    p=argparse.ArgumentParser()
    p.add_argument("asset",type=Path)
    p.add_argument("--report",type=Path)
    args=p.parse_args()
    result=validate(args.asset)
    if args.report:
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(result,indent=2)+"\n")

if __name__=="__main__":
    main()

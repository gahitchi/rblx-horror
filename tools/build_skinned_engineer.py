#!/usr/bin/env python3
"""Produce a *genuinely skinned* glTF 2.0 Engineer from original source meshes.

A skeleton without JOINTS_0 / WEIGHTS_0 does not deform. This builder inserts
both per-vertex attributes, a valid glTF skin, inverse bind matrices and an
ordered skeleton into the texture-mapped EngineerBody scene. Uses no commercial
character/animation IP. It does NOT claim artist-quality retopology or weights.

Run: python3 tools/build_skinned_engineer.py --out build/roblox-glb/EngineerSkinned.glb
"""
from __future__ import annotations
import argparse
import json
import math
import struct
from pathlib import Path
import numpy as np
from build_character_assets import engineer_body

# Roblox requires root at (0,0,0), no weights on that root, <=4 influences.
# Coordinates are in source-engine studs; forward is -Z.
BONES = [
    ("EngineerRoot", None, (0.0, 0.0, 0.0)),  # nondeforming hierarchy root
    ("Spine", "EngineerRoot", (0.0, 0.32, 0.0)),
    ("Neck", "Spine", (0.0, 1.45, -0.06)),
    ("Head", "Neck", (0.0, 1.99, -0.18)),
    ("LeftShoulder", "Spine", (-0.79, 1.33, -0.04)),
    ("LeftElbow", "LeftShoulder", (-0.84, 0.25, -0.06)),
    ("LeftWrist", "LeftElbow", (-0.84, -0.65, -0.06)),
    ("RightShoulder", "Spine", (0.79, 1.33, -0.04)),
    ("RightElbow", "RightShoulder", (0.84, 0.25, -0.06)),
    ("RightWrist", "RightElbow", (0.84, -0.65, -0.06)),
    ("LeftHip", "Spine", (-0.33, -0.54, 0.01)),
    ("LeftKnee", "LeftHip", (-0.34, -2.13, 0.03)),
    ("LeftAnkle", "LeftKnee", (-0.36, -3.58, -0.03)),
    ("RightHip", "Spine", (0.33, -0.54, 0.01)),
    ("RightKnee", "RightHip", (0.34, -2.13, 0.03)),
    ("RightAnkle", "RightKnee", (0.36, -3.58, -0.03)),
]
WEIGHTED_BONES = [b[0] for b in BONES if b[0] != "EngineerRoot"]
INDEX = {name: i for i, name in enumerate(WEIGHTED_BONES)}
PARENT = {name: parent for name, parent, _ in BONES}
WORLD = {name: np.asarray(xyz, dtype=np.float64) for name, _, xyz in BONES}

def smooth(x: float, a: float, b: float) -> float:
    t = max(0.0, min(1.0, (x-a)/(b-a)))
    return t*t*(3.0-2.0*t)

def weights_for(point: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    x, y, _z = [float(q) for q in point]
    side = "Left" if x < 0 else "Right"
    ax = abs(x)
    influence: dict[str, float] = {}
    def assign(name: str, value: float):
        if value > 1e-7:
            influence[name] = influence.get(name, 0.0) + value

    # Only distal portions of limbs use distal bones; blend through a local
    # bend region to prevent hard joint cracks in the skin.
    arm = smooth(ax, 0.47, 0.78) * (1-smooth(y, 1.26, 1.80)) * smooth(y, -2.05, -1.27)
    leg = (1-arm)*smooth(-y, 0.78, 1.45)*smooth(ax, 0.10, 0.26)
    head = (1-arm-leg)*smooth(y, 1.32, 1.86)
    body = max(0.0, 1-arm-leg-head)
    assign("Spine", body)

    # Head/neck blend has 2 joints plus a little shoulder-following torso.
    neck_t = smooth(y, 1.56, 2.02)
    assign("Neck", head*(1-neck_t))
    assign("Head", head*neck_t)

    if arm:
        elbow = 1-smooth(y, -0.25, 0.58)
        wrist = 1-smooth(y, -0.79, -0.18)
        assign(side+"Shoulder", arm*(1-elbow))
        assign(side+"Elbow", arm*elbow*(1-wrist))
        assign(side+"Wrist", arm*elbow*wrist)
    if leg:
        knee = 1-smooth(y, -2.33, -1.62)
        ankle = 1-smooth(y, -3.66, -2.96)
        assign(side+"Hip", leg*(1-knee))
        assign(side+"Knee", leg*knee*(1-ankle))
        assign(side+"Ankle", leg*knee*ankle)

    ordered = sorted(influence.items(), key=lambda q: -q[1])[:4]
    total = sum(w for _, w in ordered)
    assert total > 0.0
    ids = [INDEX[n] for n, _ in ordered]
    values = [float(w/total) for _, w in ordered]
    while len(ids)<4:
        ids.append(0)
        values.append(0.0)
    return np.array(ids, dtype=np.uint16), np.array(values,dtype=np.float32)

def unpack(blob: bytes) -> tuple[dict, bytearray]:
    assert blob[:4] == b"glTF" and struct.unpack_from("<I",blob,4)[0]==2
    offset=12
    chunks={}
    while offset<len(blob):
        count,kind=struct.unpack_from("<I4s",blob,offset)
        offset+=8
        chunks[kind]=blob[offset:offset+count]
        offset+=count
    return json.loads(chunks[b"JSON"].decode("utf8")),bytearray(chunks[b"BIN\x00"])

def pack(gltf: dict, data: bytearray) -> bytes:
    js=json.dumps(gltf,separators=(",",":"),ensure_ascii=False).encode("utf8")
    js+=b" " * ((-len(js))%4)
    data+=b"\x00"*((-len(data))%4)
    length=12+8+len(js)+8+len(data)
    return (struct.pack("<4sII",b"glTF",2,length)
            +struct.pack("<I4s",len(js),b"JSON")+js
            +struct.pack("<I4s",len(data),b"BIN\x00")+data)

def add_accessor(gltf:dict,bin_data:bytearray,raw:bytes,
                 component:int,kind:str,count:int,target:int|None=None):
    bin_data.extend(b"\x00"*((-len(bin_data))%4))
    start=len(bin_data)
    bin_data.extend(raw)
    view={"buffer":0,"byteOffset":start,"byteLength":len(raw)}
    if target is not None:
        view["target"]=target
    view_index=len(gltf["bufferViews"])
    gltf["bufferViews"].append(view)
    accessor={"bufferView":view_index,"byteOffset":0,
              "componentType":component,"count":count,"type":kind}
    number=len(gltf["accessors"])
    gltf["accessors"].append(accessor)
    return number

def positions(gltf:dict,binary:bytearray,accessor_number:int) -> np.ndarray:
    a=gltf["accessors"][accessor_number]
    view=gltf["bufferViews"][a["bufferView"]]
    assert a["componentType"]==5126 and a["type"]=="VEC3"
    stride=view.get("byteStride",12)
    offset=view.get("byteOffset",0)+a.get("byteOffset",0)
    # glTF preserves the mesh's texture coordinates and normal tangents.
    result=np.empty((a["count"],3),dtype=np.float32)
    for i in range(a["count"]):
        result[i]=np.frombuffer(binary,dtype="<f4",count=3,offset=offset+i*stride)
    return result

def create(output:Path)->dict:
    source=engineer_body().export(file_type="glb")
    gltf,binary=unpack(source)
    nodes=gltf["nodes"]
    skin_root=len(nodes)
    index_of={}
    for name,parent,position in BONES:
        idx=len(nodes)
        index_of[name]=idx
        if parent is None:
            local=position
        else:
            local=WORLD[name]-WORLD[parent]
        nodes.append({"name":name,"translation":[float(q) for q in local]})
    for name,parent,_ in BONES:
        if parent is not None:
            nodes[index_of[parent]].setdefault("children",[]).append(index_of[name])
    # Keep skinned meshes at their original positions under the scene's world
    # root. Bone matrices are world-space inverse bind matrices.
    gltf["nodes"][0].setdefault("children",[]).append(skin_root)
    ibm=[]
    for name in WEIGHTED_BONES:
        tx,ty,tz=WORLD[name]
        matrix=np.eye(4,dtype=np.float32)
        matrix[:3,3]=(-tx,-ty,-tz)
        ibm.append(matrix.T.reshape(-1)) # glTF is column-major
    raw_ibm=np.asarray(ibm,dtype="<f4").tobytes()
    matrices=add_accessor(gltf,binary,raw_ibm,5126,"MAT4",len(WEIGHTED_BONES))
    gltf["skins"]=[{
        "name":"EngineerSkinV1","inverseBindMatrices":matrices,
        "skeleton":skin_root,
        "joints":[index_of[name] for name in WEIGHTED_BONES],
    }]

    n_vertices=0
    influenced=set()
    for mesh_node in nodes[:skin_root]:
        if "mesh" not in mesh_node:
            continue
        mesh_node["skin"]=0
        mesh=gltf["meshes"][mesh_node["mesh"]]
        for primitive in mesh["primitives"]:
            attrs=primitive["attributes"]
            xyz=positions(gltf,binary,attrs["POSITION"])
            js=np.zeros((len(xyz),4),dtype="<u2")
            ws=np.zeros((len(xyz),4),dtype="<f4")
            for i,point in enumerate(xyz):
                ids,vals=weights_for(point)
                js[i]=ids
                ws[i]=vals
                influenced.update(int(v) for v,w in zip(ids,vals) if w>0.001)
            assert np.allclose(ws.sum(axis=1),1,atol=1e-5)
            attrs["JOINTS_0"]=add_accessor(
                gltf,binary,js.tobytes(),5123,"VEC4",len(xyz),34962)
            attrs["WEIGHTS_0"]=add_accessor(
                gltf,binary,ws.tobytes(),5126,"VEC4",len(xyz),34962)
            n_vertices+=len(xyz)
    assert n_vertices>=2000 and len(influenced)>=12,(
        "insufficient skinned vertices or unweighted skeleton",n_vertices,influenced)
    gltf["buffers"][0]["byteLength"]=len(binary)
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_bytes(pack(gltf,binary))
    return {"file":str(output),"meshVertices":n_vertices,
            "joints":len(WEIGHTED_BONES),"influencedBones":len(influenced),
            "skinnedMeshNodes":sum("skin" in n for n in gltf["nodes"]),
            "status":"SKINNED_SOURCE_VALIDATED_STUDIO_IMPORT_UNTESTED"}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--out",type=Path,default=Path("build/roblox-glb/EngineerSkinned.glb"))
    args=ap.parse_args()
    result=create(args.out)
    print("SKINNED ENGINEER",json.dumps(result,sort_keys=True))

if __name__=="__main__":
    main()

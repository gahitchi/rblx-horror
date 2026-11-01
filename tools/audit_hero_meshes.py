#!/usr/bin/env python3
"""Integrity audit and honest fidelity inventory for Roblox GLB source pack.

Does not certify "photorealistic" art: records measurable geometry and whether
authored image texture maps exist. Produces a JSON manifest in the export pack.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import numpy as np
import trimesh

EXPECTED={
    "MixingConsole","BroadcastMicrophone","FoundryBell",
    "CassetteRecorder","EngineerHeadset","WalkieTalkie",
    "AnalogRack","NearfieldMonitor","TapeReel",
    "ReceptionTerminal","TapeArchiveCart","ServiceIntercom",
    "StudioWallClock",
    "EngineerBody","FieldOperatorVest","FieldOperatorMask","FieldOperatorPack",
}


def check(path: Path):
    scene=trimesh.load(path,force="scene",process=False)
    bounds=np.asarray(scene.bounds,dtype=float)
    assert bounds.shape==(2,3) and np.all(np.isfinite(bounds)),path.name
    dims=bounds[1]-bounds[0]
    assert np.all(dims>0) and np.max(dims)<100,(path.name,dims)
    vertices=0; triangles=0; materials=set(); images=0
    for mesh in scene.geometry.values():
        assert isinstance(mesh,trimesh.Trimesh)
        assert np.isfinite(mesh.vertices).all(),(path.name,"non-finite geometry")
        assert len(mesh.faces)>0 and len(mesh.vertices)>0,path.name
        assert np.all(mesh.faces>=0) and np.all(mesh.faces<len(mesh.vertices)),path.name
        triangles+=len(mesh.faces)
        vertices+=len(mesh.vertices)
        visual=mesh.visual
        mat=getattr(visual,"material",None)
        if mat is not None:
            materials.add(getattr(mat,"name",None) or type(mat).__name__)
            for field in ("baseColorTexture","normalTexture",
                          "metallicRoughnessTexture","emissiveTexture"):
                if getattr(mat,field,None) is not None:
                    images+=1
    assert vertices>=100 and triangles>=80,(path.name,"empty/underbuilt")
    return {
        "file":path.name,
        "sourceTier":"procedural-prototype",
        "vertices":vertices,
        "triangles":triangles,
        "materialMeshes":len(scene.geometry),
        "materialFamilies":sorted(materials),
        "imagesAttached":images,
        "dimensionsStuds":[round(float(x),3) for x in dims],
        "artistUvAndBakedTexturePassRequired":images==0,
    }


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--directory",type=Path,default=Path("build/roblox-glb"))
    parser.add_argument("--report",type=Path,default=Path("build/art-quality-report.json"))
    args=parser.parse_args()
    found={p.stem for p in args.directory.glob("*.glb")}
    assert found==EXPECTED,("unexpected asset pack",sorted(EXPECTED-found),sorted(found-EXPECTED))
    assets=[check(args.directory/(name+".glb")) for name in sorted(EXPECTED)]
    data={
        "benchmark":"TTK Testing-level visual fidelity: aspirational; no parity claim",
        "count":len(assets),
        "sourceStatus":"VALIDATED_GEOMETRY_PROTOTYPES_NOT_FINAL_ART",
        "notes":[
            "Roblox upload and creator permissions not tested by this script",
            "Image textures / baked normal maps and LODs require authored upgrades",
            "Real in-game lighting, collision, streaming and FPS need Studio review",
        ],
        "assets":assets,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(data,indent=2)+"\n")
    print(f"PASS source mesh audit: {len(assets)} GLBs, "
          f"{sum(a['triangles'] for a in assets)} triangles, "
          f"{sum(a['imagesAttached'] for a in assets)} embedded maps")
    print("ART STATUS: PROTOTYPES — artist-authored UV / baked materials and real Studio visual QA pending")


if __name__=="__main__":
    main()

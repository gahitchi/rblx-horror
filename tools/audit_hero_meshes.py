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
    "BlacklineTransferDeck","BlacklinePatchMatrix",
    "BlacklineHeroConsole","BlacklineArchiveCabinet","BlacklineMasterReference",
    "EngineerRigTorso","EngineerRigHead","EngineerRigArmLeft","EngineerRigArmRight","EngineerRigLegLeft","EngineerRigLegRight",
    "EngineerSkinned",
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
    if path.stem in {
        "EngineerBody","FieldOperatorVest","FieldOperatorMask","FieldOperatorPack",
        "BlacklineTransferDeck","BlacklinePatchMatrix",
        "BlacklineHeroConsole","BlacklineArchiveCabinet","BlacklineMasterReference",
        "EngineerRigTorso","EngineerRigHead","EngineerRigArmLeft","EngineerRigArmRight","EngineerRigLegLeft","EngineerRigLegRight",
        "EngineerSkinned",
    }:
        assert images>=9,(path.name,"missing embedded color, normal or packed ORM images")
        assert vertices>=500,(path.name,"artist prototype too simplified")
    if path.stem=="BlacklineHeroConsole":
        # Q01 is a deliberately concentrated art asset, not a count of props.
        # It must retain both actual UV printed material surfaces and curved
        # construction geometry; still NOT a Studio visual-quality signoff.
        assert {"Blackline12ChannelScreenprint",
                "Blackline12ChannelMeterBridge"}.issubset(materials),(
                    "Q01 original printed control/meter atlases are missing",materials)
        assert 9000<=triangles<=65000,(
            "Q01 needs modeled construction, but a bounded triangle budget",triangles)
        assert 5.8<dims[0]<6.8 and 3.8<dims[1]<4.6 and 2.9<dims[2]<4.2,(
            "Q01 pivot-size drift relative to the existing Control A collider",dims)
        for mesh in scene.geometry.values():
            uv=getattr(mesh.visual,"uv",None)
            assert uv is not None and len(uv)==len(mesh.vertices) and (
                np.isfinite(uv).all()),("Q01 unwrapped mesh required",mesh)
    if path.stem in {"EngineerBody","EngineerSkinned"}:
        assert "BlacklineEngineerOriginalIDPlate" in materials,(
            "Q02 needs printed, real UV-mapped studio identification",path.name)
        assert 16000<=triangles<=60000,(
            "Q02 technician geometry detail or budget regression",triangles)
        assert 2.5<dims[0]<3.8 and 7.5<dims[1]<8.8 and 1.2<dims[2]<2.4,(
            "Q02 must remain approximately human-proportioned",path.name,dims)
        for mesh in scene.geometry.values():
            uv=getattr(mesh.visual,"uv",None)
            assert uv is not None and len(uv)==len(mesh.vertices) and np.isfinite(uv).all(),(
                "Q02 requires physically UV-mapped meshes",mesh)
    assert path.stat().st_size<18_000_000,(path.name,"mesh exceeds conservative import budget")

    return {
        "file":path.name,
        "sourceTier":("machined-UV-console-source-prototype"
                      if path.stem=="BlacklineHeroConsole"
                      else "grounded-character-Q02-source-candidate"
                      if path.stem in {"EngineerBody","EngineerSkinned"}
                      else "procedural-prototype"),
        "vertices":vertices,
        "triangles":triangles,
        "materialMeshes":len(scene.geometry),
        "materialFamilies":sorted(materials),
        "imagesAttached":images,
        "dimensionsStuds":[round(float(x),3) for x in dims],
        # Raw source-space bounds help diagnose Studio 3D Importer pivot
        # recentering, especially shoulder/hip-aligned articulated segments.
        "boundsMinStuds":[round(float(x),3) for x in bounds[0]],
        "boundsMaxStuds":[round(float(x),3) for x in bounds[1]],
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
    from validate_production_baseline import check as check_production_baseline
    policy=check_production_baseline()
    quality_ledger=json.loads((Path(__file__).resolve().parent.parent /
        "docs/art/asset_quality_ledger.json").read_text())
    by_name={name:group for group in quality_ledger["groups"]
             for name in group["assetNames"]}
    for asset in assets:
        group=by_name[Path(asset["file"]).stem]
        asset["productionGroup"]=group["id"]
        asset["studioApproved"]=group["studioApproved"]
        asset["userAcceptedSourceDirection"]=group["ownerPreviewAccepted"]

    data={
        "benchmark":"TTK Testing-level visual fidelity: aspirational; no parity claim",
        "productionBaseline":policy,
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

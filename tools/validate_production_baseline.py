#!/usr/bin/env python3
"""Production-baseline ledger is an honest source inventory, NOT artistic signoff.

Both the Rojo source build and the real source-asset exporter run this.
Rebuild only the authored game objects; never silently promote prototypes.
"""
from __future__ import annotations

import ast
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
LEDGER=ROOT/"docs/art/asset_quality_ledger.json"
AUDIT=ROOT/"tools/audit_hero_meshes.py"


def exported_asset_names()->set[str]:
    tree=ast.parse(AUDIT.read_text())
    for node in tree.body:
        if isinstance(node,ast.Assign):
            if any(isinstance(t,ast.Name) and t.id=="EXPECTED" for t in node.targets):
                value=ast.literal_eval(node.value)
                assert isinstance(value,set)
                return value
    raise AssertionError("Source mesh audit has no EXPECTED inventory")


def check()->dict:
    ledger=json.loads(LEDGER.read_text())
    assert ledger["schema"]=="dead-air-art-quality-ledger-v1"
    assert ledger["referenceAsset"]=="BlacklineHeroConsole"
    assert ledger["finalAaaPolish"]=="deferred-until-baseline-game-built"
    assert "mission-loop-undecided" in ledger["gameSystemsHeldConstant"]
    groups=ledger["groups"]
    assert [g["id"] for g in groups]==["Q01","Q02","Q03","Q04","Q05","Q06"]
    assert [g["priority"] for g in groups]==list(range(len(groups)))
    valid_stages={"source-prototype","source-candidate",
                  "source-reference","studio-approved"}
    assert all(g["status"] in valid_stages for g in groups)
    assert groups[0]["status"] in {"source-reference","studio-approved"}
    assert groups[0]["assetNames"]==["BlacklineHeroConsole"]
    assert groups[0]["ownerPreviewAccepted"] is True
    all_assets={}
    for group in groups:
        assert isinstance(group["nextGate"],str) and len(group["nextGate"])>35
        # A later Studio signoff must carry actual saved evidence paths;
        # this source-only branch has none and cannot silently approve it.
        assert isinstance(group["studioApproved"],bool)
        if group["studioApproved"]:
            assert group["status"]=="studio-approved"
            evidence=group.get("studioEvidencePaths",[])
            assert len(evidence)>=3
            for relative in evidence:
                path=(ROOT/relative).resolve()
                assert path.is_relative_to(ROOT) and path.is_file(),(
                    "missing in-game review evidence",relative)
        else:
            assert group["status"]!="studio-approved"
        for name in group["assetNames"]:
            assert name not in all_assets,("same GLB in two quality groups",name)
            all_assets[name]=group["id"]
    assert set(all_assets)==exported_asset_names(),(
        "asset pack/quality ledger drift",
        sorted(exported_asset_names()-set(all_assets)),
        sorted(set(all_assets)-exported_asset_names()))
    assert len(all_assets)==29

    baseline=(ROOT/"docs/art/PRODUCTION_BASELINE_Q01.md").read_text()
    assert "Pass A" in baseline and "Pass B" in baseline
    assert "not" in baseline.lower() and "Studio" in baseline
    source=(ROOT/"tools/quality_console.py").read_text()
    assert "Blackline12ChannelScreenprint" in source
    assert "Blackline12ChannelMeterBridge" in source
    assert 'for ch in range(12):' in source
    audit=AUDIT.read_text()
    assert 'if path.stem=="BlacklineHeroConsole"' in audit
    approved=sum(len(g["assetNames"]) for g in groups if g["studioApproved"])
    candidates=sum(len(g["assetNames"]) for g in groups
                   if g["status"] in {"source-reference","source-candidate"})
    pending=next((g["id"] for g in groups if g["priority"]>0
                  and not g["studioApproved"]),None)
    return {"assetCount":len(all_assets),"reference":"BlacklineHeroConsole",
            "inGameApprovedCount":approved,"baselineSourceCandidateCount":candidates,
            "nextProductionGroup":pending,"productionGroups":len(groups)}


def main():
    result=check()
    print("PASS Q01 production baseline source/ledger:",json.dumps(result,sort_keys=True))
    print("STUDIO: none signed off; game-wide art will be built to Q01 preview direction")

if __name__=="__main__":
    main()

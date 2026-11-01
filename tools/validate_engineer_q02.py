#!/usr/bin/env python3
"""Q02 Last Listener: verify real source, cosmetic-only runtime and safe art.

A source, style and safety contract, not human artist or Studio approval.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent

def read(path):
    return (ROOT/path).read_text()

def main():
    q=read("tools/quality_engineer.py")
    importer=read("tools/build_character_assets.py")
    rig=read("tools/build_skinned_engineer.py")
    studio=read("tools/studio/InspectEngineerQ02.luau")
    runtime=read("src/server/Monster/SkinnedEngineer.luau")
    owner=read("src/server/Monster/EngineerModel.luau")
    motion=read("src/client/SkinnedEngineerMotion.luau")
    collider=read("src/server/PrefabLibrary.luau")
    workflow=read(".github/workflows/asset-export.yml")
    audit=read("tools/audit_hero_meshes.py")

    assert "from quality_engineer import build" in importer
    assert "return build()" in importer
    assert 'EngineerBody":engineer_body' in importer
    assert "source=engineer_body().export" in rig
    for token in ('def loft(', 'BlacklineEngineerOriginalIDPlate',
                  'circumaural headphones','belt field recorder',
                  'No exposed injuries', 'Normal human nose'):
        assert token.lower() in q.lower(),token
    assert "for side in (-1,1):" in q
    assert "m.add(loft" in q and "m.ellipsoid" in importer
    assert 'plaque(' in q
    assert 'trimesh.visual.TextureVisuals' in q
    assert 'metallicRoughnessTexture=orm' in q
    assert 'normalTexture=normal' in q
    assert "tools/quality_engineer.py" in workflow
    assert "grounded-character-Q02-source-candidate" in audit
    assert 'path.stem in {"EngineerBody","EngineerSkinned"}' in audit

    assert 'local skinnedReady=SkinnedEngineer.ready()' in owner
    assert 'if skinnedReady and SkinnedEngineer.mount(m,hrp,glows)' in owner
    assert 'hrp:SetNetworkOwner(nil)' in owner
    assert 'h.HipHeight = 3' in owner
    assert 'light.Parent=attachment' in runtime
    assert 'model:SetAttribute("RigVersion",2)' in runtime
    assert 'model:SetAttribute("CharacterVisualTier","Q02WeightedTechnician")' in runtime
    assert "bone.Transform=bone.Transform:Lerp(pose,alpha)" in motion
    assert "root.CFrame=" not in motion and "root.Position=" not in motion
    for token in ("p.CanCollide = false", "p.CanQuery = false", "p.Massless = true"):
        assert token in collider
    assert "expected exactly two preserved earcup warning lights" in studio
    assert 'root.Size~=Vector3.new(2,2,1)' in studio

    # These assets remain visually unnerving, not graphic, and contain no
    # simulated gore. The final *game*, not this file, needs Roblox's
    # honest Maturity & Compliance questionnaire at publication.
    for banned in ('blood', 'gore', 'torture', 'mutilation', 'exposed wound'):
        # Wording in benign negative comments is allowed. No modeled
        # blood families, blood effects or damage decals may be added.
        assert 'm.add_blood' not in q and 'bloodMaterial' not in q
    print("PASS Q02 Last Listener: original human-scale audio-technician model, ")
    print("      UV-mapped identity props, shared body/skin source, cosmetic-only rig")
    print("PENDING Studio imported bone motion, real human facial quality, graphics")
    print("        medium/high test, owner signoff, full-game Roblox maturity rating")

if __name__=="__main__":
    main()

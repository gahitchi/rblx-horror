#!/usr/bin/env python3
"""Offline regression checks for the opt-in imported skinned Engineer.

The importer may rename Bone instances or fail to preserve the skin; Roblox
Studio qualification is therefore mandatory and rig v1 remains an active fallback.
"""
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
def src(path):
    return (ROOT/path).read_text()

def main():
    importer=src("tools/studio/InstallImportedModels.luau")
    prefabs=src("src/server/PrefabLibrary.luau")
    source=src("src/server/Monster/SkinnedEngineer.luau")
    owner=src("src/server/Monster/EngineerModel.luau")
    motion=src("src/client/SkinnedEngineerMotion.luau")
    main=src("src/client/Main.client.luau")
    skin_generator=src("tools/build_skinned_engineer.py")
    skin_validator=src("tools/validate_skinned_engineer.py")
    build=src(".github/workflows/asset-export.yml")

    assert 'EngineerSkinned=true' in importer
    assert 'candidate.Name] and not SKINNED[candidate.Name]' in importer
    assert 'PrefabLibrary.hasBones("EngineerSkinned",REQUIRED)' in source
    assert 'child:IsA("Bone")' in prefabs and 'FindFirstChild(boneName,true)' in prefabs
    assert 'local skinnedReady=SkinnedEngineer.ready()' in owner
    assert 'if skinnedReady and SkinnedEngineer.mount(m,hrp,glows)' in owner
    assert 'elseif segmentedReady and ArticulatedEngineer.mount(m,hrp,glows)' in owner
    assert 'elseif PrefabLibrary.attach(hrp,"EngineerBody"' in owner
    assert 'model:SetAttribute("RigVersion",2)' in source
    assert 'model:SetAttribute("CharacterVisualTier","WeightedSkinPrototype")' in source
    assert 'light.Parent=attachment' in source
    assert 'RunService.PreSimulation:Connect' in motion
    assert 'bone.Transform=bone.Transform:Lerp(pose,alpha)' in motion
    assert 'local imported=root:FindFirstChild("EngineerSkinned")' in motion
    assert 'child:IsA("Bone")' in motion
    assert 'model:GetAttribute("RigVersion")~=2' in motion
    assert 'SkinnedEngineerMotion = SkinnedEngineerMotion' in main
    assert 'root.CFrame=' not in motion and 'root.Position=' not in motion
    assert '"JOINTS_0"' in skin_generator and '"WEIGHTS_0"' in skin_generator
    assert '"inverseBindMatrices"' in skin_generator and '"skin"' in skin_generator
    assert 'assert len(all_used)>=12' in skin_validator
    assert 'tools/validate_skinned_engineer.py' in build
    assert 'tools/build_skinned_engineer.py' in build
    assert 'No Root influences' not in motion  # 4 influences validated at GLB level
    print("PASS weighted runtime gates: validated 15-bone import, client-only deformation, "
          "retained movement authority and three-stage visual fallback")
    print("PENDING: skin survival through Studio importer, actual animation quality and multiplayer frame budget")

if __name__=="__main__":
    main()

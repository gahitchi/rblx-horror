#!/usr/bin/env python3
"""Static safety contract for Dead Air's cosmetic character mesh integration.

This cannot verify R15 retargeting, skin weights, live animation, visual quality
or Roblox import permissions. Those must be tested inside Studio.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent

def source(path):
    return (ROOT/path).read_text()

def require(expr,message):
    assert expr,message

def main():
    obj=source("tools/build_character_assets.py")
    installer=source("tools/studio/InstallImportedModels.luau")
    art=source("src/server/CharacterArt.luau")
    engineer=source("src/server/Monster/EngineerModel.luau")
    rig=source("src/server/Monster/ArticulatedEngineer.luau")
    motion=source("src/client/EngineerMotion.luau")
    main_client=source("src/client/Main.client.luau")
    main_script=source("src/server/Main.server.luau")
    prefabs=source("src/server/PrefabLibrary.luau")
    exporter=source(".github/workflows/asset-export.yml")
    audit=source("tools/audit_hero_meshes.py")
    for name in ("EngineerBody","FieldOperatorVest","FieldOperatorPack","FieldOperatorMask"):
        require('"'+name+'"' in obj,(name,"mesh not built"))
        require(name+" = true" in installer,(name,"Studio installer doesn't recognize model"))
        require('"'+name+'"' in audit,(name,"mesh export not audited"))
    for name in ("FieldOperatorVest","FieldOperatorPack","FieldOperatorMask"):
        require('PrefabLibrary.attach(' in art and '"'+name+'"' in art,
                (name,"not equipped to player rig"))
    require('PrefabLibrary.attach(hrp,"EngineerBody",CFrame.identity)' in engineer,
            "Engineer full-body mesh not attached to existing server-owned root")
    require('child~=hrp' in engineer, "Engineer gameplay HRP must remain visible to physics")
    require('m:SetAttribute("MonsterName", "The Engineer")' in engineer,
            "Engineer name contract changed")
    require('glow.Parent = cup' in engineer,
            "Lunge earcup indicator parts must retain controlled light")
    require('ArticulatedEngineer.mount(m,hrp,glows)' in engineer,
            "segmented rig not preferred over rigid body prototype")
    for joint in ("RigTorso","RigHead","RigArmLeft","RigArmRight",
                  "RigLegLeft","RigLegRight"):
        require('name="'+joint+'"' in rig,(joint,"missing motor rig bone"))
    require('joint.Part0=root' in rig and 'joint.Part1=bone' in rig,
            "motor joints must follow original server AI root")
    require('light.Parent=host' in rig, "live earcup glow must follow animated head")
    require('Motor6D' in motion and 'PreSimulation' in motion,
            "Engineer visual pose update missing")
    require('EngineerMotion = EngineerMotion' in main_client,
            "Engineer animation client controller not registered")
    require('h.HipHeight = 3' in engineer and 'hrp:SetNetworkOwner(nil)' in engineer,
            "Engineer collision, hip height or server authority changed")
    require('HumanoidRigType.R15' in art and
            'DeadAirAppearanceStatus","DefaultAvatar"' in art,
            "R6/custom avatar compatibility missing")
    require('character:GetAttribute("DeadAirAppearanceApplied")' in art,
            "duplicate cosmetics may be attached across spawn calls")
    require('inRound' in art and 'RoundService.onSpawn(' in main_script,
            "cosmetics must only be mounted on round spawns")
    require(main_script.index("RoundService.onSpawn(") <
            main_script.index("RoundService.init(layout)"),
            "character art callback must be registered before spawns")
    require('p.CanCollide = false' in prefabs and
            'p.CanQuery = false' in prefabs and
            'p.Massless = true' in prefabs,
            "imported visuals may interfere with physics / audio")
    require('python3 tools/build_character_assets.py' in exporter,
            "character exports missing from pack build")
    require('tools/audit_hero_meshes.py' in exporter,
            "GLB audit missing from pack build")
    require("normalTexture=Image.fromarray" in obj and
            "metallicRoughnessTexture=Image.fromarray" in obj,
            "hero model textures not in GLB exporter")
    print("PASS character contracts: 4 optional GLBs; safe Engineer root/lights;"
          " R15-only cosmetics; non-solid art; normal + ORM image maps")
    print("PENDING: in-Studio imported rig fit, overlapping avatar accessories,"
          " Engineer animation quality, final texture fidelity and FPS")

if __name__=="__main__":
    main()

#!/usr/bin/env python3
"""Source contracts for character articulation and four Blackline hero rooms.

Not an image-quality score and not proof of Roblox Studio physical navigation.
The Studio command-bar probes and actual rendering tests remain mandatory.
"""
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent

def content(path):
    return (ROOT/path).read_text()

def main():
    hero=content("src/server/Maps/BlacklineHeroRooms.luau")
    kit=content("src/server/Maps/Kit.luau")
    rig=content("src/server/Monster/ArticulatedEngineer.luau")
    model=content("src/server/Monster/EngineerModel.luau")
    motion=content("src/client/EngineerMotion.luau")
    client=content("src/client/Main.client.luau")
    exporter=content("tools/build_character_assets.py")
    studio=content("tools/studio/InstallImportedModels.luau")
    audit=content("tools/audit_hero_meshes.py")

    for name in ("Reception","StaffGallery","ControlA","LiveHall"):
        assert f'r.name=="{name}"' in hero,("authored flagship room missing",name)
    assert "BlacklineHeroRooms.decorate(detailFolder,lights,room,theme)" in kit
    assert 'spec.authored==true and spec.id=="studio"' in kit
    assert "p.CanCollide=false" in hero and "p.CanQuery=false" in hero
    assert 'p:SetAttribute("DisablePBR",true)' in hero
    assert 'p:SetAttribute("ArtPass","BlacklineHero01")' in hero
    assert 'if i==3 or i==4 then' in hero and "continue" in hero, (
        "doorway-safe sound diffusion gap has regressed")
    assert "r.height" in hero and "r.center" in hero, (
        "lighting should follow actual nonuniform room geometry")
    assert 'light.Enabled=false' in hero and 'light.Parent=emitter' in hero
    assert 'local emitter=part(lights,' in hero, (
        "practical emitters must be registered with the generator's PowerLights")
    assert 'local light=Instance.new("SurfaceLight")' in hero
    assert "CFrame.lookAt" in hero and "FixtureStandoff" in hero
    assert "Environment" not in hero or "No" not in hero  # no global light overrides

    rig_names=("RigTorso","RigHead","RigArmLeft","RigArmRight",
               "RigLegLeft","RigLegRight")
    for name in rig_names:
        assert f'name="{name}"' in rig,(name,"rig joint not declared")
        assert f'joint(root,"{name}")' in motion,(name,"client animation not bound")
        filename="Engineer"+name.replace("Rig","Rig",1)
        assert f'"{filename}"' in exporter,(filename,"not exported")
        assert f'{filename} = true' in studio,(filename,"not importable")
        assert f'"{filename}"' in audit,(filename,"not covered by GLB audit")
    assert 'Motor6D' in rig and 'joint.Part0=root' in rig
    assert 'joint.Part1=bone' in rig and 'joint.C0=CFrame.new(spec.offset)' in rig
    assert 'p.CanCollide = false' in content("src/server/PrefabLibrary.luau")
    assert 'light.Parent=host' in rig
    assert 'ArticulatedEngineer.mount(m,hrp,glows)' in model
    assert 'elseif PrefabLibrary.attach(hrp,"EngineerBody"' in model, (
        "rig must retain the old full-body fallback")
    assert 'm:SetAttribute("CharacterVisualTier","ProceduralFallback")' in model
    assert 'EngineerMotion = EngineerMotion' in client
    assert 'RunService.PreSimulation:Connect' in motion
    assert 'model:GetAttribute("Lunging")' in motion
    assert 'model:GetAttribute("State")' in motion
    assert 'j.head.Transform=' in motion and 'j.leftLeg.Transform=' in motion
    assert 'root.CFrame=' not in motion and 'root.Position=' not in motion,(
        "client visual animation must never steer a server-owned NPC")

    print("PASS visual prototype gates: 4 functional flagship rooms, generator-linked "
          "lights, 6-segment Engineer rig, root-safe client poses, mesh/fallback checks")
    print("PENDING: studio render review, native nav/acoustic tests, skinned mesh deformation,"
          " real animation quality, relative character proportions, measured FPS")


if __name__=="__main__":
    main()

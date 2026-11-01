#!/usr/bin/env python3
"""Q01 static production contract for the first modeled console benchmark.

The asset-export workflow checks the real exported GLB's triangles, dimensions
and UV maps. Static tests here defend map/collider/import fallback integration.
Neither test proves Roblox Studio image quality.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent

def read(name):
    return (ROOT/name).read_text()

def main():
    exporter=read("tools/build_signature_assets.py")
    model=read("tools/quality_console.py")
    audit=read("tools/audit_hero_meshes.py")
    kit=read("src/server/Maps/Kit.luau")
    prefab=read("src/server/PrefabLibrary.luau")
    installer=read("tools/studio/InstallImportedModels.luau")
    workflow=read(".github/workflows/asset-export.yml")
    rojo=read(".github/workflows/rojo-build.yml")
    inspector=read("tools/studio/InspectConsoleQuality.luau")
    assert "from quality_console import build" in exporter
    assert '"BlacklineHeroConsole":blackline_hero_console' in exporter
    assert 'BlacklineHeroConsole = true' in installer
    assert 'tools/quality_console.py' in workflow
    assert "validate_console_quality.py" in rojo
    assert 'if theme.id=="studio" and r.name=="ControlA"' in kit
    assert 'PrefabLibrary.place(parent,"BlacklineHeroConsole"' in kit
    assert '"DeskPlinth"' in kit
    assert 'collider.Transparency=1' in kit
    assert 'collider:SetAttribute("VisualPresentation","BlacklineHeroConsole")' in kit
    assert 'FinishDetail.counter' in kit, "no imported-art fallback"
    assert 'clone:SetAttribute("ImportedArt",true)' in prefab
    assert 'p.CanCollide = false' in prefab and 'p.CanQuery = false' in prefab
    assert 'p:SetAttribute("DisablePBR",true)' in prefab
    assert "Blackline12ChannelScreenprint" in model
    assert "Blackline12ChannelMeterBridge" in model
    assert "for ch in range(12):" in model
    assert "return 3.02-.21*z" in model
    assert "the operator FRONT faces +Z" in model or "operator FRONT faces +Z" in model
    assert "rounded_outline" in model and "soft_case" in model
    assert "polygon_case" in model and "print_atlas" in model
    assert "metallicRoughnessTexture=orm" in model
    assert "normalTexture=n" in model
    assert "Q01" in audit and "Blackline12ChannelScreenprint" in audit
    assert "source console has wrong scale" in inspector
    assert "p50/p95 frame time" in inspector
    for forbidden in ('Instance.new("Sound")','ProximityPrompt','RemoteEvent',
                      'ObjectiveService','MonsterService','Lighting.Brightness'):
        assert forbidden not in model, forbidden
    print("PASS Q01: 12-channel modeled console + printed PBR atlas,")
    print("         original Control A collider, import and native fallback intact")
    print("PENDING real Studio angles, surface quality, lighting, performance and")
    print("         replacing an old installed prefab after preserving a backup")

if __name__=="__main__":
    main()

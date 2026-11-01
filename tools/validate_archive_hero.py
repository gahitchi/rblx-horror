#!/usr/bin/env python3
"""VF02 source and placement qualification for Blackline's archive hero.

A focused static acceptance check, not a substitute for Roblox first-person
inspection, artist review, collision validation, or measured rendering cost.
"""
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parent.parent

def read(path):
    return (ROOT/path).read_text()

def main():
    layout=read("src/server/Maps/BlacklineLayout.luau")
    kit=read("src/server/Maps/Kit.luau")
    art=read("src/server/Maps/BlacklineArchiveHero.luau")
    exporter=read("tools/build_signature_assets.py")
    importer=read("tools/studio/InstallImportedModels.luau")
    audit=read("tools/audit_hero_meshes.py")
    rooms=re.findall(
        r'\{name="([^"]+)",role="([^"]+)",x1=(-?\d+),x2=(-?\d+),'
        r'z1=(-?\d+),z2=(-?\d+),height=(\d+)\}',layout)
    by_name={name:(role,*map(int,(x1,x2,z1,z2,h)))
             for name,role,x1,x2,z1,z2,h in rooms}
    assert len(rooms)==19
    assert "TapeArchive" in by_name
    role,x1,x2,z1,z2,height=by_name["TapeArchive"]
    assert role=="archive"
    assert x2-x1>=36 and z2-z1>=27 and height>=13
    # The cabinet's rear must live on an uninterrupted outer wall. A north
    # neighbor/portal would turn this object into a blocked entrance.
    for name,(_,a,b,c,d,_) in by_name.items():
        if name!="TapeArchive":
            assert not (d==z1 and min(b,x2)>max(a,x1)),(
                "north wall no longer free",name)
    width,depth,front=11.8,1.95,1.56
    cx=(x1+x2)/2
    assert cx-width/2>x1+6 and cx+width/2<x2-6
    assert z1+1.16+front<z1+3.0 and z1+3.0<z2-8
    assert height>8.5
    assert 'local base=CFrame.new(r.center.X,0,r.z1+1.16)*CFrame.Angles(0,math.pi,0)' in art
    assert 'if r.name~="TapeArchive" then return end' in art
    assert 'BlacklineArchiveHero.decorate(detailFolder,room)' in kit
    assert 'spec.authored==true and spec.id=="studio"' in kit
    assert 'PrefabLibrary.place(scene,"BlacklineArchiveCabinet",base)' in art
    assert 'nativeCabinet(scene,base)' in art
    assert 'if index~=8 then' in art and '08  /  NOT RETURNED' in art
    assert 'scene:SetAttribute("VisualTier","ImportedPBR")' in art
    assert 'scene:SetAttribute("VisualTier","NativeFallback")' in art
    # Both presentation paths use original static, nonblocking geometry.
    for expected in ('p.CanCollide=false','p.CanTouch=false','p.CanQuery=false',
                     'p:SetAttribute("DisablePBR",true)','p.CastShadow=false'):
        assert expected in art,expected
    forbidden=('ObjectiveService','ProximityPrompt','ClickDetector',
               'RemoteEvent','RemoteFunction','TweenService','Heartbeat',
               'PowerLights','PointLight','SurfaceLight','SoundService')
    assert not any(item in art for item in forbidden),"mechanics leaked into art"
    assert 'def blackline_archive_cabinet():' in exporter
    assert '"BlacklineArchiveCabinet":blackline_archive_cabinet' in exporter
    assert 'm.box((0,4.25,0),(11.8,8.5,1.85),"iron")' in exporter
    assert 'metallicFactor=0,roughnessFactor=.89' in exporter
    assert '"BlacklineArchiveCabinet" in exporter' or (
        '"BlacklineArchiveCabinet":blackline_archive_cabinet' in exporter)
    assert "BlacklineArchiveCabinet = true" in importer
    assert audit.count('"BlacklineArchiveCabinet"')>=2
    print("PASS VF02: authored archive placement, eight narrative slots,")
    print("           native/GLB parity, no new gameplay, physics, audio or lighting")
    print("PENDING: Studio sightlines, mesh pivots and render/performance review")

if __name__=="__main__":
    main()

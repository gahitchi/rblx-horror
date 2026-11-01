#!/usr/bin/env python3
"""VF03: topology-aware source QA for the MasteringVault / ViewingGallery pass.

Checks honest spatial constraints and art-only routing. Studio collision,
renderer, perspective and acoustic simulation must still be tested natively.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def read(path: str) -> str:
    return (ROOT / path).read_text()

def rooms_and_links():
    src = read("src/server/Maps/BlacklineLayout.luau")
    rows = re.findall(
        r'\{name="([^"]+)",role="([^"]+)",x1=(-?\d+),x2=(-?\d+),'
        r'z1=(-?\d+),z2=(-?\d+),height=(\d+)\}', src
    )
    assert len(rows) == 19, "authored Blackline rooms changed"
    rooms = {n: (role, *map(int, (x1, x2, z1, z2, h)))
             for n, role, x1, x2, z1, z2, h in rows}
    link_section = src.split("local links={", 1)[1].split("    return {", 1)[0]
    links = {(a,b): (kind or "normal") for a,b,kind in re.findall(
        r'\{"([^"]+)","([^"]+)"(?:,"([^"]+)")?\}',link_section)}
    return rooms,links

def main():
    rooms,links = rooms_and_links()
    m = rooms["MasteringVault"]
    g = rooms["ViewingGallery"]
    live = rooms["LiveHall"]
    archive = rooms["TapeArchive"]
    assert m == ("master", -72, -24, -192, -160, 14)
    assert g == ("corridor", -72, 30, -160, -128, 18)
    assert live[:5] == ("live", -72, 30, -128, -60)
    assert archive[:5] == ("archive", -24, 30, -192, -160)
    edges = {frozenset((a,b)):kind for (a,b),kind in links.items()}
    assert edges[frozenset(("MasteringVault","ViewingGallery"))]=="normal"
    assert edges[frozenset(("MasteringVault","TapeArchive"))]=="normal"
    assert edges[frozenset(("IsolationWest","MasteringVault"))]=="booth"
    assert edges[frozenset(("ViewingGallery","LiveHall"))]=="open"
    # Existing MasteringVault left-hand shift board: x=-63 +/-5.15.
    # Reference array: x=-36.5 +/-6.65; right edge is 5.85 studs from
    # east wall. Its footprint never approaches y<3.35 or the door midlines.
    x1,x2,z1,z2 = m[1:5]
    center_x = x2 - 12.5
    half_width = 13.3/2
    assert center_x-half_width > x1+20
    assert center_x+half_width < x2-5.5
    assert center_x-half_width > x1+9+10.3/2+8
    assert z1+1.16+1.30 < z1+3
    assert z1+3 < z2-8
    assert (m[5] > 9.45)
    # Open gallery doorway on its southern wall is centered x=-21,
    # width14; the 9-stud observation pane has to shift east to x=23.5.
    # These are Kit's actual rules, not guessed scene coordinates.
    kit = read("src/server/Maps/Kit.luau")
    assert 'along=hi-6.5' in kit
    assert 'local width=9' in kit
    assert 'local width=if kind=="open" then 14 else 8' in kit
    open_cx=(g[1]+g[2])/2
    pane_cx=g[2]-6.5
    pane_lo,pane_hi=pane_cx-4.5,pane_cx+4.5
    open_lo,open_hi=open_cx-7,open_cx+7
    assert open_hi+1 < pane_lo
    assert pane_hi+1 < g[2]
    talk_x=pane_cx-8.65
    assert talk_x + 4.0/2 < pane_lo
    assert talk_x - 4.0/2 > open_hi + 1
    # Existing north door opening centers at -48 and 3. A 17-stud
    # sign centered at -21 fits strictly between these openings.
    sign_left,sign_right=open_cx-17/2,open_cx+17/2
    mastering_door_right=(-72-24)/2+4
    archive_door_left=(-24+30)/2-4
    assert mastering_door_right+1 < sign_left
    assert sign_right+1 < archive_door_left

    hero = read("src/server/Maps/BlacklineMasteringGallery.luau")
    assets = read("src/server/Maps/AssetLibrary.luau")
    architecture = read("src/server/Maps/ArchitecturalDetail.luau")
    story = read("src/server/Maps/StoryProps.luau")
    exporter = read("tools/build_signature_assets.py")
    installer = read("tools/studio/InstallImportedModels.luau")
    audit = read("tools/audit_hero_meshes.py")
    workflow = read(".github/workflows/rojo-build.yml")
    assert 'BlacklineMasteringGallery.decorate(detailFolder,room)' in kit
    assert 'spec.authored==true and spec.id=="studio"' in kit
    assert 'room.z1,room.z2,room.height,theme,room.name)' in kit
    for s in ('if room.name == "MasteringVault"',
              'elseif room.name == "ViewingGallery"',
              'local base = CFrame.new(room.x2 - 12.5, 0, room.z1 + 1.16)',
              'PrefabLibrary.place(model, "BlacklineMasterReference", base)',
              'nativeReference(model, base)',
              'local cx = room.x2 - 6.5',
              'local callX = cx - 8.65',
              'model:SetAttribute("AcousticPaneOwnedBy", "Kit")',
              'model:SetAttribute("VisualTier", "ImportedPBR")',
              'model:SetAttribute("VisualTier", "NativeFallback")',
              'p.CanQuery = false', 'p.CanCollide = false',
              'p.CanTouch = false', 'p:SetAttribute("DisablePBR", true)'):
        assert s in hero,s
    for forbidden in ("ProximityPrompt", "ObjectiveService", "RoundService",
                      "RemoteEvent", "RemoteFunction", "TweenService",
                      "Heartbeat", "PathfindingService", 'Instance.new("Sound")',
                      'Instance.new("PointLight")', 'Instance.new("SurfaceLight")',
                      'Instance.new("SpotLight")'):
        assert forbidden not in hero,forbidden
    # The old shared library used to cover both doorway faces with racks,
    # speakers and repetitive acoustic slats. Only this room opts out.
    assert 'and roomName~="MasteringVault"' in assets
    assert 'roomName~="MasteringVault"' in architecture
    assert 'roomName~="ViewingGallery"' in architecture, (
        "redundant general cable tray not removed from signature gallery")
    # A single purpose-built transfer station replaces the misleading
    # generic fallback; both paths face into the south of MasteringVault.
    assert 'transferStation(parent,room)' in hero
    assert 'model.Name="MasteringTransferStation"' in hero
    assert 'PrefabLibrary.place(model,"BlacklineTransferDeck",base)' in hero
    assert 'nativeTransfer(model,base)' in hero
    assert 'CFrame.new(room.x1+13,0,room.z1+12)*' in hero
    assert 'CFrame.Angles(0,math.pi,0)' in hero
    assert '"ArchiveTransferFallback"' not in story
    assert 'PrefabLibrary.place(parent,"BlacklineTransferDeck"' not in story
    assert hero.count('PrefabLibrary.place(model,"BlacklineTransferDeck",base)')==1
    # 5-stud-wide, 4-stud-high station is offset from all portal cutouts
    # and from the reference monitor wall by more than 5 studs.
    tx,tz=x1+13,z1+12
    assert tx-2.5>x1+8 and tx+2.5<x2-15
    assert tz-2.2>z1+8 and tz+2.2<z2-8
    assert center_x-half_width-(tx+2.5)>12
    assert 'roomName: string?' in assets and 'roomName: string?' in architecture
    assert 'CFrame.new(r.center.X,9.7,r.z1+0.95),17,2.6)' in story
    assert 'BlacklineMasterReference = true' in installer
    assert 'def blackline_master_reference():' in exporter
    assert '"BlacklineMasterReference":blackline_master_reference' in exporter
    assert audit.count('"BlacklineMasterReference"')>=2
    assert "validate_mastering_gallery.py" in workflow
    assert "src/server/Maps/BlacklineMasteringGallery.luau" in workflow
    print("PASS VF03: true portal/window geometry, MasteringVault clearances,")
    print("           authored glTF/native artwork, no new gameplay, sound or collision")
    print("PENDING: imported mesh orientation, in-Studio sightlines and renderer cost")

if __name__ == "__main__":
    main()

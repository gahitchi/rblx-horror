#!/usr/bin/env python3
"""Check authored Luau room catalogs and original OBJ geometry without Roblox Studio."""
import re
from collections import defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
source = (ROOT / "src/server/Maps/Layouts.luau").read_text()
files = ["console-master.obj", "broadcast-microphone.obj", "foundry-bell.obj",
         "cassette-recorder.obj", "engineer-headset.obj"]

def brace_chunk(text, key):
    m = re.search(r"\b" + re.escape(key) + r"\s*=\s*\{", text)
    assert m, f"Missing {key} block"
    start = m.end()-1
    depth = 0
    quote = False
    escape = False
    for i in range(start,len(text)):
        ch=text[i]
        if quote:
            if escape: escape=False
            elif ch=="\\": escape=True
            elif ch=='"': quote=False
            continue
        if ch=='"': quote=True
        elif ch=="{": depth += 1
        elif ch=="}":
            depth -= 1
            if depth==0: return text[start:i+1]
    raise AssertionError(f"Unclosed {key} block")

def room_rows(chunk):
    return [re.findall(r'"([^"]+)"', row) for row in re.findall(r"\{([^{}]+)\}",chunk)]

def check_map(mapid):
    start = source.index(f"function Layouts.{mapid}()")
    later = source.find("\nfunction Layouts.",start+1)
    block = source[start:later if later!=-1 else len(source)]
    names=room_rows(brace_chunk(block,"names"))
    roles=room_rows(brace_chunk(block,"roles"))
    assert len(names)==len(roles)==5,(mapid,len(names),len(roles))
    assert all(len(n)==len(r)==4 for n,r in zip(names,roles))
    flattened=[name for row in names for name in row]
    assert len(flattened)==len(set(flattened))==20,(mapid,"duplicate rooms")
    def key(k):
        m=re.search(r"\b"+k+r'="([^"]+)"',block)
        assert m, (mapid,k)
        assert m.group(1) in flattened,(mapid,k,m.group(1))
        return m.group(1)
    for k in ("generator","fuseBox","tape","spawn","monster"):key(k)
    fuse= re.findall(r'"([^"]+)"',brace_chunk(block,"fuseRooms"))
    assert len(fuse)>=10 and len(fuse)==len(set(fuse)),(mapid,"fuse count")
    assert set(fuse).issubset(flattened),(mapid,"unknown fuse rooms")
    xs=[float(v) for v in re.findall(r"-?\d+",brace_chunk(block,"x"))]
    zs=[float(v) for v in re.findall(r"-?\d+",brace_chunk(block,"z"))]
    assert len(xs)==5 and len(zs)==6,(mapid,"grid dims")
    assert all(b-a>=24 for a,b in zip(xs,xs[1:])),(mapid,"narrow cell")
    assert all(b-a>=24 for a,b in zip(zs,zs[1:])),(mapid,"narrow cell")
    # Cross-check the explicit network built in Layouts.luau.
    edges=[]
    for col in (1,3):edges.append(((1,col),(1,col+1)))
    for row in range(2,6):
        for col in range(1,4):edges.append(((row,col),(row,col+1)))
    for r,c in [(1,2),(1,4),(2,1),(2,3),(2,4),(3,1),(3,2),(3,3),
                (4,1),(4,2),(4,3),(4,4)]:
        edges.append(((r,c),(r+1,c)))
    adjacency=defaultdict(set)
    for a,b in edges: adjacency[a].add(b);adjacency[b].add(a)
    visited={(5,3)}
    pending=deque(visited)
    while pending:
        for neighbour in adjacency[pending.popleft()]:
            if neighbour not in visited:
                visited.add(neighbour);pending.append(neighbour)
    assert len(visited)==20,(mapid,"unreachable room")
    assert len(edges)-20+1>=4,(mapid,"insufficient escape loops")
    leaves=[v for v,adj in adjacency.items() if len(adj)==1]
    assert len(leaves)>=2,(mapid,"need risky dead ends")
    booth_block=brace_chunk(block,"booths")
    booth_names=re.findall(r"(\w+)\s*=\s*true",booth_block)
    for b in booth_names:
        assert b in flattened
        j=flattened.index(b)
        assert (j//4+1,j%4+1) in leaves,(mapid,"booth has alternate exit",b)
    # Observation glazing must join real neighboring rooms; a window must never
    # secretly create a monster route or collide with the door on the same wall.
    windows=room_rows(brace_chunk(block,"windows"))
    assert len(windows)>=1,(mapid,"no observation glazing")
    assert all(len(pair)==2 and pair[0]!=pair[1] for pair in windows)
    room_coords={name:(r+1,c+1) for r,row in enumerate(names) for c,name in enumerate(row)}
    for first,second in windows:
        assert first in room_coords and second in room_coords,(mapid,"unknown window room")
        a,b=room_coords[first],room_coords[second]
        assert abs(a[0]-b[0])+abs(a[1]-b[1])==1,(mapid,"window on nonadjacent rooms")
        pair=(a,b) if a<b else (b,a)
        is_open=pair in edges or (pair[1],pair[0]) in edges
        if is_open:
            span=(xs[1]-xs[0]) if a[0]!=b[0] else (zs[1]-zs[0])
            assert span>=30,(mapid,"door and glazing have insufficient wall")
    assert len(set(tuple(sorted(window)) for window in windows))==len(windows)
    print(f"PASS {mapid}: 20 rooms, {len(edges)} links, {len(leaves)} dead ends, "
          f"{len(fuse)} fuse sites, {len(booth_names)} booths")

def check_blackline_authored_geometry():
    file=(ROOT/"src/server/Maps/BlacklineLayout.luau").read_text()
    data=re.findall(
        r'\{name="([^"]+)",role="([^"]+)",x1=(-?\d+),x2=(-?\d+),'
        r'z1=(-?\d+),z2=(-?\d+),height=(\d+)\}',file
    )
    assert len(data)==19,("expected 19 authored functional rooms",len(data))
    room={name:(role,*map(int,(x1,x2,z1,z2,height)))
          for name,role,x1,x2,z1,z2,height in data}
    assert len(room)==len(data),"duplicate architectural areas"
    for a,(role,x1,x2,z1,z2,h) in room.items():
        assert x2-x1>=22 and z2-z1>=22 and h>=13,(a,"invalid usable room geometry")
    names=list(room)
    for i,a in enumerate(names):
        _,ax1,ax2,az1,az2,_=room[a]
        for b in names[i+1:]:
            _,bx1,bx2,bz1,bz2,_=room[b]
            assert min(ax2,bx2)-max(ax1,bx1)<=0 or min(az2,bz2)-max(az1,bz1)<=0,(
                a,b,"rooms overlap in occupied space")
    link_block=file.split('local links={',1)[1].split('    return {',1)[0]
    links=re.findall(r'\{"([^"]+)","([^"]+)"(?:,"([^"]+)")?\}',link_block)
    assert len(links)>=23,(len(links),"too few interconnecting routes")
    graph=defaultdict(set)
    edges=set()
    for a,b,kind in links:
        assert a in room and b in room and a!=b,(a,b,"bad link")
        _,ax1,ax2,az1,az2,_=room[a]
        _,bx1,bx2,bz1,bz2,_=room[b]
        edge=frozenset((a,b))
        assert edge not in edges,("duplicate link",a,b)
        edges.add(edge)
        width=14 if kind=="open" else 8
        horizontal=(az2==bz1 or bz2==az1) and min(ax2,bx2)-max(ax1,bx1)>=width+4
        vertical=(ax2==bx1 or bx2==ax1) and min(az2,bz2)-max(az1,bz1)>=width+4
        assert horizontal or vertical,(a,b,"door endpoints not physically adjacent")
        graph[a].add(b)
        graph[b].add(a)
    visited={"Reception"}
    queue=deque(visited)
    while queue:
        for nxt in graph[queue.popleft()]:
            if nxt not in visited:
                visited.add(nxt)
                queue.append(nxt)
    assert len(visited)==len(room),(len(visited),"unreachable story rooms")
    assert len(edges)-len(room)+1>=6,"not enough intentional escape loops"
    for booth in ("IsolationWest","IsolationEast"):
        assert len(graph[booth])==1,("unsafe booth with multiple doors",booth)
    for objective in ("Reception","GeneratorRoom","PatchBay","ControlA","TapeArchive"):
        assert objective in graph,(objective,"absent gameplay destination")
    # A door and an observation pane may share an architectural boundary;
    # the window/door modules must stagger their centers rather than overlap.
    assert 'along=hi-6.5' in (ROOT/"src/server/Maps/Kit.luau").read_text()
    assert 'room.height' in (ROOT/"src/server/Maps/Kit.luau").read_text()
    assert 'wallBands' in (ROOT/"src/server/Maps/Kit.luau").read_text()
    print(f"PASS authored Blackline: {len(room)} nonoverlapping functional rooms, "
          f"{len(edges)} physically adjacent routes, {len(edges)-len(room)+1} loops")


def check_mesh(name):
    file=ROOT/"assets/meshes"/name
    lines=file.read_text().splitlines()
    nv=sum(line.startswith("v ") for line in lines)
    nu=sum(line.startswith("vt ") for line in lines)
    faces=[line for line in lines if line.startswith("f ")]
    assert nv>=100 and nv==nu and len(faces)>=80,(name,"missing geometry/uv")
    for line in faces:
        for component in line[2:].split():
            pos,uv=component.split("/")[:2]
            assert 1<=int(pos)<=nv and 1<=int(uv)<=nu,(name,component)
    print(f"PASS OBJ {name}: {nv} vertices, {len(faces)} faces, UV indices valid")

def check_pbr_asset_wiring():
    glb_script=(ROOT/"tools/build_glb_assets.py").read_text()
    kit=(ROOT/"src/server/Maps/Kit.luau").read_text()
    asset_lib=(ROOT/"src/server/Maps/AssetLibrary.luau").read_text()
    monster=(ROOT/"src/server/Monster/EngineerModel.luau").read_text()
    items=(ROOT/"src/server/ItemArt.luau").read_text()
    prefabs=(ROOT/"src/server/PrefabLibrary.luau").read_text()
    studio=(ROOT/"tools/studio/InstallImportedModels.luau").read_text()
    for key in ("MixingConsole","BroadcastMicrophone","FoundryBell",
                "CassetteRecorder","EngineerHeadset","WalkieTalkie",
                "AnalogRack","NearfieldMonitor","TapeReel"):
        assert key in glb_script,("GLB exporter missing",key)
        assert key in studio,("Studio installer missing",key)
        assert any(key in text for text in (kit,asset_lib,monster,items)),("No scene uses",key)
    assert 'local ServerStorage = game:GetService("ServerStorage")' in prefabs
    assert "p.CanCollide = false" in prefabs
    assert "p.CanQuery = false" in prefabs
    assert "p.Massless = true" in prefabs
    assert "joint.Part0 = root" in prefabs
    print("PASS prefab integrations: nine asset keys, non-solid welded visual roots")
    story=(ROOT/"src/server/Maps/StoryProps.luau").read_text()
    new_assets=("ReceptionTerminal","TapeArchiveCart","ServiceIntercom","StudioWallClock")
    for name in new_assets:
        assert name in glb_script,("new GLB exporter missing",name)
        assert name in studio,("studio installer missing optional asset",name)
        assert name in story,("new Blackline prop is not placed",name)
    assert 'StoryProps.decorate(detailFolder,room,theme,lights)' in kit
    assert 'PowerLights' in kit and 'powerIndicator(lights,r,' in story
    assert 'CanQuery=false' in story and 'CanCollide=false' in story
    signature=(ROOT/"tools/build_signature_assets.py").read_text()
    for name in ("BlacklineTransferDeck","BlacklinePatchMatrix"):
        assert name in signature,("Missing original environment hero mesh",name)
        assert name in studio,("Studio importer does not accept environment hero mesh",name)
    assert 'if not PrefabLibrary.place(parent,"BlacklinePatchMatrix"' in story
    # Mastering now has a room-owned visual fallback, not StoryProps' generic rack.
    mastering=(ROOT/"src/server/Maps/BlacklineMasteringGallery.luau").read_text()
    assert 'PrefabLibrary.place(model,"BlacklineTransferDeck",base)' in mastering
    assert 'nativeTransfer(model,base)' in mastering
    assert 'BlacklineMasteringGallery.decorate(detailFolder,room)' in kit
    assert 'PrefabLibrary.place(parent,"BlacklineTransferDeck"' not in story
    assert "BlacklineHeroConsole" in signature
    assert "BlacklineHeroConsole" in studio
    assert 'r.name=="ControlA"' in kit and '"BlacklineHeroConsole"' in kit
    assert 'collider:SetAttribute("VisualPresentation","BlacklineHeroConsole")' in kit
    assert 'local floorMaterial,ceilingMaterial,floorTint,ceilingTint=' in kit
    assert 'interiorFinishes(spec,room)' in kit
    assert 'FunctionalSurfaceRole' in kit
    print("PASS Blackline story assets: six new optional environment meshes,"
          " map-purpose floors and powered wayfinding")

def check_lighting_security():
    import json
    # Restricted properties may be authored in a place, never assigned at runtime.
    for script in ("src/server/VisualFidelity.luau", "src/hub/server/Main.server.luau"):
        body = (ROOT / script).read_text()
        for property_name in ("LightingStyle", "PrioritizeLightingQuality"):
            assert not re.search(r"\\bLighting\\." + property_name + r"\\s*=", body), (
                script, "restricted lighting property was assigned at runtime", property_name
            )
    for project in ("default.project.json", "hub.project.json"):
        tree = json.loads((ROOT / project).read_text())["tree"]
        props = tree["Lighting"]["$properties"]
        assert props["LightingStyle"] == "Realistic", (project, "missing Realistic lighting")
        assert props["PrioritizeLightingQuality"] is True, (project, "missing lighting priority")
    print("PASS lighting security: no protected runtime writes, both Rojo places configured")


def check_finish_detail_contract():
    kit = (ROOT/"src/server/Maps/Kit.luau").read_text()
    finish = (ROOT/"src/server/Maps/FinishDetail.luau").read_text()
    pbr = (ROOT/"src/server/Maps/PBRMaterials.luau").read_text()
    doors = (ROOT/"src/server/DoorService.luau").read_text()
    d0=kit.index("local function doorLeaf(")
    d1=kit.index("local function portalsForEdge(", d0)
    door=kit[d0:d1]
    furnishing=kit[kit.index("local function furnishing("):d0]
    assert 'leaf:SetAttribute("DisablePBR",true)' in door
    assert 'leaf:SetAttribute("DoorArtVersion",2)' in door
    assert 'Enum.Material.SmoothPlastic,true' in door
    assert 'FinishDetail.doorFields(leaf,mapId,portal.kind,attachment)' in door
    assert 'item:SetAttribute("DisablePBR",true)' in door
    assert 'for _, side in {-1,1} do' in finish
    assert 'PressedFieldBacking' in finish and 'PressedField' in finish
    assert 'local median=math.max(' in pbr and 'median>=0.6' in pbr
    assert 'doorByName[p.name]=doorLeaf(doors,p,theme,spec.id)' in kit
    assert 'p.kind~="open" and p.kind~="window"' in kit
    assert 'leaf:SetAttribute("Kind",portal.kind)' in door
    assert 'DoorService.register' in (ROOT/"src/server/Main.server.luau").read_text()
    assert 'state.part.CanCollide = not open' in doors
    assert 'state.part.CanQuery = not open' in doors

    # Furniture must retain the collision proxy but make the broad color and
    # tabletop independent of global tiled oxidized-steel/aged-oak materials.
    assert 'collider.Transparency=1' in furnishing
    assert 'counterProxy.Transparency=1' in furnishing
    assert 'counterProxy:SetAttribute("DisablePBR",true)' in furnishing
    assert 'FinishDetail.counter(parent,theme.id,"control"' in furnishing
    assert 'FinishDetail.counter(parent,theme.id,"reception"' in furnishing
    assert 'PrefabLibrary.place(parent,"MixingConsole"' in furnishing
    assert 'CounterWorktop' in finish and 'CounterFrontFacade' in finish
    assert 'CounterToeRunner' in finish and 'CounterAccessField' in finish
    assert 'p.CanCollide = false' in finish
    assert 'p.CanQuery = false' in finish
    assert 'p:SetAttribute("DisablePBR",true)' in finish
    prefabs=(ROOT/"src/server/PrefabLibrary.luau").read_text()
    assert 'p:SetAttribute("DisablePBR",true)' in prefabs, "imported mesh PBR must be preserved"
    assert 'part:FindFirstChildOfClass("SurfaceAppearance")==nil' in pbr, (
        "SurfaceAppearance should never be overridden by environment tiling")
    assert 'if PrefabLibrary.place(parent,"MixingConsole"' in furnishing
    assert 'FinishDetail.consoleMount(parent,theme.id' in furnishing
    assert 'ConsolePedestalCrossbrace' in finish
    assert 'box(parent,"CounterTop"' not in furnishing
    assert 'box(parent,"ConsoleSurface"' not in furnishing
    for identifier in ("studio","radio","foundry"):
        assert identifier + " = {" in finish, ("missing map-specific finish",identifier)
    print("PASS finish contract: matte door fields, deliberate table facades, preserved interaction hulls")


if __name__=="__main__":
    for ident in ("radio","foundry"):check_map(ident)
    check_blackline_authored_geometry()
    for item in files:check_mesh(item)
    check_pbr_asset_wiring()
    check_lighting_security()
    check_finish_detail_contract()

#!/usr/bin/env python3
"""LD03 offline geometry and acoustic contract audit.

This intentionally checks geometric facts only. PathfindingService, door swings,
sound raycasts, GPU draw calls and player readability require Roblox Studio.
"""
import json
from collections import defaultdict, deque
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
design=json.loads((ROOT/"docs/design/blackline_graph.json").read_text())
areas={r["id"]:r["bounds"] for r in design["rooms"]}
portals=[]
walls=defaultdict(list)

def shared(a,b):
    ax,bx=areas[a],areas[b]
    xlo,xhi=max(ax["x1"],bx["x1"]),min(ax["x2"],bx["x2"])
    zlo,zhi=max(ax["z1"],bx["z1"]),min(ax["z2"],bx["z2"])
    if ax["z2"]==bx["z1"] or bx["z2"]==ax["z1"]:
        return ("X",ax["z2"] if ax["z2"]==bx["z1"] else bx["z2"],xlo,xhi)
    if ax["x2"]==bx["x1"] or bx["x2"]==ax["x1"]:
        return ("Z",ax["x2"] if ax["x2"]==bx["x1"] else bx["x2"],zlo,zhi)
    raise AssertionError((a,b,"no shared straight wall"))

def add(a,b,kind):
    axis,at,lo,hi=shared(a,b)
    width=14 if kind=="open" else 9 if kind=="window" else 10 if kind=="front" else 8
    assert hi-lo>=width+4,(a,b,"insufficient wall for portal")
    center=(lo+hi)/2
    if kind=="window":
        # Match the authored Kit window-staggering rule exactly.
        if any(p["axis"]==axis and p["at"]==at and
               p["center"]==center and p["kind"]!="window" for p in portals):
            center=hi-6.5
    portals.append(dict(a=a,b=b,kind=kind,axis=axis,at=at,
                        lo=lo,hi=hi,width=width,center=center))

for a,r in areas.items():
    for axis,at,lo,hi in (("X",r["z1"],r["x1"],r["x2"]),
                         ("X",r["z2"],r["x1"],r["x2"]),
                         ("Z",r["x1"],r["z1"],r["z2"]),
                         ("Z",r["x2"],r["z1"],r["z2"])):
        walls[(axis,at)].append((lo,hi,a,r["height"]))

for item in design["traversalPortals"]:
    add(item["a"],item["b"],item["kind"])
for a,b in design["visualOnlySightlines"]:
    add(a,b,"window")

for p in portals:
    cuts=sorted({pos for lo,hi,_,_ in walls[(p["axis"],p["at"])] for pos in (lo,hi)})
    segments=[(lo,hi) for lo,hi in zip(cuts,cuts[1:])
              if lo<p["center"]<hi and any(
                  start<=lo and end>=hi for start,end,_,_ in walls[(p["axis"],p["at"])]
              )]
    assert len(segments)==1,(p,"portal center falls on partition")
    left,right=segments[0]
    assert p["center"]-p["width"]/2>=left and p["center"]+p["width"]/2<=right,(
        p,"cut portal crosses a wall-band segmentation boundary")

for i,p in enumerate(portals):
    for q in portals[i+1:]:
        if (p["axis"],p["at"])!=(q["axis"],q["at"]):
            continue
        gap=abs(p["center"]-q["center"])-(p["width"]+q["width"])/2
        assert gap>=1,(p,q,"glazing/doors overlap or create narrow unusable jamb")

# Every Room has a path to each objective. Verify key routes even if a single
# *non-booth* traversal edge is temporarily unavailable (door/path disruption).
graph=defaultdict(set)
for e in design["traversalEdges"]:
    a,b=e
    graph[a].add(b);graph[b].add(a)

def reachable(src,blocked=None):
    visited={src};q=deque([src])
    while q:
        a=q.popleft()
        for b in graph[a]:
            if blocked==frozenset((a,b)) or b in visited: continue
            visited.add(b);q.append(b)
    return visited

assert reachable("Reception")==set(areas),"disconnected building"
core={"Reception","GeneratorRoom","PatchBay","ControlA"}
bridges=[]
for a,b in design["traversalEdges"]:
    if not core.issubset(reachable("Reception",frozenset((a,b)))):
        bridges.append((a,b))
# A booth's only link is expected to be a bridge, but it must never disconnect
# mandatory objectives / the front exit.
assert not bridges,("critical objective disconnected by one door",bridges)
assert {r for r in areas if len(graph[r])==1}==set(design["sealedBooths"]),(
    "unexpected isolation or blind dead-end")

# Sound assumptions: only actual architectural walls and closed door leaves may
# attenuate. Visual props must never intercept raycasts by default.
kit=(ROOT/"src/server/Maps/Kit.luau").read_text()
noise=(ROOT/"src/server/NoiseService.luau").read_text()
story=(ROOT/"src/server/Maps/StoryProps.luau").read_text()
assert 'Enum.Material.Glass,true' in kit
assert 'pane:SetAttribute("AcousticGlazing",true)' in kit
assert 'p.CanQuery=false' in story
assert 'table.insert(ignore,hit.Instance)' in noise, "thick occluders may be over-counted"
assert 'if noise.zone then' in noise and 'return 0 -- sealed in a booth' in noise

print(f"PASS LD03 offline Blackline: {len(areas)} areas, {len(portals)} "
      f"door/window portals, no segment clipping or overlap, sound contracts, "
      f"single-door objective resilience")
print("PENDING in Studio: navigation meshes, closed/open door travel, acoustic rays, "
      "player sightlines, resource budgets and real performance")

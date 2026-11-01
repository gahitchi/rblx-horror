#!/usr/bin/env python3
"""Validate *proposed* Blackline experience topology, not constructed Roblox rooms.

The design graph is planning evidence, NOT an assertion that existing runtime
maps already use this topology. Runtime map geometry has its own validator.
"""
from __future__ import annotations
import json
from collections import deque, defaultdict
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
PATH=ROOT/"docs/design/blackline_graph.json"


def reach(start, graph, blocked=None):
    seen={start}
    q=deque([start])
    while q:
        current=q.popleft()
        for dest in graph[current]:
            if blocked and frozenset((current,dest)) in blocked:
                continue
            if dest not in seen:
                seen.add(dest)
                q.append(dest)
    return seen


def shortest_edges(start, finish, graph, blocked=None):
    q=deque([start])
    previous={start:None}
    while q:
        a=q.popleft()
        if a==finish:
            break
        for b in graph[a]:
            if blocked and frozenset((a,b)) in blocked:
                continue
            if b not in previous:
                previous[b]=a
                q.append(b)
    assert finish in previous,(start,finish,"not connected")
    current=finish
    edges=set()
    while previous[current] is not None:
        parent=previous[current]
        edges.add(frozenset((parent,current)))
        current=parent
    return edges


def validate():
    data=json.loads(PATH.read_text())
    assert data["status"]=="RUNTIME_WHITEBOX_UNQUALIFIED","never claim visual/playtest qualification from source checks"
    assert data["mapId"]=="studio"
    rooms=data["rooms"]
    ids=[item["id"] for item in rooms]
    assert len(ids)==len(set(ids))>=15,"room IDs must be distinct and deliberately scheduled"
    ids=set(ids)
    assert {"public","circulation","production","technical","restricted","isolation"}.issubset(
        {item["sector"] for item in rooms}),"missing required architecture functions"
    graph=defaultdict(set)
    edges=set()
    for a,b in data["traversalEdges"]:
        assert a in ids and b in ids and a!=b,(a,b,"invalid adjacency")
        edge=frozenset((a,b))
        assert edge not in edges,("duplicate traversal edge",a,b)
        edges.add(edge)
        graph[a].add(b)
        graph[b].add(a)
    assert len(reach(data["objectives"]["spawn"],graph))==len(ids),"disconnected building"
    cycles=len(edges)-len(ids)+1
    assert cycles>=data["requestedConstraints"]["requiredCyclomaticLoops"],"not enough designed route loops"
    for item in ("spawn","exit","generator","fuseBox","tape","monsterStartCandidate"):
        assert data["objectives"][item] in ids,("unknown objective area",item)
    assert data["objectives"]["spawn"]==data["objectives"]["exit"],"return-to-familiar-entry premise"
    for b in data["sealedBooths"]:
        assert b in ids and len(graph[b])==1,(b,"booth must have one entrance and escape cost")
    for a,b in data["requestedConstraints"]["requiredAlternativeRoutes"]:
        first=shortest_edges(a,b,graph)
        assert b in reach(a,graph,first),(a,b,"no edge-independent alternative route")
    for a,b in data["visualOnlySightlines"]:
        assert a in ids and b in ids,(a,b,"unknown sightline endpoint")
    bounds={r["id"]:r["bounds"] for r in rooms}
    for a,b in data["visualOnlySightlines"]:
        one,two=bounds[a],bounds[b]
        xoverlap=min(one["x2"],two["x2"])-max(one["x1"],two["x1"])
        zoverlap=min(one["z2"],two["z2"])-max(one["z1"],two["z1"])
        assert ((one["z2"]==two["z1"] or two["z2"]==one["z1"]) and xoverlap>=23) or (
            (one["x2"]==two["x1"] or two["x2"]==one["x1"]) and zoverlap>=23), (
            a,b,"observation pane must join real neighboring rooms")
    fuses=data["curatedFuseCandidateAreas"]
    assert len(fuses)==len(set(fuses))>=10
    assert set(fuses).issubset(ids)
    assert len({item["sector"] for item in rooms if item["id"] in fuses})>=3,(
        "fuse candidates must have a meaningful facility-wide distribution")
    assert data["requestedConstraints"]["minAgentOpeningWidthStuds"]>=6
    assert data["requestedConstraints"]["minOpeningHeightStuds"]>=9
    assert data["requestedConstraints"]["preferredMainClearanceStuds"]>=8
    assert len(data["planGates"])>=7 and "geometry_whitebox" in data["planGates"]
    assert len(data["traversalPortals"])==len(edges)
    # The design document must reflect the implementation exactly, not drift
    # back into a beautiful but misleading conceptual network drawing.
    authored=(ROOT/"src/server/Maps/BlacklineLayout.luau").read_text()
    links=authored.split("local links={",1)[1].split("    return {",1)[0]
    for item in rooms:
        b=item["bounds"]
        needle=(
            f'{{name="{item["id"]}",role='
        )
        assert needle in authored,("missing authored room",item["id"])
        for field in ("x1","x2","z1","z2","height"):
            assert isinstance(b[field],int)
        exact=",".join(f"{field}={b[field]}" for field in ("x1","x2","z1","z2","height"))
        assert exact in authored,(item["id"],"geometry drift",exact)
    for item in data["traversalPortals"]:
        a,b,kind=item["a"],item["b"],item["kind"]
        literal='{"'+a+'","'+b+'"'+(',"'+kind+'"' if kind!="normal" else '')+'}'
        assert literal in links,("runtime portal differs from plan",a,b,kind)
    assert len(data["traversalPortals"])==len(data["traversalEdges"])
    print(f"PASS authored Blackline design: {len(ids)} purposeful Areas, {len(edges)} edges, "
          f"{cycles} loops, two sealed dead ends, independent objective approaches; "
          "Studio performance and navigation still unqualified")



if __name__=="__main__":
    validate()

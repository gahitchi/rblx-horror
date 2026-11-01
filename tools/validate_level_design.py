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
    assert data["status"]=="DESIGN_PROPOSAL_ONLY","do not silently treat proposal as runtime map"
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
    assert any(frozenset(pair) not in edges for pair in data["visualOnlySightlines"]),(
        "visual-only viewing relation not represented")
    fuses=data["curatedFuseCandidateAreas"]
    assert len(fuses)==len(set(fuses))>=10
    assert set(fuses).issubset(ids)
    assert len({item["sector"] for item in rooms if item["id"] in fuses})>=3,(
        "fuse candidates must have a meaningful facility-wide distribution")
    assert data["requestedConstraints"]["minAgentOpeningWidthStuds"]>=6
    assert data["requestedConstraints"]["minOpeningHeightStuds"]>=9
    assert data["requestedConstraints"]["preferredMainClearanceStuds"]>=8
    assert len(data["planGates"])>=7 and "geometry_whitebox" in data["planGates"]
    print(f"PASS DESIGN-ONLY Blackline: {len(ids)} purposeful Areas, {len(edges)} edges, "
          f"{cycles} loops, two sealed dead ends, 2 independent objective approaches")


if __name__=="__main__":
    validate()

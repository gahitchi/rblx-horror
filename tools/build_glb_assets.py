#!/usr/bin/env python3
"""Build import-ready glTF binary hero models for Roblox Studio.

Dependencies: numpy, pillow, trimesh, pygltflib (optional trimesh export backend).
Every model is self-contained. Imported assets must still be uploaded by their
Roblox experience owner; this script never invents Roblox MeshIds.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import math
import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

ROOT = Path(__file__).resolve().parent.parent
ORIGINALS = {
    "MixingConsole": "console-master.obj",
    "BroadcastMicrophone": "broadcast-microphone.obj",
    "FoundryBell": "foundry-bell.obj",
    "CassetteRecorder": "cassette-recorder.obj",
    "EngineerHeadset": "engineer-headset.obj",
}
COLORS = {
    "steel": (0.28, 0.31, 0.33, 1),
    "dark": (0.10, 0.12, 0.13, 1),
    "rubber": (0.045, 0.055, 0.055, 1),
    "oxide": (0.25, 0.19, 0.15, 1),
    "bronze": (0.53, 0.31, 0.16, 1),
    "glass": (0.08, 0.20, 0.19, 1),
    "label": (0.67, 0.60, 0.44, 1),
    "red": (0.55, 0.07, 0.04, 1),
}
MATERIALS = {
    "steel": (0.82, 0.42), "dark": (0.62, 0.53),
    "rubber": (0.0, 0.93), "oxide": (0.48, 0.77),
    "bronze": (0.78, 0.37), "glass": (0.0, 0.20),
    "label": (0.02, 0.62), "red": (0.08, 0.40),
}


def pbr(name: str) -> PBRMaterial:
    metal, rough = MATERIALS[name]
    factor = (np.array(COLORS[name]) * 255).round().astype("uint8")
    return PBRMaterial(name=name, baseColorFactor=factor,
                       metallicFactor=metal, roughnessFactor=rough,
                       doubleSided=False)


class Model:
    """Combines repeated primitives by material for fewer imported render meshes."""
    def __init__(self):
        self.parts: dict[str, list[trimesh.Trimesh]] = {k: [] for k in COLORS}

    def add(self, mesh: trimesh.Trimesh, mat: str):
        mesh.remove_unreferenced_vertices()
        self.parts[mat].append(mesh)

    def box(self, center, extents, mat):
        mesh = trimesh.creation.box(extents=extents)
        mesh.apply_translation(center)
        self.add(mesh, mat)

    def cylinder(self, pos, radius, height, mat, sections=24, direction="y"):
        mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
        if direction == "y":
            mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
        elif direction == "x":
            mesh.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [0, 1, 0]))
        mesh.apply_translation(pos)
        self.add(mesh, mat)

    def tube_between(self, a, b, r, mat, sections=12):
        start, end = np.asarray(a, dtype=float), np.asarray(b, dtype=float)
        delta = end - start
        mesh = trimesh.creation.cylinder(radius=r, height=np.linalg.norm(delta), sections=sections)
        mesh.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], delta))
        mesh.apply_translation((start+end)/2)
        self.add(mesh, mat)

    def finish(self) -> trimesh.Scene:
        scene = trimesh.Scene()
        for name, meshes in self.parts.items():
            if not meshes:
                continue
            mesh = trimesh.util.concatenate(meshes)
            mesh.visual = trimesh.visual.TextureVisuals(material=pbr(name))
            scene.add_geometry(mesh, node_name="PBR_" + name, geom_name="PBR_" + name)
        return scene


def walkie() -> trimesh.Scene:
    m = Model()
    m.box((0, 0.43, 0), (0.46, .86, .24), "dark")
    m.box((0, .48, -.135), (.40, .62, .045), "steel")
    m.box((0, .66, -.17), (.28, .13, .024), "glass")
    m.box((0, .30, -.17), (.31, .29, .022), "rubber")
    for i in range(6):
        m.box((0,.20+i*.041,-.186),(.29,.012,.02),"steel")
    for i in range(5):
        m.box((-.10+i*.049,.089,-.162),(.025,.032,.025),"label")
    m.cylinder((.15, 1.01, .012),.043,.72,"rubber",16)
    m.cylinder((.15, .87, .012),.075,.11,"steel",16)
    m.cylinder((-.14,.89,.012),.075,.12,"dark",20)
    m.box((-.263,.54,.008),(.078,.27,.11),"red")
    m.box((0,.44,.174),(.18,.52,.14),"steel")
    for i in range(7):
        m.box((-.223,.16+i*.07,.0),(.022,.015,.22),"rubber")
    return m.finish()


def rack() -> trimesh.Scene:
    m = Model()
    m.box((0,3.7,0), (3.35,7.4,2), "dark")
    for x in [-1.62,1.62]:
        m.box((x,3.7,-1.06),(.18,7.42,.18),"steel")
    for i in range(13):
        y=.65+i*.5
        m.box((0,y,-1.06),(3.15,.39,.10),"steel")
        m.box((-.67,y,-1.123),(1.3,.26,.021),"dark")
        for j in range(4):
            x=-1.29+j*.37
            m.cylinder((x,y,-1.145),.055,.045,"bronze",12,"z")
        for j in range(3):
            x=.48+j*.30
            m.box((x,y,-1.13),(.18,.09,.024), "glass" if i%2 else "red")
    for y in [.38,7.04]:
        for x in [-1.55,1.55]:
            m.cylinder((x,y,-1.18),.065,.055,"dark",12,"z")
    return m.finish()


def monitor() -> trimesh.Scene:
    m=Model()
    m.box((0,1.18,0),(2.65,2.36,1.82),"dark")
    m.box((0,1.18,-.94),(2.34,2.12,.10),"steel")
    for radius,y in [(0.76,1.01),(0.27,1.91)]:
        m.cylinder((0,y,-1.015),radius,.08,"rubber",48,"z")
        m.cylinder((0,y,-1.09),radius*.59,.08,"steel",48,"z")
    m.box((0,.24,.94),(1.52,.15,.07),"label")
    for i in range(4):
        m.cylinder((-.5+i*.33,.23,-1.04),.055,.04,"bronze",12,"z")
    return m.finish()


def reel() -> trimesh.Scene:
    m=Model()
    for x in [-.045,.045]:
        m.cylinder((x,0,0),1.02,.035,"steel",48,"x")
    m.cylinder((0,0,0),.32,.15,"dark",32,"x")
    m.cylinder((0,0,0),.11,.18,"bronze",28,"x")
    for i in range(5):
        t=2*math.pi*i/5
        m.tube_between((-.09,.25*math.sin(t),.25*math.cos(t)),
                       (.09,.85*math.sin(t),.85*math.cos(t)),.048,"steel")
    return m.finish()


def export(path: Path, scene: trimesh.Scene):
    path.write_bytes(scene.export(file_type="glb"))
    load=trimesh.load(path,force="scene",process=False)
    assert len(load.geometry)>0, "No geometry in output"
    vertices=sum(len(mesh.vertices) for mesh in load.geometry.values())
    assert vertices >= 100, "Unexpectedly empty output"
    print(f"{path.name}: {vertices:,} vertices, {len(load.geometry)} material meshes, {path.stat().st_size:,} bytes")


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,default=Path("build/roblox-glb"))
    args=parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    for name,filename in ORIGINALS.items():
        src=ROOT/"assets"/"meshes"/filename
        scene=trimesh.load(src,force="scene",process=False,skip_materials=False)
        assert len(scene.geometry)>0,(filename,"empty input")
        # Keep original UVs/material components; Studio may add SurfaceAppearance later.
        export(args.out/(name+".glb"),scene)
    for name,builder in {
        "WalkieTalkie":walkie,"AnalogRack":rack,
        "NearfieldMonitor":monitor,"TapeReel":reel,
    }.items():
        export(args.out/(name+".glb"),builder())

if __name__=="__main__":
    main()

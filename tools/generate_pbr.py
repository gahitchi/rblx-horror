#!/usr/bin/env python3
"""Generate original seamless starter PBR texture sets for Roblox Studio.

Usage:
    python -m pip install pillow numpy
    python tools/generate_pbr.py --size 1024 --out assets/generated-textures

Outputs four material families x ColorMap, NormalMap, RoughnessMap and MetalnessMap.
Procedural textures are production *starter sources*; a scanned/photographed high-detail
PBR pass should supersede them for close-up hero assets.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

def smooth_noise(size: int, cells: int, rng: np.random.Generator) -> np.ndarray:
    tile = rng.random((cells, cells))
    grid = np.pad(tile, ((0, 1), (0, 1)), mode="wrap")
    image = Image.fromarray((grid * 255).astype("uint8"), mode="L")
    # +1 endpoints enforce periodicity; use a bicubic resize to soften low-frequency wear.
    return np.asarray(image.resize((size + 1, size + 1), Image.Resampling.BICUBIC), dtype="float32")[:-1,:-1] / 255

def make_material(name: str, size: int, rng: np.random.Generator):
    y, x = np.indices((size, size), dtype="float32")
    long = smooth_noise(size, 8, rng)
    medium = smooth_noise(size, 24, rng)
    fine = smooth_noise(size, 64, rng)
    noise = 0.50 * long + 0.32 * medium + 0.18 * fine
    if name == "aged_oak":
        grain = np.sin((x * 2*np.pi / 19) + np.sin(y * 2*np.pi / 86) + long * 4)
        grain2 = np.sin((x * 2*np.pi / 7.5) + medium * 2.6)
        height = 0.44 + 0.27 * noise + 0.14 * grain + 0.05 * grain2
        offset = 22 * grain + 36 * (noise - 0.5)
        color = np.stack([111 + offset, 71 + offset * .66, 49 + offset * .45], axis=-1)
        roughness = np.clip(.72 + fine * .16 + medium * .08, 0, 1)
        metalness = np.zeros_like(roughness)
    elif name == "old_plaster":
        pores = (fine < .20).astype("float32") * -16
        height = .28 + .42 * noise + .20 * fine
        offset = (noise-.5) * 39 + pores
        color = np.stack([103+offset, 99+offset*.93, 92+offset*.8], axis=-1)
        roughness = np.clip(.78 + .16 * fine, 0, 1)
        metalness = np.zeros_like(roughness)
    elif name == "oxidized_steel":
        corrosion = np.clip(medium * 2.2 - 1.04, 0, 1)
        streak = np.cos(y * 2*np.pi / 3.8)*.09
        height = .30 + .36 * noise + .25 * corrosion + streak
        color = np.stack([65+76*corrosion+12*(noise-.5),
                          70+18*corrosion+9*(noise-.5),
                          73-15*corrosion+10*(noise-.5)], axis=-1)
        roughness = np.clip(.43 + .44 * corrosion + .13 * fine, 0, 1)
        metalness = np.clip(1-corrosion*.85,0,1)
    else:
        weave = np.sin(x * 2*np.pi / 4.2)*np.cos(y * 2*np.pi / 4.2)
        height = .33 + .18 * noise + .20 * weave
        offset = (noise-.5)*20+weave*14
        color = np.stack([43+offset,48+offset,51+offset*.9],axis=-1)
        roughness = np.clip(.88 + .1*fine,0,1)
        metalness = np.zeros_like(roughness)
    dy, dx = np.gradient(height)
    strength = 13
    nx, ny, nz = -dx*strength, -dy*strength, np.ones_like(dx)
    l = np.sqrt(nx*nx+ny*ny+nz*nz)
    normal = np.stack([.5 + .5*nx/l, .5 + .5*ny/l, .5 + .5*nz/l],axis=-1)
    return (color, normal*255,roughness*255,metalness*255)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--size",type=int,default=1024)
    parser.add_argument("--out",type=Path,default=Path("assets/generated-textures"))
    args=parser.parse_args()
    if args.size<128 or args.size>4096 or args.size&(args.size-1):
        parser.error("--size must be power of two between 128 and 4096")
    args.out.mkdir(parents=True,exist_ok=True)
    for j,name in enumerate(("aged_oak","old_plaster","oxidized_steel","acoustic_weave")):
        color,normal,rough,metal=make_material(name,args.size,np.random.default_rng(7137+j))
        for suffix,arr in (("ColorMap",color),("NormalMap",normal),("RoughnessMap",rough),("MetalnessMap",metal)):
            data=np.clip(arr,0,255).astype("uint8")
            Image.fromarray(data,mode="RGB" if data.ndim==3 else "L").save(args.out/f"{name}_{suffix}.png")
        print(f"{name}: 4 maps")
if __name__=="__main__":
    main()

# Dead Air — Rebuilt playable maps and original assets

## November 1 implementation update

Blackline `studio` now uses a purpose-built 19-Area, 26-connection
nonuniform architectural plan in `src/server/Maps/BlacklineLayout.luau`.
Its 24-stud-high LiveHall, distinct service/production loops, higher-detail
room storytelling and four **new optional GLB models** are documented in
[Blackline LD-02](../design/BLACKLINE_LD02_IMPLEMENTATION.md).
Radio and Foundry retain the earlier 20-room grid designs. The new Blackline
runtime source passes automated checks, **not yet Studio navigation or image acceptance**.

## Current implementation

The former recording-studio greybox is no longer the active geometry. The runtime creates one of three **new original environments** using `src/server/Maps/Layouts.luau` and `src/server/Maps/Kit.luau`.

| Map ID | Map | Envelope (studs) | Main identity | Distinctive spaces |
| --- | --- | --- | --- | --- |
| `studio` | Blackline Recording Complex | 200 × 226 | Authored non-grid recording complex | Control A/B, drum room, tracking stage, isolation suites, vault, loading dock |
| `radio` | Wavelength Broadcast Station | 128 × 160 | Institutional, cold blue-green broadcaster | Newsroom, talk studio, edit bay, master control, transmitter vault |
| `foundry` | Ashbell Industrial Foundry | 160 × 200 | Industrial foundry and bellworks | Casting and pouring bays, crane gallery, mold shop, furnace annex, bell-testing room |

Radio and Foundry use 20 named contract Areas; Blackline now uses 19, each with an axis-aligned Bounds volume and three spaced patrol Spots. Each supports multiple circulation circuits plus isolated risky rooms, with marker-based MonsterSpawn and PlayerSpawn. Three fuses are chosen from a larger map-specific set of potential positions. Every area has a speaker marker and its own generator-switched industrial pendant.

The graphic differences come from **distinctive source geometry**: acoustic treatment and consoles in the recording complex, radio electronics and transmission gear in the broadcast station, and custom machinery, bell forms and piping in the foundry. The structural models provide independent floors, ceilings, walls, material palettes and door leaves; they do not borrow old-world coordinates.

## Source architecture

- `src/server/MapBuilder.luau`: compact map dispatcher and API compatibility layer. `MapBuilder.build(mapId)` returns a contract-conformant Model parented to `Workspace`.
- `src/server/Maps/Layouts.luau`: full room names, dimensions, adjacency graph, roles, objective locations and themed colours.
- `src/server/Maps/Kit.luau`: builds geometry, wall segments, 8-stud/10-stud portals, doors and their handle welds, markers, booths, Area Bounds, lamps and signage.
- `src/server/Maps/AssetLibrary.luau`: shared modular visual assets, distinct per map, with no sound or physical collision from decorative detail.
- `src/server/Maps/Lobby.luau`: new atmospheric waiting room.
- `src/server/VisualFidelity.luau`: Realistic lighting and intentionally controlled post-processing for generated maps.
- `src/shared/Config.luau`: three map IDs now appear in replay votes and the hub.

A custom Studio-authored map may still be loaded from `Workspace.Map` or `ServerStorage.Maps.<id>` with the same contract. Map-only geometry intentionally stays out of Claude's sound/AI/service scripts. The `src/server/ArtBuilder.luau` greybox-dependent module has been retired and removed.

## Original mesh source files

The following source geometry lives under `assets/meshes/`. These are **actual OBJ models**, not automatically usable Roblox MeshPart IDs.

| File | Source content | Import target |
| --- | --- | --- |
| `console-master.obj` | Rack console, sixteen channel strips, faders and meter bridge | Studio mastering/control rooms |
| `broadcast-microphone.obj` | Vintage capsule, shock mounting, stem and weighted base | Studio live room / radio studio |
| `foundry-bell.obj` | Lathe-generated casting, relief rings, shoulder pin and clapper | Bell-testing room |
| `cassette-recorder.obj` | Portable recorder chassis, reels, buttons, grille and handle | Tape-decoy visual mesh |
| `engineer-headset.obj` | Headband arc, headset earcups, boom microphone | Engineer silhouette asset |
| `dead-air-materials.mtl` | Original basic diffuse/specular colour definitions | Blender import reference |

**Import workflow:** download or clone the mesh sources; open with Blender; check face normals, smoothing, UVs and physical scale; produce any necessary LODs; assign and bake licensed high-resolution PBR maps; export as FBX/glTF; import via Roblox Studio's 3D Importer. Uploading is a required user-side Studio action. Replace generated `Part` shells with `MeshPart` visuals only after the Roblox asset IDs are known. Keep door/objective collision and monster anchors unchanged.

A five-file source mesh pack is not a finished AAA asset library: the imported models still need textured materials, baked normal detail, calibrated roughness and Studio lighting tests. It is **incorrect to claim these source files already render as imported meshes**.

## Original PBR texture source pack

`tools/generate_pbr.py` deterministically produces **16 PNG maps** at configurable resolution for four families: aged oak, old plaster, oxidized steel and acoustic weave. Each includes colour, normal, roughness and metalness maps. The script is the editable source of truth; textures are **not yet uploaded as Roblox asset IDs**, so they are not currently displayed on live MeshParts.

The `Source Asset Export` GitHub workflow runs the generator at 1024×1024 and bundles its outputs with the five OBJ meshes into `dead-air-original-asset-pack`. A confirmed successful export is available under [Source Asset Export run #41250991694](https://github.com/gahitchi/rblx-horror/actions/runs/41250991694) (GitHub Actions artifact retention: 30 days). Regenerate with:

```bash
python -m pip install pillow numpy
python tools/generate_pbr.py --size 1024 --out assets/generated-textures
```

These are procedural starter materials, **not scanned photoreal textures**. Replace high-visibility surfaces with measured/photogrammetry PBR data during the final art-quality pass, respecting source licenses and Roblox Studio image import requirements.

## Contract and gameplay invariants

- `Workspace.Map` must have `Areas`, `Markers`, `Doors`, `Objectives`, `PowerLights`, and optional `Booths`.
- Every opening in the generated map is 8–14 studs wide; the exterior front exit is 10 studs. Moving door leaves are 0.2 studs narrower than their openings.
- Every floor is solid, every room has a ceiling at least 13 studs high and the main layout uses no jump-only pathing or stairs.
- Graphics-only parts set `CanQuery=false` and `CanCollide=false`, so only architectural walls and meaningful obstacles muffle sound.
- Booths are cul-de-sac rooms with precisely one `Kind="booth"` door and one acoustical-zone marker.
- Each map has exactly one `Kind="front"` door, a generator, a fuse box, a tape deck and an exit zone. Player spawn faces into the building.
- The generated environments are intended for **first playable qualification**. Do not assume Monster/Navigator routes work until verified in Studio.

## Required qualification

1. `rokit install`, `rojo build -o debug.rbxl`, `selene src/server/Maps` and Rojo sync.
2. In Studio Play, verify no `[Map] ERROR` or `[Map] warning` from each map; turn `Config.DEBUG_AI` on.
3. Test PlayerSpawn, FuseSpot and MonsterSpawn floor-snapping and pathfinding from **every room to the main corridor**.
4. Check booth doors, sound isolation, front-door escape and the complete fuse/generator/tape sequence.
5. Check all hub/replay map vote values choose the corresponding environment (also in reserved live servers).
6. Profile graphics at 1080p on high quality and medium quality. Adjust lighting and heavy static models based on MicroProfiler evidence.
7. Import the original meshes and realistic PBR textures, then compare in-game before/after screenshots; do not merge as fully finished graphics until the correct assets have been uploaded and approved.

**Status:** three new procedural gameplay environments, a rebuilt hub, five OBJ hero source models and a reproducible 16-texture PBR source pack authored. Rojo serialization, lint and source-asset topology checks have passed on CI; **no Roblox Studio client rendering, navigation or frame-rate data has been collected in this authoring session**.

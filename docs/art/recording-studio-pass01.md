# Dead Air — Recording Studio Art Pass 01

**Branch:** `chatgpt/studio-art-pass`  
**Target version:** `0.3.0` (current upstream gameplay milestone)  
**Visual owner:** ChatGPT (map and environment art)  
**Gameplay owner:** Claude (objectives, AI, rounds, interactive systems)

## Status

First native-Part environment pass and a 12-Area navigation expansion committed; **Studio runtime verification is pending**. This is not a finished production art pass. Playable geometry is created by `MapBuilder` and detailed after map-contract loading by `ArtBuilder.build(layout)` when the game starts.

The new environment-art source is `src/server/ArtBuilder.luau`; `src/server/Main.server.luau` invokes it immediately after `local layout = loaded`. The active map is `layout.map`, read from `MapContract`, not a model named `Studio`.

## Art identity

A grounded, abandoned 1980s–2000s recording facility: aged plaster, hardwood, aged steel, dense acoustic treatments, professional recording equipment, dusty media archives, and restrained emergency lighting. A professional workplace gone silent rather than a fantasy dungeon.

No marketplace assets, paid models, or uploads are required. This pass deliberately uses Roblox primitives to make the visuals usable immediately. Later passes can replace these silhouettes with carefully authored meshes and textures without disrupting their gameplay anchors.

## Completed visual areas

| Area | Art work | Gameplay-critical element preserved |
| --- | --- | --- |
| Reception | Branding, reception furniture, sofa cushions, document signage, floor seams | Entrance spawn, front door, exit zone |
| Control rooms A & B | Multi-channel mixing desks, monitors, absorbers, identification | Tape deck, doors, original desk collision |
| Live floor | Microphone stands, drum details, rigging, acoustic baffles | Large traversal routes, Engineer wander nodes |
| Booths 1–3 | Acoustic tiles, interior carpets, isolation markings, microphones | Sealed-noise zones and swinging booth doors |
| Main/cross corridors | Wayfinding, cable trays, trim | AI navigation, objective corridors |
| Archive | Media cases, labels, wall details | Original shelving collision and fuse spawn locations |
| Break room | Table dressing, wall cabinets, staff notices | Existing furniture collision and entrance |
| Generator level | Generator mechanical accents, pipes, fuse-panel details, warnings | Generator/fuse box prompts, stair ramp |
| Lighting | Seven powered fixtures and subtle colour grade | Existing `ObjectiveService.setPower()` lifecycle |

## Hard integration constraints

1. Follow `docs/MAP_CONTRACT.md`: gameplay objects belong in `Workspace.Map/Markers`, `Areas`, `Doors`, `Booths`, `Objectives`, and `PowerLights`. The greybox built by `MapBuilder` is the reference implementation; `MapContract` owns the loaded layout.
2. Keep `ArtBuilder` strictly responsible for presentation. Its details use `CanCollide=false`, `CanQuery=false`, and `CanTouch=false`.
3. Do not attach static art directly to swinging doors: that would leave the decoration behind when `DoorService` tweens their CFrames.
4. Treat new powered lights as part of `layout.powerLights` and `layout.powerLamps`. `ObjectiveService` already turns them on and off for each round.
5. Do not replace or move `layout.generator`, `layout.fuseBox`, or `layout.tapeDeck`; ProximityPrompts are attached to those original Parts.
6. `src/server/MapBuilder.luau` is now extended with twelve contract Areas; keep `src/server/MapContract.luau` owned by Claude and unchanged in this pass. Future transparent glass partitions or wall openings need an explicit AI/noise-routing review with Claude.
7. This visual pass still uses the greybox's fixed coordinates. For a newly authored map, adapt the room-specific art positions to that map instead of assuming the same room coordinates. Its gameplay structure must follow the map contract.

## How to test in Roblox Studio

```sh
git fetch origin
git switch chatgpt/studio-art-pass
rokit install
rojo serve
```

Connect Rojo in Roblox Studio, click **Play**, and check the Output window for:

```
[Dead Air] recording-studio ArtPass01: ... decorative parts
[Dead Air] server running, v0.3.0
```

**Test checklist**

- [ ] Lobby launches and round countdown transitions to Playing.
- [ ] Reception branding, consoles, microphones, booth foam, archive tapes and basement detailing appear.
- [ ] Player can enter every room and all three booths; doors swing without detached decoration.
- [ ] Generator prompt still responds and turns on all emergency lighting.
- [ ] Every fuse pickup, fuse-box insertion, and emergency-tape interaction still works.
- [ ] Engineer can traverse corridors and doors; it still ignores noises sealed in a closed booth.
- [ ] Flashlight visibility is sufficient in the basement and archive.
- [ ] Two-player Studio test shows the same art and functioning shared state.
- [ ] Performance is acceptable on the target hardware.

The authoring environment here **cannot run Roblox Studio**, so these boxes must not be checked without real tests.

## Validation on a development machine

```sh
stylua --check src
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json src
rojo build -o build.rbxl
```

Do not merge the PR as playtested until the above commands and in-game checklist pass.

## Claude handoff

Compatible with the 0.2.0 layered Engineer AI and its widened doorways. The art pass requires no changes to monster, sound, objectives or rounds. When Claude changes the reference map layout, update `ArtBuilder`'s spatial coordinates, and review whether artwork obscures prompts or critical sightlines. Claude can safely keep working on `main` while the art branch is reviewed.

## Expansion and new model handoffs

- See `docs/art/STUDIO_EXPANSION.md` for chase loops, the lower level, and room-by-room traversal validation.
- `src/server/Monster/EngineerModel.luau` now defines a detailed procedural Engineer, with the original Humanoid settings, root part and two red earcup lights preserved.
- `src/server/ItemArt.luau` now returns detailed belt walkies and anchored tape decoys with their existing API contracts preserved.
- See `docs/art/SOUND_CATALOG.md` for all 16 current `Sounds.luau` entries, plus suggested Creator Store search terms.

## Follow-up art passes

The next pass should focus on transparent control-room windows with acoustically correct sound occlusion, textured material/mesh replacement, custom sounds/ambience, glass/door visual state, measured framerate, visibility tuning, and physically believable equipment silhouettes. The first pass is intentionally reversible and conservative on traversal.

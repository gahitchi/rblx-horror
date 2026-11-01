# Finish refinement acceptance — door panels, worktops and cabinet bases

**Branch:** `chatgpt/studio-art-pass`.
**Scope:** appearance-only changes within the three generated environments.
**Status:** source implementation and automated tests complete; **Studio visual qualification pending** because the tester's laptop is offline.

## User-reported problems

- Rectangular inner fields of doors looked unnatural with the current material.
- Worktable / reception-counter **lower rectangular body** looked artificial.
- Tabletop surfaces looked wrong: repetitive, strongly textured or overly reflective.

## Root causes addressed in code

### Door panels

The preceding revision made the door shell a stable, painted SmoothPlastic
collision leaf but left its small upper/lower decorative panels on the global
Wood / Metal / Fabric PBR variants. Those variants were authored for broad
environment surfaces and have incompatible roughness/normal frequency when
mapped to a narrow door field.

`FinishDetail.doorFields()` now creates **two-sided, layered pressed panels**:
dark shadow/reveal, matte field, narrow formed crossmembers and an unobtrusive
door identification blank. The broad silhouette stays readable at corridor
distances. All finishing pieces are welded by `Kit.doorLeaf` to the one
anchored gameplay leaf; hinges, opening time, prompts, and booth sound logic
are unchanged.

### Control desks and reception counters

The old fallback desk and reception countertop were rectangular wood or metal
Parts which inherited environment-wide aged oak or oxidized steel. The new
`FinishDetail.counter()` uses:

- one invisible `DeskPlinth` or `ReceptionCounter` collision hull;
- a painted cabinet facade, end returns and recessed toe plinth;
- clear structural joint lines and restrained access panel details;
- a low-sheen laminate/powder-coated worktop and narrow edge band;
- a simple rear cable channel for a control desk, not a decorative glowing stripe.

**Critical mesh integration correction:** the approved imported `MixingConsole`
GLB already contains the tabletop and upper cabinet. Its original source OBJ
extends from y=1.07 to y=4.13 studs. We now draw **only a short pedestal**
beneath the imported console through `FinishDetail.consoleMount()`. A second
large procedure-generated tabletop would overlap the imported mesh and cause
visual conflicts. When the GLB is absent, the procedural fallback builds the
entire purposeful worktop and meter/fader equipment.

### Authored asset protection

`PrefabLibrary` marks cloned imported MeshParts `DisablePBR=true` so approved
GLB surface art isn't replaced by the environment-wide MaterialVariant pass.
`PBRMaterials` also deliberately excludes any Part that owns a
`SurfaceAppearance`, as a second layer of protection.

All new finish detail uses `CanCollide=false`, `CanTouch=false`,
`CanQuery=false`, low-detail painted finishes and no extra runtime lights.
The invisible original collision proxies remain queryable for the audio and
navigation systems.

## Identity by map

| Map | Door-field treatment | Cabinet base | Worktop |
| --- | --- | --- | --- |
| Blackline studio | Muted charcoal / warm-gray pressed field | Dark studio cabinet, neutral painted support | Graphite warm laminate, subtle edge band |
| Wavelength radio | Slate gray-blue industrial painted field | Cold powder-coated console cabinet | Neutral electronics work surface |
| Ashbell foundry | Dry gray-brown pressed heat-aged panel | Heavier muted iron/painted support | Darker industrial bench finish |
| Acoustic booths | Dark felt-toned sound-seal fields | Not applicable | Not applicable |

The palette is deliberately low saturation, without broad repeated rust or
oak tiles on these **small** surfaces. Large structural walls and floors
continue to use the creator's six installed PBR MaterialVariants; no reupload
or replacement of the original 16 textures is required.

## Next Studio acceptance protocol (not run here)

**Preparation:** pull `chatgpt/studio-art-pass` into the Rojo-connected match
place. Preserve `ServerStorage.ArtLibrary` and `MaterialService`; reimporting
assets is not required. Capture screenshots of the same objects before/after
if an earlier place backup is available.

1. In Edit, verify no duplicate `UpperDoorInlay` / `LowerDoorInlay` art remains
   from an old static `Workspace.Map`. This pass affects code-generated maps;
   an authored persistent Map overrides `Kit.build()`.
2. In Play, inspect one door at 5, 15 and 30 studs, closed, opening and open.
   Inspect each side. Confirm the two fields read as purpose-built surfaces,
   don't float, shimmer or clip.
3. Inspect `ReceptionCounter` from the front, ends and above. Evaluate the base,
   edge band and worktop under flashlight and generator-powered light.
4. Visit `ControlA`. Confirm the imported `MixingConsole` and low pedestal
   do not overlap or flicker. If no GLB is installed, verify the full procedural
   fallback table instead.
5. Repeat relevant checks at Wavelength and Ashbell. Inspect acoustic-booth
   door materials and confirm booth doors are still functional.
6. Walk/sprint against cabinets and doors. Verify player and Engineer cannot
   pass through invisible collision hulls, but small visual pieces never snag.
7. Read Output for `[Map] ERROR`, PBR warnings, runtime errors and
   imported-prefab availability. `PBR: assigned N parts` may be **lower**
   than the earlier 1,809 because fewer details are eligible for PBR.
8. Compare at high and medium Roblox graphics quality. Look for stable silhouettes
   and no quality-dependent sparkling. If needed, profile actual frametimes.

## Code qualification performed

- All named surface-finish assets exist and are wired to generated maps.
- Visuals are explicit noncolliding, nonqueryable parts; gameplay hulls remain.
- Door leaf still uses the original `DoorService` interface.
- PBR updates exclude imported meshes, explicit finish detail and
  `SurfaceAppearance`-protected assets.
- Static map topology, audio system, objective services, monster logic and
  authored Studio mesh IDs are unchanged.
- Selene, Rojo builds for match and hub, topology/source checks and level-design
  **proposal** graph checks run in CI.

**Do not declare final visual acceptance before the screenshots and interaction
checks above.** The work is ready for that test, not retrospectively tested.

## Next development phase

The next phase is deliberate map architecture, documented at:

- `docs/design/BLACKLINE_LD00_BRIEF.md`: narrative, facility workflow, room
  program, audio risk, objectives, traversal loops, route gates, acceptance.
- `docs/design/blackline_graph.json`: machine-readable **proposal**, not live
  geometry; independently checked by `tools/validate_level_design.py`.

The existing 5x4 generated map is still the active baseline until the new
authored Blackline plan is reviewed, built and qualified. It should not be
presented as a finished, carefully designed level.

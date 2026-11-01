# Dead Air — Engineer articulation + Blackline flagship-room art, iteration 2

**Branch:** `chatgpt/studio-art-pass` (draft PR #1); main untouched.
**Status:** implementation, source checks and GLB export complete; actual Studio
rig/lighting/visual/animation acceptance pending. This is a significant
visual-prototype iteration, **not** final TTK-grade production art.

## The Engineer: actual joint motion rather than a single rigid figure

The original `EngineerBody.glb` was attached entirely to the monster's
HumanoidRootPart. It could translate and rotate but **could not swing its arms,
articulate its head or walk with its legs**. The fallback procedural Part
figure had the same rigid-assembly limitation.

The new source builds six additional, independently textured GLB segments:

| Imported model name | Joint parent | Source pivot |
| --- | --- | --- |
| `EngineerRigTorso` | HumanoidRootPart / `RigTorso` | Root origin |
| `EngineerRigHead` | `RigHead` | Head, ~3.70 studs above HRP |
| `EngineerRigArmLeft` | `RigArmLeft` | Left shoulder, (-1.38, 1.70, 0) |
| `EngineerRigArmRight` | `RigArmRight` | Right shoulder, (1.38, 1.70, 0) |
| `EngineerRigLegLeft` | `RigLegLeft` | Left hip, (-0.54, -1.43, 0) |
| `EngineerRigLegRight` | `RigLegRight` | Right hip, (0.54, -1.43, 0) |

The GLBs carry original image-mapped color, normal and packed
metallic/roughness materials. They are **rigid art segments**, not
high/low-poly retopologized, skin-weighted anatomy. Motor6Ds move the
segments as one articulated assembly, with smooth client-side blend
poses on `RunService.PreSimulation`.

**State-driven animation:** idle breathing; gait swinging under actual
velocity; distinct listening/looking posture; searching head scanning;
leaning forward in Hunt; reaching and hunching during windup/lunge.
A client joining midround also observes the rig after replication and
registers its joint controller.

**Safety:** the server-owned HumanoidRootPart remains the single
navigation/collision authority. The original AI, `MonsterService` states,
sounds, lunge range, Humanoid/hip height, network ownership and gameplay
collision remain unchanged. Both gameplay-controlled earcup PointLights
follow the new head joint without losing their reference in the monster
service's `glows` array.

**Fallback order:**

1. **All six** segmented mesh prefabs present in
   `ServerStorage.ArtLibrary` → `ArticulatedPrototype` (new visual rig).
2. If incomplete, but `EngineerBody` exists → `ImportedBodyPrototype`
   (the previous rigid full-body figure).
3. Otherwise → `ProceduralFallback` (original functional Parts).

No partial articulated build silently replaces the existing working monster.

## Four flagship Blackline areas, visual-only construction

A reusable `BlacklineHeroRooms.luau` adds custom first-person details to
**Reception**, **StaffGallery**, **ControlA** and **LiveHall**. Each room
receives details determined by realistic recording-facility function:

- **Reception:** structurally mounted suspended fixtures, physical floor
  expansion joints and restrained polished metal fasteners.
- **StaffGallery:** overhead exposed service cableways, retention brackets,
  circulation lane identifiers and functional utility lighting.
- **ControlA:** varied-depth acoustic diffuser cells and visible signal
  trunking, with a gap preserving the 8-stud doorway to DrumRoom;
  subdued overhead desk/task lights.
- **LiveHall:** ceiling-mounted tracking-grid luminaires, hangers and
  recessed floor recording-bay markers, in addition to prior baffles.

All new scene geometry is **anchored, noncolliding, nonqueryable, without
high-frequency world PBR tiling** and marked
`ArtPass="BlacklineHero01"`. Nothing moves an objective trigger or
interferes with the Engineer's physical path. The practical fixtures'
`SurfaceLight` objects are initially disabled and registered under the
existing `PowerLights` contract, so they follow the actual generator
power phase. The user-visible quality and light placement still require
first-person inspection.

## Reproducible asset pipeline and source qualification

The optional GLB pack now includes **25 models** (the original 19 plus
six segmented Engineer parts). The latest exported pack and its generated
`art-quality-report.json` are available from the
[Source Asset Export workflow](https://github.com/gahitchi/rblx-horror/actions/runs/41297996570).
The audit recorded **51,400 triangles** and **234 embedded image-map
instances** across 25 source meshes. These statistics measure the asset
pack, not visual realism.

`tools/validate_hero_pass.py` checks that the new art module is wired to
the correct rooms; all cosmetics remain non-solid; power fixtures are
generator-linked; doorway clearance is maintained; the six rig segments
are exported and importable; the client animation touches only Motor6D
Transforms, never the server's actual movement root. CI also validates
character safety, level navigation, Rojo serialization and Selene linting.

The art quality audit now emits GLB source-space min/max bounds to help
detect changes made by Roblox Studio's 3D Importer to mesh pivots.

## Studio import (only when user laptop is available)

1. Pull the branch into the Rojo-connected match place and sync code.
2. Download the newest 25-model asset pack from the Source Asset Export run.
   The original nine and the earlier optional assets can stay installed.
3. Import **only** these six GLBs from `roblox-glb/` through Studio 3D Importer:
   `EngineerRigTorso`, `EngineerRigHead`, `EngineerRigArmLeft`,
   `EngineerRigArmRight`, `EngineerRigLegLeft`, `EngineerRigLegRight`.
4. Preserve precise imported names and source pivots; do **not** align each
   piece by its visual bounding-box center. The arm and leg geometry extends
   below the local shoulder/hip pivot. Compare source bounds in
   `art-quality-report.json` if an import is offset.
5. Select the six imported roots and execute
   `tools/studio/InstallImportedModels.luau` in the Studio Command Bar.
   Alternatively, place the six exact-named Model/MeshPart roots manually
   into `ServerStorage.ArtLibrary`. Save the Studio place.
6. Press F5, play until the Engineer spawns. In the **Server** Command Bar,
   run the entire `tools/studio/InspectCharacterAndHeroArt.luau` script.
   Check output for `ArticulatedPrototype`, six joints, zero solid
   cosmetic parts, and installed hero-space art.
7. Inspect the Engineer from front, rear and side in Roam, Listen, Search,
   Hunt and Lunge. Verify foot sliding, arm intersections, earcup flare,
   skull pivot, shoulder and hip alignment, and pose transitions. Repeat
   across different client graphics levels.
8. Re-run `tools/studio/QualifyBlackline.luau` for physical paths and
   acoustic/door checks. Capture 5/15/30-stud first-person views from
   the flagship rooms, with generator off and on.
9. Record 1080p FPS, frame-time p50/p95, memory and ArtLibrary size on
   the target laptop, then a lower-detail/client quality setting.
10. Keep existing character and environment fallbacks available until
    final independent visual approval.

## Remaining professional art gates

A segmented Motor6D prototype **is not a finished skinned character**:
there are still visible rigid shoulder/hip deformations. Final work needs
high/low-poly sculpt, careful topology and weights, native Roblox skinned
mesh rig import, animation authored and blended with true cycles, detailed
face/hand treatment, custom UV/bakes at production texel density, optional
LOD/streaming, and performance optimization.

The environment still needs photographic reference matching, measured
materials on hero surfaces, mesh-based fixtures instead of excessive Parts,
consistent geometric wear, lighting tuning and first-person validation.

**Do not call either workstream TTK-class until those gates pass.**

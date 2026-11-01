# Blackline Q01 — first controlled asset-quality rebuild

**Status:** modeled original textured GLB exported and source-audited; **not visually
signed off, not AAA-quality**, and not yet measured inside Roblox Studio.

**Target:** Control A's mixing console, a single high-salience visual landmark
seen by players at 3–25 studs. Do not improve credibility by scattering more
unrelated Parts or by changing mission/monster gameplay.

## Delivered source changes

- `tools/quality_console.py` creates an original, sloped, 12-channel analog
  console; true rounded/beveled edge topology rather than large unbroken
  cubes; cabinet supports, recessed operating deck, separate metal framing,
  per-channel 3D knobs, fader runners and slider heads, and a meter bridge.
- The top is a **real image-mapped 2048×1024** original control legend with
  labels, channel numbers and scale marks; the **1536×512** two-channel meter
  art has real original needle graphics, printing and institutional identity.
  These are printed equipment graphics, not live signal indicators.
- The new GLB exports its **color, tangent-space normal and metallic-roughness**
  images; no guessed Roblox texture IDs or runtime decal uploads.
- The console now faces the operator at **+Z**. Its raised meter bridge is at
  `-Z`, away from the user. Prior material/image previews showed legacy
  identity art facing the wrong side.
- The authoring output remains `BlacklineHeroConsole.glb`; the existing
  runtime imported/absent-fallback selection in `Kit.luau` is unchanged.
  **The original invisible `DeskPlinth` remains the only gameplay collider.**
- `tools/audit_hero_meshes.py` now fails the source export if this hero asset
  loses its two original printed PBR atlas materials, drops out of the geometry
  budget, loses UVs or drifts from its original scale. The Rojo pipeline runs
  `tools/validate_console_quality.py` as an independent gameplay-source gate.

## Source-asset measurement

| Quantity | Previous exported console | Q01 exported console |
| --- | ---: | ---: |
| Triangles | 5,552 | 20,720 |
| Vertices | 3,340 | 10,650 |
| Distinct material meshes | 10 | 7 |
| External dimensions, studs | approx. 6.32 × 4.20 × 3.47 | 6.16 × 4.07 × 3.34 |
| Original custom top / meter printing | No | Yes |
| Operator-facing, correctly oriented controls | No | Source design faces +Z |
| Actual studio render / frame time | Pending | Pending |

The triangle increase is acceptable for **one flagship** only if real Roblox
profiling supports it. These geometry counts are **not** a proxy for perceived
AAA quality. The images are synthetic author-created decals, not finished
photographic scans or high-to-low-poly sculpt bakes. Geometry and labels will
still need a Blender (or comparable DCC) artisan pass.

## Install safely without damaging the current place

1. Download the successful **Source Asset Export** job's
   `dead-air-import-ready-mesh-pbr-pack`. Extract
   `roblox-glb/BlacklineHeroConsole.glb`.
2. In Roblox Studio, **back up the old**
   `ServerStorage.ArtLibrary.BlacklineHeroConsole` to a separate storage
   folder with a new name. Do not move it into the new ArtLibrary as a second
   console. The supplied installer deliberately refuses to overwrite an
   existing approved prefab.
3. Use Studio 3D Importer on the new GLB. Ensure the imported Model keeps its
   source pivot at the center of its feet, with its operators facing +Z.
   Confirm there are texture-bearing MeshParts, not a single flat mesh with
   missing SurfaceAppearances.
4. Select the new Model, name it **exactly `BlacklineHeroConsole`**, then run
   `tools/studio/InstallImportedModels.luau` in Edit mode. Verify it was
   installed, not silently skipped. Save the place.
5. Enter F5 Play (server), then run
   `tools/studio/InspectConsoleQuality.luau` in the Server Command Bar.
   The Control A pivot should be near **(-110, 0, -122.8)**. No imported
   MeshPart may block physics or raycasts. The invisible original desk
   collision must remain intact.

## Visual acceptance — required, not yet performed

- Photograph the console from +Z (operator side) at 3, 12 and 25 studs,
  at medium and high Roblox graphics quality; do not approve photographs
  taken from its back or an orthographic asset viewer.
- Check the top atlas / meter labels for **correct orientation**, distinct
  legibility and zero texture mirroring. Check the beveled corners and fader
  stems for silhouette/normal smoothing artifacts, and the printed deck for
  coplanar z-fighting under a moving flashlight.
- Examine the area with generator power off/on; all control legends and
  analog meter artwork must remain passive, with no false signal glow.
- Run player + Engineer paths around both the occupied corridor and the desk;
  all previously navigable routes and sound occlusion must remain intact.
- Log actual 1080p GPU frame time p50/p95, memory, texture streaming and
  MeshPart count before deciding if a 20.7k-triangle desk is worth its cost.
- Rework if it still reads as a stylized/simple game asset. **Do not call this
  AAA-class until it passes artistic review and measured performance.**

## Next real quality gate

The model should go through an artist-led **Blender high/low-poly workflow**:
dimensional reference and construction design, hand-placed bevel widths,
curved/high-res control housings, correct UV islands and texel density,
AO/normal bake from high poly, physically justified paint wear, multiple
light rigs and actual first-person Roblox screenshots.

Only after a **single asset** passes this gate should its visual vocabulary be
extended to the other recording desks, the Engineer costume and other hero props.
Quality over quantity remains the production rule.

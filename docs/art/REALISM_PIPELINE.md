# Dead Air — realistic rendering and asset production standard

**Scope:** rebuilt recording complex, broadcast station, bell foundry, Engineer and portable items.  
**Goal:** believable, high-fidelity horror within Roblox's production renderer, with measurable runtime performance.  
**Status:** three original generated environments and five OBJ hero meshes committed, with native-lighting and architectural passes implemented in code; **scanned/hand-authored PBR textures, UV-mapped meshes and in-Studio photometric acceptance are not yet complete**.

## Renderer: what actually works

- **Roblox Realistic lighting** with `LightingStyle = Realistic`, `PrioritizeLightingQuality = true`, global shadows, calibrated exposure, environment specular/diffuse and restrained post-processing.
- Local `SpotLight`s with selected dynamic shadows. The eight new primary light fixtures have genuine housings and emissive lens pieces; four cast shadows. Ordinary emergency lamps are non-shadowed fill, tied to the existing generator state. Pre-power visibility remains limited.
- `ColorCorrectionEffect` and small `BloomEffect` values approximate camera response. Avoid always-on depth of field, fake film grain, cartoon chromatic aberration, extreme vignette or strobing. Do not apply another global color grade through individual map art.
- **No real-time RTX/path tracing toggle** is exposed to Roblox creators. Do not claim ray-traced reflections or global illumination; Roblox raycasts are gameplay geometry queries, not image rendering and will not approximate path tracing at acceptable cost.

**Current code:** `default.project.json`, `src/server/VisualFidelity.luau`, `src/server/Maps/Kit.luau`, `src/server/Maps/AssetLibrary.luau`, `src/server/MapBuilder.luau`. The `OwnsLighting` attribute remains respected: maps that own their lighting opt out of the studio treatment. The generated environments opt into calibrated Realistic lighting via `ProductionGeometry=true`. Imported Studio maps may supply independent lighting with `OwnsLighting=true`.

## Physical materials: PBR asset manifest (not uploaded)

The native material pass is an approximation. To reach the visual target, replace built-in materials using **MaterialVariant** for tileable building finishes and **SurfaceAppearance** on UV-mapped `MeshPart` props. The asset IDs in the table do not yet exist; do not invent numeric IDs.

| Family / usage | Base colour direction | Target roughness | Metalness | Asset set |
| --- | --- | --- | --- | --- |
| Aged studio plaster walls | warm neutral grey, localized wear | 0.78–0.92 | 0 | albedo, tangent normal, roughness |
| Fabric acoustic treatment | charcoal fabric, fine fibres, dusty corners | 0.86–0.98 | 0 | albedo, tangent normal, roughness |
| Walnut/oak floor and trim | aged dark brown, slight polish at traffic | 0.48–0.78 | 0 | albedo, tangent normal, roughness |
| Scuffed utility concrete | cool grey with mineral variation | 0.72–0.94 | 0 | albedo, tangent normal, roughness |
| Brushed electronics metal | neutral grey, anisotropy *suggested* in maps | 0.30–0.55 | 1 | albedo, tangent normal, roughness, metalness |
| Painted/rust-spotted steel | chipped painted casing, localized corrosion | 0.50–0.88 | mixed 0 / 1 **in map** | albedo, tangent normal, roughness, metalness |
| Recorder and handset plastics | worn matte black, finger-polished buttons | 0.48–0.76 | 0 | albedo, tangent normal, roughness |
| Dark glass/control displays | dusty glass, no full-mirror reflectivity | 0.10–0.30 | 0 | albedo, roughness, restrained emissive where supported |

Roughness above is an *authoring target*, not a Lua numeric property on native Parts. A single flat `Part.Color` cannot simulate microscopic roughness variation.

**PBR file requirements**: prepare 1024×1024-or-smaller source images where appropriate, with correctly oriented OpenGL tangent-space normal maps; albedo is not an illumination map, roughness is grayscale, and metalness is generally binary except mixed worn/painted surfaces. Store original source and license metadata in version control, and import images into Roblox Studio via Asset Manager. The resulting asset IDs and `.rbxmx` MaterialService content can then be wired to Rojo. A texture without an uploaded, usable Roblox asset ID will not render in the game.

## Hero meshes first, not thousands of tiny Parts

Current procedural shapes guarantee a working gameplay-art handoff. They are **not final AAA assets**. Replace *in this priority order* with professionally authored UV-unwrapped meshes, retaining separate gameplay volumes:

1. **Engineer**: 1 main mesh or a small joined set, actual gaunt proportions, clothing folds, organic fused headset, controlled red emissive earcup textures. Preserve the original `HumanoidRootPart`, Humanoid navigation and two earcup lights.
2. **Mixing desk**: convincing console shape, backlit meter bridge, tactile controls, selective backlight; retain a simple invisible collision hull.
3. **Live-room equipment**: drum kit, mic booms, cases, piano, acoustic diffusion and rigging.
4. **Portable items**: walkie and recorder, including UV mapped body plastic, grille details, small LCD and buttons. Keep root-part APIs unchanged.
5. **Architecture kit**: modular wall/coving/door jamb, glass partition, studio door seals, ventilation and realistic industrial pipe fittings; preserve `CanQuery` sound rules.

A small number of carefully authored meshes is preferable to dozens of overlapping primitive bolts: the latter increases draw calls, shadows and CPU-instance overhead without delivering realistic silhouettes. Use repeated meshes and reuse PBR sets. Match collisions to the map contract separately from art geometry.

## Studio import + Git workflow

1. Produce/obtain licensed reference photographs and PBR scans, record source and terms; CC0 scans from e.g. Poly Haven or ambientCG are reasonable starting points.
2. In Blender, model from measured-ish proportions in **studs** (e.g. control desk height 3.5 studs), UV unwrap, bake normals, author masks and LODs. Set scale before export. Prefer GLTF/FBX and import in Studio.
3. Confirm silhouette, world scale, UVs, correct tangent normal orientation and PBR reflectivity in Roblox Studio at quality 10 and lower settings.
4. In Material Manager, create MaterialVariants; for MeshParts, set SurfaceAppearance with asset IDs. Ensure uploaded asset permissions allow use in the experience.
5. Preserve `Workspace.Map` gameplay structure and immutable objective/door/Area anchor semantics; put visuals underneath separate art folders.
6. Export the approved `Map` as text `.rbxmx` to `assets/maps/Map.rbxmx` and reference it in the project file as documented in `docs/MAP_CONTRACT.md`. Do not overwrite the code-built fallback until the authored version passes contract checks.
7. Check pathfinding, `[Map]` validation warnings, player sprinting, booth noise isolation, prompts, fuse locations, actual flashlight visibility and sound mix.
8. Commit source asset licence attribution, Blender source if available, map export and material settings as a reviewable art PR.

## Lighting direction and photography acceptance

**Before generator:** near-black with *limited* emergency signage and flashlight-driven evidence; players must still distinguish floors, door outlines and important geometry. Dark is not the same as clipping all blacks to 0.

**After generator:** localized illumination and natural shadow falloff from plausible fixtures; avoid fully lighting the facility. A control-room meter may glow softly in a dark booth, but must not become a floodlight. The loaded room's exposure should not pop unnaturally when passing through a doorway.

**Basement:** directional ochre/amber light pools reveal steam pipes and wet-looking metal; use actual reflection/roughness contrast, not excessive neon. Avoid permanent point lights that are bright while the generator is off.

**Engineer:** from 15–25 studs away, the skull/headset silhouette and two earcups must read against a flashlight. The body should not become a pure black blob or create distracting bloom.

Acceptance screenshots should be captured in **Studio Play**, not Edit, from reception, control A, live floor, an enclosed booth, rear gallery, archive loop, basement and a monster encounter. Capture both power states, with and without flashlight, at quality 10 and a medium quality level. Review the images alongside performance capture.

## Performance gates (targets, not measured results)

- Primary target: **60 FPS, 1080p** on an RTX 4050-class laptop with a stable high-detail Studio/Roblox graphics setting; measure p50/p95 frametime and ensure major encounters do not stutter.
- Secondary target: a playable lower-quality fallback for common integrated GPUs and midrange mobile hardware. Optimize detail/shadows before abandoning the product's visual identity.
- Shadowed local lights: limit overlapping expensive sources; start with four *hero* shadow-casting practicals, tune only after profiling.
- Avoid hundreds of dynamically moving non-essential pieces. Merge repeated static detail into mesh kits; use appropriate streaming and mesh render fidelity.
- Keep `CanQuery=false` on decorative visuals that should not attenuate sound. Structural walls, floors and collision doors continue to block sound as defined by the contract.
- Roblox MicroProfiler, script performance statistics and memory budget must be measured in a real client; source inspection cannot establish FPS, draw calls, quality or traversal.

## References

- Roblox Creator Hub: [Lighting](https://create.roblox.com/docs/environment/lighting), [PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance), [MaterialVariant](https://create.roblox.com/docs/reference/engine/classes/MaterialVariant), [Performance optimization](https://create.roblox.com/docs/performance-optimization).

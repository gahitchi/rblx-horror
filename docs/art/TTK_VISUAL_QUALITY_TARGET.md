# Dead Air — visual-quality benchmark: TTK Testing, with Control-scale worldbuilding

**Status (2026-11-01):** quality target and acceptance specification, NOT an assertion
that the current Dead Air builds already resemble TTK Testing. This note is
paired with the implemented Blackline whitebox and LD-03 qualification pipeline.

## References and intended identity

- [TTK Testing (Sable Digital) on Roblox](https://www.roblox.com/games/120189115846709/TTK-Testing): a contemporary example of the material, lighting and prop standards Roblox can support.
- [TTK development discussion (Roblox Developer Forum)](https://devforum.roblox.com/t/ttk-our-very-early-tactical-fps/4664539): the team's perspective on tactical atmosphere, presentation and technical ambition.
- Remedy's Control is a **level architecture** reference: connected, functional, institutionally coherent spaces, vistas, dramatic scale and hidden history. It is not a prop library or permission to copy its settings.

**Dead Air should be visually credible at first glance as a mature industrial
horror experience**, while retaining its own muted recording-studio aesthetic,
acoustically important rooms, environmental backstory, flashlight-led tension
and distinctive Engineer silhouette. Avoid copying the TTK weapon viewmodels,
maps, UI, color grade or any proprietary materials.

## What the current implementation does and does not have

**Already in source:** authored 19-space Blackline circulation, varied room
heights, larger LiveHall, actual functional props/story clues, Rojo-imported
six MaterialVariants, nine previously imported GLBs, four optional new GLBs
(with procedural fallbacks), lighting rules, moving doors, sonic gameplay.
The non-grid map and last art refinements have passed source validation.

**Currently not at target:** many walls, desk fronts, shelves and architectural
details are still rectangular Parts. Existing high-level PBR material families
are **procedurally synthesized starter textures**, not measured scans or
artist-authored baked surfaces. The thirteen current GLBs are original,
principally low-complexity hard-surface meshes; most lack a professional
high-frequency material pass, detailed atlas UVs, damage/wear masks and
per-asset LOD qualification. No before/after TTK-style lighting comparison,
render measurements or actual frame-time data from this new Blackline exists.

The benchmark requires improving the asset pipeline rather than compensating
with bloom, neon, film grain, excessive postprocessing or thousands of tiny Parts.

## Visual standards, in priority order

### 1. Architecture and spatial identity
- **Hero vistas**: Reception to StaffGallery; StaffGallery to LiveHall; viewing
  pane to studio floor; service corridor to generator; ControlA to archive wing.
- Exposed beams, risers, structural transitions, service cabinets and real
  construction joints are explained by the facility's history and function.
- Architectural wall and floor modules use consistent scale, grout/joint sizing,
  trim and believable intersections. No repeated square-room grids.
- Preserve clear routes for the Engineer (8.5-stud-high pathing agent,
  at least 6x9 usable doors) and the scripted acoustic material contract.

### 2. Primary readable surfaces
- Replace high-visibility, obviously tiled starter wall/floor textures with
  artist-approved **physically based** albedo/color, tangent-space normal,
  roughness and metalness where appropriate. Prefer real measured references,
  licensed scan-derived maps or original baked materials.
- Solid steel should not look evenly rusted everywhere. Use material layering
  by physical exposure: protected surfaces are painted; edges, moisture traps
  and handles show use. Acoustic fabric has no metallic response.
- Desk top, lower base, door pressed panels and close-up handles have bespoke,
  plausible material responses and less noisy distant silhouettes.
- Place surface seams at actual structural joints; avoid texture repetition
  visible when standing 10–30 studs from a wall.

### 3. Hero assets (complete one room first)
**Blackline flagship vertical slice:** Reception -> StaffGallery -> ControlA ->
LiveHall. Every object within reach must have a functional purpose, readable
mass, correct human scale and consistent roughness. Prioritize:
- rebuilt control desk with convincing channels, faders, displays and meter bridge;
- properly detailed reception fixtures and security terminal;
- realistic acoustic glazing, frame seals, wall trim and door hardware;
- professional rack electronics, patch cabling and labeled equipment;
- original floor treatment, practical lights, cable routing and maintenance signs;
- the Engineer's face/headset/garment silhouette at first-person distance.

Produce original art in Blender or an equivalent professional DCC, preserve
editable sources/UVs and asset licenses, and export validated Roblox-compatible
meshes. Each uploaded mesh must retain an invisible gameplay collision proxy.

### 4. Lighting and image quality
- Realistic lighting, accurate shadow placement, controlled exposure,
  believable fixtures and stable flashlight response.
- Cool production worklights, localized amber service lamps, restrained
  low-level emergency egress and dark acoustic booths; no uniform green/teal
  filter applied to the whole game.
- No bright lights from equipment whose power supply is disabled. Lighting
  activation should track actual generator/room power when applicable.
- No synthetic fake ray-traced promises. Roblox's rendering is subject to
  the engine's real lighting and hardware constraints.

### 5. Animation, sound and immersion
- Moving door hinges, physical sound barriers, machinery ambience, equipment
  interactions and a credible Engineer route are part of perceived realism.
- Lens effects should remain subtle, optional and testable. Add no permanent
  heavy camera shake or bodycam distortion that sacrifices horror readability.
- Detail only earns its place if seen/heard or if it communicates authentic
  occupation of the facility.

## Submission / acceptance checklist

A scene can be called TTK-class **only after actual Roblox footage and measured
benchmarks** support that qualitative judgment.

For each of the five flagship viewpoints, capture:
1. High-quality graphics, neutral camera exposure, lights off, flashlight off/on.
2. Same camera pose after generator restoration.
3. Close (<5 studs), human observation (10–15), corridor (25–40) material tests
   for visible tiling, normal shimmer and texture streaming.
4. A profile at 1080p on RTX-4050-class hardware with FPS, frame-time p50/p95,
   draw/instance counts and memory. Start with a **60 FPS target** and tune
   shadowed sources/instance count rather than inventing numbers.
5. A medium-quality GPU test and mobile/integrated graphics fallback, not just
   an ultra-only cinematic screenshot.
6. Real co-op route and monster-chase recordings; no occlusion/pathfinding
   blockers introduced by decorative visual upgrades.

**Reject criteria:** repeated generic primitive assets on hero surfaces;
uniform rust or wood PBR where surface function differs; light leaks/coplanar
flicker; readable textures only close to the camera; heroic screenshots with
nonfunctional gameplay; unmeasured FPS claims; unowned external mesh assets.

## Production ordering after LD-03

- **VF-00** gather five exact screenshots from Blackline Studio + two representative
  TTK reference shots; label shortcomings objectively.
- **VF-01** hero-room asset replacement: complete Reception/StaffGallery/ControlA/
  LiveHall materials, geometry, trims and lights before multiplying detail.
- **VF-02** apply the approved modular construction kit to remaining wings,
  while preserving the unique history of each room.
- **VF-03** coherent audio, interactive props, light/power transitions and
  cinematic but readable silhouette passes.
- **VF-04** capture real-performance evidence and cut unneeded details.
- **VF-05** visual signoff with the user; only then qualify production aesthetic.

TTK Testing's appearance is a legitimate benchmark for Roblox production
quality; **we are not there yet**. The next source updates and asset exports
should be judged against this definition, not the number of Parts or GLBs.

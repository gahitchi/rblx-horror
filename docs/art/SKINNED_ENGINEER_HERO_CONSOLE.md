# Dead Air — weighted Engineer and Control A hero console, source qualification

**Branch:** `chatgpt/studio-art-pass`; **main unchanged**.
**Status:** exporter, skin integrity tests, Luau integration and Rojo automated
checks implemented and validated; Studio import/animation/art sign-off pending.
**Target:** original horror art with the production discipline and realism
of TTK Testing; not an attempt to reproduce copyrighted assets.

## 1. What changed in the Engineer

### Genuine weighted glTF 2.0 skin, not six welded static rigid pieces

The new optional source asset `EngineerSkinned.glb` contains the same
original Engineer concept but with a named hierarchical bone skeleton,
15 deforming joints, per-vertex `JOINTS_0` and `WEIGHTS_0` (up to four
influences), normalized weights and inverse bind matrices.

**Structural export acceptance (GitHub Actions):**

- 15 named influencing joints, and a separate unweighted root at 0,0,0.
- 10 skinned GLB material mesh nodes, 4,434 weighted mesh vertices.
- 1,504 vertices have more than one active bone influence, allowing actual
  interpolation at anatomical joints instead of only rigid pivot movement.
- Maximum observed per-vertex weight-sum error: 5.96e-8.
- The GLB exporter and independent verifier agree on every inverse bind
  matrix and skeleton parent relation.

These measurements prove a **valid skin representation in the GLB**,
not that the anatomy or weights look professional under deformation.

### Runtime integration and safe fallbacks

`SkinnedEngineer.luau` checks that an imported
`ServerStorage.ArtLibrary.EngineerSkinned` contains all 15 actual
`Bone` instances; a Model with the correct filename but no valid
skeleton is rejected. If present, imported MeshParts are noncolliding
and welded to the original AI/hitbox root, while the bone hierarchy
and weighted surface remain available for visual posing.

`SkinnedEngineerMotion.luau` animates the skin through `Bone.Transform`
on each client: breathing, gait, head scanning, shoulders, elbows, wrists,
hips, knees, ankles and lunge anticipation. Audio/glow PointLights remain
the same game-controlled instances and are attached to the moving head.

**Fallback precedence**, deliberately opt-in:

1. Imported, validated `EngineerSkinned` → skinned visual (RigVersion 2).
2. All six prior `EngineerRig*` GLBs → segmented Motor6D visual (v1).
3. Original rigid `EngineerBody` GLB → original rigid visual.
4. Original built-in primitive Engineer → reliable functional fallback.

This does not modify AI perception, root motion, monster collision,
attack range, generator objectives, player movement or network authority.

### Important limits

- The weight assignment is procedural, guided by anatomical positions.
  Shoulder/elbow/knee weighting requires in-Studio review, possible
  correction in Blender, and ideally hand-painted weights.
- The source body is built from original hard-surface/anatomical primitives,
  **not** a professional scanned, retopologized, hand-sculpted character.
- Roblox import may reparent/rename Bones or split meshes. Those behaviors
  are runtime-gated and require real Studio validation.
- The authored animation is state-driven/parametric, not a finished
  high-quality motion-capture sequence or blended animation library.
- Client Bone.Transform does not change the invisible monster hitbox,
  intentionally preserving the original collision/navigation behavior.

## 2. Control A's upgraded hero equipment

`BlacklineHeroConsole.glb` is a new original, room-specific mixing desk
with a built-in structural base, top, 16 control channels, physical
fader stems, rotary gain controls, visible metering and a real original
engraved identification graphic baked into the GLB's material image.
Its dry finish and warm analog details are designed for Control A,
not copied from any existing game.

The original console is **optional**. If imported, Blackline Control A
uses it without generating a second overlapping top or pedestal. If it is
missing, the earlier `MixingConsole` GLB remains valid; if that is missing,
the native desk fallback still builds. The functional invisible collision
proxy remains unchanged.

The source model is 3,340 vertices, has 10 material mesh groups and
includes original embedded texture assets. Actual Roblox render quality
and import scale/pivots are still unqualified.

## 3. Source pack and installer

The reproducible Source Asset Export now contains **27 GLBs** total:
the previous 25, the weighted `EngineerSkinned.glb`, and the new
`BlacklineHeroConsole.glb`. The pack also carries `art-quality-report.json`
and the original PBR materials.

**You will not need to reimport any of the previous 25 files.** When the
laptop and Roblox Studio are available again:

1. Pull `chatgpt/studio-art-pass` and sync Rojo.
2. Download the newest successful **Source Asset Export** artifact.
3. Import only `EngineerSkinned.glb` and `BlacklineHeroConsole.glb`
   with the Roblox Studio 3D Importer. Select **Custom** rig for the
   skinned creature if Studio does not select it automatically.
4. Confirm imported skeleton and PBR textures in Explorer. Preserve
   embedded hierarchy and precise physical sizing; do not merge all meshes
   into a plain rigid Part.
5. Select both imported root Models and run
   `tools/studio/InstallImportedModels.luau` from the Studio Command Bar.
   Save your place. The installer will not overwrite previously imported
   models or asset IDs.
6. Start F5 with the **Blackline** (`studio`) map.
7. In the **server-side Command Bar**, run
   `tools/studio/InspectCharacterAndHeroArt.luau`. Check 15 Bone
   names and `RigVersion=2`, or investigate the fallback reason.
8. On a **client**, observe idle, walk, listen, hunt and lunge for actual
   smooth deformation and realistic bone pivoting. Screenshots of the
   same pose from front/side/rear are essential.
9. Examine the Control A console at 5, 15, 30 studs under generator
   on/off lighting and flashlight. Check label legibility, tabletop
   materials, source-pivot alignment, UV seams and reflections.
10. Record measured FPS, frame-time p50/p95, memory and the size of
    the imported MeshParts on actual hardware.

## 4. Formal gates

**Source-complete:** export and strict GLB skin tests; CI Rojo/Selene;
optional runtime path; noncolliding imported MeshParts; tiered fallbacks;
original materials and room-specific console placement.

**Still unqualified:** authentic creature silhouette under light; correct
bone orientation and skin shading in Studio; animation style, skin clipping,
player versus monster scaling, revised occlusion/pathfinding after import;
high/medium GPU settings; first-person asset photographic comparison.

**No TTK parity claim** is justified by a triangle count or texture-map
count. Full professional character and environmental quality remains
an active production objective rather than a completed milestone.

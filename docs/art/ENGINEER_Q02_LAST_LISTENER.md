# Engineer Q02 — The Last Listener, anatomical source candidate

**Status (November 1, 2026): newly modeled, textured, CC0-derived 3D
character and 15-joint weighted GLB successfully exported; Source Asset Export
and Rojo builds passed.** An actual character exists, but it has NOT
yet passed Roblox Studio import, performance or owner visual review.

## The specific character made

The Engineer is a normal-height, human-proportioned, unnervingly focused
Blackline mastering technician. He is threatening because of *behavior*,
not because his anatomy is monstrous. The original asymmetrical face,
hair, eyes, hands, jacket with cloth folds, trousers and shoes are derived
from a publicly released anatomically modeled MakeHuman adult, not
programmatic 3D spheres or box silhouettes.

The game's original studio-specific additions are aged monitoring
headphones (lathed ear housings, cushions, adjustable spring and mic boom),
a routed signal cable, a compact waist monitor with machined controls,
and real UV-mapped Blackline employee/equipment labels. The jacket and
denim have been recolored to dusty, worn charcoal while preserving
the original photographic fabric detail. There is no gore, wounds,
abuse symbolism or supernatural anatomy.

## Measured source assets

| Source check | Result |
| --- | --- |
| EngineerBody.glb | 94,863 triangles; 70,262 vertices |
| EngineerSkinned.glb | 94,863 triangles; genuine weight attributes and 15 deform bones |
| Material mesh sections | 41 |
| Largest individual MeshPart source section | 18,423 triangles |
| External size in Roblox source studs | 2.386 × 6.545 × 1.504 |
| Original image maps attached to GLB | 22 (shared/duplicated references across material sections) |
| Original source | CC0 MakeHuman-derived Innerscene 'Daniel', exact SHA-256 checked on download |
| Collision / navigation / monster AI | Same invisible 2×2×1 root; HipHeight 3; no change |
| Two existing warning lights | Repositioned cosmetically to new earcup coordinates; original trigger remains |
| Automated weighted-skin verification | Pass in Source Asset Export |
| Roblox Studio import + screenshots | NOT TESTED |
| Owner-approved TTK-class art | NOT CLAIMED |

The 93k triangle source is **not** appropriate to multiply across many
characters and may be expensive on some Roblox hardware. Its parts
individually meet the Creator Hub's 20k triangle geometry ceiling.
The Q02 candidate is an intermediate source for first-person review,
not performance signoff or an excuse to neglect optimization.

The *previous* Q02 sphere-and-loft character was reviewed on
2026-11-01 and rejected for cartoonish anatomy. That source was removed
from the active export. This new character comes from a completely
different, anatomically based production method.

## Reproducibility

- Realistic material/gear authoring: `tools/quality_engineer_real.py`
- Character dual rigid/weighted export routing: `tools/build_character_assets.py`
- New human-proportioned weighted 15-bone rig: `tools/build_skinned_engineer.py`
- Source licensing and exact SHA: `docs/art/ENGINEER_CC0_LICENSE.md`
- Visual-only runtime mounting / existing gameplay lighting:
  `src/server/Monster/SkinnedEngineer.luau`
- Automated checks: `tools/audit_hero_meshes.py`,
  `tools/validate_skinned_engineer.py` and the Rojo build.
- Official export includes `roblox-glb/EngineerBody.glb` and
  `roblox-glb/EngineerSkinned.glb` and a license note.

An original MakeHuman-derived CC0 `daniel-man.glb` is downloaded at
build time from the documented publisher endpoint. Builds **fail**
if the source SHA does not exactly match the reviewed input.

## Safe Studio installation and remaining gates

1. Keep the previous approved `ServerStorage.ArtLibrary.EngineerBody`
   and `EngineerSkinned` as backups **outside ArtLibrary**. The
   importer does not overwrite assets with duplicate names.
2. Import both new exported GLBs using Studio 3D Importer. On the
   weighted version inspect every needed named Bone, correct feet
   pivot y=-4 relative to root, the original textured face and jacket,
   and non-emissive ear cups. Source local front points to **-Z**.
3. Select each newly imported Model named precisely
   `EngineerBody` / `EngineerSkinned` and run the existing
   `tools/studio/InstallImportedModels.luau` in Edit mode; save.
4. Test with F5/Server Command Bar and
   `tools/studio/InspectEngineerAnatomicalQ02.luau`. All
   imported mesh geometry must stay CanCollide/CanQuery/CanTouch false;
   the original invisible HumanoidRootPart remains the server
   authority. Check the two live ear-cup PointLights still react.
5. Capture source and in-game face details, 3/12/25-stud front and
   profile shots under neutral, low-power and normal-power lighting.
   Check jacket/neck clipping, hand anatomy, bone bends and headphone
   placement; walking/Listen/Investigate/Hunt/lunge pose transitions.
6. Compare frame-time and streaming on target devices. A large
   animated actor can cost more than static environment props;
   reduce texture/mesh cost or bake to a high/low LOD if needed.
7. Only promote from `source-candidate` to owner-reviewed / Studio
   approved when **actual in-game evidence** is saved. Passing CI
   proves import-oriented geometry/skin validity, not aesthetics.

This art intentionally targets **unsettling rather than graphic horror**.
The full published game's actual Roblox maturity classification must
be answered from final gameplay/scares/audio, not assumed from this mesh.


## Q02-HF01 — headset fit correction (2026-11-01)

The previous source-rendered headset was visibly floating beside the actor's
ears. The source MakeHuman character is **not horizontally centered on x=0**:
its ear outer surfaces lie around source x=-0.107 and x=+0.055. The headset
had incorrectly assumed x=-0.104 and +0.104 (equal offsets).

This is now corrected in **actual model geometry**, not a retouched render:

- Measured scalp/ear landmarks from the SHA-pinned original CC0
  `base` and `short01` meshes during source asset generation.
- Moved each ear cushion onto its corresponding **asymmetric anatomical ear**.
- Replaced uncovered hollow shells with rounded black leather seal rings,
  fitted metal forks, and genuine closed-back driver caps.
- Built the headband to touch the real scalp arch rather than hovering
  at a generic Y position. Shortened and mounted the microphone boom at
  the headset; split the signal lead into a head section and a jacket section.
- Corrected the actual `EngineerSkinned.glb` skinning so 18 source
  material/mesh sections making up the earcups, forks, band and mic are
  **fully rigidly weighted to the existing Head bone**. The headset cable
  transitions smoothly into Neck/Spine at the collar.
- Moved the existing two triggered warning lights to the measured ears
  (Head Bone local x=-0.20 and +0.39 studs, preserving the old fallback
  light offsets when an earlier prefab is installed).
- Added `tools/validate_headset_fit.py` to Source Asset Export. It verifies
  ear surface alignment, crown contact, closed cup geometry, and exact
  per-vertex head bone weights on the actual exported GLBs.
- Re-exported real textured `EngineerBody.glb` and
  `EngineerSkinned.glb`; source model totals **94,863 triangles,
  70,262 vertices, 41 mesh sections**, maximum 18,423 triangles/section.
  Both source-art export and Rojo CI pass.

**Art review remains required:** static source renders have been compared
with identical lighting/cameras, but these are not Studio screenshots.
The Studio installer never automatically replaces earlier ArtLibrary
imports: back up and manually swap the GLB to see the revised headset.
Evaluate dynamic head pivots, microphone-to-lip distance, seal occlusion,
and cable deformation in Roblox Studio before confirming in-game quality.

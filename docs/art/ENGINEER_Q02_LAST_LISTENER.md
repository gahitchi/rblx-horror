# Engineer Q02 — "The Last Listener": source character production sheet

**Branch:** `chatgpt/studio-art-pass`.
**Art status:** an original 3D **source candidate**, not Studio-authorized or
AAA/TTK-class final sculpt. It is deliberately human at first glance.

## Character promise

The Engineer once operated Blackline's mastering/recording equipment. His horror
is driven by an obsessive professional ritual: he still listens for the
missing M-08 master. He looks like a *person in the wrong place*, rather than a
10-stud monster with claws or a speaker head.

**Design ratio:** ~80% credible human, ~20% wrong. Normal/slightly tall
technician proportions, worn charcoal work jacket, dark trousers, proper boots,
quiet mechanical recorders, ordinary skin and asymmetric gaze. A headset and
microphone boom are the most visible identifying landmarks. He is not a robot,
a gore creature or a named mental-health condition; the threat comes from
intent, stillness and sound-related habits.

**No** blood, open wounds, mutilation, protruding bones, exposed organs,
torture imagery, self-harm symbolism or gratuitous injuries. No occult marks
or frightening non-diegetic LEDs. The Q02 portrait is allowed to be *unnerving*
without being graphic.

## Source actually implemented

- `tools/quality_engineer.py`: a new original human-shape technician with
  continuous tapered clothing surfaces, more believable head/body ratios,
  grounded eyes and mouth, short work hair, worn cuffs/seams/trousers, work
  boots, staff badge, asymmetric analog headphones + flexible signal lead,
  and a belt field recorder. Two printed identification plates are **real UV
  image textures** with unlit metallic/roughness and normal support.
- `tools/build_character_assets.py`: exports the same new model as
  `EngineerBody.glb` so a non-skinned imported cosmetic can be the fallback.
- `tools/build_skinned_engineer.py`: derives the fully weighted
  `EngineerSkinned.glb` from the same geometry, retaining the existing
  15 movement bones, real JOINTS_0/WEIGHTS_0 and inverse bind matrices,
  retargeted to the new shorter shoulders/head/arms. This is **not** a claim
  that Roblox 3D Importer has already preserved the skin or good animation.
- `src/server/Monster/SkinnedEngineer.luau`: keeps the two original gameplay
  ear warning PointLights and attaches them at the new headset proportions.
- `src/client/SkinnedEngineerMotion.luau`: restrained listening, walking,
  investigating and pursuit poses, applied **only to visual Bone.Transform**.
  No changes to server steering, attack reach, hitboxes or root movement.
- Legacy rigid segmented/procedural models remain available for clients when
  required imported assets are not present or cannot be skinned.

## Measured source budget

| Metric | Q02 candidate |
| --- | --- |
| Geometry source | Author-created deterministic GLB |
| EngineerBody | 26,920 triangles, 13,680 vertices |
| EngineerSkinned | Same surface, with actual 15-joint weight set |
| Dimensions | ~3.16 × 8.18 × 1.55 studs (source local) |
| Embedded texture attachments | 36 per GLB |
| Distinct material geometry | 12 parts |
| Runtime navigation | **Unchanged** invisible 2×2×1 HumanoidRootPart, HipHeight 3 |
| Audio and game AI | **Unchanged**; two live warning lights preserved |

These are *source measurements*, not rendering performance or acceptance.
The 8.18-stud art height is only moderately above the base Roblox avatar
relative to the original 4-stud root/feet datum; measure in Studio before
agreeing that the proportion meets the brief.

## Real-art preview and remaining risks

The Q02 preview was rendered directly from the exported `EngineerBody.glb`
with real embedded texture maps, using independent offline preview lighting.
The **first draft was rejected** because spherical cheeks, oversized eyes and
round knee/shoulder joints read as cartoonish. The second draft uses much
smaller recessed eyes and a narrow closed mouth, flat jacket collars and
continuous sleeve/pant surfaces.

**Remaining artist work:** the head, hands and fabric drape are still
automatically authored source approximations. A full AAA sculpt, high/low-poly
bakes, carefully painted cloth/skin response and motion capture-like acting
are *later* quality gates under the approved Q01 production-first plan. The
current source is meant to be tested and potentially revised, **not** multiplied
to other monsters without review.

## Safe Studio replacement and acceptance

The pack contains **two separate assets** to import:
`EngineerBody.glb` and `EngineerSkinned.glb`. Prefer the weighted version
when all required Bones survive Roblox Studio 3D import.

1. Back up the currently installed originals in `ServerStorage.ArtLibrary`
   outside that folder. The existing importer intentionally refuses to
   overwrite installed source names. Do not rename a backup as an active
   prefabricated source.
2. Import the two Q02 GLBs with **exact original model names**, keeping their
   ground-to-root pivot and the original local forward **-Z**. Check imported
   `MeshPart.SurfaceAppearance` and the fifteen Bone names.
3. Select the new Model(s) in Studio Edit and run
   `tools/studio/InstallImportedModels.luau`. Save the place.
4. Run F5 Play, inspect `Workspace.Monster` and run read-only
   `tools/studio/InspectEngineerQ02.luau` in **SERVER** Command Bar.
5. Compare face and headset at 3/12/25 studs, idle/Listen/Hunt/lunge
   in Play, with flashlight off/on and high/medium graphics quality.
   Test actual player sightlines, narrow 8-stud portals and monster pursuit.
   Record frame times p50/p95; a 26k-triangle animated actor has an
   actual runtime cost, unlike a static console.
6. Confirm **both** original ear warning lights respond to the existing
   attack telegraph, exactly one cosmetic actor appears, and no imported
   geometry is collidable or queryable. No arm, cable or badge should visibly
   cross the original gameplay hitbox or camera.
7. If imported Bones deform incorrectly, do NOT disable gameplay. Restore
   the archived skinned rig or use a non-skinned original source while
   diagnosing the skin; the original AI still moves and hears normally.

## Roblox age guidance

Roblox's current
[content maturity and compliance guidance](https://create.roblox.com/docs/production/promotion/content-maturity)
explicitly includes creepy NPCs, ominous music and tension among **mild fear**
examples. This art pass intentionally targets that non-graphic range.
The *game as a whole* may require a different label depending on final
player violence, scare frequency, audio and game events. Submit an honest
Maturity & Compliance questionnaire at publishing and update it whenever
content changes. Source validation alone cannot establish eligibility,
moderation approval or an age category.

## Following task

Import and visually qualify Q02, then prepare Q03 player PPE with similar
silhouette and material quality, *without* introducing a new gameplay loop,
invasive horror imagery or gratuitous map expansion. The final post-game AAA
hero polish remains a separate, deferred pass.

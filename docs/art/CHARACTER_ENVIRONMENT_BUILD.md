# Dead Air — character and environment high-fidelity build checkpoint

**Date:** 2026-11-01
**Branch:** `chatgpt/studio-art-pass`
**Target:** visual-production quality comparable to TTK Testing, with original
Blackline recording-complex worldbuilding and Control-style spatial logic.

**Status:** SOURCE BUILT, EXPORT TESTED, STUDIO QUALIFICATION PENDING.
The assets in this checkpoint are original, procedurally modeled prototypes,
not a claim that either the characters or environment already meet TTK's
in-game rendering and animation quality.

## Character and monster development

### The Engineer
New `EngineerBody.glb` (full character sculpt) is exported with:
- non-player proportions: thin waist, wide yoke, overlong forearms,
  hooked fingers, off-axis coat panels and elongated footwear;
- embedded analog recording hardware, sternum meter, cabling and neck;
- damaged face, two distinct eye sockets and uncomfortable physical anatomy;
- separate original palette families for cloth, aged metal, rubber, tissue,
  analog status and repair hardware;
- UV-projected, embedded **base color, normal and metallic/roughness maps**.

`EngineerModel.build()` now optionally welds this imported character mesh to
the existing server-owned `HumanoidRootPart`, hiding the primitive body while
preserving the original headlight/earcup PointLights, AI, lunge behavior,
navigation and collision. When the mesh isn't imported, the previous
procedural monster automatically remains visible. **The full-body mesh is
not skinned**, and remains rigid during turns and lunges. This cannot be
described as finished creature animation or TTK-class monster presentation.

### Player operators
New `FieldOperatorVest.glb`, `FieldOperatorMask.glb` and
`FieldOperatorPack.glb`, with the same embedded PBR image pipeline.
`src/server/CharacterArt.luau` attaches them to existing Roblox R15
`UpperTorso` and `Head` parts **only during rounds**, with the R15 rig,
camera, movement, accessories and hitboxes left unchanged. R6/custom
rigs retain their existing avatar. Models remain massless, noncolliding
and nonqueryable. This gives a consistent Blackline technician identity
without silently modifying a user's avatar skeleton.

**Required art gate:** create a professional skinned R15 clothing/body
pipeline, shape-key/morph passes, real limb articulation and a fully
rigged Engineer (especially gait, turning, listening, lunging, hands,
face and headset response). Current cosmetics are wearable prototypes,
not final mesh deformations. Review the default Roblox avatar outfits
for visible clipping before using them in a shipped game.

## Environment development

Blackline's actual studio map has 19 deliberately authored Areas,
**27 traversable portals and 10 independent circulation cycles**.
Its power plant acquired a second, plausible Reception service door
after offline LD-03 validation revealed an unintended single-route
critical generator dependency. The two sealed booths and the loading dock
remain purposeful terminal spaces.

`Kit.luau` now varies flooring and ceilings with a room's actual purpose:
- timber tracking/live floors;
- subdued control and mastering floors;
- textile-lined acoustic booths;
- practical unglamorous maintenance concrete;
- institutional stone circulation and public areas.

This prevents every room from inheriting the same broad wall/floor PBR,
and maintains nonuniform ceiling/fixture heights.

### Two newly modeled signature environment assets
- `BlacklineTransferDeck.glb` — visually layered tape-transfer machine
  with large reel drives, supports, metering, gain pots and equipment
  legends; authored into `MasteringVault`.
- `BlacklinePatchMatrix.glb` — steel routing rack with dedicated panels,
  sockets, indicators, retained cable bundles and material response;
  authored into `PatchBay`.

Both embed our original image-map families and can replace their
procedural fallback geometries when imported. They remain
noncolliding set dressing for now; physical walkability/cover must
be qualified in Studio before they become solid gameplay obstacles.

Blackline also has original facility signs, narrative evidence, generator-
powered signals, clock, visitor registry, archive cart and intercom.
All require first-person sightline and rendering checks.

## Reproducible import pack

The asset generator exports **19 models**:
- 9 original core props, used since the first import;
- 4 optional additional environmental props
  (`ReceptionTerminal`, `TapeArchiveCart`, `ServiceIntercom`,
   `StudioWallClock`);
- 4 new optional characters/monster meshes
  (`EngineerBody`, `FieldOperatorVest`, `FieldOperatorMask`,
   `FieldOperatorPack`);
- 2 new optional signature environmental machines
  (`BlacklineTransferDeck`, `BlacklinePatchMatrix`).

`tools/build_character_assets.py` and
`tools/build_signature_assets.py` preserve generator code (editable
procedural geometry), export GLBs with UVs and image-mapped PBR data.
`tools/audit_hero_meshes.py` verifies the exported files, finite
geometry, material image presence for all six new image-mapped models
and a conservative per-mesh upload budget. The asset pack also includes
`art-quality-report.json` so simplified or untextured mesh sources
are not mislabeled as high-fidelity.

**No new asset IDs were invented.** Approved artist-owned imports are
read from `ServerStorage.ArtLibrary`. The original nine need not be
reimported. The six new image-mapped models and prior four optional
props can be imported when Studio is available.

## Formal qualification remaining for TTK-level claim

1. **Modeling:** real sculpt/bake pass for the Engineer,
   full R15 skinned uniform with proper weights/morph support,
   physically credible face/hands, normalized correct scale.
2. **Animation:** Engineer locomotion sets, procedural listening,
   attack/lunge/retreat animation and human movement, with proper
   IK and root-motion compatibility.
3. **Materials:** licensed or original hand-authored UV/baked
   maps with realistic edge wear and usage, no repetitive
   procedural image noise on prominent surfaces.
4. **World:** full-room hero architecture, purpose-built mechanical
   installation, physical props/cover and sound acoustic profiling.
5. **Lighting:** photographic reference-match under on/off
   generator phases, flashlight, realistic shadows and no
   uncontrolled glare.
6. **Performance:** actual 1080p playtests on an RTX 4050-class
   laptop and lower-quality hardware; record p50/p95 frame time,
   instance/mesh count, shadow budget, light count and memory.
7. **Studio pass:** import all optional meshes, inspect whether
   textures survive GLB import and remain legible at 5/15/30 studs;
   check rig clipping and doors/monster chase and acoustics.
8. **User approval:** side-by-side comparison with two identified
   TTK gameplay reference shots and five fixed Blackline views.

**The high-quality target remains an acceptance goal, not a completed
claim.** Automated compilation, geometry and GLB export do not
replace independent visual judgment and Studio performance data.

# Blackline VF-03 — Mastering Vault → Viewing Gallery

**Implemented in source:** November 1, 2026.
**Status:** CI Rojo/geometry checks and source GLB export pass;
first-person Roblox Studio appearance, acoustic behavior, asset import and
frame-time qualification remain pending.

## Design objective: a coherent technical procession

The journey north from Blackline's Live Hall through the Viewing Gallery,
Mastering Vault and Tape Archive should feel like part of one credible recording
institution. The same channel-08 incident must be inferable from physical
equipment, records and negative space, not an explicit quest UI.

This pass adds **one** high-value imported-ready piece: an original
dual-driver mastering reference wall. Everything else is a constrained
architectural treatment around the existing gallery glazing. No additional
mission requirement, pickup, sound event, new objective screen, timer, powered
lighting source or interaction prompt is introduced.

### Mastering Vault: the reference wall

Existing narrative equipment: the mastering transfer machine, a north-west
operator board with magnetic-source procedures, calibration racks, floor
treatment and the doorway to the archive. The new fixture is a
13.3 × 6.1 × 1.3-stud wall-mounted, sober analog A/B monitor array, with two
smoothly modeled low-frequency drivers, stamped acoustic surround, real trim
and fastening, dark calibration bridge, thermal slots and original engraved
identity plate. The plate reads:

- `BLACKLINE / MASTERING A-B REFERENCE`
- `M-08 RETURN UNVERIFIED`

This note is archival evidence, *not* an authoritative indicator that
a tape is currently broadcasting or that the player's objectives are complete.

**Placement:** Blackline MasteringVault x=-72..-24, z=-192..-160, y=0..14.
The reference array is mounted at x=-36.5, z=-190.84, facing **south**.
Its front is near z=-189.5 and its lower edge is approximately 3.35 studs
above the floor. It does not touch the three portals: west isolation at
x=-72/z=-176, east archive at x=-24/z=-176, and south gallery
at x=-48/z=-160. The old shift board to its west remains legible.

The `BlacklineMasterReference.glb` source asset is original, image mapped
and export-validated. It lives in the existing
`dead-air-import-ready-mesh-pbr-pack` GitHub Actions artifact.
No new texture IDs or asset IDs are invented. The native fallback is
deliberately close in silhouette and uses two physical driver profiles,
non-emissive labels, proper dark acoustic face material and a separate
housing (not repeated material tiles).

**Important de-clutter correction:** generic nearfield monitor clones and a
wall-length rack from `AssetLibrary` were suppressed *only* in MasteringVault.
Likewise, the repeat acoustic wood slats on the west booth doorway and the
generic patch socket panel across the east archive doorway were suppressed
only here. Their source logic continues unchanged in other maps/rooms.
These old pieces had **non-colliding** visual geometry but still risked
making real passages appear sealed.

### Viewing Gallery: the existing window is the hero

The gallery spans x=-72..30, z=-160..-128, with an 18-stud ceiling.
The large LiveHall transition is a physical 14-stud opening on its south
wall (center x=-21). Kit's **original 9-stud sound-blocking observation
window** is centered at x=23.5, z=-128, beside that opening. It is retained
untouched and remains the *only* acoustic/physical window collider.

A restrained surround now explains its construction: a short metal sill
and recess, crown trim, two rubber gasket returns and a blanked-out talkback
plate on adjacent masonry. The raised overhead return-air plenum is a
single functional-scale architectural element with just three splice plates,
not decorative duct spam. Its mounting is far above player and Engineer
clearance and creates no new sound-blocking surface.

The `GalleryDirection` sign has moved to solid north masonry between
the MasteringVault and TapeArchive doors, rather than over the
MasteringVault's entrance.

## Source integration and boundaries

- `src/server/Maps/BlacklineMasteringGallery.luau` owns the two localized
  art scenes. `BlacklineMasterReference` is imported via PrefabLibrary when
  creator-approved GLB art exists; otherwise a deterministic native scene
  is created.
- `src/server/Maps/Kit.luau` passes the current room name to the generic
  asset/architectural builders, then calls the new Blackline-only hero pass
  under the existing `spec.authored and studio` guard.
- `src/server/Maps/AssetLibrary.luau` and
  `src/server/Maps/ArchitecturalDetail.luau` use that name **only** to avoid
  placing repeat equipment over MasteringVault's existing doorways.
- `tools/build_signature_assets.py`, `tools/audit_hero_meshes.py` and
  `tools/studio/InstallImportedModels.luau` add the new optional mesh to the
  existing source/export/Studio workflow.
- `tools/validate_mastering_gallery.py` verifies hard-coded bounds against
  the **actual** 19-room Blackline plan and Kit portal/window placement,
  checks the direction-sign bay, guarantees all new pieces are visual-only,
  and enforces no new gameplay, physics or audio system ownership.
- `tools/studio/InspectMasteringGallery.luau` provides a *read-only*
  F5/server Command Bar inspection of new Models, visual collisions, exact
  Kit pane location, imported prefab pivot and basic counts.

The art props are anchored, `CanCollide=false`, `CanTouch=false`,
`CanQuery=false`, and opt out of broad PBR swapping. Existing structural
walls, doors, all Areas, monster routes, sound occlusion, PowerLights and
objective marker Parts are not modified.

## Studio acceptance to complete later

1. Sync `chatgpt/studio-art-pass` via Rojo into the **match place** and use
   the Blackline/studio map. The native fallback should load immediately.
2. Walk from LiveHall into ViewingGallery, then MasteringVault, then
   TapeArchive. Check the point of attraction and that the gallery sign
   no longer covers a doorway. View each room from both directions.
3. Run `tools/studio/InspectMasteringGallery.luau` in the **server Command Bar
   during F5 Play**; record every `[VF03]` line. Also run
   `tools/studio/QualifyBlackline.luau` for the real pathfinding/acoustic
   scenarios.
4. Compare **native fallback** to the imported
   `BlacklineMasterReference.glb` at <5, 15 and 30 studs, including
   flashlight-off and flashlight-on conditions. Check the physically
   authored front, bounding box, pivot, signage readability, and any
   intersections with existing machinery.
5. Check the genuine glass still occludes sound and remains collidable,
   while every new finish Part is non-colliding/non-queryable.
6. At 1080p on the target laptop, compare representative first-person
   screenshots, frame-time p50/p95, memory, imported material count and
   streaming state against the previous branch build. Do not accept a
   striking screenshot if the play path or frame time has regressed.
7. Only after the above, decide whether the reference enclosure needs
   a professional high/low-poly modeling and baked UV/roughness pass.

**Not a TTK Testing-class visual signoff:** the new wall is a bespoke
procedural texture-mapped source prototype with validated export geometry.
It has not received a photogrammetric/hand-sculpted master material bake,
artist-approved lighting match or native Roblox GPU review. The correct next
step after this pass is targeted visual refinement of these two rooms, not
arbitrary expansion into the other 17 spaces.


## VF-04 refinement — remove counterfeit complexity, face the player

**Implemented in source, automated CI passed; Studio acceptance pending.**

A subsequent close-read of the actual room builder identified two avoidable
visual regressions in the prior VF-03 vertical slice:

1. The historical transfer deck spawned at x=-59, z=-180 without a yaw
   correction. Its modeled operating front pointed away from the main
   MasteringVault approach. The installed GLB and the native fallback now
   share a **180-degree yaw** and are housed in a single, named
   `MasteringTransferStation` scene. From the south/gallery approach
   the reels, transport buttons, VU displays and identification plate face
   the player.
2. Without imported art, `StoryProps` used to replace the tape machine
   with an unrelated generic stacked service rack. That fallback is removed.
   The new native backup is a deliberately modeled, two-spindle analog
   transport with machined faceplate, controls, calibrated VU panels,
   tape guide and identification strip. The custom GLB
   `BlacklineTransferDeck` is **reused**, not duplicated or re-exported.
   The old per-room StoryProps placement was eliminated, preventing
   two machines from occupying the same location.
3. The ViewingGallery had both the authored overhead return plenum and
   a shared automatic service-cable tray. The generic tray is now skipped
   **only in the ViewingGallery**, leaving the original air-return design
   as the recognizable ceiling feature. Other corridors are unchanged.

**Source safety:** no new sound, fake electrical state, interaction, physics
collider, AI path, door or mission mechanic. All new fallback pieces use
`CanCollide=false`, `CanQuery=false`, `CanTouch=false` and
`DisablePBR=true`. The existing actual doorway and observation-glazing
collision remain untouched. `tools/validate_map_assets.py` and
`tools/validate_mastering_gallery.py` are updated to verify exactly
one room-owned transfer station and to reject a reintroduced generic rack.

The independent, read-only F5 server Command Bar probe
`tools/studio/InspectMasteringGallery.luau` now examines the
`MasteringTransferStation`, including part bounds, visual tier,
non-collision, two native reels, and imported pivot orientation.

### Four reproducible first-person review compositions

These coordinates use the existing authored Blackline room geometry in
Roblox studs. Camera heights are **inspection viewpoints**, not new
player spawn positions, teleport destinations or extra game systems.

| Shot | Approx. camera position (x, y, z) | Look at (x, y, z) | Criterion |
| --- | --- | --- | --- |
| 1. From gallery to live hall | (-10, 5.5, -139) | (23.5, 7.5, -128) | True glass reads as part of a recording campus; frame has no light leak or UI clutter |
| 2. North gallery / room doors | (-21, 5.5, -148) | (-21, 8.5, -160) | North direction sign is on actual masonry between two clear entrances |
| 3. Mastering reference wall | (-45, 5.5, -170) | (-36.5, 6.4, -190.84) | Baffle surrounds and calibration panel read at 15–25 studs; side light remains plausible |
| 4. Master tape transfer | (-52, 5.5, -170) | (-59, 2.7, -179) | The recorder's usable front and stereo reels actually face the player, no overlap with control desk |

Use the **same viewpoints** at low/medium/high Roblox graphics quality, with
the flashlight off/on and before/after any powered-light transition.
Do not treat these as captured screenshots. Document visible seam
artifacts, reflective quality, imported mesh pivot differences and frame
time p50/p95 in the actual target PC before approving visual fidelity.

**Remaining non-negotiable gate:** an actual Roblox Studio first-person
run of Blackline with the imported models and generated fallback scene.
Source geometry is a necessary check, not proof of final appearance.

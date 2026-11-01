# Blackline VF-02 — an archive with a missing master

**Implemented in source:** November 1, 2026. Studio and first-person
appearance are **not yet qualified**. This is environmental art, not a new
mission or an extension of the current generator/fuse objectives.

## Why this location

The TapeArchive is a believable destination on the north side of Blackline:
it connects to the MasteringVault, an isolation booth, and the ViewingGallery.
Before this pass, generic shelves and case spines carried too much of its
visual identity. The generic shelf cluster is now suppressed in **this room
only**, replaced by the dedicated cabinet rather than duplicated by it. One authored storage fixture now gives the wing a readable
center of gravity without changing the existing 19-room plan or door graph.

**Visual sequence:** from the gallery, the player sees a tall, dark
professional master-storage bank against the north wall. At medium distance
seven circular archival reels are accounted for. Up close, the eighth
compartment is empty and its tab reads `08 / NOT RETURNED`. This is a
physical clue to Blackline's interrupted archival handover, not a quest marker.

## Concrete deliverables

- `src/server/Maps/BlacklineArchiveHero.luau`: a single non-interactive
  `ArchiveMasterEvidence` scene in TapeArchive; a deliberate 8-bay
  bank, narrow industrial rails, reel bosses, retention lips and legible
  serialized plates. The nonimported fallback is deterministic.
- `tools/build_signature_assets.py`: exports
  `BlacklineArchiveCabinet.glb`, an original image-mapped GLB with steel,
  dark lacquer, plated details, seven modeled multi-spoke reel flanges, and
  the actual printed archival identity as an embedded texture.
- `tools/studio/InstallImportedModels.luau`: accepts the new **optional**
  prefab, without touching any previously installed models.
- `tools/audit_hero_meshes.py` and `tools/validate_archive_hero.py`:
  enforce the GLB name/embedded-map requirement, bounded placement and the
  static art-only integration. The normal CI build includes the validator.

The existing ArchiveCart, MasteringVault transfer deck, documentary props
and functional room envelope remain unchanged. Only the TapeArchive's generic
shelf boxes are omitted; storage on other maps remains as before.
The new object deliberately requires neither a pickup nor an objective state.

## Placement and technical safety

Original TapeArchive envelope: **x -24..30, z -192..-160, height 15**.
Bank pivot: **(room.center.X, 0, z1 + 1.16)**, rotated 180 degrees so
the front faces into the room. The bank is **11.8 × 8.5 × 1.95 studs**
in the fallback. The rear is recessed into the uninterrupted *north* wall
and its front only protrudes a few studs. This keeps the east/west/south door
openings and the room's monster patrol positions as authored.

Every fallback detail is anchored, `CanCollide=false`,
`CanTouch=false`, `CanQuery=false` and `DisablePBR=true`.
Imported art inherits the same nonblocking behavior from PrefabLibrary.
No additional light, Sound, prompt, event, remote, objective, pathfinding
modifier or state machine is added. There is only one bank; no repeated
cabinet spam across all rooms.

## How to see it when Studio is available

Pull `chatgpt/studio-art-pass` and synchronize Rojo. The native fallback
will appear without new asset uploads. To substitute the more detailed
version, download the **Source Asset Export** artifact from the branch's
GitHub Actions run, import only `BlacklineArchiveCabinet.glb` through
Studio's 3D Importer, rename the root model accordingly, select it and run
`tools/studio/InstallImportedModels.luau`. Save the place after import;
the creator-owned MeshIds remain in Studio, not in Rojo text files.

Check it from the ViewingGallery entrance and from 5, 15 and 30 studs.
Inspect the large silhouette, the empty eighth compartment, text legibility,
cabinet material response, and any overlaps with default archive furniture.
Confirm the importer preserved the origin, the cabinet front faces south,
the Engineer is not blocked, and no missing shelf collider or invisible wall
conflicts with the imported model. Use both flashlight-off and
flashlight-on setups and measure memory, frame time and imported meshes.

## What this does not claim

The mesh is a **procedural, textured prototype**, not a final high-to-low
artist-baked photorealistic asset or proof of TTK Testing-quality visuals.
There has been no physical Roblox Studio check or rendering benchmark.
If it fails first-person review, refine this one object instead of
expanding the environment with extra props. The architectural map and
gameplay remain open to redesign.

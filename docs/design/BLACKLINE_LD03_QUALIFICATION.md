# Blackline — LD-03 routing, acoustic and quality qualification

**Status:** offline source and geometry checks implemented and passing; in-Studio
native pathfinding / sound qualification is still pending. The new Blackline
world is not production-qualified by static checks alone.

## Implemented fixes

### Redundant service access to power
The first physical graph made `Maintenance -> GeneratorRoom` a single critical
bridge. One blocked door disconnected the power objective. The generator now
has a second, fire-rated service access from Reception on their shared wall.
This is a credible emergency/staff bypass and provides an alternate player
route; it is not an invisible teleport. The loading dock remains a deliberate
single-access side bay, and the two audio-isolated booths remain deliberate
one-door dead ends. The authored graph now has **19 Areas, 27 traversal links
and 9 independent graph cycles**.

### Distinct sound occluders
`NoiseService.effectiveLoudness` previously advanced the ray 1.2 studs after
each hit. At grazing angles, this can count the same thick architectural wall
multiple times and attenuate sound too much. The source now excludes each
already-hit `CanQuery` object from subsequent raycasts, counting distinct
occluders only. This keeps the maximum attenuation cap and booth containment
rules. Actual ray behavior across mixed transparent material, doors and walls
must still be qualified in Roblox Studio.

### Offline topology / wall geometry
`tools/qualify_blackline_offline.py` independently checks:
- all authored door/window spans are within the Kit's atomic split wall bands;
- no two portals share a wall with an overlapping leaf/window cutout;
- no single interior portal can disconnect the mandatory entry, generator,
  fuse box or tape-deck objective;
- all authored rooms are connected; all dead ends are intentional;
- observation glazing blocks sound and decorations do not create artificial
  noise occlusion; the acoustic occluder counter preserves distinct hits.

These are **topology and source checks**, not a replacement for Roblox's
runtime PathfindingService, door geometry or line-of-hearing tests.

## Native Roblox Studio probe

`tools/studio/QualifyBlackline.luau` is a developer-only, read-mostly
Command Bar script. Use it in the **server-side Command Bar during F5 Play**,
not Edit. It does not teleport players, change doors or rewrite the map.

It checks actual generated Area/door/booth/objective parts and performs native
PathfindingService agent path queries for:
- every 27 connection;
- each non-entry Area's return path to Reception;
- reception approaches to GeneratorRoom, PatchBay and ControlA;
- sound-containment behavior for each *currently closed* booth;
- observation windows' `CanQuery` and collisions.

It outputs `[LD03]` results. **A successful path query does not prove the
Engineer will physically open every door or move through the route**. His
animation, collision, path retry behavior and acoustics must still be tested in
the live game.

## Hands-on acceptance protocol (when Windows Studio is available)

1. Pull `chatgpt/studio-art-pass` and synchronize Rojo. Preserve the installed
   `ServerStorage.ArtLibrary` and six `MaterialService` variants.
2. In Studio select the **studio / Blackline** match map; start F5 Play.
3. Run the complete `tools/studio/QualifyBlackline.luau` in the **Server**
   Command Bar. Save the full Output, particularly `[LD03] FAIL`.
4. Enable `Config.DEBUG_AI = true` temporarily in a development test and
   observe Engineer movement from Reception through the large LiveHall, across
   staff/service bypasses, into each recording booth, and into the archive.
5. Close and open all booth doors, and generate noises inside and outside.
   Confirm containment only while sealed, and distinguish physical sounds from
   microphone/recorded sound logic.
6. Perform a full solo/co-op objective sequence: start power, gather three
   distinct fuses, install at PatchBay, activate ControlA tape and escape via
   familiar reception. Repeat with the Engineer at critical passages.
7. Record exact door IDs and Area names for any stuck point. Compare physical
   pathing and pursuit to the offline path expectations.
8. Inspect close/medium/far door/texturing, rendering costs at 1080p and
   high/medium quality, and total memory against
   `docs/art/TTK_VISUAL_QUALITY_TARGET.md`.

## Remaining risks (not hidden)

- Physical doorway openings may be valid mathematically yet blocked by
  furniture, a swing animation, ceiling changes or Roblox navigation tiles.
- The existing monster path replan/open-door sequence may need improvement
  after live traces. It has not been modified or independently qualified here.
- Story/signage props can overlap important sightlines and need first-person
  acceptance. All additions to StoryProps intentionally have no collision.
- The visual benchmark is *TTK Testing*-class asset quality; current custom
  GLB prototypes and synthesized PBR materials still require a serious
  artist-authored mesh/material pass.

**Next gate:** real F5 [LD03] diagnostics and first-person movement plus sound
scenarios. Only after this stage should we call level navigation/acoustics
qualified and proceed to full VF-01 flagship-room visual upgrades.

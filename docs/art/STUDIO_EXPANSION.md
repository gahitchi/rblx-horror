# Recording studio — spatial expansion and navigation handoff

**Owner:** ChatGPT (environment/layout); Claude owns gameplay services.  
**Source:** `src/server/MapBuilder.luau` and `src/server/ArtBuilder.luau`.  
**Contract:** `docs/MAP_CONTRACT.md`.

## What changed

The first greybox remains as the recognisable heart of the studio (reception, control A/B, live room, three isolation booths, archive, break room, stairs, generator and electrical room). This expansion adds **12 named Areas** without introducing teleports, jumps or an inaccessible second floor. It gives the Engineer new patrol destinations and players genuinely alternate movement routes instead of simply lengthening one hallway.

| New area | Approx. X range | Z range | Y / height | Routes and risk |
| --- | --- | --- | --- | --- |
| RearGallery | -40 to 40 | -146 to -130 | 0 / 12 | Two doors back into live floor, loop 1 |
| MasteringSuite | -40 to -5 | -178 to -146 | 0 / 12 | Gallery and central spine exits |
| NorthSpine | -5 to 5 | -178 to -146 | 0 / 12 | 10-stud central link connecting two rooms and vault |
| MachineShop | 5 to 40 | -178 to -146 | 0 / 12 | Gallery and central spine exits |
| TapeVault | -18 to 18 | -201 to -178 | 0 / 12 | One doorway, intentional dead end |
| EastServiceHall | 70 to 90 | -130 to -70 | 0 / 12 | Two entrances to archive, loop 2 |
| LoadingBay | 90 to 122 | -130 to -90 | 0 / 12 | One doorway, intentional dead end |
| QuietStore | 90 to 122 | -90 to -70 | 0 / 12 | One doorway, intentional dead end |
| ServiceTunnel | -46 to -34 | 10 to 43 | -14 / 13 | 12-stud main basement branch |
| CompressorRoom | -76 to -46 | 14 to 43 | -14 / 13 | One doorway, dead end |
| ColdStore | -34 to -4 | 14 to 43 | -14 / 13 | One doorway, dead end |
| BoilerRoom | -55 to -25 | 43 to 66 | -14 / 13 | One doorway, furthest dead end |

**Connections (walking routes)**

- Loop 1: LiveRoom → RearGallery → MasteringSuite → NorthSpine → MachineShop → RearGallery → LiveRoom. Two separate live-room connections allow a player to circle the Engineer.
- Loop 2: Archive → EastServiceHall (north door) → EastServiceHall (south door) → Archive. Escape is possible in either direction.
- High-risk branch: ElectricalRoom → ServiceTunnel → CompressorRoom, ColdStore or BoilerRoom. Each side room has a single exit.
- Hide/shelter: mastering and workshop open-bottom tables and industrial cover, plus large solid equipment/pallets at room edges. Collidable furniture, not art decorations, provides actual occlusion.

## Contract invariants

- Every added room has an `Areas/<Room>/Bounds` and at least two `Spot` markers except compact originals that already have one.
- The existing `MapContract` reads them. No MonsterService special-casing.
- Doors use ordinary anchored Parts with `Kind="normal"`; leaf sizes are `DOOR_W - 0.2` (5.8 studs) inside six-stud or wider openings, preserving DoorService's expected clearance.
- All new ground-floor ceilings are 12 studs high; basement extension is 13 studs high; all new corridors are at least 10 studs wide.
- Added 9 new `FuseSpot` markers (21 total) and 7 new `Speaker` markers (13 total).
- Added 8 generator-controlled lights through `PowerLights`.
- All visual details added by `ArtBuilder` are non-solid and `CanQuery=false`; they must not obstruct audio/pathfinding raycasts.
- The two rear live-room exits are deliberately clear of opaque acoustic foam.

## Integration risks that must be tested in Studio

1. **Paths:** turn `Config.DEBUG_AI` on and watch the Engineer enter the rear gallery through both doors, use the mastering/shop-to-spine doors, and traverse the archive service loop.
2. **Basement:** run the Engineer from the electrical room through the extension. A path failure or stuck state means adjust collision, ramp continuity or the new door transitions before merging.
3. **No accidental bottlenecks:** check the existing archive shelves (now 10 studs wide) and the narrow central spine in both directions.
4. **Spawns and markers:** confirm no `[Map] ERROR`/unusable marker; every new area spot is on solid flooring and not on top of a cabinet.
5. **Hiding:** verify the open-bottom worktables can actually shelter a Roblox character; adjust tabletop height if avatars clip.
6. **Audio:** test wall dampening and radio crackle in the longer building; `CanQuery=false` art should not affect raycasts.
7. **Visibility and performance:** inspect the basement, two new loops, actual exit signage and all decorative geometry with one and four players.
8. **Completion:** reach the generator, collect three fuses across the expanded pool, play the tape and escape. Confirm danger remains fair at 20-minute round length.

## Future scale

A second floor is intentionally deferred: vertical circulation has higher navigation/pathfinding risk than lateral loops. Do not add climb-only routes until navigation and sound tests pass.

## Status

**Code built and committed; runtime validation not yet performed.** Neither a successful Rojo build nor a Studio gameplay pass can be asserted from the GitHub-only authoring environment.

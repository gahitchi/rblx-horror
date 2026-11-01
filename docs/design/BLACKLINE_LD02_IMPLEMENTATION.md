# Blackline LD-02 — authored, interconnected architectural whitebox

**Status: implemented in source, automated checks passed; Roblox Studio qualification pending.**
**Map id:** `studio`.
**Files:** `src/server/Maps/BlacklineLayout.luau`, `Kit.luau`,
`StoryProps.luau`, `docs/design/blackline_graph.json`.

## Design identity

Blackline is a converted commercial recording campus with a quiet mastering
wing, an expanded high-ceilinged live floor, a public arrival concourse and
electrical/maintenance circulation. Its emergency incident left traceable
records in workspaces, rather than anonymous jump-scare props. The architecture
takes *principles* from ambitious interconnected institutional environments
(monumental brutalism, physical wayfinding, legible transitions, return routes,
world-as-character) while using **wholly original** signage, organization, lore,
names, material palettes and bespoke equipment.

The plan preserves a readable **worldly logic**: visitors enter from reception;
staff reach control and recording from the gallery; electrical personnel can
circle through the separate service wing; tape archives sit beyond monitoring
and mastering rooms; loading is attached to the power/services side rather
than opening onto the public foyer.

## Actual playable topology, viewed roughly north-to-south

This diagram reflects physical positions; **edges in the illustration do not
automatically imply a door**. The authoritative door schedule is the
`links` table in `BlacklineLayout.luau` and the JSON manifest.

```text
NORTH / ARCHIVE & ISOLATION WING
+-------------+---------------+----------------+--------------+
| ISOLATION W | MASTERING      | TAPE ARCHIVE   | ISOLATION E  |
+-------------+---------------+----------------+--------------+
| DRUM ROOM   | VIEWING / ARCHIVE GALLERY       | SERVICE GAL  |
+-------------+---------------------------------+--------------+
| CONTROL A   |                                 | TRACKING     |
+-------------+                                 +--------------+
| CONTROL B   |       LIVE HALL (24 HIGH)       | PATCH BAY    |
+-------------+                                 +--------------+
| STAFF PASS. +---------------------------------+ MAINTENANCE  |
+-------------+      STAFF GALLERY              +--------------+
| LOUNGE      +---------------------------------+ GENERATOR    |
+-------------+          RECEPTION              +--------------+
                  [FRONT ENTRANCE]               | LOADING DOCK |
                                                +--------------+
SOUTH / PUBLIC APPROACH
```

**Key geometry changes:** 19 authored rectangular room envelopes, not the
old standardized 4x5 grid. The LiveHall is about 102 by 68 studs with a
24-stud ceiling. Control rooms, booths and service galleries have their own
dimensions and ceiling heights (14–20 studs). Shared walls are split at
all real boundary intersections, built once, and contain physically verified
8-stud doors, 14-stud open thresholds or 9-stud viewing windows.

The building spans x=-116..84 and z=-192..34. There is also an exterior apron
at the front exit. No floor-to-floor traversal is implemented yet because the
current Engineer navigator is not qualified for complex vertical movement.

## Navigation / tension

There are 19 areas, 26 authored portal connections and **8 independent graph
cycles**. This supplies meaningful alternate loops, including a public/staff
approach to generator power, a production-to-service return through PatchBay,
and multiple routes around the LiveHall. The two acoustically sealed isolation
booths each have **one** opening; entering a booth is a conscious tradeoff.

The objective contract remains unchanged:
- **Reception:** player entry, familiar ending and single front exit.
- **GeneratorRoom:** noisy three-pull startup at the edge of service circulation.
- **PatchBay:** fuse installation and electrical route reveal.
- **ControlA:** 20-second emergency tape broadcast / final commitment.
- **TapeArchive:** Engineer start, physically separated from the entrance.

Existing fuse placements are drawn from 12 intentional rooms. All rooms are
connected by portal edges, and no new jumps, lifts, key locks or invisible
teleports were added. Observation glass separates light/sight from actual
traversal; acoustic blocking remains governed by `CanQuery` and sealed booths.

## Environment and story beats

Visual hierarchy:
1. **Reception:** tall Blackline identity wall, actual facility directory,
   guest check-in, terminal, visitor instructions.
2. **StaffGallery:** production vs engineering directional wayfinding, with
   a recognizable framed approach to the tall LiveHall.
3. **LiveHall:** a 24-stud interior with overhead hanging acoustic baffles,
   lighting/service structure, cable routing and plausible recording treatment.
4. **Control A/B:** session change logs, failed channel-08 investigation,
   backup patch panel, VU/console equipment and clock.
5. **MasteringVault / TapeArchive:** isolation warnings, media inventory, a
   deliberately missing reel, catalog drawer labels and a proposed reel cart.
6. **PatchBay / Maintenance / ServiceGallery:** diagram labels, shift handover
   at 03:17, signal racks, intercom and work-order records.
7. **Generator / LoadingDock:** plant operating procedure, exhaust housings,
   shipping crates, evidence of a halted media transfer.
8. **Isolation rooms:** authentic silence/seal protocol signs and a genuine
   one-door risk/reward layout.

The repeated 03:17 incident and channel 08 references are deliberate *narrative
breadcrumbs*. They imply a chronology, so the player's reconstruction of the
event follows the order in which staff would have discovered the problem.
Avoid turning these into direct exposition or a collectible log dump.

**Facility state:** some "ON AIR" and electrical indicators now physically
use `PowerLights`. They respond to the *existing generator-on state* instead
of operating on an unrelated timer. No strobe/flicker loops were added.

## Art and original meshes

Four more original multi-material, import-ready GLBs were added to the exporter:

| Model | Intended room | Story purpose |
| --- | --- | --- |
| `ReceptionTerminal.glb` | Reception | Period-correct visitor registry and arrival ritual |
| `TapeArchiveCart.glb` | TapeArchive | Classified reel storage, cataloguing and maintenance |
| `ServiceIntercom.glb` | Maintenance | The chain of communication that failed during the event |
| `StudioWallClock.glb` | ControlA | The interrupted session's timing and recording culture |

These supplement the previous nine models for **13 total**. The existing
`ServerStorage.ArtLibrary` models remain valid, and the new four are
**optional**. There are safe procedural fallbacks until the user can import
them via Studio; no fake Roblox asset IDs are assigned and no old model
must be reinstalled.

The new meshes are **original generated assets**, not licensed photogrammetry
or scans. Their Blender/Studio scale, normals, import materials and appearance
require confirmation. Geometric detail alone is not a promise of AAA realism.

## Automated acceptance completed

- Static room geometry, ceiling minima, nonoverlap, physically adjacent
  links and all-room connectivity checked.
- At least 6 independent loops, both one-door soundproof booths,
  12 fuse candidates and named mandatory objective rooms checked.
- Design JSON cross-checked against the **actual** authored Luau room bounds
  and portal connections.
- Noncollision/nonqueryable storytelling geometry and powered light wiring
  checked.
- Original mesh exporter produces all 13 GLBs in GitHub Actions; core
  nine remain installable without the new extras.
- Selene and Rojo serialization of match and hub pass in CI.

## Qualification gates not yet completed (mandatory)

**Architectural:** inspect thresholds for visual obstruction; check two doors
plus a window on the same wall, ceiling-height transitions, floor seams,
projection scale and no clipping at each gallery connection.

**Movement:** Studio path checks with DEBUG_AI from every named room to
Reception, GeneratorRoom, PatchBay and ControlA; verify monster can open
closed doors, move through 14-stud public thresholds and cross all 26 edges.
Check booths cannot be path-bypassed.

**Gameplay:** start, generator, three different fuse placements, PatchBay,
ControlA tape holdout, multiple return routes, exit and replay vote. Verify
first-time players can interpret signage and not get lost with no map overlay.

**Visual/art:** compare macro volume and human scale; review original GLBs,
repeated texture tiling, imported prefab pivots, small-text legibility, and
Realistic lighting at high and medium quality. Verify world feels inhabited,
not just that it has numerous Parts.

**Performance:** memory and actual p50/p95 frametimes on a real Studio
client; especially review the very large LiveHall's overlapping lights,
multi-part acoustic structure and GLB draw calls.

**Outcome:** LD-02 is an implemented and source-validated **whitebox with
story dressing**. It is not yet a production-complete level. Do not claim
LD-03 through LD-06 done without actual playtest data.

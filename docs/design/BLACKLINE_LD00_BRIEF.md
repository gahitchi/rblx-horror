# Dead Air — Blackline recording complex: authored level-design brief (LD-00)

**Historical design basis (LD-00):** this document records the initial conceptual proposal.
**Update:** Blackline's actual nonuniform 19-room, 26-connection implementation now lives in
[BLACKLINE_LD02_IMPLEMENTATION.md](BLACKLINE_LD02_IMPLEMENTATION.md) and
`src/server/Maps/BlacklineLayout.luau`. Some adjacency/room scheduling proposals below
were revised during real geometry implementation. The runtime code and synchronized
`docs/design/blackline_graph.json` are authoritative. Studio qualification is pending.
**Target map ID:** `studio`. **Owner branch:** `chatgpt/studio-art-pass`.
**Priority:** develop ONE coherent flagship map before applying its lessons to the radio station or foundry.

## 1. Why we are replacing the generic room grid

`src/server/Maps/Layouts.luau` currently applies nearly the same 4-column, 5-row
navigation topology to all three maps. The room names and props differ, but the
building still feels mechanically assembled from identical rectangles. A credible
facility must have architecture driven by **workflow, acoustic isolation, equipment
and emergency access**. Horror pacing should emerge from how its architecture is
used, rather than from random passages or repeating dark rooms.

Keep the current runtime geometry operational as a **baseline test fixture** until
a complete authored replacement passes its navigation, acoustics and playtest gates.
Do not prematurely delete a playable layout.

## 2. Fiction and physical justification

**Blackline** began as a late-1970s commercial recording studio, expanded through
the 1990s with control suites and a magnetic-tape archive. A later corporate retrofit
installed private acoustic-research booths and redundant electrical infrastructure.
The facility was evacuated after an audio event that corrupted its last emergency
recording; maintenance engineer equipment remains, as does **the Engineer**.

This single history explains the whole playable space:

- Reception and public gallery belong near the front facade and observation glass.
- Live floor sits in the core, with drum and isolation booths directly beside it.
- Control rooms face the live floor through sealed observation glazing.
- Mastering and tape archive sit in the quiet wing, away from loading noise and heavy
  air handling. Original door seals and acoustic bulkheads still function.
- Generator, transformer/patching and maintenance access follow the service spine and
  have believable cable-tray continuity.
- Loading faces the rear service route, not the public entrance.
- Emergency exit is at the entry vestibule; the magnetic alarm tape unlocks it.

Each transition should visibly show **age, use, purpose and a plausible retrofit**.
Do not distribute random grime, machinery or scary props uniformly.

## 3. Core experience contract

1. **Observe:** players find an intelligible facility with two or three distinct
   destinations from the entry, not a flat field of 20 identical doors.
2. **Commit:** crossing from public rooms into production and service areas has
   readable thresholds, visible consequences and limited retreat options.
3. **Listen:** hearing the Engineer matters; chase survival depends on turning
   corners, splitting routes, controlled noise and real sound insulation.
4. **Choose:** each major objective has a legible primary path and an alternative
   that carries an actual risk: louder, longer, tighter or less visible.
5. **Return:** the tape causes a deliberate holdout, then a memorable return toward
   the front exit through spaces the player previously learned.

**Anti-goals:** arbitrary locked-key mazes, a single long hallway of doors, false
jump-scare triggers at every corner, confusing nonfunctional architecture, acoustic
"safe zones" that trivialize the monster, or fuses placed in identical shelves.

## 4. Spatial program (proposed 19 Areas, identity before coordinates)

| Area | Everyday building function | Player/narrative role | Architectural signature |
| --- | --- | --- | --- |
| Reception | Check-in and visitor administration | Start and escape destination | Glazed vestibule, reception desk, company identity |
| Lounge | Waiting and staff break | Early orientation, optional refuge | Lower ceiling, worn upholstery, trophy shelves |
| StaffGallery | Central staffed circulation | First major navigation landmark | View of live room, room-number signage |
| StaffPassage | Staff-only back route | Low-light alternative to the gallery | Fire doors, low utility ceiling |
| LiveHall | Main recording floor | Major central landmark and risky traversal | Tall volume, stage cues, acoustic reflectors |
| ControlA | Main console/mix position | Tape-deck objective and late holdout | Window into live hall, mixing desk |
| ControlB | Secondary monitor room | Alternative bypass and foreshadowing | Smaller window, patched equipment |
| DrumRoom | Separate high-noise studio | Risky fuse position, localized acoustic shift | Bass traps, decoupled floor |
| TrackingStage | Auxiliary tracking room | Secondary loop around live floor | Instrument screens, overhead rigging |
| ViewingGallery | Client observation/walkway | Visual-only sightline and route choice | Sealed panes, directional wall signs |
| PatchBay | Electrical/audio patch distribution | Fuse installation objective | Dense cabling, labeled service panels |
| MasteringVault | Quiet final-mix suite | Restricted archive approach | Dry acoustic treatment and thick seals |
| TapeArchive | Media storage | Evidence and high-risk searching | Dense reels, filing order, missing labels |
| ServiceGallery | Rear service circulation | Flanking/backtrack alternative | Pipe trunk and maintenance identifiers |
| Maintenance | Repairs, workshop, spare parts | Tension reset and route junction | Oil-stained benches, tools, locked lockers |
| GeneratorRoom | Power plant | Loud generator sequence | Accessible starter; exhaust and ductwork |
| LoadingDock | Rear delivery zone | Alternate service traversal and back-of-house history | Pallet bay, service shutter |
| IsolationWest | Small vocal isolation booth | Intentional risky dead end, silence mechanic | Double seals and line-of-sight restriction |
| IsolationEast | Independent isolation booth | Second, distinct dead-end choice | Different acoustic treatment and viewing angle |

This is a **functional room schedule**, not a command to pack all rooms into equal
cells. Smaller areas may merge or split after path, acoustic and spatial testing.

## 5. Authored circulation diagram (topology proposal, not world-space geometry)

`--` is an **actual traversal connection**. Observation windows are documented
separately and **are not** graph edges.

### Public to production

```text
EXIT <= Reception -- StaffGallery -- LiveHall -- TrackingStage -- IsolationEast
           |              |             |                |
         Lounge       ViewingGallery   DrumRoom -- IsolationWest
                          |             |
                     MasteringVault    ControlA -- ControlB
                          |               |         |
                       TapeArchive      PatchBay -- StaffPassage
                          |               |          |
                     ServiceGallery -- Maintenance -- GeneratorRoom
                          |               |
                       rear service ---- LoadingDock
```

**Diagram is conceptual, not a final coordinate map.** A graph validator must
maintain the actual designed edges below, not infer connectivity from visual layout.
The diagram may omit a cross-link; the edge schedule is authoritative.

**Proposed undirected edges:**

```text
Reception--StaffGallery, Reception--Lounge,
StaffGallery--LiveHall, StaffGallery--StaffPassage,
StaffGallery--ViewingGallery,
LiveHall--ControlA, LiveHall--DrumRoom, LiveHall--TrackingStage,
ControlA--ControlB, ControlA--PatchBay,
ControlB--TrackingStage, ControlB--StaffPassage,
TrackingStage--IsolationEast,
DrumRoom--IsolationWest,
ViewingGallery--MasteringVault,
MasteringVault--TapeArchive,
TapeArchive--ServiceGallery,
ServiceGallery--PatchBay, ServiceGallery--Maintenance,
PatchBay--Maintenance,
Maintenance--LoadingDock, Maintenance--GeneratorRoom,
GeneratorRoom--StaffPassage
```

Do not create two doors in a booth. Keep isolation zones at degree one; they are
**optional risk/reward acoustical shelters**, not mandatory objective corridors.

**Gates:** The front door is the only scripted mission lock. Ordinary interior
doors can be opened by players or the Engineer. Any new custom lock or bulkhead
requires corresponding service and pathfinding work, not an art-only shortcut.

## 6. Nonrandom route design

**Entry -> power.** Reception / StaffGallery / StaffPassage / GeneratorRoom is a
short, comprehensible route, but the acoustic threat from starting the generator
must make players reconsider returning the same way. An alternative route through
ControlB/TrackingStage/LiveHall offers a different exposure profile.

**Power -> fuses.** Keep fuse candidates distributed among public-facing, production
and service wings. The existing round code chooses three distinct `FuseSpot`
markers randomly: randomness should choose from **curated intentional placements**,
not floor scatter. Use a placement manifest with approximate concealment, visibility,
route risk, role and object support. Establish no inaccessible fuses and test every
three-item combination considered feasible under the time limit.

**Fuses -> patch.** PatchBay must be identifiable by real cable infrastructure
through the building, not a floating waypoint; approach options should be obvious
once players understand the service system.

**Tape -> escape.** ControlA is a deliberate tactical commitment. Starting the tape
broadcasts for 20 seconds, and the exit opens afterward. Provide more than one
meaningful return route, broken lines of sight, and readable directional signs;
avoid a single mandatory death funnel.

**Hearing.** The monster is blind, reacts to emitted noise, can investigate, search,
hunt, retreat and open closed interior doors. The studio must contain separated
sound volumes, moments of audible long-range transmission, and surfaces that let
players learn how quiet behavior changes pursuit.

## 7. Architectural visibility, acoustic and collision intent

- Every transparent observation pane gets a documented **visual-only** relation.
  If sound should transmit, its `CanQuery` and any sound occlusion logic must
  agree; a soundproof glass wall should block or dampen sound.
- Two or more visual landmarks must be readable from circulation: live-room glass
  and a distinctly color-coded service spine are the starting proposals.
- Avoid long unbroken straight routes where the Engineer's line of travel is
  predictable. Long sightlines are used selectively to foreshadow a decision.
- Main traversable paths should be **at least 8 studs usable clearance**; service
  pinch points must stay above the game's hard 6-stud minimum. Door leaves must
  provide at least 6x9 traversable openings and correct hinge swing clearance.
- The Engineer currently paths at radius 1.5, height 8.5, no jumping or climbing.
  Any change to vertical navigation requires a tested ramp/path contract first.
- All small set dressing must be `CanCollide=false` and `CanQuery=false`.
  Deliberate physical cover or sound occluders must be reviewed and tested.
- Do not add vast decorative ceilings/overlapping glass that interfere with sound
  raycasts or swallow flashlight beams.

## 8. Spatial / encounter pacing (targets, not proven timings)

**Phase 0: arrival and recognition.** The initial entry gives the player a room
hierarchy and basic navigation landmarks. A service route and production route
present different threats rather than an unexplained corridor fork.

**Phase 1: first commitment.** Generator emits 3 pulls, then persistent hum.
The current Engineer arrival delay is 15 seconds and Director grace is 45 seconds;
design under the *existing* behavior, not a presumed permanently safe introduction.

**Phase 2: fuse hunt.** The monster's acoustic presence can steer players toward
less familiar branches, while visual clues and signage prevent aimless searching.

**Phase 3: final transmission.** Once fuses are installed, ControlA's emergency tape
plays for 20 seconds; sound is intentionally enormous. Define readable escape paths.

**Phase 4: exit.** Familiar spaces become newly dangerous. The exit is where the
player began, now experienced as a deliberate reversal of the opening.

Measure first-play completion, confusion and failure rates from real tests;
do not prescribe a universal encounter schedule before evidence exists.

## 9. Construction gates (strict order)

**LD-00 — narrative and room schedule.** Confirm facility purpose, target mood,
essential landmarks and room workflow; review adjacency with the goal loop.

**LD-01 — 2D functional floor plan.** Draw nonuniform room envelopes, corridors,
door orientations, true/false visual connections, entrances, raised sections and
emergency access. Check adjacency and access before adding props.

**LD-02 — physical whitebox.** Implement one map with structurally truthful halls
and corners; wire it to MapContract. Keep every room accessible and preserve
fuse/generator/tape/exit and booth semantics.

**LD-03 — navigation / acoustic qualification.** Validate full-room patrol reach,
closed/open door transitions, player chase/retreat, occlusion, booth seals, edge
cases and every critical circuit. Record p95 path failure rate, graph dead ends,
traversal times, and safety escapes. No aesthetic additions until baseline works.

**LD-04 — readability and tension.** Test with first-time players and remove
unjustified confusion. Signage, landmarks, lighting and audio should teach spatial
structure without overt UI exposition.

**LD-05 — environmental storytelling / hero art.** Dress rooms according to
plausible use and retrofit history. Give each distinct wear patterns, bespoke
props and material response. No random junk distribution.

**LD-06 — performance and final qualification.** Capture client FPS, p50/p95
frametimes, streaming/memory costs and shadow/light burden on high and medium
quality. Preserve reversibility and a fallback map until acceptance.

## 10. Acceptance evidence required before replacing the current map

- A reviewed 2D floor plan and room adjacency diagram, matching **actual geometry**
  rather than just labels.
- Generator, fuse box, tape deck, front exit and every fuse site reachable and usable.
- At least two genuinely different routes across the main play space, with
  meaningful risk tradeoffs; no accidental choke from decorative clutter.
- Zero unintentional dead ends, no unreachable authored Areas/Spots, and valid
  routes while doors are closed and opened by the Engineer.
- Isolation booth acoustics and chase behavior verified in Studio.
- Coherent room identification by first-time players without relying on GPS arrows.
- Recorded round timing, navigation debug logs and performance captures.
- Explicit design review before any layout is treated as final or used as a template
  for the radio station and foundry.

## 11. Implementation scope / deferred decisions

Current `Layouts.luau` and `Kit.luau` remain active until LD-02 is designed and
built. The proposed topology may require non-grid coordinates and custom wall
modules; that is expected. Do not force architectural realism into the old shared
5x4 template merely to preserve quick implementation.

**Need visual review before actual geometry change:** floor plan, preferred
industrial-vs-studio atmosphere, vertical complexity, target typical match length,
and initial solo/co-op difficulty. The code contract remains the ground truth, and
changes to the contract require matching tests.

This brief exists to make the *next* development step accountable, not to claim
a level has already been completed.

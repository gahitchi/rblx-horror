# Studio v2 — recording house redesign / first playable

Build: `0.7.6-studio-v2` on `chatgpt/studio-v2`.
The default match place builds `src/server/Maps/StudioGroundFloor.luau`.
The older `MapBuilder` greybox is retained only as an error fallback.
The contract is still **v2**: `docs/MAP_CONTRACT.md` and
`src/server/MapContract.luau` are unchanged.

## Why this is a recording house, not a grid of level rooms

The 1987 engineer ran a working town recording house, not a corporate research complex.
A guest could arrive, visit reception, sit or use a bathroom without crossing tracking.
Musicians go from reception and lounge into a sound-lock/recording wing. The live hall
is where musicians play; three isolation booths open directly off its back wall.
Control A is alongside it and looks through a substantial tracking window. Control B
is the editing / backup desk down the production side. The archive is behind Control A
near its adjoining mastering suite. Loud machine racks, instrument storage and load-in
sit on the east service spine; staff have a separate WC and janitor closet. The
navy's quarantined stairwell remains visible from the front hall, while a sealed lift
shaft is reserved at the back loading bay.

Reference logic (not a copy of any plan):

- Red Rock Recording floor plan: public lounge/baths alongside the control room
  and a sound lock between public and live/iso spaces:
  https://redrockrecording.com/studio/floor-plan
- Miloco, Dock Street Studio floorplan: reception, kitchen, control, live and booth
  arranged around a compact studio circulation:
  https://milocostudios.com/studios/dock-street-studio/floorplan/
- Creative Victoria technical design guide: live room, booths, machine room and
  carefully separated acoustic/service uses:
  https://creative.vic.gov.au/__data/assets/pdf_file/0005/2244803/Creative-Space-Design-Guides-PART-3-Sound-recording-studio.pdf

This is **functional architectural realism**, not the parked PBR/anatomy pipeline.
The rooms remain stylized, low-part-count, phone-readable Roblox geometry.

## Floor programming

| Wing | Rooms | Purpose |
| --- | --- | --- |
| Public (south) | Reception, EntryHall, PublicWC, BreakRoom, Stairwell | Arrival, waiting, guest bathroom; sealed naval route seen from entry |
| Production (west/centre) | ControlA, ControlB, MasteringSuite, TapeArchive, LiveHall | Engineer workflow, dubbing and chapter objective landmarks |
| Acoustic | IsolationWest, IsolationVocal, IsolationDrums, SoundLock, ViewingGallery | Three directly linked booths, buffered entrance, studio sightlines |
| Service (east/back) | MachineRoom, ServicePass, ServiceHall, LoadingBay, StaffWC, JanitorCloset, InnerHall, StaffPassage | Instrument delivery, racks, staff needs, service circulation |

**23 Areas / 30 authored links.** All 12 chapter 1 objective markers, four reel shelves,
at least six hiding spots, optional tapes, speakers, and throwables are kept.

## Last Call topology

**Short path (before closure):**
Control A → Control B → [short shutter] → Break Room → Reception → front doors.

**Surviving escape path:**
Control A → Live Hall → Sound Lock → Viewing Gallery → Inner Hall →
Entry Hall → Reception → front doors.

A second raised quarantine shutter guards the Loading Bay service connection. No
exit exists through the loading bay, basement, flat or service lift.

## What to playtest next

1. Run `rojo serve` from the match project (`default.project.json`) and
   confirm `Config.VERSION = 0.7.6-studio-v2`.
2. Read every `[Map]` Output line. **Any ERROR is a stop**: an invalid generated
   map will be replaced by the fallback greybox. Confirm the `MapName` attribute
   reads Wrenmouth Recording House / Chapter 1.
3. Walk public paths: Reception → Entry Hall → Public WC and Stairwell;
   Break Room → Staff Passage → Staff WC; Service Hall → Janitor Closet.
4. Walk the control/live workflow and each booth. Confirm door prompts,
   acoustic booth noise isolation, and clear views through the glass.
5. Confirm every chapter 1 objective is interactable (8 studs), all four
   signed reels can be picked up and all hiding containers can be used.
6. With `Config.DEBUG_AI = true`, watch the Engineer navigate control rooms,
   archive aisle, toilets, sound lock, service spine and each hiding Spot.
7. Trigger Last Call: the short shutter must drop, Control A must still have
   a navigable route through Live Hall to Reception, and the Exit Zone must work.
8. Check that the upper stair ramp can be navigated without snagging on
   decorative no-collision treads; basement and flat doors should remain shut.
9. Test dead/woken/red lighting and speaker sound from a phone-size viewport.

The graph and objective names were **source-reviewed**; Studio build, Luau
language-server, and Roblox gameplay/playfinding tests have **not** run in this
environment. Report actual geometry or navigation failures before any
large-scale prop-dressing pass.


## 0.7.3 environment-dressing pass

The room graph and contract are unchanged; visuals are additive and source-controlled
in five small modules, installed by `StudioGroundFloor.build()`:

- `Maps/StudioDecorKit.luau`: native part helpers for timber furniture,
  printed signs, tape reels, analogue racks, doorside pieces and upholstered seating.
- `Maps/StudioProductionDetail.luau`: multitrack transport, VU bridge, console
  faders, monitor speakers, archive cassette rows, mastering desk, electric keyboard,
  amplifiers, live-room drum kit and vocal booths.
- `Maps/StudioServiceDetail.luau`: reception desk contents and seating, period
  notices, staff lounge and kitchen, ceramic/tiled restrooms, janitor's closet,
  navy conduits, freight cases and loading-bay hardware.
- `Maps/StudioArchitectureDetail.luau`: timber skirting and ceiling ribs,
  glazing mullions, door frames, quarantine frame and front porch signage.
- `Maps/StudioStoryDetail.luau`: choir/family photographs, a memorial arrangement,
  session notices, maintenance records, plants and sealed stairwell clues.

The original **twelve chapter objective parts** are not replaced, moved or renamed;
the extra visuals sit in `Map.Props`. The original `Map.Doors`, `Map.HidingSpots`,
`Map.Booths`, `Map.Shutters` and `Map.Areas` remain authoritative. Added accent
lamps are grouped in `Map.Lamps`, so dead/woken/red are controlled by the existing
script. Most decorative parts have `CanCollide = false` and `CanQuery = false`;
some original large objective cabinets remain solid.

### Priority smoke test (before deciding the next art pass)

1. Verify `0.7.6-studio-v2` in the server Output and that `Workspace.Map`
   says `Wrenmouth Recording House / Chapter 1` (not the fallback greybox).
2. At the start, the room must be dark. Load a reel to wake dim warm lamps and
   confirm red emergency lighting after the second shock. Inspect in phone view.
3. Check **front-door entry/exit** and that the new porch/signs do not obstruct
   the Exit Zone. Test the welded mail slot when the door swings open.
4. Walk to all twelve objective prompts, try retrieving a reel from each labelled
   shelf, and complete a whole round, including the final cassette escape.
5. Check each of the three isolation booths, restrooms, janitor closet,
   loading bay and stairwell: no snags, no invisible collision and no
   distracting secondary prompts.
6. With `Config.DEBUG_AI = true`, watch the monster enter every room and
   reach hiding spots. In Last Call, the short shutter must drop while the
   live-hall and sound-lock route stays viable.
7. Watch FPS, memory and part/render cost on a phone-size view. If the new art
   is too heavy, optimize repeated decor parts before adding any new rooms.

**Not run here:** Roblox Studio simulation, Rojo build, Luau language-server
analysis and device profiling. These must be done on Gabriel's machine.


## 0.7.4 optional Creator Store asset upgrades

The default map and earlier visual dressing are unchanged. The build now
supports **approved** static geometry stored in
`ServerStorage/StudioApprovedAssets`. None is bundled with GitHub or
fetched from the Store at runtime. Empty or unavailable slots keep the
native visual version.

Full sourcing, model-review and Studio staging steps: [STUDIO_V2_ASSETS.md](STUDIO_V2_ASSETS.md).
The edit-mode helper is `tools/studio/StageApprovedStudioAsset.luau`.

For every staged upgrade: verify the 1987 look, model dimensions,
script stripping, collision, contact prompts, two lighting states and
phone FPS. In particular, `MixingDesk` and `TapeMachine` remain invisible
collision/prompt proxies when replacement art exists. Check that all reel
interactions and the dubbing desk are still usable. Delete a staged asset
from ServerStorage to restore its native fallback immediately.

No actual third-party Creator Store models are preinstalled on this branch;
Studio visual and playability checks remain outstanding.


## Offline pre-playtest cleanup — 0.7.5

No Studio playthrough was claimed or simulated. Source review was limited to
low-risk improvements until a real session can identify gameplay problems:

- Dynamic shadow cost: only the central LiveHall and Reception practicals
  retain shadow casting; other lamps still participate in dead/woken/red.
- 1987 story continuity: last session is **2 November**, the broadcast and
  town's silence begin **3 November**, and subsequent navy closures are
  labelled November. The chapter's document and puzzle dates take precedence
  over decorative signs.
- The viewing gallery's benches no longer clip the two side walls.
- StudioStoreAssets remains opt-in; no third-party assets are bundled or
  automatically downloaded, and no new gameplay systems or validators exist.

### First return to Roblox Studio (quick gate)

1. Open the match place on `chatgpt/studio-v2`; ensure Output reports
   `0.7.6-studio-v2` and the new recording house (not the greybox).
2. From Reception, reach Control A and interact with the tape machine,
   patch bay and mixing desk. Check that prompts aren't hidden by visuals.
3. Open a booth door and retrieve the archive reel. Confirm the shelf
   label matches the card index and the reel can be grabbed.
4. Complete or manually trigger Last Call; confirm the Control B shortcut
   shuts while the Live Hall exit route and front-door escape still work.
5. Watch phone FPS near the lights, live drum kit and control-room consoles.

Only after this gate should new Creator Store imports, path-blocking furniture,
or further art/detail changes be considered.


## 0.7.6 chapter opening tension pass

The new `Chapters/StudioTension.luau` adds up to four quiet, proximity-driven
sound events in the first ten minutes, each at least 45 seconds apart. It
never emits monster-attracting noise, resets on round change, and stops on
first shock or Last Call. The existing 15-second Engineer arrival, handler
radio, upstairs thumps and broadcast bleed remain unchanged.

See [STUDIO_CH1_OPENING.md](STUDIO_CH1_OPENING.md) for the narrative beat
sheet and the short audition plan. The new cues still reference placeholder
sounds, so listen for sound balance and potential repeats in Studio.

# Studio v2 — recording house redesign / first playable

Build: `0.7.2-studio-v2` on `chatgpt/studio-v2`.
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
   confirm `Config.VERSION = 0.7.2-studio-v2`.
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

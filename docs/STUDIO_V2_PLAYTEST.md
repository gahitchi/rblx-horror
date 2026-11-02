# Studio v2 — first playable blockout

Branch: `chatgpt/studio-v2`. The default match-place fallback now builds
`src/server/Maps/StudioGroundFloor.luau`; the previous `MapBuilder` greybox is kept
only if a supplied map fails its contract or its chapter requirements.
`MapContract.luau` and `docs/MAP_CONTRACT.md` are **unchanged**.

## What is implemented

- 19 connected, purpose-shaped rooms based on Blackline, including the larger 24-stud
  live hall, archive, both controls, reception, break room, service and staff loops.
- Three booth doors with acoustic volumes, seven wardrobes/lockers, four signed archive
  reel shelves, five optional tape spots, five throwables, multiple PA markers.
- All twelve named chapter-1 objective parts in their authored rooms, including the
  mail slot attached to the front door and the exit volume outside it.
- Two quarantine shutters: `Route = "short"` at ControlB–StaffPassage drops in Last Call;
  `Route = "production"` guards the other wing but stays raised. The alternate path
  ControlA → LiveHall → StaffGallery → Reception remains open.
- Basement quarantine seal, an upper landing/ramp ending at a barricaded flat door,
  and reserved service-lift location. **No basement or flat play spaces** are created.
- Warm beige/wood/teal/mustard studio palette against navy-grey closures. Existing
  `LightingService` controls dead, woken and red states on grouped `Lamps`.

## Playtest on Gabriel's laptop

1. Check out `chatgpt/studio-v2` and run the match place with `rojo serve`
   (use `default.project.json`, not the hub place). Confirm the in-game build version
   is `0.7.1-studio-v2`.
2. In Output, look for `[Map]`. **Any ERROR is a stop:** the runtime may have loaded the
   original greybox instead. Confirm the map name is Wrenmouth Recording Studio.
3. Walk from Reception through ControlA, TapeArchive, every booth, ControlB, LiveHall,
   BreakRoom, Stairwell and LoadingBay. Check all portal openings and slopes.
4. Complete the chapter objectives. Verify prompts are within eight studs, reels can be
   picked from all four signed shelves, the desk/machine/reception mail slot are usable.
5. With `Config.DEBUG_AI = true`, watch the Engineer reach the archive, side rooms,
   hiding containers and the live hall without `nav Failed` or clipping.
6. Trigger Last Call. The short shutter must close, the live-hall route must remain
   possible, and escape must register only after crossing the front threshold.
7. Check dead/woken/red lighting on a phone-size viewport and listen for false
   acoustic leaks through a closed booth.

This commit is **source-reviewed, not Studio-playtested**. No new validators or
realism/mesh pipelines were added. Fix first-play navigation and objective issues
before another art-detail pass.

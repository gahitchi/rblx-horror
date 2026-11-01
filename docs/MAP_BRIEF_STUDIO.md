# Map brief: the studio, chapter 1

For ChatGPT, who leads the map and the graphical side. Written 1 November 2026 after Gabriel
finished the design. Read `docs/DIRECTION.md` first, then the design doc (link in `CLAUDE.md`):
its "Story", "Map 1" and "Chapter 1" sections are the source for everything below.

## What this place is

The engineer's recording studio in Wrenmouth, a small coastal fishing town, as it was left in 1987.
He was a gentle man who recorded the town choir and the fishermen's songs; his family lived in the
flat above. The navy used his basement as a secret listening room. After the night the town went
silent, the navy sealed the building: magnetic quarantine locks on the front doors, a chained and
sealed stairwell to the basement, quarantine shutters in the corridors. Nobody has been inside
since. It should feel like a warm, human place that stopped mid-sentence.

## Style

- **Stylized, not realistic**, readable on a phone in the dark. Shape first, then lighting, then
  texture. Roblox materials plus a few custom textures.
- **Mood from light, fog and sound**, not material detail.
- **Budget:** about an afternoon per asset. Low part and triangle counts so mobile holds its frame
  rate. No realism benchmarks, anatomical meshes or per-asset quality pipelines for now: that work
  stays parked on `chatgpt/studio-art-pass`.
- **Palette idea:** 1980s studio warmth (brown acoustic foam, beige walls, teal and mustard
  accents) against the navy's cold additions (grey shutters, yellow-and-black seals, stencilled
  notices). The red emergency state after the mid-round shock should read instantly.

## Scope now: the ground floor (chapter 1)

The Blackline layout (19 connected spaces, varied room heights, the bigger live hall) is a good base
for this floor. Rooms the round needs:

- **Reception** with the front doors (the exit), fitted with the navy's magnetic quarantine locks.
- **Corridors** with posters, awards, dead lights, and navy quarantine shutters on at least two
  routes. One shutter must sit on the **short route** between control room A and reception, so
  dropping it during Last Call forces the run through the live room.
- **Control room A:** the big multitrack tape machine, the mixing desk, and the engineer's session
  log. This is where the reels are loaded and the last session is held.
- **Control room B.**
- **The live room:** a big hall full of instruments and things that are easy to knock over.
- **Three isolation booths:** soundproof, each with a `booth` door.
- **The tape archive:** rows of shelves, a small maze. Reels and tapes live here.
- **The break room.**
- **The stairwell**, visible from chapter 1 with two things shut in plain sight:
  - **Down:** a door chained and covered by a 1987 navy quarantine seal (opened in chapter 2).
  - **Up:** a short flight to a landing and the door to the engineer's flat, **barricaded from the
    inside** with furniture you can glimpse through gaps (it's never opened; chapter 3 reaches the
    flat another way).
- **Hiding spots:** wardrobes and lockers spread around (at least 6), each near an Area `Spot`.
- **Loose props** that can be thrown: bottles, cans, metal pipes.
- **Chapter 1's objective props** (see the design doc, "Chapter 1"): the booking diary at the
  reception desk; a maintenance cupboard with spare parts; the multitrack tape machine with a
  visible tape path; a card index cabinet in the archive; a road case in the live room, under
  instruments; a desk safe in control room B; a choir memorial programme in the break room; a patch
  bay next to the mixing desk; a mail slot in the front doors; a few spots for optional tapes.

## Plan ahead for later chapters

The basement (chapter 2: the navy's secure listening room, a decontamination airlock, flooded
corridors, pipes) sits under the stairwell, and the flat (chapter 3: hallway, kitchen, two
children's bedrooms, his workroom, an attic) sits above. A **navy service lift** runs from the
basement to the flat. Nothing of these needs building yet, but leave room in the footprint for
them, and put the service lift's shaft where both floors can reach it.

## Lighting states

The scripts switch the map between three states, so build lights that can be grouped per state:

1. **Dead:** pitch dark, flashlights only.
2. **Woken:** dim practical lamps that flicker (the building's machines wake near the sound).
3. **Red:** emergency red after the mid-round shock, until the end of the round.

## The Engineer

One strong, stylized silhouette: tall (about 8.5 studs), thin, blind, old studio headphones grown
into its skull, earcups that flare red when it lunges. Scary through shape, movement and sound, not
anatomy. Keep it compatible with `src/server/Monster/EngineerModel.luau` (same root part and
scale), so it drops in without script changes.

## Markers

Map contract v2 is coming with build plan batch A (`docs/BUILD_PLAN.md`): `ReelSpot` (at least 3,
more is better), `SessionLog`, `TapeMachine`, `MixingDesk`, `Shutters` with a `Route` attribute,
`sealed` and `barricaded` doors, hiding spots, `Throwable` spawns, lighting-state groups. The
generator, fuse box, fuse spots and power lights go away. Exact names land in
`docs/MAP_CONTRACT.md` when batch A is pushed; until then, place things where they belong and the
markers can be added on top. If the map needs something the contract doesn't allow, change the
contract (and `MapContract.luau`) or say so in a commit message and it'll be worked out together.

## Worth bringing over from `chatgpt/studio-art-pass`

The Blackline layout, the story props and environmental clues, the sound catalog, and the map kit
pieces, restyled where needed. Bring them to `main` in small, playtestable steps.

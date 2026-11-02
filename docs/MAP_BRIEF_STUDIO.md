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

A man, not a creature: tall (about 8.5 studs), thin, human, with old studio headphones fused into
his skull, earcups that flare red when he lunges. Scary through shape, movement and sound, not
anatomy. Keep it compatible with `src/server/Monster/EngineerModel.luau` (same root part and
scale), so it drops in without script changes.

He is **not blind** (changed 2 Nov 2026, Gabriel's call). Hearing still leads, but he sees too,
and light decides how far (`src/server/Monster/Vision.luau`, tuning in `Config.MONSTER.SIGHT`):
a few studs in the dark, much farther near a lamp that's on, farthest when a player's flashlight
is on; a beam shone at him is noticed whichever way he faces. Walls, shelves and closed doors block
his view, and hiding players are never seen. For the map this means: lamps in `Lamps` matter for
gameplay (lit pools are dangerous), and solid cover and dark corners are where players survive.

In the generated 1987 studio, hiding is now primarily **under ordinary desks**,
not inside giant lockers. Furniture has opaque sides/back panels and a physically
open front; the Engineer can inspect a desk when he heard a plausible cue or
confirmed seeing someone crawl underneath. A completed occupied-desk inspection
is a catch, not another chase. This does not grant automatic knowledge of
hidden players. See `docs/UNDER_DESK_HIDING.md`.

## Markers

Map contract v2 is in: `docs/MAP_CONTRACT.md` lists every folder, marker and objective name
chapter 1 needs (`ReelSpot`, `OptionalTapeSpot`, `Throwable`, `HidingSpots`, `Shutters`, `Lamps`,
`sealed` and `barricaded` doors, and the objective table). The greybox in
`src/server/MapBuilder.luau` builds all of it and is a working example of every rule. A map
missing any of chapter 1's objectives is refused and the greybox loads instead; the Output says
what's missing. If the map needs something the contract doesn't allow, change the contract (and
`MapContract.luau`) or say so in a commit message and it'll be worked out together.

## How to work

- Start a fresh branch from current `main` (for example `chatgpt/studio-v2`): `main` changed a
  lot since `chatgpt/studio-art-pass` branched. Bring pieces over from the old branch, don't merge it.
- Order: block out the ground floor first (rooms, doorways, routes, the stairwell landing), with
  the markers and objectives in place, so it can be played as soon as possible. Then the landmark
  props, then lighting, then dressing.
- Push playable steps often, so each can be tested in a round.
- The look: the Wrenmouth look-book (Gabriel has the link) and `docs/DIRECTION.md`. Studio colours:
  foam brown, beige, teal, mustard, against the navy's grey and yellow-black.

## Worth bringing over from `chatgpt/studio-art-pass`

The Blackline layout, the story props and environmental clues, the sound catalog, and the map kit
pieces, restyled where needed. Bring them to `main` in small, playtestable steps.

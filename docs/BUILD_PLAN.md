# Build plan: playable chapter 1

Goal: the studio's chapter 1 ("The Last Session") playable end to end, built to the design doc
(link in `CLAUDE.md`) and `docs/DIRECTION.md`. Written 1 November 2026, before any of it is built.

Gabriel prefers testing a fuller build in one session over many small playtests, so the work is
grouped into two playtests. Each batch below is pushed to `main` as it's done; the playtest happens
when its batches are in. Nothing here can be play-tested in Claude's environment: every batch ends
with a checklist in `docs/PLAYTEST.md` saying what to try and what is untested.

## Playtest 1: the new round

### A. Map contract v2 and the chapter system

- **Contract v2** (`docs/MAP_CONTRACT.md` and `src/server/MapContract.luau`, changed together):
  - Remove `Generator`, `FuseBox`, `FuseSpot`, `PowerLights`.
  - Add `ReelSpot` markers (at least 3, more is better), and objectives `SessionLog`,
    `TapeMachine`, `MixingDesk`.
  - Add `Shutters`: navy quarantine shutters that open and close by script, each with a `Route`
    attribute; one marked as the short route that drops during Last Call.
  - Add `Sealed` doors: `Kind = "sealed"` (the chained basement stairwell) and `"barricaded"` (the
    flat door upstairs, with occasional sounds behind it). Visible, never opened in chapter 1.
  - Add `Lighting` states the scripts switch between: dead (flashlight only), woken (dim practical
    lamps that flicker), red (after the mid-round shock).
  - Greybox (`MapBuilder`) updated to match, so the game runs with or without ChatGPT's map.
- **Chapters:** `ObjectiveService` becomes a chapter runner. Each chapter is one module listing its
  steps (`Chapters/Studio1.luau` first); shared steps (dub to cassette, Last Call) are reused by
  later chapters.
- **Round length:** 20 to 25 minutes of play and **no round timer**: a round ends when the crew
  escapes or the Engineer catches everyone. Remove the round clock (`Config.ROUND_TIME`) and
  anything that depends on time left (for example `REVIVE.MIN_TIME_LEFT`).
- **Soft pressure instead of a clock:** the longer the round runs, the thicker the fog, the sharper
  the Engineer's hearing and the more often the director sends it toward the crew (curves in
  `Config`).
- **Optional story tapes:** a few per chapter at their own markers; pushing one through the front
  doors' mail slot delivers it to the handler, and delivered tapes count even if the crew is wiped.

### B. Chapter 1's round (about 22 minutes)

The full sequence is in the design doc ("Chapter 1"). What gets built:

- **Arrival:** front-door locks slam, foghorn, handler line on the walkies (subtitled text for
  now). The booking diary at reception points to control room A.
- **Fix the tape machine:** spares (pinch roller, belt) picked up in the maintenance cupboard, then
  a rethreading puzzle at the machine: route the tape around the guides in the right order. Quiet,
  interruptible, works with mouse, touch and gamepad.
- **The session log** at control room A names the three reels by catalogue number (random each
  round).
- **Three reels, three ways:**
  - archive: a card index gives the shelf for the number, then the shelf in the aisle maze;
  - live room: a road case under instruments that must be moved first (each move is noisy);
  - control room B: a desk safe whose combination is a fixed story date, found on the memorial
    programme in the break room.
  Loading a reel plays its track aloud for a few seconds (a big noise event).
- **Two shocks, on progress with a time fallback:** shock 1 when the first reel is loaded (the
  building wakes: lamps flicker on, speakers crackle, the barricaded door bangs, the first real
  hunt); shock 2 after the second reel (blackout, fog, every speaker replays sounds the team made
  earlier from `Monster/Mimicry` recordings, about 20 seconds of frenzy, then red lights). If the
  crew stalls, each shock fires anyway after a while (times in `Config`).
- **Patch the desk:** a patch-bay puzzle (connect the three track outputs to the desk inputs the log
  lists, different each round).
- **The last session:** a 20-second hold at the mixing desk that dubs onto the cassette while the
  full recording plays through the building. The holder rides the faders (keep the levels in the
  safe band); letting them drift makes louder noise spikes.
- **The cassette:** a pocket item (no weight). A caught carrier drops it where they fell. The
  chapter is cleared only if it crosses the `ExitZone`.
- **Optional tapes:** three per chapter at their own markers; delivered through the mail slot in
  the front doors (counts even after a wipe).
- **Last Call:** door locks release for 45 seconds with a HUD countdown, the short-route shutter
  drops, the Engineer frenzies (director back-off off, top hunt speed just under a sprint), then the
  doors relock and anyone inside is caught. Escape moment and near-miss results (closest distance,
  seconds left, who rescued whom).
- **New contract markers** for all of this: `BookingDiary`, `Spares`, `CardIndex`, `RoadCase`,
  `Safe`, `MemorialProgramme`, `PatchBay`, `MailSlot`, `OptionalTapeSpot`.
- **Retire** the generator, fuse and emergency-tape code and their `Config`, `Sounds` and rewards.

### C. Catches, echoes and revive

- **Catch:** the Engineer rips the headset off. The body stays where it fell, entranced and humming
  softly (a quiet looping noise event the monster can hear).
- **Echo:** the caught player floats freely through the whole building (no collision), sees the
  monster through walls, can ping it for the living (cooldown) and whisper: proximity voice for
  players with voice, a few quick whispers for those without. Short range, fades if spammed, and
  the monster sometimes hears it.
- **Revive:** a teammate holds E on the body for about 4 seconds while the headset re-syncs (loud
  static). Price rules stay as they are (a level, a bought revive token, or the high-priced Robux
  product).
- **All caught:** the round ends, chapter not cleared. A last survivor can still win alone.

## Playtest 2: moment to moment and the story layer

### D. Hiding, weight and throwables

- **Hiding spots:** wardrobes and lockers (new contract markers) you step into and out of. Inside,
  your noise is muffled. When the Engineer is close your breathing grows loud: hold a key to hold
  your breath for a few seconds (voice still counts). Every hiding spot near an Area `Spot`.
- **Hands and pockets:** one item in hand (a reel or a throwable), the cassette in a pocket, fixed
  gear on the belt (flashlight, walkie, tape recorder, headset).
- **Weight:** every hand item has a weight that drains stamina faster and lowers sprint speed
  (a reel or metal pipe heavy, a glass bottle light). Values in `Config`.
- **Throwables:** bottles, cans and pipes spawn at `Throwable` markers. Pick up, throw in an arc,
  noise where it lands by weight and material.

### E. The story layer for chapter 1

- Handler and broadcast lines on the walkies, with subtitles; the session log readable.
- **Progress:** clearing chapter 1 saves it (`ProgressService`) and unlocks its story tape.
- **Hub:** crews carry a chapter; strict lobbies (everyone must have it unlocked, greyed out with
  the reason otherwise); quick join to your next unplayed chapter; the tape deck replays recovered
  tapes. The hub's art (the coast road, the van) comes later with the map work.
- **Medals** for chapter 1: clean run, fast run, nobody caught.

## Before each playtest

`stylua src`, `luau-lsp analyze` for both places, `rojo build` for both project files, bump
`Config.VERSION`, update `README.md` and `docs/PLAYTEST.md`.

## After chapter 1

Chapters 2 and 3 reuse this system: new contract markers for the basement and the flat (water
areas, pipes, the sonar analyzer, the service lift, family tapes), the Engineer's new behaviours,
and the chapter-specific Last Call shapes. Planned once chapter 1 has been played.

# Playtest checklist: 0.7.0

Everything since 0.6.0 was written in one night and **none of it has run in Roblox yet**: expect
things to break. That's what this session is for. Play `main` (the greybox): ChatGPT's map still
follows the old contract, so the game would fall back to the greybox anyway.

## Before you start

- Set `Config.DEBUG_AI = true` for the first round (the monster's state and path), `false` after.
- To get to the later parts quickly while testing, you can lower the shock fallbacks in
  `Config.PACING` (for example `SHOCK1_FALLBACK = 60`, `SHOCK2_FALLBACK = 150`). Put them back after.
- Use **Test > Clients and Servers with 2 players** for at least one round: echoes, revives and
  whispers need two people.
- Keep the Output window open and copy every red or yellow line, and every `[Map]` line.

## 1. Start and the greybox

- [ ] No `[Map] ERROR` lines. The first line says `chapter studio1`.
- [ ] The stairwell door (cross corridor, west end) shows the navy quarantine notice and doesn't open.
- [ ] The "PRIVATE, stairs to the flat" door next to it doesn't open; now and then something thumps behind it.
- [ ] The new back route works: break room back door > service passage > side door into reception.
- [ ] Wardrobes and lockers stand in reception, both control rooms, the break room, the archive and the live room.
- [ ] Bottles, cans and pipes lie around.
- [ ] It's pitch dark at the start (flashlights only).

## 2. Arrival (first 30 seconds)

- [ ] A slam at the front doors and a (placeholder) foghorn.
- [ ] Two handler lines appear on the right in amber: "[Handler] ...".
- [ ] The objective list (top left) says THE LAST SESSION with the steps.

## 3. Documents

- [ ] Booking diary (reception desk): a readable page opens; walking away closes it; "Close" too.
- [ ] Session log (on the mixing desk, control A): three catalogue numbers, the patch, the threading order.
- [ ] Order of service (break room table): the date 3 November 1979.
- [ ] Card index (archive, by the door): cards sorted by number; reel A's card says a shelf, B's the road case, C's the safe.

## 4. The tape machine

- [ ] Using the machine without spares says the tape path is broken (and the handler mentions the cupboard).
- [ ] Break room cupboard: "Take spare parts". The item line says "Holding: Spare parts". G drops it, E picks it up.
- [ ] Machine with spares: the rethreading screen. Wrong guide: "slipped off", a clatter, start again.
- [ ] Right order (supply reel ... take-up reel): the machine is fixed, the objective list updates.

## 5. The three reels

- [ ] Archive: the shelf from the card index has the right reel (its prompt shows the catalogue number); other shelves show "Read the label".
- [ ] Live room road case: "Open" refuses until the three instruments are moved; each move is noisy.
- [ ] Control B safe: keypad; a wrong code clunks; three wrong jams it briefly; 031179 opens it.
- [ ] Holding a reel, sprinting feels shorter and slower than empty-handed.
- [ ] Loading a reel on the fixed machine plays it out loud and the monster comes.

## 6. The shocks

- [ ] First reel: lamps flicker on (warm), a crackle through the speakers, a thump behind the flat door, a handler line.
- [ ] Second reel (at least 90 seconds after the first): blackout, then red lights, thick fog for a while, your own sounds played back from the speakers, a frenzied monster for about 20 seconds.
- [ ] Waiting without loading reels: the shocks come anyway (9 and 16 minutes by default).

## 7. Patch bay and the last session

- [ ] Before the second shock, the patch bay says there's nothing to patch.
- [ ] After it: the patch bay screen. A wrong patch buzzes through the speakers ("N of 3 right"); the log's patch works.
- [ ] Mixing desk with 3 reels and the patch: the fader screen opens straight away. W/S or the arrows move the level; out of the band it says TOO HOT and the speakers spike.
- [ ] Walking away from the desk pauses it; someone else can take over.
- [ ] At 100%: you get the cassette (item line: CASSETTE), Last Call starts.

## 8. Last Call

- [ ] Top centre: "THE LOCKS RE-ENGAGE IN 45" counting down in red. The front doors are open.
- [ ] The corridor shutter (between the control rooms and reception) crashes down: the way out is the long way round.
- [ ] The monster is relentless.
- [ ] Escaping with the cassette: "escaped with the cassette!", a sting. The results say the chapter is cleared.
- [ ] Still inside when the count ends: the doors shut and you're caught.

## 9. Hiding

- [ ] E on a wardrobe or locker: you're inside, "Hiding · E to step out". E again steps out in front.
- [ ] With the monster close: "It's close. Hold your breath (Space)" with a meter. Not holding: it comes to check.
- [ ] Holding too long: a gasp.
- [ ] When it searches nearby, it opens the closest hiding spot; if you're inside, it has you.

## 10. Throwing

- [ ] Pick up a bottle, can or pipe; T (or the Throw button) throws it where you look.
- [ ] It lands with a noise and the monster goes to check. Bottles smash; cans and pipes can be picked up again.

## 11. Caught, echoes, revive (2 players)

- [ ] When caught, your body stays slumped where it fell (with your headset next to it) and hums now and then.
- [ ] You float freely (move with the usual controls, forward follows where you look) and see the monster red through walls.
- [ ] P (or "Mark it") puts a red "!" over the monster for the other player for a few seconds; a cooldown after.
- [ ] 5 to 8 (or the buttons) whisper: the living player nearby sees "Name, faintly: ...". Spamming fades out.
- [ ] Revive panel: pay with a level; the living player gets a radio message, holds E on the headset (loud static), you're back there.
- [ ] Everyone caught: the round ends.
- [ ] Anything you carried (reel, cassette, tapes) lies where you were caught.

## 12. Optional tapes

- [ ] Three old tapes lie somewhere each round. Picking one up says its title.
- [ ] At the front doors' mail slot: "Push tapes through": "Tape delivered".
- [ ] Delivered tapes are kept even if the crew is wiped later (not visible anywhere yet: the hub tape deck isn't built).

## 13. Results and progress

- [ ] Results lines: closest call, seconds left on the doors, who you brought back, medals when cleared.
- [ ] There's no round clock anywhere.
- [ ] The game feels harder the longer it runs (fog thickens, the monster finds you more).

## 14. Hub (published game only)

- [ ] The crew panel shows "Chapter 1. The Last Session", "Create crew" and "Quick join".
- [ ] Quick join with nobody waiting makes a crew; a second player's quick join joins it.
- [ ] The match server starts chapter 1 (Output: `chapter studio1`).

## Tell me after

How it feels: which moments were tense, which were boring, what was confusing, what was too dark.
And how long the round took.
